#!/usr/bin/env python3
"""Snapshot, back up, prove, restore, and check one mutation against the user's tree.

    mutation-guard.py snapshot --out FILE [--guard PATH]...
    mutation-guard.py backup   --dir D PATH...
    mutation-guard.py prove    --dir D PATH...
    mutation-guard.py restore  --dir D PATH...
    mutation-guard.py check    --dir D --snapshot FILE PATH...

Each subcommand runs one fixed comparison and offers no alternative, because
three times an alternative offered beside a check was weaker and became the
route a run took (ledger row 21). Nothing compares against HEAD or the index:
the tree carries the user's uncommitted guard, which git cannot tell from the
run's own mutation (rows 16, 18, 20).

  snapshot  writes `git status --porcelain -uall` to FILE verbatim and prints
            DIFF's working-tree paths (`git diff`, `git diff --cached`,
            `git ls-files --others --exclude-standard`) to stdout, one per
            line, relative to the caller's cwd so they feed `backup`. An
            ignored --guard exits 1 before FILE is written (row 28).
  backup    copies each PATH to D/<repo-relative path>, mode kept. Refuses,
            copying nothing, a PATH that is not a regular file (rows 30, 35)
            or a D inside the repository (row 12).
  prove     exits 1 for a PATH whose bytes match its backup (row 20).
  restore   unlinks each PATH, copies its backup back, and sets the backup's
            mode, since a copy onto an existing file keeps the destination's
            mode (row 22).
  check     exits 1 for a PATH that differs from its backup in bytes or mode,
            and for any difference between current status and FILE (rows 16,
            18, 26). Reports every problem, not only the first.

Exit 0 pass, 1 semantic failure with one stderr line per problem, 3 usage
error or unreadable input.
"""

import argparse
import os
import shutil
import stat
import subprocess
import sys

PROG = "mutation-guard"


class UsageError(Exception):
    pass


class Parser(argparse.ArgumentParser):
    # argparse exits 2 on a usage error; the validator convention says 3.
    def error(self, message):
        self.print_usage(sys.stderr)
        sys.stderr.write(f"{PROG}: {message}\n")
        sys.exit(3)


def git(top, *args):
    proc = subprocess.run(["git", *args], cwd=top, capture_output=True)
    if proc.returncode != 0:
        raise UsageError(f"git {' '.join(args)} failed: {proc.stderr.decode(errors='replace').strip()}")
    return proc.stdout


def toplevel():
    proc = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True)
    if proc.returncode != 0:
        raise UsageError("not inside a git repository")
    # realpath on both sides, so macOS's /var -> /private/var cannot make an
    # inside --dir read as outside, or the reverse.
    return os.path.realpath(proc.stdout.strip())


def inside(path, top):
    real = os.path.realpath(path)
    return real == top or real.startswith(top + os.sep)


def repo_relative(path, top):
    """Return PATH relative to the repo root without following PATH itself:
    resolving a link here would back up the target under the link's name."""
    absolute = os.path.abspath(path)
    parent = os.path.realpath(os.path.dirname(absolute))
    rel = os.path.relpath(os.path.join(parent, os.path.basename(absolute)), top)
    if rel == "." or rel == ".." or rel.startswith(".." + os.sep):
        return None
    return rel


def backups(paths, d, top):
    """Pair each PATH with its backup, or raise if any backup is unreadable.
    Checked up front so a restore never stops halfway through the paths."""
    pairs = []
    for path in paths:
        rel = repo_relative(path, top)
        if rel is None:
            raise UsageError(f"{path}: outside the repository")
        bak = os.path.join(d, rel)
        try:
            st = os.lstat(bak)
        except OSError:
            raise UsageError(f"{path}: no backup at {bak}")
        if not stat.S_ISREG(st.st_mode):
            raise UsageError(f"{path}: backup at {bak} is not a regular file")
        pairs.append((path, bak, st))
    return pairs


def read_bytes(path):
    with open(path, "rb") as fh:
        return fh.read()


def cmd_snapshot(args, top):
    problems = []
    for guard in args.guard:
        rel = repo_relative(guard, top)
        if rel is None:
            raise UsageError(f"{guard}: outside the repository")
        # check-ignore exits 0 for ignored, 1 for not ignored, 128 on error.
        proc = subprocess.run(["git", "check-ignore", "-q", "--", rel], cwd=top)
        if proc.returncode == 0:
            problems.append(f"{guard}: ignored by git, so the snapshot cannot see a restore of it")
        elif proc.returncode != 1:
            raise UsageError(f"git check-ignore failed on {guard}")
    if problems:
        return problems
    status = git(top, "status", "--porcelain", "-uall")
    # -z keeps core.quotePath from turning a non-ASCII name into a quoted
    # escape that `backup` would then report as missing.
    raw = (
        git(top, "diff", "--name-only", "-z")
        + git(top, "diff", "--cached", "--name-only", "-z")
        + git(top, "ls-files", "--others", "--exclude-standard", "-z")
    )
    paths = dict.fromkeys(os.fsdecode(name) for name in raw.split(b"\0") if name)
    with open(args.out, "wb") as fh:
        fh.write(status)
    # git names paths from the repo root; every other subcommand reads PATH
    # from the caller's cwd, so print them that way or a run from a subdir
    # backs up a missing file, or the wrong one.
    cwd = os.path.realpath(os.getcwd())
    for path in paths:
        print(os.path.relpath(os.path.join(top, path), cwd))
    return []


def cmd_backup(args, top):
    problems = []
    if inside(args.dir, top):
        problems.append(f"{args.dir}: --dir is inside the repository, so each backup shows in status")
    planned = []
    for path in args.paths:
        rel = repo_relative(path, top)
        if rel is None:
            problems.append(f"{path}: outside the repository")
            continue
        try:
            st = os.lstat(path)
        except OSError:
            problems.append(f"{path}: does not exist")
            continue
        if stat.S_ISLNK(st.st_mode):
            problems.append(f"{path}: is a symlink; no mutation was written through it")
        elif not stat.S_ISREG(st.st_mode):
            problems.append(f"{path}: not a regular file")
        else:
            planned.append((path, os.path.join(args.dir, rel)))
    # Every refusal lands before the first copy, so --dir stays untouched.
    if problems:
        return problems
    for path, bak in planned:
        os.makedirs(os.path.dirname(bak), exist_ok=True)
        shutil.copy2(path, bak)
    return []


def cmd_prove(args, top):
    problems = []
    for path, bak, _ in backups(args.paths, args.dir, top):
        try:
            live = read_bytes(path)
        except FileNotFoundError:
            continue  # a deleted file differs from its backup
        if live == read_bytes(bak):
            problems.append(f"{path}: bytes match the backup, so the edit did not land")
    return problems


def cmd_restore(args, top):
    for path, bak, st in backups(args.paths, args.dir, top):
        if os.path.lexists(path):
            os.unlink(path)
        os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
        shutil.copyfile(bak, path)
        os.chmod(path, stat.S_IMODE(st.st_mode))
    return []


def cmd_check(args, top):
    try:
        snapshot = read_bytes(args.snapshot)
    except OSError as exc:
        raise UsageError(f"{args.snapshot}: unreadable snapshot: {exc.strerror}")
    problems = []
    for path, bak, bst in backups(args.paths, args.dir, top):
        try:
            st = os.lstat(path)
        except FileNotFoundError:
            problems.append(f"{path}: missing, backup at {bak}")
            continue
        if not stat.S_ISREG(st.st_mode):
            problems.append(f"{path}: not a regular file, backup is")
            continue
        if read_bytes(path) != read_bytes(bak):
            problems.append(f"{path}: bytes differ from the backup")
        if stat.S_IMODE(st.st_mode) != stat.S_IMODE(bst.st_mode):
            problems.append(
                f"{path}: mode {oct(stat.S_IMODE(st.st_mode))} differs from the backup's "
                f"{oct(stat.S_IMODE(bst.st_mode))}"
            )
    status = git(top, "status", "--porcelain", "-uall")
    if status != snapshot:
        before = snapshot.decode(errors="replace").splitlines()
        after = status.decode(errors="replace").splitlines()
        before_set, after_set = set(before), set(after)
        changed = [f"status: snapshot had '{line}', now absent" for line in before if line not in after_set]
        changed += [f"status: now '{line}', absent from snapshot" for line in after if line not in before_set]
        problems += changed or ["status: same lines as the snapshot in a different order"]
    return problems


def main(argv=None):
    ap = Parser(prog=PROG, description=__doc__.split("\n\n")[0])
    sub = ap.add_subparsers(dest="cmd", required=True, parser_class=Parser)
    p = sub.add_parser("snapshot")
    p.add_argument("--out", required=True, metavar="FILE")
    p.add_argument("--guard", action="append", default=[], metavar="PATH")
    for name in ("backup", "prove", "restore"):
        p = sub.add_parser(name)
        p.add_argument("--dir", required=True, metavar="D")
        p.add_argument("paths", nargs="+", metavar="PATH")
    p = sub.add_parser("check")
    p.add_argument("--dir", required=True, metavar="D")
    p.add_argument("--snapshot", required=True, metavar="FILE")
    # Without a PATH, check is status-only: the weaker comparison row 21 cuts.
    p.add_argument("paths", nargs="+", metavar="PATH")
    args = ap.parse_args(argv)

    handlers = {
        "snapshot": cmd_snapshot,
        "backup": cmd_backup,
        "prove": cmd_prove,
        "restore": cmd_restore,
        "check": cmd_check,
    }
    try:
        problems = handlers[args.cmd](args, toplevel())
    except UsageError as exc:
        sys.stderr.write(f"{PROG}: {exc}\n")
        return 3
    except OSError as exc:
        sys.stderr.write(f"{PROG}: {exc.filename}: {exc.strerror}\n")
        return 3
    for problem in problems:
        sys.stderr.write(f"{PROG}: {problem}\n")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
