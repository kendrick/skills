#!/usr/bin/env python3
"""Hand each lane the wave's ruling policy, and copy its rulings into facts (#461).

    work-wave/scripts/lane-policy.py flags [--auto-budget R] [--repair-class C] [--defer-after K]
    work-wave/scripts/lane-policy.py facts --run-dir RUN_DIR --wave-dir WAVE_DIR

`flags` prints the lane brief's `{{POLICY}}`: one leading space, then
`--auto-budget R --defer-after K --repair-class C` in that fixed order. Each
flag the wave left out takes the lane default, `--auto-budget 4.0`,
`--defer-after 3` or `--repair-class unowned-write`, because nobody watches a
lane to answer the stop the flag rules. R is a finite number above 0, printed
as a float, C is `unowned-write`, and K is a positive integer. Each bad value is
one `lane-policy: --<flag>: <value>` stderr line, all of them before it exits.

These rules are re-stated from `work-issue/scripts/policy.py`, its `flags`
subcommand, rather than imported, since a skill lands alone and work-wave
never imports across a skill boundary. `tests/work-wave-smoke.sh` runs both
scripts over the same values and fails when they accept, refuse or print one
differently, so a rule changed there has to be changed here too.

`facts` copies each `- [wave] policy:` line of RUN_DIR/policy.log that
WAVE_DIR/facts/wave.md doesn't already hold onto the end of that file, in
log order, and prints `facts: <n> appended`. A lane never writes under
`facts/` itself: wave.md is the one facts file the orchestrator owns, so the
orchestrator copies the lines in as each report returns. Re-running it appends
nothing, and a missing policy.log appends nothing. It touches no other file.

Exit codes: 0 done; 3 usage, a bad flag value, or an unreadable or unwritable
file. Never 1: this rules nothing and gates nothing.

Stdlib only.
"""
import argparse
import math
import re
import sys
from pathlib import Path

REPAIR_CLASSES = ("unowned-write",)
LANE_DEFAULTS = {"auto_budget": "4.0", "defer_after": "3", "repair_class": "unowned-write"}
POLICY_LINE = "- [wave] policy: "


class Usage(Exception):
    pass


class Parser(argparse.ArgumentParser):
    def error(self, message):
        # The validator convention's 3 for usage, not argparse's 2.
        self.print_usage(sys.stderr)
        sys.stderr.write(f"lane-policy: {message}\n")
        sys.exit(3)


def cmd_flags(args):
    given = {k: getattr(args, k) for k in LANE_DEFAULTS}
    values = {k: LANE_DEFAULTS[k] if v is None else v for k, v in given.items()}
    problems = []
    try:
        ratio = float(values["auto_budget"])
    except ValueError:
        ratio = None
    if ratio is None or not math.isfinite(ratio) or ratio <= 0:
        problems.append(f"lane-policy: --auto-budget: {values['auto_budget']}")
    k = values["defer_after"]
    if not (re.fullmatch(r"[0-9]+", k) and int(k) > 0):
        problems.append(f"lane-policy: --defer-after: {k}")
    if values["repair_class"] not in REPAIR_CLASSES:
        problems.append(f"lane-policy: --repair-class: {values['repair_class']}")
    if problems:
        raise Usage(problems)
    # repr, as policy.py prints it, so `4` and `4.0` render alike in both.
    print(f" --auto-budget {ratio!r} --defer-after {int(k)} --repair-class {values['repair_class']}")
    return 0


def cmd_facts(args):
    log = Path(args.run_dir) / "policy.log"
    wave = Path(args.wave_dir) / "facts" / "wave.md"
    try:
        lines = log.read_text(encoding="utf-8").splitlines()
    except FileNotFoundError:
        lines = []
    except OSError as e:
        raise Usage([f"lane-policy: {log}: {e.strerror or e}"])
    try:
        existing = wave.read_text(encoding="utf-8")
    except FileNotFoundError:
        existing = ""
    except OSError as e:
        raise Usage([f"lane-policy: {wave}: {e.strerror or e}"])
    held = set(existing.splitlines())
    new = []
    for line in lines:
        if line.startswith(POLICY_LINE) and line not in held:
            new.append(line)
            held.add(line)
    if new:
        try:
            wave.parent.mkdir(parents=True, exist_ok=True)
            with open(wave, "a", encoding="utf-8") as handle:
                if existing and not existing.endswith("\n"):
                    handle.write("\n")
                handle.write("".join(line + "\n" for line in new))
        except OSError as e:
            raise Usage([f"lane-policy: {wave}: {e.strerror or e}"])
    print(f"facts: {len(new)} appended")
    return 0


def parse_args(argv):
    parser = Parser(prog="lane-policy.py", description="Hand lanes the wave's ruling policy.")
    sub = parser.add_subparsers(dest="command", required=True, parser_class=Parser)
    f = sub.add_parser("flags", help="validate the wave's policy flags and print {{POLICY}}")
    # Strings, not argparse types, so every bad value is reported at once.
    for name in ("auto-budget", "repair-class", "defer-after"):
        f.add_argument(f"--{name}", metavar=name.split("-")[-1].upper())
    f.set_defaults(func=cmd_flags)
    c = sub.add_parser("facts", help="copy a lane's policy.log lines into facts/wave.md")
    c.add_argument("--run-dir", required=True)
    c.add_argument("--wave-dir", required=True)
    c.set_defaults(func=cmd_facts)
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
