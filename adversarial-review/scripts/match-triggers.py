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
    match-triggers.py lines [--only 1,2,4] [--table PATH] < diff
    match-triggers.py derive <merge_base_sha> --exclude PATH [--depth 0|1|2]
                             [--table PATH]

`rows` prints `<n> <name>` once per matched row. `lines` prints the evidence
behind it, one `<n> <name>\t<path>\t<signal>\t<sign><body>` line per matched
row per changed line, for a caller that has to read each match (#120).
`derive`, run from the repo's work tree, prints the `changed_files`, `depth`,
`territories`, and `derivation` fields of adversarial-review's scope.json as
one JSON object (#406): Step 2's territories, computed once instead of by hand
each run.

Exit codes: 0 with matches printed (possibly none), 1 on a table it can't
parse, 3 on usage or unreadable input—the convention check-territories.py
sets in this same directory.
"""
import argparse
import importlib.util
import json
import os
import re
import subprocess
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
# Under `color.ui=always`, git opens every diff line with an SGR escape, so
# HUNK_RE never sees `@@` and the prefix tests never see `+` or `-`. An
# unstripped colored diff matches nothing and still exits 0, which callers
# read as no triggers: adversarial-review puts every file in `general` alone,
# and work-issue records `fired: no`. Stripping here covers every caller at
# once. A `--no-color` flag instead is one more string each caller must keep.
ANSI_CSI_RE = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")

HEADER_RE = re.compile(r"^\|\s*#\s*\|\s*Row\s*\|", re.IGNORECASE)
TIER_HEADING_RE = re.compile(r"^##\s+Model tier\s*$", re.IGNORECASE)
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
    """Rows in table order, as {"number": int, "name": str, "signals": [...],
    "patterns": [...]}, where `signals[i]` is the table spelling `patterns[i]`
    was compiled from.
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
                "signals": signals,
                "patterns": [compile_signal(s, units) for s in signals],
            }
        )

    if not rows:
        raise TableError("table header found but no data rows followed")
    return rows


def _header_path(raw, strip):
    """The path in a `--- `/`+++ ` header, minus git's `a/` or `b/` prefix.
    A quoted path stays quoted, and anything after a tab (git's marker on a
    path with spaces, or a timestamp from plain diff) is dropped so it can't
    add a column to `lines` output."""
    path = raw[4:].split("\t", 1)[0]
    return path[len(strip):] if path.startswith(strip) else path


def diff_content_records(diff_text):
    """Added and removed lines as (path, sign, body), sign being `+` or `-`
    and body the line without it. Context lines and file headers are left
    out. Inside a counted hunk every `+`/`-` line is content; outside one,
    `--- `/`+++ ` lines are file headers and every other `+`/`-` line is
    content. `path` comes from the `+++ ` header, or from the `--- ` header
    when a deleted file's `+++ ` is /dev/null, and is `-` before any header."""
    records = []
    path = old_path = "-"
    old_left = new_left = 0
    for raw in diff_text.splitlines():
        raw = ANSI_CSI_RE.sub("", raw)
        in_hunk = old_left > 0 or new_left > 0
        # The hunk's counts say where the hunk ends. A prefix test can't: a
        # removed SQL comment `-- CHECK (a > 0)` prints as `--- CHECK (a > 0)`,
        # which reads as a file header.
        if in_hunk and raw[:1] in ("+", "-", " ", "", "\\"):
            if raw.startswith("+"):
                records.append((path, "+", raw[1:]))
                new_left -= 1
            elif raw.startswith("-"):
                records.append((path, "-", raw[1:]))
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
        if raw.startswith("--- "):
            old_path = _header_path(raw, "a/")
            continue
        if raw.startswith("+++ "):
            new_path = _header_path(raw, "b/")
            path = old_path if new_path == "/dev/null" else new_path
            continue
        if raw.startswith("+") or raw.startswith("-"):
            records.append((path, raw[0], raw[1:]))
    return records


def diff_content_lines(diff_text):
    """Added and removed line bodies, without the one-character prefix.
    Derived from diff_content_records so `rows` and `lines` can never parse
    a diff two different ways."""
    return [body for _, _, body in diff_content_records(diff_text)]


def matched_rows(rows, content_lines):
    hits = []
    for row in rows:
        if any(p.search(line) for p in row["patterns"] for line in content_lines):
            hits.append(row)
    return hits


def first_signal(row, body):
    """The first of `row`'s signals, in table order and table spelling, whose
    pattern matches `body`, or None."""
    for signal, pattern in zip(row["signals"], row["patterns"]):
        if pattern.search(body):
            return signal
    return None


def load_rows_and_diff(args):
    """The table's rows, narrowed by `--only`, and the diff text on stdin,
    as (rows, diff_text, None); or (None, None, exit_code) after writing
    the reason to stderr."""
    try:
        with open(args.table, encoding="utf-8") as f:
            table_text = f.read()
    except OSError as e:
        sys.stderr.write(f"match-triggers: {args.table}: {e}\n")
        return None, None, 3

    try:
        rows = parse_table(table_text)
    except TableError as e:
        sys.stderr.write(f"match-triggers: {args.table}: {e}\n")
        return None, None, 1

    if args.only is not None:
        try:
            wanted = {int(n) for n in args.only.split(",")}
        except ValueError:
            sys.stderr.write(f"match-triggers: --only: not a comma-separated "
                              f"list of integers: {args.only!r}\n")
            return None, None, 3
        unknown = wanted - {row["number"] for row in rows}
        if unknown:
            sys.stderr.write(
                f"match-triggers: --only: no such row number(s): "
                f"{', '.join(str(n) for n in sorted(unknown))}\n"
            )
            return None, None, 3
        rows = [row for row in rows if row["number"] in wanted]

    try:
        diff_text = sys.stdin.read()
    except OSError as e:
        sys.stderr.write(f"match-triggers: stdin: {e}\n")
        return None, None, 3
    return rows, diff_text, None


def cmd_rows(args):
    rows, diff_text, code = load_rows_and_diff(args)
    if code is not None:
        return code
    content_lines = diff_content_lines(diff_text)
    for row in matched_rows(rows, content_lines):
        print(f"{row['number']} {row['name']}")
    return 0


def cmd_lines(args):
    rows, diff_text, code = load_rows_and_diff(args)
    if code is not None:
        return code
    for path, sign, body in diff_content_records(diff_text):
        for row in rows:
            signal = first_signal(row, body)
            if signal is not None:
                print(f"{row['number']} {row['name']}\t{path}\t{signal}"
                      f"\t{sign}{body}")
    return 0


# Roster cap per depth, from the trigger table's "Cap the roster" step.
DEPTH_CAPS = {0: 2, 1: 4, 2: 6}
# Rows 1 to 3 are the high-stakes rows (#406, settled answer 2): the rows the
# tier table puts on opus and that Depth 2 "raises".
HIGH_STAKES_NUMBERS = {1, 2, 3}
# Depth 2's file-count trigger fires on more than this many changed files
# after exclusions (#406, settled answer 1).
DEPTH2_FILE_COUNT = 40


def parse_tiers(text):
    """{class name: base tier} from the first table under `## Model tier`.
    Each first cell lists row names separated by commas; `general alone`
    means the name `general`. Raises TableError if the section or its table
    is missing, since `derive` has no other source for a tier."""
    lines = text.splitlines()
    start = next(
        (i for i, line in enumerate(lines) if TIER_HEADING_RE.match(line)), None
    )
    if start is None:
        raise TableError("no '## Model tier' section found")
    table = []
    for line in lines[start + 1 :]:
        if line.startswith("## "):
            break
        if line.strip().startswith("|"):
            table.append(line.strip())
        elif table:
            break
    if len(table) < 3 or not SEPARATOR_RE.match(table[1]):
        raise TableError("'## Model tier' has no header, separator, and rows")
    tiers = {}
    for line in table[2:]:
        cells = [c.strip() for c in line.strip("|").split("|")]
        if len(cells) < 2 or not cells[1]:
            raise TableError(f"tier row has no tier: {line!r}")
        for name in cells[0].split(","):
            name = re.sub(r"\s+alone$", "", name.strip())
            if name:
                tiers[name] = cells[1]
    return tiers


def load_check_territories():
    """check-territories.py, loaded as a module so `derive` excludes exactly
    what `intersect --exclude` does. Its hyphenated name rules out a plain
    import, and it runs main() only under __main__, so loading it is inert."""
    path = os.path.join(SCRIPT_DIR, "check-territories.py")
    spec = importlib.util.spec_from_file_location("check_territories", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _git(argv):
    """git's stdout, or raise OSError carrying git's stderr."""
    try:
        proc = subprocess.run(
            ["git", "-c", "core.quotePath=false", "--literal-pathspecs"] + argv,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
    except OSError as e:
        raise OSError(f"git: {e}")
    if proc.returncode != 0:
        raise OSError(proc.stderr.strip() or f"git exited {proc.returncode}")
    return proc.stdout


def derive_scope(rows, tiers, changed_files, file_diffs, depth_override):
    """The four scope.json fields as a dict. `file_diffs` maps each changed
    file to its own `git diff <sha>..HEAD -- <file>` text."""
    general = next((r for r in rows if r["name"] == "general"), None)
    if general is None:
        raise TableError("no 'general' row found")
    number = {r["name"]: r["number"] for r in rows}
    missing = [r["name"] for r in rows if r["name"] not in tiers]
    if missing:
        raise TableError(f"no model tier for row(s): {', '.join(missing)}")

    derivation = []
    for path in changed_files:
        hits = [r for r in matched_rows(rows, diff_content_lines(file_diffs[path]))
                if r is not general]
        derivation.append({
            "file": path,
            "matched_rows": [r["name"] for r in hits] + ["general"],
            # First match in table order decides ownership
            # (ledger row 21); match count never enters into it.
            "territory": hits[0]["name"] if hits else "general",
        })

    hit_numbers = {number[m] for rec in derivation for m in rec["matched_rows"]}
    if depth_override is not None:
        depth = depth_override
    elif hit_numbers <= {general["number"]}:
        # Read top-down, Depth 0's row wins over Depth 2's file count: a big
        # diff with nothing above general has nothing to suspect.
        depth = 0
    elif (len(changed_files) > DEPTH2_FILE_COUNT
          or HIGH_STAKES_NUMBERS <= hit_numbers):
        depth = 2
    else:
        depth = 1

    owners = {}
    for rec in derivation:
        owners.setdefault(rec["territory"], []).append(rec)
    roster = [{"name": name, "files": recs}
              for name, recs in sorted(owners.items(), key=lambda kv: number[kv[0]])]
    # Over the cap, the highest-numbered territory merges into the one just
    # below it (#406, settled answer 3). The survivor keeps its name.
    while len(roster) > DEPTH_CAPS[depth]:
        last = roster.pop()
        roster[-1]["files"].extend(last["files"])

    order = {path: i for i, path in enumerate(changed_files)}
    territories = []
    for t in roster:
        files = sorted(t["files"], key=lambda rec: order[rec["file"]])
        for rec in files:
            rec["territory"] = t["name"]
        classes = sorted({m for rec in files for m in rec["matched_rows"]},
                         key=lambda name: number[name])
        tier = tiers[classes[0]]
        if depth == 0 and tier == "opus":
            tier = "sonnet"
        elif depth == 2 and number[classes[0]] in HIGH_STAKES_NUMBERS:
            tier = "opus"
        territories.append({
            "name": t["name"],
            "entries": [rec["file"] for rec in files],
            "classes": classes,
            "model_tier": tier,
        })

    return {
        "changed_files": changed_files,
        "depth": depth,
        "territories": territories,
        "derivation": derivation,
    }


def cmd_derive(args):
    try:
        with open(args.table, encoding="utf-8") as f:
            table_text = f.read()
    except OSError as e:
        sys.stderr.write(f"match-triggers: {args.table}: {e}\n")
        return 3
    try:
        rows = parse_table(table_text)
        tiers = parse_tiers(table_text)
    except TableError as e:
        sys.stderr.write(f"match-triggers: {args.table}: {e}\n")
        return 1

    # Step 1 always writes excluded.txt, so a missing one at Step 2 is a wrong
    # path. Read as empty, as `intersect` reads it, it would let dist/ in.
    if not os.path.isfile(args.exclude):
        sys.stderr.write(f"match-triggers: --exclude: no such file: "
                         f"{args.exclude}\n")
        return 3
    ct = load_check_territories()
    excludes = ct.load_excludes(args.exclude)

    sha = args.merge_base_sha
    try:
        names = _git(["diff", "--name-only", f"{sha}..HEAD"]).splitlines()
        changed_files = [p for p in names if p and not ct.is_excluded(p, excludes)]
        # One diff per file, so each file's rows are exactly what
        # `git diff <sha>..HEAD -- <file> | match-triggers.py rows` prints.
        file_diffs = {
            p: _git(["diff", "--no-color", "--no-ext-diff", f"{sha}..HEAD", "--", p])
            for p in changed_files
        }
    except OSError as e:
        sys.stderr.write(f"match-triggers: {e}\n")
        return 3

    try:
        scope = derive_scope(rows, tiers, changed_files, file_diffs, args.depth)
    except TableError as e:
        sys.stderr.write(f"match-triggers: {args.table}: {e}\n")
        return 1
    print(json.dumps(scope, indent=2))
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

    for name, func, help_text in (
        ("rows", cmd_rows, "print rows a diff on stdin matches"),
        ("lines", cmd_lines,
         "print each matched changed line with its path and signal"),
    ):
        cmd = sub.add_parser(name, help=help_text)
        cmd.add_argument(
            "--only",
            metavar="N,N,...",
            help="restrict to these row numbers, comma-separated",
        )
        cmd.add_argument(
            "--table",
            metavar="PATH",
            default=DEFAULT_TABLE_PATH,
            help=f"trigger table to read (default: {DEFAULT_TABLE_PATH})",
        )
        cmd.set_defaults(func=func)

    # Outside the loop so it takes no --only: a narrowed table would move
    # files to a different owner.
    derive = sub.add_parser(
        "derive", help="print scope.json's territories for <sha>..HEAD")
    derive.add_argument("merge_base_sha")
    derive.add_argument("--exclude", required=True, metavar="PATH",
                        help="Step 1's excluded.txt; must exist")
    derive.add_argument("--depth", type=int, choices=(0, 1, 2),
                        help="pin the depth (--fast is 0, --deep is 2)")
    derive.add_argument("--table", metavar="PATH", default=DEFAULT_TABLE_PATH,
                        help=f"trigger table to read (default: {DEFAULT_TABLE_PATH})")
    derive.set_defaults(func=cmd_derive)

    return ap.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
