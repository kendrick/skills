#!/usr/bin/env python3
"""End-to-end checks of work-issue's resume table against the writes the skill makes.

    work-issue/scripts/resume_checks.py crash-points --model work-issue/scripts/write-order.json

`crash-points` replays each sequence in the model, one write at a time, in a
scratch repository with a bare origin under `mktemp -d`. Before every write,
and once after the last, it runs the real `run-state.py probe` and `phase` and
compares the answer with the entry's `resume`. A wrong answer prints one line:

    <sequence>#<i> before <subpath>: expected <phase> row <n>, got <phase> row <n>

The last line is `rows covered:` and the rows 1 through 19 that some expected
answer names. Exit 0 when every prefix resumes where the model says and every
row is covered, 1 when a prefix resumes wrong or a row is missing, 3 on a usage
error, a missing or malformed model, or a model whose writes can't be replayed.

The model is a JSON object. `bundles` maps a name to a pull-request bundle in
the shape `run-state.py review --save` writes. `sequences` is a list, and each
sequence carries:

- `name`, unique.
- `run_dir`, the RUN_DIR's name under the scratch repo's `.git/work-issue/`.
- `probe`, `{"issue": N}` or `{"pr": M}`, which picks the probe's flag.
- `branch`, optional, `issue-<N>` by default.
- `bundle`, optional, the bundle in place before the first write.
- `setup`, optional entries run first and never checked, for world state the
  skill finds rather than makes.
- `prefix`, optional `{"sequence": <earlier name>, "through": <entry id>}`:
  that sequence's setup and entries up to and including the one with that
  `id`, replayed unchecked, so a side sequence starts where the main one was.
- `entries`, the writes in the order the skill makes them.
- `end`, the answer once every entry has run.

An entry carries `step` (0-8), `subpath`, `op` with that op's arguments, and
exactly one of `resume` or `blind`. `subpath` is the RUN_DIR subpath as
SKILL.md spells it, `<wave>` and `<k>` included, or a world-side name:
`branch`, `push`, `pr`, `tree` for a worker's edit, `herdr`, and `origin` for
the default branch moving under the run. A directory subpath in SKILL.md, such
as `reports/`, is covered by any entry under it. The concrete file goes in the
op's `path`.

`resume` is `{"phase": <0-8|done|wait|stop>, "row": <1-19 or null>}`, null for
a stop whose reason names no row, or `{"exit": 3}` where probe must refuse.
`blind` is the reason a write is safe to lose. Such a write changes nothing
probe reads, so the prefix before it must answer what the next non-blind entry
expects.
`cite`, optional, names the prose the answer was read from.

Ops: `write`, `append`, `remove`, and `rename` act on RUN_DIR paths; `edit`
writes a file in the work tree; `commit`, `branch`, `push`, `rebase` (with
`conflict: true` where it must stop), and `resolve` drive git; `worktree`
checks the branch out in its own tree from origin; `upstream` commits to
origin's `branch`, `main` by default, from a throwaway clone; `pr` swaps in a
named bundle, or none; `herdr` sets the state passed as `--herdr-state`. A
`content` of `{head}` or `{merge_base}` is replaced with that SHA.

    work-issue/scripts/resume_checks.py invariants --model work-issue/scripts/write-order.json
    work-issue/scripts/resume_checks.py liveness --model work-issue/scripts/write-order.json

These two read the model's `invariants`, `assumptions`, and `effects`, import
`run-state.py` from beside this script, and run `phase_of` in-process over
every non-null probe, with no git and no subprocess.

They don't list probes one at a time. A field `phase_of` hasn't tested yet is
open, and each test it makes of an open field splits the search, so one search
path stands for every probe that takes it. Before the search, each local in
`phase_of` that holds a pure probe read is inlined where it's used: computed up
front, those locals tested a dozen fields on every path. Counts run 0-2, and
the run exits 3 where `phase_of` compares a count with a literal other than 0.

`invariants` prints one line per invariant and answer, naming the first probe
in field order that breaks it:

    <invariant name>: <phase> row <n> on {<the fields phase_of and the invariant read>}

A null sweep then sets each field but `pr_state` and `review_state` to null in
turn, and prints `null: ...` where a null answers a step number. The last line
is `probes: <n> leaves, <m> pruned`: the distinct answers reached, and how many
of them only probes the assumptions rule out can reach.

`liveness` follows every path from every probe: `phase_of`, one outcome of that
step's effect, `phase_of` again, until a stop, a wait, or done. A path that
comes back to a state it already held prints
`cycle: <phase> row <n> -> ... -> <phase> row <n> on {...}`, and one still
going after 40 transitions prints `unbounded: ...`. The last line is
`paths: <n>`, the distinct moves from one answer to the next. It takes
minutes, where `invariants` takes seconds.

Both exit 0 when nothing printed on stderr, 1 on a violation or a loop, and 3
on a usage error, a malformed model, a blank `cite`, a failed count bound, or
an inlined `phase_of` that answers differently from the real one.

`invariants` and `assumptions` are lists of
`{"name", "cite", "if": [atoms], "then": [atoms]}`. An atom is
`[lhs, op, rhs]`: `lhs` is a probe field or `phase`, which an assumption may
not read; `op` is `==`, `!=`, `in`, `<`, `<=`, `>`, or `>=`; `rhs` is a
literal, a list for `in`, or `{"field": name}`. An empty `if` always holds. A
probe where an assumption's `if` holds and its `then` fails is pruned, and one
where an invariant's does is a violation. `effects` holds one entry per step,
`{"step", "done_when": [RUN_DIR paths], "cite", "outcomes"}`, and each outcome
is `{"name", "set", "add", "if"}` or `{"name", "terminal": "stop"}`. Every
step needs one outcome with no `if`.

Standard library only, so the skill stays copy-in portable.
"""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

RUN_STATE = Path(__file__).resolve().parent / "run-state.py"
DEFAULT = "main"
ROWS = tuple(range(1, 20))
PHASES = tuple(str(n) for n in range(9)) + ("done", "wait", "stop")
HERDR_STATES = ("working", "blocked", "idle", "done", "absent")
OPS = {
    "write": ("path", "content"),
    "append": ("path", "content"),
    "remove": ("path",),
    "rename": ("path", "to"),
    "edit": ("file", "content"),
    "commit": ("paths", "message"),
    "branch": (),
    "push": (),
    "rebase": (),
    "resolve": ("file", "content"),
    "worktree": (),
    "upstream": ("file", "content"),
    "pr": ("bundle",),
    "herdr": ("state",),
}
PHASE_LINE = re.compile(r"phase: (\S+) reason: (.*)")
ROW_REASON = re.compile(r"row ([0-9]+):")


class ModelError(Exception):
    """A model this script can't read or replay. Carries every problem found,
    so a hand-edited model costs one run to fix rather than one per typo."""

    def __init__(self, problems):
        self.problems = list(problems)
        super().__init__("; ".join(self.problems))


def check_resume(value, where, problems):
    if not isinstance(value, dict):
        problems.append(f"{where}: expected an object")
    elif set(value) == {"exit"}:
        if value["exit"] != 3:
            problems.append(f"{where}: exit must be 3")
    elif set(value) != {"phase", "row"}:
        problems.append(f"{where}: expected phase and row, or exit")
    else:
        if value["phase"] not in PHASES:
            problems.append(f"{where}: phase {value['phase']!r} is not one of {', '.join(PHASES)}")
        row = value["row"]
        if row is not None and (isinstance(row, bool) or row not in ROWS):
            problems.append(f"{where}: row {row!r} is not 1-19 or null")


def check_entry(entry, where, bundles, problems, checked):
    if not isinstance(entry, dict):
        problems.append(f"{where}: expected an object")
        return
    op = entry.get("op")
    # A list or object in a field tested with `in` against a dict raises
    # TypeError, which would exit 1 as if it were a resume hole.
    if not isinstance(op, str) or op not in OPS:
        problems.append(f"{where}: op {op!r} is not one of {', '.join(OPS)}")
        return
    for key in OPS[op]:
        if key not in entry:
            problems.append(f"{where}: {op} needs {key}")
    # file lands in the work tree or an upstream clone, so a stray ".." or "/" would write outside the scratch tree
    for key in ("path", "to", "file"):
        value = entry.get(key)
        if value is not None and (
            not isinstance(value, str) or not value or value.startswith("/") or ".." in Path(value).parts
        ):
            problems.append(f"{where}: {key} {value!r} must be a relative path with no '..' part")
    if op == "pr" and entry.get("bundle") is not None and (
        not isinstance(entry["bundle"], str) or entry["bundle"] not in bundles
    ):
        problems.append(f"{where}: no bundle named {entry.get('bundle')!r}")
    if op == "herdr" and entry.get("state") not in HERDR_STATES:
        problems.append(f"{where}: herdr state {entry.get('state')!r} is not one of {', '.join(HERDR_STATES)}")
    if not checked:
        return
    step = entry.get("step")
    if isinstance(step, bool) or step not in range(9):
        problems.append(f"{where}: step {step!r} is not 0-8")
    if not isinstance(entry.get("subpath"), str) or not entry["subpath"].strip():
        problems.append(f"{where}: subpath must be a non-empty string")
    if ("resume" in entry) == ("blind" in entry):
        problems.append(f"{where}: needs exactly one of resume or blind")
    elif "blind" in entry:
        # An empty reason is a write nobody checked, which is what the field
        # exists to rule out.
        if not isinstance(entry["blind"], str) or not entry["blind"].strip():
            problems.append(f"{where}: blind needs a reason")
    else:
        check_resume(entry["resume"], f"{where}.resume", problems)


def check_model(model):
    """Raise ModelError naming every problem in a parsed model."""
    problems = []
    if not isinstance(model, dict):
        raise ModelError([f"model: expected a JSON object, got {type(model).__name__}"])
    bundles = model.get("bundles", {})
    if not isinstance(bundles, dict) or not all(isinstance(b, dict) for b in bundles.values()):
        problems.append("bundles: expected an object of objects")
        bundles = {}
    sequences = model.get("sequences")
    if not isinstance(sequences, list) or not sequences:
        raise ModelError(problems + ["sequences: expected a non-empty list"])
    seen = {}
    for index, seq in enumerate(sequences):
        where = f"sequences[{index}]"
        if not isinstance(seq, dict):
            problems.append(f"{where}: expected an object")
            continue
        name = seq.get("name")
        if not isinstance(name, str) or not name or name in seen:
            problems.append(f"{where}: name must be a unique non-empty string")
        where = f"sequence {name}"
        if not isinstance(seq.get("run_dir"), str) or not re.fullmatch(r"[A-Za-z0-9._-]+", seq["run_dir"]):
            problems.append(f"{where}: run_dir must be a plain directory name")
        probe = seq.get("probe")
        if not (
            isinstance(probe, dict) and len(probe) == 1
            and next(iter(probe)) in ("issue", "pr")
            and isinstance(next(iter(probe.values())), int)
            and next(iter(probe.values())) > 0
        ):
            problems.append(f"{where}: probe must be {{\"issue\": N}} or {{\"pr\": M}}")
        if "branch" in seq and (not isinstance(seq["branch"], str) or not seq["branch"]):
            problems.append(f"{where}: branch must be a non-empty string")
        if seq.get("bundle") is not None and (not isinstance(seq["bundle"], str) or seq["bundle"] not in bundles):
            problems.append(f"{where}: no bundle named {seq['bundle']!r}")
        setup = seq.get("setup", [])
        if not isinstance(setup, list):
            problems.append(f"{where}: setup must be a list")
            setup = []
        for i, entry in enumerate(setup):
            check_entry(entry, f"{where} setup[{i}]", bundles, problems, checked=False)
        prefix = seq.get("prefix")
        if prefix is not None:
            named = prefix.get("sequence") if isinstance(prefix, dict) else None
            source = seen.get(named) if isinstance(named, str) else None
            if source is None:
                problems.append(f"{where}: prefix must name an earlier sequence")
            elif not any(
                e.get("id") == prefix.get("through")
                for e in (source.get("entries") if isinstance(source.get("entries"), list) else [])
                if isinstance(e, dict)
            ):
                problems.append(f"{where}: {prefix.get('sequence')} has no entry with id {prefix.get('through')!r}")
        entries = seq.get("entries")
        if not isinstance(entries, list) or not entries:
            problems.append(f"{where}: entries must be a non-empty list")
            entries = []
        for i, entry in enumerate(entries):
            check_entry(entry, f"{where}#{i}", bundles, problems, checked=True)
        if "end" not in seq:
            problems.append(f"{where}: needs end")
        else:
            check_resume(seq["end"], f"{where}.end", problems)
        if isinstance(name, str) and name not in seen:
            seen[name] = seq
    if problems:
        raise ModelError(problems)


def load_model(path):
    try:
        with open(path, encoding="utf-8") as handle:
            model = json.load(handle)
    except FileNotFoundError:
        raise ModelError([f"--model {path}: no such file"])
    except (OSError, UnicodeDecodeError, ValueError) as e:
        raise ModelError([f"--model {path}: {e}"])
    check_model(model)
    return model


def expectations(seq):
    """The expected answer at each checkpoint: before entry i, then the end.

    A blind entry takes the next checkpoint's answer, because losing it to a
    crash must leave the run where the next real write expects it."""
    entries = seq["entries"]
    expected = [None] * len(entries) + [seq["end"]]
    for i in range(len(entries) - 1, -1, -1):
        expected[i] = expected[i + 1] if "blind" in entries[i] else entries[i]["resume"]
    return expected


def show(answer):
    if "exit" in answer:
        return f"exit {answer['exit']}"
    row = "none" if answer["row"] is None else answer["row"]
    return f"{answer['phase']} row {row}"


class Scratch:
    """One sequence's scratch repo, origin, fake tools, and probe state."""

    def __init__(self, base, seq, bundles):
        self.base = base
        self.bundles = bundles
        self.branch = seq.get("branch") or f"issue-{seq['probe'].get('issue')}"
        self.probe_flag = ["--issue", str(seq["probe"]["issue"])] if "issue" in seq["probe"] else ["--pr", str(seq["probe"]["pr"])]
        self.root = base / "repo"
        self.origin = base / "repo.origin"
        self.tree = self.root
        self.run_dir = self.root / ".git" / "work-issue" / seq["run_dir"]
        self.bundle = seq.get("bundle")
        self.herdr = "absent"
        # File times start well in the past and step one second per write, so
        # every "newest by file time" read sees the order the model wrote in,
        # whatever the filesystem's timestamp resolution.
        self.clock = int(time.time()) - 100000
        fakebin = base / "fakebin"
        fakebin.mkdir()
        # probe must never call either, since GitHub's answer arrives as
        # --pr-bundle and herdr's as --herdr-state. A call leaves a marker that
        # the run reports.
        for tool in ("gh", "herdr"):
            fake = fakebin / tool
            fake.write_text(f'#!/bin/sh\ntouch "{base}/called-{tool}"\nexit 99\n')
            fake.chmod(0o755)
        # Pin the identity and drop global and system config, signing, and
        # hooks, so the user's own git config can't decide whether a scratch
        # commit lands or what the probe's git reads.
        self.env = {
            key: value for key, value in os.environ.items()
            if key != "HERDR_ENV" and not key.startswith("GIT_")
        }
        self.env.update(
            PATH=f"{fakebin}{os.pathsep}{os.environ.get('PATH', '')}",
            GIT_CONFIG_GLOBAL=os.devnull,
            GIT_CONFIG_NOSYSTEM="1",
            GIT_AUTHOR_NAME="resume-checks",
            GIT_AUTHOR_EMAIL="resume-checks@example.invalid",
            GIT_COMMITTER_NAME="resume-checks",
            GIT_COMMITTER_EMAIL="resume-checks@example.invalid",
            GIT_EDITOR="true",
            GIT_TERMINAL_PROMPT="0",
        )
        self.git(base, "init", "-q", "--bare", "-b", DEFAULT, str(self.origin))
        self.git(base, "init", "-q", "-b", DEFAULT, str(self.root))
        self.git(self.root, "config", "commit.gpgsign", "false")
        self.git(self.root, "config", "core.hooksPath", os.devnull)
        (self.root / "seed.txt").write_text("seed\n")
        self.git(self.root, "add", "seed.txt")
        self.git(self.root, "commit", "-q", "-m", "seed")
        self.git(self.root, "remote", "add", "origin", str(self.origin))
        self.git(self.root, "push", "-q", "origin", DEFAULT)

    def git(self, where, *args, ok=True):
        done = subprocess.run(
            ["git", "-C", str(where), *args], capture_output=True, text=True, env=self.env, cwd=self.base
        )
        if ok and done.returncode != 0:
            raise ModelError([f"git {' '.join(args)}: exit {done.returncode}: {done.stderr.strip()[:300]}"])
        return done

    def tick(self, path):
        self.clock += 1
        os.utime(path, (self.clock, self.clock))

    def fill(self, content):
        if "{head}" in content:
            content = content.replace("{head}", self.git(self.tree, "rev-parse", "HEAD").stdout.strip())
        if "{merge_base}" in content:
            sha = self.git(self.root, "merge-base", f"origin/{DEFAULT}", self.branch).stdout.strip()
            content = content.replace("{merge_base}", sha)
        return content

    def apply(self, entry):
        op = entry["op"]
        run_path = self.run_dir / entry["path"] if "path" in entry else None
        if op in ("write", "append"):
            run_path.parent.mkdir(parents=True, exist_ok=True)
            with open(run_path, "a" if op == "append" else "w", encoding="utf-8") as handle:
                handle.write(self.fill(entry["content"]))
            self.tick(run_path)
        elif op == "remove":
            run_path.unlink()
        elif op == "rename":
            target = self.run_dir / entry["to"]
            run_path.rename(target)
            self.tick(target)
        elif op == "edit":
            (self.tree / entry["file"]).write_text(entry["content"])
        elif op == "commit":
            self.git(self.tree, "add", "--", *entry["paths"])
            self.git(self.tree, "commit", "-q", "-m", entry["message"])
        elif op == "branch":
            self.git(self.root, "fetch", "-q", "origin", DEFAULT)
            self.git(self.root, "switch", "-q", "-c", self.branch, f"origin/{DEFAULT}")
        elif op == "push":
            lease = [f"--force-with-lease={self.branch}"] if entry.get("force") else ["-u"]
            self.git(self.tree, "push", "-q", *lease, "origin", f"{self.branch}:refs/heads/{self.branch}")
        elif op == "rebase":
            self.git(self.tree, "fetch", "-q", "origin", DEFAULT)
            done = self.git(self.tree, "rebase", f"origin/{DEFAULT}", ok=False)
            if (done.returncode != 0) != bool(entry.get("conflict")):
                raise ModelError([f"rebase exited {done.returncode}, conflict: {bool(entry.get('conflict'))}: {done.stderr.strip()[:300]}"])
        elif op == "resolve":
            (self.tree / entry["file"]).write_text(entry["content"])
            self.git(self.tree, "add", "--", entry["file"])
            self.git(self.tree, "rebase", "--continue")
        elif op == "worktree":
            self.tree = self.base / "worktree"
            self.git(self.root, "fetch", "-q", "origin", self.branch, DEFAULT)
            self.git(self.root, "worktree", "add", "-q", "--track", "-b", self.branch, str(self.tree), f"origin/{self.branch}")
        elif op == "upstream":
            clone = Path(tempfile.mkdtemp(prefix="upstream-", dir=self.base))
            self.git(self.base, "clone", "-q", str(self.origin), str(clone))
            branch = entry.get("branch", DEFAULT)
            if branch != DEFAULT:
                self.git(clone, "switch", "-q", "-c", branch)
            (clone / entry["file"]).write_text(entry["content"])
            self.git(clone, "add", "--", entry["file"])
            self.git(clone, "-c", "commit.gpgsign=false", "commit", "-q", "-m", f"upstream {entry['file']}")
            self.git(clone, "push", "-q", "origin", branch)
            shutil.rmtree(clone)
        elif op == "pr":
            self.bundle = entry["bundle"]
        elif op == "herdr":
            self.herdr = entry["state"]

    def answer(self):
        """What probe and phase say now: `{"phase", "row"}` or `{"exit", "why"}`."""
        args = [
            sys.executable, str(RUN_STATE), "probe", "--run-dir", str(self.run_dir),
            "--root", str(self.root), *self.probe_flag, "--herdr-state", self.herdr,
        ]
        if self.bundle is not None:
            bundle_file = self.base / "bundle.json"
            bundle_file.write_text(json.dumps(self.bundles[self.bundle]))
            args += ["--pr-bundle", str(bundle_file)]
        probe = subprocess.run(args, capture_output=True, text=True, env=self.env, cwd=self.base)
        if probe.returncode != 0:
            return {"exit": probe.returncode, "why": first_line(probe.stderr)}
        probe_file = self.base / "probe.json"
        probe_file.write_text(probe.stdout)
        phase = subprocess.run(
            [sys.executable, str(RUN_STATE), "phase", "--probe", str(probe_file)],
            capture_output=True, text=True, env=self.env, cwd=self.base,
        )
        match = PHASE_LINE.fullmatch(phase.stdout.strip())
        if phase.returncode != 0 or not match:
            return {"exit": phase.returncode, "why": first_line(phase.stderr or phase.stdout)}
        row = ROW_REASON.match(match.group(2))
        return {"phase": match.group(1), "row": int(row.group(1)) if row else None}

    def called(self):
        return [tool for tool in ("gh", "herdr") if (self.base / f"called-{tool}").exists()]


def first_line(text):
    return (text.strip().split("\n") or [""])[0]


def agrees(expected, got):
    if "exit" in expected:
        return got.get("exit") == expected["exit"]
    return "exit" not in got and got["phase"] == expected["phase"] and got["row"] == expected["row"]


def apply_entry(scratch, entry, where):
    """Apply one entry, turning a write the model can't make into a ModelError."""
    try:
        scratch.apply(entry)
    except ModelError as e:
        raise ModelError([f"{where}: {problem}" for problem in e.problems])
    except (OSError, KeyError, TypeError) as e:
        # A model typo, such as removing a file nothing wrote, exits 3 so it
        # can't pass for a resume hole's 1. answer() stays unguarded, so a wrong
        # answer from probe or phase still exits 1.
        raise ModelError([f"{where}: {type(e).__name__}: {e}"])


def run_sequence(model, seq, base):
    """Replay one sequence and return its wrong prefixes as printable lines."""
    by_name = {s["name"]: s for s in model["sequences"]}
    scratch = Scratch(base, seq, model.get("bundles", {}))
    unchecked = [(f"setup[{j}]", entry) for j, entry in enumerate(seq.get("setup", []))]
    prefix = seq.get("prefix")
    if prefix:
        source = by_name[prefix["sequence"]]
        unchecked += [(f"prefix {source['name']} setup[{j}]", entry) for j, entry in enumerate(source.get("setup", []))]
        for k, entry in enumerate(source["entries"]):
            unchecked.append((f"prefix {source['name']}#{k}", entry))
            if entry.get("id") == prefix["through"]:
                break
    for label, entry in unchecked:
        apply_entry(scratch, entry, f"sequence {seq['name']} {label}")
    wrong = []
    entries = seq["entries"]
    for i, expected in enumerate(expectations(seq)):
        got = scratch.answer()
        if not agrees(expected, got):
            where = f"before {entries[i]['subpath']}" if i < len(entries) else "end"
            shown = show(got) + (f" ({got['why']})" if got.get("why") else "")
            wrong.append(f"{seq['name']}#{i} {where}: expected {show(expected)}, got {shown}")
        if i < len(entries):
            apply_entry(scratch, entries[i], f"sequence {seq['name']}#{i}")
    for tool in scratch.called():
        wrong.append(f"{seq['name']}: probe called {tool}, which it must never do")
    return wrong


def covered_rows(model):
    rows = set()
    for seq in model["sequences"]:
        for answer in [e["resume"] for e in seq["entries"] if "resume" in e] + [seq["end"]]:
            if answer.get("row") is not None:
                rows.add(answer["row"])
    return sorted(rows)


def cmd_crash_points(args):
    try:
        model = load_model(args.model)
    except ModelError as e:
        for problem in e.problems:
            sys.stderr.write(f"resume_checks: {problem}\n")
        return 3
    base = Path(tempfile.mkdtemp(prefix="resume-checks-"))
    wrong = []

    def one(indexed):
        index, seq = indexed
        seq_base = base / f"{index}-{seq['name']}"
        seq_base.mkdir()
        return run_sequence(model, seq, seq_base)

    try:
        # Each sequence has its own repo, and nearly all the time is spent
        # waiting on probe subprocesses, so threads cut the run to about the
        # length of the longest sequence. map keeps the output in model order.
        with ThreadPoolExecutor() as pool:
            for lines in pool.map(one, enumerate(model["sequences"])):
                wrong += lines
    except ModelError as e:
        for problem in e.problems:
            sys.stderr.write(f"resume_checks: replay: {problem}\n")
        return 3
    finally:
        shutil.rmtree(base, ignore_errors=True)
    for line in wrong:
        print(line)
    rows = covered_rows(model)
    print("rows covered: " + " ".join(str(r) for r in rows))
    # A model that stops naming a row can no longer fail when that row breaks.
    missing = [r for r in ROWS if r not in rows]
    if missing:
        print("rows missing: " + " ".join(str(r) for r in missing))
    return 1 if wrong or missing else 0


# The `invariants` and `liveness` subcommands. Both run `phase_of` in-process
# on probes they enumerate, so they need no git and no subprocess.

ATOM_OPS = ("==", "!=", "in", "<", "<=", ">", ">=")
STEPS = tuple(str(n) for n in range(9))
# A full run is under 20 transitions, and two review rounds add about 6, so a
# path still going at 40 has no end the model can see.
PATH_CAP = 40
# Null is an answer for these two (no pull request yet), so they keep it in
# their domains, and the null sweep never nulls them.
NULLABLE = ("pr_state", "review_state")
# The fields the null sweep enumerates: the two above, and the one row 1
# reads ahead of the generic null check.
NULL_SWEEP_FREE = NULLABLE + ("queue_unfiled_rows",)
# Enough only while `phase_of` compares counts with 0 and with each other,
# which `bound_check` enforces.
COUNT_DOMAIN = (0, 1, 2)


def load_run_state():
    """Import `run-state.py` from beside this script, so a scratch copy's
    mutated script is the one checked."""
    import importlib.util
    spec = importlib.util.spec_from_file_location("run_state_under_check", RUN_STATE)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def domains_of(run_state):
    domains = {}
    for name, kind, allowed in run_state.PROBE_FIELDS:
        values = (False, True) if kind == "bool" else COUNT_DOMAIN if kind == "int" else tuple(allowed)
        domains[name] = ((None,) + values) if name in NULLABLE else values
    return domains


def check_atoms(atoms, where, domains, problems):
    if not isinstance(atoms, list):
        problems.append(f"{where}: expected a list of atoms")
        return
    for i, atom in enumerate(atoms):
        at = f"{where}[{i}]"
        if not (isinstance(atom, list) and len(atom) == 3):
            problems.append(f"{at}: an atom is [lhs, op, rhs]")
            continue
        lhs, op, rhs = atom
        if lhs != "phase" and lhs not in domains:
            problems.append(f"{at}: {lhs!r} is neither phase nor a probe field")
            continue
        if op not in ATOM_OPS:
            problems.append(f"{at}: op {op!r} is not one of {', '.join(ATOM_OPS)}")
            continue
        allowed = PHASES if lhs == "phase" else domains[lhs] + (None,)
        if isinstance(rhs, dict):
            if set(rhs) != {"field"} or rhs["field"] not in domains or op == "in":
                problems.append(f"{at}: rhs {rhs!r} must be {{\"field\": <probe field>}}, never with in")
            continue
        values = rhs if op == "in" else [rhs]
        if op == "in" and not isinstance(rhs, list):
            problems.append(f"{at}: in needs a list")
            continue
        # A typo such as "OPENED" never matches, and an invariant that can't
        # match passes every probe.
        for value in values:
            if isinstance(value, (list, dict)) or not any(
                value == a and type(value) is type(a) for a in allowed
            ):
                problems.append(f"{at}: {value!r} is not a value {lhs} can take")
        if op in ("<", "<=", ">", ">=") and not all(type(v) is int for v in values):
            problems.append(f"{at}: {op} needs an integer")


def check_rules(rules, key, domains, problems):
    if not isinstance(rules, list):
        problems.append(f"{key}: expected a list")
        return
    names = set()
    for i, rule in enumerate(rules):
        where = f"{key}[{i}]"
        if not isinstance(rule, dict):
            problems.append(f"{where}: expected an object")
            continue
        name = rule.get("name")
        if not isinstance(name, str) or not name.strip() or name in names:
            problems.append(f"{where}: name must be a unique non-empty string")
        names.add(name)
        where = f"{key} {name}"
        # A rule with no cite is one nobody read from the prose, which is the
        # failure this field exists to rule out.
        if not isinstance(rule.get("cite"), str) or not rule["cite"].strip():
            problems.append(f"{where}: cite must name the prose it was read from")
        check_atoms(rule.get("if"), f"{where}.if", domains, problems)
        if not rule.get("then"):
            problems.append(f"{where}: then must be a non-empty list of atoms")
        check_atoms(rule.get("then", []), f"{where}.then", domains, problems)


def check_effects(effects, domains, problems):
    if not isinstance(effects, list):
        problems.append("effects: expected a list")
        return
    seen = set()
    for i, effect in enumerate(effects):
        where = f"effects[{i}]"
        if not isinstance(effect, dict):
            problems.append(f"{where}: expected an object")
            continue
        step = effect.get("step")
        if isinstance(step, bool) or step not in range(9) or step in seen:
            problems.append(f"{where}: step {step!r} is not a unique 0-8")
        seen.add(step)
        where = f"effects step {step}"
        if not isinstance(effect.get("cite"), str) or not effect["cite"].strip():
            problems.append(f"{where}: cite must name the Done-when line it was read from")
        done_when = effect.get("done_when")
        if not isinstance(done_when, list) or not all(isinstance(p, str) and p for p in done_when):
            problems.append(f"{where}: done_when must be a list of RUN_DIR paths")
        outcomes = effect.get("outcomes")
        if not isinstance(outcomes, list) or not outcomes:
            problems.append(f"{where}: outcomes must be a non-empty list")
            continue
        # With every outcome guarded, a state matching no guard would end a
        # path as if the step had finished.
        if not any(isinstance(o, dict) and "if" not in o for o in outcomes):
            problems.append(f"{where}: needs at least one outcome with no if")
        for j, outcome in enumerate(outcomes):
            at = f"{where} outcomes[{j}]"
            if not isinstance(outcome, dict) or not isinstance(outcome.get("name"), str) or not outcome["name"].strip():
                problems.append(f"{at}: expected an object with a name")
                continue
            check_atoms(outcome.get("if", []), f"{at}.if", domains, problems)
            if "terminal" in outcome:
                if outcome["terminal"] != "stop" or set(outcome) - {"name", "terminal", "if"}:
                    problems.append(f"{at}: a terminal outcome is {{\"name\", \"terminal\": \"stop\"}} and an optional if")
                continue
            if set(outcome) - {"name", "set", "add", "if"}:
                problems.append(f"{at}: keys are name, set, add, and if")
            for field, value in (outcome.get("set") or {}).items():
                if field not in domains or not any(value == a and type(value) is type(a) for a in domains[field]):
                    problems.append(f"{at}: set {field} to {value!r}, which it can't take")
            for field, value in (outcome.get("add") or {}).items():
                if field not in domains or domains[field] != COUNT_DOMAIN or type(value) is not int:
                    problems.append(f"{at}: add needs a count field and an integer, got {field} {value!r}")
    missing = [n for n in range(9) if n not in seen]
    if missing:
        problems.append("effects: no effect for step " + ", ".join(str(n) for n in missing))


def load_logic_model(path, domains):
    """The model's `invariants`, `assumptions`, and `effects`, or ModelError."""
    try:
        with open(path, encoding="utf-8") as handle:
            model = json.load(handle)
    except FileNotFoundError:
        raise ModelError([f"--model {path}: no such file"])
    except (OSError, UnicodeDecodeError, ValueError) as e:
        raise ModelError([f"--model {path}: {e}"])
    if not isinstance(model, dict):
        raise ModelError([f"model: expected a JSON object, got {type(model).__name__}"])
    problems = []
    if not model.get("invariants"):
        problems.append("invariants: expected a non-empty list")
    check_rules(model.get("invariants", []), "invariants", domains, problems)
    check_rules(model.get("assumptions", []), "assumptions", domains, problems)
    # An assumption that reads the answer prunes a probe by what phase_of
    # says about it, so it could hide the very hole the check is after.
    for rule in model.get("assumptions", []) if isinstance(model.get("assumptions"), list) else []:
        if isinstance(rule, dict) and any(
            isinstance(a, list) and a[:1] == ["phase"] for a in (rule.get("if") or []) + (rule.get("then") or [])
        ):
            problems.append(f"assumptions {rule.get('name')}: an assumption may not read phase")
    check_effects(model.get("effects"), domains, problems)
    if problems:
        raise ModelError(problems)
    return model


def bound_check():
    """Problems with the count bound: each `Compare` in `phase_of` with an
    integer literal other than 0 on either side.

    Counts run 0-2 because `phase_of` compares a count only with 0 and with
    another count, and 0-2 realizes every ordering of each pair alongside the
    zero test. A literal 3 needs a 3 and a 4 to test both sides of it."""
    import ast
    tree = ast.parse(RUN_STATE.read_text(encoding="utf-8"))
    func = next(
        (n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name == "phase_of"), None
    )
    if func is None:
        return [f"{RUN_STATE.name}: no phase_of"]
    problems = []
    for node in ast.walk(func):
        if not isinstance(node, ast.Compare):
            continue
        for side in [node.left] + node.comparators:
            while isinstance(side, ast.UnaryOp):
                side = side.operand
            if isinstance(side, ast.Constant) and type(side.value) is int and side.value != 0:
                problems.append(
                    f"{RUN_STATE.name} line {node.lineno}: phase_of compares with literal "
                    f"{side.value}, past what counts of 0-2 can test"
                )
    return problems


class Chooser:
    """One leaf of a stateless depth-first search over choice sequences.

    Replays `prefix`, takes the first option past it, and keeps the trail so
    `next_prefix` can step to the next untried choice."""

    def __init__(self, prefix):
        self.prefix = prefix
        self.trail = []

    def pick(self, options):
        i = self.prefix[len(self.trail)] if len(self.trail) < len(self.prefix) else 0
        self.trail.append((i, len(options)))
        return options[i]

    def next_prefix(self):
        trail = list(self.trail)
        while trail and trail[-1][0] + 1 >= trail[-1][1]:
            trail.pop()
        if not trail:
            return None
        last, _ = trail.pop()
        return [i for i, _ in trail] + [last + 1]


def search(run):
    """Call `run(chooser)` once per leaf of the choice tree it walks."""
    prefix = []
    while prefix is not None:
        chooser = Chooser(prefix)
        run(chooser)
        prefix = chooser.next_prefix()


def same(a, b):
    # Strict, so true never matches 1 and a typo'd type never matches at all.
    return a is b or (type(a) is type(b) and a == b)


class Store:
    """What one path knows about the probe. A field nothing has tested is
    absent and may hold any value in its domain. A tested field sits in a
    component, a tuple of fields with the set of value rows still possible,
    and fields compared with each other share one."""

    def __init__(self, domains, comps=None):
        self.domains = domains
        self.comps = dict(comps or {})

    def copy(self):
        return Store(self.domains, self.comps)

    def comp(self, field):
        found = self.comps.get(field)
        if found is None:
            return (field,), frozenset((v,) for v in self.domains[field])
        return found

    def cut(self, fields, test):
        """The component joining `fields`, cut to the rows where `test` holds."""
        names, yes, _ = self.partition(fields, test)
        return names, yes

    def partition(self, fields, test):
        """The component joining `fields`, as (names, rows where `test`
        holds, rows where it doesn't)."""
        comps = []
        for f in fields:
            c = self.comp(f)
            if c not in comps:
                comps.append(c)
        names = tuple(n for c in comps for n in c[0])
        rows = comps[0][1]
        for c in comps[1:]:
            rows = [r + t for r in rows for t in c[1]]
        at = [names.index(f) for f in fields]
        yes = []
        no = []
        for r in rows:
            (yes if test(*(r[i] for i in at)) else no).append(r)
        return names, frozenset(yes), frozenset(no)

    def keep(self, comp):
        for part in split(comp):
            for f in part[0]:
                self.comps[f] = part

    def values(self, field):
        names, rows = self.comp(field)
        i = names.index(field)
        return sorted({r[i] for r in rows}, key=lambda v: order(self.domains[field], v))

    def set(self, field, value):
        names, rows = self.comp(field)
        if len(names) > 1:
            i = names.index(field)
            rest = (names[:i] + names[i + 1:], frozenset(r[:i] + r[i + 1:] for r in rows))
            self.keep(rest)
        self.comps[field] = ((field,), frozenset({(value,)}))

    def add(self, field, n):
        names, rows = self.comp(field)
        i = names.index(field)
        self.keep((names, frozenset(r[:i] + (r[i] + n,) + r[i + 1:] for r in rows)))

    def key(self):
        return frozenset(
            c for c in set(self.comps.values())
            if not (len(c[0]) == 1 and c[1] == frozenset((v,) for v in self.domains[c[0][0]]))
        )


MERGE_ROWS = 4096


def union(a, b):
    """One Store holding exactly the probes of `a` and of `b`, or None where
    the component that would take would pass MERGE_ROWS rows.

    The fields where the two differ are joined into one component on each
    side, and the rows of the two joined components are pooled."""
    differ = {f for f in set(a.comps) | set(b.comps) if a.comp(f) != b.comp(f)}
    if not differ:
        return a
    close = set()
    while differ:
        f = differ.pop()
        close.add(f)
        differ |= {g for st in (a, b) for g in st.comp(f)[0]} - close
    names = tuple(sorted(close))
    for st in (a, b):
        size = 1
        for comp in {st.comp(f) for f in names}:
            size *= len(comp[1])
        if size > MERGE_ROWS:
            return None
    pooled = set()
    for st in (a, b):
        joined, rows = st.cut(names, lambda *v: True)
        at = [joined.index(f) for f in names]
        pooled |= {tuple(r[i] for i in at) for r in rows}
    if len(pooled) > MERGE_ROWS:
        return None
    out = a.copy()
    out.keep((names, frozenset(pooled)))
    return out


def split(comp):
    """`comp` as independent components: a field whose rows are every
    pairing of its values with the rest's goes off alone. Two paths that
    know the same thing then hold the same Store, which liveness relies on
    to see a state twice."""
    names, rows = comp
    parts = []
    while len(names) > 1:
        for i in range(len(names)):
            mine = {r[i] for r in rows}
            rest = {r[:i] + r[i + 1:] for r in rows}
            if len(mine) * len(rest) == len(rows):
                parts.append(((names[i],), frozenset((v,) for v in mine)))
                names, rows = names[:i] + names[i + 1:], frozenset(rest)
                break
        else:
            break
    return parts + [(names, frozenset(rows))]


def order(domain, value):
    for i, v in enumerate(domain):
        if same(v, value):
            return i
    if value is None:
        return -1
    # A count `add` pushed past the domain sorts after it, in numeric order.
    return len(domain) + value


class SearchPath:
    """One run of `phase_of` or of the model's atoms over a Store, where each
    test whose answer the store doesn't settle becomes a choice."""

    def __init__(self, store, chooser):
        self.store = store
        self.chooser = chooser

    def decide(self, fields, test):
        names, yes, no = self.store.partition(fields, test)
        # A test the store already settles is no choice, and leaves the
        # store as it was.
        if not no:
            return True
        if not yes:
            return False
        answer = self.chooser.pick((True, False))
        self.store.keep((names, yes if answer else no))
        return answer

    def concrete(self, field):
        value = self.chooser.pick(self.store.values(field))
        self.store.keep(self.store.cut((field,), lambda v: same(v, value)))
        return value

    def atom(self, atom, phase):
        lhs, op, rhs = atom
        test = ATOM_TESTS[op]
        if lhs == "phase":
            return test(phase, rhs)
        if isinstance(rhs, dict):
            return self.decide((lhs, rhs["field"]), test)
        return self.decide((lhs,), lambda v: test(v, rhs))


def _lt(a, b):
    return a is not None and b is not None and a < b


ATOM_TESTS = {
    "==": same,
    "!=": lambda a, b: not same(a, b),
    "in": lambda a, b: any(same(a, x) for x in b),
    "<": _lt,
    "<=": lambda a, b: same(a, b) or _lt(a, b),
    ">": lambda a, b: _lt(b, a),
    ">=": lambda a, b: same(a, b) or _lt(b, a),
}


class Sym:
    """A probe field `phase_of` has read but not yet tested. Each comparison
    or truth test asks the SearchPath, so the field is narrowed only as far
    as the code looks."""

    __slots__ = ("path", "field")

    def __init__(self, path, field):
        self.path = path
        self.field = field

    def _test(self, other, op):
        if isinstance(other, Sym):
            return self.path.decide((self.field, other.field), op)
        return self.path.decide((self.field,), lambda v: op(v, other))

    def __eq__(self, other):
        return self._test(other, lambda a, b: a == b)

    def __ne__(self, other):
        return self._test(other, lambda a, b: a != b)

    def __lt__(self, other):
        return self._test(other, lambda a, b: a < b)

    def __le__(self, other):
        return self._test(other, lambda a, b: a <= b)

    def __gt__(self, other):
        return self._test(other, lambda a, b: a > b)

    def __ge__(self, other):
        return self._test(other, lambda a, b: a >= b)

    def __bool__(self):
        return self.path.decide((self.field,), bool)

    __hash__ = None

    # Reason text only: the checker reads nothing from it but the row prefix.
    def __str__(self):
        return f"<{self.field}>"

    __format__ = lambda self, spec: str(self)


class SymProbe:
    """The probe `phase_of` sees on a SearchPath. A field that may be null is
    pinned to one value at its first read, because `is None` can't be asked
    of a stand-in. Every other field is a Sym: in the non-null space no such
    field is None, so `is None` on a Sym answers right."""

    def __init__(self, path):
        self.path = path

    def __getitem__(self, name):
        if any(v is None for v in self.path.store.domains[name]):
            return self.path.concrete(name)
        return Sym(self.path, name)


INLINE_NODES = (
    "Name", "Constant", "Subscript", "Compare", "BoolOp", "UnaryOp", "Call", "Tuple", "Load",
    "And", "Or", "Not", "Gt", "GtE", "Lt", "LtE", "Eq", "NotEq", "In", "NotIn", "Is", "IsNot",
)


def lazy_phase_of(run_state):
    """`phase_of` with each single-assignment local whose value is a pure
    probe read inlined at its uses, compiled into a copy of run-state's
    globals with `count` and `null_fields` swapped for the search.

    `phase_of` computes `branch_anywhere`, `redteam_clean`, and the rest up
    front, so every field they read is tested on every path, and the search
    ran past 20 million leaves. Inlined, a field is tested only where a row
    looks at it. The answers are the same, since a pure read gives the same
    value wherever it runs, and `check_inlined` holds the copy to that."""
    import ast
    tree = ast.parse(RUN_STATE.read_text(encoding="utf-8"))
    func = next(n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name == "phase_of")
    stores = {}
    values = {}
    for node in ast.walk(func):
        if isinstance(node, ast.Name) and isinstance(node.ctx, (ast.Store, ast.Del)):
            stores[node.id] = stores.get(node.id, 0) + 1
        if isinstance(node, ast.Assign) and len(node.targets) == 1 and isinstance(node.targets[0], ast.Name):
            values[node.targets[0].id] = node.value
    allowed = tuple(getattr(ast, n) for n in INLINE_NODES)

    def pure(expr, inlinable):
        for x in ast.walk(expr):
            if not isinstance(x, allowed):
                return False
            if isinstance(x, ast.Call) and not (isinstance(x.func, ast.Name) and x.func.id in ("flag", "count")):
                return False
            if isinstance(x, ast.Name) and x.id not in ("probe", "flag", "count") and x.id not in inlinable:
                return False
        return True

    inlinable = {name for name in values if stores.get(name) == 1}
    while True:
        kept = {name for name in inlinable if pure(values[name], inlinable)}
        if kept == inlinable:
            break
        inlinable = kept

    class Inline(ast.NodeTransformer):
        def visit_Name(self, node):
            if isinstance(node.ctx, ast.Load) and node.id in inlinable:
                return self.visit(ast.parse(ast.unparse(values[node.id]), mode="eval").body)
            return node

        def visit_Assign(self, node):
            if len(node.targets) == 1 and isinstance(node.targets[0], ast.Name) and node.targets[0].id in inlinable:
                return ast.copy_location(ast.Pass(), node)
            self.generic_visit(node)
            return node

    func = ast.fix_missing_locations(Inline().visit(func))
    namespace = dict(vars(run_state))
    exec(compile(ast.Module(body=[func], type_ignores=[]), str(RUN_STATE), "exec"), namespace)
    return namespace


def check_inlined(run_state, namespace, domains):
    """Problems where the inlined copy answers differently from `phase_of`,
    over a fixed sample of full non-null probes."""
    import random
    rng = random.Random(148)
    fields = [name for name, _, _ in run_state.PROBE_FIELDS]
    for _ in range(3000):
        probe = {name: rng.choice([v for v in domains[name] if v is not None or name in NULLABLE]) for name in fields}
        if run_state.phase_of(probe) != namespace["phase_of"](probe):
            return [f"inlined phase_of disagrees with phase_of on {shown(probe)}"]
    return []


def label(answer):
    phase, reason = answer
    row = ROW_REASON.match(reason)
    return f"{phase} row {row.group(1) if row else 'none'}"


def shown(bound):
    return json.dumps(bound, sort_keys=True)


def narrow(store, rules, fields, phase):
    """Each field's values the store allows, cut by propagation until no
    rule or component rules out another value; None once a field runs dry.

    A test that fails only with every field assigned would otherwise be
    found by trying each value of every field ahead of it."""
    dom = {f: store.values(f) for f in fields}

    def can(atom, want, fixed=None):
        lhs, op, rhs = atom
        test = ATOM_TESTS[op]
        if lhs == "phase":
            return test(phase, rhs) == want
        lefts = [fixed[1]] if fixed and fixed[0] == lhs else dom[lhs]
        if isinstance(rhs, dict):
            g = rhs["field"]
            rights = [fixed[1]] if fixed and fixed[0] == g else dom[g]
            return any(test(x, y) == want for x in lefts for y in rights)
        return any(test(x, rhs) == want for x in lefts)

    def fields_of(atom):
        return [x for x in (atom[0], atom[2]["field"] if isinstance(atom[2], dict) else None) if x not in (None, "phase")]

    def supported(rule, fixed):
        if any(can(a, False, fixed) for a in rule["if"]):
            return True
        return all(can(a, True, fixed) for a in rule["then"])

    comps = set(store.comps.values())
    changed = True
    while changed:
        changed = False
        for rule in rules:
            for f in {x for a in rule["if"] + rule["then"] for x in fields_of(a)}:
                kept = [v for v in dom[f] if supported(rule, (f, v))]
                if len(kept) != len(dom[f]):
                    dom[f] = kept
                    changed = True
                    if not kept:
                        return None
        for names, rows in comps:
            live = [r for r in rows if all(any(same(r[j], v) for v in dom[n]) for j, n in enumerate(names))]
            for j, n in enumerate(names):
                kept = [v for v in dom[n] if any(same(r[j], v) for r in live)]
                if len(kept) != len(dom[n]):
                    dom[n] = kept
                    changed = True
                    if not kept:
                        return None
    return dom


def holds(rule, probe):
    """Whether `rule` holds on a full probe. Assumptions never read phase."""
    def atom(a):
        lhs, op, rhs = a
        return ATOM_TESTS[op](probe[lhs], probe[rhs["field"]] if isinstance(rhs, dict) else rhs)
    return not all(atom(a) for a in rule["if"]) or all(atom(a) for a in rule["then"])


def first_probe(store, rules, fields, phase=None):
    """The first full probe, in field order and each field's domain order,
    that the store allows and every rule holds on; None where there is none.

    Doubles as the satisfiability test the assumptions prune with, and,
    since it's the first in a fixed order, it names the same probe however
    the search reached the store."""
    dom = narrow(store, rules, fields, phase)
    if dom is None:
        return None
    index = {f: i for i, f in enumerate(fields)}
    checks = []
    for rule in rules:
        atoms = rule["if"] + rule["then"]
        named = {a[0] for a in atoms if a[0] != "phase"} | {a[2]["field"] for a in atoms if isinstance(a[2], dict)}
        checks.append((named, ("rule", rule)))
    for comp in set(store.comps.values()):
        checks.append((set(comp[0]), ("comp", comp)))
    # A rule is tried at each of its fields, since one then-atom can fail
    # long before the rule's last field is assigned. A component waits for
    # its last field.
    at = {}
    for named, check in checks:
        if check[0] == "rule":
            for i in {index[f] for f in named} or {-1}:
                at.setdefault(i, []).append(check)
        else:
            at.setdefault(max(index[f] for f in named), []).append(check)
    # The assigned fields that some check still waiting on a later field reads.
    frontier = [
        tuple(sorted(
            {f for named, _ in checks if any(index[g] >= i for g in named) for f in named if index[f] < i},
            key=index.get,
        ))
        for i in range(len(fields) + 1)
    ]
    probe = {}

    def ok(check):
        kind, what = check
        if kind == "comp":
            names, rows = what
            return any(all(same(r[j], probe[n]) for j, n in enumerate(names)) for r in rows)

        def atom(a):
            """True, False, or None while a field it reads is unassigned."""
            lhs, op, rhs = a
            if lhs != "phase" and lhs not in probe:
                return None
            if isinstance(rhs, dict) and rhs["field"] not in probe:
                return None
            left = phase if lhs == "phase" else probe[lhs]
            return ATOM_TESTS[op](left, probe[rhs["field"]] if isinstance(rhs, dict) else rhs)
        return not (
            all(atom(a) is True for a in what["if"]) and any(atom(a) is False for a in what["then"])
        )

    failed = set()

    def walk(i):
        if i == len(fields):
            return True
        key = (i, tuple(probe[f] for f in frontier[i]))
        if key in failed:
            return False
        for value in dom[fields[i]]:
            probe[fields[i]] = value
            if all(ok(c) for c in at.get(i, ())) and walk(i + 1):
                return True
        del probe[fields[i]]
        failed.add(key)
        return False

    if not all(ok(c) for c in at.get(-1, ())):
        return None
    return dict(probe) if walk(0) else None


def read_set(run_state, probe):
    """The fields the real `phase_of` reads on a full probe, with the generic
    null check stubbed out since it reads every field."""

    class Reads(dict):
        def __getitem__(self, name):
            seen.add(name)
            return dict.__getitem__(self, name)

    seen = set()
    real = run_state.null_fields
    run_state.null_fields = lambda probe: []
    try:
        run_state.phase_of(Reads(probe))
    finally:
        run_state.null_fields = real
    return seen


def logic_setup(args):
    """The imported run-state module, its field domains, the model, and the
    inlined `phase_of` namespace, or None after reporting an exit 3."""
    try:
        run_state = load_run_state()
    except Exception as e:
        sys.stderr.write(f"resume_checks: {RUN_STATE}: {type(e).__name__}: {e}\n")
        return None
    domains = domains_of(run_state)
    try:
        model = load_logic_model(args.model, domains)
    except ModelError as e:
        for problem in e.problems:
            sys.stderr.write(f"resume_checks: {problem}\n")
        return None
    problems = bound_check()
    if not problems:
        namespace = lazy_phase_of(run_state)
        # In the non-null space `count` is `int` of a non-null value, so it
        # can hand back the Sym and let the comparison decide.
        namespace["count"] = lambda probe, name: probe[name]
        namespace["null_fields"] = lambda probe: []
        problems = check_inlined(run_state, namespace, domains)
    for problem in problems:
        sys.stderr.write(f"resume_checks: {problem}\n")
    return None if problems else (run_state, domains, model, namespace)


def non_null(domains):
    return {
        name: values if name in NULLABLE else tuple(v for v in values if v is not None)
        for name, values in domains.items()
    }


def cmd_invariants(args):
    setup = logic_setup(args)
    if setup is None:
        return 3
    run_state, domains, model, namespace = setup
    fields = [name for name, _, _ in run_state.PROBE_FIELDS]
    assumptions = model.get("assumptions", [])
    found = {}
    # Counted by answer: the search paths depend on the order phase_of tests
    # its fields, and a reordering that changes no answer must print the
    # same line.
    reached = set()
    live = set()

    def report(name, answer, probe, atoms):
        reads = read_set(run_state, probe) | {
            f for a in atoms for f in ([a[0]] + ([a[2]["field"]] if isinstance(a[2], dict) else []))
            if f != "phase"
        }
        rank = tuple(order(domains[f], probe[f]) for f in fields)
        key = f"{name}: {label(answer)}"
        if key not in found or rank < found[key][0]:
            found[key] = (rank, shown({f: probe[f] for f in reads}))

    def one(chooser):
        path = SearchPath(Store(non_null(domains)), chooser)
        answer = namespace["phase_of"](SymProbe(path))
        reached.add(answer)
        if first_probe(path.store, assumptions, fields, answer[0]) is None:
            return
        live.add(answer)
        for rule in model["invariants"]:
            for broken in rule["then"]:
                store = path.store.copy()
                ok = True
                for atom, want in [(a, True) for a in rule["if"]] + [(broken, False)]:
                    lhs, op, rhs = atom
                    if lhs == "phase":
                        ok = ATOM_TESTS[op](answer[0], rhs) == want
                    else:
                        fs = (lhs, rhs["field"]) if isinstance(rhs, dict) else (lhs,)
                        test = ATOM_TESTS[op]
                        comp = store.cut(fs, (lambda a, b, t=test, w=want: t(a, b) == w) if len(fs) == 2
                                         else (lambda v, t=test, r=rhs, w=want: t(v, r) == w))
                        ok = bool(comp[1])
                        store.keep(comp)
                    if not ok:
                        break
                if not ok:
                    continue
                probe = first_probe(store, assumptions, fields, answer[0])
                if probe is not None:
                    report(rule["name"], answer, probe, rule["if"] + rule["then"])

    search(one)

    # Once any field but the exempt three is null, phase_of stops before
    # reading another field's value, so the rest can sit at one value each.
    first = {name: values[0] for name, values in non_null(domains).items()}
    for name in fields:
        if name in NULLABLE:
            continue

        def nulled(chooser, name=name):
            probe = dict(first, **{name: None})
            for free in NULL_SWEEP_FREE:
                if free != name:
                    probe[free] = chooser.pick(domains[free])
            answer = run_state.phase_of(probe)
            reached.add(answer)
            live.add(answer)
            if answer[0] in STEPS:
                report("null", answer, probe, [])

        search(nulled)

    for key in sorted(found):
        sys.stderr.write(f"{key} on {found[key][1]}\n")
    print(f"probes: {len(reached)} leaves, {len(reached - live)} pruned")
    return 1 if found else 0


def cmd_liveness(args):
    setup = logic_setup(args)
    if setup is None:
        return 3
    run_state, domains, model, namespace = setup
    fields = [name for name, _, _ in run_state.PROBE_FIELDS]
    effects = {str(e["step"]): e["outcomes"] for e in model["effects"]}
    assumptions = model.get("assumptions", [])
    sys.setrecursionlimit(max(sys.getrecursionlimit(), 20 * PATH_CAP))
    possible_child = {}

    def expand(store):
        """Every way one resume can go from `store`, as (label, resolved
        store, child store or None for an end), then each outcome whose child
        holds no probe the assumptions allow, as (label, outcome name,
        resolved store). Leaves of phase_of that end on the same label and
        outcome are pooled into as few child Stores as `union` allows.

        Unpooled, every start probe's path stays its own Store and the graph
        runs past 100,000 nodes. Pooling hides no loop: a pooled Store that
        comes back to itself is a set each probe of which comes back into
        it, and a probe whose own path runs past PATH_CAP takes its Store
        past PATH_CAP with it."""
        moves = []

        possible = {}
        impossible = []

        def one(chooser):
            path = SearchPath(store.copy(), chooser)
            answer = namespace["phase_of"](SymProbe(path))
            seen = (path.store.key(), answer[0])
            if seen not in possible:
                possible[seen] = first_probe(path.store, assumptions, fields, answer[0])
            witness = possible[seen]
            if witness is None:
                return
            if answer[0] not in STEPS:
                moves.append((label(answer), path.store, None, None))
                return
            outcome = chooser.pick(effects[answer[0]])
            if not all(path.atom(a, answer[0]) for a in outcome.get("if", [])):
                return
            # A guard can narrow the leaf to probes the assumptions rule out.
            # No real run takes that outcome, so its child says nothing about
            # the effect.
            if outcome.get("if"):
                seen = (path.store.key(), answer[0])
                if seen not in possible:
                    possible[seen] = first_probe(path.store, assumptions, fields, answer[0])
                witness = possible[seen]
                if witness is None:
                    return
            if "terminal" in outcome:
                moves.append((label(answer), path.store, None, None))
                return
            child = path.store.copy()
            for field, n in (outcome.get("add") or {}).items():
                child.add(field, n)
            for field, value in (outcome.get("set") or {}).items():
                child.set(field, value)
            # A child with no probe the assumptions allow is an effect writing
            # a state no real run reaches, so liveness reports it. Pruning it
            # would drop every path behind it with nothing said: a Step 1 that
            # also wrote base_sha false looped 1 -> 1 and passed that way.
            # A child with some allowed probe is narrowed leaf by leaf once expanded.
            # The parent's allowed probe, carried through the effect, is a
            # probe of the child, so a child it satisfies needs no search.
            carried = dict(witness, **(outcome.get("set") or {}))
            for field, n in (outcome.get("add") or {}).items():
                carried[field] = witness[field] + n
            if child.key() not in possible_child:
                possible_child[child.key()] = all(holds(rule, carried) for rule in assumptions) \
                    or first_probe(child, assumptions, fields) is not None
            if not possible_child[child.key()]:
                impossible.append((label(answer), outcome["name"], path.store))
                return
            moves.append((label(answer), path.store, child, outcome["name"]))

        search(one)
        pooled = {}
        for move in moves:
            if move[2] is None:
                key = (move[0], None)
                if key not in pooled:
                    pooled[key] = [move]
                continue
            group = pooled.setdefault((move[0], move[3]), [])
            # Only the newest Store of a group takes a merge, which keeps
            # pooling linear in the leaves rather than quadratic.
            merged = union(group[-1][2], move[2]) if group else None
            if merged is not None:
                group[-1] = group[-1][:2] + (merged,) + group[-1][3:]
            else:
                group.append(move)
        return [m[:3] for key in sorted(pooled, key=str) for m in pooled[key]], impossible

    gray = {}
    done = {}
    # Each (answer, next answer) a resume can take, "end" for a stop, a
    # wait, or done. Pooling decides how many search paths there are, so the
    # count printed is of these, which pooling can't change.
    steps = set()
    found = {}
    stack = []

    def report(kind, labels, start):
        probe = first_probe(start, assumptions, fields)
        rank = tuple(order(domains[f], probe[f]) for f in fields)
        line = f"{kind}: " + " -> ".join(labels)
        if line not in found or rank < found[line][0]:
            found[line] = (rank, shown({f: probe[f] for f in read_set(run_state, probe)}))

    def visit(store, depth):
        """The most transitions any path from `store` takes to an end."""
        key = store.key()
        if key in done:
            height, firsts = done[key]
            steps.update((stack[-1][0] if stack else "start", f) for f in firsts)
            if depth + height > PATH_CAP:
                report("unbounded", [l for l, _ in stack] + ["..."], stack[0][1])
            return height
        gray[key] = len(stack)
        height = 0
        moves, impossible = expand(store)
        for here, outcome, resolved in impossible:
            report("impossible", [here, outcome], resolved)
        steps.update((stack[-1][0] if stack else "start", m[0]) for m in moves)
        for here, resolved, child in moves:
            stack.append((here, resolved))
            if child is None:
                steps.add((here, "end"))
            elif child.key() in gray:
                entry = gray[child.key()]
                report("cycle", [l for l, _ in stack[entry:]] + [stack[entry][0]], stack[entry][1])
            elif depth + 1 > PATH_CAP:
                report("unbounded", [l for l, _ in stack], stack[0][1])
            else:
                height = max(height, visit(child, depth + 1) + 1)
            stack.pop()
        del gray[key]
        done[key] = (height, {m[0] for m in moves})
        return height

    visit(Store(non_null(domains)), 0)
    for line in sorted(found):
        sys.stderr.write(f"{line} on {found[line][1]}\n")
    print(f"paths: {len(steps)}")
    return 1 if found else 0


def parse_args(argv):
    ap = argparse.ArgumentParser(description="End-to-end checks of work-issue's resume table.")
    sub = ap.add_subparsers(dest="command", required=True)
    c = sub.add_parser("crash-points", help="replay every write-sequence prefix through probe and phase")
    c.add_argument("--model", metavar="MODEL", required=True, help="write-order.json")
    c.set_defaults(func=cmd_crash_points)
    i = sub.add_parser("invariants", help="check the model's invariants over every probe phase_of can tell apart")
    i.add_argument("--model", metavar="MODEL", required=True, help="write-order.json")
    i.set_defaults(func=cmd_invariants)
    v = sub.add_parser("liveness", help="check every path through the step effects reaches a stop, a wait, or done")
    v.add_argument("--model", metavar="MODEL", required=True, help="write-order.json")
    v.set_defaults(func=cmd_liveness)
    return ap.parse_args(argv)


def main(argv=None):
    argv = sys.argv[1:] if argv is None else list(argv)
    try:
        args = parse_args(argv)
    except SystemExit as e:
        # The validator convention's 3 for usage, in place of argparse's 2.
        return 3 if e.code == 2 else e.code
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
