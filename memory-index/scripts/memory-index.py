#!/usr/bin/env python3
"""Register a memory scope's folders with qmd as collections, and refresh the index.

Exit codes: 0 pass, 1 a qmd command failed, 2 usage error (argparse's own
code), 3 not a memory scope or qmd not on PATH.

Collections key on folders and the script never opens a record file under
_memory/<type>/. Frontmatter can drift from the folder a record sits in, and
the folder is what the scope owner actually moves.
"""

from __future__ import annotations

import argparse
import json
import re
import shlex
import shutil
import subprocess
import sys
from pathlib import Path

MCP_LINE = (
    "MCP: add "
    + json.dumps({"qmd": {"command": "qmd", "args": ["mcp"]}})
    + " to your client's mcpServers"
)


def scope_name(root: Path) -> str:
    return re.sub(r"[^a-z0-9]+", "-", root.name.lower()).strip("-")


def section_body(text: str, matches) -> str | None:
    """Body of the first `## ` heading whose title satisfies `matches`."""
    lines = text.splitlines()
    for i, line in enumerate(lines):
        if line.startswith("## ") and matches(line[3:].strip()):
            body = []
            for nxt in lines[i + 1 :]:
                if nxt.startswith("#"):
                    break
                body.append(nxt)
            return "\n".join(body)
    return None


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError):
        return ""


def scope_text(root: Path, scope: str) -> str:
    # Strip comments before splitting lines: a multi-line fill-in comment
    # would otherwise leak its text into every context string.
    text = re.sub(r"<!--.*?-->", "", read_text(root / "CLAUDE.md"), flags=re.S)
    body = section_body(text, lambda t: t.endswith("in One Paragraph"))
    body = " ".join((body or "").split())
    return body or f"Memory scope {scope}."


def letters(s: str) -> str:
    return re.sub(r"[^a-z]", "", s.lower())


def type_description(root: Path, folder: str) -> str | None:
    key = letters(folder)
    key = key[:-1] if key.endswith("s") else key
    body = section_body(read_text(root / "_memory" / "CLAUDE.md"), lambda t: t.startswith("Record Types"))
    for line in (body or "").splitlines():
        if line.startswith("- ") and key in letters(line):
            return line[2:].replace("**", "").strip()
    return None


def register_commands(root: Path) -> list[list[str]]:
    scope = scope_name(root)
    base = scope_text(root, scope)
    cmds = []
    types = sorted(p.name for p in (root / "_memory").iterdir() if p.is_dir() and not p.name.startswith("."))
    for t in types:
        desc = type_description(root, t)
        ctx = f"{base} {t} records: {desc}" if desc else f"{base} {t} records."
        name = f"{scope}-{t}"
        cmds.append(["qmd", "collection", "add", str(root / "_memory" / t), "--name", name])
        cmds.append(["qmd", "context", "add", f"qmd://{name}", ctx])
    if (root / "notes").is_dir():
        name = f"{scope}-notes"
        ctx = f"{base} Groomed notes, one per input; raw transcripts live in notes/raw/ and are not indexed."
        # Mask, not ignore: qmd's ignore list is YAML-only, and "*.md" matches only top-level notes.
        cmds.append(["qmd", "collection", "add", str(root / "notes"), "--name", name, "--mask", "*.md"])
        cmds.append(["qmd", "context", "add", f"qmd://{name}", ctx])
    return cmds


def run_all(cmds: list[list[str]]) -> int:
    for cmd in cmds:
        proc = subprocess.run(cmd, capture_output=True, text=True)
        if proc.returncode != 0:
            first = (proc.stderr.strip().splitlines() or [""])[0]
            print(f"FAILED: {shlex.join(cmd)}", file=sys.stderr)
            print(first, file=sys.stderr)
            return 1
    return 0


def cmd_register(args) -> int:
    root = Path(args.scope_root).resolve()
    if not (root / "_memory").is_dir():
        print(f"not a memory scope: {root}", file=sys.stderr)
        return 3
    if not args.dry_run and shutil.which("qmd") is None:
        print("qmd not on PATH", file=sys.stderr)
        return 3
    cmds = register_commands(root)
    if args.dry_run:
        for cmd in cmds:
            print(shlex.join(cmd))
    elif (rc := run_all(cmds)) != 0:
        return rc
    print(MCP_LINE)
    return 0


def cmd_refresh(_args) -> int:
    if shutil.which("qmd") is None:
        print("qmd not on PATH", file=sys.stderr)
        return 3
    return run_all([["qmd", "update"], ["qmd", "embed"]])


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    sub = p.add_subparsers(dest="command", required=True)
    r = sub.add_parser("register", help="register a scope's folders as qmd collections")
    r.add_argument("scope_root")
    r.add_argument("--dry-run", action="store_true", help="print the qmd commands and run nothing")
    r.set_defaults(fn=cmd_register)
    f = sub.add_parser("refresh", help="qmd update, then qmd embed")
    f.set_defaults(fn=cmd_refresh)
    args = p.parse_args()
    return args.fn(args)


if __name__ == "__main__":
    sys.exit(main())
