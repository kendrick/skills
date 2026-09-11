#!/usr/bin/env python3
"""Prove a plan's waves are safe to dispatch in parallel, then work out which
task in a wave owns a path an agent wrote.

    divvy-up/scripts/check-waves.py validate PLAN.md
    git diff --name-only \\
        | divvy-up/scripts/check-waves.py owners PLAN.md --wave 1

`validate` is the gate the skill passes before it dispatches anything. Two tasks
in one wave run at the same moment against one working tree, so if the paths
they own overlap, one of them loses a write and nobody finds out. Disjoint
ownership is the only reason a wave can fan out at all, so an overlap fails the
run rather than warning about it.

An overlap between tasks in DIFFERENT waves is not a problem. It is the planner
having serialized two tasks that touch one tree, which is what should happen.
Those print on stdout as `serialized:` lines and pass.

`owners` is the check on a wave that already ran. A path in the diff that no
task in the wave owns exits 1 instead of being skipped. An agent writing outside
its territory is the exact failure the wave structure exists to prevent, and
catching it is worth nothing unless it stops the run.

Exit codes: 0 pass; 1 semantic failure (missing or malformed table, in-wave
overlap, malformed entry, unknown model, non-contiguous waves, unowned or
multiply-owned path) with one line per problem on stderr; 3 usage, missing file,
unreadable input. Argparse supplies 2 for a mistyped flag.

Stdlib only, so the skill stays copy-in portable.
"""
import argparse
import collections
import os
import re
import sys

# ---------------------------------------------------------------------------
# Vendored verbatim from adversarial-review/scripts/check-territories.py (lines
# 48-167), itself vendored from agent-guild's check-diff-scope.py. Vendored
# 2026-09-10. Upstream is authoritative: fix a bug there first, then re-copy.
# The docstrings travel with the code on purpose—they record the incident (#162)
# that set each rule, and a reader who trims them will eventually re-introduce
# the bug they describe. This skill installs standalone to ~/.claude/skills/, so
# importing from the sibling skill is not available.
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


# ---------------------------------------------------------------------------
# End vendored block.
# ---------------------------------------------------------------------------

MODELS = ("haiku", "sonnet", "opus", "fable")
COLUMNS = ("Wave", "Task", "Files owned", "Model", "Done when", "Constraints")
SEPARATOR_CELL = re.compile(r"^:?-+:?$")

Row = collections.namedtuple("Row", "lineno wave task entries model done constraints")


def load_plan(path, label):
    """Read the plan, or exit 3. Anything wrong at this layer is an environment
    problem rather than a planning problem, and the two exit codes stay separate
    so a caller can tell 'your waves collide' from 'your file isn't there'."""
    try:
        if path == "-":
            return sys.stdin.read()
        with open(path, encoding="utf-8") as f:
            return f.read()
    except OSError as e:
        sys.stderr.write(f"check-waves: {label}: {e}\n")
        raise SystemExit(3)
    except UnicodeDecodeError as e:
        sys.stderr.write(f"check-waves: {label}: not valid UTF-8: {e}\n")
        raise SystemExit(3)


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


def _count(n, word):
    return f"{n} {word}" if n == 1 else f"{n} {word}s"


def owners_of(path, rows):
    """Every row owning `path`, by exact entry match or by sitting inside a
    directory entry. Containment, not overlap: a task owning `src/api/` does not
    thereby own `src`, which is above it."""
    owners = []
    for row in rows:
        for entry in row.entries:
            if entry.endswith("/"):
                if path_within(path, entry):
                    owners.append(row.task)
                    break
            elif path == entry:
                owners.append(row.task)
                break
    return owners


def repo_root_for():
    """The repo root to resolve ownership entries against, or None.

    Walks up from the working directory, never from the plan file. Entries are
    relative to the repo under change, and the plan often sits outside it—a
    conversation-only plan is written to a temp file, and resolving from there
    would find no `.git` and silently skip every on-disk check. Answers None
    when no `.git` is found above the working directory. None keeps the spelling-only checks
    and skips the on-disk ones, which is what a plan validated outside a
    checkout should get.

    Passing this matters because `owns_entry_problem`'s sharpest check needs
    it: an entry naming an existing directory without its trailing slash reads
    as a file claim, so it collides with nothing and owns nothing beneath
    itself. Without repo_root that entry validates, the wave dispatches, and
    the first file the task writes comes back unowned at the gate—after the
    tree has already changed.
    """
    node = os.getcwd()
    while True:
        if os.path.exists(os.path.join(node, ".git")):
            return node
        parent = os.path.dirname(node)
        if parent == node:
            return None
        node = parent


def cmd_validate(args):
    rows, problems = read_rows(load_plan(args.plan, args.plan))
    repo_root = repo_root_for()

    seen = {}
    for row in rows:
        if row.task:
            if row.task in seen:
                problems.append(
                    f"line {row.lineno}: duplicate task {row.task!r}, first seen "
                    f"at line {seen[row.task]}"
                )
            else:
                seen[row.task] = row.lineno
        for entry in row.entries:
            reason = owns_entry_problem(entry, repo_root)
            if reason:
                problems.append(
                    f"line {row.lineno}: malformed entry {entry!r} in "
                    f"{row.task or '?'}: {reason}"
                )
        if row.model and row.model not in MODELS:
            problems.append(
                f"line {row.lineno}: unknown model {row.model!r}; expected one of "
                f"{', '.join(MODELS)}"
            )

    # Malformed entries are excluded from here down. paths_overlap answers for
    # the two shapes owns_entry_problem admits; hand it a third and the answer
    # is meaningless rather than wrong, and a meaningless 'no overlap' is the
    # thing this whole script exists to refuse.
    comparable = [
        row._replace(
            entries=[e for e in row.entries if owns_entry_problem(e) is None]
        )
        for row in rows
        if row.wave is not None and row.task
    ]

    serialized = []
    for i, first in enumerate(comparable):
        for second in comparable[i + 1 :]:
            for a in first.entries:
                for b in second.entries:
                    if not paths_overlap(a, b):
                        continue
                    if first.wave == second.wave:
                        problems.append(
                            f"overlap: {first.task}:{a} ~ {second.task}:{b} "
                            f"in wave {first.wave}"
                        )
                    else:
                        serialized.append(
                            f"serialized: {first.task}:{a} (wave {first.wave}) ~ "
                            f"{second.task}:{b} (wave {second.wave})"
                        )

    waves = sorted({row.wave for row in rows if row.wave is not None})
    if waves and waves != list(range(len(waves))):
        problems.append(
            f"wave numbers {waves} are not contiguous from 0; expected "
            f"{list(range(len(waves)))}"
        )

    for line in serialized:
        print(line)
    if problems:
        for problem in problems:
            sys.stderr.write(f"check-waves: {problem}\n")
        return 1

    print(f"OK: {_count(len(rows), 'task')} in {_count(len(waves), 'wave')}, disjoint")
    return 0


def cmd_owners(args):
    if args.plan == "-":
        sys.stderr.write("check-waves: owners reads paths on stdin; name a plan file\n")
        return 3
    if args.wave < 0:
        sys.stderr.write(f"check-waves: --wave {args.wave} is negative\n")
        return 3

    rows, problems = read_rows(load_plan(args.plan, args.plan))
    if problems:
        for problem in problems:
            sys.stderr.write(f"check-waves: {problem}\n")
        return 1

    paths = [line.strip() for line in sys.stdin.read().splitlines() if line.strip()]
    if not paths:
        return 0

    in_wave = [row for row in rows if row.wave == args.wave]
    for path in paths:
        owners = owners_of(path, in_wave)
        if not owners:
            problems.append(f"unowned in wave {args.wave}: {path}")
        elif len(owners) > 1:
            problems.append(
                f"multiply-owned in wave {args.wave}: {path} ({', '.join(owners)})"
            )
        else:
            print(owners[0])

    if problems:
        for problem in problems:
            sys.stderr.write(f"check-waves: {problem}\n")
        return 1
    return 0


def parse_args(argv=None):
    ap = argparse.ArgumentParser(
        description="Validate a plan's waves, or name the owner of a written path."
    )
    sub = ap.add_subparsers(dest="command", required=True)

    v = sub.add_parser("validate", help="prove each wave's tasks own disjoint paths")
    v.add_argument("plan", metavar="PLAN_MD", help="plan markdown, or '-' for stdin")
    v.set_defaults(func=cmd_validate)

    o = sub.add_parser("owners", help="task in a wave owning each path on stdin")
    o.add_argument("plan", metavar="PLAN_MD")
    o.add_argument("--wave", type=int, required=True, metavar="N")
    o.set_defaults(func=cmd_owners)

    return ap.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
