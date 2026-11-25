#!/usr/bin/env python3
"""Save a lane's returned message as its report, or as an interim hand-back.

Usage: handback.py --wave-dir WAVE_DIR --lane issue-N --phase build|publish|repoll --text FILE [--check]

Reads the lane's final message from FILE. A message that is a terminal report
(exactly one fenced json block, or a bare JSON object, whose `lane` and `phase`
are the ones passed, whose `status` is done, stopped, failed, or refused, whose
`worktree` and `run_dir` are absolute paths, whose `head` is a 40-hex SHA, and
which carries every other field of the brief's contract with its stated type) is
written to reports/issue-<N>-<phase>.json, and the script prints
`terminal <path>`. Anything else is a hand-back: the lane's turn ended mid-run.
It is written to reports/issue-<N>-<phase>-interim-<k>.json, k one past the
highest interim number already there, so a gap never lets a hand-back overwrite
a saved one. The first two (by interim files on disk) print
`redispatch <k> <path>`. The third prints `stop` and every interim path on
stdout, and on stderr a `handback: <lane> <phase>: <n> hand-backs without a
terminal report:` line naming the same paths.

--check classifies without writing anything: it prints `terminal <status>` or
`handback`. Step 7 runs it first so it can hold a failed lane's successors
before the report lands, and only for a message the write will save as a report.

Exit codes: 0 terminal, redispatch, or any --check verdict, 1 third hand-back (the wave stops on the
lane), 3 usage, unreadable FILE, or a terminal report already on disk for this
lane and phase (nothing is written, so a saved report is never clobbered).
"""

import argparse
import json
import os
import re
import sys
import tempfile

STATUSES = {"done", "stopped", "failed", "refused"}
SHA = re.compile(r"[0-9a-f]{40}")
MAX_REDISPATCH = 2
FENCE = re.compile(r"```(?:json)?[ \t]*\n(.*?)\n[ \t]*```", re.S)


def terminal_report(text, lane, phase):
    """The parsed report if `text` is this lane's terminal report for this phase, else None.

    This is the one check that keeps a finished lane from being re-dispatched:
    a report for another lane or phase is somebody else's, so it counts as a
    hand-back here. The path and SHA checks live here too (F-r1-authz-01): a
    report saved as terminal with a relative worktree could never be replaced,
    so a re-prompt's answer hit the overwrite refusal and stopped the wave.
    The brief's contract requires all three fields in every phase and allows
    none of them null.

    The remaining contract fields are checked too: a truncated report saved
    as terminal is immutable, so the full report a resumed lane returns would
    hit the overwrite refusal, and Step 5's contract-change gate would read
    arrays that were never there. `head` stays non-null: a refused lane's
    null head is for the merger to rule on, not for this script.
    """
    text = text.strip()
    blocks = FENCE.findall(text)
    if len(blocks) == 1:
        text = blocks[0].strip()
    elif blocks or not text.startswith("{"):
        return None
    try:
        report = json.loads(text)
    except ValueError:
        return None
    if not isinstance(report, dict):
        return None
    # `status` is lane-supplied JSON: a list or object is unhashable, so `in STATUSES` would raise.
    status = report.get("status")
    if report.get("lane") != lane or report.get("phase") != phase or not isinstance(status, str) or status not in STATUSES:
        return None
    if not all(isinstance(report.get(k), str) and os.path.isabs(report[k]) for k in ("worktree", "run_dir")):
        return None
    if not isinstance(report.get("head"), str) or not SHA.fullmatch(report["head"]):
        return None
    for k in ("files_changed", "contract_changed", "facts"):
        v = report.get(k)
        if not isinstance(v, list) or not all(isinstance(i, str) for i in v):
            return None
    # `pr` may be null, so absence has to be tested apart from the type.
    if "pr" not in report or not isinstance(report["pr"], (str, type(None))):
        return None
    if not all(isinstance(report.get(k), str) for k in ("detail", "question")):
        return None
    return text, report


def write_atomic(path, content):
    # A temp file in the same directory plus rename, so a crash never leaves half a report.
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path), prefix=".handback-")
    with os.fdopen(fd, "w") as f:
        f.write(content)
    os.chmod(tmp, 0o644)  # mkstemp makes 0600; reports were world-readable before
    os.replace(tmp, path)


def main():
    ap = argparse.ArgumentParser(add_help=False)
    ap.add_argument("--wave-dir", required=True)
    ap.add_argument("--lane", required=True)
    ap.add_argument("--phase", required=True, choices=["build", "publish", "repoll"])
    ap.add_argument("--text", required=True)
    ap.add_argument("--check", action="store_true")
    try:
        args = ap.parse_args()
    except SystemExit:
        print(__doc__.split("\n\n")[1].strip(), file=sys.stderr)
        return 3
    if not re.fullmatch(r"issue-\d+", args.lane):
        print(f"handback: --lane must look like issue-N, got {args.lane}", file=sys.stderr)
        return 3
    try:
        # errors="replace": undecodable lane text is a hand-back, not a crash that exit 1 reads as the stop.
        with open(args.text, errors="replace") as f:
            text = f.read()
    except OSError as e:
        print(f"handback: cannot read {args.text}: {e}", file=sys.stderr)
        return 3

    reports = os.path.join(args.wave_dir, "reports")
    base = f"{args.lane}-{args.phase}"
    final = os.path.join(reports, base + ".json")
    if os.path.exists(final):
        print(f"handback: {final} already exists; refusing to overwrite a saved report", file=sys.stderr)
        return 3

    report = terminal_report(text, args.lane, args.phase)
    if args.check:
        print(f"terminal {report[1]['status']}" if report else "handback")
        return 0
    os.makedirs(reports, exist_ok=True)
    if report is not None:
        write_atomic(final, report[0] + "\n")
        print(f"terminal {final}")
        return 0

    interim = re.compile(re.escape(base) + r"-interim-(\d+)\.json")
    # Numeric sort: lexical puts interim-10 before interim-2.
    have = sorted((n for n in os.listdir(reports) if interim.fullmatch(n)),
                  key=lambda n: int(interim.fullmatch(n).group(1)))
    k = int(interim.fullmatch(have[-1]).group(1)) + 1 if have else 1
    count = len(have) + 1
    path = os.path.join(reports, f"{base}-interim-{k}.json")
    # No `status` key, so nothing downstream can read a hand-back as a report.
    write_atomic(path, json.dumps({"lane": args.lane, "phase": args.phase, "handback": k, "text": text}) + "\n")
    if count <= MAX_REDISPATCH:
        print(f"redispatch {k} {path}")
        return 0
    # A third hand-back means resuming isn't converging; a human has to look.
    paths = [os.path.join(reports, n) for n in have] + [path]
    print("stop " + " ".join(paths))
    print(f"handback: {args.lane} {args.phase}: {count} hand-backs without a terminal report: {' '.join(paths)}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
