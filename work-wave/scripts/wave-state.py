#!/usr/bin/env python3
"""Gather a wave's resume probe and map it to a phase.

    work-wave/scripts/wave-state.py probe --wave-dir DIR --root ROOT --default BRANCH [--pr-bundle FILE]
    work-wave/scripts/wave-state.py phase --probe PROBE.json

`probe` reads WAVE_DIR, the lane RUN_DIRs beside it under the git common dir,
and git, then prints the JSON `phase --probe` reads, with every field present.
It never calls `gh` and never fetches. The orchestrator fetches `origin/DEFAULT`
before probing, and GitHub's answer arrives as `--pr-bundle`, a JSON object
mapping `issue-<N>` to the pull-request URLs `gh pr list --head issue-<N>
--state all --json url --jq '.[].url'` printed. The URLs go into `detail.prs`
so a stop can name them. No row reads them. A field the probe can't answer is
null, and one stderr line says why.

`phase` prints `phase: <phase> reason: <reason>`, where every row's reason
starts `row <n>:`. A phase is a step number, `done`, or `stop`.

Nothing in WAVE_DIR records a phase. The probe reads outputs only, and "newest"
always means the highest `k`, never a file time, so the answer doesn't depend
on the order the writes landed in.

Exit codes follow the validator convention. `probe` exits 0 with the JSON on
stdout, or 3 on usage, a ROOT that isn't a git repository, a WAVE_DIR name
that isn't `wave-<N>[-<N>...]`, or an unreadable `--pr-bundle`. `phase` exits
0 with its answer, 1 when the answer is `stop`, because a stop is the one
answer a shell caller must not walk past, and 3 on a probe it can't read or
one missing a field. Argparse errors exit 3 too.

Stdlib only, so the skill stays copy-in portable.
"""
import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

PROBE_FIELDS = (
    ("wave_closed", "bool", ()),
    ("lane_run_dirs_open", "int", ()),
    ("wave_dir", "bool", ()),
    ("lanes_md", "bool", ()),
    ("harvest_md", "bool", ()),
    ("footprint_check", "bool", ()),
    ("coupling_md", "bool", ()),
    ("order_md", "bool", ()),
    ("coupling_asks", "int", ()),
    ("baseline_test", "bool", ()),
    ("build_ungated", "int", ()),
    ("gate_stops", "int", ()),
    ("unheld_unreported", "int", ()),
    ("merge_test_matches", "bool", ()),
    ("merge_test_green", "bool", ()),
    ("base_current", "bool", ()),
    ("publish_unreported", "int", ()),
    ("heads_moved", "bool", ()),
    ("merge_set_size", "int", ()),
)

# Copied cell for cell from SKILL.md's Resume table, and pinned against it by
# tests/work-wave-smoke.sh. When the two disagree, the table is right. Re-copy
# the row and fix phase_of to match it; never edit the copy to match phase_of.
RESUME_ROWS = (
    (1, '`<COMMON>/work-wave/closed/wave-<WAVE_ID>/` exists', 'done; say so. Where a lane RUN_DIR is open again, stop instead, naming each such lane: its own `work-issue N` resumes it, and a closed wave never restarts'),
    (2, 'no WAVE_DIR, or WAVE_DIR with `lanes.md` or `harvest.md` missing', 'Step 0'),
    (3, '`lanes.md` and `harvest.md`; no `footprint/check.txt`', 'Step 1'),
    (4, '`check.txt`; `coupling.md` or `order.md` missing', 'Step 2'),
    (5, '`order.md`; no `merge-test/0.md`', 'Step 3, every `ask` row and the confirmation again, then Step 4'),
    (6, '`merge-test/0.md`; some saved build report has no `gate/issue-<N>.md`, or some gate record recorded a stop', "Step 5 for the ungated reports only, then probe again; a recorded stop stops the wave again, naming the lane and its pull-request URL or the re-check's stderr lines, until the user rules on it"),
    (7, '`merge-test/0.md`; some unheld lane has no `reports/issue-N-build.json`', 'Step 4 for those lanes only, in one message; a lane whose RUN_DIR exists is resumed by its own `work-issue`, and its build report is whatever it returns'),
    (8, 'every gate record; some lane in the merge set has no `reports/issue-N-publish.json`, and the newest `merge-test/<k>.md` with k > 0 whose recorded branches are exactly the merge set, each at its current HEAD, is missing or not green', 'Step 6, which stops again on a red or conflicted record'),
    (9, 'the newest merge test over exactly the merge set at its current HEADs is green; some lane in the merge set has no `reports/issue-N-publish.json`', "Step 7 for those lanes only, when the fetched `origin/DEFAULT` equals that merge test's `base:`; where it differs, Step 6, then Step 7"),
    (10, 'every publish report; a non-empty merge set; the HEAD of some lane in it moved since the newest merge test, or that test merged a lane that has since left the merge set', "Step 8's re-test, then the report"),
    (11, 'every publish report; the newest merge test over exactly the merge set at its current HEADs is green, or an empty merge set', "Step 8's report"),
)

ROUTES = ("done", "stopped", "failed", "refused", "early-publish", "recheck-failed")
RECORDED_STOPS = ("early-publish", "recheck-failed")
OUT_OF_SET = ("stopped", "failed", "refused")
RESULTS = ("green", "red", "conflict")

WAVE_NAME = re.compile(r"wave-([1-9][0-9]*(?:-[1-9][0-9]*)*)")
LANE_CELL = re.compile(r"(?:issue-|#)?([1-9][0-9]*)")
SHA = r"[0-9a-f]{40,64}"
BASE_LINE = re.compile(rf"base: \S+ ({SHA})")
LANE_LINE = re.compile(rf"issue-([1-9][0-9]*) ({SHA})")
# First token only: a note after it ("result: green (baseline red only)") is
# the orchestrator's, and the token still has to be in RESULTS/ROUTES.
RESULT_LINE = re.compile(r"result: (\S+)(?:\s.*)?")
ROUTE_LINE = re.compile(r"route: (\S+)(?:\s.*)?")
GIT_TIMEOUT = 60


class InputError(Exception):
    def __init__(self, problems):
        super().__init__("\n".join(problems))
        self.problems = problems


class Unknown(Exception):
    """A read failed, so the field it feeds is null. Every row reads false as
    not done or nothing to do, so a failed read never becomes false."""


def check_probe(probe):
    """Every field present, each null or of its kind. `detail` and any other
    extra key are ignored."""
    if not isinstance(probe, dict):
        raise InputError([f"probe: expected a JSON object, got {type(probe).__name__}"])
    problems = []
    for name, kind, _ in PROBE_FIELDS:
        if name not in probe:
            problems.append(f"probe: missing field {name}")
            continue
        value = probe[name]
        if value is None:
            continue
        if kind == "bool" and not isinstance(value, bool):
            problems.append(f"probe: {name} is {value!r}, expected a boolean")
        elif kind == "int" and (isinstance(value, bool) or not isinstance(value, int)):
            problems.append(f"probe: {name} is {value!r}, expected an integer")
    if problems:
        raise InputError(problems)


def flag(probe, name):
    return bool(probe[name])


def count(probe, name):
    value = probe[name]
    return 0 if value is None else int(value)


def null_fields(probe):
    """The fields the generic null check stops on, in field order. A module
    function so `resume_checks.py invariants` and `liveness` can stub it."""
    return [name for name, _, _ in PROBE_FIELDS if probe[name] is None]


def phase_of(probe):
    """The Resume table, in its own order, first match wins, one branch per
    row. Reads fields only through `flag`, `count`, or `probe[...]`, and
    compares counts only with 0, so `resume_checks.py` can inline it."""
    # The null check runs ahead of row 1 too. A closed wave with an unreadable
    # lane count would otherwise read the null as 0 and answer done.
    unknown = null_fields(probe)
    if unknown:
        return (
            "stop",
            "unknown probe fields: " + ", ".join(unknown)
            + "; a null here would read as no, so fix what probe's stderr names and probe again",
        )
    # A closed wave never falls through to row 2: with WAVE_DIR moved away,
    # Step 0 would rebuild a finished wave whose Step 8 move then collides
    # with closed/wave-<WAVE_ID>/ (ledger row 50).
    if flag(probe, "wave_closed"):
        if count(probe, "lane_run_dirs_open") == 0:
            return "done", "row 1: the wave is under closed/ and no lane RUN_DIR is open; say so"
        return (
            "stop",
            "row 1: the wave is under closed/ and a lane RUN_DIR is open again; stop, naming each such lane, "
            "whose own work-issue N resumes it, and never restart the closed wave",
        )
    if not flag(probe, "wave_dir") or not flag(probe, "lanes_md") or not flag(probe, "harvest_md"):
        return "0", "row 2: no WAVE_DIR, or lanes.md or harvest.md is missing; run Step 0"
    if not flag(probe, "footprint_check"):
        return "1", "row 3: lanes.md and harvest.md, and no footprint/check.txt; run Step 1"
    # An ask is Step 2's finished output and Step 3's input, so it goes on to
    # row 5. Sent back to Step 2, it gets written again and loops (ledger row 49).
    if not flag(probe, "coupling_md") or not flag(probe, "order_md"):
        return "2", "row 4: coupling.md or order.md is missing; run Step 2"
    if not flag(probe, "baseline_test"):
        return "3", "row 5: order.md, and no merge-test/0.md; run Step 3, every ask row and the confirmation again, then Step 4"
    if count(probe, "gate_stops") > 0:
        return (
            "stop",
            "row 6: a gate record recorded a stop; stop the wave again, naming the lane and its "
            "pull-request URL or the re-check's stderr lines, until the user rules on it",
        )
    if count(probe, "build_ungated") > 0:
        return "5", "row 6: a saved build report has no gate record; run Step 5 for the ungated reports only, then probe again"
    if count(probe, "unheld_unreported") > 0:
        return "4", "row 7: an unheld lane has no build report; run Step 4 for those lanes only, in one message"
    # Row 8 is pre-publish only, or it shadows row 10 once a repair moves a
    # published HEAD. It asks for green too, or a red record at the current
    # HEADs matches no row at all (ledger row 48).
    if count(probe, "publish_unreported") > 0 and not (
        flag(probe, "merge_test_matches") and flag(probe, "merge_test_green")
    ):
        return "6", "row 8: every report is gated, a lane has no publish report, and no green merge test since the baseline records exactly the merge set at its current HEADs; run Step 6, which stops again on red"
    if flag(probe, "merge_test_green") and count(probe, "publish_unreported") > 0:
        if not flag(probe, "base_current"):
            return "6", "row 9: origin/DEFAULT differs from the green merge test's base:; run Step 6, then Step 7"
        return "7", "row 9: a green merge test over the merge set at its current HEADs, and a lane has no publish report; run Step 7 for those lanes only"
    if count(probe, "publish_unreported") == 0 and flag(probe, "heads_moved"):
        return "8", "row 10: every publish report, and a merge-set lane's HEAD moved or a lane left the merge set since the newest merge test; run Step 8's re-test, then the report"
    # Every lane failed, stopped, or held leaves nothing to merge-test or
    # publish, and no green record can ever match an empty set.
    if count(probe, "publish_unreported") == 0 and (
        flag(probe, "merge_test_green") or count(probe, "merge_set_size") == 0
    ):
        return "8", "row 11: every publish report, and a green merge test over the merge set at its current HEADs or an empty merge set; run Step 8's report"
    return (
        "stop",
        "no resume row matches: a merge test records the merge set at its current HEADs and is not green; "
        "report the probe and stop",
    )


def merge_set(order_rows, routes, published):
    """The lanes Step 6 merges, in `order.md`'s order: every lane not `held`,
    less any whose gate record or publish report routed it out. Step 7 routes
    a publish report by Step 5's table without rewriting the gate record, so
    reading routes alone kept a lane that failed publishing in the set."""
    return [
        lane for order, lane in order_rows
        if order != "held" and routes.get(lane) not in OUT_OF_SET and published.get(lane) not in OUT_OF_SET
    ]


def bare(cell):
    return cell.strip().strip("`").strip()


def table_rows(text, header, label):
    """The cells of each body row of the first table whose header is `header`.
    A row may carry extra cells, since an Evidence or Why cell can quote a
    `|`, so callers index from the front or take the last cell."""
    lines = text.split("\n")
    for i, line in enumerate(lines):
        if line.strip().startswith("|") and [c.strip() for c in line.strip().strip("|").split("|")] == header:
            break
    else:
        raise Unknown(f"{label} has no | {' | '.join(header)} | table")
    rows = []
    for line in lines[i + 1:]:
        line = line.strip()
        if not line.startswith("|"):
            break
        cells = [c.strip() for c in line.strip("|").split("|")]
        if all(re.fullmatch(r":?-+:?", c) for c in cells):
            continue
        if len(cells) < len(header):
            raise Unknown(f"{label}: a row has {len(cells)} cells, fewer than its header's {len(header)}")
        rows.append(cells)
    return rows


class Wave:
    def __init__(self, wave_dir, common, root, default, lanes):
        self.dir = wave_dir
        self.common = common
        self.root = root
        self.default = default
        self.lanes = lanes

    def has(self, sub):
        return (self.dir / sub).is_file()

    def read(self, sub):
        try:
            return (self.dir / sub).read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError) as e:
            raise Unknown(f"{sub}: {e}")

    def numbered(self, sub, pattern):
        """{number: name} for the files in `sub` whose name fully matches
        `pattern`, or {} where `sub` is absent."""
        directory = self.dir / sub
        if not directory.is_dir():
            return {}
        found = {}
        for path in directory.iterdir():
            match = re.fullmatch(pattern, path.name)
            if match:
                found[int(match.group(1))] = path.name
        return found

    def rev(self, ref):
        try:
            done = subprocess.run(
                ["git", "-C", str(self.root), "rev-parse", "--verify", "--quiet", ref],
                capture_output=True, text=True, timeout=GIT_TIMEOUT,
            )
        except (OSError, subprocess.TimeoutExpired) as e:
            raise Unknown(f"git rev-parse {ref}: {e}")
        if done.returncode != 0:
            raise Unknown(f"git rev-parse --verify {ref} found no commit")
        return done.stdout.strip()

    def coupling_asks(self):
        if not self.has("coupling.md"):
            return 0
        rows = table_rows(self.read("coupling.md"), ["Pair", "Answer", "Evidence", "Resolution"], "coupling.md")
        return sum(1 for cells in rows if bare(cells[-1]).startswith("ask"))

    def order_rows(self):
        if not self.has("order.md"):
            return []
        rows = []
        for cells in table_rows(self.read("order.md"), ["Order", "Lane", "After", "Why"], "order.md"):
            match = LANE_CELL.fullmatch(bare(cells[1]))
            if not match:
                raise Unknown(f"order.md: lane cell {cells[1]!r} names no issue")
            rows.append((bare(cells[0]), int(match.group(1))))
        # Step 2 places or holds every lane, so a lane the table omits is a torn
        # write, not finished work; read as done, it vanished from every count.
        named = [lane for _, lane in rows]
        for lane in sorted(set(named)):
            if named.count(lane) > 1:
                raise Unknown(f"order.md names issue-{lane} {named.count(lane)} times")
        missing = sorted(set(self.lanes) - set(named))
        if missing:
            raise Unknown(f"order.md has no row for {', '.join(f'issue-{n}' for n in missing)}")
        extra = sorted(set(named) - set(self.lanes))
        if extra:
            raise Unknown(f"order.md names {', '.join(f'issue-{n}' for n in extra)}, not a lane of {self.dir.name}")
        return rows

    def gates(self):
        return self.numbered("gate", r"issue-([1-9][0-9]*)\.md")

    def routes(self):
        """{lane: route} from each gate record's first line. A record with no
        `route:` line, or an unknown route, is unreadable rather than done."""
        routes = {}
        for lane, name in sorted(self.gates().items()):
            text = self.read(f"gate/{name}")
            first = text.split("\n", 1)[0].strip()
            match = ROUTE_LINE.fullmatch(first)
            if not match:
                raise Unknown(f"gate/{name} does not open with a route: line")
            if match.group(1) not in ROUTES:
                raise Unknown(f"gate/{name}: route {match.group(1)!r} is not one of {', '.join(ROUTES)}")
            routes[lane] = match.group(1)
        return routes

    def build_reports(self):
        return self.numbered("reports", r"issue-([1-9][0-9]*)-build\.json")

    def published(self):
        """{lane: status} from each publish report. A `stopped` lane whose
        RUN_DIR holds `triage/waiting` is `done` (Step 7): it stopped on the
        review poll's cap, after its pull request opened. A report that isn't
        a JSON object with a known `status` is unreadable, never in or out."""
        statuses = {}
        for lane, name in self.numbered("reports", r"issue-([1-9][0-9]*)-publish\.json").items():
            try:
                report = json.loads(self.read(f"reports/{name}"))
            except ValueError as e:
                raise Unknown(f"reports/{name}: {e}")
            status = report.get("status") if isinstance(report, dict) else None
            if status not in ("done",) + OUT_OF_SET:
                raise Unknown(f"reports/{name}: status {status!r} is not one of done, {', '.join(OUT_OF_SET)}")
            run_dirs = (self.common / "work-issue" / f"issue-{lane}", self.common / "work-issue" / "closed" / f"issue-{lane}")
            if status == "stopped" and any((d / "triage" / "waiting").is_file() for d in run_dirs):
                status = "done"
            statuses[lane] = status
        return statuses

    def merge_set(self):
        return merge_set(self.order_rows(), self.routes(), self.published())

    def records(self):
        """{k: (base sha, {lane: sha}, result)} for every merge-test/<k>.md
        with k > 0. One record without its base: or result: line makes all of
        them unreadable, since the newest might be the one that's broken."""
        records = {}
        for k, name in self.numbered("merge-test", r"([1-9][0-9]*)\.md").items():
            base, lanes, result = None, {}, None
            for line in self.read(f"merge-test/{name}").split("\n"):
                line = line.strip()
                if base is None and BASE_LINE.fullmatch(line):
                    base = BASE_LINE.fullmatch(line).group(1)
                elif LANE_LINE.fullmatch(line):
                    lane, sha = LANE_LINE.fullmatch(line).groups()
                    if int(lane) in lanes:
                        raise Unknown(f"merge-test/{name} records issue-{lane} twice")
                    lanes[int(lane)] = sha
                elif result is None and RESULT_LINE.fullmatch(line):
                    result = RESULT_LINE.fullmatch(line).group(1)
                    # What follows is VERIFY_CMD's tail, which may print `issue-<N> <sha>`.
                    break
            if base is None:
                raise Unknown(f"merge-test/{name} has no base: <ref> <sha> line")
            if result is None:
                raise Unknown(f"merge-test/{name} has no result: line")
            if result not in RESULTS:
                raise Unknown(f"merge-test/{name}: result {result!r} is not one of {', '.join(RESULTS)}")
            records[k] = (base, lanes, result)
        return records

    def heads(self, lanes):
        return {lane: self.rev(f"refs/heads/issue-{lane}") for lane in lanes}

    def matching(self):
        """The ks whose record names exactly the merge set, each lane at its
        current HEAD. HEADs are read only once some record's lanes equal the
        merge set, so a lane still building with no branch yet isn't a null,
        and then for every merge-set lane, so one missing branch can't hide
        behind another's mismatch."""
        lanes = self.merge_set()
        records = self.records()
        same = [k for k, (_, recorded, _) in sorted(records.items()) if set(recorded) == set(lanes)]
        if not same:
            return [], records
        heads = self.heads(lanes)
        return [k for k in same if records[k][1] == heads], records

    def newest_matching(self):
        """The highest-k matching record, or None. Only it decides: a red
        re-test at SHAs an older record passed has to block publishing, or a
        crash between the red record and Step 6's stop publishes anyway."""
        matching, records = self.matching()
        return records[max(matching)] if matching else None

    def merge_test_green(self):
        newest = self.newest_matching()
        return newest is not None and newest[2] == "green"

    def base_current(self):
        newest = self.newest_matching()
        if newest is None or newest[2] != "green":
            return False
        return newest[0] == self.rev(f"refs/remotes/origin/{self.default}")

    def heads_moved(self):
        """True where Step 8 must re-test: a merge-set lane's HEAD differs from
        the newest record, or the record's lanes aren't the merge set because a
        lane left it at Step 7. An empty set has nothing to re-test."""
        records = self.records()
        lanes = self.merge_set()
        if not records or not lanes:
            return False
        recorded = records[max(records)][1]
        if set(recorded) != set(lanes):
            return True
        heads = self.heads(lanes)
        return any(recorded[lane] != heads[lane] for lane in lanes)


def gather(wave):
    """(probe, [stderr lines]). Each field is computed alone, so one failed
    read nulls only the fields that depend on it."""
    reports = lambda kind: set(wave.numbered("reports", rf"issue-([1-9][0-9]*)-{kind}\.json"))
    gatherers = {
        "wave_closed": lambda: (wave.common / "work-wave" / "closed" / wave.dir.name).is_dir(),
        "lane_run_dirs_open": lambda: sum(
            1 for lane in wave.lanes if (wave.common / "work-issue" / f"issue-{lane}").is_dir()
        ),
        "wave_dir": lambda: wave.dir.is_dir(),
        "lanes_md": lambda: wave.has("lanes.md"),
        "harvest_md": lambda: wave.has("harvest.md"),
        "footprint_check": lambda: wave.has("footprint/check.txt"),
        "coupling_md": lambda: wave.has("coupling.md"),
        "order_md": lambda: wave.has("order.md"),
        "coupling_asks": wave.coupling_asks,
        "baseline_test": lambda: wave.has("merge-test/0.md"),
        "build_ungated": lambda: len(reports("build") - set(wave.gates())),
        "gate_stops": lambda: sum(1 for route in wave.routes().values() if route in RECORDED_STOPS),
        "unheld_unreported": lambda: sum(
            1 for order, lane in wave.order_rows() if order != "held" and lane not in reports("build")
        ),
        "merge_test_matches": lambda: bool(wave.matching()[0]),
        "merge_test_green": wave.merge_test_green,
        "base_current": wave.base_current,
        "publish_unreported": lambda: sum(1 for lane in wave.merge_set() if lane not in reports("publish")),
        "heads_moved": wave.heads_moved,
        "merge_set_size": lambda: len(wave.merge_set()),
    }
    probe, why = {}, []
    for name, _, _ in PROBE_FIELDS:
        try:
            probe[name] = gatherers[name]()
        except Unknown as e:
            probe[name] = None
            why.append(f"{name} is null: {e}")
    return probe, why


def read_bundle(path):
    try:
        bundle = json.loads(Path(path).read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, ValueError) as e:
        raise InputError([f"--pr-bundle {path}: {e}"])
    if not isinstance(bundle, dict):
        raise InputError([f"--pr-bundle {path}: expected an object of issue-<N> to a list of URLs"])
    problems = [
        f"--pr-bundle {path}: {key!r} must be issue-<N> with a list of URL strings"
        for key, urls in bundle.items()
        if not re.fullmatch(r"issue-[1-9][0-9]*", key)
        or not isinstance(urls, list)
        or not all(isinstance(url, str) for url in urls)
    ]
    if problems:
        raise InputError(problems)
    return bundle


def cmd_probe(args):
    def usage(problems):
        for problem in problems:
            sys.stderr.write(f"wave-state: probe: {problem}\n")
        return 3

    root = Path(args.root).absolute()
    try:
        done = subprocess.run(
            ["git", "-C", str(root), "rev-parse", "--git-common-dir"],
            capture_output=True, text=True, timeout=GIT_TIMEOUT,
        )
    except (OSError, subprocess.TimeoutExpired) as e:
        return usage([f"--root {args.root}: {e}"])
    if done.returncode != 0:
        return usage([f"--root {args.root} is not a git repository"])
    common = (root / done.stdout.strip()).resolve()
    wave_dir = Path(args.wave_dir).absolute()
    name = WAVE_NAME.fullmatch(wave_dir.name)
    if not name:
        return usage([f"--wave-dir {args.wave_dir}: the directory name must be wave-<N>[-<N>...]"])
    lanes = [int(n) for n in name.group(1).split("-")]
    try:
        bundle = read_bundle(args.pr_bundle) if args.pr_bundle else None
    except InputError as e:
        return usage(e.problems)
    probe, why = gather(Wave(wave_dir, common, root, args.default, lanes))
    for line in why:
        sys.stderr.write(f"wave-state: probe: {line}\n")
    probe["detail"] = {"prs": bundle}
    print(json.dumps(probe, indent=2))
    return 0


def cmd_phase(args):
    try:
        try:
            probe = json.loads(Path(args.probe).read_text(encoding="utf-8"))
        except (OSError, UnicodeDecodeError, ValueError) as e:
            raise InputError([f"probe: {args.probe}: {e}"])
        check_probe(probe)
    except InputError as e:
        for problem in e.problems:
            sys.stderr.write(f"wave-state: {problem}\n")
        return 3
    phase, reason = phase_of(probe)
    print(f"phase: {phase} reason: {reason}")
    return 1 if phase == "stop" else 0


def parse_args(argv):
    ap = argparse.ArgumentParser(description="Gather a wave's resume probe and map it to a phase.")
    sub = ap.add_subparsers(dest="command", required=True)
    p = sub.add_parser("probe", help="print the probe JSON for one WAVE_DIR")
    p.add_argument("--wave-dir", required=True)
    p.add_argument("--root", required=True)
    p.add_argument("--default", required=True)
    p.add_argument("--pr-bundle")
    p.set_defaults(func=cmd_probe)
    q = sub.add_parser("phase", help="answer the phase a probe resumes at")
    q.add_argument("--probe", required=True)
    q.set_defaults(func=cmd_phase)
    return ap.parse_args(argv)


def main(argv=None):
    argv = sys.argv[1:] if argv is None else list(argv)
    try:
        args = parse_args(argv)
    except SystemExit as e:
        # The validator convention's 3 for usage, where argparse would give 2.
        return 3 if e.code == 2 else e.code
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
