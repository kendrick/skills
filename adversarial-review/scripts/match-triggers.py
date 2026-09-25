#!/usr/bin/env python3
"""Match a diff's added/removed lines against trigger-table.md's own signals,
instead of a grep hand-copied from the table's prose.

Until #157 the table shipped its own recipe (`grep -Ei '\\bsignal\\b'`) for
each reader to fill in by hand. Filled in for `round(`, the recipe is
`grep -Ei '\\bround(\\b'`, which exits 2 on `total = round(amount, 2)`
instead of matching it: the literal `(` opens a group nothing closes (#114).
Each hand rebuild also had to get whole-word matching, the `_` prefix rule,
and the unit-suffix rule right on its own, and two runs that each got one
slightly wrong disagreed with each other as often as with the table. This
script parses the table once, so every run and every skill that shells out
to it shares one matcher.

    match-triggers.py rows [--only 1,2,4] [--table PATH] < diff

Exit codes: 0 with matches printed (possibly none), 1 on a table it can't
parse, 3 on usage or unreadable input—the convention check-territories.py
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

# The unit list comes from the table's matching paragraph, so a unit added
# to the table's prose takes effect with no code change. A hardcoded
# `px`/`rem`/`em` set inverted row 1's `ms`, `bytes`, and `kb`: `ms = 3`
# matched as a whole word, and `500ms` never matched.
# The capture must open on a backtick: the table also quotes this sentence's
# opening words elsewhere, and a looser match would read `<n> <name>` off
# that quote as a unit once the real sentence was deleted.
UNIT_LIST_RE = re.compile(r"The unit suffixes are (`[^.]*)\.")
# Either count may be omitted, and an omitted count means 1.
HUNK_RE = re.compile(r"^@@ -\d+(?:,(\d+))? \+\d+(?:,(\d+))? @@")

HEADER_RE = re.compile(r"^\|\s*#\s*\|\s*Row\s*\|", re.IGNORECASE)
SEPARATOR_RE = re.compile(r"^\|[\s:-]+\|")
BACKTICK_RE = re.compile(r"`([^`]+)`")


class TableError(Exception):
    """The table file exists and was read, but its rows don't parse."""


def _is_word_char(ch):
    return bool(ch) and re.match(r"\w", ch, re.UNICODE) is not None


def compile_signal(signal, units):
    """One compiled pattern per table signal, applying the table's rules
    under "Match signals as whole words or identifiers, case-insensitively":
    whole word or identifier; a trailing `_` is a prefix; a signal in `units`
    matches only straight after a digit. `re.escape` runs first, so a signal
    like `float(` or `CHECK (` can't turn its own punctuation into regex
    syntax."""
    if signal.lower() in units:
        # Digit immediately before, no space allowed: code writes the literal
        # as `12px`, `"500ms"`, `10kb`, and a space would let prose like
        # `3 em dashes` match row 6.
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


def parse_units(text):
    """The lowercased unit suffixes the table's "The unit suffixes are ..."
    sentence names in backticks. Raises TableError if the sentence is
    missing or names no unit."""
    m = UNIT_LIST_RE.search(text)
    units = BACKTICK_RE.findall(m.group(1)) if m else []
    if not units:
        raise TableError("no 'The unit suffixes are `...`.' sentence found")
    return {u.lower() for u in units}


def parse_table(text):
    """Rows in table order, as {"number": int, "name": str, "patterns": [...]}.
    Raises TableError if the unit list or the row-table header is missing,
    or a row's own shape (number, name, signals cell) can't be read."""
    units = parse_units(text)
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
                "patterns": [compile_signal(s, units) for s in signals],
            }
        )

    if not rows:
        raise TableError("table header found but no data rows followed")
    return rows


def diff_content_lines(diff_text):
    """Added and removed line bodies, without the one-character prefix.
    Context lines and file headers are left out. Inside a counted hunk every
    `+`/`-` line is content; outside one, `--- `/`+++ ` lines are file
    headers and every other `+`/`-` line is content."""
    lines = []
    old_left = new_left = 0
    for raw in diff_text.splitlines():
        in_hunk = old_left > 0 or new_left > 0
        # The hunk's counts say where the hunk ends. A prefix test can't: a
        # removed SQL comment `-- CHECK (a > 0)` prints as `--- CHECK (a > 0)`,
        # which reads as a file header.
        if in_hunk and raw[:1] in ("+", "-", " ", "", "\\"):
            if raw.startswith("+"):
                lines.append(raw[1:])
                new_left -= 1
            elif raw.startswith("-"):
                lines.append(raw[1:])
                old_left -= 1
            elif raw[:1] in (" ", ""):
                old_left -= 1
                new_left -= 1
            continue
        # Any other line ends the hunk early, so a header that overstates its
        # counts can't swallow the next file's `---`/`+++` lines as content.
        old_left = new_left = 0
        hunk = HUNK_RE.match(raw)
        if hunk:
            old_left = int(hunk.group(1) or 1)
            new_left = int(hunk.group(2) or 1)
            continue
        # Outside a counted hunk: a bare `@@`, or stdin with no `@@` at all,
        # like the `printf '+total = round(amount, 2)\n'` in #157's criteria.
        if raw.startswith("+++ ") or raw.startswith("--- "):
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


class _Parser(argparse.ArgumentParser):
    # argparse exits 2 on a usage error, and the validator convention says 3.
    # add_subparsers builds each subparser from type(self), so `rows --bogus`
    # reaches this override too.
    def error(self, message):
        self.print_usage(sys.stderr)
        sys.stderr.write(f"{self.prog}: error: {message}\n")
        sys.exit(3)


def parse_args(argv=None):
    ap = _Parser(
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
