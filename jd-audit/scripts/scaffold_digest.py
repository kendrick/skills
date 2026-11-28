#!/usr/bin/env python3
"""Compute, stamp, and check the `scaffold_digest` a scaffolded note carries.

A scaffolded file is furniture: something a skill dropped in by itself, not
something a person put there. `jd-audit` needs to tell the two apart so
`hygiene-empty` can report an ID that holds nothing anyone wrote. Basenames
cannot answer that -- `README.md` and `CLAUDE.md` are furniture in a scaffold
and payload everywhere else -- so a scaffolded file records a digest of the
body it was written with, and any later edit breaks the match.

The digest covers the body alone. Obsidian rewrites frontmatter unprompted,
adding tags and touching timestamps, and none of that is a person writing
content. Hashing frontmatter would report every synced vault as edited.

Three skills write this key and one of them reads it back. `jd-file` stamps
an Overview at mint time, `inbox-to-memory` stamps what scaffold mode
generates, and `jd-audit` both stamps existing notes in a one-time pass and
re-hashes every candidate on a normal run. A one-byte disagreement between
any writer and that reader marks every stamped file as edited and silences
the check in the exact direction it exists to catch, with no error and no
trace. That is why the algorithm lives in this file rather than in three
prose restatements of it.

This file is duplicated byte-for-byte into jd-file/scripts/,
jd-audit/scripts/, and inbox-to-memory/scripts/. Skills install standalone
(`npx skills add ... --skill jd-file` pulls only that skill's directory), so
each skill needs its own copy on disk rather than a shared import outside
any of the three trees. Edit the jd-file copy and re-copy it verbatim over
the other two -- tests/scaffold-digest-smoke.sh runs `cmp` across all three
and fails the suite if they drift apart.

  scaffold_digest.py --stamp FILE [FILE ...]
  scaffold_digest.py --check FILE [FILE ...]

--check writes nothing and exits 1 when a stored digest no longer matches its
body, which is what lets an audit ask "has anyone written here?" without
holding the power to answer by overwriting.
"""

from __future__ import annotations

import argparse
import hashlib
import sys

# --------------------------------------------------------------------------
# Digest
# --------------------------------------------------------------------------

# 0 clean, 1 a real mismatch, 2 the file is not shaped like a stamped note.
# A mismatch and a malformed file are different answers: the first says a
# person wrote here, the second says nothing at all and must not be read as
# the first.
EXIT_OK, EXIT_MISMATCH, EXIT_STRUCTURE = 0, 1, 2

KEY = "scaffold_digest"
DELIMITER = "---\n"


def _split(text: str) -> tuple[str, str]:
    """Split `text` into its frontmatter and the bytes the digest covers.

    The closing `---` line and its own newline are excluded from the body.
    The blank line that follows it and the file's trailing newline are
    included, untrimmed. Drawing the boundary anywhere else is still
    self-consistent, which is the trap: every writer would agree with itself
    and disagree with the reader.
    """
    parts = text.replace("\r\n", "\n").split(DELIMITER, 2)
    if len(parts) < 3 or parts[0] != "":
        raise ValueError("no frontmatter block delimited by --- lines")
    return parts[1], parts[2]


def compute(text: str) -> str:
    """Digest of `text`'s body, as `sha256:` followed by lowercase hex."""
    body = _split(text)[1]
    return "sha256:" + hashlib.sha256(body.encode("utf-8")).hexdigest()


def stored(text: str) -> str | None:
    """The digest recorded in frontmatter, or None when the key is absent."""
    for line in _split(text)[0].splitlines():
        name, sep, value = line.partition(":")
        if sep and name.strip() == KEY:
            return value.strip().strip('"').strip("'")
    return None


def restamp(text: str) -> str:
    """Return `text` with its `scaffold_digest` set to match its body.

    Every other byte survives, including line endings, key order, and any
    frontmatter Obsidian has added. An existing key is rewritten in place; a
    missing one is appended just above the closing delimiter, which keeps the
    key adjacent to whatever else describes the file rather than buried.
    """
    digest = compute(text)
    lines = text.splitlines(keepends=True)

    # Line 0 opens the frontmatter, so the next bare `---` closes it.
    close = next(i for i in range(1, len(lines)) if lines[i].rstrip("\r\n") == "---")
    eol = "\r\n" if lines[close].endswith("\r\n") else "\n"

    for i in range(1, close):
        name, sep, _ = lines[i].partition(":")
        if sep and name.strip() == KEY:
            lines[i] = f'{KEY}: "{digest}"{eol}'
            break
    else:
        lines.insert(close, f'{KEY}: "{digest}"{eol}')

    return "".join(lines)


# --------------------------------------------------------------------------
# CLI
# --------------------------------------------------------------------------


def parse_args(argv):
    p = argparse.ArgumentParser(prog="scaffold_digest.py")
    mode = p.add_mutually_exclusive_group(required=True)
    mode.add_argument("--stamp", action="store_true")
    mode.add_argument("--check", action="store_true")
    p.add_argument("files", nargs="+")
    return p.parse_args(argv)


def main(argv=None) -> int:
    args = parse_args(argv if argv is not None else sys.argv[1:])
    status = EXIT_OK

    for path in args.files:
        try:
            with open(path, encoding="utf-8", newline="") as f:
                text = f.read()
        except OSError as exc:
            print(f"{path}: {exc.strerror}", file=sys.stderr)
            status = max(status, EXIT_STRUCTURE)
            continue

        try:
            if args.stamp:
                stamped = restamp(text)
                if stamped != text:
                    with open(path, "w", encoding="utf-8", newline="") as f:
                        f.write(stamped)
                print(f"{path}: {compute(text)}")
                continue

            recorded = stored(text)
            if recorded is None:
                print(f"{path}: no {KEY} in frontmatter", file=sys.stderr)
                status = max(status, EXIT_STRUCTURE)
            elif recorded != compute(text):
                print(f"{path}: {KEY} does not match body", file=sys.stderr)
                status = max(status, EXIT_MISMATCH)
        except ValueError as exc:
            print(f"{path}: {exc}", file=sys.stderr)
            status = max(status, EXIT_STRUCTURE)

    return status


if __name__ == "__main__":
    sys.exit(main())
