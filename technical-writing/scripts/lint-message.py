#!/usr/bin/env python3
"""Check a commit message or PR body against technical-writing's hard rules.

The rules live in references/commit-messages.md and references/pr-descriptions.md.
Step 2's audit is a reading pass, and a reading pass is what misses a hard wrap
or a trailer the harness slipped in (#394), so this does the mechanical part.
It reports and never edits.

    lint-message.py commit FILE [--convention conventional|bare | --log N]
    lint-message.py pr FILE [--title TITLE] [--convention ... | --log N]

FILE may be `-` for stdin. Every mode checks each line for:

  trailers    a `Co-Authored-By:` trailer (any case), a line starting
              `Generated with`, any line holding the robot emoji
  hard wrap   outside fenced code, a non-blank line under a non-blank line,
              unless it opens a block: a list marker, a `|` table row, a
              heading, a blockquote, or a fence. A heading or a fence line is
              one line long, so the line under it is never a continuation,
              and neither is a `Key: value` trailer under another trailer.
              Line length plays no part.

`commit` also checks the subject (line 1) and that line 2 is blank. `pr`
checks the subject rules only on --title. The subject rules: no trailing
period; under conventional, a `type(scope): ` prefix with a lowercase letter
after it; under bare, no type prefix and a capital first letter. A subject
outside 50 to 75 characters prints a `note:` line on stdout and leaves the
exit code alone, since the profile says "roughly".

The convention comes from --convention, or else from the last N subjects of
`git log` in the current directory (--log N, default 12): conventional when
strictly more than half carry a type prefix, else bare.

Exit codes:
    0  clean (notes may still print)
    1  at least one problem, one stderr line each naming its line
    3  usage error, unreadable input, or --log with no git history to read
"""

import argparse
import re
import subprocess
import sys

TYPE_PREFIX_RE = re.compile(r"^[a-z]+(\([^)]*\))?!?: ")
COAUTHOR_RE = re.compile(r"^\s*co-authored-by:", re.I)
FENCE_RE = re.compile(r"^\s*(```|~~~)")
# A line that starts its own block is never a continuation of the line above.
BLOCK_OPEN_RE = re.compile(r"^\s*(?:[-*+][ \t]|\d{1,9}[.)][ \t]|\||#{1,6}(?:[ \t]|$)|>|```|~~~)")
HEADING_RE = re.compile(r"^\s*#{1,6}(?:[ \t]|$)")
# git's trailer shape; a block of these is one trailer per line, not a wrapped sentence.
TRAILER_RE = re.compile(r"^[A-Za-z0-9-]+: \S")
ROBOT = "\U0001F916"


class Parser(argparse.ArgumentParser):
    # argparse exits 2 on bad usage; the repo's validator convention is 3.
    def error(self, message):
        self.print_usage(sys.stderr)
        print(f"{self.prog}: error: {message}", file=sys.stderr)
        sys.exit(3)


def die(message):
    print(f"lint-message: {message}", file=sys.stderr)
    sys.exit(3)


def read_input(path):
    try:
        if path == "-":
            return sys.stdin.buffer.read().decode("utf-8")
        with open(path, encoding="utf-8") as f:
            return f.read()
    except (OSError, UnicodeDecodeError) as e:
        die(f"cannot read {path}: {e}")


def infer_convention(n):
    try:
        out = subprocess.run(
            ["git", "log", f"-n{n}", "--format=%s"],
            capture_output=True, text=True, check=True,
        ).stdout
    except (OSError, subprocess.CalledProcessError) as e:
        die(f"--log needs git history in the current directory, pass --convention instead ({e})")
    subjects = out.splitlines()
    if not subjects:
        # A strict majority of zero would silently pick bare.
        die("--log found no commits to infer from, pass --convention instead")
    conventional = sum(1 for s in subjects if TYPE_PREFIX_RE.match(s))
    return "conventional" if conventional * 2 > len(subjects) else "bare"


def check_subject(subject, convention, where, problems, notes):
    if not subject.strip():
        problems.append(f"{where}: empty subject")
        return
    if subject.endswith("."):
        problems.append(f"{where}: subject ends in a period")
    prefix = TYPE_PREFIX_RE.match(subject)
    if convention == "conventional":
        if not prefix:
            problems.append(f"{where}: no type(scope): prefix under Conventional Commits")
        elif subject[prefix.end():prefix.end() + 1].isupper():
            problems.append(f"{where}: uppercase letter after the type prefix")
    else:
        if prefix:
            problems.append(f"{where}: type prefix in a bare-imperative repo")
        elif subject[:1].islower():
            problems.append(f"{where}: bare subject starts lowercase")
    if not 50 <= len(subject) <= 75:
        notes.append(f"note: {where}: subject is {len(subject)} characters, outside the rough 50 to 75")


def check_lines(lines, first, problems):
    """Check lines[first:]; the line before `first` counts as blank."""
    in_fence = False
    prev_blank = True
    prev_trailer = False
    for i, line in enumerate(lines):
        number = i + 1
        if COAUTHOR_RE.match(line):
            problems.append(f"line {number}: Co-Authored-By trailer")
        if line.lstrip().startswith("Generated with"):
            problems.append(f"line {number}: \"Generated with\" footer")
        if ROBOT in line:
            problems.append(f"line {number}: robot-emoji sign-off")
        if i < first:
            continue
        blank = not line.strip()
        trailer = bool(TRAILER_RE.match(line))
        fence = bool(FENCE_RE.match(line))
        if fence:
            in_fence = not in_fence
        elif (not in_fence and not blank and not prev_blank
              and not BLOCK_OPEN_RE.match(line) and not (trailer and prev_trailer)):
            problems.append(f"line {number}: hard wrap, this line continues the one above")
        # A heading or fence line closes its own block, so the next line starts fresh.
        prev_blank = blank or fence or bool(HEADING_RE.match(line))
        prev_trailer = trailer


def main():
    parser = Parser(prog="lint-message.py", description=__doc__.split("\n")[0])
    sub = parser.add_subparsers(dest="mode", required=True, parser_class=Parser)
    for mode in ("commit", "pr"):
        p = sub.add_parser(mode)
        p.add_argument("file")
        if mode == "pr":
            p.add_argument("--title")
        group = p.add_mutually_exclusive_group()
        group.add_argument("--convention", choices=("conventional", "bare"))
        group.add_argument("--log", type=int, metavar="N")
    args = parser.parse_args()
    if args.log is not None and args.log < 1:
        parser.error("--log takes a positive count")

    lines = read_input(args.file).splitlines()
    problems, notes = [], []
    needs_subject = args.mode == "commit" or args.title is not None
    convention = None
    if needs_subject:
        convention = args.convention or infer_convention(args.log or 12)

    if args.mode == "commit":
        check_subject(lines[0] if lines else "", convention, "line 1", problems, notes)
        if len(lines) > 1 and lines[1].strip():
            # Reported once here, so check_lines starts past it.
            problems.append("line 2: no blank line after the subject")
        check_lines(lines, 2, problems)
    else:
        if args.title is not None:
            check_subject(args.title, convention, "title", problems, notes)
        check_lines(lines, 0, problems)

    for note in notes:
        print(note)
    for problem in problems:
        print(problem, file=sys.stderr)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
