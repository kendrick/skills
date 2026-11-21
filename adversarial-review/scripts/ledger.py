#!/usr/bin/env python3
"""The finding ledger: append findings, append events, read derived state.

    scripts/ledger.py append-finding --ledger RUN/ledger.jsonl \\
        --id F-r1-money-01 --round 1 --territory money \\
        --file src/billing/invoice.py --quoted-evidence 'total += round(x, 2)' \\
        --claim '...' --proposed-fix '...' --proposed-repro 'pytest -k rounding' \\
        --claimed-severity blocking --reachability normal_use --failure-mode silent
    scripts/ledger.py append-event --ledger RUN/ledger.jsonl \\
        --finding-id F-r1-money-01 --disposition REPRODUCED \\
        --actor verifier-r1-money --repro-command 'pytest -k rounding' \\
        --observed-output 'E assert 10.01 == 10.00'
    scripts/ledger.py state --ledger RUN/ledger.jsonl [--round N]
    scripts/ledger.py validate --ledger RUN/ledger.jsonl
    scripts/ledger.py import-findings --ledger RUN/ledger.jsonl --round 1 \\
        RUN/findings/round-1-money.json
    scripts/ledger.py verifier-input --ledger RUN/ledger.jsonl --round 1 [--territory money]
    scripts/ledger.py report --ledger RUN/ledger.jsonl --scope RUN/scope.json \\
        --findings-dir RUN/findings

A finding carries no disposition field. Its state is derived from the events
appended after it: no events means UNVERIFIED, otherwise the latest event in
each category wins. That is what lets the ledger be append-only in fact rather
than only in intent — a field that "starts UNVERIFIED" and later reads
REPRODUCED is a mutation with extra steps, and it throws away the record of when
the state changed and who changed it.

Every line is validated against its schema BEFORE the ledger is touched, and
appends open the file in "a" and never read it first, so one malformed line
(a subagent killed mid-write, say) never blocks the next append. `append-event`
is the one exception: it scans to confirm the finding id exists, skipping
unparseable lines rather than failing on them, because an event pointing at
nothing is a worse outcome than a tolerated bad line.

Exit codes: 0 success; 1 invalid input, unknown finding id, or a corrupt line
where reading matters — stderr names it as `ledger: <detail>`, ledger untouched.
Argparse supplies 2 for a mistyped flag. The three later subcommands,
import-findings, verifier-input, and report, follow the validator convention
instead: 1 for a semantic failure with one `ledger:` line per problem, 3 for a
usage error or input that can't be read. The first four keep 2 because
work-issue reads their output and exit codes as they stand.

Stdlib only, so the skill stays copy-in portable.
"""
import argparse
import datetime
import json
import os
import re
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ASSETS_DIR = os.path.normpath(os.path.join(SCRIPT_DIR, "..", "assets"))
FINDING_SCHEMA = os.path.join(ASSETS_DIR, "finding.schema.json")
EVENT_SCHEMA = os.path.join(ASSETS_DIR, "event.schema.json")

VERIFICATION = ("REPRODUCED", "NOT_REPRODUCED", "UNVERIFIABLE")
REACHABILITY = ("normal_use", "specific_environment", "hand_edited_input", "unknown")
FAILURE_MODES = ("silent", "loud")

# What each disposition must carry to mean anything. A REPRODUCED event with no
# observed output is the exact artifact this skill exists to refuse: a confident
# claim with nothing behind it. The schema cannot say this — its keyword set is
# deliberately conservative — so the rule lives here, matching the kit's own
# split of shape in the schema and semantics in the script.
REQUIRED_EVIDENCE = {
    "REPRODUCED": ("repro_command", "observed_output"),
    "NOT_REPRODUCED": ("counter_evidence",),
    "UNVERIFIABLE": ("reason",),
    "TEST_WRITTEN": ("artifact",),
    "ISSUE_FILED": ("artifact",),
    "ESCALATED": ("reason",),
    "LISTED": ("reason",),
}

# LISTED puts a finding in the report and nowhere else: no test, no fix, no
# issue. On a blocker anyone can hit, LISTED skips the failing test Step 6
# requires before the fix, so it is refused there.
ADVISORY_ONLY = ("LISTED",)

# Reachability decides whether a reproduced blocker earns a fix cycle (#160).
# unknown counts as reachable, so a finder that skips the question gains
# nothing by it. The rest are listed or escalated, never fixed in the loop:
# most late P0s in the #151-#153 run took a hand-edited input or one
# machine's setup to reach, and each cost a full fix cycle. A silent one still
# escalates, because a run that checks less than it claims (#153's loop ending
# on empty input) goes unnoticed wherever it runs, and nobody comes back to
# read its listing.
REACHABLE = ("normal_use", "unknown")
UNREACHABLE_ROUTES = {"loud": ("LISTED", "ESCALATED"), "silent": ("ESCALATED",)}


def is_reachable(finding):
    # A finding without the field predates it. validate refuses that ledger,
    # and state still counts the finding as reachable, the conservative read.
    return finding.get("reachability", "unknown") in REACHABLE


def severity_problem(disposition, finding, verification):
    """A reason `disposition` can't land on `finding`, whose verification
    state is `verification` at that point in the ledger, or None if it can."""
    if disposition in VERIFICATION or finding.get("claimed_severity") == "advisory":
        return None
    fid = finding.get("id")
    reachability = finding.get("reachability", "unknown")
    if verification != "REPRODUCED":
        if disposition in ADVISORY_ONLY:
            return (
                f"{disposition} is valid only on an advisory finding or a "
                f"REPRODUCED blocker outside normal use; {fid} is blocking "
                f"and {verification}"
            )
        return None
    if is_reachable(finding):
        if disposition in ADVISORY_ONLY:
            return (
                f"reachability rule: {disposition} is valid only on an advisory "
                f"finding or a blocker outside normal use that fails loudly; "
                f"{fid} is blocking with reachability {reachability}"
            )
        return None
    # A missing failure_mode is read as silent, the stricter route, for the
    # same reason unknown reachability is read as reachable.
    failure_mode = finding.get("failure_mode", "silent")
    allowed = UNREACHABLE_ROUTES.get(failure_mode, UNREACHABLE_ROUTES["silent"])
    if disposition not in allowed:
        return (
            f"reachability rule: {fid} is a REPRODUCED blocker with reachability "
            f"{reachability} and failure_mode {failure_mode}, so it routes to "
            f"{' or '.join(allowed)}, not {disposition}"
        )
    return None


def _type_name(value):
    if value is None:
        return "null"
    if isinstance(value, bool):
        return "boolean"
    if isinstance(value, int):
        return "integer"
    if isinstance(value, float):
        return "number"
    if isinstance(value, str):
        return "string"
    if isinstance(value, list):
        return "array"
    if isinstance(value, dict):
        return "object"
    return type(value).__name__


def _matches_type(value, expected):
    actual = _type_name(value)
    if expected == "number":
        return actual in ("number", "integer")
    return actual == expected


def schema_violation(instance, schema, path=""):
    """Return (json_path, reason) for the first thing about `instance` that
    fails `schema`, or None if it conforms. Walks type -> enum -> object
    (required, additionalProperties, properties) -> array (items)."""
    types = schema.get("type")
    if types is not None:
        expected = types if isinstance(types, list) else [types]
        if not any(_matches_type(instance, t) for t in expected):
            want = " or ".join(expected)
            return (
                path or "$",
                f"expected type {want}, got {_type_name(instance)} ({instance!r})",
            )

    if "enum" in schema and instance not in schema["enum"]:
        allowed = ", ".join(repr(v) for v in schema["enum"])
        return path or "$", f"must be one of [{allowed}], got {instance!r}"

    if isinstance(instance, dict) and (
        "properties" in schema or "required" in schema or types == "object"
    ):
        for key in schema.get("required", []):
            if key not in instance:
                return (f"{path}.{key}" if path else key), "required field missing"
        properties = schema.get("properties", {})
        if schema.get("additionalProperties") is False:
            extra = sorted(set(instance) - set(properties))
            if extra:
                return path or "$", f"additional properties not allowed: {extra}"
        for key, subschema in properties.items():
            if key in instance:
                violation = schema_violation(
                    instance[key], subschema, f"{path}.{key}" if path else key
                )
                if violation:
                    return violation

    if isinstance(instance, list) and "items" in schema:
        items_schema = schema["items"]
        for i, item in enumerate(instance):
            violation = schema_violation(item, items_schema, f"{path}[{i}]")
            if violation:
                return violation

    return None


def load_schema(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def append_line(line, ledger_path):
    """Append `line` as one newline-terminated JSON line, creating the
    directory on demand. Never opens the file for reading first: append-only
    means append-only, even when the file already holds a line that would trip
    a reader."""
    ledger_dir = os.path.dirname(ledger_path)
    if ledger_dir:
        os.makedirs(ledger_dir, exist_ok=True)
    with open(ledger_path, "a", encoding="utf-8") as f:
        f.write(json.dumps(line) + "\n")


def read_lines(ledger_path, strict):
    """Yield (lineno, obj) for each line. `strict` decides what a bad line
    means: readers computing state must refuse it, because a corrupt line could
    be hiding a REPRODUCED finding and a termination decision computed over it
    would be wrong. A tolerant scan just skips it."""
    try:
        with open(ledger_path, encoding="utf-8") as f:
            raw = f.readlines()
    except OSError as e:
        sys.stderr.write(f"ledger: {ledger_path}: {e}\n")
        raise SystemExit(1)

    for i, text in enumerate(raw, start=1):
        if not text.strip():
            continue
        try:
            yield i, json.loads(text)
        except json.JSONDecodeError:
            if strict:
                sys.stderr.write(f"ledger: line {i}: not valid JSON\n")
                raise SystemExit(1)
            continue


def cmd_append_finding(args):
    line = {
        "record": "finding",
        "id": args.id,
        "round": args.round,
        "territory": args.territory,
        "file": args.file,
        "quoted_evidence": args.quoted_evidence,
        "claim": args.claim,
        "proposed_fix": args.proposed_fix,
        "proposed_repro": args.proposed_repro,
        "claimed_severity": args.claimed_severity,
        "reachability": args.reachability,
        "failure_mode": args.failure_mode,
    }

    violation = schema_violation(line, load_schema(FINDING_SCHEMA))
    if violation:
        json_path, reason = violation
        sys.stderr.write(f"ledger: {json_path}: {reason}\n")
        return 1

    append_line(line, args.ledger)
    print(f"OK: appended finding {args.id}")
    return 0


def cmd_append_event(args):
    line = {
        "record": "event",
        "finding_id": args.finding_id,
        "disposition": args.disposition,
        "actor": args.actor,
        "repro_command": args.repro_command,
        "observed_output": args.observed_output,
        "counter_evidence": args.counter_evidence,
        "reason": args.reason,
        "artifact": args.artifact,
        "at": args.at
        or datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    }

    violation = schema_violation(line, load_schema(EVENT_SCHEMA))
    if violation:
        json_path, reason = violation
        sys.stderr.write(f"ledger: {json_path}: {reason}\n")
        return 1

    for field in REQUIRED_EVIDENCE.get(args.disposition, ()):
        if not line[field]:
            sys.stderr.write(
                f"ledger: {args.disposition} requires --{field.replace('_', '-')}\n"
            )
            return 1

    # QUESTION_FILED is the one disposition that may land with no artifact: in
    # report-only mode there is no inbox to file into, and the reason says so.
    if args.disposition == "QUESTION_FILED" and not (line["artifact"] or line["reason"]):
        sys.stderr.write(
            "ledger: QUESTION_FILED requires --artifact, or --reason when no "
            "inbox scope was found\n"
        )
        return 1

    known = {}
    verification = "UNVERIFIED"
    for _, obj in read_lines(args.ledger, strict=False):
        if obj.get("record") == "finding":
            known[obj.get("id")] = obj
        elif (
            obj.get("record") == "event"
            and obj.get("finding_id") == args.finding_id
            and obj.get("disposition") in VERIFICATION
        ):
            verification = obj["disposition"]
    if args.finding_id not in known:
        sys.stderr.write(f"ledger: unknown finding_id {args.finding_id}\n")
        return 1
    problem = severity_problem(args.disposition, known[args.finding_id], verification)
    if problem:
        sys.stderr.write(f"ledger: {problem}\n")
        return 1

    append_line(line, args.ledger)
    print(f"OK: appended {args.disposition} for {args.finding_id}")
    return 0


def derive(ledger_path):
    """Fold the ledger into per-finding state. Latest event wins within each
    category, so a re-verification supersedes an earlier one without anything
    being rewritten."""
    findings = {}
    order = []
    for _, obj in read_lines(ledger_path, strict=True):
        if obj.get("record") == "finding":
            findings[obj["id"]] = {
                "finding": obj,
                "verification": "UNVERIFIED",
                "outcome": None,
            }
            order.append(obj["id"])
        elif obj.get("record") == "event":
            state = findings.get(obj["finding_id"])
            if state is None:
                continue
            if obj["disposition"] in VERIFICATION:
                state["verification"] = obj["disposition"]
            else:
                state["outcome"] = obj["disposition"]
    return [findings[i] for i in order]


def cmd_state(args):
    rows = derive(args.ledger)

    if args.json:
        print(
            json.dumps(
                [
                    {
                        "id": r["finding"]["id"],
                        "territory": r["finding"]["territory"],
                        "round": r["finding"]["round"],
                        "claimed_severity": r["finding"]["claimed_severity"],
                        "verification": r["verification"],
                        "outcome": r["outcome"],
                    }
                    for r in rows
                ],
                indent=2,
            )
        )
        return 0

    for r in rows:
        f = r["finding"]
        outcome = r["outcome"] or "-"
        print(
            f"{f['id']}  {f['territory']:<16} {f['claimed_severity']:<9} "
            f"{r['verification']:<15} {outcome}"
        )

    by_territory = {}
    for r in rows:
        t = r["finding"]["territory"]
        by_territory.setdefault(t, []).append(r)

    print()
    for territory, group in by_territory.items():
        counts = {}
        for r in group:
            counts[r["verification"]] = counts.get(r["verification"], 0) + 1
        summary = ", ".join(f"{k} {v}" for k, v in sorted(counts.items()))
        print(f"{territory}: {len(group)} findings — {summary}")

        # A territory that mostly could not be checked is telling you its hunt
        # items produced claims nobody can test. That is worth reporting and
        # worth a human's attention, but it deliberately does not trigger a
        # re-fan-out: the loop terminates on reproduced blockers alone, and a
        # second trigger would make termination depend on a judgment call.
        unverifiable = counts.get("UNVERIFIABLE", 0)
        if unverifiable * 2 > len(group):
            print(
                f"calibration: territory {territory}: "
                f"{unverifiable}/{len(group)} UNVERIFIABLE — hunt items may be "
                f"producing untestable claims"
            )

    # Only a reachable blocker counts. One outside normal use is listed or
    # escalated, and counting it would start the fix round listing it was
    # meant to save. The line's shape stays fixed: work-issue greps it.
    blocking = [
        r
        for r in rows
        if r["verification"] == "REPRODUCED"
        and r["finding"]["claimed_severity"] == "blocking"
        and is_reachable(r["finding"])
    ]
    unverified = [r for r in rows if r["verification"] == "UNVERIFIED"]
    print()
    print(f"blocking (REPRODUCED): {len(blocking)}   UNVERIFIED: {len(unverified)}")

    # Step 7's termination rule. Only a reproduced blocker in the round just
    # reviewed starts another. An advisory still gets its Step 6 outcome, but
    # counting advisories kept cambium #23/#26's review loops going: each fix is new code,
    # new code draws a slightly smaller advisory, and the round never came
    # back empty.
    if args.round is not None:
        in_round = [r for r in blocking if r["finding"]["round"] == args.round]
        if in_round:
            print(f"loop: continue ({len(in_round)} blocking REPRODUCED in round {args.round})")
        else:
            print(f"loop: stop (no blocking REPRODUCED in round {args.round})")
    return 0


def cmd_validate(args):
    finding_schema = load_schema(FINDING_SCHEMA)
    event_schema = load_schema(EVENT_SCHEMA)

    findings = 0
    events = 0
    problems = []
    lines = list(read_lines(args.ledger, strict=True))
    # Findings first, so an event written above its finding (a hand-edited
    # ledger) still meets the severity rule rather than slipping past it.
    seen = {
        obj.get("id"): obj for _, obj in lines if obj.get("record") == "finding"
    }
    read_so_far = set()
    # Verification as of each line, folded in file order the way derive()
    # folds it, so an outcome is judged against the verdict it followed.
    verified = {}
    for lineno, obj in lines:
        record = obj.get("record")
        if record == "finding":
            schema = finding_schema
            findings += 1
            read_so_far.add(obj.get("id"))
        elif record == "event":
            schema = event_schema
            events += 1
        else:
            problems.append(f"line {lineno}: unknown record type {record!r}")
            continue
        violation = schema_violation(obj, schema)
        if violation:
            json_path, reason = violation
            problems.append(f"line {lineno}: {json_path}: {reason}")
            continue
        # The same evidence table append-event enforces, so a line written
        # by hand or by an older script can't carry a verdict or a listing
        # with nothing behind it.
        if record == "event":
            for field in REQUIRED_EVIDENCE.get(obj["disposition"], ()):
                if not obj.get(field):
                    problems.append(f"line {lineno}: {obj['disposition']} requires {field}")
        # derive() skips an event with no finding behind it, so one that
        # validated would drop out of the report without a trace.
        if record == "event" and obj.get("finding_id") not in seen:
            problems.append(f"line {lineno}: unknown finding_id {obj.get('finding_id')}")
            continue
        # derive() folds in file order and skips an event whose finding it
        # hasn't read yet, so a forward event would drop out of `state`.
        # append-event never writes one; only a hand edit does.
        if record == "event" and obj.get("finding_id") not in read_so_far:
            problems.append(
                f"line {lineno}: event precedes its finding {obj.get('finding_id')}"
            )
        if record == "event" and obj["disposition"] in VERIFICATION:
            verified[obj["finding_id"]] = obj["disposition"]
        if record == "event" and obj.get("finding_id") in seen:
            problem = severity_problem(
                obj["disposition"],
                seen[obj["finding_id"]],
                verified.get(obj["finding_id"], "UNVERIFIED"),
            )
            if problem:
                problems.append(f"line {lineno}: {problem}")

    if problems:
        for problem in problems:
            sys.stderr.write(f"ledger: {problem}\n")
        return 1

    print(f"OK: {findings} findings, {events} events")
    return 0


# The five keys a verifier may see, selected by name rather than by deleting
# proposed_fix from a full record, so a field added to the finding schema
# later can't reach the verifier by default.
VERIFIER_KEYS = ("id", "file", "quoted_evidence", "claim", "proposed_repro")

# The finder's message is one fenced json block, and Step 3 saves it verbatim.
FENCE = re.compile(r"^```json[ \t]*\n(.*?)^```[ \t]*$", re.MULTILINE | re.DOTALL)


class Unreadable(Exception):
    """Input that can't be read or parsed; main() exits 3 on it."""


def load_findings_file(path):
    try:
        with open(path, encoding="utf-8") as f:
            text = f.read()
    except OSError as e:
        raise Unreadable(f"{path}: {e}")
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass
    blocks = FENCE.findall(text)
    if len(blocks) != 1:
        raise Unreadable(
            f"{path}: not bare JSON, and holds {len(blocks)} fenced json blocks, not 1"
        )
    try:
        return json.loads(blocks[0])
    except json.JSONDecodeError as e:
        raise Unreadable(f"{path}: fenced json block is not valid JSON: {e}")


def require_readable(path):
    try:
        with open(path, encoding="utf-8"):
            pass
    except OSError as e:
        raise Unreadable(f"{path}: {e}")


def cmd_import_findings(args):
    doc = load_findings_file(args.file)
    if not isinstance(doc, dict):
        sys.stderr.write(f"ledger: {args.file}: expected a JSON object\n")
        return 1
    territory = doc.get("territory")
    findings = doc.get("findings")
    problems = []
    if not isinstance(territory, str) or not territory:
        problems.append(f"{args.file}: territory: required string missing")
    if not isinstance(findings, list):
        problems.append(f"{args.file}: findings: required array missing")
    if problems:
        for p in problems:
            sys.stderr.write(f"ledger: {p}\n")
        return 1

    schema = load_schema(FINDING_SCHEMA)
    lines = []
    for pos, finding in enumerate(findings, start=1):
        if not isinstance(finding, dict):
            problems.append(f"findings[{pos - 1}]: expected an object")
            continue
        # The array position is the rank, so it is the id: an importer that
        # sorted first (by severity, say) would silently reorder Step 5's work.
        line = {
            **finding,
            "record": "finding",
            "id": f"F-r{args.round}-{territory}-{pos:02d}",
            "round": args.round,
            "territory": territory,
        }
        for key in ("record", "id", "round", "territory"):
            if key in finding:
                problems.append(f"findings[{pos - 1}]: {key}: assigned by import, not by the finder")
        violation = schema_violation(line, schema)
        if violation:
            json_path, reason = violation
            problems.append(f"findings[{pos - 1}]: {json_path}: {reason}")
        lines.append(line)

    existing = set()
    if os.path.exists(args.ledger):
        require_readable(args.ledger)
        existing = {
            obj.get("id")
            for _, obj in read_lines(args.ledger, strict=False)
            if obj.get("record") == "finding"
        }
    for line in lines:
        if line["id"] in existing:
            problems.append(f"{line['id']}: already in the ledger")

    # All or nothing: a half-imported file leaves ids a rerun would collide
    # with, and no way to tell which findings the verifier never saw.
    if problems:
        for p in problems:
            sys.stderr.write(f"ledger: {p}\n")
        return 1
    for line in lines:
        append_line(line, args.ledger)
    print(f"OK: imported {len(lines)} findings")
    return 0


def cmd_verifier_input(args):
    require_readable(args.ledger)
    out = []
    problems = []
    for r in derive(args.ledger):
        f = r["finding"]
        if f.get("round") != args.round:
            continue
        if args.territory is not None and f.get("territory") != args.territory:
            continue
        missing = [k for k in VERIFIER_KEYS if k not in f]
        if missing:
            problems.append(f"{f.get('id')}: missing {', '.join(missing)}")
            continue
        out.append({k: f[k] for k in VERIFIER_KEYS})
    if problems:
        for p in problems:
            sys.stderr.write(f"ledger: {p}\n")
        return 1
    print(json.dumps(out, indent=2))
    return 0


def cmd_report(args):
    try:
        with open(args.scope, encoding="utf-8") as f:
            scope = json.load(f)
    except OSError as e:
        raise Unreadable(f"{args.scope}: {e}")
    except json.JSONDecodeError as e:
        raise Unreadable(f"{args.scope}: not valid JSON: {e}")
    if not os.path.isdir(args.findings_dir):
        raise Unreadable(f"{args.findings_dir}: not a directory")
    require_readable(args.ledger)

    rows = derive(args.ledger)
    # derive() keeps only the latest disposition, and the listed section needs
    # the REPRODUCED event's own command and output.
    reproduced = {}
    for _, obj in read_lines(args.ledger, strict=True):
        if obj.get("record") == "event" and obj.get("disposition") == "REPRODUCED":
            reproduced[obj.get("finding_id")] = obj

    problems = []
    territories = [t.get("name") for t in scope.get("territories", []) if isinstance(t, dict)]
    rounds = scope.get("rounds") or []
    if not rounds:
        problems.append(f"{args.scope}: rounds: no round recorded")
    for r in rows:
        if r["finding"].get("territory") not in territories:
            problems.append(
                f"{r['finding'].get('id')}: territory {r['finding'].get('territory')!r} "
                f"is not in {args.scope}, so the report would drop it"
            )
    listed = [r for r in rows if r["outcome"] == "LISTED"]
    for r in listed:
        ev = reproduced.get(r["finding"]["id"])
        if not ev or not ev.get("repro_command") or not ev.get("observed_output"):
            problems.append(f"{r['finding']['id']}: LISTED with no REPRODUCED repro command and output")
    if problems:
        for p in problems:
            sys.stderr.write(f"ledger: {p}\n")
        return 1

    out = []
    for name in territories:
        # A territory is judged on the latest round that fanned out to it. A
        # missing findings file is the only failure mark on disk: Step 3's
        # "marked failed" lives in the agent's context, not in a file.
        latest = None
        for rnd in rounds:
            if name in rnd.get("territories", []):
                latest = rnd.get("round")
        doc = None
        if latest is not None:
            path = os.path.join(args.findings_dir, f"round-{latest}-{name}.json")
            if os.path.exists(path):
                doc = load_findings_file(path)
        out.append(f"## {name}")
        out.append("")
        if doc is None:
            out.append("**Verdict:** UNREVIEWED")
            out.append("")
            out.append(f"No findings file for round {latest}: this territory's finder never reported.")
        else:
            out.append("**Verdict:** (write this territory's verdict)")
            out.append("")
            works = doc.get("works") if isinstance(doc, dict) else None
            out.append(f"**Works:** {works or '(no works line)'}")
        out.append("")
        group = [r for r in rows if r["finding"].get("territory") == name]
        # Silent first: a silent defect reads as a working run to whoever
        # meets it. A missing failure_mode sorts as silent, the stricter read.
        group.sort(key=lambda r: r["finding"].get("failure_mode", "silent") != "silent")
        if not group:
            out.append("No findings.")
        for r in group:
            f = r["finding"]
            out.append(
                f"- `{f['id']}` {f.get('failure_mode', 'silent')}, "
                f"{f.get('claimed_severity')}: {r['verification']} → "
                f"{r['outcome'] or '(no outcome)'}. {f.get('claim')}"
            )
        out.append("")

    def count(pred):
        return sum(1 for r in rows if pred(r))

    out.append("## Run")
    out.append("")
    out.append(f"- Rounds taken: {len(rounds)}")
    for rnd in rounds:
        n = rnd.get("round")
        out.append(f"- Round {n} findings: {count(lambda r: r['finding'].get('round') == n)}")
    for v in ("REPRODUCED", "NOT_REPRODUCED", "UNVERIFIABLE", "UNVERIFIED"):
        out.append(f"- {v}: {count(lambda r: r['verification'] == v)}")
    for label, d in (
        ("Tests written", "TEST_WRITTEN"),
        ("Issues filed", "ISSUE_FILED"),
        ("Questions filed", "QUESTION_FILED"),
        ("Listed", "LISTED"),
        ("Escalated", "ESCALATED"),
        ("Closed", "CLOSED"),
    ):
        out.append(f"- {label}: {count(lambda r: r['outcome'] == d)}")
    out.append("")

    out.append("## Listed")
    out.append("")
    if not listed:
        out.append("None.")
    for r in listed:
        f = r["finding"]
        ev = reproduced[f["id"]]
        reach = (
            f" Reachability: {f.get('reachability')}."
            if f.get("claimed_severity") == "blocking"
            else ""
        )
        out.append(f"- `{f['id']}`: {f.get('claim')}{reach}")
        out.append("")
        out.append("  ```")
        out.append(f"  $ {ev['repro_command']}")
        for text in ev["observed_output"].splitlines():
            out.append(f"  {text}")
        out.append("  ```")
        out.append("")
    print("\n".join(out).rstrip("\n"))
    return 0


def parse_args(argv=None):
    ap = argparse.ArgumentParser(description="Append to and read the finding ledger.")
    sub = ap.add_subparsers(dest="command", required=True)

    f = sub.add_parser("append-finding", help="record one hypothesis")
    f.add_argument("--ledger", required=True, metavar="PATH")
    f.add_argument("--id", required=True)
    f.add_argument("--round", required=True, type=int)
    f.add_argument("--territory", required=True)
    f.add_argument("--file", required=True)
    f.add_argument("--quoted-evidence", required=True)
    f.add_argument("--claim", required=True)
    f.add_argument("--proposed-fix", required=True)
    f.add_argument("--proposed-repro", required=True)
    f.add_argument("--claimed-severity", required=True, choices=["blocking", "advisory"])
    f.add_argument("--reachability", required=True, choices=REACHABILITY)
    f.add_argument("--failure-mode", required=True, choices=FAILURE_MODES)
    f.set_defaults(func=cmd_append_finding)

    e = sub.add_parser("append-event", help="record what happened to a finding")
    e.add_argument("--ledger", required=True, metavar="PATH")
    e.add_argument("--finding-id", required=True)
    e.add_argument(
        "--disposition",
        required=True,
        choices=[
            "REPRODUCED",
            "NOT_REPRODUCED",
            "UNVERIFIABLE",
            "TEST_WRITTEN",
            "ISSUE_FILED",
            "CLOSED",
            "QUESTION_FILED",
            "ESCALATED",
            "LISTED",
        ],
    )
    e.add_argument("--actor", required=True, help="e.g. verifier-r1-money")
    e.add_argument("--repro-command", default=None)
    e.add_argument("--observed-output", default=None)
    e.add_argument("--counter-evidence", default=None)
    e.add_argument("--reason", default=None, help="required on LISTED, e.g. 'listed in PR Left Out'")
    e.add_argument("--artifact", default=None, help="test path, issue URL, note path")
    e.add_argument("--at", default=None, help="ISO-8601 UTC; defaults to now")
    e.set_defaults(func=cmd_append_event)

    s = sub.add_parser("state", help="derived disposition per finding")
    s.add_argument("--ledger", required=True, metavar="PATH")
    s.add_argument("--json", action="store_true")
    s.add_argument(
        "--round",
        type=int,
        default=None,
        metavar="N",
        help="also print Step 7's loop decision for round N",
    )
    s.set_defaults(func=cmd_state)

    v = sub.add_parser("validate", help="every line parses and conforms")
    v.add_argument("--ledger", required=True, metavar="PATH")
    v.set_defaults(func=cmd_validate)

    i = sub.add_parser("import-findings", help="append one findings file, in rank order")
    i.add_argument("--ledger", required=True, metavar="PATH")
    i.add_argument("--round", required=True, type=int)
    i.add_argument("file", metavar="FILE")
    i.set_defaults(func=cmd_import_findings)

    vi = sub.add_parser("verifier-input", help="the five keys a verifier may see")
    vi.add_argument("--ledger", required=True, metavar="PATH")
    vi.add_argument("--round", required=True, type=int)
    vi.add_argument("--territory", default=None)
    vi.set_defaults(func=cmd_verifier_input)

    r = sub.add_parser("report", help="Step 8's report skeleton")
    r.add_argument("--ledger", required=True, metavar="PATH")
    r.add_argument("--scope", required=True, metavar="PATH")
    r.add_argument("--findings-dir", required=True, metavar="DIR")
    r.set_defaults(func=cmd_report)

    return ap.parse_args(argv)


VALIDATOR_COMMANDS = ("import-findings", "verifier-input", "report")


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    validator = bool(argv) and argv[0] in VALIDATOR_COMMANDS
    try:
        args = parse_args(argv)
    except SystemExit as e:
        # Only the later subcommands move argparse's 2 to 3; the first four
        # keep 2, since work-issue reads them as they are.
        if validator and e.code == 2:
            raise SystemExit(3)
        raise
    try:
        return args.func(args)
    except Unreadable as e:
        sys.stderr.write(f"ledger: {e}\n")
        return 3


if __name__ == "__main__":
    sys.exit(main())
