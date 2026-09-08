#!/usr/bin/env python3
"""Validate a `.refine.md` staging file against the grammar in
`references/staging-format.md`, or emit its entries as the JSON lines
`jira-apply.py` expects on stdin.

    jira-refine/scripts/check-staging.py validate STAGING.refine.md
    cat STAGING.refine.md | jira-refine/scripts/check-staging.py validate -
    jira-refine/scripts/check-staging.py entries STAGING.refine.md --status approved

`validate` is the gate `/jira-refine --apply` passes before any entry reaches
a tracker. The staging file is a human-edited artifact between a transcript
and a write to Jira, so every rule in the grammar exists to catch a shape a
person could produce by hand: a status word misspelled, a section skipped, an
acceptance criterion with no anchor back to what was actually said. A gate
that lets a malformed file through is a silent path to writing something
nobody reviewed.

`entries` runs the same checks `validate` does before it prints anything, and
prints one JSON object per selected entry, in the shape
`references/tracker-contract.md` specifies. SKILL.md documents
`entries STAGING --status approved | jira-apply.py update` as a copy-paste
pipeline against a client's live Jira, so a malformed file has to produce no
JSON at all rather than fields read from a broken parse — a truncated stream
still feeds the pipe, and content nobody reviewed would reach real tickets.

Exit codes, shared by both commands: 0 pass; 1 semantic failure (a rule in the
grammar is broken), one line per problem on stderr and, for `entries`, no JSON
emitted; 3 usage, missing file, unreadable input, not valid UTF-8, or no
frontmatter fences at all — the last case means the file cannot be parsed as a
staging file, as opposed to being one with rule violations. Argparse supplies
2 for a mistyped flag.

Stdlib only, so the skill stays copy-in portable.
"""
import argparse
import json
import re
import sys

# ---------------------------------------------------------------------------
# Grammar constants, from references/staging-format.md.
# ---------------------------------------------------------------------------

FRONTMATTER_KEYS = (
    "skill", "schema", "source", "source_path", "session", "label",
    "config", "projects", "generated",
)
STATUS_VALUES = ("staged", "approved", "skipped", "applied", "conflict")
ON_CONFLICT_VALUES = ("append", "replace")
CONTENT_SECTIONS = (
    "Context", "Acceptance criteria", "Out of scope", "Dependencies",
    "Goal", "Open questions",
)
ALL_SECTIONS = CONTENT_SECTIONS + ("Provenance", "Source excerpt")
SUMMARY_SUBSECTIONS = (
    "Spike candidates", "Mentioned in passing", "Gaps to file", "Apply log",
)
# The lowercased names a `- not discussed: <section>` line may name — the six
# content sections, spelled exactly as staging-format.md's not-discussed
# table gives them.
NOT_DISCUSSED_NAMES = frozenset(name.lower() for name in CONTENT_SECTIONS)

KEY_RE = re.compile(r"^[A-Z][A-Z0-9]+-[0-9]+$")
PROJECT_RE = re.compile(r"^[A-Z][A-Z0-9]+$")
ANCHOR_RE = re.compile(r'\(raw: "([^"]{1,120})" (\d\d:\d\d:\d\d|L\d+)\)$')
DEP_KEY_RE = re.compile(r"^-\s+([A-Z][A-Z0-9]+-[0-9]+)\b")
SESSION_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
DATETIME_RE = re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$")
SEGMENT_RE = re.compile(r"^(?:\d\d:\d\d:\d\d - \d\d:\d\d:\d\d|L\d+ - L\d+)$")
DURATION_RE = re.compile(r"^\d+m\d+s$")
INT_RE = re.compile(r"^\d+$")
LIST_RE = re.compile(r"^\[(.*)\]$")
KV_LINE_RE = re.compile(r"^(\w+):\s?(.*)$")
CLOCK_COORD_RE = re.compile(r"^\d\d:\d\d:\d\d$")
# segment.py's render_turn_line prefixes every excerpt line with `[HH:MM:SS]`
# or `[L<n>]` depending on has_clock — never both in one transcript, so
# whichever bracket shape shows up on the excerpt's own lines is the mode an
# anchor's coordinate has to match. Matched against raw (non-normalized)
# excerpt lines, since normalize_ws joins them into one string.
EXCERPT_TIMESTAMP_LINE_RE = re.compile(r"^\[\d\d:\d\d:\d\d\]")
EXCERPT_LINENO_LINE_RE = re.compile(r"^\[L\d+\]")
ANCHOR_MIN_WORDS = 4
ANCHOR_MAX_WORDS = 10


def group_clock_turns(content):
    """Split a clock-mode Source excerpt into turns and return {coord:
    [turn_text, ...]}, normalized the same way `excerpt_text` is.

    A turn starts at a `[HH:MM:SS]` line and swallows every following line
    up to the next one, because segment.py's render_turn_line only stamps a
    timestamp on a turn's first line and wraps the rest of that turn's text
    across further lines with no stamp of their own. Folding those wrapped
    lines back together (rather than checking one raw line at a time) is
    what lets a snippet split across a wrap still match; keying strictly on
    "next timestamp line, not next line" is what stops a snippet from
    running past its own turn into a different speaker's, which would mean
    the anchor quoting two people as one. A stamp can recur (two turns
    landing in the same second) so each coordinate maps to a list, and a
    line before the first stamp has no turn to join and is dropped — an
    excerpt is only in clock mode because some line matched the stamp
    pattern, and text with no stamp ahead of it can't be labelled by any
    coordinate regardless.
    """
    turns = {}
    coord = None
    buf = []

    def flush():
        if coord is not None:
            turns.setdefault(coord, []).append(normalize_ws(" ".join(buf)))

    for line in content:
        if EXCERPT_TIMESTAMP_LINE_RE.match(line):
            flush()
            coord = line[1:9]
            buf = [line]
        elif coord is not None:
            buf.append(line)
    flush()
    return turns


def normalize_ws(text):
    """Collapse all whitespace runs to single spaces and trim. An anchor's
    snippet is checked against the excerpt after this normalization on both
    sides, because segment.py wraps the excerpt at whatever width the source
    transcript used and a snippet that reads identically to a human can still
    differ in whitespace from the raw line."""
    return " ".join(text.split())


def parse_bracket_list(value):
    """`[A, B]` -> `["A", "B"]`; `[]` -> `[]`; anything else -> None. `projects`
    and `mentions` are the only two frontmatter/entry values shaped this way."""
    m = LIST_RE.match(value)
    if not m:
        return None
    inner = m.group(1).strip()
    if not inner:
        return []
    return [item.strip() for item in inner.split(",")]


def strip_anchor(text):
    return ANCHOR_RE.sub("", text).strip()


def strip_bullet(line):
    return line[2:].strip() if line.startswith("- ") else line.strip()


# ---------------------------------------------------------------------------
# I/O
# ---------------------------------------------------------------------------


def load_staging(path):
    """Read the staging file as UTF-8 text, or exit 3. Reading as bytes first
    (rather than opening in text mode) means '-' and a real path share one
    UTF-8 check instead of relying on stdin's locale encoding, which is not
    guaranteed to be UTF-8 even when the file on disk is."""
    try:
        data = sys.stdin.buffer.read() if path == "-" else open(path, "rb").read()
    except OSError as e:
        sys.stderr.write(f"check-staging: {path}: {e}\n")
        raise SystemExit(3)
    try:
        return data.decode("utf-8")
    except UnicodeDecodeError as e:
        sys.stderr.write(f"check-staging: {path}: not valid UTF-8: {e}\n")
        raise SystemExit(3)


# ---------------------------------------------------------------------------
# Structural parsing
# ---------------------------------------------------------------------------


def find_headers(lines, marker):
    """(idx, name) for every line reading exactly '{marker} name', skipping
    fenced code blocks. Fence state resets at the start of `lines`, which
    holds for every call site here: a fence never spans two entries, and the
    only fence in the grammar lives inside one entry's Source excerpt.
    '## ' and '### ' can never be confused by this scan, because the fourth
    character after a '### ' header is never a space for a '## ' match."""
    out = []
    in_fence = False
    prefix = marker + " "
    for i, line in enumerate(lines):
        if line.startswith("```"):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        if line.startswith(prefix):
            out.append((i, line[len(prefix):].strip()))
    return out


def find_fences(lines):
    """(start, end, tag, content, closed) for every fenced block in `lines`.
    `end` is the index of the closing fence line, or len(lines) when the fence
    never closes — an unclosed fence still needs to be reported, not silently
    swallowed to the end of the file."""
    fences = []
    i = 0
    while i < len(lines):
        if lines[i].startswith("```"):
            tag = lines[i][3:].strip()
            start = i
            j = i + 1
            content = []
            closed = False
            while j < len(lines):
                if lines[j].startswith("```"):
                    closed = True
                    break
                content.append(lines[j])
                j += 1
            fences.append((start, j, tag, content, closed))
            i = j + 1 if closed else len(lines)
            continue
        i += 1
    return fences


def parse_frontmatter(lines):
    """Returns (fm, body_start, fatal, problems). `fatal` is set only when the
    file cannot be read as a staging file at all — no opening or closing
    '---' fence — which is the one frontmatter failure the grammar treats as
    unreadable (exit 3) rather than a rule violation (exit 1)."""
    if not lines or lines[0].rstrip() != "---":
        return {}, 0, "no opening '---' fence on line 1", []
    closing = None
    for i in range(1, len(lines)):
        if lines[i].rstrip() == "---":
            closing = i
            break
    if closing is None:
        return {}, 0, "no closing '---' fence for frontmatter", []

    fm = {}
    problems = []
    for i in range(1, closing):
        raw = lines[i]
        if not raw.strip():
            continue
        m = KV_LINE_RE.match(raw)
        if not m:
            problems.append(f"line {i + 1}: frontmatter line is not 'key: value': {raw!r}")
            continue
        key, value = m.group(1), m.group(2).strip()
        if key in fm:
            problems.append(f"line {i + 1}: duplicate frontmatter key {key!r}")
        fm[key] = value
    return fm, closing + 1, None, problems


def check_frontmatter(fm):
    """Every frontmatter-level rule from staging-format.md's Frontmatter
    table. Returns (problems, projects) — `projects` is used by every entry
    check downstream, so it is handed back even when malformed (as []) rather
    than making every caller re-parse it."""
    problems = []
    for key in FRONTMATTER_KEYS:
        if key not in fm:
            problems.append(f"frontmatter: missing required key '{key}'")
    for key in sorted(set(fm) - set(FRONTMATTER_KEYS)):
        problems.append(f"frontmatter: unexpected key '{key}'")

    if "skill" in fm and fm["skill"] != "jira-refine":
        problems.append(f"frontmatter: skill is {fm['skill']!r}, expected 'jira-refine'")
    if "schema" in fm and fm["schema"] != "1":
        problems.append(f"frontmatter: schema is {fm['schema']!r}, expected '1'")
    if "session" in fm and not SESSION_RE.match(fm["session"]):
        problems.append(f"frontmatter: session {fm['session']!r} is not YYYY-MM-DD")
    if "generated" in fm and not DATETIME_RE.match(fm["generated"]):
        problems.append(f"frontmatter: generated {fm['generated']!r} is not YYYY-MM-DDTHH:MM:SS")
    if "source_path" in fm and not fm["source_path"].startswith("/"):
        problems.append(f"frontmatter: source_path {fm['source_path']!r} is not an absolute path")
    if "config" in fm and not fm["config"].startswith("/"):
        problems.append(f"frontmatter: config {fm['config']!r} is not an absolute path")
    if "source" in fm and "source_path" in fm:
        basename = fm["source_path"].rsplit("/", 1)[-1]
        if fm["source"] != basename:
            problems.append(
                f"frontmatter: source {fm['source']!r} does not match the basename "
                f"of source_path ({basename!r})"
            )
    if "label" in fm and "session" in fm and not fm["label"].endswith(fm["session"]):
        problems.append(
            f"frontmatter: label {fm['label']!r} does not end with session {fm['session']!r}"
        )

    projects = []
    if "projects" in fm:
        parsed = parse_bracket_list(fm["projects"])
        if parsed is None:
            problems.append(f"frontmatter: projects {fm['projects']!r} is not a bracketed list")
        else:
            projects = parsed
            for p in projects:
                if not PROJECT_RE.match(p):
                    problems.append(f"frontmatter: projects entry {p!r} is not a bare project key")
    return problems, projects


def check_entry_kv(key, kv_lines):
    """The key-value block between an entry header and its first '###'.
    `status:` is the only line the grammar requires; everything else is
    validated only when present, because segment.py writes some keys and
    reconcile writes others, and neither runs before a fresh skeleton is
    reviewed the first time."""
    problems = []
    kv = {}
    for raw in kv_lines:
        if not raw.strip():
            continue
        m = KV_LINE_RE.match(raw)
        if not m:
            problems.append(f"entry {key}: key-value line is not 'key: value': {raw!r}")
            continue
        k, v = m.group(1), m.group(2).strip()
        if k in kv:
            problems.append(f"entry {key}: duplicate '{k}:' line")
        kv[k] = v

    if "status" not in kv:
        problems.append(f"entry {key}: missing required 'status:' line")
    else:
        if kv["status"] not in STATUS_VALUES:
            problems.append(
                f"entry {key}: status {kv['status']!r} is not one of {list(STATUS_VALUES)}"
            )
        if kv["status"] == "applied" and "applied" not in kv:
            problems.append(f"entry {key}: status is 'applied' but no 'applied:' line")
        if kv["status"] == "conflict" and "conflict" not in kv:
            problems.append(f"entry {key}: status is 'conflict' but no 'conflict:' line")

    if "on_conflict" in kv and kv["on_conflict"] not in ON_CONFLICT_VALUES:
        problems.append(
            f"entry {key}: on_conflict {kv['on_conflict']!r} is not one of {list(ON_CONFLICT_VALUES)}"
        )
    if "applied" in kv and not DATETIME_RE.match(kv["applied"]):
        problems.append(f"entry {key}: applied {kv['applied']!r} is not YYYY-MM-DDTHH:MM:SS")
    if "conflict" in kv and not kv["conflict"]:
        problems.append(f"entry {key}: conflict: line has no reason")
    if kv.get("words") and not INT_RE.match(kv["words"]):
        problems.append(f"entry {key}: words {kv['words']!r} is not an integer")
    if kv.get("revisited") and not INT_RE.match(kv["revisited"]):
        problems.append(f"entry {key}: revisited {kv['revisited']!r} is not an integer")
    if kv.get("segment") and not SEGMENT_RE.match(kv["segment"]):
        problems.append(
            f"entry {key}: segment {kv['segment']!r} does not match "
            "'HH:MM:SS - HH:MM:SS' or 'L<n> - L<n>'"
        )
    if kv.get("duration") and not DURATION_RE.match(kv["duration"]):
        problems.append(f"entry {key}: duration {kv['duration']!r} does not match '<m>m<s>s'")

    mentions = []
    if kv.get("mentions"):
        parsed = parse_bracket_list(kv["mentions"])
        if parsed is None:
            problems.append(f"entry {key}: mentions {kv['mentions']!r} is not a bracketed list")
        else:
            mentions = parsed
            for m in mentions:
                if not KEY_RE.match(m):
                    problems.append(f"entry {key}: mentions entry {m!r} is not a valid issue key")

    return kv, mentions, problems


def check_sections(key, sections, fm, projects):
    """Every Sections/Anchors/Not-discussed/Provenance rule for one entry.
    Returns (problems, fields, not_discussed) — `fields` and `not_discussed`
    are the values `entries` needs for its JSON line, computed here rather
    than re-walked later so the two commands never disagree about what a
    section's body says."""
    problems = []

    # Source excerpt first: every anchor check below needs its normalized
    # text, and the excerpt is script-filled last in the file's own layout
    # but has no forward dependency on anything else in the entry.
    se_body = sections.get("Source excerpt", [])
    fences = find_fences(se_body)
    if len(fences) != 1:
        problems.append(
            f"entry {key}: Source excerpt has {len(fences)} fenced blocks, expected exactly 1"
        )
        excerpt_text = ""
        excerpt_mode = None
        clock_turns = {}
    else:
        _start, _end, tag, content, closed = fences[0]
        if not closed:
            problems.append(f"entry {key}: Source excerpt fence never closes")
        if tag != "text":
            problems.append(f"entry {key}: Source excerpt fence tag is {tag!r}, expected 'text'")
        if not any(line.strip() for line in content):
            problems.append(f"entry {key}: Source excerpt fenced block is empty")
        excerpt_text = normalize_ws(" ".join(content))
        # The excerpt is the one place a per-entry transcript's mode is
        # actually recorded (no separate transcript file is read here), so
        # the mode an anchor's coordinate must match is read off these lines
        # rather than assumed from the file as a whole. `None` means neither
        # bracket shape showed up — an already-malformed excerpt gets its own
        # problem above, and guessing a mode for it would just add noise.
        if any(EXCERPT_TIMESTAMP_LINE_RE.match(line) for line in content):
            excerpt_mode = "clock"
        elif any(EXCERPT_LINENO_LINE_RE.match(line) for line in content):
            excerpt_mode = "line"
        else:
            excerpt_mode = None
        # Only clock mode gets turn-level checking (see check_anchor below):
        # an untimed excerpt carries no line labels of its own, so an L<n>
        # anchor names a line in the source transcript, which this validator
        # never reads.
        clock_turns = group_clock_turns(content) if excerpt_mode == "clock" else {}

    def check_anchor(line, section_name):
        m = ANCHOR_RE.search(line)
        if not m:
            problems.append(f"entry {key}: {section_name} line has no valid anchor: {line!r}")
            return
        snippet = normalize_ws(m.group(1))
        if snippet not in excerpt_text:
            problems.append(
                f"entry {key}: {section_name} anchor snippet {m.group(1)!r} not found "
                "in this entry's Source excerpt"
            )
        # staging-format.md L156: the snippet is "authoritative" only because
        # it is distinctive enough to locate in the excerpt on its own. A
        # one- or two-word snippet can match anywhere (or match by luck),
        # which quietly turns the anchor from a provenance check into a
        # rubber stamp — the floor is what carries that guarantee. The
        # ceiling only exists to stop an anchor from swallowing a whole
        # line; it is loose because a real quote runs longer than a tidy
        # made-up one (staging-format.md's own worked example is 7 words).
        word_count = len(snippet.split())
        if not (ANCHOR_MIN_WORDS <= word_count <= ANCHOR_MAX_WORDS):
            problems.append(
                f"entry {key}: {section_name} anchor snippet is {word_count} words "
                f"{m.group(1)!r}, expected {ANCHOR_MIN_WORDS} to {ANCHOR_MAX_WORDS}"
            )
        # staging-format.md L156: `L<n>` is legal only when the transcript
        # (here, this entry's own excerpt) carries no clock. An `L<n>` on a
        # timed excerpt — or a clock time on an untimed one — can't be traced
        # back to anything the excerpt actually holds, which defeats the
        # anchor's whole job of pointing at a real line.
        coord = m.group(2)
        is_clock_coord = bool(CLOCK_COORD_RE.match(coord))
        if excerpt_mode == "clock" and not is_clock_coord:
            problems.append(
                f"entry {key}: {section_name} anchor coordinate {coord!r} is L<n>, but "
                "this entry's Source excerpt carries clock timestamps"
            )
        elif excerpt_mode == "line" and is_clock_coord:
            problems.append(
                f"entry {key}: {section_name} anchor coordinate {coord!r} is a clock time, "
                "but this entry's Source excerpt carries no timestamps"
            )
        elif excerpt_mode == "clock" and is_clock_coord:
            # Shape alone (checked above) never confirms the coordinate
            # points anywhere real — machine-contracts.md's rule that "a
            # reference that silently points at the wrong line is worse
            # than one that points nowhere" applies just as much to a
            # timestamp as to the file:line anchors that rule was written
            # for. So a clock coordinate has to name an actual turn in this
            # entry's excerpt, and the snippet has to actually be in that
            # turn — not just somewhere in the excerpt at large, which
            # would let a snippet and a coordinate from two different turns
            # pass by accident.
            turns = clock_turns.get(coord)
            if turns is None:
                problems.append(
                    f"entry {key}: {section_name} anchor coordinate {coord!r} does not "
                    "label any line in this entry's Source excerpt"
                )
            elif not any(snippet in turn for turn in turns):
                problems.append(
                    f"entry {key}: {section_name} anchor snippet {m.group(1)!r} does not "
                    f"appear on the {coord!r} line of this entry's Source excerpt"
                )

    context_lines = [l for l in sections.get("Context", []) if l.strip()]

    ac_content = [l for l in sections.get("Acceptance criteria", []) if l.strip()]
    ac_fields = []
    for line in ac_content:
        if not line.startswith("- [ ] "):
            problems.append(
                f"entry {key}: Acceptance criteria line does not start with '- [ ] ': {line!r}"
            )
            continue
        check_anchor(line, "Acceptance criteria")
        ac_fields.append(strip_anchor(line[len("- [ ] "):]))

    oos_content = [l for l in sections.get("Out of scope", []) if l.strip()]
    for line in oos_content:
        if not line.startswith("- "):
            problems.append(f"entry {key}: Out of scope line does not start with '- ': {line!r}")

    dep_content = [l for l in sections.get("Dependencies", []) if l.strip()]
    dep_keys = []
    for line in dep_content:
        if not line.startswith("- "):
            problems.append(f"entry {key}: Dependencies line does not start with '- ': {line!r}")
            continue
        check_anchor(line, "Dependencies")
        m = DEP_KEY_RE.match(line)
        if not m:
            problems.append(f"entry {key}: Dependencies line names no issue key: {line!r}")
            continue
        dkey = m.group(1)
        # staging-format.md also says a dependency key must be "in mentions:
        # or anchored" — but the Anchors section makes an anchor mandatory on
        # every non-empty Dependencies line regardless, so that clause is
        # already enforced by check_anchor above and is not a separate branch
        # to test here.
        if dkey == key:
            problems.append(f"entry {key}: Dependencies references its own key")
        elif dkey.split("-", 1)[0] not in projects:
            problems.append(f"entry {key}: Dependencies key {dkey} has a prefix not in projects")
        dep_keys.append(dkey)

    goal_content = [l for l in sections.get("Goal", []) if l.strip()]
    goal_field = None
    if len(goal_content) > 1:
        problems.append(f"entry {key}: Goal has {len(goal_content)} lines, expected at most 1")
    if goal_content:
        check_anchor(goal_content[0], "Goal")
        goal_field = strip_anchor(goal_content[0])

    oq_content = [l for l in sections.get("Open questions", []) if l.strip()]
    not_discussed = set()
    oq_fields = []
    for line in oq_content:
        if not line.startswith("- "):
            problems.append(f"entry {key}: Open questions line does not start with '- ': {line!r}")
            continue
        oq_fields.append(strip_bullet(line))
        m = re.match(r"^- not discussed: (.+)$", line)
        if not m:
            continue
        name = m.group(1)
        if name not in NOT_DISCUSSED_NAMES:
            problems.append(f"entry {key}: not-discussed names {name!r}, not a content section")
        elif name in not_discussed:
            problems.append(f"entry {key}: duplicate not-discussed line for {name!r}")
        not_discussed.add(name)

    # Every content section needs either a body or a matching not-discussed
    # line, and never both or neither. Open questions checks itself here too,
    # but its own not-discussed bookkeeping about the OTHER five sections is
    # genuine body text for Open questions (staging-format.md's own example
    # shows an Open questions section holding nothing but two such lines and
    # treats it as populated) — only a line naming "open questions" itself is
    # excluded, since that is the marker for Open questions being empty, not
    # its content.
    section_content = {
        "context": context_lines,
        "acceptance criteria": ac_content,
        "out of scope": oos_content,
        "dependencies": dep_content,
        "goal": goal_content,
        "open questions": [l for l in oq_content if l != "- not discussed: open questions"],
    }
    for name, content in section_content.items():
        label = next(s for s in CONTENT_SECTIONS if s.lower() == name)
        has_content = bool(content)
        has_marker = name in not_discussed
        if has_content and has_marker:
            problems.append(f"entry {key}: {label} has both content and a not-discussed line")
        elif not has_content and not has_marker:
            problems.append(f"entry {key}: {label} has neither content nor a not-discussed line")

    prov_lines = [l for l in sections.get("Provenance", []) if l.strip()]
    prov_values = {}
    if len(prov_lines) != 3:
        problems.append(
            f"entry {key}: Provenance has {len(prov_lines)} bullets, expected 3 "
            "(source, session, segment)"
        )
    else:
        malformed = False
        for name, line in zip(("source", "session", "segment"), prov_lines):
            prefix = f"- {name}: "
            if not line.startswith(prefix):
                problems.append(
                    f"entry {key}: Provenance bullets out of order or malformed at {line!r}, "
                    "expected '- source: ', '- session: ', '- segment: ' in that order"
                )
                malformed = True
                break
            prov_values[name] = line[len(prefix):].strip()
        if not malformed:
            if prov_values["source"] != fm.get("source"):
                problems.append(
                    f"entry {key}: Provenance source {prov_values['source']!r} != "
                    f"frontmatter source {fm.get('source')!r}"
                )
            if prov_values["session"] != fm.get("session"):
                problems.append(
                    f"entry {key}: Provenance session {prov_values['session']!r} != "
                    f"frontmatter session {fm.get('session')!r}"
                )

    fields = {
        "context": "\n".join(context_lines),
        "acceptance_criteria": ac_fields,
        "out_of_scope": "\n".join(strip_bullet(l) for l in oos_content),
        "dependencies": dep_keys,
        "goal": goal_field,
        "open_questions": oq_fields,
        "provenance": (
            f"source: {prov_values['source']}, session: {prov_values['session']}, "
            f"segment: {prov_values['segment']}"
            if len(prov_values) == 3 else ""
        ),
    }
    return problems, fields, sorted(not_discussed)


def parse_entry(key, region):
    """Split one entry's body (everything between its '## KEY' header and the
    next top-level header) into its key-value block and its '###' sections."""
    sub_headers = find_headers(region, "###")
    names = tuple(name for _, name in sub_headers)
    problems = []
    if names != ALL_SECTIONS:
        problems.append(
            f"entry {key}: sections are {list(names)}, expected {list(ALL_SECTIONS)} in order"
        )

    kv_end = sub_headers[0][0] if sub_headers else len(region)
    kv, mentions, kv_problems = check_entry_kv(key, region[:kv_end])
    problems.extend(kv_problems)

    sections = {}
    for i, (idx, name) in enumerate(sub_headers):
        next_idx = sub_headers[i + 1][0] if i + 1 < len(sub_headers) else len(region)
        sections[name] = region[idx + 1:next_idx]

    return kv, mentions, sections, problems


def split_body(lines, body_start, projects):
    """Everything after the frontmatter: the list of (key, header_lineno,
    region) entries, the Summary region (or None), and every structural
    problem found while locating them. Shared by both commands so `validate`
    and `entries` can never disagree about where one entry ends and the next
    begins."""
    body = lines[body_start:]
    headers = find_headers(body, "##")
    problems = []

    summary_pos = next((i for i, (_, name) in enumerate(headers) if name == "Summary"), None)
    if summary_pos is None:
        problems.append("no '## Summary' header found")
        entry_headers = headers
        summary_region = None
    else:
        entry_headers = headers[:summary_pos]
        for idx, name in headers[summary_pos + 1:]:
            problems.append(f"line {body_start + idx + 1}: unexpected '## {name}' header after Summary")
        summary_start = headers[summary_pos][0] + 1
        summary_end = headers[summary_pos + 1][0] if summary_pos + 1 < len(headers) else len(body)
        summary_region = body[summary_start:summary_end]

    boundary = headers[summary_pos][0] if summary_pos is not None else len(body)
    entries = []
    seen = {}
    for i, (idx, name) in enumerate(entry_headers):
        next_idx = entry_headers[i + 1][0] if i + 1 < len(entry_headers) else boundary
        lineno = body_start + idx + 1
        if not KEY_RE.match(name):
            problems.append(f"line {lineno}: malformed entry header '## {name}'")
            continue
        if name in seen:
            problems.append(f"line {lineno}: duplicate entry key {name!r}, first seen at line {seen[name]}")
        else:
            seen[name] = lineno
        prefix = name.split("-", 1)[0]
        if prefix not in projects:
            problems.append(f"line {lineno}: entry {name} prefix {prefix!r} not in frontmatter projects")
        entries.append((name, lineno, body[idx + 1:next_idx]))

    return entries, summary_region, problems


# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------


def run_validation(lines, body_start, fm, projects):
    """Every semantic check both commands need, run once. Returns (problems,
    parsed) where `parsed` is one (key, kv, fields, not_discussed) tuple per
    entry found — `entries` reuses these instead of re-walking the file, so
    what it emits is guaranteed to be exactly what `validate` graded rather
    than a second, possibly-diverging read of the same text."""
    problems = []
    entries, summary_region, structural_problems = split_body(lines, body_start, projects)
    problems.extend(structural_problems)

    parsed = []
    for key, _lineno, region in entries:
        kv, _mentions, sections, entry_problems = parse_entry(key, region)
        problems.extend(entry_problems)
        section_problems, fields, not_discussed = check_sections(key, sections, fm, projects)
        problems.extend(section_problems)
        parsed.append((key, kv, fields, not_discussed))

    if summary_region is not None:
        names = tuple(name for _, name in find_headers(summary_region, "###"))
        if names != SUMMARY_SUBSECTIONS:
            problems.append(
                f"Summary sections are {list(names)}, expected {list(SUMMARY_SUBSECTIONS)} in order"
            )

    return problems, parsed


def cmd_validate(args):
    lines = load_staging(args.staging).splitlines()
    fm, body_start, fatal, fm_line_problems = parse_frontmatter(lines)
    if fatal:
        sys.stderr.write(f"check-staging: {fatal}\n")
        return 3

    fm_value_problems, projects = check_frontmatter(fm)
    validation_problems, parsed = run_validation(lines, body_start, fm, projects)
    problems = fm_line_problems + fm_value_problems + validation_problems

    if problems:
        for problem in problems:
            sys.stderr.write(f"check-staging: {problem}\n")
        return 1

    print(f"OK: {len(parsed)} {'entry' if len(parsed) == 1 else 'entries'}")
    return 0


def cmd_entries(args):
    lines = load_staging(args.staging).splitlines()
    fm, body_start, fatal, fm_line_problems = parse_frontmatter(lines)
    if fatal:
        sys.stderr.write(f"check-staging: {fatal}\n")
        return 3

    # entries feeds jira-apply.py directly against a live tracker (see
    # SKILL.md's copy-paste pipeline), so it runs every check validate runs
    # and, on any problem, emits no JSON at all rather than fields read from
    # a broken parse. A truncated stream still feeds the pipe; the staging
    # gate exists so nothing unreviewed reaches a real ticket.
    fm_value_problems, projects = check_frontmatter(fm)
    validation_problems, parsed = run_validation(lines, body_start, fm, projects)
    problems = fm_line_problems + fm_value_problems + validation_problems

    if problems:
        for problem in problems:
            sys.stderr.write(f"check-staging: {problem}\n")
        return 1

    for key, kv, fields, not_discussed in parsed:
        status = kv.get("status")
        if args.status and status != args.status:
            continue
        obj = {
            "key": key,
            "status": status,
            "on_conflict": kv.get("on_conflict") or None,
            "session": fm.get("session", ""),
            "source": fm.get("source", ""),
            "label": fm.get("label", ""),
            "fields": fields,
            "not_discussed": not_discussed,
        }
        print(json.dumps(obj))

    return 0


def parse_args(argv=None):
    ap = argparse.ArgumentParser(
        description="Validate a jira-refine staging file, or emit its entries as JSON."
    )
    sub = ap.add_subparsers(dest="command", required=True)

    v = sub.add_parser("validate", help="enforce staging-format.md's grammar; the apply-mode gate")
    v.add_argument("staging", metavar="STAGING_MD", help="staging file, or '-' for stdin")
    v.set_defaults(func=cmd_validate)

    e = sub.add_parser("entries", help="emit approved (or --status-filtered) entries as JSON lines")
    e.add_argument("staging", metavar="STAGING_MD", help="staging file, or '-' for stdin")
    e.add_argument("--status", metavar="STATUS", help="only emit entries with this status")
    e.set_defaults(func=cmd_entries)

    return ap.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
