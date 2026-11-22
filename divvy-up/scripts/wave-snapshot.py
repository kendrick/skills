#!/usr/bin/env python3
"""Record a wave's snapshot, list what the wave changed, and revert one task.

    divvy-up/scripts/wave-snapshot.py record --out PROMPT_DIR/wave-N.json
    divvy-up/scripts/wave-snapshot.py changed PROMPT_DIR/wave-N.json \\
        > PROMPT_DIR/wave-N.changed && divvy-up/scripts/check-waves.py \\
        owners PLAN.md --wave N < PROMPT_DIR/wave-N.changed
    divvy-up/scripts/wave-snapshot.py revert PROMPT_DIR/wave-N.json \\
        --plan PLAN.md --wave N --task LABEL

The orchestrator used to type this git by hand every wave, and the suite only
pinned its wording, so an edit or a run-time slip that compared the manifest by
name or dropped `-w` passed every check until a revert had no bytes to restore.

The snapshot file is JSON: `wave_base`, a commit; `untracked`, a map of each
untracked path to its blob; and `links`, the untracked paths that are symlinks.
A link's blob holds its link text, as git stores one, because hash-object on
the path follows the link to its target. Every path is repo-relative and every git
command runs at the top level, because `git diff --name-only` prints
root-relative paths while `git ls-files` prints cwd-relative ones, and
`check-waves.py owners` matches root-relative entries.

A path is changed when its content differs from the snapshot, never its status
text, name, or mtime. Decision 12: a ` M` file rewritten in a later wave keeps
its status line. Decision 15: an untracked file rewritten keeps its name.

`record` writes nothing to the index, the stash list, or the work tree: `git
stash create` builds a commit without storing it on the stash list, and `git
hash-object -w` writes only into the object database. `-w` is what lets revert
restore an untracked file once a worker overwrote or deleted it (decision 21).

`--out` may not land in a work tree, for the reason render-prompt.py gives:
the snapshot file would read as a write no task owns. A path under `.git/`
passes, since `--show-toplevel` fails there.

Exit codes: 0 success; 1 a git command failed, a manifest blob is missing,
the plan's Waves table is malformed, the task is not in the wave, or --out is
inside the work tree, with one line per problem on stderr; 3 usage or an
unreadable snapshot file. Argparse supplies 2 for a mistyped flag.

Stdlib only. check-waves.py is loaded by path, as render-prompt.py loads it,
so ownership has one rule.
"""
import argparse
import importlib.util
import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))


def fail(code, msg):
    sys.stderr.write(f"wave-snapshot: {msg}\n")
    raise SystemExit(code)


def run(cmd, *args, cwd=None, input=None):
    """Run `cmd`, a literal git command line, plus args; return the process."""
    argv = cmd.split() + list(args)
    if cwd:
        argv[1:1] = ["-C", cwd]
    return subprocess.run(argv, capture_output=True, input=input)


def git(cmd, *args, cwd=None, input=None):
    """Like run, but exit 1 on failure and return stdout bytes."""
    proc = run(cmd, *args, cwd=cwd, input=input)
    if proc.returncode != 0:
        err = proc.stderr.decode(errors="replace").strip().splitlines()
        fail(1, f"{cmd} failed: {err[-1] if err else 'exit ' + str(proc.returncode)}")
    return proc.stdout


def top_level():
    return git("git rev-parse --show-toplevel").decode().strip()


def split_z(out):
    return [p for p in out.decode("utf-8", "surrogateescape").split("\0") if p]


def untracked(root):
    return split_z(git("git ls-files -z --others --exclude-standard", cwd=root))


def links_of(root, paths):
    return {p for p in paths if os.path.islink(os.path.join(root, p))}


def hashes(root, cmd, paths):
    # A symlink hashes as its link text, the way git stores one: hash-object
    # on the path follows the link, so a peer rewriting the target would read
    # as a change to the link, and revert would replace the link with a file.
    links = links_of(root, paths)
    files = [p for p in paths if p not in links]
    # Chunked so a large untracked set stays under the argv limit.
    out = []
    for i in range(0, len(files), 500):
        out += git(cmd, "--", *files[i : i + 500], cwd=root).decode().split()
    blobs = dict(zip(files, out))
    for p in links:
        try:
            text = os.fsencode(os.readlink(os.path.join(root, p)))
        except OSError as e:
            fail(1, f"{p}: cannot read the symlink: {e}")
        blobs[p] = git(cmd + " --stdin", cwd=root, input=text).decode().strip()
    return blobs


def load_check_waves():
    # No bytecode: a __pycache__ written into the skill's directory is an
    # untracked file the ownership check would see.
    sys.dont_write_bytecode = True
    spec = importlib.util.spec_from_file_location("check_waves", os.path.join(HERE, "check-waves.py"))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def load_snapshot(path):
    try:
        with open(path, encoding="utf-8") as f:
            snap = json.load(f)
        base, manifest, links = snap["wave_base"], snap["untracked"], snap.get("links", [])
    except (OSError, ValueError, KeyError, TypeError, AttributeError) as e:
        fail(3, f"{path}: unreadable snapshot: {e}")
    if (
        not isinstance(base, str)
        or not isinstance(manifest, dict)
        or not isinstance(links, list)
        or not all(isinstance(p, str) for p in links)
    ):
        fail(3, f"{path}: unreadable snapshot: wave_base, untracked, or links has the wrong type")
    return base, manifest, set(links)


def cmd_record(args):
    where = os.path.dirname(os.path.realpath(args.out))
    if run("git rev-parse --show-toplevel", cwd=where).returncode == 0:
        fail(1, f"--out {args.out} is inside the work tree; Step 6 would count it as an unowned write")
    root = top_level()
    # Empty on a clean tree, which is the HEAD fallback.
    base = git("git stash create", cwd=root).decode().strip() or git("git rev-parse HEAD", cwd=root).decode().strip()
    paths = untracked(root)
    # --no-filters: a clean filter or eol rule would store normalized bytes,
    # and revert would restore those instead of what the file held.
    manifest = hashes(root, "git hash-object -w --no-filters", paths)
    try:
        with open(args.out, "w", encoding="utf-8") as f:
            snap = {"wave_base": base, "untracked": manifest, "links": sorted(links_of(root, paths))}
            json.dump(snap, f, indent=2, sort_keys=True)
            f.write("\n")
    except OSError as e:
        fail(3, f"--out {args.out}: {e}")
    return 0


def changed_paths(root, base, manifest, links):
    paths = set(split_z(git("git diff --name-only --no-renames -z", base, "--", cwd=root)))
    now = untracked(root)
    current = hashes(root, "git hash-object --no-filters", now)
    now_links = links_of(root, now)
    # Type counts too: a link swapped for a file holding its link text hashes the same.
    paths.update(p for p in now if manifest.get(p) != current[p] or (p in links) != (p in now_links))
    # Gone from the untracked set: deleted, or staged into the index.
    paths.update(p for p in manifest if p not in current)
    return sorted(paths)


def cmd_changed(args):
    base, manifest, links = load_snapshot(args.snapshot)
    for p in changed_paths(top_level(), base, manifest, links):
        print(p)
    return 0


def symlinked_parent(root, path):
    """Return the first parent of path, from the repo root down, that is a symlink."""
    parts = path.split("/")[:-1]
    for i in range(1, len(parts) + 1):
        component = "/".join(parts[:i])
        if os.path.islink(os.path.join(root, component)):
            return component
    return None


def cmd_revert(args):
    base, manifest, links = load_snapshot(args.snapshot)
    cw = load_check_waves()
    rows, problems = cw.read_rows(cw.load_plan(args.plan, args.plan))
    for problem in problems:
        sys.stderr.write(f"wave-snapshot: {problem}\n")
    if problems:
        return 1
    in_wave = [r for r in rows if r.wave == args.wave]
    if args.task not in {r.task for r in in_wave}:
        fail(1, f"no task {args.task!r} in wave {args.wave}")

    root = top_level()
    problems = []
    for path in changed_paths(root, base, manifest, links):
        if args.task not in cw.owners_of(path, in_wave):
            continue
        full = os.path.join(root, path)
        # A worker may have swapped a parent directory for a symlink, so a
        # restore or delete through it would land in a peer's file or outside
        # the repo. The tracked branch skips this check: git checkout replaces
        # the link with a real directory and never writes through it.
        parent = symlinked_parent(root, path)
        if path in manifest:
            if parent:
                problems.append(f"{path}: parent {parent} is a symlink; not followed, so it cannot be restored")
                continue
            # Restored from the blob, not the work tree: the worker may have
            # overwritten or deleted the only other copy.
            proc = run("git cat-file -p", manifest[path], cwd=root)
            if proc.returncode != 0:
                problems.append(f"{path}: manifest blob {manifest[path]} is missing; its bytes cannot be restored")
                continue
            # Never delete a directory a worker left here: it may hold files
            # no snapshot recorded, so report it and leave it for the user.
            if os.path.isdir(full) and not os.path.islink(full):
                problems.append(f"{path}: a directory now sits here; not removed, so it cannot be restored")
                continue
            try:
                os.makedirs(os.path.dirname(full), exist_ok=True)
                # Always a fresh file: open() would follow a symlink into its
                # target, and would write into a hard link's shared inode,
                # either of which may be a peer's file.
                if os.path.lexists(full):
                    os.remove(full)
                if path in links:
                    os.symlink(os.fsdecode(proc.stdout), full)
                else:
                    with open(full, "wb") as f:
                        f.write(proc.stdout)
            except OSError as e:
                problems.append(f"{path}: cannot restore it: {e}")
                continue
        elif run("git cat-file -e", f"{base}:{path}", cwd=root).returncode == 0:
            # Same rule as the manifest branch: checkout would delete the
            # directory and every unrecorded file in it.
            if os.path.isdir(full) and not os.path.islink(full):
                problems.append(f"{path}: a directory now sits here; not removed, so it cannot be restored")
                continue
            # run(), not git(): git() exits mid-loop and drops the problems
            # already collected.
            # --literal-pathspecs: check-waves allows brackets in an owned path
            # (app/[slug]/page.tsx), and as a pathspec `a[1].txt` also matches a
            # peer's `a1.txt` (review r4658035135).
            proc = run("git --literal-pathspecs checkout", base, "--", path, cwd=root)
            if proc.returncode != 0:
                err = proc.stderr.decode(errors="replace").strip().splitlines()
                problems.append(f"{path}: git checkout failed: {err[-1] if err else 'exit ' + str(proc.returncode)}")
                continue
        elif parent:
            problems.append(f"{path}: parent {parent} is a symlink; not followed, so it cannot be deleted")
            continue
        elif os.path.lexists(full):
            try:
                os.remove(full)
            except OSError as e:
                problems.append(f"{path}: cannot delete it: {e}")
                continue
        print(path)
    for problem in problems:
        sys.stderr.write(f"wave-snapshot: {problem}\n")
    return 1 if problems else 0


def main(argv=None):
    ap = argparse.ArgumentParser(description="Record, diff, and revert a divvy-up wave snapshot.")
    sub = ap.add_subparsers(dest="cmd", required=True)
    r = sub.add_parser("record", help="write WAVE_BASE and the untracked manifest")
    r.add_argument("--out", required=True, metavar="FILE")
    r.set_defaults(func=cmd_record)
    c = sub.add_parser("changed", help="print every path the wave changed")
    c.add_argument("snapshot", metavar="FILE")
    c.set_defaults(func=cmd_changed)
    v = sub.add_parser("revert", help="revert the changed paths one task owns")
    v.add_argument("snapshot", metavar="FILE")
    v.add_argument("--plan", required=True, metavar="PLAN")
    v.add_argument("--wave", type=int, required=True, metavar="N")
    v.add_argument("--task", required=True, metavar="LABEL")
    v.set_defaults(func=cmd_revert)
    args = ap.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
