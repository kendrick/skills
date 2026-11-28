#!/usr/bin/env python3
"""Step 3's collision check: which unheld lanes already have a tree at their
own WORKTREE path, so the wave can refuse before dispatching any of them.

    work-wave/scripts/check-worktrees.py --root ROOT \\
        --lane issue-N=WORKTREE [--lane issue-M=WORKTREE ...] \\
        [--started issue-N ...]

A lane is a hit when its WORKTREE exists as a directory or appears in
`git worktree list --porcelain`, prunable entries included. Both sides are
compared after os.path.realpath. WORKTREE is spelled `<ROOT>/../<PROJECT>-
issue-N/`, with a `..` and a trailing slash, while porcelain prints a
resolved absolute path, so a string comparison never matched and refused
every already-started lane.

A --started lane (Step 0 item 4) is exempt when the tree at its WORKTREE
holds its own `issue-N`, checked out or mid-rebase. A rebase stopped on a
conflict detaches HEAD, so that tree's porcelain entry carries no branch
line, and the exemption as first written ("registered on its own issue-N
branch") refused the wave over a lane's own tree (#391). find_tree already
answers the question for work-issue's resume probe, rebase fallback included,
so this script calls it rather than parsing the porcelain a second way. The
only porcelain read here is the hit test's list of registered paths, which
find_tree can't give: it answers where one branch lives, and says nothing
about a prunable entry or a tree on some other branch.

A lane whose WORKTREE is ROOT is never exempt, since find_tree answers ROOT
for a branch that exists nowhere locally. A branch that is local and checked
out in no worktree, or in a different tree than the lane's WORKTREE, is a
hit too.

Output: one `collision: issue-N <resolved path>` line per hit on stderr, in
ascending issue order, so one run names every hit as Step 3 requires. A pass
prints `OK: <n> lanes, <k> exempt` on stdout, where <k> counts the --started
lanes whose own tree was found and exempted, not every --started lane: one whose
WORKTREE is gone has nothing to exempt.

Exit codes: 0 pass; 1 one or more collisions; 3 usage or unreadable input,
which covers no lanes, a malformed --lane or --started, a lane named twice, a
--started lane with no matching --lane (a lane the wave forgot to pass is a
conductor mistake, and ignoring it would hide that), and a failed `git
worktree list`. A missing --root or a mistyped flag exits 3 as well, since
argparse's own exit 2 would sit outside the contract Step 3 branches on.

Stdlib only, so the skill stays copy-in portable.
"""
import argparse
import os
import re
import subprocess
import sys
from pathlib import Path

# ---------------------------------------------------------------------------
# Vendored verbatim from work-issue/scripts/run-state.py at f14fb72, 2026-11-22:
# GIT_TIMEOUT, run_git, git_failure, read_text, chomp, rebasing_branch, and
# find_tree, the last with the helpers it calls.
# Upstream is authoritative: fix it there, then re-copy.
# The docstrings and comments travel with the code on purpose, since they
# record the incidents (#147, PR #177) that set each rule.
# Copy with sed, never through a transcript. This skill installs standalone, so
# importing from a sibling skill is not an option, and
# tests/work-wave-smoke.sh compares each function against upstream by name.
# ---------------------------------------------------------------------------

GIT_TIMEOUT = 60

# end vendored


# Vendored verbatim from work-issue/scripts/run-state.py: run_git, git_failure.
def run_git(tree, *args):
    # No prompt: a credential helper waiting on a terminal would hang the
    # probe past its timeout instead of answering null.
    env = dict(os.environ, GIT_TERMINAL_PROMPT="0")
    return subprocess.run(
        ["git", "-C", str(tree), *args],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="surrogateescape",
        timeout=GIT_TIMEOUT,
        env=env,
    )


def git_failure(args, done):
    why = " ".join((done.stderr or "").split())[:200]
    return f"git {' '.join(args)}: exit {done.returncode}" + (f": {why}" if why else "")

# end vendored


# Vendored verbatim from work-issue/scripts/run-state.py: read_text.
def read_text(path):
    with open(path, encoding="utf-8", errors="surrogateescape") as handle:
        return handle.read()

# end vendored


# Vendored verbatim from work-issue/scripts/run-state.py: chomp.
def chomp(text):
    """What `$(cat FILE)` gives: trailing newlines gone, nothing else."""
    return text.rstrip("\n")

# end vendored


# Vendored verbatim from work-issue/scripts/run-state.py: rebasing_branch,
# find_tree.
def rebasing_branch(tree):
    """The ref a rebase in `tree` is rewriting, else None. A tree git cannot
    read, or one with no rebase, answers None, which leaves `find_tree` to
    report the branch as checked out nowhere."""
    for name in ("rebase-merge", "rebase-apply"):
        done = run_git(tree, "rev-parse", "--git-path", f"{name}/head-name")
        if done.returncode != 0:
            return None
        where = Path(chomp(done.stdout))
        if not where.is_absolute():
            where = Path(tree) / where
        try:
            return chomp(read_text(where))
        except OSError:
            continue
    return None


def find_tree(root, branch, terminal=False):
    """`(tree, problem)`: the worktree holding `branch`, else ROOT where no
    local `branch` exists, since rows 1 and 4 through 7 own those runs.
    `terminal` (a MERGED or CLOSED bundle) takes ROOT for a `branch` in no
    worktree too: row 1 answers from `pr_state` alone, and a merge usually
    leaves ROOT back on main with the branch still local.

    A local `branch` that no worktree has checked out is a problem, not
    ROOT: ROOT's HEAD is another branch, and reading its status and log
    counted a committed, reported task as unreported, so row 7 re-dispatched
    it (PR #177 review). A second flag naming TREE would be one more value an
    agent could pass wrong on a resume."""
    done = run_git(root, "worktree", "list", "--porcelain")
    if done.returncode != 0:
        return None, git_failure(("worktree", "list"), done)
    current = None
    detached = []
    for line in done.stdout.split("\n"):
        if line.startswith("worktree "):
            current = line[len("worktree "):]
        elif line == f"branch refs/heads/{branch}" and current:
            return Path(current), None
        elif line == "detached" and current:
            detached.append(current)
    # A rebase stopped on a conflict detaches HEAD, so the porcelain list names
    # no branch for that tree, and row 12's rebase leg was unreachable behind
    # this function's exit 3 (#147). git records the branch being rebased in
    # head-name under the tree's own git dir.
    for tree in detached:
        if rebasing_branch(tree) == f"refs/heads/{branch}":
            return Path(tree), None
    local = run_git(root, "show-ref", "--verify", "--quiet", f"refs/heads/{branch}")
    if local.returncode == 0 and not terminal:
        return None, (
            f"{branch} exists locally but is not checked out in any worktree, so "
            f"no tree shows its work; check it out (or git worktree add a tree "
            f"for it) and re-run"
        )
    if local.returncode not in (0, 1):
        return None, git_failure(("show-ref",), local)
    return root, None


# ---------------------------------------------------------------------------
# end vendored
# ---------------------------------------------------------------------------

LANE_NAME = re.compile(r"^issue-([0-9]+)$")


def usage_error(message):
    print(f"check-worktrees: {message}", file=sys.stderr)
    sys.exit(3)


def parse_lanes(specs):
    """{N: WORKTREE} for each `issue-N=WORKTREE` spec."""
    lanes = {}
    for spec in specs:
        name, sep, path = spec.partition("=")
        match = LANE_NAME.match(name)
        if not sep or not path or not match:
            usage_error(f"--lane {spec!r} is not issue-N=WORKTREE")
        number = int(match.group(1))
        if number in lanes:
            usage_error(f"{name} is named by more than one --lane")
        lanes[number] = path
    return lanes


def registered_paths(root):
    done = run_git(root, "worktree", "list", "--porcelain")
    if done.returncode != 0:
        usage_error(git_failure(("worktree", "list", "--porcelain"), done))
    return {
        os.path.realpath(line[len("worktree "):])
        for line in done.stdout.split("\n")
        if line.startswith("worktree ")
    }


def holds_own_branch(root, name, worktree):
    tree, problem = find_tree(root, name)
    return problem is None and os.path.realpath(tree) == worktree and worktree != os.path.realpath(root)


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.error = usage_error
    parser.add_argument("--root", required=True)
    parser.add_argument("--lane", action="append", default=[])
    parser.add_argument("--started", action="append", default=[])
    args = parser.parse_args()

    lanes = parse_lanes(args.lane)
    if not lanes:
        usage_error("no --lane given")
    started = set()
    for name in args.started:
        match = LANE_NAME.match(name)
        if not match:
            usage_error(f"--started {name!r} is not issue-N")
        if int(match.group(1)) not in lanes:
            usage_error(f"--started {name} has no --lane")
        started.add(int(match.group(1)))

    try:
        registered = registered_paths(args.root)
        hits = []
        exempt = 0
        for number in sorted(lanes):
            name = f"issue-{number}"
            worktree = os.path.realpath(lanes[number])
            if not (os.path.isdir(worktree) or worktree in registered):
                continue
            if number in started and holds_own_branch(args.root, name, worktree):
                exempt += 1
                continue
            hits.append(f"collision: {name} {worktree}")
    except (OSError, subprocess.TimeoutExpired) as e:
        usage_error(f"git did not run: {e}")

    if hits:
        print("\n".join(hits), file=sys.stderr)
        return 1
    count = len(lanes)
    print(f"OK: {count} lane{'' if count == 1 else 's'}, {exempt} exempt")
    return 0


if __name__ == "__main__":
    sys.exit(main())
