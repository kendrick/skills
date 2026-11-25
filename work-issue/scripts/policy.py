#!/usr/bin/env python3
"""Rule a work-issue stop by the launch policy before the run asks (#461).

    work-issue/scripts/policy.py flags [--auto-budget R] [--repair-class C] [--defer-after K]
    work-issue/scripts/policy.py budget --timing RUN_DIR/timing.log --at 4|7|8 --run-dir RUN_DIR [--now T] [--auto-budget R]
    work-issue/scripts/policy.py sort --kind triage|redteam --round-file FILE --round K --plan RUN_DIR/plan.md --run-dir RUN_DIR [--repair-class C] [--defer-after K]

`flags` prints the flags it was given, normalized, in the fixed order
`--auto-budget R --defer-after K --repair-class C`, or an empty line for none.
R is a finite number above 0, C is `unowned-write`, K is a positive integer.
Each bad value is one `policy: --<flag>: <value>` stderr line, all of them
before it exits. `budget` and `sort` check the flags they take the same way.

`budget` prints one ruling. `under`: not over at the current threshold, the
log's last `budget-raised` value or 2.0. `ask`: over with no `--auto-budget`.
`raise R`: over at a threshold below R, and `budget-raised R` is appended to
the timing log, so the raise happens once by construction. `defer`: over at R
or more with `--at 7`, the only stop with unqueued in-scope rows to defer
(`run-state.py budget_stop`, #240). `ask` again: over at R or more at step 4 or
8, since skipping a red-team round or a re-fired review would ship claims
nobody reproduced. A missing timing log reads as under budget, as
`run-state.py budget` reads it.

`sort` prints one `<id> <ruling>` line per finding, a ruling being `repair`,
`defer`, `ask` or `keep`. `--kind triage` reads the in-scope rows not yet
queued of a `triage/round-<k>.md`, id the row's `#`. `--kind redteam` reads the
`NOT_REPRODUCED` verdicts of a `redteam/round-<k>.json`, id the verdict's `n`
or else its 1-based position, plus each `holds: false` left check as
`left-<n>`, since `round_failed` fails a round on either.

Triage: below round K, or with no `--defer-after`, every row is `keep`, which
routes it as today. From round K on, a row naming a path outside `owns` is
`repair` under `--repair-class`, a row that cites the "Writes outside a task's
files" rule and names no path is `keep`, and every other row is `defer`. A
missing plan or one with no `## Waves` task rows has no `owns` to sort
against: every row is `keep` with `--repair-class` set, `defer` without.

Red-team: with no `--repair-class`, with no `owns`, or once `policy.log`
records a red-team ruling for an earlier round (the one granted round is
spent), every finding is `ask`. Otherwise a finding naming a path outside
`owns` is `repair` and the rest `defer`, except that a citation with no path
is `ask`, and one `ask` makes the whole round `ask`, so the stop fires.

Heuristic: a finding names a path when a token of its text, backticks
dropped, contains `/` or ends in a file extension. Prose like `and/or` or
`e.g.` reads as a path, and a path with a space in it reads as two tokens. A
red-team finding's text is its `claim`, `output` and `caller.output`, so a
pasted output naming an unowned file sorts it `repair`. Both misreadings fall
toward repair, never toward deferring a real unowned write. A path is outside
`owns` when no `Files owned` entry equals it or, for an entry ending in `/`,
prefixes it: `scoped-cmd`'s match, no globs.

Every `raise`, `defer` and `repair` appends one line to RUN_DIR/policy.log,
`- [wave] policy: <run> <stop>: <ruling> (<flag> <value>) — <evidence>`, unless
that exact line is already there, so a resumed ruling leaves one line.
`ask` and `keep` record nothing.

Exit codes: 0 with the ruling on stdout; 3 usage, a bad flag value, an
unreadable or malformed timing log, round file or plan, a red-team round that
is not JSON once one fence is stripped, or an unwritable log. Never 1: this
rules a stop and gates nothing.

Stdlib only. It imports run-state.py by path rather than copying from it, so
the budget threshold and the plan table parse can't drift from the probe's.
"""
import argparse
import importlib.util
import json
import math
import re
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location("run_state", Path(__file__).with_name("run-state.py"))
rs = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(rs)

REPAIR_CLASSES = ("unowned-write",)
CITATION = "writes outside a task's files"
EXTENSION = re.compile(r"\w\.[A-Za-z][A-Za-z0-9]{0,7}$")
LOCATION = re.compile(r"(?::[0-9]+){1,2}$|#L[0-9]+(?:-L?[0-9]+)?$")
REDTEAM_RULED = re.compile(r" red-team round ([0-9]+): (?:repair|defer) ")


class Usage(Exception):
    pass


class Parser(argparse.ArgumentParser):
    def error(self, message):
        # The validator convention's 3 for usage, not argparse's 2.
        self.print_usage(sys.stderr)
        sys.stderr.write(f"policy: {message}\n")
        sys.exit(3)


def check_flags(args):
    """The normalized flags as a dict, or Usage with one line per bad value."""
    problems = []
    out = {}
    ratio = getattr(args, "auto_budget", None)
    if ratio is not None:
        try:
            value = float(ratio)
        except ValueError:
            value = None
        if value is None or not math.isfinite(value) or value <= 0:
            problems.append(f"policy: --auto-budget: {ratio}")
        else:
            out["auto_budget"] = value
    k = getattr(args, "defer_after", None)
    if k is not None:
        if re.fullmatch(r"[0-9]+", k) and int(k) > 0:
            out["defer_after"] = int(k)
        else:
            problems.append(f"policy: --defer-after: {k}")
    c = getattr(args, "repair_class", None)
    if c is not None:
        if c in REPAIR_CLASSES:
            out["repair_class"] = c
        else:
            problems.append(f"policy: --repair-class: {c}")
    if problems:
        raise Usage(problems)
    return out


def record(run_dir, stop, ruling, flag, evidence):
    path = Path(run_dir) / "policy.log"
    line = f"- [wave] policy: {Path(run_dir).resolve().name} {stop}: {ruling} ({flag}) — {evidence}"
    existing = rs.read_or_none(path) or ""
    if line in existing.split("\n"):
        return
    with open(path, "a", encoding="utf-8") as handle:
        if existing and not existing.endswith("\n"):
            handle.write("\n")
        handle.write(line + "\n")


def cmd_flags(args):
    flags = check_flags(args)
    parts = []
    if "auto_budget" in flags:
        parts.append(f"--auto-budget {flags['auto_budget']!r}")
    if "defer_after" in flags:
        parts.append(f"--defer-after {flags['defer_after']}")
    if "repair_class" in flags:
        parts.append(f"--repair-class {flags['repair_class']}")
    print(" ".join(parts))
    return 0


def cmd_budget(args):
    flags = check_flags(args)
    problems = []
    now = rs.parse_ts(args.now, "--now", problems) if args.now is not None else None
    if problems:
        raise Usage([f"policy: {p}" for p in problems])
    try:
        text = rs.read_text(args.timing)
    except FileNotFoundError:
        text = ""
    except OSError as e:
        raise Usage([f"policy: --timing {args.timing}: {e.strerror or e}"])
    try:
        build, review, over = rs.budget_over(text, None, now)
        _, _, raised = rs.parse_timing_log(text, "timing.log", now)
    except rs.InputError as e:
        raise Usage([f"policy: {p}" for p in e.problems])
    threshold = rs.DEFAULT_BUDGET_RATIO if raised is None else raised
    target = flags.get("auto_budget")
    if not over:
        print("under")
        return 0
    # The smoke test's scratch copy deletes this guard to prove a run with no
    # --auto-budget asks.
    if target is None:
        print("ask")
        return 0
    ratio_text = "n/a" if build == 0 else f"{review / build:.2f}"
    evidence = f"build: {round(build / 60)}m review: {round(review / 60)}m ratio: {ratio_text} over: yes"
    stop = f"budget at step {args.at}"
    flag = f"--auto-budget {target!r}"
    if threshold < target:
        try:
            with open(args.timing, "a", encoding="utf-8") as handle:
                if text and not text.endswith("\n"):
                    handle.write("\n")
                handle.write(f"budget-raised {target!r}\n")
            record(args.run_dir, stop, f"raise {target!r}", flag, evidence)
        except OSError as e:
            raise Usage([f"policy: {e.filename}: {e.strerror or e}"])
        print(f"raise {target!r}")
        return 0
    if args.at == "7":
        try:
            record(args.run_dir, stop, "defer", flag, evidence)
        except OSError as e:
            raise Usage([f"policy: {e.filename}: {e.strerror or e}"])
        print("defer")
        return 0
    print("ask")
    return 0


def named_paths(text):
    """Tokens of `text` that read as paths, by the docstring's heuristic."""
    paths = []
    for token in text.replace("`", " ").replace("’", "'").split():
        token = token.lstrip("([{<\"'*").rstrip(")]}>\"'*.,;:!?")
        if token.endswith("'s"):
            token = token[:-2].rstrip(")]}>\"'*.,;:!?")
        token = LOCATION.sub("", token)
        if token.startswith("./"):
            token = token[2:]
        if not token or "://" in token:
            continue
        if "/" in token or EXTENSION.search(token):
            paths.append(token)
    return paths


def cites_rule(text):
    return CITATION in re.sub(r"[*_]", "", text.replace("’", "'")).lower()


def load_owns(plan_path):
    """The plan's owned entries, or None where there is no plan to sort against."""
    try:
        text = rs.read_text(plan_path)
    except FileNotFoundError:
        return None
    except OSError as e:
        raise Usage([f"policy: --plan {plan_path}: {e.strerror or e}"])
    tasks = rs.wave_tasks_rows(text)
    if not tasks:
        return None
    owns = []
    for _, _, owned, _ in tasks:
        for entry in rs.owned_paths(owned):
            entry = entry.strip(" \t`")
            owns.append(entry[2:] if entry.startswith("./") else entry)
    return owns


def is_owned(path, owns):
    return any(path == e or (e.endswith("/") and path.startswith(e)) for e in owns)


def triage_findings(path):
    try:
        columns, rows = rs.triage_table(path)
    except OSError as e:
        raise Usage([f"policy: --round-file {path}: {e.strerror or e}"])
    missing = [name for name in ("#", "Finding", "Scope") if name not in columns]
    if missing:
        raise Usage([f"policy: --round-file {path}: no {name!r} column" for name in missing])
    findings = []
    for fields in rows:
        if not rs.owed_scope(rs.cell(fields, columns["Scope"])):
            continue
        index = columns["Finding"]
        findings.append((rs.cell(fields, columns["#"]), fields[index] if index < len(fields) else ""))
    return findings


def redteam_findings(path):
    try:
        raw = rs.read_text(path)
    except OSError as e:
        raise Usage([f"policy: --round-file {path}: {e.strerror or e}"])
    try:
        data = json.loads(rs.unfence(raw), strict=False)
    except ValueError as e:
        raise Usage([f"policy: --round-file {path}: not JSON: {e}"])
    if not isinstance(data, dict):
        raise Usage([f"policy: --round-file {path}: not a JSON object"])

    def texts(node, keys):
        return " ".join(node[k] for k in keys if isinstance(node.get(k), str))

    findings = []
    for prefix, key, failed, keys in (
        ("", "verdicts", lambda v: v.get("verdict") == "NOT_REPRODUCED", ("claim", "output")),
        ("left-", "left_checks", lambda v: v.get("holds") is False, ("what", "evidence")),
    ):
        items = data.get(key) or []
        if not isinstance(items, list):
            raise Usage([f"policy: --round-file {path}: {key} is not a list"])
        for position, item in enumerate(items, start=1):
            if not isinstance(item, dict) or not failed(item):
                continue
            n = item.get("n") if isinstance(item.get("n"), int) else position
            text = texts(item, keys)
            if isinstance(item.get("caller"), dict):
                text += " " + texts(item["caller"], ("output",))
            findings.append((f"{prefix}{n}", text))
    return findings


def cmd_sort(args):
    flags = check_flags(args)
    if not re.fullmatch(r"[0-9]+", args.round) or int(args.round) < 1:
        raise Usage([f"policy: --round: {args.round}"])
    k = int(args.round)
    klass = flags.get("repair_class")
    if args.kind == "triage":
        findings = triage_findings(args.round_file)
    else:
        findings = redteam_findings(args.round_file)
    owns = load_owns(args.plan)

    rulings = []  # (id, ruling, paths for the evidence)
    if args.kind == "triage":
        after = flags.get("defer_after")
        for fid, text in findings:
            paths = named_paths(text)
            outside = [] if owns is None else [p for p in paths if not is_owned(p, owns)]
            if after is None or k < after:
                rulings.append((fid, "keep", []))
            elif owns is None:
                rulings.append((fid, "keep" if klass else "defer", []))
            elif klass and outside:
                rulings.append((fid, "repair", outside))
            elif cites_rule(text) and not paths:
                rulings.append((fid, "keep", []))
            else:
                rulings.append((fid, "defer", paths))
    else:
        log = rs.read_or_none(Path(args.run_dir) / "policy.log") or ""
        spent = any(int(m.group(1)) < k for m in REDTEAM_RULED.finditer(log))
        for fid, text in findings:
            paths = named_paths(text)
            # The smoke test's scratch copy deletes this guard to prove a run with
            # no --repair-class asks.
            if not klass or spent or owns is None:
                rulings.append((fid, "ask", []))
                continue
            outside = [p for p in paths if not is_owned(p, owns)]
            if outside:
                rulings.append((fid, "repair", outside))
            elif cites_rule(text) and not paths:
                rulings.append((fid, "ask", []))
            else:
                rulings.append((fid, "defer", paths))
        if any(r == "ask" for _, r, _ in rulings):
            rulings = [(fid, "ask", []) for fid, _, _ in rulings]

    stop = f"{'triage' if args.kind == 'triage' else 'red-team'} round {k}"
    try:
        for ruling in ("repair", "defer"):
            picked = [(fid, paths) for fid, r, paths in rulings if r == ruling]
            if not picked:
                continue
            if ruling == "defer" and args.kind == "triage":
                flag = f"--defer-after {flags.get('defer_after')}"
            else:
                flag = f"--repair-class {klass}"
            evidence = "; ".join(f"{fid} {', '.join(paths)}" if paths else fid for fid, paths in picked)
            record(args.run_dir, stop, ruling, flag, evidence)
    except OSError as e:
        raise Usage([f"policy: {e.filename}: {e.strerror or e}"])
    for fid, ruling, _ in rulings:
        print(f"{fid} {ruling}")
    return 0


def parse_args(argv):
    parser = Parser(prog="policy.py", description="Rule a work-issue stop by the launch policy.")
    sub = parser.add_subparsers(dest="command", required=True, parser_class=Parser)

    def policy_flags(p, names):
        # Strings, not argparse types, so every bad value is reported at once.
        for name in names:
            p.add_argument(f"--{name}", metavar=name.split("-")[-1].upper())

    f = sub.add_parser("flags", help="validate and normalize the policy flags")
    policy_flags(f, ("auto-budget", "repair-class", "defer-after"))
    f.set_defaults(func=cmd_flags)

    b = sub.add_parser("budget", help="rule a budget stop")
    b.add_argument("--timing", required=True)
    b.add_argument("--at", required=True, choices=("4", "7", "8"))
    b.add_argument("--run-dir", required=True)
    b.add_argument("--now")
    policy_flags(b, ("auto-budget",))
    b.set_defaults(func=cmd_budget)

    s = sub.add_parser("sort", help="rule each finding of a triage or red-team round")
    s.add_argument("--kind", required=True, choices=("triage", "redteam"))
    s.add_argument("--round-file", required=True)
    s.add_argument("--round", required=True)
    s.add_argument("--plan", required=True)
    s.add_argument("--run-dir", required=True)
    policy_flags(s, ("repair-class", "defer-after"))
    s.set_defaults(func=cmd_sort)
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(sys.argv[1:] if argv is None else argv)
    try:
        return args.func(args)
    except Usage as e:
        for line in e.args[0]:
            sys.stderr.write(line + "\n")
        return 3


if __name__ == "__main__":
    sys.exit(main())
