#!/usr/bin/env python3
"""Report code-span paths in a draft that don't resolve in this repository.

Step 2's self-check says every path is real at this commit, and a reading pass
is what misses a path a later edit renamed (#401). This does the mechanical
part. It reports and never edits. It is partial by design: it checks paths, and
with --gh issue numbers. Symbols, flags, and counts stay with the writer.

    check-refs.py FILE [--gh]

FILE may be `-` for stdin. Only inline code spans outside fenced blocks are
read. A span is a path by its shape, never by whether it exists: it holds a
`/` or ends in a dot and one to five letters, and holds no whitespace, `://`,
`#`, `<`, `*`, or `?`. A trailing `:<digits>` line suffix and a trailing `/`
are dropped before lookup. Bare paths outside code spans are not checked, and
a path the text proposes as new work reads as unresolved; the writer decides.

A path resolves when `git ls-files --cached --others --exclude-standard` lists
it, or lists a file under it. Paths resolve against the top level of the
repository the current directory sits in, so a body piped on stdin needs no
directory of its own.

With --gh, each distinct bare `#N` in prose (outside code spans and fences, not
preceded by a word character or `/`, so `owner/repo#12` is skipped) is looked
up once with `gh issue view`, then `gh pr view`: the writer means "this
reference exists", and a PR number is as good as an issue's. Without --gh the
script never runs `gh`.

Exit codes:
    0  every reference resolves
    1  at least one doesn't, one stderr line each naming its input line
    3  usage error, unreadable input, a cwd outside any git repository, or
       --gh with `gh` missing or failing for a reason other than not found
"""

import argparse
import re
import subprocess
import sys

# Fence reading adapted from lint-message.py, not vendored: the regexes match it
# and the open/close loop is rewritten as a generator, so a fence fix there has
# to be carried here by hand. That keeps each script copy-in portable.
FENCE_RE = re.compile(r"^\s*(`{3,}|~{3,})(.*)$")
# A list marker can only precede an opener, so "- ```" inside a fence is code, not a closer.
OPEN_RE = re.compile(r"^\s*(?:(?:[-*+]|\d{1,9}[.)])[ \t]+)?(`{3,}|~{3,})(.*)$")

SPAN_RE = re.compile(r"(?<!`)(`+)(?!`)(.+?)(?<!`)\1(?!`)")
LINE_SUFFIX_RE = re.compile(r":\d+$")
EXTENSION_RE = re.compile(r".\.[A-Za-z]{1,5}$")
NOT_PATH = re.compile(r"\s|://|[#<*?]")
BARE_ISSUE_RE = re.compile(r"(?<![\w/])#(\d+)\b")
NOT_FOUND_RE = re.compile(r"could not resolve|not found", re.I)


class Parser(argparse.ArgumentParser):
    # argparse exits 2 on bad usage; the repo's validator convention is 3.
    def error(self, message):
        self.print_usage(sys.stderr)
        print(f"{self.prog}: error: {message}", file=sys.stderr)
        sys.exit(3)


def die(message):
    print(f"check-refs: {message}", file=sys.stderr)
    sys.exit(3)


def read_input(path):
    try:
        if path == "-":
            return sys.stdin.buffer.read().decode("utf-8")
        with open(path, encoding="utf-8") as f:
            return f.read()
    except (OSError, UnicodeDecodeError) as e:
        die(f"cannot read {path}: {e}")


def tracked_paths():
    """Every tracked or untracked-but-not-ignored path, and every directory above one."""
    try:
        top = subprocess.run(["git", "rev-parse", "--show-toplevel"],
                             capture_output=True, text=True, check=True).stdout.strip()
        listing = subprocess.run(
            ["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard"],
            capture_output=True, text=True, check=True, cwd=top,
            errors="surrogateescape").stdout
    except (OSError, subprocess.CalledProcessError) as e:
        die(f"needs a git repository in the current directory ({e})")
    files = {p for p in listing.split("\0") if p}
    dirs = {"/".join(p.split("/")[:i]) for p in files for i in range(1, p.count("/") + 1)}
    return files | dirs


def prose_lines(lines):
    """Yield (number, line) for each line outside a fenced block."""
    open_fence = None  # the opening run, e.g. "````"; None outside a fence
    for number, line in enumerate(lines, 1):
        # CommonMark: a closer repeats the opener's character, is at least as long,
        # and carries no info string. A bare toggle closes a four-backtick example
        # at the three-backtick fence nested inside it.
        if open_fence is None:
            m = OPEN_RE.match(line)
            # A backtick info string can't hold a backtick, so "```code``` text" is inline code.
            if m and not (m.group(1)[0] == "`" and "`" in m.group(2)):
                open_fence = m.group(1)
                continue
            yield number, line
        else:
            m = FENCE_RE.match(line)
            if (m and m.group(1)[0] == open_fence[0]
                    and len(m.group(1)) >= len(open_fence) and not m.group(2).strip()):
                open_fence = None


def as_path(span):
    """The lookup key for a span that has a path's shape, else None."""
    span = span.strip()
    if not span or NOT_PATH.search(span):
        return None
    key = re.sub(r"^(\./)+", "", LINE_SUFFIX_RE.sub("", span)).rstrip("/")
    if key and ("/" in span or EXTENSION_RE.search(key)):
        return key
    return None


def issue_exists(number):
    for kind in ("issue", "pr"):
        try:
            run = subprocess.run(["gh", kind, "view", number], capture_output=True,
                                 text=True, timeout=30)
        except (OSError, subprocess.TimeoutExpired) as e:
            die(f"--gh could not run gh ({e})")
        if run.returncode == 0:
            return True
        if not NOT_FOUND_RE.search(run.stderr):
            die(f"gh {kind} view {number} failed, so #{number} is unchecked: {run.stderr.strip()}")
    return False


def main():
    parser = Parser(prog="check-refs.py", description=__doc__.split("\n")[0])
    parser.add_argument("file")
    parser.add_argument("--gh", action="store_true")
    args = parser.parse_args()

    lines = read_input(args.file).splitlines()
    repo_paths = tracked_paths()
    problems, seen, issue_found = [], set(), {}
    for number, line in prose_lines(lines):
        for m in SPAN_RE.finditer(line):
            key = as_path(m.group(2))
            if key and key not in repo_paths and (number, key) not in seen:
                seen.add((number, key))
                problems.append(f"line {number}: {key} does not resolve in this repository")
        if args.gh:
            for m in BARE_ISSUE_RE.finditer(SPAN_RE.sub(" ", line)):
                n = m.group(1)
                if n not in issue_found:
                    issue_found[n] = issue_exists(n)
                    if not issue_found[n]:
                        problems.append(f"line {number}: #{n} is not an issue or pull request here")

    for problem in problems:
        print(problem, file=sys.stderr)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
