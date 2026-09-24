#!/usr/bin/env python3
"""Prove that the lanes of a work-wave own disjoint paths, both from each
other and from every in-flight work-issue run, before any lane is dispatched.

    work-wave/scripts/check-footprints.py --lane issue-N=PATH \\
        --lane issue-M=PATH [...] [--runs DIR]

Each lane runs its own work-issue in its own worktree, and each work-issue
runs check-inflight.py at its own gate. Those gates can't close the gap this
script closes. check-inflight.py skips a sibling whose plan has no `## Waves`
table yet, and N lanes dispatched in one message all write their tables
within seconds of each other. So every lane's gate can pass against siblings
that haven't written a table yet. This script holds every lane's footprint at
once, so it has to run before dispatch.

A lane PATH takes one of two shapes. A plan with a `## Waves` heading is read
through its table, which is what a lane's RUN_DIR/plan.md holds after it
builds. Anything else is a bare list, one repo-relative path per line, which
is what work-wave writes before any lane exists. One script reads both, so
the pre-dispatch proof and the post-build re-check are the same command over
different paths.

--runs names work-issue's run directory. Every subdirectory in it, except
`closed/` and any directory named after a lane, is an in-flight run whose
plan.md table is compared against every lane. The script skips the lane-named
directories because each holds the plan its lane's --lane path comes from:
every returned lane's at the post-build re-check, and an already-started
lane's before dispatch, since its resume builds from that copy and not from
the source plan. Compared as a run, a lane always overlaps itself.

Output on a pass: one `footprint: issue-N <k> paths` line per lane, then one
`pair: issue-N issue-M` line for each pair of lanes, which is C(N,2) lines,
then `OK: <n> lanes disjoint (checked <r> in-flight runs)`. Lanes print in
ascending issue order whatever order the flags came in, so two runs over one
wave print the same lines. <r> counts only the runs whose tables were
compared, so a lane-named directory never adds to it.

An in-flight run without a readable, parseable table fails the proof. It
prints `unchecked: issue-M has no ## Waves table` on stderr, and the exit is
1 even when every footprint compared is disjoint. Skipping such a run once
let an overlap through: Codex finding 1 on PR #141 put a lane owning
src/a.py beside a tableless run whose plan said `Files: src/a.py`, and the
proof passed. A missing table is what the lanes' own gates skip over, so
skipping it here reopened the race this script exists to close. The caller
waits for a run still writing its table and moves a dead one to closed/.

Exit codes: 0 pass; 1 semantic failure, with one line per problem on stderr:
`overlap:`, `malformed:`, `empty:`, or `unchecked:`; 3 usage or unreadable
input, which covers fewer than two lanes, a lane named twice, a malformed
--lane, an unreadable PATH, and a lane plan whose `## Waves` table won't
parse. Argparse supplies 2 for a mistyped flag.

Stdlib only, so the skill stays copy-in portable.
"""
import argparse
import collections
import os
import re
import sys

# ---------------------------------------------------------------------------
# Vendored verbatim from work-issue/scripts/check-inflight.py (lines 48-167:
# paths_overlap, owns_entry_problem, path_within; lines 170-173: COLUMNS,
# SEPARATOR_CELL, Row; lines 176-299: split_row, extract_table, read_rows),
# itself vendored from divvy-up/scripts/check-waves.py, itself vendored from
# adversarial-review/scripts/check-territories.py, itself vendored from
# agent-guild's check-diff-scope.py. Vendored 2026-09-24. Upstream is
# authoritative: fix a bug there first, then re-copy. The docstrings travel
# with the code on purpose—they record the incident (#162) that set each
# rule, and a reader who trims them will eventually re-introduce the bug they
# describe. Copy with sed, never through a transcript: owns_entry_problem's
# invisible-character test holds four zero-width code points in a string
# literal, and a transcript copy drops them silently. This skill installs
# standalone to ~/.claude/skills/, so importing from a sibling skill is not
# available.
# ---------------------------------------------------------------------------


def paths_overlap(a, b):
    """True if ownership paths `a` and `b` denote overlapping territory.
    Each is either an exact file path or a directory prefix ending in
    '/'—the same two shapes ALLOWED and `owns:` entries both take.

    The comparison is on the path itself, with the trailing slash treated
    as notation rather than as part of the name, so `src/lib` and
    `src/lib/` are the same territory spelled two ways. #162 found the
    earlier version answering False there: it compared a file claim
    against a directory claim, correctly for the shapes it was handed and
    uselessly for what the author meant, and two tasks writing one tree
    rode the same wave on the strength of that answer. R15 refuses the
    slashless spelling of a directory that already exists, but a task's
    whole job is often to create the tree it owns, and this predicate is
    the only thing standing between that case and a lost write.

    So: two paths overlap when they name the same node, or when either is
    a parent directory of the other. A trailing slash still carries
    meaning for anyone reading the file, and `plugin/` still does not
    swallow `plugin-extra/`, because a parent relationship is tested at a
    separator rather than by raw string prefix. `a` and `b` are
    interchangeable—the check is symmetric—which matters to a caller like
    R13 comparing two tasks' owns lists pairwise without caring which one
    it read first."""
    a_core = a.rstrip("/")
    b_core = b.rstrip("/")
    if a_core == b_core:
        return True
    return a_core.startswith(b_core + "/") or b_core.startswith(a_core + "/")


def owns_entry_problem(entry, repo_root=None):
    """A short reason an `owns:` entry is malformed, or None if it's one of
    the two shapes paths_overlap above understands.

    Shape is load-bearing rather than cosmetic. `paths_overlap` above
    answers "same territory?" for the two documented shapes; hand it a
    third thing and its answer is meaningless rather than wrong, and a
    meaningless "no overlap" is what puts two tasks on one file in the
    same wave (#162). Every check here catches a spelling that would
    produce one: `./src/a.py` never matches `src/a.py`, a glob never
    matches the files it was meant to stand for, an invisible character
    makes a path that matches nothing at all, a backticked path never
    matches the bare twin a peer task wrote (#232).

    Existence is never required—a task's whole job is often to create the
    file it owns. The repo_root checks fire only when the path DOES exist
    and its kind contradicts its spelling. Pass repo_root=None for the
    textual checks alone, which is what ready-set.py does to stay a pure
    function of the task files."""
    if not isinstance(entry, str):
        return f"not a string ({type(entry).__name__})"
    if not entry.strip():
        return "empty entry"
    if entry != entry.strip():
        return "leading or trailing whitespace"
    invisible = next((c for c in entry if c in "​‌‍﻿\xa0"), None)
    if invisible is not None:
        # Survives .strip(), reads as an ordinary path, matches nothing.
        # Usually arrived by paste rather than by typing.
        return f"invisible character U+{ord(invisible):04X}"
    # A task template's own prose backticks every path shape it names, and
    # a markdown table backticks every cell, so a decorated entry is what
    # a careful author writes. It reads as an ordinary path and is worse
    # than one owning nothing: it differs from the bare spelling a peer
    # task wrote, so R13 answers "no overlap" and both ride one wave over
    # one file (#232). Refused rather than stripped, because the reason
    # has to quote text the author can find in their own file.
    if "`" in entry:
        return "backtick; write the path bare, without markdown decoration"
    # `](` rather than a bracket, for the reason the glob check gives
    # below: `app/[slug]/page.tsx` is a real path shape and stays legal.
    if "](" in entry:
        return "markdown link; write the path bare, without markdown decoration"
    if "\\" in entry:
        return "backslash; entries use '/' separators"
    # `*` and `?` only. Brackets are ordinary filename characters and
    # `app/[slug]/page.tsx` is the most common path shape in half the
    # frameworks a copied-in kit will meet; rejecting it would fail
    # DEC-audit with no spelling the author could fix.
    glob_char = next((c for c in entry if c in "*?"), None)
    if glob_char is not None:
        return (
            f"glob character {glob_char!r}; an entry is a literal path, and a "
            "pattern here would own nothing"
        )
    if entry.startswith("~") or entry.startswith("$"):
        return "shell expansion; entries are literal repo-relative paths"
    if entry.startswith("/"):
        return "absolute path; entries are repo-relative"
    core = entry[:-1] if entry.endswith("/") else entry
    if not core:
        return "bare '/'"
    parts = core.split("/")
    if "" in parts:
        return "empty path segment ('//')"
    if "." in parts:
        return "'.' segment; write the path without './'"
    if ".." in parts:
        return "'..' segment; entries stay inside the repo"
    if repo_root is not None:
        full = os.path.join(repo_root, core)
        if entry.endswith("/"):
            if os.path.isfile(full):
                return "ends with '/' but exists as a file"
        elif os.path.isdir(full):
            return "exists as a directory but lacks the trailing '/'"
    return None


def path_within(path, prefix):
    """True if `path` sits inside directory `prefix`, which ends in '/'.

    Containment, not overlap, and the difference is the whole reason this
    isn't paths_overlap. Overlap is symmetric because two owners collide
    whichever way you read the pair. A grant flows one way only: allowing
    `docs/generated/` says nothing about a file at `docs`, which is
    ABOVE the granted territory rather than inside it. Sharing the
    symmetric predicate here let exactly that through."""
    return path.startswith(prefix)


COLUMNS = ("Wave", "Task", "Files owned", "Model", "Done when", "Constraints")
SEPARATOR_CELL = re.compile(r"^:?-+:?$")

Row = collections.namedtuple("Row", "lineno wave task entries model done constraints")


def split_row(line):
    r"""Cells of one pipe-table row, stripped, honouring Markdown's `\|` escape.

    A row is fenced by pipes, so splitting leaves an empty string at each end.
    split_row drops those two and nothing else. An empty cell in the middle is a
    real problem the caller has to see, and discarding it would turn a missing
    owner into a column-count complaint pointing at the wrong row.

    An escaped pipe stays inside its cell and arrives unescaped. A done-when is
    routinely an acceptance command, and a shell pipeline written the only way
    Markdown allows (`printf x \| grep x`) otherwise splits into extra columns
    and fails a plan the planner wrote correctly. Validation is a hard stop, so
    that reads as the whole run refusing an ordinary pipeline."""
    cells, cell, i = [], [], 0
    body = line.strip()
    while i < len(body):
        ch = body[i]
        if ch == "\\" and i + 1 < len(body) and body[i + 1] == "|":
            cell.append("|")
            i += 2
            continue
        if ch == "|":
            cells.append("".join(cell))
            cell = []
            i += 1
            continue
        cell.append(ch)
        i += 1
    cells.append("".join(cell))
    if cells and not cells[0].strip():
        cells = cells[1:]
    if cells and not cells[-1].strip():
        cells = cells[:-1]
    return [cell.strip() for cell in cells]


def extract_table(text):
    """Return (rows, error): the first pipe table under `## Waves` as a list of
    (line number, cells), or an error string.

    The table ends at the first blank line, heading, or non-table line below it,
    so a sentence the planner writes under the table never parses as a task
    row."""
    lines = text.splitlines()
    start = None
    for i, line in enumerate(lines):
        if line.strip() == "## Waves":
            start = i + 1
            break
    if start is None:
        return [], "no '## Waves' section"

    rows = []
    for i in range(start, len(lines)):
        stripped = lines[i].strip()
        if stripped.startswith("|"):
            rows.append((i + 1, split_row(lines[i])))
            continue
        if rows:
            break
        if stripped.startswith("#"):
            break
        # Above the table, blank lines and prose are both ordinary. A blank
        # line follows the heading, and planners often write a sentence of
        # framing before the table, so refusing either would be a trap.
    if not rows:
        return [], "no pipe table under '## Waves'"
    return rows, None


def read_rows(text):
    """Return (rows, problems): the table's body as Row records, plus every
    structural complaint. read_rows reports a row that cannot yield six cells
    and then drops it, because every check downstream reads cells by position
    and a short row would shift all of them without saying so."""
    table, error = extract_table(text)
    if error:
        return [], [error]

    problems = []
    header_lineno, header = table[0]
    if [cell.lower() for cell in header] != [name.lower() for name in COLUMNS]:
        problems.append(
            f"line {header_lineno}: header is {' | '.join(header)}, expected "
            f"{' | '.join(COLUMNS)}"
        )

    if len(table) > 1 and all(SEPARATOR_CELL.match(c) for c in table[1][1]):
        body = table[2:]
    else:
        problems.append(f"line {header_lineno}: no separator row under the header")
        body = table[1:]
    if not body:
        problems.append("the Waves table has no body rows")

    rows = []
    for lineno, cells in body:
        if len(cells) != 6:
            problems.append(f"line {lineno}: {len(cells)} columns, expected 6")
            continue
        for name, value in zip(COLUMNS, cells):
            if not value and name != "Constraints":
                # A constraint names the shortcut that would satisfy Done when
                # without doing the work, and most tasks have none worth
                # naming. The validator carries the column so a planner can
                # fill it in, but never reads the cell's content—a shortcut is
                # prose a human judges, not a check a script can run.
                problems.append(f"line {lineno}: empty {name} cell")

        wave_text, task, files_owned, model, done, constraints = cells
        wave = None
        if wave_text:
            if re.fullmatch(r"[0-9]+", wave_text):
                wave = int(wave_text)
            else:
                problems.append(
                    f"line {lineno}: wave {wave_text!r} is not a non-negative integer"
                )
        # Entries get stripped around the commas rather than checked for stray
        # whitespace. The table's own formatting pads every cell, so the
        # whitespace owns_entry_problem rejects is never the author's.
        entries = [e.strip() for e in files_owned.split(",")] if files_owned else []
        rows.append(Row(lineno, wave, task, entries, model, done, constraints))
    return rows, problems


# ---------------------------------------------------------------------------
# End vendored block.
# ---------------------------------------------------------------------------

LANE_NAME = re.compile(r"^issue-([0-9]+)$")

Claim = collections.namedtuple("Claim", "owner entry")


class UsageError(Exception):
    """A problem with the arguments or their files, which exits 3."""


def _count(n, word):
    return f"{n} {word}" if n == 1 else f"{n} {word}s"


def read_text(path):
    """The file's text, or UsageError.

    An unreadable footprint has to stop the run. If it read as empty text, the
    lane would own nothing, and a lane that owns nothing overlaps nothing, so
    the proof would pass over the one lane it never saw."""
    try:
        with open(path, encoding="utf-8") as f:
            return f.read()
    except OSError as e:
        raise UsageError(f"{path}: {e}")
    except UnicodeDecodeError as e:
        raise UsageError(f"{path}: not valid UTF-8: {e}")


def is_waves_plan(text):
    """True when the text has a `## Waves` heading, so it is read as a plan.

    The match is exact after strip(), the same test extract_table uses. An
    indented heading still reads as the plan it is, and a plan is never read
    as a bare list whose lines are prose and table rows."""
    return any(line.strip() == "## Waves" for line in text.splitlines())


def entries_from_waves(lane, text, path):
    """A Claim for every owned entry in the plan's table, every wave included.

    Wave numbers matter inside one tree, where a later wave can own a path an
    earlier wave wrote. Across lanes they don't: each lane runs every one of
    its waves in its own worktree, and the merges land on one branch. A table
    that won't parse raises UsageError, since an empty result would read as a
    lane that owns nothing."""
    rows, problems = read_rows(text)
    if problems:
        raise UsageError(f"{path}: unparseable ## Waves table: {'; '.join(problems)}")
    return [
        Claim(f"{lane} task {row.task}", entry)
        for row in rows
        for entry in row.entries
    ]


def entries_from_list(lane, text):
    """A Claim for every non-blank line of a bare footprint list.

    A line is not stripped. owns_entry_problem refuses stray whitespace and
    decoration rather than cleaning them up, so the reason it prints quotes a
    string that is really in the file."""
    return [Claim(lane, line) for line in text.splitlines() if line.strip()]


def lane_entries(lane, path):
    text = read_text(path)
    if is_waves_plan(text):
        return entries_from_waves(lane, text, path)
    return entries_from_list(lane, text)


def inflight_entries(runs_dir, lanes):
    """(checked, claims, unchecked) over the in-flight runs under runs_dir.

    A missing runs_dir is 0 runs and not an error. work-issue creates the
    directory on its first run, so it is absent in a repo that has never had
    one.

    A run whose plan.md is missing, unreadable, or has no parseable table
    lands in `unchecked`, and main fails on it rather than passing over it.
    Its footprint is unknown, and an unknown footprint can overlap anything.
    Skipping it once let a sibling owning a lane's file through (Codex
    finding 1, PR #141).
    It isn't counted in `checked` either, since nothing of it was compared.

    A sibling's malformed entries are dropped silently rather than failed.
    That plan passed its own `check-waves validate`, and its spelling isn't
    this wave's to fix. The drop also keeps a meaningless shape out of
    paths_overlap, where it would answer 'no overlap' for the wrong reason."""
    if not os.path.isdir(runs_dir):
        return 0, [], []
    checked, claims, unchecked = 0, [], []
    for name in sorted(os.listdir(runs_dir)):
        if name == "closed" or name in lanes:
            continue
        if not os.path.isdir(os.path.join(runs_dir, name)):
            continue
        try:
            with open(os.path.join(runs_dir, name, "plan.md"), encoding="utf-8") as f:
                text = f.read()
        except (OSError, UnicodeDecodeError):
            unchecked.append(name)
            continue
        rows, problems = read_rows(text)
        if problems:
            unchecked.append(name)
            continue
        checked += 1
        claims.extend(
            Claim(f"in-flight {name} task {row.task}", entry)
            for row in rows
            if row.task
            for entry in row.entries
            if owns_entry_problem(entry) is None
        )
    return checked, claims, unchecked


def parse_lanes(specs):
    """{lane: path}, ordered by issue number, or UsageError naming every bad
    --lane at once.

    The name has to be `issue-<N>` because every output line and every
    in-flight exclusion keys on it. A lane named twice is refused rather than
    merged, because two footprints under one name mean the caller built the
    lane set wrong."""
    problems, lanes = [], {}
    for spec in specs:
        name, sep, path = spec.partition("=")
        if not sep or not LANE_NAME.match(name) or not path:
            problems.append(f"malformed --lane {spec!r}; expected issue-N=PATH")
        elif name in lanes:
            problems.append(f"lane {name} named twice")
        else:
            lanes[name] = path
    if not problems and len(lanes) < 2:
        problems.append(
            f"{_count(len(lanes), 'lane')}; a wave needs at least two, and one "
            "issue is work-issue's job"
        )
    if problems:
        raise UsageError("\n".join(problems))
    ordered = sorted(lanes, key=lambda n: int(LANE_NAME.match(n).group(1)))
    return {name: lanes[name] for name in ordered}


def main(argv=None):
    ap = argparse.ArgumentParser(
        description="Prove a wave's lanes own disjoint paths, and list the pairs."
    )
    ap.add_argument("--lane", action="append", default=[], metavar="issue-N=PATH")
    ap.add_argument("--runs", metavar="DIR")
    args = ap.parse_args(argv)

    try:
        lanes = parse_lanes(args.lane)
        # Read every lane file before comparing anything, so one run names
        # every unreadable footprint at once.
        claims, unreadable = {}, []
        for lane, path in lanes.items():
            try:
                claims[lane] = lane_entries(lane, path)
            except UsageError as e:
                unreadable.append(str(e))
        if unreadable:
            raise UsageError("\n".join(unreadable))
    except UsageError as e:
        for line in str(e).splitlines():
            sys.stderr.write(f"check-footprints: {line}\n")
        return 3

    problems = []
    comparable = {}
    for lane, lane_claims in claims.items():
        if not lane_claims:
            problems.append(f"empty: {lane} owns no paths")
        comparable[lane] = []
        for claim in lane_claims:
            reason = owns_entry_problem(claim.entry)
            if reason:
                problems.append(f"malformed: {claim.owner}: {claim.entry!r}: {reason}")
            else:
                comparable[lane].append(claim)

    names = list(lanes)
    pairs = [(a, b) for i, a in enumerate(names) for b in names[i + 1 :]]
    for a, b in pairs:
        for x in comparable[a]:
            for y in comparable[b]:
                if paths_overlap(x.entry, y.entry):
                    problems.append(
                        f"overlap: {x.entry} — {x.owner} owns {x.entry}, "
                        f"{y.owner} owns {y.entry}"
                    )

    checked, sibling_claims, unchecked = (
        inflight_entries(args.runs, lanes) if args.runs else (0, [], [])
    )
    for name in unchecked:
        problems.append(
            f"unchecked: {name} has no ## Waves table; wait for it to write "
            "one, or move its run dir to closed/ if the run is dead"
        )
    for lane in names:
        for x in comparable[lane]:
            for y in sibling_claims:
                if paths_overlap(x.entry, y.entry):
                    problems.append(
                        f"overlap: {x.entry} — {x.owner} owns {x.entry}, "
                        f"{y.owner} owns {y.entry}"
                    )

    if problems:
        for problem in problems:
            sys.stderr.write(f"check-footprints: {problem}\n")
        return 1

    for lane in names:
        print(f"footprint: {lane} {_count(len(claims[lane]), 'path')}")
    for a, b in pairs:
        print(f"pair: {a} {b}")
    print(
        f"OK: {len(names)} lanes disjoint "
        f"(checked {_count(checked, 'in-flight run')})"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
