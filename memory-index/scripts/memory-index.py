#!/usr/bin/env python3
"""Register a memory scope's folders with qmd as collections, and refresh the index.

Exit codes: 0 pass, 1 a qmd command failed or refresh could not write its
stamp after every qmd command succeeded (FAILED: write <path>), 2 usage error (argparse's own
code), 3 not a memory scope or qmd not on PATH. refresh --if-changed always
exits 0.

Collections key on folders and the script never opens a record file under
_memory/<type>/. Frontmatter can drift from the folder a record sits in, and
the folder is what the scope owner actually moves.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shlex
import shutil
import subprocess
import sys
import time
from pathlib import Path

MCP_LINE = (
    "MCP: add "
    + json.dumps({"qmd": {"command": "qmd", "args": ["mcp"]}})
    + " to your client's mcpServers"
)


def scope_name(root: Path) -> str:
    return re.sub(r"[^a-z0-9]+", "-", root.name.lower()).strip("-")


# find-candidates.sh vendors the next three functions byte-for-byte.
def state_dir() -> Path:
    return Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local" / "state") / "memory-index"


def last_refresh_ns() -> int | None:
    """Start time of the last successful refresh, or None when no stamp is readable."""
    try:
        return int(json.loads((state_dir() / "last-refresh.json").read_text(encoding="utf-8"))["started_ns"])
    except (OSError, ValueError, KeyError, TypeError):
        return None


def changed_since(folder: Path, pattern: str, since: int | None) -> bool:
    """True when a regular file in folder.glob(pattern) is newer than since.

    pathlib's glob, not fnmatch: fnmatch's `*` crosses `/`, so "*.md" would
    match notes/raw/x.md, which qmd's `*.md` mask leaves out. since None means
    no stamp, so every matching file counts as newer.
    """
    for f in folder.glob(pattern):
        try:
            if f.is_file() and (since is None or f.stat().st_mtime_ns > since):
                return True
        except OSError:
            continue
    return False


def matching_files(folder: Path, pattern: str) -> list[str]:
    """Sorted POSIX paths, relative to folder, of the regular files in folder.glob(pattern)."""
    return sorted(f.relative_to(folder).as_posix() for f in folder.glob(pattern) if f.is_file())


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
        if not line.startswith("- "):
            continue
        text = line[2:]
        # Match the label only: a description can name another type ("a choice made under standing rules").
        m = re.search(r"\*\*(.+?)\*\*", text) or re.search(r"`(.+?)`", text) or re.match(r"[A-Z][A-Za-z/-]*(?: [A-Z][A-Za-z/-]*)*", text)
        label = m.group(m.lastindex or 0) if m else ""
        if key in letters(label):
            return text.replace("**", "").strip()
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


def qmd_output(cmd: list[str]) -> str | None:
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        first = (proc.stderr.strip().splitlines() or [""])[0]
        print(f"FAILED: {shlex.join(cmd)}", file=sys.stderr)
        print(first, file=sys.stderr)
        return None
    return proc.stdout


def run_all(cmds: list[list[str]]) -> int:
    for cmd in cmds:
        if qmd_output(cmd) is None:
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


def refresh() -> int:
    if shutil.which("qmd") is None:
        print("qmd not on PATH", file=sys.stderr)
        return 3
    # Stamp the start, not the end: a file written while update or embed runs
    # stays newer than the stamp, so the next hook call picks it up.
    started = time.time_ns()
    if run_all([["qmd", "update"], ["qmd", "embed"]]) != 0:
        return 1
    listing = qmd_output(["qmd", "collection", "list"])
    if listing is None:
        return 1
    # Cached here because every qmd call takes seconds, and the hook mode has
    # under one to decide.
    cols = []
    for name in re.findall(r"^(\S+) \(qmd://", listing, re.M):
        cmd = ["qmd", "collection", "show", name]
        shown = qmd_output(cmd)
        if shown is None:
            return 1
        path = re.search(r"^\s*Path:\s+(.*?)\s*$", shown, re.M)
        pattern = re.search(r"^\s*Pattern:\s+(.*?)\s*$", shown, re.M)
        if not (path and pattern):
            # A guessed path would watch the wrong folder.
            print(f"FAILED: {shlex.join(cmd)}", file=sys.stderr)
            print("unreadable qmd output", file=sys.stderr)
            return 1
        p, m = path.group(1), pattern.group(1)
        cols.append({"name": name, "path": p, "pattern": m, "files": matching_files(Path(p), m)})
    stamp = state_dir() / "last-refresh.json"
    try:
        stamp.parent.mkdir(parents=True, exist_ok=True)
        part = stamp.with_name(f"{stamp.name}.{os.getpid()}")
        part.write_text(json.dumps({"started_ns": started, "collections": cols}), encoding="utf-8")
        os.replace(part, stamp)
    except OSError as e:
        print(f"FAILED: write {stamp}", file=sys.stderr)
        print(e, file=sys.stderr)
        return 1
    return 0


def cmd_if_changed() -> int:
    """Hook mode: never a qmd call, nothing on stdout, exit 0 on every branch.

    A Claude Code SessionStart hook's stdout lands in the agent's context and a
    Stop hook's exit 2 blocks the stop, so any output or nonzero exit here
    leaks into the session. Diagnostics go to stderr, one line.
    """
    sd = state_dir()
    since = last_refresh_ns()
    try:
        cols = json.loads((sd / "last-refresh.json").read_text(encoding="utf-8"))["collections"]
        # mtimes alone miss a rename or a delete: mv keeps the file's mtime, and a
        # deleted file drops out of the glob. Comparing the file list catches both.
        stale = since is None or any(
            changed_since(Path(c["path"]), c["pattern"], since)
            or matching_files(Path(c["path"]), c["pattern"]) != c["files"]
            for c in cols
        )
    except (OSError, ValueError, KeyError, TypeError):
        # No stamp, or one written before stamps listed files, so nothing shows
        # the index is current.
        stale = True
    if not stale:
        return 0
    # Before the lock, so a machine without qmd never spawns a child that can only fail.
    if shutil.which("qmd") is None:
        print("qmd not on PATH", file=sys.stderr)
        return 0
    # Imported here because a top-level import would shift the lines find-candidates.sh vendors.
    # Windows has no fcntl, and the hook contract still wants exit 0 there.
    try:
        import fcntl
    except ImportError:
        print("memory-index: no fcntl on this platform; hook refresh skipped", file=sys.stderr)
        return 0

    try:
        sd.mkdir(parents=True, exist_ok=True)
        fd = os.open(sd / "refresh.lock", os.O_CREAT | os.O_WRONLY, 0o600)
    except OSError as e:
        print(f"memory-index: {e}", file=sys.stderr)
        return 0
    try:
        # flock, not an O_EXCL file: the kernel drops it when the child exits,
        # even on SIGKILL, so no stale lock is left for two callers to reclaim at once.
        fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        # A refresh is running.
        os.close(fd)
        return 0
    except OSError as e:
        os.close(fd)
        print(f"memory-index: {e}", file=sys.stderr)
        return 0
    try:
        # The child must not hold the hook's pipes, or the harness waits on it.
        # The child inherits fd, so the lock lasts exactly as long as the refresh.
        with open(sd / "refresh.log", "w", encoding="utf-8") as log:
            subprocess.Popen(
                [sys.executable, str(Path(__file__).resolve()), "refresh", "--holding-lock"],
                stdin=subprocess.DEVNULL,
                stdout=log,
                stderr=log,
                start_new_session=True,
                pass_fds=(fd,),
            )
    except OSError as e:
        print(f"memory-index: {e}", file=sys.stderr)
    finally:
        os.close(fd)
    return 0


def cmd_refresh(args) -> int:
    if args.if_changed:
        return cmd_if_changed()
    return refresh()


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    sub = p.add_subparsers(dest="command", required=True)
    r = sub.add_parser("register", help="register a scope's folders as qmd collections")
    r.add_argument("scope_root")
    r.add_argument("--dry-run", action="store_true", help="print the qmd commands and run nothing")
    r.set_defaults(fn=cmd_register)
    f = sub.add_parser("refresh", help="qmd update, then qmd embed")
    f.add_argument(
        "--if-changed",
        action="store_true",
        help="hook mode: no stdout, exit 0, refresh detached only when a collection changed",
    )
    # Marks the child --if-changed spawns, so `ps` shows which refresh holds the lock.
    f.add_argument("--holding-lock", action="store_true", help=argparse.SUPPRESS)
    f.set_defaults(fn=cmd_refresh)
    args = p.parse_args()
    return args.fn(args)


if __name__ == "__main__":
    sys.exit(main())
