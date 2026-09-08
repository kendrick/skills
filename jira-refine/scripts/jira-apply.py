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
    return cfg


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
    has to come back unchanged."""
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
            if lines[j].strip() == END_LINE:
                end = j
                break
        # A begin with no end is still our block: someone hand-deleted the
        # closing sentinel. Claiming to the end of the description keeps the
        # next run replacing it rather than nesting a second block inside it.
        if end is None:
            end = len(lines) - 1
        blocks.append((i, end, match.group("source")))
        i = end + 1
    return blocks


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

    if same and not other:
        text = splice_block(existing, same, block)
    elif not blocks and not existing.strip():
        text = block
    elif on_conflict == "append":
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
    unless the caller supplies them."""
    fields = entry.get("fields") or {}
    outcomes = _outcomes()

    link_type = str(cfg.get("link_type") or "").strip()
    deps = _bullets(entry.get("blocked_by"))
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
    elif goal:
        outcomes["goal"] = "applied"

    block = render_block(
        entry,
        depends_on=deps if links_unmapped else None,
        goal_line=goal if (goal and goal_unmapped) else None,
    )

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

    def _request(self, method, path, payload=None):
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
            if e.code == 404:
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
        return self._request("GET", f"issue/{urllib.parse.quote(key)}?{query}")

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
        created = self._request("POST", "issue", {"fields": fields})
        key = (created or {}).get("key")
        if not key:
            raise TransportError("create returned no issue key")
        return key, 1

    def list_fields(self, name):
        found = self._request("GET", "field") or []
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
    not land, `unmapped` for a label or goal that did not — and the entry-level
    conflict carries what actually happened."""
    name = op["op"]
    if name in ("update_description", "create_issue"):
        outcomes["description"] = "skipped"
    elif name == "add_labels":
        outcomes["label"] = "unmapped"
        outcomes["unmapped"].append({"field": "label", "fallback": FALLBACK_BLOCK})
    elif name == "set_field":
        # The contract's answer to a failed `--custom` edit is `unmapped` plus
        # the description fallback. The fallback line is not re-rendered here:
        # it is a plan-time decision, and re-deciding it mid-run would make the
        # dry run — which cannot know a write will fail — describe a different
        # description than the real run writes.
        outcomes["goal"] = "unmapped"
        outcomes["unmapped"].append({"field": "goal", "fallback": FALLBACK_BLOCK})
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
    if any(link["result"] == "missing-issue" for link in report["links"]):
        return True
    return any(not item.get("fallback") for item in report["unmapped"])


def human_line(report):
    links = report["links"]
    landed = sum(1 for link in links if link["result"] != "missing-issue")
    return (
        f"{report['key'] or '(new)'}  description={report['description']}  "
        f"links={landed}/{len(links)}  label={report['label']}  "
        f"goal={report['goal']}  writes={report['writes']}"
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
        entries.append(entry)
    return entries


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
    exit 3 here means the config or the credentials are wrong, which is worth
    knowing before the first write."""
    cfg = load_config(args.config, args.transport)
    transport = build_transport(cfg)
    try:
        issue = transport.get_issue(args.key)
    except TransportError as e:
        sys.stderr.write(f"jira-apply: {args.key}: {e}\n")
        return 1
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
        sys.stderr.write(f"jira-apply: {e}\n")
        return 1
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
