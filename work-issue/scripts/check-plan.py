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
      `to be decided` anywhere, and `open question` wherever an occurrence
      is not the object of its own `settl…`/`resolv…`/`answer…` word, with
      at most one determiner between them, which covers a label (`Open
      question: …`, `- **Open question** …`) because no resolving word
      comes before the phrase there to take it as its object
      (case-insensitive, whole-word,
      ignoring a marker written inside backticks — a plan documenting
      this rule quotes its own trigger words); and any list item that is
      not a box D4 reports, under a non-task heading containing `open
      question(s)`, `open uncertainty`/`open uncertainties`, `open
      decision(s)`, or `open item(s)`, or opening with `unresolved` or
      `undecided` (optionally after `3.`, with or without `**`/`_`
      emphasis), backtick spans ignored (a heading naming uncertainties
      without `open` does not count), unless the item opens with a
      `~~struck~~` span or a ticked `[x]` box, or is nested at or past the
      content column of one that does
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
)
# `open question` names the category, so prose that closes questions uses it
# too. It gets its own gate in check_d3 rather than a slot above.
OPEN_QUESTION_RE = re.compile(r"\bopen question\b", re.IGNORECASE)
# The verb has to take the open question as its object. A resolving word
# anywhere in the sentence is not enough: "Whether the key is resolved remains
# an open question." holds `resolv` and still leaves the question open.
RESOLVED_OBJECT_RE = re.compile(
    r"\b(?:settl|resolv|answer)\w*\s+"
    r"(?:(?:a|an|the|this|that|each|every|one|its|our|their|your)\s+)?"
    r"open question\b",
    re.IGNORECASE,
)
SENTENCE_SPLIT_RE = re.compile(r"[.!?;:](?:\s+|$)")
# `uncertainties` needs `open` in front. A `## Risks and uncertainties` list
# holds risks the plan already answers ("we back off"), and failing it
# refuses a plan with nothing left open.
OPEN_STATE_HEADING_RE = re.compile(
    r"\bopen\s+(?:questions?|uncertaint(?:y|ies)|decisions?|items?)\b",
    re.IGNORECASE,
)
# A bare `unresolved` or `undecided` is a state label only when it opens the
# heading. Anywhere else it names a topic, and `### T1 Count unresolved
# threads` failed every item in its own task. Emphasis around the word doesn't
# change that. A test anchored on the first character passed every item under
# `## **Unresolved**`.
OPEN_STATE_LEAD_RE = re.compile(
    r"^\s*(?:\d+[.)]\s+)?[*_]*(?:unresolved|undecided)[*_]*(?!\w)", re.IGNORECASE
)
# Whole words: `OpenAPI changes` is not an open question.
D4_HEADING_RE = re.compile(r"\b(?:decision|question|open)s?\b", re.IGNORECASE)
LIST_ITEM_RE = re.compile(r"^\s*(?:[-*+]|\d+[.)])\s+(.*)$")
CHECKED_BOX_RE = re.compile(r"^\[[xX]\]")
STRUCK_RE = re.compile(r"^(?:\[[ xX]\]\s*)?~~.+?~~")

TASK_HEADING_RES = (
    re.compile(r"^ {0,3}##\s+Task\b"),
    re.compile(r"^ {0,3}###\s+Task\b"),
    re.compile(r"^ {0,3}###\s+T\d+\b"),
)
# Any list marker, at any indent, the same widening D4 and D6 carry: a task
# written as an indented checkbox was a task D2 never checked for files.
CHECKBOX_TASK_RE = re.compile(r"^\s*[-*+]\s*\[[ xX]\]\s*Task\b")
# Any list marker, at any indent. A box nested under a bullet or written with
# `*` is an ordinary Markdown checkbox, and column-1 `-` alone let it past D4.
CHECKBOX_RE = re.compile(r"^\s*[-*+]\s*\[\s\]")
# Up to three leading spaces, which CommonMark allows on a heading (four is a
# code block). Column-1-only patterns lost D2, D4, and D6 their section
# ancestry on an indented heading.
HEADING_RE = re.compile(r"^ {0,3}(#{1,6})\s+(.*)$")
FILES_LINE_RE = re.compile(r"Files:|\*\*Files:\*\*|owns:|Files owned")
WAVES_HEADING_RE = re.compile(r"^ {0,3}##\s+Waves\s*$")


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
    documents the rule.

    `open question` is gated where the other six are not (#129). Issue
    #113's plan was refused at "The four that settle an open question",
    a sentence closing questions, while its "Open uncertainties" list of
    genuinely unresolved items passed clean. The other six leave something
    open in ordinary use; only this one got reproduced misfiring. So it
    fires in a sentence where no resolving verb takes it as its object.
    That includes a label, since nothing in front of a label's phrase is
    a resolving word. The
    heading walk catches what the phrase list never could: items filed
    under a heading that says they're open."""
    problems = []
    ancestors = []  # (level, text, open state), the same walk D4 does
    # (marker indent, content column) of the struck or ticked item whose
    # nested items are closed with it, or None. A sub-bullet recording the
    # answer belongs to the closed item, and failing it as an open item of its
    # own pushes authors to delete the answer.
    closed = None
    for lineno, line in enumerate(lines, start=1):
        level = heading_level(line)
        if level is not None:
            text = HEADING_RE.match(line).group(2)
            while ancestors and ancestors[-1][0] >= level:
                ancestors.pop()
            ancestors.append((level, text, is_open_state_heading(line, text)))
            closed = None
        scannable = BACKTICK_SPAN_RE.sub("", line)
        for shown, pattern in OPEN_MARKERS:
            if re.search(pattern, scannable, re.IGNORECASE):
                problems.append(f"check-plan: line {lineno}: D3 open marker {shown!r}")
        if open_question_fires(scannable):
            problems.append(f"check-plan: line {lineno}: D3 open marker 'open question'")
        if level is not None:
            continue
        indent = len(line) - len(line.lstrip())
        item = LIST_ITEM_RE.match(line)
        if not item:
            # A paragraph back at the closed item's indent or shallower has
            # left its list. Blank lines don't, since a loose list puts them
            # between an item and its sub-items.
            if line.strip() and closed is not None and indent <= closed[0]:
                closed = None
            continue
        # CommonMark nests an item only at its parent's content column: 2
        # past `- `, 4 past `10. `. Anything shallower is a new item that
        # renders as open, and exempting it passed a live sibling.
        if closed is not None:
            if indent >= closed[1]:
                continue
            closed = None
        body = item.group(1)
        # A struck or ticked item is closed. "settled" in the text is not:
        # #129's unresolved fixture reads "Unresolved; settled by a live run."
        if STRUCK_RE.match(body) or CHECKED_BOX_RE.match(body):
            closed = (indent, item.start(1))
            continue
        open_heading = next(
            (t for _, t, open_state in reversed(ancestors) if open_state), None
        )
        if open_heading is None:
            continue
        # An unchecked box D4 already reports stays D4's, so no line reports
        # twice. One D4 misses (under `## Unresolved`) is still ours.
        if CHECKBOX_RE.match(line) and any(D4_HEADING_RE.search(t) for _, t, _ in ancestors):
            continue
        problems.append(
            f"check-plan: line {lineno}: D3 unresolved item under heading {open_heading!r}"
        )
    return problems


def is_open_state_heading(line, text):
    """A task heading names work to do, so its title never marks its items
    open. Backtick spans are a name being quoted, the same exemption
    the marker scan gives them.

    The lead test swaps each span for a placeholder word instead of
    deleting it. Deleting the span would leave `unresolved` first in
    `` `gh api` unresolved thread counts ``, and the heading would read as
    a state label."""
    if any(p.match(line) for p in TASK_HEADING_RES):
        return False
    if OPEN_STATE_LEAD_RE.match(BACKTICK_SPAN_RE.sub("name", text)):
        return True
    return bool(OPEN_STATE_HEADING_RE.search(BACKTICK_SPAN_RE.sub("", text)))


def open_question_fires(scannable):
    """The sentence test also covers a label. In `Open question: …` and
    `- **Open question** …`, no resolving word comes before the phrase to
    take it as its object, so `RESOLVED_OBJECT_RE` can't remove it. A
    resolving verb in the tail clears only an occurrence that follows it.
    `_Open question_` never fires, because `_` is a word character and
    `OPEN_QUESTION_RE` finds no word boundary before `Open`.

    Each occurrence needs its own resolving verb. Removing the resolved
    spans before the search keeps "This settles the open question of
    retries, but the open question of caching remains." from passing on
    the strength of its first half."""
    if not OPEN_QUESTION_RE.search(scannable):
        return False
    return any(
        OPEN_QUESTION_RE.search(RESOLVED_OBJECT_RE.sub("", sentence))
        for sentence in SENTENCE_SPLIT_RE.split(scannable)
    )


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
            if D4_HEADING_RE.search(text):
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
