#!/usr/bin/env python3
"""The finding ledger: append findings, append events, read derived state.

    scripts/ledger.py append-finding --ledger RUN/ledger.jsonl \\
        --id F-r1-money-01 --round 1 --territory money \\
        --file src/billing/invoice.py --quoted-evidence 'total += round(x, 2)' \\
        --claim '...' --proposed-fix '...' --proposed-repro 'pytest -k rounding' \\
        --claimed-severity blocking
    scripts/ledger.py append-event --ledger RUN/ledger.jsonl \\
        --finding-id F-r1-money-01 --disposition REPRODUCED \\
        --actor verifier-r1-money --repro-command 'pytest -k rounding' \\
        --observed-output 'E assert 10.01 == 10.00'
    scripts/ledger.py state --ledger RUN/ledger.jsonl
    scripts/ledger.py validate --ledger RUN/ledger.jsonl

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
Argparse supplies 2 for a mistyped flag.

Stdlib only, so the skill stays copy-in portable.
"""
import argparse
import datetime
import json
import os
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ASSETS_DIR = os.path.normpath(os.path.join(SCRIPT_DIR, "..", "assets"))
FINDING_SCHEMA = os.path.join(ASSETS_DIR, "finding.schema.json")
EVENT_SCHEMA = os.path.join(ASSETS_DIR, "event.schema.json")

VERIFICATION = ("REPRODUCED", "NOT_REPRODUCED", "UNVERIFIABLE")

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
}


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

    known = {
        obj.get("id")
        for _, obj in read_lines(args.ledger, strict=False)
        if obj.get("record") == "finding"
    }
    if args.finding_id not in known:
        sys.stderr.write(f"ledger: unknown finding_id {args.finding_id}\n")
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
        # re-fan-out: the loop terminates on REPRODUCED findings alone, and a
        # second trigger would make termination depend on a judgment call.
        unverifiable = counts.get("UNVERIFIABLE", 0)
        if unverifiable * 2 > len(group):
            print(
                f"calibration: territory {territory}: "
                f"{unverifiable}/{len(group)} UNVERIFIABLE — hunt items may be "
                f"producing untestable claims"
            )

    blocking = [
        r
        for r in rows
        if r["verification"] == "REPRODUCED"
        and r["finding"]["claimed_severity"] == "blocking"
    ]
    unverified = [r for r in rows if r["verification"] == "UNVERIFIED"]
    print()
    print(f"blocking (REPRODUCED): {len(blocking)}   UNVERIFIED: {len(unverified)}")
    return 0


def cmd_validate(args):
    finding_schema = load_schema(FINDING_SCHEMA)
    event_schema = load_schema(EVENT_SCHEMA)

    findings = 0
    events = 0
    problems = []
    for lineno, obj in read_lines(args.ledger, strict=True):
        record = obj.get("record")
        if record == "finding":
            schema = finding_schema
            findings += 1
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

    if problems:
        for problem in problems:
            sys.stderr.write(f"ledger: {problem}\n")
        return 1

    print(f"OK: {findings} findings, {events} events")
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
        ],
    )
    e.add_argument("--actor", required=True, help="e.g. verifier-r1-money")
    e.add_argument("--repro-command", default=None)
    e.add_argument("--observed-output", default=None)
    e.add_argument("--counter-evidence", default=None)
    e.add_argument("--reason", default=None)
    e.add_argument("--artifact", default=None, help="test path, issue URL, note path")
    e.add_argument("--at", default=None, help="ISO-8601 UTC; defaults to now")
    e.set_defaults(func=cmd_append_event)

    s = sub.add_parser("state", help="derived disposition per finding")
    s.add_argument("--ledger", required=True, metavar="PATH")
    s.add_argument("--json", action="store_true")
    s.set_defaults(func=cmd_state)

    v = sub.add_parser("validate", help="every line parses and conforms")
    v.add_argument("--ledger", required=True, metavar="PATH")
    v.set_defaults(func=cmd_validate)

    return ap.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
