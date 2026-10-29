#!/usr/bin/env python3
"""Relaunch a confirmed work-issue run as fresh headless agents until a launch
ends on a stop that needs a person.

    work-issue/scripts/drive.py N [PLAN] [--isolate | --no-isolate] [--deep]
        [--max-review-rounds R] [--no-publish] [--detach] [--max-launches K]
        [--max-review-waits W] [--agent-cmd CMD]

work-issue resumes from disk, but nothing outside the session starts the next
invocation, so a dead session or Step 6's no-review stop leaves the run idle.
Each launch here is `work-issue N ...` handed to --agent-cmd (default
`claude -p`). How a launch ended is read against SKILL.md's Where a Run Stops
table at run time, never against a copy held here: a copy drifts from the
table the suite pins.

Exit codes follow the validator convention: 0 the run reached `done`; 1 a
halt, with one `drive: halted: <reason>` line on stderr; 3 a usage error, a
cwd outside a git repo, an agent command that isn't found, or a stops table
that can't be read.

Stdlib only, so the skill stays copy-in portable.
"""
import argparse
import os
import re
import shlex
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
RUN_STATE = HERE / "run-state.py"
# Found relative to this file, so a scratch copy of work-issue/ reads its own
# SKILL.md. The smoke test's reads-the-table case depends on that.
SKILL_MD = HERE.parent / "SKILL.md"
TABLE_HEADER = "| Stop | Step | What the run prints or writes |"
GRANT_ENV = "WORK_ISSUE_DRIVE_GRANT"
TAIL_LINES = 40


class _Parser(argparse.ArgumentParser):
    def error(self, message):
        # argparse defaults to 2; issue #187 fixes usage errors at 3.
        self.print_usage(sys.stderr)
        sys.stderr.write(f"{self.prog}: error: {message}\n")
        sys.exit(3)


class _Pass(argparse.Action):
    """Record a work-issue flag in the order the user gave it."""

    def __call__(self, parser, ns, values, option_string=None):
        ns.passthrough.append(option_string)
        if self.nargs != 0:
            ns.passthrough.append(values)


def positive(text):
    if not re.fullmatch(r"[1-9][0-9]*", text):
        raise argparse.ArgumentTypeError(f"not a positive integer: {text!r}")
    return int(text)


def nonnegative(text):
    if not re.fullmatch(r"[0-9]+", text):
        raise argparse.ArgumentTypeError(f"not a non-negative integer: {text!r}")
    return int(text)


def parse_args(argv):
    if "--dry-run" in argv:
        sys.stderr.write("drive: --dry-run is the driver's own grant step\n")
        sys.exit(3)
    # allow_abbrev off: a typo'd prefix like --dry would otherwise resolve to
    # some other flag instead of failing.
    ap = _Parser(prog="drive.py", allow_abbrev=False)
    ap.set_defaults(passthrough=[])
    ap.add_argument("n", metavar="N", type=positive, help="the issue number")
    ap.add_argument("plan", metavar="PLAN", nargs="?", help="the plan path, passed to work-issue")
    iso = ap.add_mutually_exclusive_group()
    iso.add_argument("--isolate", nargs=0, action=_Pass)
    iso.add_argument("--no-isolate", nargs=0, action=_Pass)
    ap.add_argument("--deep", nargs=0, action=_Pass)
    ap.add_argument("--max-review-rounds", metavar="R", type=positive, action=_Pass)
    ap.add_argument("--no-publish", nargs=0, action=_Pass)
    ap.add_argument("--detach", action="store_true")
    ap.add_argument("--max-launches", metavar="K", type=positive, default=20)
    ap.add_argument("--max-review-waits", metavar="W", type=nonnegative, default=6)
    ap.add_argument("--agent-cmd", metavar="CMD", default="claude -p")
    args = ap.parse_intermixed_args(argv)
    args.passthrough = [str(v) for v in args.passthrough]
    return args


def usage_exit(message):
    sys.stderr.write(f"drive: {message}\n")
    sys.exit(3)


def halt(reason):
    sys.stderr.write(f"drive: halted: {reason}\n")
    sys.exit(1)


def say(line):
    # Flushed per line so `tail -f` on a detached log shows each launch as it ends.
    print(line, flush=True)


def git(*args, cwd=None):
    r = subprocess.run(["git", *args], cwd=cwd, capture_output=True, text=True)
    return r.returncode, r.stdout.strip()


def normalize(text):
    return re.sub(r"\s+", " ", text.replace("`", "")).strip()


def message_pattern(msg, n):
    """Compile one quoted message, or return None when it has no literal text.
    `N` becomes the issue number, backticks drop, and each `<placeholder>`
    matches any text."""
    # The whole message is matched. Matching up to the first placeholder, as
    # the issue proposed, keeps the rebase-conflict message's literal `N`,
    # which no launch prints, and cuts the budget line to `build: `.
    text = normalize(re.sub(r"\bN\b", str(n), msg))
    pieces = re.split(r"<[^<>]+>", text)
    if not any(p.strip() for p in pieces):
        return None
    return re.compile(".+?".join(re.escape(p) for p in pieces))


def read_table(n):
    """Return (stops, no_review, done): every row with quoted text as
    (stop cell, [patterns]), plus the two rows the driver keys by Stop cell.

    The cut matches the suite's drift-check awk: the lines after the header,
    minus the separator, up to the first line not starting with `|`."""
    where = f"cannot read Where a Run Stops from {SKILL_MD}"
    try:
        lines = SKILL_MD.read_text(encoding="utf-8").splitlines()
    except OSError as e:
        usage_exit(f"{where}: {e.strerror or e}")
    try:
        start = lines.index(TABLE_HEADER) + 1
    except ValueError:
        usage_exit(f"{where}: no `{TABLE_HEADER}` header")
    rows = []
    for line in lines[start:]:
        if not line.startswith("|"):
            break
        if re.fullmatch(r"\|(\s*:?-+:?\s*\|)+", line.strip()):
            continue
        cells = line.split("|")
        if len(cells) < 4:
            continue
        stop, cell = cells[1].strip(), cells[3].strip()
        pats = [p for p in (message_pattern(m, n) for m in re.findall(r'"([^"]*)"', cell)) if p]
        rows.append((stop, pats))
    no_review = next((r for r in rows if r[0].startswith("No review")), None)
    done = next((r for r in rows if r[0].startswith("The final report")), None)
    # A renamed or unquoted special row fails here, at startup, rather than
    # silently turning a wait into a halt or a finish into a relaunch.
    for name, row in (("No review", no_review), ("The final report", done)):
        if row is None:
            usage_exit(f"{where}: no row whose Stop starts `{name}`")
        if not row[1]:
            usage_exit(f"{where}: the `{name}` row has no quoted message")
    stops = [r for r in rows if r[1] and r is not no_review and r is not done]
    return stops, no_review, done


def tail_text(log):
    """Return the log's last TAIL_LINES lines, normalized like the messages."""
    # SKILL.md makes each stop's message the invocation's last output, and a
    # verbose --agent-cmd prints its transcript above it.
    try:
        text = Path(log).read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""
    return normalize(" ".join(text.splitlines()[-TAIL_LINES:]))


def first_match(row, text):
    for pat in row[1]:
        m = pat.search(text)
        if m:
            return m.group(0)
    return None


def gather(ctx):
    """Run references/resume.md's gather from ROOT and return (phase line,
    error). error is None when probe and phase both exit 0."""
    # A failed gh or review drops --pr-bundle and nothing else. This probe
    # feeds only the done check and the fingerprint, and every launch gathers
    # its own.
    n, root = ctx["n"], ctx["root"]
    bundle = None
    try:
        r = subprocess.run(
            ["gh", "pr", "list", "--head", f"issue-{n}", "--state", "all",
             "--json", "number", "--jq", ".[0].number"],
            cwd=root, capture_output=True, text=True, stdin=subprocess.DEVNULL)
        pr = r.stdout.strip() if r.returncode == 0 else ""
    except OSError:
        pr = ""
    tmps = []
    try:
        if pr:
            fd, bundle = tempfile.mkstemp(prefix="drive-bundle-")
            os.close(fd)
            tmps.append(bundle)
            r = subprocess.run([sys.executable, str(RUN_STATE), "review", pr, "--save", bundle],
                               cwd=root, capture_output=True, text=True, stdin=subprocess.DEVNULL)
            if r.returncode != 0:
                bundle = None
        # Always passed: the driver waits for each launch to exit, so no agent
        # it started is still working, and under HERDR_ENV=1 an omitted flag
        # makes probe exit 3.
        cmd = [sys.executable, str(RUN_STATE), "probe", "--run-dir", str(ctx["run_dir"]),
               "--root", root, "--issue", str(n), "--herdr-state", "absent"]
        if bundle:
            cmd += ["--pr-bundle", bundle]
        r = subprocess.run(cmd, cwd=root, capture_output=True, text=True, stdin=subprocess.DEVNULL)
        if r.returncode == 0:
            fd, probe = tempfile.mkstemp(prefix="drive-probe-")
            with os.fdopen(fd, "w") as f:
                f.write(r.stdout)
            tmps.append(probe)
            r = subprocess.run([sys.executable, str(RUN_STATE), "phase", "--probe", probe],
                               cwd=root, capture_output=True, text=True, stdin=subprocess.DEVNULL)
        if r.returncode != 0:
            err = r.stderr.strip()
            last = err.splitlines()[-1] if err else ""
            return f"probe exit {r.returncode}: {last}", err or f"exit {r.returncode}"
        return r.stdout.strip(), None
    finally:
        for t in tmps:
            try:
                os.unlink(t)
            except OSError:
                pass


def fingerprint(ctx, phase):
    rc, head = git("-C", ctx["root"], "rev-parse", "--verify", "-q", f"refs/heads/issue-{ctx['n']}")
    files = []
    run_dir = ctx["run_dir"]
    for dirpath, dirnames, filenames in os.walk(run_dir):
        here = Path(dirpath)
        if here == run_dir:
            # drive/ is this script's own output. timing.log grows on every
            # resume (`<n> start`) and every stop (`<n> end`), so counting it
            # would keep the fingerprint moving and the no-progress halt could
            # never fire. Every other artifact a step writes still counts.
            dirnames[:] = [d for d in dirnames if d != "drive"]
            filenames = [f for f in filenames if f != "timing.log"]
        for f in filenames:
            p = here / f
            try:
                files.append((str(p.relative_to(run_dir)), p.stat().st_size))
            except OSError:
                pass
    return (phase, head if rc == 0 and head else "absent", tuple(sorted(files)))


def keep_log(ctx, tmp, name=None):
    """Move a launch's temp log to RUN_DIR/drive/ and return its path. Where
    RUN_DIR doesn't exist, the log stays at its temp path."""
    # Creating RUN_DIR here would make row 5 read a fresh issue as a dead run
    # and archive it to closed/.
    run_dir = ctx["run_dir"]
    if not run_dir.is_dir():
        return tmp
    drive = run_dir / "drive"
    drive.mkdir(exist_ok=True)
    if name is None:
        # Continue from the highest existing index, so a restarted driver
        # never overwrites an earlier driver's log.
        seen = [int(m.group(1)) for p in drive.iterdir()
                if (m := re.fullmatch(r"launch-([0-9]+)\.log", p.name))]
        name = f"launch-{max(seen, default=0) + 1}.log"
    dest = drive / name
    shutil.move(tmp, dest)
    return str(dest)


def launch(ctx, prompt, name=None):
    fd, tmp = tempfile.mkstemp(prefix=f"drive-issue-{ctx['n']}-", suffix=".log")
    env = dict(os.environ)
    env.pop(GRANT_ENV, None)
    with os.fdopen(fd, "w") as out:
        # stdin closed: a headless agent left reading stdin blocks forever.
        rc = subprocess.run(ctx["agent"] + [prompt], stdin=subprocess.DEVNULL,
                            stdout=out, stderr=subprocess.STDOUT, env=env).returncode
    return rc, keep_log(ctx, tmp, name)


def first_line(ctx, extra=()):
    words = [f"work-issue {ctx['n']}"]
    if ctx["plan"]:
        words.append(shlex.quote(ctx["plan"]))
    words += [shlex.quote(w) for w in ctx["passthrough"]]
    words += list(extra)
    return " ".join(words)


def ask_grant(ctx, stops, no_review, done):
    """Put Step 0's confirmation to the user on this terminal and return the
    grant brief. Halts on a no, or when the dry run ends on a stop."""
    # The brief stays in memory and never reaches disk, so no later driver and
    # no hand-typed `work-issue N` inherits a yes it never got.
    rc, log = launch(ctx, first_line(ctx, ["--dry-run"]), name="dry-run.log")
    try:
        sys.stdout.write(Path(log).read_text(encoding="utf-8", errors="replace"))
    except OSError:
        pass
    text = tail_text(log)
    for row in [done, no_review, *stops]:
        hit = first_match(row, text)
        if hit:
            halt(f"{row[0]}: {hit}")
    sys.stdout.write("Go? [y/N] ")
    sys.stdout.flush()
    answer = sys.stdin.readline().strip()
    if answer.lower() not in ("y", "yes"):
        halt("the confirmation was answered no")
    dry = Path(log).read_text(encoding="utf-8", errors="replace").rstrip("\n")
    # Mirrors {{GRANT}} in work-wave/references/lane-brief.md.
    return ("work-issue's Step 0 confirmation has been put to the user by "
            "work-issue/scripts/drive.py and answered. Do not ask it again. "
            "The confirmation, as the dry run rendered it:\n\n"
            f"{dry}\n\nThe answer, verbatim: {answer}")


def detach(ctx, argv, brief):
    child = [sys.executable, str(Path(__file__).resolve())] + [a for a in argv if a != "--detach"]
    env = dict(os.environ)
    if brief:
        env[GRANT_ENV] = brief
    n = ctx["n"]
    if shutil.which("tmux"):
        session = f"work-issue-{n}"
        cmd = ["tmux", "new-session", "-d", "-s", session, "-c", os.getcwd()]
        if brief:
            cmd += ["-e", f"{GRANT_ENV}={brief}"]
        r = subprocess.run(cmd + ["--"] + child, capture_output=True, text=True, env=env)
        if r.returncode != 0:
            halt(f"tmux: {r.stderr.strip() or f'exit {r.returncode}'}")
        say(f"watch: tmux attach -t {session}")
        say(f"stop: tmux kill-session -t {session}")
        return
    # Named outside the issue-* pattern, so check-inflight.py and Step 1's
    # in-flight probe, which list directories only, both skip it.
    log = ctx["common"] / "work-issue" / f"drive-issue-{n}.log"
    log.parent.mkdir(parents=True, exist_ok=True)
    with open(log, "a") as out:
        p = subprocess.Popen(["nohup"] + child, stdin=subprocess.DEVNULL, stdout=out,
                             stderr=subprocess.STDOUT, env=env, start_new_session=True)
    say(f"watch: tail -f {log}")
    # The negative pgid stops the agent launch along with the driver.
    say(f"stop: kill -TERM -{p.pid}")


def main(argv):
    args = parse_args(argv)
    # Read and dropped at once, so no agent launch inherits the grant.
    brief = os.environ.pop(GRANT_ENV, None)
    rc, root = git("rev-parse", "--show-toplevel")
    rc2, common = git("rev-parse", "--git-common-dir")
    if rc or rc2 or not root:
        usage_exit("not inside a git repository")
    common = Path(common)
    if not common.is_absolute():
        common = Path.cwd() / common
    common = common.resolve()
    try:
        agent = shlex.split(args.agent_cmd)
    except ValueError as e:
        usage_exit(f"--agent-cmd: {e}")
    if not agent or not shutil.which(agent[0]):
        usage_exit(f"agent command not found: {agent[0] if agent else '(empty)'}")
    n = args.n
    ctx = {"n": n, "root": root, "common": common, "agent": agent,
           "run_dir": common / "work-issue" / f"issue-{n}",
           "plan": args.plan, "passthrough": args.passthrough}
    stops, no_review, done = read_table(n)

    phase, err = gather(ctx)
    if err:
        # The first launch would stop on this same gather.
        halt(err.replace("\n", " | "))
    if brief is None and phase.split()[:2] == ["phase:", "0"]:
        brief = ask_grant(ctx, stops, no_review, done)
    if args.detach:
        detach(ctx, argv, brief)
        return 0

    prompt = first_line(ctx)
    if brief:
        prompt += "\n\n" + brief
    prints = [fingerprint(ctx, phase)]
    logs = []
    waits = 0
    k = 0
    while True:
        if k >= args.max_launches:
            halt(f"launch cap {args.max_launches} reached")
        k += 1
        rc, log = launch(ctx, prompt)
        logs.append(log)
        phase, _ = gather(ctx)
        prints.append(fingerprint(ctx, phase))
        text = tail_text(log)

        # The exit status is printed and never decides how a launch ended.
        hit = first_match(done, text)
        if phase.startswith("phase: done") or hit:
            say(f"launch {k}: exit {rc}, done, log {log}")
            say(f"drive: done after {k} launches")
            return 0
        for row in stops:
            hit = first_match(row, text)
            if hit:
                say(f"launch {k}: exit {rc}, stop, log {log}")
                halt(f"{row[0]}: {hit}")
        hit = first_match(no_review, text)
        if hit:
            say(f"launch {k}: exit {rc}, no review, log {log}")
            waits += 1
            # Exempt from the no-progress halt: waiting on a reviewer writes
            # nothing, and W is this stop's own bound.
            if waits > args.max_review_waits:
                halt(f"no review after {args.max_review_waits} relaunches: {hit}")
            continue
        waits = 0
        say(f"launch {k}: exit {rc}, no stop matched, log {log}")
        if k >= 2 and prints[-1] == prints[-2] == prints[-3]:
            halt(f"no progress in {logs[-2]} and {logs[-1]}")


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
