#!/usr/bin/env python3
"""Run work-wave's merge test (references/merge-test.md) in one call.

    merge-test.py --wave-dir WAVE_DIR --root ROOT --default DEFAULT
                  --merge-tree MERGE_TREE --install INSTALL_CMD --verify VERIFY_CMD
                  [--lane issue-N ...] [--baseline]

Prints the path of the record it wrote. Exit 0 on `result: green`, 1 on `red`
or `conflict` with the record written, 3 on usage or a git failure before any
merge, with nothing written under merge-test/. A git failure once merging has
started writes a red record with a `git failed:` line and exits 1. Argparse's
own 2 covers a mistyped flag.

The script is the procedure and nothing else. Reading a red result against
coupling.md, writing facts/wave.md and deciding to stop stay with the conductor.
"""
import argparse
import os
import re
import shutil
import signal
import subprocess
import sys
from pathlib import Path

# A suite's useful failure is at the end. 200 lines holds a pytest or bash
# summary plus the failing cases; the full log is never the record's job.
TAIL_LINES = 200

LANE = re.compile(r"issue-[1-9][0-9]*")


class Usage(Exception):
    pass


class GitFailure(Exception):
    pass


def git(root, *args, check=True):
    p = subprocess.run(["git", "-C", str(root), *args], capture_output=True, text=True)
    if check and p.returncode != 0:
        raise GitFailure(f"git {' '.join(args)}: {(p.stderr or p.stdout).strip()}")
    return p


def lines_of(p):
    return [s for s in p.stdout.split("\n") if s]


def run_cmd(cmd, cwd):
    """Run a resolved shell command in the merge tree, folding stderr into stdout."""
    p = subprocess.run(cmd, shell=True, cwd=cwd, stdout=subprocess.PIPE,
                       stderr=subprocess.STDOUT, text=True, errors="replace")
    return p.returncode, p.stdout.split("\n")


def next_k(wave_dir):
    ks = [int(m.group(1)) for f in (wave_dir / "merge-test").glob("*.md")
          if (m := re.fullmatch(r"([0-9]+)\.md", f.name))]
    return max(ks, default=0) + 1


def write_atomic(path, text):
    # The probe reads a file's existence as "this step finished", so a half
    # write must never be visible under the final name.
    tmp = path.with_name(f".{path.name}.tmp")
    tmp.write_text(text)
    os.replace(tmp, path)


def conflict_line(args, tree, base, shas, lane, merged):
    """Name every already-merged branch whose own diff against base touches a
    conflicted path (ledger row 35), or DEFAULT when none does. Never the
    branch merged just before by position. Diffs the captured SHAs: a lane
    still running can move its branch after build() recorded it."""
    conflicted = lines_of(git(tree, "diff", "--name-only", "--diff-filter=U"))
    culprits = []
    for other in merged:
        theirs = set(lines_of(git(args.root, "diff", "--name-only", f"{base}...{shas[other]}")))
        if theirs & set(conflicted):
            culprits.append(other)
    return f"conflict: {lane} with {', '.join(culprits) or 'DEFAULT'} — {', '.join(conflicted)}"


def build(args, state):
    """Raises Usage or GitFailure before any merge, for a bad lane, fetch, or
    worktree add. main() turns either into exit 3."""
    root, tree = args.root, args.merge_tree
    shas = {}
    for lane in args.lane:
        p = git(root, "rev-parse", "--verify", f"refs/heads/{lane}", check=False)
        if p.returncode != 0:
            raise Usage(f"{lane}: no such branch in {root}")
        shas[lane] = p.stdout.strip()

    if os.path.lexists(tree):
        git(root, "worktree", "remove", "--force", str(tree), check=False)
        git(root, "worktree", "prune", check=False)
        if os.path.lexists(tree):
            raise Usage(f"{tree} exists and is not a worktree of {root}; remove it by hand")
    git(root, "fetch", "origin", args.default)
    # Set before the add: teardown on a tree that never appeared is harmless,
    # and one skipped over a half-made tree is the leak the finally exists for.
    state["created"] = True
    git(root, "worktree", "add", "--detach", str(tree), f"origin/{args.default}")
    base = git(tree, "rev-parse", "HEAD").stdout.strip()
    base_line = f"base: origin/{args.default} {base}"
    return tree, base, base_line, shas


def run(args, state):
    tree, base, base_line, shas = build(args, state)
    head = [base_line]
    try:
        return merge_and_verify(args, tree, base, base_line, shas, head)
    except GitFailure as e:
        # Merging has started, so exit 3 would pass for a usage error and leave
        # no record. A red record naming the failed command is one the probe reads.
        head.append(f"git failed: {e}")
        return head, "red", 1, [], base_line


def merge_and_verify(args, tree, base, base_line, shas, head):
    merged = []
    for lane in args.lane:
        head.append(f"{lane} {shas[lane]}")
        p = git(tree, "merge", "--no-ff", "--no-edit", shas[lane], check=False)
        if p.returncode == 0:
            merged.append(lane)
            continue
        if git(tree, "diff", "--name-only", "--diff-filter=U").stdout.strip():
            head.append(conflict_line(args, tree, base, shas, lane, merged))
            kind, note = "conflict", ""
        else:
            # A merge that failed with nothing unmerged (a hook, an identity
            # error) is not a conflict, and calling it one would send the
            # conductor hunting for overlapping paths.
            head.append(f"merge failed: {lane}")
            kind, note = "red", (p.stderr or p.stdout).strip()
        git(tree, "merge", "--abort", check=False)
        return head, kind, None, note.split("\n") if note else [], base_line

    status, tail = 0, []
    if args.install != "absent":
        status, tail = run_cmd(args.install, tree)
    if status == 0 and args.verify != "absent":
        status, tail = run_cmd(args.verify, tree)
    result = "green" if status == 0 else "red"

    # Checked after the suite, with diff for tracked files and ls-files for
    # non-ignored new ones, never `git status` (#109, merge-test.md step 5).
    stat = git(tree, "diff", "--stat", "HEAD").stdout.strip()
    others = lines_of(git(tree, "ls-files", "--others", "--exclude-standard"))
    if stat:
        names = lines_of(git(tree, "diff", "--name-only", "HEAD"))
        head.append(f"dirty after verify: tracked changes — {', '.join(names)}")
        result = "red"
    if others:
        head.append(f"dirty after verify: untracked — {', '.join(others)}")
        result = "red"
    if result == "red" and status == 0:
        # reuse-baseline copies baseline.txt's exit: line into each lane unread,
        # and divvy-up takes green or red from it, so a dirty tree must exit 1.
        status = 1
    return head, result, status, tail, base_line


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--wave-dir", required=True, type=Path)
    ap.add_argument("--root", required=True, type=Path)
    ap.add_argument("--default", required=True)
    ap.add_argument("--merge-tree", required=True, type=Path)
    ap.add_argument("--install", required=True)
    ap.add_argument("--verify", required=True)
    ap.add_argument("--lane", action="append", default=[])
    ap.add_argument("--baseline", action="store_true")
    args = ap.parse_args(argv)

    try:
        if args.baseline and args.lane:
            raise Usage("--baseline takes no --lane")
        for lane in args.lane:
            if not LANE.fullmatch(lane):
                raise Usage(f"--lane {lane}: expected issue-<N>")
        if len(set(args.lane)) != len(args.lane):
            raise Usage("--lane repeats a branch")
        if not args.wave_dir.is_dir():
            raise Usage(f"--wave-dir {args.wave_dir}: not a directory")
        if not (args.root / ".git").exists():
            raise Usage(f"--root {args.root}: not a git checkout")
    except Usage as e:
        sys.stderr.write(f"merge-test: {e}\n")
        return 3

    # SIGTERM becomes SystemExit so the finally below still tears down. SIGKILL
    # can't be trapped, and VERIFY_CMD's own children outlive either signal.
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(143))
    state = {"created": False}
    try:
        try:
            head, result, status, tail, base_line = run(args, state)
        except (Usage, GitFailure) as e:
            sys.stderr.write(f"merge-test: {e}\n")
            return 3
        tail = tail[-TAIL_LINES:]
        k = 0 if args.baseline else next_k(args.wave_dir)
        record_dir = args.wave_dir / "merge-test"
        record_dir.mkdir(exist_ok=True)
        record = record_dir / f"{k}.md"
        body = "\n".join(head + [f"result: {result}"] + tail).rstrip("\n") + "\n"
        if args.baseline:
            header = [f"exit: {status}", base_line, f"install: {args.install}", f"verify: {args.verify}"]
            write_atomic(args.wave_dir / "baseline.txt", "\n".join(header + tail).rstrip("\n") + "\n")
        write_atomic(record, body)
        print(record)
        return 0 if result == "green" else 1
    finally:
        if state["created"]:
            git(args.root, "worktree", "remove", "--force", str(args.merge_tree), check=False)
            git(args.root, "worktree", "prune", check=False)
            if args.merge_tree.exists():
                shutil.rmtree(args.merge_tree, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
