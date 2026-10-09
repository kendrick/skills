#!/usr/bin/env python3
"""Report open issues whose `**Blocked by:**` or `**Parent:**` body lines disagree with GitHub's native links.

GitHub never reads those two body lines, so an issue filed before file-issue set
native links can say one thing in its body and hold another in `blockedBy` or
`parent`. The digest epic drifted this way: #60's body named four blockers while
the native field held one, so anything reading the dependency graph saw a
quarter of the truth. In kendrick/cambium, whose conventions forbid
body-text relationships, eight issues carried them anyway. The native field is
the authority, so an issue-resolvable entry in the body is the defect.

    check-relationships.py [--repo OWNER/REPO]

One line per finding on stdout, then a summary line:

    UNLINKED #<n> <slot> <entry>     the body names an issue the native field lacks
    CONTRADICTED #<n> <slot> None    the body says None; the native field is not empty
    DUPLICATE #<n> <slot> <entry>    the body names an issue the native field holds too

The repo's validators print findings to stderr. This script prints them to
stdout because it reports rather than gates, and
`_maintenance/jd/check-prose-refs.py` does the same.

`DUPLICATE` is a legacy double record that is safe to strip by hand, and it
doesn't fail the run, so the hand-reconciled #57-#62 stay clean. An entry
`parse_entry` rejects (a path, a discussion URL) agrees with anything and
prints nothing. So do an issue with no slot line and a `None` over an empty
native field.

A `**Parent:**` entry under a different owner than the repo also prints
nothing. GitHub won't link a sub-issue to a parent another owner holds, so
link-issues.py leaves that entry in the body as text, and no native link
exists to compare it with. A parent in another repo under the same owner
still reports, because GitHub can link it.

Only a line that starts with `**Blocked by:**` or `**Parent:**` counts. An issue
number in a Problem section or a quoted error block is prose, not a
relationship, and flagging it would train the reader to ignore the report.
For the same reason the script skips a slot line inside a ``` or ~~~ fence, in
code indented four columns, or behind a `>` quote marker.

Entries go through `parse_entry` from file-issue's link-issues.py rather than a
second regex here, and fences through its `FENCE_RE`, so this check and the
writer agree on what counts as an issue reference and as a code block.

It writes nothing to GitHub. An unrecorded blocker and a stale body line need
different fixes, and a person rules on each; the posture is jd-audit's.

Exit codes:
    0  no UNLINKED or CONTRADICTED finding (DUPLICATE alone still exits 0)
    1  at least one UNLINKED or CONTRADICTED finding
    3  usage error, or a gh call that failed or returned unreadable output
"""

import argparse
import importlib.util
import json
import subprocess
import sys
from pathlib import Path

GH_TIMEOUT = 60

REPO_ROOT = Path(__file__).resolve().parents[2]
SLOTS = {"**Blocked by:**": "blocked-by", "**Parent:**": "parent"}

# Sized to the plan's query: fifty blockers is far past any real issue here.
QUERY = (
    "query($owner:String!,$name:String!,$cursor:String){"
    "repository(owner:$owner,name:$name){"
    "issues(states:OPEN,first:100,after:$cursor){"
    "pageInfo{hasNextPage endCursor} "
    "nodes{number body parent{number repository{nameWithOwner}} "
    "blockedBy(first:50){nodes{number repository{nameWithOwner}}}}}}}"
)


class Parser(argparse.ArgumentParser):
    # argparse exits 2 on bad usage; the repo's validator convention is 3.
    def error(self, message):
        self.print_usage(sys.stderr)
        print(f"{self.prog}: error: {message}", file=sys.stderr)
        sys.exit(3)


class GhError(Exception):
    pass


def load_link_issues():
    # The filename has a hyphen, so a plain import can't reach it.
    path = REPO_ROOT / "file-issue" / "scripts" / "link-issues.py"
    spec = importlib.util.spec_from_file_location("link_issues", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.parse_entry, module.FENCE_RE


def gh(args):
    try:
        done = subprocess.run(["gh"] + args, capture_output=True, text=True, timeout=GH_TIMEOUT)
    except (OSError, subprocess.TimeoutExpired) as e:
        raise GhError(f"gh failed: {e}")
    if done.returncode != 0:
        detail = (done.stderr or done.stdout).strip().splitlines()
        raise GhError(f"gh exited {done.returncode}: {detail[0] if detail else 'no output'}")
    return done.stdout


def gh_json(args):
    out = gh(args)
    try:
        return json.loads(out)
    except ValueError:
        raise GhError("unreadable response from gh")


def fetch_issues(repo):
    owner, name = repo.split("/", 1)
    issues, cursor = [], None
    while True:
        args = ["api", "graphql", "-f", f"query={QUERY}", "-F", f"owner={owner}", "-F", f"name={name}"]
        if cursor:
            args += ["-F", f"cursor={cursor}"]
        data = gh_json(args)
        try:
            page = data["data"]["repository"]["issues"]
            issues += page["nodes"]
            has_next = page["pageInfo"]["hasNextPage"]
            cursor = page["pageInfo"]["endCursor"]
        except (KeyError, TypeError):
            raise GhError("unreadable response from gh")
        if not has_next:
            return issues


def issue_key(node):
    return (node["repository"]["nameWithOwner"].lower(), node["number"])


def native_refs(issue):
    parent = issue.get("parent")
    blockers = (issue.get("blockedBy") or {}).get("nodes") or []
    return {"parent": {issue_key(parent)} if parent else set(), "blocked-by": {issue_key(n) for n in blockers}}


def body_slots(body, fence_re):
    """Yield (slot, entries) for each slot line outside code; entries are the comma-split texts."""
    fence = None
    for line in (body or "").splitlines():
        # Same fence rule as strip_body in link-issues.py: a fence closes only
        # on a run of the opener's character at least as long as the opener,
        # so a ```` fence keeps a ``` line inside it.
        m = fence_re.match(line)
        if m:
            run, rest = m.group(1), m.group(2)
            if fence is None:
                fence = run
            elif run[0] == fence[0] and len(run) >= len(fence) and not rest.strip():
                fence = None
            continue
        if fence is not None:
            continue
        # Four columns of indent make a code block, except under a list item,
        # where they make continuation text. The check skips both. No
        # template indents a slot line, so skipping list text can cost a
        # finding only on a hand-written body.
        expanded = line.expandtabs(4)
        if len(expanded) - len(expanded.lstrip(" ")) >= 4:
            continue
        text = line.strip()
        for marker, slot in SLOTS.items():
            if text.startswith(marker):
                rest = text[len(marker):]
                yield slot, [e.strip() for e in rest.split(",") if e.strip()]


def check_issue(issue, home, parse_entry, fence_re):
    native = native_refs(issue)
    number = issue["number"]
    home_owner = home.split("/", 1)[0].lower()
    found, contradicted = [], set()
    for slot, entries in body_slots(issue.get("body"), fence_re):
        for entry in entries:
            if entry.lower() == "none":
                if native[slot] and slot not in contradicted:
                    contradicted.add(slot)
                    found.append(("CONTRADICTED", f"CONTRADICTED #{number} {slot} {entry}"))
                continue
            parsed = parse_entry(entry, home)
            if parsed is None:
                continue
            # Same owner test as resolve_entry in link-issues.py, the branch
            # whose reason starts "a sub-issue needs a parent owned by".
            # resolve_entry goes on to query GitHub, so the check copies the
            # comparison rather than calling it.
            if slot == "parent" and parsed[0].split("/", 1)[0].lower() != home_owner:
                continue
            key = (parsed[0].lower(), parsed[1])
            if key in native[slot]:
                found.append(("DUPLICATE", f"DUPLICATE #{number} {slot} {entry}"))
            else:
                found.append(("UNLINKED", f"UNLINKED #{number} {slot} {entry}"))
    return found


def main(argv):
    parser = Parser(description="Report body Parent/Blocked by lines that disagree with native links.")
    parser.add_argument("--repo", help="OWNER/REPO; defaults to the current directory's repository")
    args = parser.parse_args(argv)
    try:
        repo = args.repo
        if not repo:
            repo = gh_json(["repo", "view", "--json", "nameWithOwner"]).get("nameWithOwner")
        if not repo or repo.count("/") != 1:
            raise GhError(f"cannot resolve a repository from {repo!r}")
        parse_entry, fence_re = load_link_issues()
        issues = fetch_issues(repo)
    except GhError as e:
        print(f"check-relationships.py: {e}", file=sys.stderr)
        return 3
    except (OSError, AttributeError) as e:
        print(f"check-relationships.py: cannot load parse_entry: {e}", file=sys.stderr)
        return 3

    counts = {"UNLINKED": 0, "CONTRADICTED": 0, "DUPLICATE": 0}
    for issue in issues:
        for kind, line in check_issue(issue, repo, parse_entry, fence_re):
            counts[kind] += 1
            print(line)
    print(
        f"{len(issues)} open issues checked: {counts['UNLINKED']} unlinked, "
        f"{counts['CONTRADICTED']} contradicted, {counts['DUPLICATE']} duplicate."
    )
    return 1 if counts["UNLINKED"] or counts["CONTRADICTED"] else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
