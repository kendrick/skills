#!/usr/bin/env python3
"""Save a lane's returned message as its report, or as an interim hand-back.

Usage: handback.py --wave-dir WAVE_DIR --lane issue-N --phase build|publish|repoll --text FILE

Reads the lane's final message from FILE. A message that is a terminal report
(exactly one fenced json block, or a bare JSON object, whose `lane` and `phase`
are the ones passed and whose `status` is done, stopped, failed, or refused) is
written to reports/issue-<N>-<phase>.json, and the script prints
`terminal <path>`. Anything else is a hand-back: the lane's turn ended mid-run.
It is written to reports/issue-<N>-<phase>-interim-<k>.json, k counting the
interim files already there plus one. The first two print
`redispatch <k> <path>`. The third prints `stop` and every interim path on
stdout, and the same on stderr after a `handback:` prefix.

Exit codes: 0 terminal or redispatch, 1 third hand-back (the wave stops on the
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
MAX_REDISPATCH = 2
FENCE = re.compile(r"```(?:json)?[ \t]*\n(.*?)\n[ \t]*```", re.S)


def terminal_report(text, lane, phase):
    """The JSON text if `text` is this lane's terminal report for this phase, else None.

    This is the one check that keeps a finished lane from being re-dispatched:
    a report for another lane or phase is somebody else's, so it counts as a
    hand-back here.
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
    if report.get("lane") == lane and report.get("phase") == phase and report.get("status") in STATUSES:
        return text
    return None


def write_atomic(path, content):
    # A temp file in the same directory plus rename, so a crash never leaves half a report.
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path), prefix=".handback-")
    with os.fdopen(fd, "w") as f:
        f.write(content)
    os.replace(tmp, path)


def main():
    ap = argparse.ArgumentParser(add_help=False)
    ap.add_argument("--wave-dir", required=True)
    ap.add_argument("--lane", required=True)
    ap.add_argument("--phase", required=True, choices=["build", "publish", "repoll"])
    ap.add_argument("--text", required=True)
    try:
        args = ap.parse_args()
    except SystemExit:
        print(__doc__.split("\n\n")[1].strip(), file=sys.stderr)
        return 3
    if not re.fullmatch(r"issue-\d+", args.lane):
        print(f"handback: --lane must look like issue-N, got {args.lane}", file=sys.stderr)
        return 3
    try:
        with open(args.text) as f:
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
    os.makedirs(reports, exist_ok=True)

    report = terminal_report(text, args.lane, args.phase)
    if report is not None:
        write_atomic(final, report + "\n")
        print(f"terminal {final}")
        return 0

    interim = re.compile(re.escape(base) + r"-interim-(\d+)\.json")
    have = sorted(n for n in os.listdir(reports) if interim.fullmatch(n))
    k = len(have) + 1
    path = os.path.join(reports, f"{base}-interim-{k}.json")
    # No `status` key, so nothing downstream can read a hand-back as a report.
    write_atomic(path, json.dumps({"lane": args.lane, "phase": args.phase, "handback": k, "text": text}) + "\n")
    if k <= MAX_REDISPATCH:
        print(f"redispatch {k} {path}")
        return 0
    # A third hand-back means resuming isn't converging; a human has to look.
    paths = [os.path.join(reports, n) for n in have] + [path]
    print("stop " + " ".join(paths))
    print(f"handback: {args.lane} {args.phase}: {k} hand-backs without a terminal report: {' '.join(paths)}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
