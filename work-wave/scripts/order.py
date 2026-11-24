#!/usr/bin/env python3
"""Write a wave's order.md from its coupling.md, and hold the lanes after one.

    work-wave/scripts/order.py build --wave-dir WAVE_DIR
    work-wave/scripts/order.py hold --wave-dir WAVE_DIR --lane issue-N --why TEXT

`build` reads `coupling.md` and writes `order.md` (Step 2, and Step 3 again
once every `ask` is settled). Placed lanes go in topological order over the
`order: B after A` rows, ties broken by the lowest ready issue number, so the
row order in `coupling.md` never moves a lane. A `hold: B until A merges` row
holds B. A lane whose `order:` row puts it after a held lane is held too,
since it can't merge ahead of what it waits on. `After` names a lane's direct
predecessors and `Why` quotes their Resolutions, both in issue-number order. An `ask` reads as `none`.

`hold` is Steps 5 and 7's move: every placed lane whose `Order` is greater
than issue-N's goes to `held`, `After` issue-N, `Why` TEXT. It reads position,
not `After`, and leaves the remaining numbers alone, gaps included.

Exit codes follow the validator convention: 0 written, 1 a `refuse` row or a
cycle among `order:` rows (one stderr line naming the lanes, nothing written),
3 usage, a missing or unparseable `coupling.md` or `order.md`, a WAVE_DIR name
that isn't `wave-<N>[-<N>...]`, or a lane outside the wave.

Parsing goes through wave-state.py's own `table_rows`, so order.md can't be
written in a shape the resume probe then reads another way. Stdlib only.
"""
import argparse
import heapq
import importlib.util
import os
import re
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location("wave_state", Path(__file__).with_name("wave-state.py"))
ws = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(ws)

LANE = r"(?:issue-|#)?([1-9][0-9]*)"
ORDER = re.compile(rf"order:\s*{LANE}\s+after\s+{LANE}\b")
HOLD = re.compile(rf"hold:\s*{LANE}\s+until\s+{LANE}\s+merges\b")
ORDER_HEADER = ["Order", "Lane", "After", "Why"]


class Fail(Exception):
    def __init__(self, code, problems):
        super().__init__("\n".join(problems))
        self.code = code
        self.problems = problems


def name(n):
    return f"issue-{n}"


def names(lanes):
    return ", ".join(name(n) for n in sorted(lanes))


def write_order(path, rows):
    text = "| Order | Lane | After | Why |\n|---|---|---|---|\n"
    text += "".join(f"| {o} | {lane} | {after} | {why} |\n" for o, lane, after, why in rows)
    # Replace in one rename: a torn order.md reads as unreadable and stops the
    # wave (ledger row 58).
    tmp = path.with_name(path.name + ".tmp")
    tmp.write_text(text, encoding="utf-8")
    os.replace(tmp, path)


def read(path):
    if not path.is_file():
        raise Fail(3, [f"{path}: no such file"])
    try:
        return path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as e:
        raise Fail(3, [f"{path}: {e}"])


def rows_of(text, header, label):
    try:
        return ws.table_rows(text, header, label)
    except ws.Unknown as e:
        raise Fail(3, [str(e)])


def cut_cycles(lanes, edges):
    """The lanes on or between cycles: prune every lane with no predecessor
    left, then every lane with no successor left, until neither moves. What
    remains can't be ordered, and a lane that merely waits on a cycle is gone."""
    left = set(lanes)
    while True:
        drop = {n for n in left if not any(a in left for a in edges.get(n, ()))}
        drop |= {n for n in left if not any(n in edges.get(b, ()) for b in left)}
        if not drop:
            return left
        left -= drop


def build(wave_dir):
    match = ws.WAVE_NAME.fullmatch(wave_dir.name)
    if not match:
        raise Fail(3, [f"--wave-dir {wave_dir}: the directory name must be wave-<N>[-<N>...]"])
    lanes = sorted(int(n) for n in match.group(1).split("-"))
    rows = rows_of(read(wave_dir / "coupling.md"), ["Pair", "Answer", "Evidence", "Resolution"], "coupling.md")

    after = {n: set() for n in lanes}  # lane -> direct order: predecessors
    held_on = {n: set() for n in lanes}  # lane -> what a hold: row waits on
    why = {n: [] for n in lanes}
    refused, outside = [], []
    for cells in rows:
        resolution = ws.bare(cells[-1])
        if resolution.startswith(("none", "ask")):
            continue
        if resolution.startswith("refuse"):
            refused.append(f"refuse: {ws.bare(cells[0])}: {resolution}")
            continue
        m = ORDER.match(resolution) or HOLD.match(resolution)
        if not m:
            raise Fail(3, [f"coupling.md: Resolution {resolution!r} is none of none, ask, refuse, order: B after A, hold: B until A merges"])
        b, a = int(m.group(1)), int(m.group(2))
        bad = [n for n in (b, a) if n not in lanes]
        if bad:
            outside.append(f"coupling.md: {resolution!r} names {names(bad)}, not a lane of {wave_dir.name}")
            continue
        (after if m.re is ORDER else held_on)[b].add(a)
        why[b].append((a, resolution))
    if outside:
        raise Fail(3, outside)
    if refused:
        raise Fail(1, refused)

    stuck = cut_cycles(lanes, after)
    if stuck:
        raise Fail(1, [f"cycle among order: rows: {names(stuck)}"])

    # A lane ordered after a held lane is held, to a fixed point, since its
    # own successors follow it out.
    held = {n for n in lanes if held_on[n]}
    grew = True
    while grew:
        grew = False
        for n in lanes:
            if n not in held and after[n] & held:
                held.add(n)
                grew = True

    placed = [n for n in lanes if n not in held]
    pending = {n: len(after[n]) for n in placed}
    ready = [n for n in placed if not pending[n]]
    heapq.heapify(ready)
    out = []
    while ready:
        n = heapq.heappop(ready)
        out.append((str(len(out) + 1), name(n), names(after[n]) or "—", "; ".join(r for _, r in sorted(why[n])) or "no coupling; number order"))
        for m in placed:
            if n in after[m]:
                pending[m] -= 1
                if not pending[m]:
                    heapq.heappush(ready, m)
    for n in sorted(held):
        on = held_on[n] | (after[n] & held)
        reasons = [r for _, r in sorted(why[n])] + [f"{name(a)} is held" for a in sorted(after[n] & held)]
        out.append(("held", name(n), names(on), "; ".join(reasons)))
    write_order(wave_dir / "order.md", out)


def hold(wave_dir, lane, text):
    m = re.fullmatch(LANE, lane)
    if not m:
        raise Fail(3, [f"--lane {lane!r} is not issue-<N>"])
    if "|" in text or "\n" in text or not text.strip():
        raise Fail(3, ["--why must be one non-empty line with no |, or it breaks the table"])
    target = int(m.group(1))
    path = wave_dir / "order.md"
    rows = []
    for cells in rows_of(read(path), ORDER_HEADER, "order.md"):
        lm = ws.LANE_CELL.fullmatch(ws.bare(cells[1]))
        if not lm:
            raise Fail(3, [f"order.md: lane cell {cells[1]!r} names no issue"])
        order = ws.bare(cells[0])
        if order != "held" and not order.isdigit():
            raise Fail(3, [f"order.md: Order {cells[0]!r} for {cells[1]} is neither a number nor held"])
        # A Why cell may quote a |, which table_rows splits on.
        rows.append([order, int(lm.group(1)), cells, " | ".join(cells[3:])])
    mine = [r for r in rows if r[1] == target]
    if not mine:
        raise Fail(3, [f"order.md has no row for {name(target)}"])
    if mine[0][0] == "held":
        return  # a held lane has no position for later lanes to be after
    pos = int(mine[0][0])
    out = []
    for order, n, cells, row_why in rows:
        if order != "held" and int(order) > pos:
            out.append(("held", name(n), name(target), text.strip()))
        else:
            out.append((cells[0], cells[1], cells[2], row_why))
    write_order(path, out)


def parse_args(argv):
    ap = argparse.ArgumentParser(description="Write a wave's order.md from coupling.md, or hold the lanes after one.")
    sub = ap.add_subparsers(dest="command", required=True)
    b = sub.add_parser("build", help="write order.md from coupling.md")
    b.add_argument("--wave-dir", required=True)
    h = sub.add_parser("hold", help="hold every placed lane ordered after --lane")
    h.add_argument("--wave-dir", required=True)
    h.add_argument("--lane", required=True)
    h.add_argument("--why", required=True)
    return ap.parse_args(argv)


def main(argv=None):
    try:
        args = parse_args(sys.argv[1:] if argv is None else argv)
    except SystemExit as e:
        # The validator convention's 3 for usage, where argparse would give 2.
        return 3 if e.code == 2 else e.code
    wave_dir = Path(args.wave_dir).absolute()
    try:
        if args.command == "build":
            build(wave_dir)
        else:
            hold(wave_dir, args.lane, args.why)
    except Fail as e:
        for problem in e.problems:
            sys.stderr.write(f"order: {args.command}: {problem}\n")
        return e.code
    return 0


if __name__ == "__main__":
    sys.exit(main())
