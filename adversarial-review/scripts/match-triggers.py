#!/usr/bin/env python3
"""Match a diff's added/removed lines against trigger-table.md's own signals,
instead of a grep hand-copied from the table's prose.

The table ships its own recipe (`grep -Ei '\\bround(\\b'`) as a worked example
of the matching rules, not as the actual command to run: a literal `(` inside
a `\\b...\\b` word-boundary grep is invalid, and that recipe exits 2 on `total =
round(amount, 2)` instead of matching it (#114). Copying the recipe by hand
into a real invocation just moves the bug: every rebuild has to independently
get whole-word matching, the `_` prefix rule, and the unit-suffix rule right,
and two runs that each got it *slightly* wrong disagree with each other as
often as they agree with the table. This script parses the table once, so
every run and every skill that shells out to it shares one matcher instead of
one grep per reader.

    match-triggers.py rows [--only 1,2,4] [--table PATH] < diff

Exit codes: 0 with matches printed (possibly none), 1 on a table it can't
parse, 3 on usage or unreadable input — the convention check-territories.py
sets in this same directory.
"""
import argparse
import os
import re
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DEFAULT_TABLE_PATH = os.path.normpath(
    os.path.join(SCRIPT_DIR, "..", "references", "trigger-table.md")
)

# The table's own prose names only these three as the unit-suffix case: a
# unit matches the number in front of it, not the identifier it would
# otherwise collide with (`\bpx\b` finds `const px`, never `padding: 12px`).
# This set is read off the rule in trigger-table.md:11, not off any one row,
# so it applies to any row that happens to carry one of these three signals —
# row 6 today, whichever row picks them up next.
UNIT_SUFFIX_SIGNALS = {"px", "rem", "em"}

HEADER_RE = re.compile(r"^\|\s*#\s*\|\s*Row\s*\|", re.IGNORECASE)
SEPARATOR_RE = re.compile(r"^\|[\s:-]+\|")
BACKTICK_RE = re.compile(r"`([^`]+)`")


class TableError(Exception):
    """The table file exists and was read, but its rows don't parse."""


def _is_word_char(ch):
    return bool(ch) and re.match(r"\w", ch, re.UNICODE) is not None


def compile_signal(signal):
    """One compiled pattern per table signal, applying trigger-table.md:11's
    rules: whole word/identifier, case-insensitive; a trailing `_` is a
    prefix; `px`/`rem`/`em` match after a digit. `re.escape` first, so a
    signal like `float(` or `CHECK (` can't reinterpret its own punctuation
    as regex syntax."""
    if signal.lower() in UNIT_SUFFIX_SIGNALS:
        return re.compile(r"\d(?:" + re.escape(signal) + r")\b", re.IGNORECASE)

    escaped = re.escape(signal)
    is_prefix = signal.endswith("_")
    # Word-char boundaries are computed manually rather than with \b: \b
    # already treats '_' as a word character, so `\bmax_\b` never matches
    # `max_retries` at all, and a table signal isn't always alphanumeric
    # (`* 100`, `CHECK (`) where \b's meaning is undefined at that edge.
    left = r"(?<!\w)" if _is_word_char(signal[0]) else ""
    if is_prefix:
        right = ""  # prefix match: nothing constrains what follows
    else:
        right = r"(?!\w)" if _is_word_char(signal[-1]) else ""
    return re.compile(left + escaped + right, re.IGNORECASE)


def parse_table(text):
    """Rows in table order, as {"number": int, "name": str, "patterns": [...]}.
    Raises TableError if no row-table header is found, or a row's own shape
    (number, name, signals cell) can't be read."""
    lines = text.splitlines()
    header_idx = next(
        (i for i, line in enumerate(lines) if HEADER_RE.match(line)), None
    )
    if header_idx is None:
        raise TableError("no '| # | Row | ...' table header found")

    body = lines[header_idx + 1 :]
    if not body or not SEPARATOR_RE.match(body[0]):
        raise TableError("table header has no '|---|...' separator row")

    rows = []
    for line in body[1:]:
        stripped = line.strip()
        if not stripped.startswith("|"):
            break  # blank line or prose: the table ended
        cells = [c.strip() for c in stripped.strip("|").split("|")]
        if len(cells) < 3:
            raise TableError(f"row has too few columns: {line!r}")
        try:
            number = int(cells[0])
        except ValueError:
            raise TableError(f"row number isn't an integer: {cells[0]!r}")
        name = cells[1]
        if not name:
            raise TableError(f"row {number} has no name")
        signals = BACKTICK_RE.findall(cells[2])
        rows.append(
            {
                "number": number,
                "name": name,
                # Row 7 ("general") names no backticked signal — "any changed
                # file" is prose, not a grep target — so it never matches
                # here. adversarial-review adds it to every file by its own
                # rule, not by anything this script prints.
                "patterns": [compile_signal(s) for s in signals],
            }
        )

    if not rows:
        raise TableError("table header found but no data rows followed")
    return rows


def diff_content_lines(diff_text):
    """Added and removed line bodies only — never context lines, and never
    the `+++`/`---` file-header lines, which look like +/- content but name
    a path rather than a change."""
    lines = []
    for raw in diff_text.splitlines():
        if raw.startswith("+++") or raw.startswith("---"):
            continue
        if raw.startswith("+") or raw.startswith("-"):
            lines.append(raw[1:])
    return lines


def matched_rows(rows, content_lines):
    hits = []
    for row in rows:
        if any(p.search(line) for p in row["patterns"] for line in content_lines):
            hits.append(row)
    return hits


def cmd_rows(args):
    try:
        with open(args.table, encoding="utf-8") as f:
            table_text = f.read()
    except OSError as e:
        sys.stderr.write(f"match-triggers: {args.table}: {e}\n")
        return 3

    try:
        rows = parse_table(table_text)
    except TableError as e:
        sys.stderr.write(f"match-triggers: {args.table}: {e}\n")
        return 1

    if args.only is not None:
        try:
            wanted = {int(n) for n in args.only.split(",")}
        except ValueError:
            sys.stderr.write(f"match-triggers: --only: not a comma-separated "
                              f"list of integers: {args.only!r}\n")
            return 3
        unknown = wanted - {row["number"] for row in rows}
        if unknown:
            sys.stderr.write(
                f"match-triggers: --only: no such row number(s): "
                f"{', '.join(str(n) for n in sorted(unknown))}\n"
            )
            return 3
        rows = [row for row in rows if row["number"] in wanted]

    try:
        diff_text = sys.stdin.read()
    except OSError as e:
        sys.stderr.write(f"match-triggers: stdin: {e}\n")
        return 3

    content_lines = diff_content_lines(diff_text)
    for row in matched_rows(rows, content_lines):
        print(f"{row['number']} {row['name']}")
    return 0


def parse_args(argv=None):
    ap = argparse.ArgumentParser(
        description="Match a diff's changed lines against trigger-table.md's "
        "own signals."
    )
    sub = ap.add_subparsers(dest="command", required=True)

    rows = sub.add_parser("rows", help="print rows a diff on stdin matches")
    rows.add_argument(
        "--only",
        metavar="N,N,...",
        help="restrict to these row numbers, comma-separated",
    )
    rows.add_argument(
        "--table",
        metavar="PATH",
        default=DEFAULT_TABLE_PATH,
        help=f"trigger table to read (default: {DEFAULT_TABLE_PATH})",
    )
    rows.set_defaults(func=cmd_rows)

    return ap.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
