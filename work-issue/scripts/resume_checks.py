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


def parse_args(argv):
    ap = argparse.ArgumentParser(description="End-to-end checks of work-issue's resume table.")
    sub = ap.add_subparsers(dest="command", required=True)
    c = sub.add_parser("crash-points", help="replay every write-sequence prefix through probe and phase")
    c.add_argument("--model", metavar="MODEL", required=True, help="write-order.json")
    c.set_defaults(func=cmd_crash_points)
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
