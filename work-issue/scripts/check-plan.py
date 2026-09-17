#!/usr/bin/env python3
"""Prove a plan is fit to dispatch before work-issue commits to it.

    work-issue/scripts/check-plan.py PLAN.md --issue N
    work-issue/scripts/check-plan.py PLAN.md --issue N --criteria ISSUE.md

A plan that never names the issue it claims to close, that leaves a task
with nowhere to write its output, that carries an open marker instead of a
decision, or that promises a criterion no line in the plan backs up is a
plan that will fail later at a point where failing costs more: mid-dispatch,
mid-review, or in front of the user who approved it. Catching this before
Step 1 sends a wave out is the entire job.

Checks, one stderr line each naming its rule and a location:

  D1  the plan never cites the issue (`#N`, `issues/N`, or `issue N`,
      whole-word)
  D2  a task heading (`## Task`, `### Task`, `### T<n>`, or a `- [ ] Task`
      line with any list marker at any indent) whose section has no `Files:`, `**Files:**`, `owns:`, or
      `Files owned` line — checked only when the plan has no `## Waves`
      table, since a Waves table carries ownership itself
  D3  an open marker: `TBD`, `TODO`, `FIXME`, `???`, `decide later`,
      `to be decided`, `open question` (case-insensitive, whole-word,
      ignoring a marker written inside backticks — a plan documenting
      this rule quotes its own trigger words)
  D4  a `- [ ]` line inside a section whose heading contains `Decision`,
      `Question`, or `Open` (a box elsewhere is a copied criterion and is
      fine)
  D6  a criterion (from `--criteria`, the `- [ ] `/`- [x] ` lines under a
      heading containing `Acceptance`) carrying a backticked identifier or
      a path-like token, none of which appears anywhere in the plan — a
      criterion with no such token is trivially covered

There is deliberately no D5: "an alternative left standing with no recorded
choice" is a judgment call, not a grep, and stays in prose at the call site
rather than becoming a heuristic this script gets blamed for guessing wrong.

Exit codes: 0 pass, printing `OK: plan cites #N, <k> tasks with files, 0
open markers, <c>/<c> criteria covered`; 1 semantic failure (any D-rule hit)
with one line per problem on stderr; 3 usage, missing file, unreadable
input. Argparse supplies 2 for a mistyped flag.

Stdlib only, so the skill stays copy-in portable.
"""
import argparse
import re
import sys

# Each marker carries its own boundary. `\b` only fires at a word/non-word edge,
# so wrapping `???` in `\b…\b` can never match: both sides of a run of question
# marks are non-word characters, and the gate passed a live `???` clean.
OPEN_MARKERS = (
    ("TBD", r"\bTBD\b"),
    ("TODO", r"\bTODO\b"),
    ("FIXME", r"\bFIXME\b"),
    ("???", r"(?<!\?)\?{3}(?!\?)"),
    ("decide later", r"\bdecide later\b"),
    ("to be decided", r"\bto be decided\b"),
    ("open question", r"\bopen question\b"),
)

TASK_HEADING_RES = (
    re.compile(r"^##\s+Task\b"),
    re.compile(r"^###\s+Task\b"),
    re.compile(r"^###\s+T\d+\b"),
)
# Any list marker, at any indent, the same widening D4 and D6 carry: a task
# written as an indented checkbox was a task D2 never checked for files.
CHECKBOX_TASK_RE = re.compile(r"^\s*[-*+]\s*\[[ xX]\]\s*Task\b")
# Any list marker, at any indent. A box nested under a bullet or written with
# `*` is an ordinary Markdown checkbox, and column-1 `-` alone let it past D4.
CHECKBOX_RE = re.compile(r"^\s*[-*+]\s*\[\s\]")
HEADING_RE = re.compile(r"^(#{1,6})\s+(.*)$")
FILES_LINE_RE = re.compile(r"Files:|\*\*Files:\*\*|owns:|Files owned")
WAVES_HEADING_RE = re.compile(r"^##\s+Waves\s*$")


def read_file(path, label):
    """Read a text file, or exit 3. An unreadable input is an environment
    problem, not a planning one, so it gets its own exit code rather than
    reading as just another failed check."""
    try:
        with open(path, encoding="utf-8") as f:
            return f.read()
    except OSError as e:
        sys.stderr.write(f"check-plan: {label}: {e}\n")
        raise SystemExit(3)
    except UnicodeDecodeError as e:
        sys.stderr.write(f"check-plan: {label}: not valid UTF-8: {e}\n")
        raise SystemExit(3)


def has_waves_table(lines):
    """True if a `## Waves` heading is followed, somewhere below, by a line
    starting with `|`. A full parse of the table belongs to check-inflight.py
    (which vendors divvy-up's parser); this script only needs to know
    whether ownership already lives in a table, which decides whether D2
    applies at all."""
    for i, line in enumerate(lines):
        if WAVES_HEADING_RE.match(line):
            for later in lines[i + 1 :]:
                stripped = later.strip()
                if stripped.startswith("|"):
                    return True
                if stripped.startswith("#"):
                    return False
            return False
    return False


def heading_level(line):
    m = HEADING_RE.match(line)
    return len(m.group(1)) if m else None


def find_task_sections(lines):
    """(lineno, title, section_lines) for every task heading, plus every
    `- [ ] Task` line treated as a one-line section extended to its
    indented continuation. A heading section runs to the next heading at
    the same or a shallower level; a checkbox section runs to the next
    line at the same or lesser indentation."""
    sections = []
    n = len(lines)
    i = 0
    while i < n:
        line = lines[i]
        level = heading_level(line)
        if level is not None and any(p.match(line) for p in TASK_HEADING_RES):
            j = i + 1
            while j < n:
                lvl = heading_level(lines[j])
                if lvl is not None and lvl <= level:
                    break
                j += 1
            sections.append((i + 1, line.strip(), lines[i:j]))
            i = j
            continue
        if CHECKBOX_TASK_RE.match(line):
            indent = len(line) - len(line.lstrip())
            j = i + 1
            while j < n:
                stripped = lines[j].strip()
                cur_indent = len(lines[j]) - len(lines[j].lstrip())
                if not stripped:
                    break
                if cur_indent <= indent:
                    break
                j += 1
            sections.append((i + 1, line.strip(), lines[i:j]))
            i = j
            continue
        i += 1
    return sections


def check_d1(text, issue):
    pattern = re.compile(
        rf"#{issue}\b|issues/{issue}\b|\bissue\s+{issue}\b", re.IGNORECASE
    )
    if pattern.search(text):
        return None
    return [f"check-plan: line 1: D1 plan does not cite #{issue}"]


def check_d2(lines, waves_present):
    """Count every task section that carries a files line, and — only when
    the plan has no `## Waves` table to carry ownership instead — flag every
    section that doesn't. The count is reported either way: a plan with a
    Waves table still names its tasks with files in prose, and the OK line
    is more useful counting what's actually there than reporting a rule
    that never ran."""
    problems = []
    with_files = 0
    for lineno, title, section in find_task_sections(lines):
        if any(FILES_LINE_RE.search(l) for l in section):
            with_files += 1
        elif not waves_present:
            problems.append(
                f"check-plan: line {lineno}: D2 task {title!r} has no "
                "Files:/owns:/Files owned line"
            )
    return problems, with_files


BACKTICK_SPAN_RE = re.compile(r"`[^`]*`")


def check_d3(lines):
    """A marker inside a backtick span is the D3 rule quoting its own
    trigger words, not a live TBD left in the plan — this contract's own
    Scripts section does exactly that (`` `TBD`, `TODO`, ... ``), and a
    scan that can't tell the two apart would refuse the plan that
    documents the rule."""
    problems = []
    for lineno, line in enumerate(lines, start=1):
        scannable = BACKTICK_SPAN_RE.sub("", line)
        for shown, pattern in OPEN_MARKERS:
            if re.search(pattern, scannable, re.IGNORECASE):
                problems.append(f"check-plan: line {lineno}: D3 open marker {shown!r}")
    return problems


def check_d4(lines):
    """A box counts when any heading still open above it names a decision,
    not only the nearest one. Tracking the nearest heading alone let
    `## Open Questions` / `### Storage` / `- [ ] IndexedDB or localStorage?`
    pass clean: the subheading replaced the section that made the box a
    decision. The problem line names the nearest ancestor that matched."""
    problems = []
    ancestors = []  # (level, text) for every heading still open above this line
    for lineno, line in enumerate(lines, start=1):
        level = heading_level(line)
        if level is not None:
            text = HEADING_RE.match(line).group(2)
            while ancestors and ancestors[-1][0] >= level:
                ancestors.pop()
            ancestors.append((level, text))
            continue
        if not CHECKBOX_RE.match(line):
            continue
        for _, text in reversed(ancestors):
            # Whole words: `OpenAPI changes` is not an open question.
            if re.search(r"\b(?:decision|question|open)s?\b", text, re.IGNORECASE):
                problems.append(
                    f"check-plan: line {lineno}: D4 unchecked box under heading {text!r}"
                )
                break
    return problems


def extract_criteria(criteria_text):
    """`- [ ] `/`- [x] ` lines under the nearest heading whose text contains
    `Acceptance`, mirroring the extraction the skill's Step 0 performs when
    it writes RUN_DIR/issue.md from the issue body."""
    lines = criteria_text.splitlines()
    criteria = []
    # Every heading still open above the line, so a `### Storage` inside
    # `## Acceptance Criteria` keeps its boxes inside the criteria. The
    # nearest-heading version dropped them, and a plan covering nothing
    # passed with `0/0 criteria covered`.
    ancestors = []
    for lineno, line in enumerate(lines, start=1):
        level = heading_level(line)
        if level is not None:
            while ancestors and ancestors[-1][0] >= level:
                ancestors.pop()
            ancestors.append((level, line.lower()))
            continue
        under_acceptance = any("acceptance" in text for _, text in ancestors)
        if under_acceptance and re.match(r"^\s*[-*+]\s*\[[ xX]\]", line):
            criteria.append((lineno, line.strip()))
    return criteria


TOKEN_BACKTICK_RE = re.compile(r"`([^`]+)`")
TOKEN_PATH_RE = re.compile(r"[\w.\-]+(?:/[\w.\-]+)+")


def check_d6(criteria_path, criteria_text, plan_text):
    criteria = extract_criteria(criteria_text)
    problems = []
    covered = 0
    for lineno, line in criteria:
        tokens = set(TOKEN_BACKTICK_RE.findall(line)) | set(TOKEN_PATH_RE.findall(line))
        if not tokens:
            covered += 1
            continue
        if any(token in plan_text for token in tokens):
            covered += 1
        else:
            shown = ", ".join(sorted(tokens))
            problems.append(
                f"check-plan: {criteria_path}:{lineno}: D6 criterion cites "
                f"{shown}, which appears nowhere in the plan"
            )
    return problems, covered, len(criteria)


def main(argv=None):
    ap = argparse.ArgumentParser(description="Gate a plan before work-issue dispatches it.")
    ap.add_argument("plan", metavar="PLAN.md")
    ap.add_argument("--issue", type=int, required=True, metavar="N")
    ap.add_argument("--criteria", metavar="ISSUE.md")
    args = ap.parse_args(argv)

    plan_text = read_file(args.plan, args.plan)
    lines = plan_text.splitlines()
    waves_present = has_waves_table(lines)

    problems = []

    d1 = check_d1(plan_text, args.issue)
    if d1:
        problems.extend(d1)

    d2_problems, tasks_with_files = check_d2(lines, waves_present)
    problems.extend(d2_problems)

    d3_problems = check_d3(lines)
    problems.extend(d3_problems)

    d4_problems = check_d4(lines)
    problems.extend(d4_problems)

    covered = total = 0
    if args.criteria:
        criteria_text = read_file(args.criteria, args.criteria)
        d6_problems, covered, total = check_d6(args.criteria, criteria_text, plan_text)
        problems.extend(d6_problems)

    if problems:
        for problem in problems:
            sys.stderr.write(problem + "\n")
        return 1

    print(
        f"OK: plan cites #{args.issue}, {tasks_with_files} tasks with files, "
        f"0 open markers, {covered}/{total} criteria covered"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
