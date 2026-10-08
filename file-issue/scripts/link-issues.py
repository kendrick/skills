#!/usr/bin/env python3
"""Resolve file-issue's Parent and Blocked-by entries and set them as native links.

Turning `#N` into a node ID, sending addSubIssue/addBlockedBy, and printing a
retry command when one fails is the same mechanical job every run, so it lives
here rather than in a fresh act of judgment each time. Deciding which entries
belong in those slots stays in SKILL.md: this script never reads the body.

    link-issues.py resolve [--repo O/R] [--parent ENTRY] [--blocked-by ENTRY ...]
    link-issues.py link [--issue URL] --plan RESOLVED.json [--out RESULT.json] [--dry-run]
    link-issues.py strip --issue URL --plan RESOLVED.json --result RESULT.json [--agent-targeted] [--dry-run]

`resolve` prints JSON. An entry gets a node only when GitHub returns an issue
for it; a path, a discussion or PR URL, a PR number, or anything unparseable
gets `node: null` and a reason, and stays in the body as text. So does a Parent
in a repository another owner holds, because GitHub only accepts a sub-issue
under a parent with the same owner. So does an entry the viewer lacks
permission to link: addBlockedBy needs TRIAGE or higher on the repo the issue
is filed into, and addSubIssue needs WRITE or higher on the parent's repo.

`link` sends one addSubIssue for the parent, then one addBlockedBy per
blocker, keeps going past a failure, and never retries. With --out it records
which links landed. --issue is optional only under --dry-run, because no issue
exists yet during a dry run; without it the lines carry the placeholder <new>
and nothing is sent.

`strip` runs after `link`. The body is rendered with every entry as text, so a
link that fails for any reason leaves its text where it was; `strip` fetches
the body, removes only the entries whose link landed from the Parent and
Blocked by lines, and sends one updateIssue. It never adds text, never touches
another line, and writes nothing when nothing linked. --agent-targeted keeps an
explicit "None" on a Blocked by line the strip emptied.

Exit codes:
    0  resolve printed its JSON; link set every link (or --dry-run listed them);
       strip wrote the body, or had nothing to remove
    1  link: at least one link failed; strip: the body write failed (each is
       printed with a retry command)
    3  usage error, unreadable plan or result, or the new issue can't be resolved
"""

import argparse
import json
import os
import re
import shlex
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


# viewerPermission levels, lowest first. addBlockedBy needs TRIAGE or higher on
# the repo the new issue is filed into, and addSubIssue needs WRITE or higher
# on the parent's repo (docs.github.com/en/issues/tracking-your-work-with-issues/
# using-issues/creating-issue-dependencies and /en/rest/issues/sub-issues).
# Creating an issue needs only read, so a filer can create and still be unable
# to link, and a link that fails for want of permission has no retry that
# could succeed. An entry the viewer cannot link therefore stays text.
PERMISSION_RANK = {"READ": 1, "TRIAGE": 2, "WRITE": 3, "MAINTAIN": 4, "ADMIN": 5}
BLOCKER_NEEDS = "TRIAGE"
PARENT_NEEDS = "WRITE"


def permits(level, needed):
    # An unreadable or unknown level counts as missing: losing a link costs a
    # manual link later, and losing the text costs the provenance.
    return PERMISSION_RANK.get(level or "", 0) >= PERMISSION_RANK[needed]


def repo_query(repo, selection):
    """Run one repository(...) query and return (repository data, reason)."""
    owner, name = repo.split("/", 1)
    query = f'query{{repository(owner:"{owner}",name:"{name}"){{{selection}}}}}'
    rc, out, err = gh(["api", "graphql", "-f", f"query={query}"])
    if rc != 0:
        return None, f"lookup failed: {first_line(err, out, rc)}"
    try:
        data = json.loads(out)["data"]["repository"]
    except (ValueError, KeyError, TypeError):
        return None, "lookup failed: unreadable response from gh"
    if not data:
        return None, f"no repository {repo}"
    return data, None


def lookup(repo, number, with_permission=False):
    """Return (node, permission, reason). node is None when there's no issue to link."""
    selection = f"issue(number:{number}){{id}}"
    if with_permission:
        selection = "viewerPermission " + selection
    data, reason = repo_query(repo, selection)
    if data is None:
        return None, None, reason
    issue = data.get("issue")
    if not issue or not issue.get("id"):
        # A PR number lands here too: GitHub's issue(number:) won't return one.
        return None, data.get("viewerPermission"), f"no issue #{number} in {repo} (a pull request, or no such number)"
    return issue["id"], data.get("viewerPermission"), None


def viewer_permission(repo):
    """Return the viewer's permission level on repo, or None where it can't be read."""
    data, _ = repo_query(repo, "viewerPermission")
    return data.get("viewerPermission") if data else None


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
    node, level, reason = lookup(repo, number, with_permission=parent)
    if node is not None and parent and not permits(level, PARENT_NEEDS):
        node, reason = None, f"addSubIssue needs {PARENT_NEEDS} or higher on {repo}, and the viewer has {level or 'no readable permission'}"
    result = {"entry": entry, "number": number, "repo": repo, "node": node}
    if node is None:
        result["reason"] = reason
    return result


def unlinkable(entry, home, reason):
    """A blocker that parsed as an issue reference but cannot be linked from home."""
    parsed = parse_entry(entry, home)
    if parsed is None:
        return {"entry": entry, "node": None, "reason": "not an issue reference"}
    repo, number = parsed
    return {"entry": entry, "number": number, "repo": repo, "node": None, "reason": reason}


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
    # addBlockedBy writes the dependency onto the new issue, so the permission
    # that matters for every blocker is the viewer's on the home repo. One
    # query covers them all, and it runs only when a blocker could link.
    if any(parse_entry(e, repo) for e in args.blocked_by):
        level = viewer_permission(repo)
        if permits(level, BLOCKER_NEEDS):
            blockers = [resolve_entry(e, repo) for e in args.blocked_by]
        else:
            reason = f"addBlockedBy needs {BLOCKER_NEEDS} or higher on {repo}, and the viewer has {level or 'no readable permission'}"
            blockers = [unlinkable(e, repo, reason) for e in args.blocked_by]
    else:
        blockers = [resolve_entry(e, repo) for e in args.blocked_by]
    plan = {
        "repo": repo,
        "parent": resolve_entry(args.parent, repo, parent=True) if args.parent is not None else None,
        "blocked_by": blockers,
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


def write_result(path, issue, node, linked, failed):
    with open(path, "w") as f:
        json.dump({"issue": issue, "node": node, "linked": linked, "failed": failed}, f, indent=2)


def cmd_link(args):
    plan_repo, links = load_plan(args.plan)
    if args.out:
        # An empty result lands before anything can fail, so a `link` that
        # exits 3 still leaves `strip` a file that says nothing linked.
        write_result(args.out, args.issue, None, [], [])
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
        new, _, reason = lookup(home, int(m.group(3)))
        if new is None or not NODE_RE.match(new):
            raise UsageError(f"can't resolve the new issue {args.issue}: {reason or 'malformed node'}")

    linked, failed = [], []
    for kind, item in links:
        query = mutation(kind, new, item["node"])
        name = label(item, home)
        record = {"kind": kind, "entry": item["entry"], "number": item.get("number"), "repo": item.get("repo")}
        if args.dry_run:
            print(f"would link {kind} {name}: {query}")
            linked.append(record)
            continue
        rc, out, err = gh(["api", "graphql", "-f", f"query={query}"])
        if rc == 0:
            print(f"linked {kind} {name}")
            linked.append(record)
        else:
            failed.append(record)
            print(f"FAILED {kind} {name}: {first_line(err, out, rc)}")
            print(f"  retry: gh api graphql -f query='{query}'")
    if args.dry_run:
        for record in linked:
            print(f"would strip {record['kind']} {label(record, home)} from the body once its link lands")
    if args.out:
        write_result(args.out, args.issue, new, linked, failed)
    return 1 if failed else 0


PARENT_LINE = "**Parent:**"
BLOCKED_LINE = "**Blocked by:**"


FENCE_RE = re.compile(r"^\s{0,3}(`{3,}|~{3,})")


def strip_body(body, linked, agent_targeted):
    """Return the body with each linked entry removed from its slot line, and whether anything changed."""
    parents_done = {l["entry"].strip() for l in linked if l["kind"] == "parent"}
    blockers_done = {l["entry"].strip() for l in linked if l["kind"] == "blocked-by"}
    out, changed = [], False
    fence = None
    for line in body.splitlines(keepends=True):
        text = line.strip()
        # A slot line inside a code fence is a sample, not the slot. The
        # fence closes on the same marker character it opened with.
        m = FENCE_RE.match(line)
        if m:
            marker = m.group(1)[0]
            if fence is None:
                fence = marker
            elif fence == marker:
                fence = None
            out.append(line)
            continue
        if fence is not None:
            out.append(line)
            continue
        # A Parent line goes only when it reads exactly as the linked entry;
        # commentary beside the reference is text nobody linked, so it stays.
        if parents_done and text.startswith(PARENT_LINE) and text[len(PARENT_LINE):].strip() in parents_done:
            changed = True
            continue
        if blockers_done and text.startswith(BLOCKED_LINE):
            entries = [e.strip() for e in text[len(BLOCKED_LINE):].split(",") if e.strip()]
            kept = [e for e in entries if e not in blockers_done]
            if len(kept) == len(entries):
                out.append(line)
                continue
            changed = True
            ending = line[len(line.rstrip("\r\n")):]
            if kept:
                out.append(f"{BLOCKED_LINE} {', '.join(kept)}{ending}")
            elif agent_targeted:
                # An absent list reads as unexamined; "None" says the slot
                # was considered and emptied on purpose.
                out.append(f"{BLOCKED_LINE} None{ending}")
            continue
        out.append(line)
    return "".join(out), changed


def load_result(path):
    try:
        with open(path) as f:
            result = json.load(f)
    except (OSError, ValueError) as e:
        raise UsageError(f"can't read result {path}: {e}")
    linked = result.get("linked") if isinstance(result, dict) else None
    if not isinstance(linked, list) or not all(isinstance(l, dict) and l.get("kind") in ("parent", "blocked-by") and isinstance(l.get("entry"), str) for l in linked):
        raise UsageError(f"result {path} isn't the shape link --out writes")
    return linked


UPDATE_BODY = 'mutation($id:ID!,$body:String!){updateIssue(input:{id:$id,body:$body}){issue{number}}}'


def cmd_strip(args):
    load_plan(args.plan)
    linked = load_result(args.result)
    if not linked:
        print("nothing linked; the body stays as filed")
        return 0
    m = URL_RE.match(args.issue.strip())
    if not m:
        raise UsageError(f"--issue must be an issue URL, got {args.issue!r}")
    home, number = f"{m.group(1)}/{m.group(2)}", int(m.group(3))
    data, reason = repo_query(home, f"issue(number:{number}){{id body}}")
    issue = (data or {}).get("issue") or {}
    node, body = issue.get("id"), issue.get("body")
    if not node or not NODE_RE.match(node) or body is None:
        raise UsageError(f"can't read the body of {args.issue}: {reason or 'no issue in the response'}")
    new_body, changed = strip_body(body, linked, args.agent_targeted)
    if not changed:
        print("no slot line carried a linked entry; the body stays as filed")
        return 0
    if args.dry_run:
        print("would update the body to:")
        print(new_body, end="" if new_body.endswith("\n") else "\n")
        return 0
    rc, out, err = gh(["api", "graphql", "-f", f"query={UPDATE_BODY}", "-f", f"id={node}", "-f", f"body={new_body}"])
    if rc == 0:
        print(f"stripped {', '.join(label(l, home) for l in linked)} from the body")
        return 0
    # The retry is this command again, not the body it tried to send: a
    # replayed snapshot would overwrite any edit made in between, and a
    # fresh run re-fetches the body before it strips.
    retry = ["python3", os.path.abspath(sys.argv[0]), "strip", "--issue", args.issue, "--plan", args.plan, "--result", args.result]
    if args.agent_targeted:
        retry.append("--agent-targeted")
    print(f"FAILED strip: {first_line(err, out, rc)}")
    print(f"  retry: {' '.join(shlex.quote(a) for a in retry)}")
    return 1


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
    lk.add_argument("--out")
    st = sub.add_parser("strip")
    st.add_argument("--issue", required=True)
    st.add_argument("--plan", required=True)
    st.add_argument("--result", required=True)
    st.add_argument("--agent-targeted", action="store_true")
    st.add_argument("--dry-run", action="store_true")
    args = parser.parse_args(argv)
    if args.cmd is None:
        parser.error("a subcommand is required: resolve, link, or strip")
    try:
        return {"resolve": cmd_resolve, "link": cmd_link, "strip": cmd_strip}[args.cmd](args)
    except UsageError as e:
        print(f"link-issues.py: {e}", file=sys.stderr)
        return 3


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
