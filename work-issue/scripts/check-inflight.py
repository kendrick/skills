#!/usr/bin/env python3
"""Prove no in-flight work-issue run already owns a path this plan owns,
before work-issue dispatches into a shared working tree.

    work-issue/scripts/check-inflight.py PLAN.md --runs DIR [--self issue-N]

Two `work-issue` invocations for different issues can each pass their own
plan gate and still collide: if their `## Waves` tables both claim the same
file, the second dispatch to reach that path clobbers whatever the first
already wrote, and a walk-away run has no rebase step positioned to notice.
This is the check that catches the collision before either run starts
writing, by reading every other run's plan out of RUN_DIR's parent and
testing ownership pairwise.

Exit codes: 0 pass, printing `OK: no in-flight run owns a path this plan
owns (checked <n> runs)` (a missing --runs directory counts as 0 runs and
still passes); 1 an owned path overlaps a sibling run's, printing `overlap:
<path> — issue-N task <a>, issue-M task <b>` one line per pair; 3 PLAN is
unreadable or has no parseable `## Waves` table. A sibling run whose own
plan has no parseable table does not fail the check: it is reported on
stderr as `skipped: issue-M has no ## Waves table` and excluded from
comparison, because a plan that has not reached its own Waves table yet is
not a plan this script can test.

Stdlib only, so the skill stays copy-in portable.
"""
import argparse
import collections
import os
import re
import sys

# ---------------------------------------------------------------------------
# Vendored verbatim from divvy-up/scripts/check-waves.py (lines 48-167:
# paths_overlap, owns_entry_problem, path_within; lines 175-178: COLUMNS,
# SEPARATOR_CELL, Row; lines 198-321: split_row, extract_table, read_rows),
# itself vendored from adversarial-review/scripts/check-territories.py,
# itself vendored from agent-guild's check-diff-scope.py. Vendored
# 2026-09-17. Upstream is authoritative: fix a bug there first, then
# re-copy. The docstrings travel with the code on purpose—they record the
# incident (#162) that set each rule, and a reader who trims them will
# eventually re-introduce the bug they describe. This skill installs
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


def read_plan_text(path, label):
    """Read a text file, or exit 3. Distinguishing 'unreadable' from 'no
    in-flight run owns your path' keeps a missing PLAN from silently
    reading as a clean pass."""
    try:
        with open(path, encoding="utf-8") as f:
            return f.read()
    except OSError as e:
        sys.stderr.write(f"check-inflight: {label}: {e}\n")
        raise SystemExit(3)
    except UnicodeDecodeError as e:
        sys.stderr.write(f"check-inflight: {label}: not valid UTF-8: {e}\n")
        raise SystemExit(3)


def read_plan_text_soft(path):
    """Like read_plan_text, but raises instead of exiting: a sibling run's
    missing or unreadable plan is a skip, not a hard stop, because a run
    that has not reached its own Waves table yet is not a run this script
    can compare against."""
    with open(path, encoding="utf-8") as f:
        return f.read()


def owned_entries(rows):
    """(task, entry) for every well-formed owns entry in a parsed table.
    A malformed entry (backticked, globbed, absolute, ...) is excluded
    rather than compared, the same filter check-waves.py's cmd_validate
    applies before it runs paths_overlap — a meaningless shape answers
    'no overlap' for the wrong reason, which is worse than not checking it
    at all."""
    return [
        (row.task, entry)
        for row in rows
        if row.task
        for entry in row.entries
        if owns_entry_problem(entry) is None
    ]


def main(argv=None):
    ap = argparse.ArgumentParser(
        description="Refuse a plan whose owned paths overlap an in-flight work-issue run."
    )
    ap.add_argument("plan", metavar="PLAN.md")
    ap.add_argument("--runs", required=True, metavar="DIR")
    ap.add_argument("--self", dest="self_id", metavar="issue-N")
    args = ap.parse_args(argv)

    own_rows, own_problems = read_rows(read_plan_text(args.plan, args.plan))
    if own_problems:
        for problem in own_problems:
            sys.stderr.write(f"check-inflight: {args.plan}: {problem}\n")
        return 3
    own = owned_entries(own_rows)

    if not os.path.isdir(args.runs):
        print("OK: no in-flight run owns a path this plan owns (checked 0 runs)")
        return 0

    candidates = []
    for name in sorted(os.listdir(args.runs)):
        if name == "closed":
            continue
        if args.self_id and name == args.self_id:
            continue
        full = os.path.join(args.runs, name)
        if os.path.isdir(full):
            candidates.append(name)

    problems = []
    checked = 0
    for name in candidates:
        checked += 1
        plan_path = os.path.join(args.runs, name, "plan.md")
        try:
            text = read_plan_text_soft(plan_path)
        except (OSError, UnicodeDecodeError):
            sys.stderr.write(f"check-inflight: skipped: {name} has no ## Waves table\n")
            continue
        sibling_rows, sibling_problems = read_rows(text)
        if sibling_problems:
            sys.stderr.write(f"check-inflight: skipped: {name} has no ## Waves table\n")
            continue
        sibling = owned_entries(sibling_rows)
        for self_task, a in own:
            for other_task, b in sibling:
                if paths_overlap(a, b):
                    problems.append(
                        f"overlap: {a} — {args.self_id or args.plan} task "
                        f"{self_task}, {name} task {other_task}"
                    )

    if problems:
        for problem in problems:
            sys.stderr.write(f"check-inflight: {problem}\n")
        return 1

    print(f"OK: no in-flight run owns a path this plan owns (checked {checked} runs)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
