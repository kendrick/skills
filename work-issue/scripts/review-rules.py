#!/usr/bin/env python3
"""Install work-issue's review-rules block into a repo's AGENTS.md, or check
that the installed copy matches the shipped one.

    work-issue/scripts/review-rules.py install <repo>
    work-issue/scripts/review-rules.py check <repo>

Codex reviews a pull request against the AGENTS.md files in the repo under
review and nothing else, so rules about work-issue's PR conventions reach a
review only once they sit in that repo's own AGENTS.md. The block is the
begin-marker line through the end-marker line of
../references/codex-review-rules.md, found from this script's own directory
so an installed skill reads the same file the repo copy does.

install: where <repo>/AGENTS.md holds a block, replace it and touch no other
byte. Where it holds an exact `## Code Review Rules` line and no block, put the
block right after the first such line, so the repo's own rules follow it.
Where it holds neither, append the heading and the block. A missing AGENTS.md
is created. A file already current is left unwritten.

check: pass when AGENTS.md holds exactly one block equal to the shipped one.
Text outside the markers never affects the result.

Exit codes: 0 pass (or installed, or already current); 1 the block is stale
or missing, the markers are malformed (a begin with no end, an end with no
begin, an end before its begin, two blocks), or install was pointed at a
symlinked AGENTS.md; 3 usage error, <repo> not a directory, or an unreadable
AGENTS.md or reference. One line per problem on stderr.

Stdlib only, so the skill stays copy-in portable.
"""
import argparse
import os
import re
import sys
import tempfile

BEGIN = re.compile(r"<!-- work-issue review rules v(\d+) begin -->")
END = re.compile(r"<!-- work-issue review rules v(\d+) end -->")
HEADING = "## Code Review Rules"
REFERENCE = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "..", "references", "codex-review-rules.md"
)


class Usage(Exception):
    pass


class Malformed(Exception):
    pass


class Parser(argparse.ArgumentParser):
    # argparse exits 2 on a usage error, but this repo's validators use 3 for
    # usage, so a caller can tell a bad call from a stale block.
    def error(self, message):
        self.print_usage(sys.stderr)
        print(f"{self.prog}: error: {message}", file=sys.stderr)
        sys.exit(3)


def read(path):
    # newline="" stops Python translating CRLF, since install promises that
    # every byte outside the block survives.
    try:
        with open(path, encoding="utf-8", newline="") as f:
            return f.read()
    except (OSError, UnicodeDecodeError) as e:
        raise Usage(f"cannot read {path}: {e}")


def find_block(text, name):
    """Return (start, stop, version) of the one block in `text`, as offsets
    from the start of the begin line to the end of the end marker's text
    (its line terminator excluded), or None when there are no markers."""
    begins, ends = [], []
    offset = 0
    for line in text.splitlines(keepends=True):
        bare = line.rstrip("\r\n")
        if BEGIN.fullmatch(bare):
            begins.append((offset, BEGIN.fullmatch(bare).group(1)))
        elif END.fullmatch(bare):
            ends.append(offset + len(bare))
        offset += len(line)
    if not begins and not ends:
        return None
    if len(begins) > 1 or len(ends) > 1:
        raise Malformed(f"{name}: {len(begins)} begin and {len(ends)} end markers; expected one block")
    if not ends:
        raise Malformed(f"{name}: begin marker with no end marker")
    if not begins:
        raise Malformed(f"{name}: end marker with no begin marker")
    (start, version), stop = begins[0], ends[0]
    if stop < start:
        raise Malformed(f"{name}: end marker before its begin marker")
    return start, stop, version


def shipped_block():
    text = read(REFERENCE)
    try:
        found = find_block(text, REFERENCE)
    except Malformed as e:
        raise Usage(str(e))
    if found is None:
        raise Usage(f"{REFERENCE}: no review-rules block")
    start, stop, version = found
    return text[start:stop], version


def agents_path(repo):
    if not os.path.isdir(repo):
        raise Usage(f"{repo}: not a directory")
    return os.path.join(repo, "AGENTS.md")


def read_agents(path):
    if not os.path.lexists(path):
        return None
    return read(path)


def placed(text, block):
    """Return `text` with the block in place, per the module docstring."""
    if text is None or text == "":
        return f"{HEADING}\n\n{block}\n"
    found = find_block(text, "AGENTS.md")
    if found is not None:
        start, stop, _ = found
        return text[:start] + block + text[stop:]
    offset = 0
    for line in text.splitlines(keepends=True):
        offset += len(line)
        if line.rstrip("\r\n") == HEADING:
            head, rest = text[:offset], text[offset:]
            if not head.endswith("\n"):
                head += "\n"
            # The repo's rules usually open with a blank line already. Add one
            # only where they don't, so the block never ends up with two.
            gap = "" if rest.startswith(("\n", "\r\n")) or rest == "" else "\n"
            return f"{head}\n{block}\n{gap}{rest}"
    if not text.endswith("\n"):
        text += "\n"
    sep = "" if text.endswith("\n\n") else "\n"
    return f"{text}{sep}{HEADING}\n\n{block}\n"


def write(path, text):
    directory = os.path.dirname(path) or "."
    try:
        mode = os.stat(path).st_mode & 0o7777
    except FileNotFoundError:
        umask = os.umask(0)
        os.umask(umask)
        mode = 0o666 & ~umask
    fd, tmp = tempfile.mkstemp(dir=directory, prefix=".AGENTS.md.", suffix=".tmp")
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="") as f:
            f.write(text)
        os.chmod(tmp, mode)
        os.replace(tmp, path)
    except BaseException:
        if os.path.exists(tmp):
            os.unlink(tmp)
        raise


def install(repo):
    block, version = shipped_block()
    path = agents_path(repo)
    # A symlinked AGENTS.md points at a path the caller never handed us, and
    # writing through it is P0 under the block's own "Writes outside a task's
    # files" rule.
    if os.path.islink(path):
        raise Malformed(f"{path}: is a symlink; refusing to write through it")
    text = read_agents(path)
    new = placed(text, block)
    if new == text:
        print(f"review rules v{version} already current in {path}")
        return
    try:
        write(path, new)
    except OSError as e:
        raise Usage(f"cannot write {path}: {e}")
    print(f"installed review rules v{version} in {path}")


def check(repo):
    block, version = shipped_block()
    path = agents_path(repo)
    text = read_agents(path)
    hint = f"run review-rules.py install {repo}"
    found = None if text is None else find_block(text, path)
    if found is None:
        raise Malformed(f"{path}: no block; shipped is v{version}; {hint}")
    start, stop, have = found
    if text[start:stop] != block:
        edited = " (edited)" if have == version else ""
        raise Malformed(f"{path}: holds v{have}{edited}, shipped is v{version}; {hint}")
    print(f"OK: {path} holds review rules v{version}")


def main(argv=None):
    parser = Parser(prog="review-rules.py", description="Install or check work-issue's review-rules block.")
    sub = parser.add_subparsers(dest="command", required=True, parser_class=Parser)
    for name in ("install", "check"):
        sub.add_parser(name).add_argument("repo")
    args = parser.parse_args(argv)
    try:
        (install if args.command == "install" else check)(args.repo)
    except Malformed as e:
        print(e, file=sys.stderr)
        return 1
    except Usage as e:
        print(e, file=sys.stderr)
        return 3
    return 0


if __name__ == "__main__":
    sys.exit(main())
