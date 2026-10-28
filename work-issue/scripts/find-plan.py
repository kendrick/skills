#!/usr/bin/env python3
"""Find the one plan for issue N in the directories WORK_ISSUE_PLAN_DIRS lists.

Usage: find-plan.py --issue N --repo OWNER/NAME

WORK_ISSUE_PLAN_DIRS is a colon-separated list. Unset means ~/.claude/plans
when that is a directory (where Claude Code's plan mode saves) and nothing
otherwise. The empty string turns the route off.

Exit codes follow the validator convention:
  0  one survivor (its absolute path on stdout), or none (stdout empty)
  1  two or more survivors: one `ambiguous: <path>` line each on stderr, sorted
  3  usage error, a set directory that is not a directory, or an unreadable
     candidate

A set-but-missing directory exits 3 instead of reading as "no plan": a typo in
the variable would otherwise fall through to the conversation route in silence.
"""
import argparse
import os
import re
import sys


class _Parser(argparse.ArgumentParser):
    def error(self, message):
        # argparse defaults to 2; the repo's validators use 3 for usage errors.
        self.print_usage(sys.stderr)
        sys.stderr.write(f"{self.prog}: error: {message}\n")
        sys.exit(3)


# A bare owner/name can't be the rule: plans cite paths like work-issue/SKILL.md
# that have the same shape. Only a GitHub URL or the cross-repo issue shorthand
# counts as naming a repository.
URL_REF = re.compile(
    r"github\.com/([A-Za-z0-9-]+)/([A-Za-z0-9._-]+?)(?:\.git)?(?=[/#?\s)\]>\"'`]|$)"
)
SHORTHAND_REF = re.compile(r"(?<![\w./-])([A-Za-z0-9-]+)/([A-Za-z0-9._-]+)#[0-9]+")
SUPERSEDED = re.compile(r"\.v[0-9]+\.md$")


def positive_int(value):
    if not re.fullmatch(r"[0-9]+", value) or int(value) < 1:
        raise argparse.ArgumentTypeError(f"not a positive integer: {value!r}")
    return int(value)


def plan_dirs():
    raw = os.environ.get("WORK_ISSUE_PLAN_DIRS")
    if raw is None:
        default = os.path.join(os.path.expanduser("~"), ".claude", "plans")
        return [default] if os.path.isdir(default) else []
    return [os.path.abspath(p) for p in raw.split(":") if p]


def names_other_repo(text, repo):
    want = repo.lower()
    for rx in (URL_REF, SHORTHAND_REF):
        for m in rx.finditer(text):
            if f"{m.group(1)}/{m.group(2)}".lower() != want:
                return True
    return False


def main():
    ap = _Parser(prog="find-plan.py", description=__doc__.split("\n")[0])
    ap.add_argument("--issue", type=positive_int, required=True)
    ap.add_argument("--repo", required=True)
    args = ap.parse_args()
    if args.repo.count("/") != 1 or not all(args.repo.split("/")):
        ap.error(f"--repo must be OWNER/NAME: {args.repo!r}")

    number = re.compile(rf"(?<![0-9]){args.issue}(?![0-9])")
    survivors = []
    for d in plan_dirs():
        if not os.path.isdir(d):
            sys.stderr.write(f"not a directory: {d}\n")
            sys.exit(3)
        try:
            names = sorted(os.listdir(d))
        except OSError:
            sys.stderr.write(f"unreadable: {d}\n")
            sys.exit(3)
        for name in names:
            path = os.path.join(d, name)
            if not name.endswith(".md") or not os.path.isfile(path):
                continue
            if not number.search(name) or SUPERSEDED.search(name):
                continue
            try:
                with open(path, encoding="utf-8", errors="replace") as f:
                    text = f.read()
            except OSError:
                sys.stderr.write(f"unreadable: {path}\n")
                sys.exit(3)
            if not names_other_repo(text, args.repo):
                survivors.append(path)

    survivors = sorted(set(survivors))
    if len(survivors) == 1:
        print(survivors[0])
    elif survivors:
        for p in survivors:
            sys.stderr.write(f"ambiguous: {p}\n")
        sys.exit(1)


if __name__ == "__main__":
    main()
