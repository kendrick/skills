#!/usr/bin/env python3
"""Push a refined ticket into Jira once, whatever a previous run already did.

    jira-refine/scripts/jira-apply.py get PROJ-412 --config jira-refine.toml
    jira-refine/scripts/jira-apply.py fields --name goal --config jira-refine.toml
    check-staging.py entries STAGING --status approved \\
        | jira-refine/scripts/jira-apply.py update --config jira-refine.toml --dry-run

This is the only file in the skill that knows Jira exists. It reads one entry
JSON object per line on stdin, writes one report object per line on stdout, and
`references/tracker-contract.md` is the specification for both shapes.

Every write is planned before it is sent. `plan_ops(entry, issue, cfg)` is a
pure function of those three things: it reads the issue as fetched, decides what
would change, and returns the op list plus the per-field outcomes without
touching the network. Two properties fall out of that. The planning half is
testable with no tracker in reach, and `--dry-run` reports the outcomes a real
run would produce rather than running a second, differently-shaped code path
that nobody exercises.

Reading the issue before writing it is the whole point. Writing
unconditionally passes a first run and duplicates the block on the second, so
every rule under "Idempotency rules" in the contract is a rule about what the
issue already holds. The block is bracketed by an `h6.` sentinel because `h6.`
survives a Jira v2 round-trip and the `{{ }}` and `[ ]` macros do not, which is
what lets rule 2 be a byte comparison.

Exit codes: 0 every field on every entry applied or was already present; 1 a
conflict, a missing-issue dependency, an unmapped field with no fallback, or a
failed write, with the report still complete because a failure is recorded and
the entry continues; 3 a config, transport, credential, site, `jira` binary, or
tomllib-floor problem, or input that is not one JSON object per line. Argparse
supplies 2 for a mistyped flag. A dry run applies the same codes to the
outcomes it planned.

`create` also sends whatever `[extra_fields]` the config declares — the Team or
board field a project's filter tests, which a ticket created without simply does
not appear on. Those have no description-block fallback, so an entry whose extra
field the config cannot map creates nothing at all and reports why.

One file, importing nothing from a sibling script and nothing from a sibling
skill: a skill lands alone, so a write path reached through a sibling breaks
whenever that sibling is absent. The follow-up that gives `file-issue` a Jira
create path vendors this file byte-identically rather than calling it, which is
also why every helper it needs lives here. Stdlib only, so the copy stays
portable.
"""
import argparse
import base64
import json
import os
import re
import shutil
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request

try:
    import tomllib
except ModuleNotFoundError:  # Python < 3.11. Reported by load_config, not here,
    tomllib = None          # so `--help` still works on an older interpreter.

TOML_FLOOR = "3.11"
API_PATH = "rest/api/2"
TRANSPORTS = ("rest", "jira-cli")
HTTP_TIMEOUT = 30

# The sentinel is a heading rather than a macro because `h6.` survives a v2
# round-trip; see the module docstring.
BEGIN_RE = re.compile(
    r"^h6\. jira-refine begin \| session (?P<session>.*?) \| source (?P<source>.*)$"
)
END_LINE = "h6. jira-refine end"
BEGIN_FMT = "h6. jira-refine begin | session {session} | source {source}"

ENV_REF = re.compile(r"\$\{([A-Za-z_][A-Za-z0-9_]*)\}")
ISSUE_KEY = re.compile(r"\b[A-Z][A-Z0-9]+-[0-9]+\b")

FALLBACK_BLOCK = "description block"

# The `fields` keys `RestTransport.create_issue` writes itself. An extra field
# declaring one of these as its `id` would land in the same flat payload dict
# and silently replace the value the create path just built — the rendered block
# most damagingly. Kept as a constant so the validator and the payload cannot
# drift apart; the smoke suite pins that every key `create_issue` sets is here.
CREATE_PAYLOAD_FIELDS = frozenset(
    {"project", "issuetype", "summary", "description", "labels", "parent"}
)


class TransportError(Exception):
    """A tracker call failed. Carries a single line fit for a report's reason."""


def die(message):
    """Exit 3 for anything that makes the run impossible rather than wrong.

    Kept separate from the exit-1 path so a caller can tell 'this entry
    conflicts' from 'your config is not there', which are different problems for
    a human holding a staging file."""
    sys.stderr.write(f"jira-apply: {message}\n")
    raise SystemExit(3)


# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------


def expand_env(value, label):
    """Expand `${NAME}` references against the environment.

    `site` carries this so a test can point one config at a local fake without
    editing the file. An unset name is fatal rather than empty: an empty site
    turns every request into a relative URL that fails somewhere far from the
    cause."""
    missing = []

    def sub(match):
        name = match.group(1)
        if name not in os.environ:
            missing.append(name)
            return ""
        return os.environ[name]

    expanded = ENV_REF.sub(sub, value)
    if missing:
        die(f"{label} names ${{{missing[0]}}} but that variable is unset")
    return expanded


def load_config(path, transport_override=None):
    """Read the TOML config, or exit 3 naming what is wrong with it."""
    if tomllib is None:
        die(
            f"reading the config needs Python {TOML_FLOOR} or newer for tomllib; "
            f"this is {sys.version.split()[0]}"
        )
    try:
        with open(path, "rb") as f:
            cfg = dict(tomllib.load(f))
    except OSError as e:
        die(f"config: {e}")
    except tomllib.TOMLDecodeError as e:
        die(f"config {path}: {e}")
    except UnicodeDecodeError as e:
        die(f"config {path}: not valid UTF-8: {e}")

    transport = transport_override or cfg.get("transport") or "rest"
    if transport not in TRANSPORTS:
        die(f"unknown transport {transport!r}; expected one of {', '.join(TRANSPORTS)}")
    cfg["transport"] = transport
    # Only the rest transport reads `site`, so only it resolves the `${ENV}` in
    # one. jira-cli carries its own base URL, and failing a jira-cli run over an
    # unset variable it never reads would be a stop with nothing to fix.
    site = str(cfg.get("site") or "")
    cfg["site"] = expand_env(site, "site") if transport == "rest" else site
    # Absent means the documented default; an explicit empty string means the
    # human turned linking off, which plan_ops reads as "dependencies are
    # unmapped" and answers with the `Depends on:` fallback line.
    if "link_type" not in cfg:
        cfg["link_type"] = "Blocks"
    if not isinstance(cfg.get("fields"), dict):
        cfg["fields"] = {}
    if not isinstance(cfg.get("auth"), dict):
        cfg["auth"] = {}
    cfg["extra_fields"] = _normalize_extra_fields(
        cfg.get("extra_fields"), cfg["fields"]
    )
    return cfg


def _normalize_extra_fields(raw, goal_fields):
    """`[extra_fields.<name>]` as `{name: {"id", "cli_name", "value"}}`, or exit 3.

    Loud rather than lenient, unlike the `fields`/`auth` tables above, which a
    wrong shape merely empties. Those two carry a documented fallback — an
    unmapped Goal lands in the description block — so a silently-dropped table
    still gets the content to Jira. An extra field has no fallback: dropping a
    misspelled `[extra_fields.team]` would create tickets missing the very
    field the board filters on, which is the invisible-ticket failure this
    table exists to close.

    Values are strings only. jira-cli writes through `--custom name=value`,
    which cannot carry a number, a list, or an object, so accepting one here
    would mean a config that works on `rest` and silently stringifies on
    `jira-cli`."""
    if raw is None:
        return {}
    if not isinstance(raw, dict):
        die("config: [extra_fields] must be a table of tables, one per field")
    normalized = {}
    for name, declaration in raw.items():
        if not isinstance(declaration, dict):
            die(
                f"config: [extra_fields.{name}] must be a table with id, "
                "cli_name, and value"
            )
        for setting in ("id", "cli_name", "value"):
            if setting in declaration and not isinstance(declaration[setting], str):
                die(f"config: extra_fields.{name}.{setting} must be a string")
        unknown = sorted(set(declaration) - {"id", "cli_name", "value"})
        if unknown:
            die(
                f"config: [extra_fields.{name}] has no setting "
                f"{unknown[0]!r}; expected id, cli_name, or value"
            )
        normalized[name] = {
            "id": declaration.get("id", "").strip(),
            "cli_name": declaration.get("cli_name", "").strip(),
            "value": declaration.get("value", "").strip(),
        }
    _reject_field_collisions(normalized, goal_fields)
    return normalized


def _reject_field_collisions(normalized, goal_fields):
    """Exit 3 where two declarations would write the same field.

    Both write paths are last-one-wins and neither says so. A REST create builds
    one flat `fields` dict, so an `id` naming a core create field replaces the
    value the create path just built — `id = "description"` sends the extra
    field's value in place of the rendered block, and the report still says
    `description: applied`. A jira-cli create repeats `--custom name=value`, so
    two declarations sharing a `cli_name` leave whichever Jira reads last.
    Shadowing the configured Goal is the same failure against `[fields]`.

    Checked for both transports whatever this run uses, because `--transport`
    overrides the config at the command line: validating only the active
    namespace would let a config pass on `rest` and silently drop a field the
    moment somebody switched."""
    seen_ids = {}
    seen_names = {}
    goal_id = str(goal_fields.get("goal") or "").strip()
    goal_cli_name = str(goal_fields.get("goal_cli_name") or "").strip()
    for name in sorted(normalized):
        declaration = normalized[name]
        field_id = declaration["id"]
        cli_name = declaration["cli_name"]
        # An empty half is a field declared for the other transport only, and
        # two of those collide with nothing.
        if field_id:
            if field_id in CREATE_PAYLOAD_FIELDS:
                die(
                    f"config: extra_fields.{name}.id is {field_id!r}, which is a "
                    "field every create already writes; an extra field cannot "
                    "replace it"
                )
            if field_id == goal_id:
                die(
                    f"config: extra_fields.{name}.id is {field_id!r}, the same "
                    "field as fields.goal; one of the two values would be lost"
                )
            if field_id in seen_ids:
                die(
                    f"config: extra_fields.{name}.id is {field_id!r}, already "
                    f"declared by extra_fields.{seen_ids[field_id]}"
                )
            seen_ids[field_id] = name
        if cli_name:
            if cli_name == goal_cli_name:
                die(
                    f"config: extra_fields.{name}.cli_name is {cli_name!r}, the "
                    "same field as fields.goal_cli_name; one of the two values "
                    "would be lost"
                )
            if cli_name in seen_names:
                die(
                    f"config: extra_fields.{name}.cli_name is {cli_name!r}, "
                    f"already declared by extra_fields.{seen_names[cli_name]}"
                )
            seen_names[cli_name] = name


# ---------------------------------------------------------------------------
# Rendering the description block (pure)
# ---------------------------------------------------------------------------


def _body_lines(value):
    """The non-empty lines of a section body.

    A body arrives as one string with its list markers and anchors already
    stripped at the entry boundary, so there is no marker translation to do
    here — only the blank lines to drop, because a blank line inside the block
    would shift the byte comparison rule 2 depends on."""
    if not value:
        return []
    return [line.rstrip() for line in str(value).splitlines() if line.strip()]


def _bullets(value):
    """The non-empty items of an array-valued section."""
    if not value:
        return []
    return [str(item).strip() for item in value if str(item).strip()]


def render_block(entry, depends_on=None, goal_line=None):
    """The jira-refine block for `entry`, as wiki markup.

    Pure, so identical entries produce identical bytes — which is what makes
    rule 2's "already-present when they are identical" a byte comparison rather
    than a guess. Sections with no content are omitted for the same reason: a
    heading whose body is empty this run and filled the next would move every
    line below it and mask the real change.

    `depends_on` and `goal_line` are the two fallbacks from the contract's
    per-field table, and both are decided at plan time. They render inside the
    Out of scope section, in that order, which is where the contract's worked
    example puts them — so the section's heading appears whenever it has a body
    OR a fallback line, and is omitted only when it has neither."""
    fields = entry.get("fields") or {}
    out = [
        BEGIN_FMT.format(
            session=entry.get("session") or "", source=entry.get("source") or ""
        )
    ]

    context = _body_lines(fields.get("context"))
    if context:
        out.append("h5. Context")
        out.extend(context)

    criteria = _bullets(fields.get("acceptance_criteria"))
    if criteria:
        out.append("h5. Acceptance criteria")
        # `*` rather than a checkbox: wiki markup has no checkbox, so the
        # staging file's `- [ ]` would render as literal brackets in Jira.
        out.extend(f"* {item}" for item in criteria)

    scope = _body_lines(fields.get("out_of_scope"))
    tail = []
    if depends_on:
        tail.append("Depends on: " + ", ".join(depends_on))
    if goal_line:
        tail.append(f"Goal: {goal_line}")
    if scope or tail:
        out.append("h5. Out of scope")
        out.extend(scope)
        out.extend(tail)

    questions = _bullets(fields.get("open_questions"))
    if questions:
        out.append("h5. Open questions")
        out.extend(f"* {item}" for item in questions)

    provenance = _body_lines(fields.get("provenance"))
    if provenance:
        out.append("h5. Provenance")
        # Three staging bullets collapse to the contract's one comma-joined
        # line, so the same entry renders identically whether the producer hands
        # over three lines or one already-joined string.
        out.append(", ".join(provenance))

    out.append(END_LINE)
    return "\n".join(out)


def find_blocks(text):
    """Every jira-refine block in `text`, as (first line, last line, source).

    Line indices rather than character offsets because splicing is a line
    operation: the block is a run of whole lines and the human text around it
    has to come back unchanged.

    The last line is None for a begin sentinel with no matching end, which is
    how a caller learns the block's extent is unknown instead of receiving a
    span it would happily overwrite."""
    lines = (text or "").splitlines()
    blocks = []
    i = 0
    while i < len(lines):
        match = BEGIN_RE.match(lines[i].strip())
        if not match:
            i += 1
            continue
        end = None
        for j in range(i + 1, len(lines)):
            stripped = lines[j].strip()
            # A second begin before any end closes nothing: this block never
            # terminated. `on_conflict: append` builds exactly that shape — a
            # stale unterminated block, the human text under it, then a whole
            # new block — and pairing this begin with the LATER block's end
            # would hand splice_block one span covering all three. The next
            # apply would then replace the lot and report `applied`, which is
            # the loss this whole guard exists to stop, arriving through the
            # recovery documented for it.
            if BEGIN_RE.match(stripped):
                break
            if stripped == END_LINE:
                end = j
                break
        # A begin with no end is still our block, but where it stops is
        # unknowable: the block's own tail and whatever a human wrote below it
        # read identically. The sentinel goes missing on its own, not only by
        # hand — Jira Cloud folds the closing heading into the last bullet when
        # the block ends in a list — so treating the rest of the description as
        # ours would discard reviewer edits on every issue shaped that way.
        # None hands that decision up to plan_description, which conflicts.
        blocks.append((i, end, match.group("source")))
        if end is None:
            i += 1
            continue
        i = end + 1
    return blocks


def self_shaped_reason(block):
    """A reason this rendered block cannot be told apart from two blocks, or None.

    Reads the body lines directly rather than asking `find_blocks` what it sees.
    Going through the scan looked equivalent and was not: a create entry carries
    no `source`, so its own begin line renders with an empty tail that `.strip()`
    takes below what BEGIN_RE matches, the scan then finds nothing at all, and a
    body line shaped like a sentinel sailed through on exactly the entries that
    can least afford it.

    The first and last lines are the block's own sentinels, because
    `render_block` always writes them there. Any line between them that reads as
    a sentinel came from a field.

    Refusing beats escaping. Escaping would rewrite what a person actually
    wrote, and this skill's posture on an unknowable extent, established for the
    missing-sentinel case, is to stop rather than guess. Refusing is that same
    rule one step earlier, at render time instead of parse time."""
    body = block.splitlines()[1:-1]
    for line in body:
        stripped = line.strip()
        if BEGIN_RE.match(stripped) or stripped == END_LINE:
            return (
                "a field carries a line shaped like a jira-refine sentinel, so "
                "the rendered block cannot be told apart from two blocks; reword "
                "that line in the staging file"
            )
    return None


def _holds_block(existing, blocks, block):
    """True when a terminated block in `existing` already holds `block` verbatim.

    Byte equality carries the source with it, because the begin sentinel names
    the source on its own line, so no separate source comparison is needed. An
    unterminated span is skipped: its extent is unknown, which is the whole
    reason it is marked, and slicing to a guessed end would compare the wrong
    lines."""
    lines = existing.splitlines()
    wanted = block.splitlines()
    return any(
        lines[start:end + 1] == wanted
        for start, end, _ in blocks
        if end is not None
    )


def splice_block(existing, spans, block):
    """Replace the first span with `block` and delete the rest.

    More than one same-source block means an earlier run was interrupted or a
    human duplicated one by hand. Converging on a single block is the repair:
    this run writes one, and the run after it finds identical bytes and writes
    nothing."""
    lines = existing.splitlines()
    first = spans[0]
    drop = set()
    for start, end, _ in spans[1:]:
        drop.update(range(start, end + 1))

    out = []
    i = 0
    while i < len(lines):
        if i == first[0]:
            out.extend(block.splitlines())
            i = first[1] + 1
            continue
        if i in drop:
            i += 1
            continue
        out.append(lines[i])
        i += 1
    # splitlines() drops a trailing newline, and putting it back is what keeps a
    # description that already matches from looking one byte different and
    # earning a pointless write on every run.
    return "\n".join(out) + ("\n" if existing.endswith("\n") else "")


def plan_description(entry, issue, block):
    """(text to write or None, verdict, conflict reason or None).

    Idempotency rules 2, 3 and 4 live here. Rule 2: a same-source block is
    replaced in place, so anything a human wrote around it survives. Rule 3: a
    block from a different source, or text with no block at all, is somebody
    else's writing — refuse it unless the human set `on_conflict`. Rule 4: an
    empty description is written."""
    self_shaped = self_shaped_reason(block)
    if self_shaped:
        return None, "conflict", self_shaped

    existing = ((issue.get("fields") or {}).get("description") or "") if issue else ""
    if not isinstance(existing, str):
        # A v3 (ADF) description comes back as a dict. This skill writes v2 wiki
        # markup and cannot merge into a document tree, so it refuses rather
        # than flattening somebody's formatting.
        return None, "conflict", "description is not wiki markup; this skill writes v2 only"

    source = entry.get("source") or ""
    blocks = find_blocks(existing)
    same = [b for b in blocks if b[2] == source]
    other = [b for b in blocks if b[2] != source]
    on_conflict = entry.get("on_conflict")

    # An unterminated block outranks every branch below, including the
    # same-source splice: the splice needs an extent, and this one has none.
    unterminated = [b for b in blocks if b[1] is None]
    if unterminated and on_conflict not in ("append", "replace"):
        return None, "conflict", (
            f"description holds a jira-refine block from source {unterminated[0][2]!r} with no "
            f"end sentinel, so its extent is unknown; restore the `{END_LINE}` line below the "
            "block, or set on_conflict to append or replace"
        )

    if same and not other and not unterminated:
        text = splice_block(existing, same, block)
    elif not blocks and not existing.strip():
        text = block
    elif on_conflict == "append":
        # Append has to converge by itself here. On an ordinary conflict the
        # same-source branch above takes over from the second run on, which is
        # what has always made `append` idempotent. An unterminated block never
        # leaves the description, so that branch stays shut and every rerun
        # would add one more copy of the same block. Rule 8 is the guarantee at
        # stake: a second run over the same input writes nothing.
        if _holds_block(existing, blocks, block):
            return None, "already-present", None
        text = (existing.rstrip("\n") + "\n\n" + block) if existing.strip() else block
    elif on_conflict == "replace":
        # Destructive by request: "removes every jira-refine block and writes
        # only the new one". A human sets this per entry, by hand, after reading
        # the conflict the previous run reported.
        text = block
    elif other:
        return (
            None,
            "conflict",
            f"description holds a jira-refine block from source {other[0][2]!r}; "
            "set on_conflict to append or replace",
        )
    else:
        return (
            None,
            "conflict",
            "description holds text this run did not write; set on_conflict to "
            "append or replace",
        )

    if text == existing:
        return None, "already-present", None
    return text, "applied", None


# ---------------------------------------------------------------------------
# Planning (pure)
# ---------------------------------------------------------------------------


def goal_mapping(cfg):
    """(field id to read, jira-cli field name to write, unmapped).

    Under `rest` the custom field id both reads and writes. Under `jira-cli`,
    `jira issue edit --custom name=value` writes by NAME while `issue view
    --raw` reports by id, so a Goal is only mapped when both are configured:
    without the id there is no way to read the current value, and without the
    current value rule 8 — a second run performs zero writes — cannot hold."""
    fields = cfg.get("fields") or {}
    field_id = str(fields.get("goal") or "").strip()
    cli_name = str(fields.get("goal_cli_name") or "").strip()
    if cfg.get("transport") == "jira-cli":
        return field_id, cli_name, not (field_id and cli_name)
    return field_id, "", not field_id


def extra_field_mappings(entry, cfg):
    """(name, field_id, cli_name, value, reason) per extra field this create wants.

    `reason` is None when the field resolved to a value and a key to write it
    under; otherwise it is the line the report hands the human, and the caller
    refuses the create. Every name the config declares is sent on every create, because the
    field these exist for — the one a board filters on — is a property of the
    run rather than of the ticket. An entry naming the same field overrides the
    value; an entry naming a field the config never declared is a mistake with
    no safe reading, since nothing here knows that field's id.

    Sorted so the op, the report, and the stderr line agree on an order across
    runs, which a dict of a TOML table would otherwise leave to file order."""
    declared = cfg.get("extra_fields") or {}
    overrides = entry.get("extra_fields") or {}
    transport = cfg.get("transport")
    resolved = []
    for name in sorted(set(declared) | set(overrides)):
        declaration = declared.get(name)
        if declaration is None:
            resolved.append(
                (name, "", "", "", f"the entry names {name!r}, which no [extra_fields."
                 f"{name}] in the config declares")
            )
            continue
        field_id = declaration["id"]
        cli_name = declaration["cli_name"]
        value = str(overrides.get(name, declaration["value"])).strip()
        if not value:
            reason = f"extra field {name!r} has no value in the config or the entry"
        elif transport == "jira-cli" and not cli_name:
            reason = f"extra field {name!r} has no cli_name, which jira-cli writes by"
        elif transport != "jira-cli" and not field_id:
            reason = f"extra field {name!r} has no id, which the rest transport writes by"
        else:
            reason = None
        resolved.append((name, field_id, cli_name, value, reason))
    return resolved


def linked_dependencies(issuelinks, link_type):
    """Keys D for which this issue already records "D blocks me".

    Rule 5 keys presence on type, direction and key together. Direction is not
    decoration: the same two issues linked the other way round means this issue
    blocks D, which is the opposite claim and would read as present to a check
    that only matched the key."""
    keys = set()
    for link in issuelinks or []:
        if ((link.get("type") or {}).get("name")) != link_type:
            continue
        inward = link.get("inwardIssue") or {}
        if inward.get("key"):
            keys.add(inward["key"])
    return keys


def _outcomes():
    """A report's per-field half, before any op has run."""
    return {
        "description": "skipped",
        "links": [],
        "label": "unmapped",
        "goal": "already-present",
        "extra_fields": {},
        "unmapped": [],
        "conflict": None,
    }


def _note_conflict(outcomes, reason):
    """Record an entry-level reason, keeping the first one.

    The first reason is the one that explains the rest: a description this run
    refused to write makes everything after it less surprising, and overwriting
    it with a later complaint costs the human the cause."""
    if outcomes["conflict"] is None:
        outcomes["conflict"] = reason


def plan_ops(entry, issue, cfg):
    """(ops, outcomes) for one entry: what to send, and what to report.

    Pure. No I/O, no clock, no environment — every decision comes from the entry
    as parsed, the issue as fetched, and the config as loaded. That is what
    makes `--dry-run` honest: the dry run and the real run plan identically and
    differ only in whether execute() sends anything.

    Dispatches on the entry's shape, because the contract gives `update` and
    `create` different objects: an update entry carries `key`, a create entry
    carries `project`."""
    if "project" in entry:
        return plan_create_ops(entry, cfg)
    return plan_update_ops(entry, issue, cfg)


def plan_update_ops(entry, issue, cfg):
    key = entry.get("key")
    fields = entry.get("fields") or {}
    outcomes = _outcomes()

    if issue is None:
        # Nothing can be planned against an issue nobody could read. Reporting
        # the fields as skipped rather than guessing is the point: a plan built
        # on an assumed-empty issue is exactly the unconditional write this
        # script exists to prevent.
        outcomes["goal"] = "unmapped"
        outcomes["conflict"] = f"could not read {key}"
        return [], outcomes

    issue_fields = issue.get("fields") or {}
    ops = []

    link_type = str(cfg.get("link_type") or "").strip()
    deps = _bullets(fields.get("dependencies"))
    links_unmapped = bool(deps) and not link_type
    if links_unmapped:
        outcomes["unmapped"].append(
            {"field": "dependencies", "fallback": FALLBACK_BLOCK}
        )

    goal = str(fields.get("goal") or "").strip()
    goal_id, goal_cli_name, goal_unmapped = goal_mapping(cfg)
    if goal and goal_unmapped:
        outcomes["goal"] = "unmapped"
        outcomes["unmapped"].append({"field": "goal", "fallback": FALLBACK_BLOCK})

    block = render_block(
        entry,
        depends_on=deps if links_unmapped else None,
        goal_line=goal if (goal and goal_unmapped) else None,
    )

    text, verdict, reason = plan_description(entry, issue, block)
    outcomes["description"] = verdict
    if reason:
        _note_conflict(outcomes, reason)
    if text is not None:
        ops.append({"op": "update_description", "key": key, "text": text})

    label = str(entry.get("label") or "").strip()
    existing_labels = [str(item) for item in (issue_fields.get("labels") or [])]
    if not label:
        outcomes["unmapped"].append({"field": "label", "fallback": FALLBACK_BLOCK})
    elif label in existing_labels:
        outcomes["label"] = "already-present"
    else:
        outcomes["label"] = "applied"
        # Rule 6 PUTs the union rather than the one new label, because a PUT of
        # `labels` replaces the array and would drop everything the team set.
        ops.append(
            {
                "op": "add_labels",
                "key": key,
                "labels": existing_labels + [label],
                "added": [label],
            }
        )

    if not goal:
        # No goal to write, so the tracker already reflects the entry.
        outcomes["goal"] = "already-present"
    elif not goal_unmapped:
        current = issue_fields.get(goal_id)
        current = "" if current is None else str(current).strip()
        if current == goal:
            outcomes["goal"] = "already-present"
        elif current:
            # Rule 7: a different non-empty value is a conflict on this field
            # alone. Somebody set it deliberately, and the rest of the entry is
            # still worth applying.
            outcomes["goal"] = "conflict"
            _note_conflict(
                outcomes,
                f"goal field {goal_id} already holds a different value",
            )
        else:
            outcomes["goal"] = "applied"
            ops.append(
                {
                    "op": "set_field",
                    "key": key,
                    "field_id": goal_id,
                    "cli_name": goal_cli_name,
                    "value": goal,
                }
            )

    if deps and not links_unmapped:
        present = linked_dependencies(issue_fields.get("issuelinks"), link_type)
        for dep in deps:
            if dep in present:
                outcomes["links"].append({"key": dep, "result": "already-present"})
                continue
            outcomes["links"].append({"key": dep, "result": "applied"})
            ops.append(
                {
                    "op": "create_link",
                    "key": key,
                    "depends_on": dep,
                    "link_type": link_type,
                }
            )

    return ops, outcomes


def plan_create_ops(entry, cfg):
    """The create half of plan_ops: one create_issue op, then its links.

    There is no issue to read, so none of the don't-clobber rules apply — but
    the block still carries the sentinel, so the first `update` against the
    ticket this makes replaces it in place instead of conflicting with it. The
    create entry shape carries no `session` or `source`, so those render empty
    unless the caller supplies them.

    An extra field the config cannot map is the one condition that plans no ops
    at all; see the comment on that branch for why refusing beats creating."""
    fields = entry.get("fields") or {}
    outcomes = _outcomes()
    # Read early, because both refusal paths below have to say whether a goal
    # was carried. `_outcomes()` defaults it to `already-present`, which is true
    # of an entry with no goal and false of one whose goal never got written.
    goal = str(fields.get("goal") or "").strip()

    extra = extra_field_mappings(entry, cfg)
    unresolved = [(name, reason) for name, _, _, _, reason in extra if reason]
    if unresolved:
        # The one place this script refuses to write rather than degrading, and
        # the asymmetry with Goal is deliberate. An unmapped Goal falls into the
        # description block, so the content still reaches Jira and a rerun after
        # the config is fixed replaces the same block. An extra field has
        # nowhere to fall: the value is a field id or a select option, not prose,
        # and the block cannot hold it. Creating the ticket anyway would put it
        # exactly where this bug already put four of them — on the tracker,
        # reported applied, missing the field its board filters on — and because
        # create is the one op with no idempotency rule, the rerun that fixed
        # the config would leave a duplicate behind rather than repairing the
        # first. Refusing leaves nothing to clean up.
        blocked = {name for name, _ in unresolved}
        for name, _, _, _, _ in extra:
            # A field that mapped cleanly still did not land, because the create
            # it would have ridden on never went. `skipped` is the same word the
            # description takes for a write nobody attempted; leaving these
            # `applied` would name a field on an issue that does not exist.
            outcomes["extra_fields"][name] = (
                "unmapped" if name in blocked else "skipped"
            )
        for name, _ in unresolved:
            outcomes["unmapped"].append({"field": name, "fallback": None})
        if goal:
            outcomes["goal"] = "skipped"
        _note_conflict(outcomes, "; ".join(reason for _, reason in unresolved))
        outcomes["description"] = "skipped"
        return [], outcomes

    link_type = str(cfg.get("link_type") or "").strip()
    deps = _bullets(entry.get("blocked_by"))
    links_unmapped = bool(deps) and not link_type
    if links_unmapped:
        outcomes["unmapped"].append(
            {"field": "dependencies", "fallback": FALLBACK_BLOCK}
        )

    goal_id, goal_cli_name, goal_unmapped = goal_mapping(cfg)
    if goal and goal_unmapped:
        outcomes["goal"] = "unmapped"
        outcomes["unmapped"].append({"field": "goal", "fallback": FALLBACK_BLOCK})
    elif goal:
        outcomes["goal"] = "applied"

    for name, _, _, _, _ in extra:
        outcomes["extra_fields"][name] = "applied"

    block = render_block(
        entry,
        depends_on=deps if links_unmapped else None,
        goal_line=goal if (goal and goal_unmapped) else None,
    )

    # Same refusal as the update path, and it matters more here: create has no
    # idempotency rule, so a ticket made from an ambiguous block could never be
    # repaired by rerunning.
    self_shaped = self_shaped_reason(block)
    if self_shaped:
        # Everything computed above describes a create that will not happen, so
        # none of it may travel into the report. A `goal` or an extra field left
        # reading `applied` names a field on a ticket nobody made, and the
        # `unmapped` entries would claim a description-block fallback inside a
        # block that was never written — the same false report `_record_failure`
        # refuses to write for a set_field that failed.
        refused = _outcomes()
        refused["description"] = "skipped"
        if goal:
            refused["goal"] = "skipped"
        for name, _, _, _, _ in extra:
            refused["extra_fields"][name] = "skipped"
        _note_conflict(refused, self_shaped)
        return [], refused

    label = str(entry.get("label") or "").strip()
    if label:
        outcomes["label"] = "applied"
    else:
        outcomes["unmapped"].append({"field": "label", "fallback": FALLBACK_BLOCK})

    outcomes["description"] = "applied"
    ops = [
        {
            "op": "create_issue",
            "key": None,
            "project": entry.get("project"),
            "issue_type": entry.get("issue_type") or "Task",
            "summary": entry.get("summary") or "",
            "description": block,
            "labels": [label] if label else [],
            "parent": entry.get("parent"),
            "field_id": "" if goal_unmapped else goal_id,
            "cli_name": "" if goal_unmapped else goal_cli_name,
            "value": "" if goal_unmapped else goal,
            "extra_fields": [
                {"name": name, "field_id": field_id, "cli_name": cli_name, "value": value}
                for name, field_id, cli_name, value, _ in extra
            ],
        }
    ]
    for dep in deps if not links_unmapped else []:
        outcomes["links"].append({"key": dep, "result": "applied"})
        # key stays None: the issue does not exist yet, and execute() fills in
        # the key the create op came back with.
        ops.append(
            {"op": "create_link", "key": None, "depends_on": dep, "link_type": link_type}
        )
    return ops, outcomes


# ---------------------------------------------------------------------------
# Transports
# ---------------------------------------------------------------------------


class Transport:
    """The op table from the contract, as seven methods.

    Every mutating method returns the number of mutations it actually sent,
    because the two transports differ: one REST PUT carries a label union that
    jira-cli spends one invocation per label on, and `writes` in the report
    counts what went over the wire rather than what was planned."""

    name = "?"

    def get_issue(self, key):
        raise NotImplementedError

    def update_description(self, key, text):
        raise NotImplementedError

    def add_labels(self, key, labels, added):
        raise NotImplementedError

    def set_field(self, key, field_id, cli_name, value):
        raise NotImplementedError

    def create_link(self, key, depends_on, link_type):
        raise NotImplementedError

    def create_issue(self, op):
        raise NotImplementedError

    def list_fields(self, name):
        raise NotImplementedError


class RestTransport(Transport):
    """`/rest/api/2` over urllib with basic auth.

    v2 rather than v3 throughout: v3 takes and returns ADF, a document tree this
    skill would have to build and diff, and the block's whole idempotency story
    is a byte comparison on wiki markup."""

    name = "rest"

    def __init__(self, cfg):
        self.site = cfg["site"].rstrip("/")
        self.goal_id = str((cfg.get("fields") or {}).get("goal") or "").strip()
        auth = cfg.get("auth") or {}
        email_env = auth.get("email_env") or "JIRA_EMAIL"
        token_env = auth.get("token_env") or "JIRA_API_TOKEN"
        email = os.environ.get(email_env)
        token = os.environ.get(token_env)
        if not self.site:
            die("the rest transport needs `site` in the config")
        if not email or not token:
            die(
                f"the rest transport needs ${email_env} and ${token_env} in the "
                "environment; the config holds the variable names, never the values"
            )
        raw = f"{email}:{token}".encode("utf-8")
        self.authorization = "Basic " + base64.b64encode(raw).decode("ascii")

    def _request(self, method, path, payload=None, read=False):
        """One HTTP call. `read=True` is the caller saying a 404 is an answer.

        Reads and mutations have to diverge on 404 and nothing else here does.
        On a GET, 404 is the tracker's real answer — the issue is not there —
        and callers act on the `None`. On a PUT or POST it means Jira refused
        the write, so it raises like every other HTTP error: returning `None`
        would let execute() count the write, the report say `applied`, and
        reconcile stamp the staging entry `applied` for content that never
        landed. A silent false success on a client's tracker is the worst
        failure this script has, so the default is the safe one and a new
        caller has to opt in to the lenient reading."""
        url = f"{self.site}/{API_PATH}/{path}"
        data = json.dumps(payload).encode("utf-8") if payload is not None else None
        request = urllib.request.Request(url, data=data, method=method)
        request.add_header("Authorization", self.authorization)
        request.add_header("Accept", "application/json")
        if data is not None:
            request.add_header("Content-Type", "application/json")
        try:
            with urllib.request.urlopen(request, timeout=HTTP_TIMEOUT) as response:
                body = response.read()
        except urllib.error.HTTPError as e:
            if e.code == 404 and read:
                return None
            detail = ""
            try:
                detail = e.read().decode("utf-8", "replace").strip().replace("\n", " ")
            except Exception:
                # The status code is the useful half; a body that will not decode
                # must not turn a reportable failure into a traceback.
                pass
            raise TransportError(f"{method} {path}: HTTP {e.code} {detail}"[:400])
        except urllib.error.URLError as e:
            raise TransportError(f"{method} {path}: {e.reason}")
        if not body:
            return {}
        try:
            return json.loads(body.decode("utf-8"))
        except (ValueError, UnicodeDecodeError) as e:
            raise TransportError(f"{method} {path}: response is not JSON: {e}")

    def get_issue(self, key):
        wanted = ["summary", "description", "labels", "issuelinks"]
        if self.goal_id:
            wanted.append(self.goal_id)
        query = urllib.parse.urlencode({"fields": ",".join(wanted)})
        return self._request(
            "GET", f"issue/{urllib.parse.quote(key)}?{query}", read=True
        )

    def update_description(self, key, text):
        self._request(
            "PUT", f"issue/{urllib.parse.quote(key)}", {"fields": {"description": text}}
        )
        return 1

    def add_labels(self, key, labels, added):
        self._request(
            "PUT", f"issue/{urllib.parse.quote(key)}", {"fields": {"labels": labels}}
        )
        return 1

    def set_field(self, key, field_id, cli_name, value):
        self._request(
            "PUT", f"issue/{urllib.parse.quote(key)}", {"fields": {field_id: value}}
        )
        return 1

    def create_link(self, key, depends_on, link_type):
        self._request(
            "POST",
            "issueLink",
            {
                "type": {"name": link_type},
                "inwardIssue": {"key": key},
                "outwardIssue": {"key": depends_on},
            },
        )
        return 1

    def create_issue(self, op):
        fields = {
            "project": {"key": op["project"]},
            "issuetype": {"name": op["issue_type"]},
            "summary": op["summary"],
            "description": op["description"],
        }
        if op["labels"]:
            fields["labels"] = op["labels"]
        if op.get("parent"):
            fields["parent"] = {"key": op["parent"]}
        if op.get("field_id") and op.get("value"):
            fields[op["field_id"]] = op["value"]
        for extra in op.get("extra_fields") or []:
            fields[extra["field_id"]] = extra["value"]
        created = self._request("POST", "issue", {"fields": fields})
        key = (created or {}).get("key")
        if not key:
            raise TransportError("create returned no issue key")
        return key, 1

    def list_fields(self, name):
        found = self._request("GET", "field", read=True) or []
        needle = name.lower()
        return [
            (
                field.get("id", ""),
                field.get("name", ""),
                (field.get("schema") or {}).get("type", ""),
            )
            for field in found
            if needle in str(field.get("name", "")).lower()
        ]


class JiraCliTransport(Transport):
    """ankitpokhrel's `jira` binary, for a client environment that allows only it.

    Every call carries `--no-input`: the binary prompts on a missing argument,
    and a prompt inside a batch apply hangs the run with nothing on screen to
    explain it."""

    name = "jira-cli"

    def __init__(self, cfg):
        self.binary = shutil.which("jira")
        if not self.binary:
            die("the jira-cli transport needs the `jira` binary on PATH")
        auth = cfg.get("auth") or {}
        token_env = auth.get("token_env") or "JIRA_API_TOKEN"
        if not os.environ.get(token_env):
            die(f"the jira-cli transport needs ${token_env} in the environment")
        probe = self._run(["me"])
        if probe.returncode != 0:
            die(f"`jira me` failed: {self._why(probe)}")

    def _run(self, args):
        try:
            return subprocess.run(
                [self.binary] + args,
                capture_output=True,
                text=True,
                timeout=HTTP_TIMEOUT,
            )
        except OSError as e:
            raise TransportError(f"jira {' '.join(args)}: {e}")
        except subprocess.TimeoutExpired:
            raise TransportError(f"jira {' '.join(args)}: timed out")

    @staticmethod
    def _why(completed):
        text = (completed.stderr or completed.stdout or "").strip()
        return " ".join(text.split())[:300] or f"exit {completed.returncode}"

    def _mutate(self, args):
        completed = self._run(args)
        if completed.returncode != 0:
            raise TransportError(f"jira {args[0]} {args[1]}: {self._why(completed)}")
        return completed

    def get_issue(self, key):
        completed = self._run(["issue", "view", key, "--raw"])
        # A missing issue and a broken binary both exit non-zero here, and the
        # binary gives no code that separates them. Reading both as "not there"
        # is the safe half: it refuses the write and reports it, where the other
        # reading would write into an issue nobody confirmed.
        if completed.returncode != 0:
            return None
        try:
            return json.loads(completed.stdout)
        except ValueError as e:
            raise TransportError(f"jira issue view {key} --raw: not JSON: {e}")

    def update_description(self, key, text):
        self._mutate(["issue", "edit", key, "-b", text, "--no-input"])
        return 1

    def add_labels(self, key, labels, added):
        # The CLI adds rather than replaces, so it takes only the new labels —
        # handing it the union would be harmless but would spend an invocation
        # per label the issue already carries.
        for label in added:
            self._mutate(["issue", "edit", key, "--label", label, "--no-input"])
        return len(added)

    def set_field(self, key, field_id, cli_name, value):
        self._mutate(
            ["issue", "edit", key, "--custom", f"{cli_name}={value}", "--no-input"]
        )
        return 1

    def create_link(self, key, depends_on, link_type):
        self._mutate(["issue", "link", depends_on, key, link_type])
        return 1

    def create_issue(self, op):
        args = [
            "issue",
            "create",
            f"-p{op['project']}",
            f"-t{op['issue_type']}",
            "-s",
            op["summary"],
            "-b",
            op["description"],
            "--no-input",
        ]
        for label in op["labels"]:
            args.extend(["-l", label])
        if op.get("parent"):
            args.extend(["--parent", op["parent"]])
        if op.get("cli_name") and op.get("value"):
            args.extend(["--custom", f"{op['cli_name']}={op['value']}"])
        # `--custom` is documented on create, unlike on edit, so this path does
        # not carry the caveat set_field does.
        for extra in op.get("extra_fields") or []:
            args.extend(["--custom", f"{extra['cli_name']}={extra['value']}"])
        completed = self._mutate(args)
        found = ISSUE_KEY.findall(completed.stdout or "")
        if not found:
            raise TransportError("create printed no issue key")
        # The key is the last thing on the line, usually inside a browse URL.
        return found[-1], 1

    def list_fields(self, name):
        raise TransportError("field discovery needs the rest transport")


def build_transport(cfg):
    if cfg["transport"] == "rest":
        return RestTransport(cfg)
    return JiraCliTransport(cfg)


# ---------------------------------------------------------------------------
# Execution
# ---------------------------------------------------------------------------


def _mark_link(outcomes, dep, result):
    for link in outcomes["links"]:
        if link["key"] == dep:
            link["result"] = result
            return


def _record_failure(outcomes, op, reason):
    """Fold a failed write into the report and keep going.

    The report's enums have no "failed" value, so each field takes the one value
    that does not falsely claim a verdict — `skipped` for a description that did
    not land, `unmapped` for a label, `conflict` for a goal — and the
    entry-level conflict carries what actually happened. Label and goal differ
    because their fallbacks do: Provenance is in the block on every run, so a
    failed label really did degrade to the block, while the `Goal:` line is
    rendered only for a goal that was already unmapped at plan time."""
    name = op["op"]
    if name in ("update_description", "create_issue"):
        outcomes["description"] = "skipped"
        # One POST carries the whole issue, extra fields included, so a create
        # that failed took every one of them down with it. Leaving them
        # `applied` would name fields on a ticket that does not exist.
        for field_name in outcomes["extra_fields"]:
            outcomes["extra_fields"][field_name] = "conflict"
    elif name == "add_labels":
        outcomes["label"] = "unmapped"
        outcomes["unmapped"].append({"field": "label", "fallback": FALLBACK_BLOCK})
    elif name == "set_field":
        # A goal that failed to write took no fallback, so it must not claim
        # one. The block was rendered at plan time, when the field still looked
        # mapped, so it carries no `Goal:` line — reporting `unmapped` plus the
        # description fallback would tell the human the goal landed somewhere
        # when it landed nowhere. Re-rendering the block here is not the way
        # out either: the dry run cannot know a write will fail, and a mid-run
        # re-decision would make it describe a different description than the
        # real run writes. So the goal reports `conflict` — it did not take the
        # value, the entry-level reason says why — and the run exits 1. A rerun
        # after the field config is fixed is safe: rule 8 makes every op
        # idempotent, so nothing that already landed lands twice.
        outcomes["goal"] = "conflict"
    elif name == "create_link":
        _mark_link(outcomes, op["depends_on"], "missing-issue")
    _note_conflict(outcomes, f"{name} failed: {reason}")


def execute(ops, outcomes, transport, dry_run):
    """Send the planned ops, or send nothing. Returns (writes, created key).

    Order is description, labels, goal, links — the order plan_ops built them
    in, so the block lands before the label that says the block is there."""
    writes = 0
    created_key = None
    for op in ops:
        name = op["op"]
        key = op.get("key") or created_key
        try:
            if name == "create_link":
                # The existence read happens even under --dry-run. Rule 5
                # refuses a link to an issue that is not on the tracker, and a
                # dry run that skipped this check would promise a link the real
                # run would refuse.
                if transport.get_issue(op["depends_on"]) is None:
                    _mark_link(outcomes, op["depends_on"], "missing-issue")
                    _note_conflict(
                        outcomes, f"{op['depends_on']} is not on the tracker"
                    )
                    continue
                if dry_run:
                    continue
                if not key:
                    _record_failure(outcomes, op, "no issue key to link from")
                    continue
                writes += transport.create_link(key, op["depends_on"], op["link_type"])
            elif dry_run:
                continue
            elif name == "update_description":
                writes += transport.update_description(key, op["text"])
            elif name == "add_labels":
                writes += transport.add_labels(key, op["labels"], op["added"])
            elif name == "set_field":
                writes += transport.set_field(
                    key, op["field_id"], op["cli_name"], op["value"]
                )
            elif name == "create_issue":
                created_key, sent = transport.create_issue(op)
                writes += sent
        except TransportError as e:
            _record_failure(outcomes, op, str(e))
    return writes, created_key


def entry_failed(report):
    """True when this entry earns exit 1.

    The exit table lists conflict, missing-issue, unmapped-without-fallback and
    a failed write. An unmapped field that DID take its fallback is not on that
    list: the content reached Jira, inside the description block, which is what
    the fallback is for."""
    if report["conflict"]:
        return True
    if report["description"] in ("conflict", "skipped"):
        return True
    if report["goal"] == "conflict":
        return True
    if any(verdict == "conflict" for verdict in report["extra_fields"].values()):
        return True
    if any(link["result"] == "missing-issue" for link in report["links"]):
        return True
    return any(not item.get("fallback") for item in report["unmapped"])


def human_line(report):
    links = report["links"]
    landed = sum(1 for link in links if link["result"] != "missing-issue")
    # Extra fields sit before `writes` so a create that refused to run reads
    # left to right as the reason and then the zero it produced.
    extra = "".join(
        f"  {name}={verdict}" for name, verdict in report["extra_fields"].items()
    )
    return (
        f"{report['key'] or '(new)'}  description={report['description']}  "
        f"links={landed}/{len(links)}  label={report['label']}  "
        f"goal={report['goal']}{extra}  writes={report['writes']}"
    )


# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------


def read_entries(required):
    """Every stdin line as an entry object, or exit 3.

    A malformed line is a wiring failure rather than a tracker failure — the
    producer is `check-staging.py entries`, and a half-parsed stream would push
    a partial entry to a client's Jira."""
    entries = []
    for lineno, line in enumerate(sys.stdin.read().splitlines(), 1):
        if not line.strip():
            continue
        try:
            entry = json.loads(line)
        except ValueError as e:
            die(f"stdin line {lineno}: not JSON: {e}")
        if not isinstance(entry, dict):
            die(f"stdin line {lineno}: expected a JSON object")
        missing = [name for name in required if not entry.get(name)]
        if missing:
            die(f"stdin line {lineno}: entry is missing {', '.join(missing)}")
        _check_extra_fields(entry, lineno)
        entries.append(entry)
    return entries


def _check_extra_fields(entry, lineno):
    """Exit 3 on an `extra_fields` that update cannot honor or create cannot send.

    Rejected outright on an update, rather than ignored. `update` edits an issue
    that already carries its fields, so the key means the caller expected a
    write this command has no path for — and a silently dropped one reads on the
    report as a field that landed. Same reasoning `read_entries` applies to every
    other malformed line: the producer is `check-staging.py entries`, which emits
    this key on neither shape, so anything here came from a hand-built line."""
    if "extra_fields" not in entry:
        return
    if "project" not in entry:
        die(
            f"stdin line {lineno}: extra_fields is create-only; update writes "
            "only the fields the contract's per-field table names"
        )
    raw = entry["extra_fields"]
    if not isinstance(raw, dict):
        die(f"stdin line {lineno}: extra_fields must be an object of name to value")
    for name, value in raw.items():
        if not isinstance(value, str):
            die(
                f"stdin line {lineno}: extra_fields.{name} must be a string; "
                "jira-cli writes custom fields as --custom name=value"
            )


def _apply(args, required, dry_run):
    """The shared body of `update` and `create`: plan, execute, report."""
    cfg = load_config(args.config, args.transport)
    entries = read_entries(required)
    transport = build_transport(cfg)

    report_file = None
    if args.report:
        try:
            report_file = open(args.report, "w", encoding="utf-8")
        except OSError as e:
            die(f"--report {args.report}: {e}")

    totals = {"applied": 0, "conflict": 0, "missing-issue": 0, "writes": 0}
    failed = False
    try:
        for entry in entries:
            issue = None
            read_error = None
            if "project" not in entry:
                try:
                    issue = transport.get_issue(entry["key"])
                except TransportError as e:
                    read_error = str(e)

            ops, outcomes = plan_ops(entry, issue, cfg)
            if issue is None and read_error and "project" not in entry:
                outcomes["conflict"] = f"could not read {entry['key']}: {read_error}"

            writes, created_key = execute(ops, outcomes, transport, dry_run)
            report = {
                "key": created_key if "project" in entry else entry.get("key"),
                "transport": transport.name,
                "dry_run": dry_run,
                "description": outcomes["description"],
                "links": outcomes["links"],
                "label": outcomes["label"],
                "goal": outcomes["goal"],
                "extra_fields": outcomes["extra_fields"],
                "unmapped": outcomes["unmapped"],
                "conflict": outcomes["conflict"],
                "writes": writes,
            }
            line = json.dumps(report)
            print(line)
            if report_file:
                report_file.write(line + "\n")
            sys.stderr.write(human_line(report) + "\n")

            totals["writes"] += writes
            totals["missing-issue"] += sum(
                1 for link in report["links"] if link["result"] == "missing-issue"
            )
            if report["conflict"]:
                totals["conflict"] += 1
            if entry_failed(report):
                failed = True
            else:
                totals["applied"] += 1
    finally:
        if report_file:
            report_file.close()

    sys.stderr.write(
        f"{totals['applied']} applied, {totals['conflict']} conflict, "
        f"{totals['missing-issue']} missing-issue, {totals['writes']} writes\n"
    )
    return 1 if failed else 0


def cmd_update(args):
    return _apply(args, ("key",), args.dry_run)


def cmd_create(args):
    return _apply(args, ("project", "issue_type", "summary"), args.dry_run)


def cmd_get(args):
    """Print one issue as the tracker returns it. The apply flow's preflight:
    exit 3 here means the config, the credentials, or the tracker itself is
    wrong or unreachable, which is worth knowing before the first write."""
    cfg = load_config(args.config, args.transport)
    transport = build_transport(cfg)
    try:
        issue = transport.get_issue(args.key)
    except TransportError as e:
        # A dead site, a refused connection, and a real 404 must not collapse
        # into the same code: get_issue already turns 404 into `None` below,
        # so anything that lands here is the tracker itself unreachable or
        # refusing the call, not an answer about this one key. That is a
        # preflight stop (die -> 3), same as a bad config or missing
        # credentials, and distinct from `not found`'s exit 1 a few lines down.
        die(f"{args.key}: {e}")
    if issue is None:
        sys.stderr.write(f"jira-apply: {args.key} not found\n")
        return 1
    print(json.dumps(issue, indent=2, sort_keys=True))
    return 0


def cmd_fields(args):
    """Print the custom fields whose name contains TEXT.

    Discovery only. The id lands in the config when the human pastes it there,
    because picking the wrong custom field writes a refinement goal into
    somebody else's reporting column and nothing on screen would say so."""
    cfg = load_config(args.config, args.transport)
    transport = build_transport(cfg)
    try:
        found = transport.list_fields(args.name)
    except TransportError as e:
        # Same split as cmd_get: a tracker that would not answer is a
        # preflight stop, not the discovery answer "no field matched" that
        # `not found` below reports for a reachable tracker.
        die(str(e))
    if not found:
        sys.stderr.write(f"jira-apply: no field whose name contains {args.name!r}\n")
        return 1
    width = max(len(field_id) for field_id, _, _ in found)
    for field_id, name, schema_type in found:
        print(f"{field_id.ljust(width)}  {name}  {schema_type}")
    return 0


def parse_args(argv=None):
    ap = argparse.ArgumentParser(
        description="Apply refined tickets to Jira, once each."
    )
    sub = ap.add_subparsers(dest="command", required=True)

    def common(parser):
        parser.add_argument("--config", required=True, metavar="PATH")
        # Deliberately not `choices=`: the contract puts an unknown transport on
        # exit 3 with every other config problem, and argparse would answer 2
        # here while a transport named in the config answered 3 — one mistake,
        # two codes, depending only on where the name was typed.
        parser.add_argument(
            "--transport",
            default=None,
            metavar="|".join(TRANSPORTS),
            help="override the config's transport",
        )
        return parser

    g = common(sub.add_parser("get", help="print one issue as the tracker returns it"))
    g.add_argument("key", metavar="KEY")
    g.set_defaults(func=cmd_get)

    f = common(sub.add_parser("fields", help="find a custom field id by name"))
    f.add_argument("--name", required=True, metavar="TEXT")
    f.set_defaults(func=cmd_fields)

    u = common(sub.add_parser("update", help="apply entries on stdin to their issues"))
    u.add_argument("--dry-run", action="store_true")
    u.add_argument("--report", default=None, metavar="PATH")
    u.set_defaults(func=cmd_update)

    c = common(sub.add_parser("create", help="create issues from entries on stdin"))
    c.add_argument("--dry-run", action="store_true")
    c.add_argument("--report", default=None, metavar="PATH")
    c.set_defaults(func=cmd_create)

    return ap.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
