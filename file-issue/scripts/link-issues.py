#!/usr/bin/env python3
"""Resolve file-issue's Parent and Blocked-by entries and set them as native links.

Turning `#N` into a node ID, sending addSubIssue/addBlockedBy, and printing a
retry command when one fails is the same mechanical job every run, so it lives
here rather than in a fresh act of judgment each time. Deciding which entries
belong in those slots stays in SKILL.md: this script never reads the body.

    link-issues.py resolve [--repo O/R] [--parent ENTRY] [--blocked-by ENTRY ...]
    link-issues.py link [--issue URL] --plan RESOLVED.json [--dry-run]

`resolve` prints JSON. An entry gets a node only when GitHub returns an issue
for it; a path, a discussion or PR URL, a PR number, or anything unparseable
gets `node: null` and a reason, and stays in the body as text. So does a Parent
in a repository another owner holds, because GitHub only accepts a sub-issue
under a parent with the same owner.

`link` sends one addSubIssue for the parent, then one addBlockedBy per
blocker, keeps going past a failure, and never retries or edits the body.
--issue is optional only under --dry-run, because no issue exists yet during a
dry run; without it the lines carry the placeholder <new> and nothing is sent.

Exit codes:
    0  resolve printed its JSON; link set every link (or --dry-run listed them)
    1  link: at least one link failed (each is printed with a retry command)
    3  usage error, unreadable plan, or the new issue can't be resolved
"""

import argparse
import json
import re
import subprocess
import sys

GH_TIMEOUT = 60

# Owner, repo, and node IDs are spliced into the GraphQL text so the logged
# mutation and the printed retry command are the same string. These patterns
# keep anything that could break out of a quoted literal from getting there.
OWNER_RE = r"[A-Za-z0-9](?:[A-Za-z0-9-]{0,38})"
NAME_RE = r"[A-Za-z0-9._-]{1,100}"
NODE_RE = re.compile(r"^[A-Za-z0-9_=-]+$")

SHORT_RE = re.compile(r"^#(\d+)$")
QUALIFIED_RE = re.compile(rf"^({OWNER_RE})/({NAME_RE})#(\d+)$")
URL_RE = re.compile(rf"^https://github\.com/({OWNER_RE})/({NAME_RE})/issues/(\d+)/?$")
REPO_RE = re.compile(rf"^({OWNER_RE})/({NAME_RE})$")


class UsageError(Exception):
    pass


class Parser(argparse.ArgumentParser):
    # argparse exits 2 on bad usage; the repo's validator convention is 3.
    def error(self, message):
        self.print_usage(sys.stderr)
        print(f"{self.prog}: error: {message}", file=sys.stderr)
        sys.exit(3)


def gh(args):
    try:
        done = subprocess.run(["gh"] + args, capture_output=True, text=True, timeout=GH_TIMEOUT)
    except OSError as e:
        return 1, "", str(e)
    except subprocess.TimeoutExpired:
        return 1, "", f"gh timed out after {GH_TIMEOUT}s"
    return done.returncode, done.stdout, done.stderr


def first_line(stderr, stdout, rc):
    # gh prints a one-line summary on stderr and the raw error JSON on stdout;
    # the summary is the readable one, so stdout is only the fallback.
    for stream in (stderr, stdout):
        for line in (stream or "").splitlines():
            if line.strip():
                return line.strip()
    return f"gh exited {rc}"


def parse_entry(entry, home):
    text = entry.strip()
    m = SHORT_RE.match(text)
    if m:
        return home, int(m.group(1))
    m = QUALIFIED_RE.match(text) or URL_RE.match(text)
    if m:
        return f"{m.group(1)}/{m.group(2)}", int(m.group(3))
    return None


def lookup(repo, number):
    """Return (node, reason). node is None when there's no issue to link."""
    owner, name = repo.split("/", 1)
    query = f'query{{repository(owner:"{owner}",name:"{name}"){{issue(number:{number}){{id}}}}}}'
    rc, out, err = gh(["api", "graphql", "-f", f"query={query}"])
    if rc != 0:
        return None, f"lookup failed: {first_line(err, out, rc)}"
    try:
        data = json.loads(out)["data"]["repository"]
    except (ValueError, KeyError, TypeError):
        return None, "lookup failed: unreadable response from gh"
    if not data:
        return None, f"no repository {repo}"
    issue = data.get("issue")
    if not issue or not issue.get("id"):
        # A PR number lands here too: GitHub's issue(number:) won't return one.
        return None, f"no issue #{number} in {repo} (a pull request, or no such number)"
    return issue["id"], None


def resolve_entry(entry, home, parent=False):
    parsed = parse_entry(entry, home)
    if parsed is None:
        return {"entry": entry, "node": None, "reason": "not an issue reference"}
    repo, number = parsed
    home_owner, owner = home.split("/", 1)[0], repo.split("/", 1)[0]
    if parent and owner.lower() != home_owner.lower():
        # addSubIssue only accepts a parent with the same owner as the new
        # issue (docs.github.com/en/rest/issues/sub-issues#add-sub-issue). A
        # cross-owner parent that resolved would leave the body at creation
        # and then fail to link, with no retry that could ever succeed, so it
        # is unresolved before any lookup. Logins compare case-insensitively.
        return {
            "entry": entry, "number": number, "repo": repo, "node": None,
            "reason": f"a sub-issue needs a parent owned by {home_owner}, and {repo}#{number} is owned by {owner}",
        }
    node, reason = lookup(repo, number)
    result = {"entry": entry, "number": number, "repo": repo, "node": node}
    if node is None:
        result["reason"] = reason
    return result


def default_repo():
    # A bare #N means the repo `gh issue create` will file into, which is the
    # one `gh repo view` reports from the current directory.
    rc, out, err = gh(["repo", "view", "--json", "nameWithOwner"])
    if rc != 0:
        raise UsageError(f"can't tell which repo #N means: {first_line(err, out, rc)}")
    try:
        return json.loads(out)["nameWithOwner"]
    except (ValueError, KeyError, TypeError):
        raise UsageError("can't tell which repo #N means: unreadable gh repo view output")


def cmd_resolve(args):
    repo = args.repo or default_repo()
    if not REPO_RE.match(repo):
        raise UsageError(f"--repo must be OWNER/REPO, got {repo!r}")
    plan = {
        "repo": repo,
        "parent": resolve_entry(args.parent, repo, parent=True) if args.parent is not None else None,
        "blocked_by": [resolve_entry(e, repo) for e in args.blocked_by],
    }
    print(json.dumps(plan, indent=2))
    return 0


def mutation(kind, new, other):
    if kind == "parent":
        return f'mutation{{addSubIssue(input:{{issueId:"{other}",subIssueId:"{new}"}}){{issue{{number}}}}}}'
    return f'mutation{{addBlockedBy(input:{{issueId:"{new}",blockingIssueId:"{other}"}}){{issue{{number}}}}}}'


def label(item, home_repo):
    if item.get("repo") and item["repo"] != home_repo and item.get("number") is not None:
        return f"{item['repo']}#{item['number']}"
    if item.get("number") is not None:
        return f"#{item['number']}"
    return str(item.get("entry"))


def load_plan(path):
    try:
        with open(path) as f:
            plan = json.load(f)
    except (OSError, ValueError) as e:
        raise UsageError(f"can't read plan {path}: {e}")
    if not isinstance(plan, dict) or not isinstance(plan.get("blocked_by", []), list):
        raise UsageError(f"plan {path} isn't the shape resolve prints")
    links = []
    parent = plan.get("parent")
    for kind, item in [("parent", parent)] + [("blocked-by", b) for b in plan.get("blocked_by", [])]:
        if item is None:
            continue
        if not isinstance(item, dict):
            raise UsageError(f"plan {path} has a {kind} entry that isn't an object")
        node = item.get("node")
        if node is None:
            continue
        if not isinstance(node, str) or not NODE_RE.match(node):
            raise UsageError(f"plan {path} has a malformed {kind} node: {node!r}")
        links.append((kind, item))
    return plan.get("repo"), links


def cmd_link(args):
    plan_repo, links = load_plan(args.plan)
    if args.issue is None:
        if not args.dry_run:
            raise UsageError("--issue is required unless --dry-run is given")
        # Labels are relative to the repo the issue will be filed into,
        # which resolve recorded in the plan.
        home, new = plan_repo, "<new>"
    else:
        m = URL_RE.match(args.issue.strip())
        if not m:
            raise UsageError(f"--issue must be an issue URL, got {args.issue!r}")
        home = f"{m.group(1)}/{m.group(2)}"
        new, reason = lookup(home, int(m.group(3)))
        if new is None or not NODE_RE.match(new):
            raise UsageError(f"can't resolve the new issue {args.issue}: {reason or 'malformed node'}")

    failed = 0
    for kind, item in links:
        query = mutation(kind, new, item["node"])
        name = label(item, home)
        if args.dry_run:
            print(f"would link {kind} {name}: {query}")
            continue
        rc, out, err = gh(["api", "graphql", "-f", f"query={query}"])
        if rc == 0:
            print(f"linked {kind} {name}")
        else:
            failed += 1
            print(f"FAILED {kind} {name}: {first_line(err, out, rc)}")
            print(f"  retry: gh api graphql -f query='{query}'")
    return 1 if failed else 0


def main(argv):
    parser = Parser(prog="link-issues.py", description=__doc__.splitlines()[0])
    sub = parser.add_subparsers(dest="cmd", parser_class=Parser)
    r = sub.add_parser("resolve")
    r.add_argument("--repo")
    r.add_argument("--parent")
    r.add_argument("--blocked-by", action="append", default=[])
    lk = sub.add_parser("link")
    lk.add_argument("--issue")
    lk.add_argument("--plan", required=True)
    lk.add_argument("--dry-run", action="store_true")
    args = parser.parse_args(argv)
    if args.cmd is None:
        parser.error("a subcommand is required: resolve or link")
    try:
        return cmd_resolve(args) if args.cmd == "resolve" else cmd_link(args)
    except UsageError as e:
        print(f"link-issues.py: {e}", file=sys.stderr)
        return 3


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
