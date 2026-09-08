#!/usr/bin/env python3
"""Turn a refinement-session transcript into segments keyed by the Jira issue
numbers the room spoke aloud, and print a jira-refine staging skeleton.

    segment.py TRANSCRIPT --config PATH --session-date YYYY-MM-DD
               [--json] [--min-words N] [--label L]

The transcript is sniffed as VTT, SRT, or plain text (first line `WEBVTT`;
a bare-digit line followed by a comma-millis `-->` line; else text), then
collapsed into speaker turns the way inbox-to-memory's collapse-vtt.sh
collapses a caption file: cues merge into one turn per speaker run, and the
words themselves are never altered, only regrouped.

A turn is scanned for the project keys the session's config says this room
speaks aloud (`projects` plus `[spoken_aliases]`), in digit or English
number-word form. A key occurrence opens a new segment — a boundary — when
it lands in the turn's first `boundary_window_words` words or within four
words after a `boundary_cues` phrase; anywhere else it is a mention,
credited to whichever segment is currently open. A key that opens a second,
later segment is a revisit, and its later span is appended to the first
entry rather than starting a second one. Turns before the first boundary are
preamble. A segment whose word count falls under `min_segment_words` is
demoted out of the entry list into the "mentioned in passing" summary,
alongside keys that were only ever mentioned and never opened a segment at
all.

The default output is the staging skeleton: frontmatter, one `## KEY` entry
per surviving segment with its eight sections (all empty — filling them from
the excerpt is the next step's job, done by a person or an agent reading the
file, not by this script), and a `## Summary` with the script's own
`long`/`revisited` flags under Spike candidates and the demoted or
mention-only keys under Mentioned in passing. `--json` dumps the same
underlying data instead, for a human or an agent to inspect before it is
turned into prose.

Exit codes: 0 success; 1 no project key was ever heard as a boundary, so
there is nothing to stage; 3 usage, an unreadable transcript or config, a
config missing `projects`, or a Python below the 3.11 floor `tomllib`
needs. Argparse supplies 2 for a mistyped flag.

Stdlib only, so the skill stays copy-in portable.
"""
import argparse
import datetime as dt
import json
import os
import re
import statistics
import sys

MIN_PYTHON = (3, 11)

# Every key below matches the same-named default in jira-refine.example.toml.
# A user's config only has to state what it overrides.
DEFAULTS = {
    "min_segment_words": 40,
    "boundary_window_words": 6,
    "boundary_cues": ["okay", "ok", "next", "next up", "let's do", "moving on", "on to", "now"],
    "long_factor": 2,
    "label_prefix": "refined-",
}

CONTENT_SECTIONS = ["context", "acceptance criteria", "out of scope", "dependencies", "goal"]

ONES = {
    "zero": 0, "one": 1, "two": 2, "three": 3, "four": 4,
    "five": 5, "six": 6, "seven": 7, "eight": 8, "nine": 9,
}
TEENS = {
    "ten": 10, "eleven": 11, "twelve": 12, "thirteen": 13, "fourteen": 14,
    "fifteen": 15, "sixteen": 16, "seventeen": 17, "eighteen": 18, "nineteen": 19,
}
TENS = {
    "twenty": 20, "thirty": 30, "forty": 40, "fifty": 50,
    "sixty": 60, "seventy": 70, "eighty": 80, "ninety": 90,
}
NUMBER_WORD_TOKENS = set(ONES) | set(TEENS) | set(TENS) | {"hundred", "thousand", "and"}

SPEAKER_LINE_RE = re.compile(r"^([A-Z][A-Za-z.' -]*): (.*)$")
CLOCK_SPEAKER_LINE_RE = re.compile(r"^\[(\d\d:\d\d:\d\d)\]\s*([A-Z][A-Za-z.' -]*):\s*(.*)$")
VOICE_SPAN_RE = re.compile(r"^<v ([^>]*)>(.*)$")
VOICE_END_RE = re.compile(r"</v>\s*$")

# NOTE, STYLE, and REGION are WebVTT's block constructs: each opens on a line
# starting with the keyword (NOTE may carry trailing text on that same line;
# STYLE and REGION stand alone) and runs through every following line up to
# the blank line that terminates it. None of that body is speech.
VTT_BLOCK_START_RE = re.compile(r"^(?:NOTE|STYLE|REGION)(?:$|[ \t])")


class Turn:
    """One collapsed speaker turn: `start` is 'HH:MM:SS' or None, `line` is
    the 1-based source line of the turn's first contributing line. `line` is
    kept even when `start` is set, because a no-clock transcript needs it for
    the `L<n>` anchor form and a clock transcript costs nothing to carry it.

    `cues` records every caption cue folded into this turn, as
    `(word_start, start, line)` triples sorted by `word_start` (always
    starting with `(0, start, line)` for the turn's own first cue) — the
    word offset into `text` where each cue began, and that cue's own clock
    and source line. It exists because a speakerless caption file merges
    every cue into one long `unknown` turn (see `parse_captions`), and
    without it a ticket key spoken at the start of the turn's third cue
    read as buried mid-turn: boundary detection only ever looked at words
    near the *turn's* start, and any segment built from that key would have
    reported the first cue's clock and line instead of its own. Labelled
    transcripts rarely fold multiple cues into one turn, so this is a no-op
    for them; `cues` is just `[(0, start, line)]`, identical to the turn's
    own fields."""

    __slots__ = ("start", "line", "speaker", "text", "cues")

    def __init__(self, start, line, speaker, text, cues=None):
        self.start = start
        self.line = line
        self.speaker = speaker
        self.text = text
        self.cues = list(cues) if cues is not None else [(0, start, line)]


# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------


def read_text_file(path, label):
    """Read `path` as UTF-8, or exit 3. Anything wrong here is an environment
    problem rather than a transcript problem, and the two exit codes stay
    separate so a caller can tell 'your file isn't readable' from 'nothing
    was heard as a boundary'."""
    try:
        with open(path, encoding="utf-8") as f:
            return f.read()
    except OSError as e:
        sys.stderr.write(f"segment: {label}: {e}\n")
        raise SystemExit(3)
    except UnicodeDecodeError as e:
        sys.stderr.write(f"segment: {label}: not valid UTF-8: {e}\n")
        raise SystemExit(3)


def load_config(path):
    """Parse the TOML config and fold in defaults. `projects` is the one key
    with no default — the pattern that finds a key in the transcript is
    derived from it at run time, so a config that never names a project would
    silently match nothing, which is a config bug rather than an empty
    session."""
    import tomllib  # deferred: importing this on Python < 3.11 would raise

    try:
        with open(path, "rb") as f:
            raw = tomllib.load(f)
    except OSError as e:
        sys.stderr.write(f"segment: {path}: {e}\n")
        raise SystemExit(3)
    except tomllib.TOMLDecodeError as e:
        sys.stderr.write(f"segment: {path}: not valid TOML: {e}\n")
        raise SystemExit(3)

    projects = raw.get("projects")
    if not projects or not isinstance(projects, list):
        sys.stderr.write(f"segment: {path}: missing or empty `projects`\n")
        raise SystemExit(3)

    cfg = dict(DEFAULTS)
    cfg.update(raw)
    cfg["projects"] = list(projects)
    cfg["spoken_aliases"] = raw.get("spoken_aliases", {})
    return cfg


# ---------------------------------------------------------------------------
# Format sniffing and turn parsing
# ---------------------------------------------------------------------------


def sniff_format(text):
    lines = [l for l in text.splitlines() if l.strip() != ""]
    if not lines:
        return "text"
    if lines[0].strip().upper().startswith("WEBVTT"):
        return "vtt"
    if re.fullmatch(r"\d+", lines[0].strip()) and len(lines) > 1:
        if re.match(r"^\s*\d{1,2}(?::\d{2}){1,2},\d{3}\s*-->", lines[1]):
            return "srt"
    return "text"


def normalize_clock(raw):
    """'MM:SS' or 'HH:MM:SS' (fractional seconds already stripped by the
    caller) to a zero-padded 'HH:MM:SS'."""
    parts = raw.strip().split(":")
    if len(parts) == 2:
        h, m, s = "0", parts[0], parts[1]
    else:
        h, m, s = parts
    return f"{int(h):02d}:{int(m):02d}:{int(float(s)):02d}"


def parse_captions(text, timing_re):
    """Shared VTT/SRT collapse. Reimplements collapse-vtt.sh's rules — skip
    the header/blank/bare-id lines and whole NOTE/STYLE/REGION blocks,
    `<v Name>` or `Name: ` opens a turn, a non-matching line continues the
    open turn, words are never altered — parameterized on the timing line's
    regex so the same walk serves both caption formats; SRT's only
    difference from VTT is a comma before the millis instead of a dot."""
    turns = []
    speaker = None
    text_parts = []
    cues = []
    start = None
    start_line = None
    pending_start = None
    # Set the instant a timing line is consumed, and cleared by the very
    # next contributing text line — the line that follows it directly. That
    # line is where its cue's words begin; any further physical lines under
    # the same cue (before the blank line that ends it) are the same
    # utterance continuing, not a new one.
    cue_pending = False
    # A block, once opened, swallows every line — including ones that would
    # otherwise look like a cue id or a timing line — until the blank line
    # that closes it, per the WebVTT grammar.
    in_block = False

    def flush():
        nonlocal speaker, text_parts, cues
        if speaker is not None:
            turns.append(Turn(start, start_line, speaker, " ".join(text_parts), cues))
        speaker = None
        text_parts = []
        cues = []

    for lineno, raw in enumerate(text.splitlines(), start=1):
        line = raw.rstrip("\r")
        if not line.strip():
            in_block = False
            continue
        if in_block:
            continue
        if line.strip().upper().startswith("WEBVTT"):
            continue
        if VTT_BLOCK_START_RE.match(line):
            # Skipping only this opening line (the original bug) let every
            # later line in the block fall through to the speaker branch
            # below, where a line with no `<v Name>` or `Name:` prefix reads
            # as a continuation of whatever turn is still open. That turned
            # editor commentary — e.g. a NOTE explaining a ticket was pulled
            # from scope — into words credited to a speaker, and once a key
            # like PROJ-900 showed up in that swallowed prose it was staged
            # as a ticket nobody actually spoke. Skip the whole block instead.
            in_block = True
            continue
        if re.fullmatch(r"\d+", line.strip()):
            continue  # cue identifier / SRT index — carries nothing
        m = timing_re.match(line)
        if m:
            pending_start = normalize_clock(m.group(1))
            cue_pending = True
            continue

        vm = VOICE_SPAN_RE.match(line)
        if vm:
            who, said = vm.group(1), vm.group(2)
        else:
            sm = SPEAKER_LINE_RE.match(line)
            if sm:
                who, said = sm.group(1), sm.group(2)
            elif speaker is not None:
                who, said = speaker, line  # continuation of the open turn
            else:
                # No turn is open yet, so this line has nothing to continue.
                # Treating it as a continuation of `speaker=None` (the old
                # behavior) meant `flush()` saw `speaker is None` and never
                # recorded the turn at all — a caption file with no speaker
                # labels anywhere, the common shape for machine-generated
                # transcripts, silently produced zero turns and the ticket
                # keys spoken in it vanished with no boundary ever found.
                # Open a turn instead, attributed the way inbox-to-memory
                # attributes unlabelled speech to `@unknown`: an admitted
                # gap beats a guessed name. `who != speaker` below then
                # opens this turn same as any other speaker change, and a
                # later unlabelled line finds `speaker == "unknown"` and
                # continues it rather than opening a second one.
                who, said = "unknown", line
        said = VOICE_END_RE.sub("", said)

        if who != speaker:
            flush()
            speaker = who
            start = pending_start
            start_line = lineno
            cues.append((0, start, start_line))
        elif cue_pending:
            # Same turn, but a new cue started it — record where, and with
            # which clock and line, so a key spoken in this cue's opening
            # words can still qualify as a boundary even though it lands
            # well past word 0 of the merged turn, and a segment built from
            # it reports this cue's own timing rather than the turn's
            # first. `word_index_at` reads word counts, so the offset is
            # counted the same way: words already banked in `text_parts`.
            cues.append((sum(len(p.split()) for p in text_parts), pending_start, lineno))
        cue_pending = False
        text_parts.append(said)
    flush()
    return turns


VTT_TIMING_RE = re.compile(r"^\s*(\d{1,2}(?::\d{2}){1,2})\.\d{3}\s*-->")
SRT_TIMING_RE = re.compile(r"^\s*(\d{1,2}(?::\d{2}){1,2}),\d{3}\s*-->")


def parse_text_transcript(text):
    """Plain text, in the order the plan names: `[HH:MM:SS] Name: text`
    lines throughout, else `Name: text` lines throughout, else paragraphs
    anchored by line number. The whole file commits to one of the three —
    a transcript doesn't switch shape mid-file — so the mode is decided once
    from every non-blank line before any turn is built."""
    lines = text.splitlines()
    numbered = list(enumerate(lines, start=1))
    has_clock_speaker = any(CLOCK_SPEAKER_LINE_RE.match(l) for _, l in numbered if l.strip())
    has_speaker = any(SPEAKER_LINE_RE.match(l) for _, l in numbered if l.strip())

    if has_clock_speaker:
        turns = []
        speaker = None
        start = None
        start_line = None
        parts = []

        def flush():
            nonlocal speaker, parts
            if speaker is not None:
                turns.append(Turn(start, start_line, speaker, " ".join(parts)))
            speaker, parts = None, []

        for lineno, line in numbered:
            if not line.strip():
                continue
            m = CLOCK_SPEAKER_LINE_RE.match(line)
            if m:
                who, said = m.group(2), m.group(3)
                # Same speaker as the open turn continues it rather than
                # starting a new one — the cue-based parsers merge back-to-
                # back same-speaker cues the identical way, and a transcript
                # shouldn't be segmented differently just because it names
                # its speaker on every line instead of only on a change.
                if who != speaker:
                    flush()
                    speaker, start, start_line = who, m.group(1), lineno
                parts.append(said)
            else:
                parts.append(line.strip())
        flush()
        return turns, True

    if has_speaker:
        turns = []
        speaker = None
        start_line = None
        parts = []

        def flush():
            nonlocal speaker, parts
            if speaker is not None:
                turns.append(Turn(None, start_line, speaker, " ".join(parts)))
            speaker, parts = None, []

        for lineno, line in numbered:
            if not line.strip():
                continue
            m = SPEAKER_LINE_RE.match(line)
            if m:
                who, said = m.group(1), m.group(2)
                if who != speaker:
                    flush()
                    speaker, start_line = who, lineno
                parts.append(said)
            else:
                parts.append(line.strip())
        flush()
        return turns, False

    # No speaker markers anywhere: each blank-line-separated paragraph is its
    # own anonymous turn, anchored at its first line.
    turns = []
    para_lines = []
    para_start = None
    for lineno, line in numbered:
        if line.strip():
            if not para_lines:
                para_start = lineno
            para_lines.append(line.strip())
        elif para_lines:
            turns.append(Turn(None, para_start, "", " ".join(para_lines)))
            para_lines = []
    if para_lines:
        turns.append(Turn(None, para_start, "", " ".join(para_lines)))
    return turns, False


def parse_transcript(text):
    """Return (turns, has_clock)."""
    fmt = sniff_format(text)
    if fmt == "vtt":
        return parse_captions(text, VTT_TIMING_RE), True
    if fmt == "srt":
        return parse_captions(text, SRT_TIMING_RE), True
    return parse_text_transcript(text)


# ---------------------------------------------------------------------------
# Spoken key recognition
# ---------------------------------------------------------------------------

_NUMBER_WORD_ALT = "|".join(sorted(NUMBER_WORD_TOKENS, key=len, reverse=True))
_NUMBER_WORD_RUN = rf"(?:{_NUMBER_WORD_ALT})(?:\s+(?:{_NUMBER_WORD_ALT}))*"
_NUMBER_PART = rf"(?:\d+|{_NUMBER_WORD_RUN})"
_SEP = r"\s*(?:-|\u2013|\u2014|dash|hyphen)?\s*"


def _flexible(word):
    """A prefix or alias, case-insensitive, with internal whitespace loosened
    to `\\s*` per the plan's key-pattern rule — so a config that writes an
    alias with its own spacing still matches a room that says it tighter or
    looser."""
    return r"\s*".join(re.escape(tok) for tok in word.split())


def build_project_regex(project, aliases):
    """The key pattern is derived from `projects` plus `[spoken_aliases]` at
    run time — never hardcoded — because a session names its own projects,
    not a fixed regex. `num` captures the raw digits or number-word run so
    the caller can canonicalize it separately from matching it."""
    forms = sorted({project, *aliases}, key=len, reverse=True)
    prefix_pattern = "|".join(_flexible(f) for f in forms)
    pattern = rf"\b(?:{prefix_pattern})\b{_SEP}\b(?P<num>{_NUMBER_PART})\b"
    return re.compile(pattern, re.IGNORECASE)


def _concatenate_digits(tokens):
    """Digit-by-digit or leading-digit-plus-remainder reading, used when no
    'hundred'/'thousand'/'and' is present: 'four one two' -> '4'+'1'+'2', and
    'four twelve' -> '4'+'12' — a ticket number read as a run of short groups,
    not summed by place value the way a quantity would be. Returns None on a
    token this grammar doesn't cover (unreachable in practice, since the
    regex only ever admits number-word vocabulary)."""
    groups = []
    i = 0
    while i < len(tokens):
        tok = tokens[i]
        if tok in ONES:
            groups.append(str(ONES[tok]))
            i += 1
        elif tok in TEENS:
            groups.append(str(TEENS[tok]))
            i += 1
        elif tok in TENS:
            val = TENS[tok]
            if i + 1 < len(tokens) and tokens[i + 1] in ONES and ONES[tokens[i + 1]] != 0:
                val += ONES[tokens[i + 1]]
                i += 2
            else:
                i += 1
            groups.append(str(val))
        else:
            return None
    return "".join(groups)


def _compositional(tokens):
    """Standard English number reading — 'four hundred twelve' -> 412 — used
    whenever a multiplier word is present, since a leading digit before
    'hundred' or 'thousand' names a place value rather than a literal digit
    to concatenate."""
    current = 0
    result = 0
    for tok in tokens:
        if tok == "and":
            continue
        if tok in ONES:
            current += ONES[tok]
        elif tok in TEENS:
            current += TEENS[tok]
        elif tok in TENS:
            current += TENS[tok]
        elif tok == "hundred":
            current = (current or 1) * 100
        elif tok == "thousand":
            result += (current or 1) * 1000
            current = 0
    return str(result + current)


def canonicalize_number(raw):
    """A matched `num` group — digits or a number-word run — to a plain
    digit string. Scope is 0-9999 (Known Limitations), which the two
    grammars above cover without ambiguity: a multiplier word always means
    composition, its absence always means concatenation."""
    stripped = raw.strip()
    if re.fullmatch(r"\d+", stripped):
        return stripped
    tokens = stripped.lower().split()
    if any(t in ("hundred", "thousand", "and") for t in tokens):
        return _compositional(tokens)
    return _concatenate_digits(tokens) or stripped


def build_cue_regex(cues):
    if not cues:
        return None
    parts = [r"\s+".join(re.escape(w) for w in c.split()) for c in sorted(cues, key=lambda c: -len(c.split()))]
    return re.compile(r"\b(?:" + "|".join(parts) + r")\b", re.IGNORECASE)


def word_index_at(text, char_pos):
    """How many whitespace-separated words precede `char_pos` — the position
    a boundary-window check reads, since the rule is stated in words, not
    characters."""
    return len(text[:char_pos].split())


# ---------------------------------------------------------------------------
# Segmentation
# ---------------------------------------------------------------------------


def _enclosing_cue_start(cues, idx):
    """The word-offset of the last entry in `turn.cues` at or before `idx`
    — which cue a word offset falls in, identified by that cue's own start
    word (unique per turn, so it doubles as the cue's key). `cues` is
    ascending by construction (cues are appended in the order they're
    read), so the last entry not past `idx` is the one that opened it."""
    region = cues[0][0]
    for word_start, _start, _line in cues:
        if word_start > idx:
            break
        region = word_start
    return region


def analyze_turns(turns, project_regexes, cue_re, boundary_window_words):
    """Walk every turn once, sorting each turn's key matches left to right.
    The plan's rule for two keys in one utterance — first is a boundary,
    a second qualifying one is a 'co-discussed' flag rather than a second
    boundary — only makes sense evaluated in that left-to-right order, so a
    single per-turn pass does both boundary detection and mention
    collection together rather than in two passes that would have to agree
    on ordering independently.

    'One utterance' is scoped to a cue, not the whole turn: a speakerless
    caption file folds every cue into one `unknown` turn (see
    `parse_captions`), and without that narrower scope the first key in the
    turn would claim the turn's one boundary slot and every key spoken in a
    later cue — a fresh thought to whoever said it — would read as merely
    co-discussed with the first. `_enclosing_cue_start` is what tells two
    matches apart as 'same cue' or 'different cues'; for an ordinary turn
    (one cue, `cues == [(0, ...)]`) every match maps to the same region and
    this reduces to the original one-boundary-per-turn behavior.

    Every event this returns carries `cue_start` — the word offset (within
    its turn) of the cue it landed in — alongside `turn_idx`, because a
    turn split across several boundaries needs finer than turn granularity
    downstream: `build_spans` and `attribute_mentions` place both boundaries
    and mentions onto per-cue atoms, not whole turns, so that a key opened
    by a later cue doesn't inherit an earlier cue's clock, line, or word
    count."""
    boundaries = []
    co_discussed = []
    mention_events = []
    all_keys_seen = []

    for turn_idx, turn in enumerate(turns):
        text = turn.text
        matches = []
        for project, rx in project_regexes.items():
            for m in rx.finditer(text):
                key = f"{project}-{canonicalize_number(m.group('num'))}"
                matches.append((m.start(), project, key))
        if not matches:
            continue
        matches.sort(key=lambda t: t[0])

        cue_end_words = [word_index_at(text, m.end()) for m in cue_re.finditer(text)] if cue_re else []

        boundary_key_by_cue = {}
        for start_char, project, key in matches:
            idx = word_index_at(text, start_char)
            # `turn.cues` is `[(0, ...)]` for an ordinary turn, so this
            # already covers the plain turn-start case; a merged speakerless
            # turn carries one entry per folded-in cue, so a key opening any
            # of them qualifies too — the cue, not the turn, is the unit of
            # utterance once there is no speaker label to mark a fresh turn.
            qualifies = any(
                cs <= idx < cs + boundary_window_words for cs, _s, _l in turn.cues
            ) or any(ce <= idx < ce + 4 for ce in cue_end_words)
            all_keys_seen.append(key)
            cue_start = _enclosing_cue_start(turn.cues, idx)
            if qualifies and cue_start not in boundary_key_by_cue:
                boundaries.append({"turn_idx": turn_idx, "cue_start": cue_start, "key": key, "project": project})
                boundary_key_by_cue[cue_start] = key
            elif qualifies:
                co_discussed.append((turn_idx, boundary_key_by_cue[cue_start], key))
            else:
                mention_events.append({"turn_idx": turn_idx, "cue_start": cue_start, "key": key})

    return boundaries, co_discussed, mention_events, all_keys_seen


def build_atoms(turns):
    """Flatten every turn's `cues` into one atom per cue: `word_start` and
    `word_end` slice that cue's own words out of the turn's merged `text`,
    and `start`/`line` are that cue's own timing rather than the turn's.
    `atom_index` maps `(turn_idx, cue_start)` — the same pair every boundary
    and mention event in `analyze_turns` carries — to a position in the
    flat, document-ordered `atoms` list, which is what lets `build_spans`
    and `attribute_mentions` work in cue units without threading turn
    internals through them. An ordinary turn (`cues == [(0, ...)]`) yields
    exactly one atom spanning its whole text, so this is a straight
    relabeling for every transcript this bug doesn't touch."""
    atoms = []
    atom_index = {}
    for turn_idx, turn in enumerate(turns):
        words = turn.text.split()
        for i, (word_start, start, line) in enumerate(turn.cues):
            word_end = turn.cues[i + 1][0] if i + 1 < len(turn.cues) else len(words)
            atom_index[(turn_idx, word_start)] = len(atoms)
            atoms.append({
                "turn_idx": turn_idx,
                "word_start": word_start,
                "word_end": word_end,
                "start": start,
                "line": line,
                "speaker": turn.speaker,
                "text": " ".join(words[word_start:word_end]),
            })
    return atoms, atom_index


def build_spans(boundaries, atoms, atom_index):
    """One span per boundary, running to the atom before the next boundary
    (or to the transcript's last atom). A span's 'end' is its own last
    atom's start time/line rather than the next span's first atom — the same
    choice collapse-vtt.sh makes by discarding cue end times entirely, since
    nothing downstream of the collapse ever has a true end-of-speech moment
    to read.

    Spans are built over atoms — one atom per cue, see `build_atoms` — and
    not whole turns, because `analyze_turns` now lets more than one boundary
    open inside a single merged speakerless turn: whichever cue a key opens
    in, only that cue's words and timing belong to its segment. An ordinary
    turn has exactly one atom, so a labelled transcript (where two turns
    almost never share a boundary) sees no change in behavior — this is
    just the old whole-turn slicing at finer grain."""
    spans = []
    for i, b in enumerate(boundaries):
        start_atom = atom_index[(b["turn_idx"], b["cue_start"])]
        if i + 1 < len(boundaries):
            nb = boundaries[i + 1]
            end_atom = atom_index[(nb["turn_idx"], nb["cue_start"])] - 1
        else:
            end_atom = len(atoms) - 1
        first_atom = atoms[start_atom]
        last_atom = atoms[end_atom]
        words = sum(a["word_end"] - a["word_start"] for a in atoms[start_atom:end_atom + 1])
        spans.append({
            "key": b["key"],
            "project": b["project"],
            "atom_start": start_atom,
            "atom_end": end_atom,
            "words": words,
            "start": first_atom["start"],
            "end": last_atom["start"],
            "start_line": first_atom["line"],
            "end_line": last_atom["line"],
            "mentions": set(),
        })
    return spans


def attribute_mentions(spans, mention_events, atom_index):
    atom_to_span = {}
    for i, span in enumerate(spans):
        for a in range(span["atom_start"], span["atom_end"] + 1):
            atom_to_span[a] = i
    for ev in mention_events:
        a = atom_index.get((ev["turn_idx"], ev["cue_start"]))
        i = atom_to_span.get(a)
        if i is None:
            continue  # preamble mention: no open segment to credit it to
        span = spans[i]
        if ev["key"] != span["key"]:
            span["mentions"].add(ev["key"])


def clock_to_seconds(clock):
    h, m, s = (int(p) for p in clock.split(":"))
    return h * 3600 + m * 60 + s


def seconds_to_duration(total):
    total = max(0, total)
    return f"{total // 60}m{total % 60}s"


def segment_transcript(turns, has_clock, cfg, min_words):
    projects = cfg["projects"]
    aliases_cfg = cfg["spoken_aliases"]
    project_regexes = {p: build_project_regex(p, aliases_cfg.get(p, [])) for p in projects}
    cue_re = build_cue_regex(cfg["boundary_cues"])

    boundaries, co_discussed, mention_events, all_keys_seen = analyze_turns(
        turns, project_regexes, cue_re, cfg["boundary_window_words"]
    )
    if not boundaries:
        return None

    atoms, atom_index = build_atoms(turns)
    spans = build_spans(boundaries, atoms, atom_index)
    attribute_mentions(spans, mention_events, atom_index)

    spans_by_key = {}
    ordered_keys = []
    for span in spans:
        if span["key"] not in spans_by_key:
            ordered_keys.append(span["key"])
        spans_by_key.setdefault(span["key"], []).append(span)

    co_discussed_by_key = {}
    for turn_idx, boundary_key, other_key in co_discussed:
        co_discussed_by_key.setdefault(boundary_key, []).append(other_key)

    entries = []
    passing = []
    for key in ordered_keys:
        key_spans = spans_by_key[key]
        words = sum(s["words"] for s in key_spans)
        if words < min_words:
            passing.append({"key": key, "reason": "demoted", "words": words})
            continue
        mentions = sorted(set().union(*(s["mentions"] for s in key_spans)) - {key})
        entries.append({
            "key": key,
            "project": key_spans[0]["project"],
            "words": words,
            "revisited": len(key_spans) - 1,
            "mentions": mentions,
            "co_discussed": sorted(set(co_discussed_by_key.get(key, []))),
            "start": key_spans[0]["start"],
            "end": key_spans[-1]["end"],
            "start_line": key_spans[0]["start_line"],
            "end_line": key_spans[-1]["end_line"],
            "atoms": [a for s in key_spans for a in range(s["atom_start"], s["atom_end"] + 1)],
        })

    mention_only = set(all_keys_seen) - set(spans_by_key)
    for key in sorted(mention_only):
        passing.append({"key": key, "reason": "mentioned-only", "count": all_keys_seen.count(key)})

    # Duration and the `long` flag both need a session median, and neither
    # means anything without real clock times to measure — a plain-text
    # transcript with no timestamps gets neither, per the format's own rule
    # that `duration:` is empty in that case.
    if has_clock:
        for e in entries:
            e["duration_seconds"] = clock_to_seconds(e["end"]) - clock_to_seconds(e["start"])
        durations = [e["duration_seconds"] for e in entries]
        median = statistics.median(durations) if durations else 0
        long_factor = cfg["long_factor"]
        for e in entries:
            e["long"] = bool(median > 0 and e["duration_seconds"] > long_factor * median)
        median_duration = median
    else:
        for e in entries:
            e["duration_seconds"] = None
            e["long"] = False
        median_duration = None

    preamble_end = boundaries[0]["turn_idx"]
    # Atoms, not turns: the first boundary can now open mid-turn — a later
    # cue of the very turn it's in — so summing whole turns before it would
    # miss that turn's own earlier cues, which are preamble too.
    first_atom = atom_index[(boundaries[0]["turn_idx"], boundaries[0]["cue_start"])]
    preamble_words = sum(a["word_end"] - a["word_start"] for a in atoms[:first_atom])

    return {
        "entries": entries,
        "passing": passing,
        "preamble": {"turns": preamble_end, "words": preamble_words},
        "median_duration_seconds": median_duration,
        "has_clock": has_clock,
    }


# ---------------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------------


def render_atom_line(atom, has_clock):
    label = f"[{atom['start']}]" if has_clock and atom["start"] else f"[L{atom['line']}]"
    if atom["speaker"]:
        return f"{label} {atom['speaker']}: {atom['text']}"
    return f"{label} {atom['text']}"


def section_block(heading, body_lines):
    """A `### Heading` plus its body (if any) plus the one blank line that
    always separates it from whatever comes next — the shape every section
    in staging-format.md's example uses, filled or empty alike, so building
    every section through this one helper is what keeps that spacing
    uniform without hand-tracking blank lines at each call site."""
    return [heading, *body_lines, ""]


def mentions_str(keys):
    return "[" + ", ".join(keys) + "]" if keys else "[]"


def build_entry_lines(entry, source, session, has_clock):
    if has_clock:
        segment_str = f"{entry['start']} - {entry['end']}"
        duration_str = seconds_to_duration(entry["duration_seconds"])
    else:
        segment_str = f"L{entry['start_line']} - L{entry['end_line']}"
        duration_str = ""

    lines = [f"## {entry['key']}", ""]
    lines += [
        "status: staged",
        f"segment: {segment_str}",
        f"duration: {duration_str}",
        f"words: {entry['words']}",
        f"revisited: {entry['revisited']}",
        f"mentions: {mentions_str(entry['mentions'])}",
        "",
    ]
    # Nothing has been read from the excerpt yet — that is the next step's
    # job — so every content section is empty and every one of them gets its
    # `not discussed` line; Open questions is therefore never itself empty.
    for heading in ("Context", "Acceptance criteria", "Out of scope", "Dependencies", "Goal"):
        lines += section_block(f"### {heading}", [])
    not_discussed = [f"- not discussed: {name}" for name in CONTENT_SECTIONS]
    lines += section_block("### Open questions", not_discussed)
    provenance = [
        f"- source: {source}",
        f"- session: {session}",
        f"- segment: {segment_str}",
    ]
    lines += section_block("### Provenance", provenance)
    excerpt = [render_atom_line(ATOM_LOOKUP[i], has_clock) for i in entry["atoms"]]
    fenced = ["```text", *excerpt, "```"]
    lines += section_block("### Source excerpt", fenced)
    return lines


def build_spike_candidates(entries, has_clock, median_duration, long_factor):
    bullets = []
    for e in entries:
        if e["revisited"] > 0:
            bullets.append(f"- {e['key']}: revisited {e['revisited']}x")
        if has_clock and e["long"]:
            bullets.append(
                f"- {e['key']}: long ({seconds_to_duration(e['duration_seconds'])} > "
                f"{long_factor}x median {seconds_to_duration(int(median_duration))})"
            )
        for other in e["co_discussed"]:
            bullets.append(f"- {e['key']} co-discussed with {other} in the same utterance")
    return bullets


def build_passing_bullets(passing, min_words):
    bullets = []
    for p in passing:
        if p["reason"] == "demoted":
            bullets.append(f"- {p['key']} ({p['words']} words; below the {min_words}-word minimum)")
        else:
            bullets.append(f"- {p['key']} (mentioned only, {p['count']}x)")
    return bullets


def build_skeleton(result, frontmatter, source, session, min_words, long_factor):
    lines = ["---"]
    for k in ("skill", "schema", "source", "source_path", "session", "label", "config", "projects", "generated"):
        v = frontmatter[k]
        if k == "projects":
            v = "[" + ", ".join(v) + "]"
        lines.append(f"{k}: {v}")
    lines.append("---")
    lines.append("")

    for entry in result["entries"]:
        lines += build_entry_lines(entry, source, session, result["has_clock"])

    lines.append("## Summary")
    lines.append("")
    spike = build_spike_candidates(result["entries"], result["has_clock"], result["median_duration_seconds"], long_factor)
    lines += section_block("### Spike candidates", spike)
    passing = build_passing_bullets(result["passing"], min_words)
    lines += section_block("### Mentioned in passing", passing)
    lines += section_block("### Gaps to file", [])
    lines += section_block("### Apply log", [])

    return "\n".join(lines).rstrip("\n") + "\n"


def build_json(result, frontmatter, min_words, long_factor):
    entries = []
    for e in result["entries"]:
        entries.append({
            "key": e["key"],
            "status": "staged",
            "segment": {"start": e["start"], "end": e["end"], "start_line": e["start_line"], "end_line": e["end_line"]},
            "duration_seconds": e["duration_seconds"],
            "words": e["words"],
            "revisited": e["revisited"],
            "mentions": e["mentions"],
            "co_discussed": e["co_discussed"],
            "long": e["long"],
        })
    passing = [dict(p) for p in result["passing"]]
    return {
        "frontmatter": frontmatter,
        "entries": entries,
        "passing": passing,
        "preamble": result["preamble"],
        "stats": {
            "boundaries": len(result["entries"]),
            "revisited_total": sum(e["revisited"] for e in result["entries"]),
            "mentioned_in_passing": len(passing),
            "median_duration_seconds": result["median_duration_seconds"],
            "has_clock": result["has_clock"],
            "min_segment_words": min_words,
            "long_factor": long_factor,
        },
    }


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

SESSION_DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")

# build_entry_lines needs each atom (one per caption cue — see build_atoms)
# by its transcript-wide index to render an entry's excerpt; threading it
# through every call in the render chain would turn a read-only lookup into
# a parameter on functions that otherwise only care about one entry, so it
# is set once per run instead. build_atoms is a pure function of `turns`, so
# rebuilding it here reproduces exactly the indices segment_transcript used.
ATOM_LOOKUP = []


def parse_args(argv=None):
    ap = argparse.ArgumentParser(
        description="Segment a refinement-session transcript into a jira-refine staging skeleton."
    )
    ap.add_argument("transcript", metavar="TRANSCRIPT")
    ap.add_argument("--config", required=True, metavar="PATH")
    ap.add_argument("--session-date", required=True, metavar="YYYY-MM-DD", dest="session_date")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--min-words", type=int, default=None, dest="min_words", metavar="N")
    ap.add_argument("--label", default=None, metavar="L")
    return ap.parse_args(argv)


def main(argv=None):
    global ATOM_LOOKUP
    args = parse_args(argv)

    if sys.version_info < MIN_PYTHON:
        sys.stderr.write(
            f"segment: needs Python {'.'.join(map(str, MIN_PYTHON))}+ for tomllib config "
            f"parsing, found {sys.version.split()[0]}\n"
        )
        return 3

    if not SESSION_DATE_RE.match(args.session_date):
        sys.stderr.write(f"segment: --session-date {args.session_date!r} is not YYYY-MM-DD\n")
        return 3

    cfg = load_config(args.config)
    text = read_text_file(args.transcript, args.transcript)

    turns, has_clock = parse_transcript(text)
    ATOM_LOOKUP, _ = build_atoms(turns)

    min_words = args.min_words if args.min_words is not None else cfg["min_segment_words"]
    result = segment_transcript(turns, has_clock, cfg, min_words)
    if result is None:
        sys.stderr.write(
            "segment: no project key was ever heard as a boundary; check `projects` and "
            "`spoken_aliases` in the config\n"
        )
        return 1

    label = args.label or f"{cfg['label_prefix']}{args.session_date}"
    frontmatter = {
        "skill": "jira-refine",
        "schema": 1,
        "source": os.path.basename(args.transcript),
        "source_path": os.path.abspath(args.transcript),
        "session": args.session_date,
        "label": label,
        "config": os.path.abspath(args.config),
        "projects": cfg["projects"],
        "generated": dt.datetime.now().strftime("%Y-%m-%dT%H:%M:%S"),
    }

    if args.json:
        print(json.dumps(build_json(result, frontmatter, min_words, cfg["long_factor"]), indent=2))
    else:
        print(
            build_skeleton(result, frontmatter, frontmatter["source"], args.session_date, min_words, cfg["long_factor"]),
            end="",
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
