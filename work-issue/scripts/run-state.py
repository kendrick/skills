#!/usr/bin/env python3
"""Read a pull request's review state, gather a resume probe, and map it to a phase.

    work-issue/scripts/run-state.py review PR [--since ISO8601] [--author LOGIN] [--save PATH]
    work-issue/scripts/run-state.py review PR --input BUNDLE.json [--save PATH]
    work-issue/scripts/run-state.py probe --run-dir DIR --root ROOT --issue N [--pr-bundle FILE] [--herdr-state STATE] [--author LOGIN]
    work-issue/scripts/run-state.py phase --probe PROBE.json

Neither subcommand is a gate. `review` answers `findings`, `cleared`, or
`pending` on its first stdout line, then lists every item that bore on the
answer. `phase` answers where a half-finished run resumes. The skill reads both
answers and decides what to do with them, so neither subcommand ever exits 1.
`findings` is an answer.

Without `--since`, every item on the pull request counts, and an approving
reaction sits there forever. PR #100 of this repo carried a `+1` beside five
finding threads from the same reviewer, so the reaction was a verdict on one
push rather than on the pull request. `--since` takes the last push's timestamp, and
every item before it is ignored. An item stamped the same second as the cutoff
counts: the marker is written just before the push, both carry one-second
precision, and a strict comparison lost a review that landed in that second.

`--input` reads the shape the `gh` calls below produce, so the fixtures under
tests/fixtures/work-issue/review/ exercise the state rules with no network.
Nothing shells out while `--input` is given.

`--save PATH` writes the gathered bundle to PATH as JSON, whether or not
`--input` was given. A thread's or a review's deciding line carries an id, a
URL, and (for a review) a state and timestamp — never the body a reply has to
quote. The skill reads the saved file for that body instead of asking `gh`
again.

`probe` reads git, RUN_DIR, and a bundle `review --save` wrote, and prints the
JSON `phase --probe` reads, every field present. It never calls `gh` or
`herdr`: the bundle carries GitHub's answer and `--herdr-state` carries
herdr's. A field it cannot answer is null, with one stderr line saying why.

Exit codes: 0 with an answer on stdout; 3 usage, a `gh` failure, an unwritable
`--save` path, or input this script cannot read (an unparseable bundle, a
bundle missing a top-level key, a probe missing a field). Argparse supplies 2
for a mistyped flag, except under `probe`, where it is 3 too, because the
issue that asked for `probe` asked for the validator convention.

Stdlib only, so the skill stays copy-in portable.
"""
import argparse
import fnmatch
import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

GH_TIMEOUT = 60

# One page size for both paginated connections below, kept as a module
# constant rather than a literal in each query. A scratch run can lower it to
# prove the paging loop against a PR with only a handful of reviews or
# threads.
PAGE_SIZE = 100

# Only these two review states bear on the answer. A COMMENTED review is
# carried by its threads, and PENDING is a draft only its author can see.
DECIDING_REVIEWS = ("APPROVED", "CHANGES_REQUESTED")

# A comment from a reviewer is a finding unless it says nothing but "yes".
# The set is short on purpose. A comment this script cannot read as a bare
# approval becomes a finding, which costs a human one triage row. The opposite
# error advances a run past a review nobody answered.
BARE_APPROVALS = frozenset(
    (
        "",
        "+1",
        "1",
        "lgtm",
        "lgtms",
        "approved",
        "approve",
        "ship it",
        "shipit",
        "looks good",
        "looks good to me",
        "looks good thanks",
        "nice work",
        "thumbsup",
    )
)

_STRIPPABLE = "*_`~#>!.,:;?()[]\"' \t\n👍✅🎉"

PROBE_FIELDS = (
    ("herdr_agent_state", "enum", ("working", "blocked", "idle", "done", "absent")),
    ("branch_local", "bool", ()),
    ("branch_remote", "bool", ()),
    ("run_dir", "bool", ()),
    ("base_sha", "bool", ()),
    ("baseline", "bool", ()),
    ("base_sha_state", "enum", ("current", "not-merge-base", "not-ancestor", "absent")),
    ("pr_state", "enum", ("OPEN", "MERGED", "CLOSED")),
    ("review_state", "enum", ("findings", "cleared", "pending")),
    ("has_waves", "bool", ()),
    ("wave_tasks", "int", ()),
    ("wave_reports", "int", ()),
    ("wave_unreported_committed", "int", ()),
    ("self_reviews", "int", ()),
    ("build_final", "bool", ()),
    ("redteam_rounds", "int", ()),
    ("redteam_last_failed", "bool", ()),
    ("redteam_failed_twice", "bool", ()),
    ("repair_after_last_round", "bool", ()),
    ("trigger_fired", "enum", ("yes", "no", "absent")),
    ("ar_complete", "bool", ()),
    ("conflict", "bool", ()),
    ("rebase_in_progress", "bool", ()),
    ("ahead_of_origin", "bool", ()),
    ("triage_rounds", "int", ()),
    ("triage_newer_than_since", "bool", ()),
    ("triage_inscope_rows", "int", ()),
    ("repair_reports", "int", ()),
    ("newest_repair_report", "bool", ()),
    ("triage_rows_unanswered", "int", ()),
    ("deferred_comment_needed", "bool", ()),
    ("triage_blocking_rows", "int", ()),
    ("max_review_rounds", "int", ()),
    ("triage_stop_rows", "int", ()),
    ("repair_ar_settled", "bool", ()),
    ("review_over_budget", "bool", ()),
    ("repair_diff_triggers", "bool", ()),
)

# A bundle's `state` is optional to `check_bundle`, so every review fixture
# written before it existed still reads, and required by `probe`.
PR_STATES = ("OPEN", "MERGED", "CLOSED")

BUNDLE_KEYS = (
    ("author", (str, type(None))),
    ("reactions", (list,)),
    ("reviews", (list,)),
    ("threads", (list,)),
    ("comments", (list,)),
)

# `poll` is a real label in a timing.log but never a build or review phase:
# it exists only so the external-reviewer wait stays visible without adding
# wall-clock time to either total. `1` (isolate/baseline) and `5` (publish)
# are read and ignored the same way.
TIMING_LABELS = frozenset(("1", "2", "3", "4", "5", "6", "7", "8", "poll"))
BUILD_LABELS = ("2", "3")
REVIEW_LABELS = ("4", "6", "7", "8")

DEFAULT_BUDGET_RATIO = 2.0


class InputError(Exception):
    """Input this script cannot read: bad JSON, a missing key, a bad timestamp.

    Carries every problem rather than the first. A bundle or probe written by
    hand is usually wrong in more than one place, and one problem per run turns
    that into one round trip per typo."""

    def __init__(self, problems):
        self.problems = list(problems)
        super().__init__("; ".join(self.problems))


class GhError(Exception):
    """`gh` could not be run, timed out, exited non-zero, or answered non-JSON."""


def load_json(path, label):
    if path == "-":
        try:
            text = sys.stdin.read()
        except OSError as e:
            raise InputError([f"{label}: cannot read stdin: {e}"])
    else:
        try:
            with open(path, encoding="utf-8") as handle:
                text = handle.read()
        except OSError as e:
            raise InputError([f"{label}: {e.strerror or e}: {path}"])
    try:
        return json.loads(text)
    except ValueError as e:
        raise InputError([f"{label}: not JSON: {e}"])


def decode_stream(text, label):
    """Every JSON document in `text`, concatenated.

    `gh api --paginate` prints one document per page with nothing between them,
    so json.loads sees trailing data and fails as soon as a pull request runs to
    a second page. raw_decode reads the documents one at a time."""
    decoder = json.JSONDecoder()
    docs = []
    index = 0
    length = len(text)
    while index < length:
        while index < length and text[index].isspace():
            index += 1
        if index >= length:
            break
        try:
            doc, index = decoder.raw_decode(text, index)
        except ValueError as e:
            raise GhError(f"{label}: not JSON: {e}")
        docs.append(doc)
    return docs


def gh(args, label):
    try:
        completed = subprocess.run(
            ["gh"] + args,
            capture_output=True,
            text=True,
            timeout=GH_TIMEOUT,
        )
    except OSError as e:
        raise GhError(f"{label}: {e}")
    except subprocess.TimeoutExpired:
        raise GhError(f"{label}: timed out after {GH_TIMEOUT}s")
    if completed.returncode != 0:
        why = (completed.stderr or completed.stdout or "").strip()
        raise GhError(f"{label}: {' '.join(why.split())[:300] or 'exit ' + str(completed.returncode)}")
    return decode_stream(completed.stdout, label)


def flatten_pages(docs, label):
    rows = []
    for doc in docs:
        if isinstance(doc, list):
            rows.extend(doc)
        else:
            raise GhError(f"{label}: expected a JSON array, got {type(doc).__name__}")
    return rows


# Reviews and review threads are separate connections, each with its own
# cursor. One query per connection is the simplest shape that pages either
# one to exhaustion without tangling its cursor with the other's. The author
# only needs to ride on one query, and reviews is the one that runs first.
REVIEWS_QUERY = """
query($owner: String!, $name: String!, $pr: Int!, $pageSize: Int!, $after: String) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $pr) {
      author { login }
      state
      reviews(first: $pageSize, after: $after) {
        nodes { state author { login } submittedAt databaseId body url }
        pageInfo { hasNextPage endCursor }
      }
    }
  }
}
"""

# Twenty is a bound, not a measurement: a review thread that runs past twenty
# comments after the reviewer's follow-up is not a shape any run has seen, and
# an unbounded tail would page per thread on every poll. Raise it here if one
# ever does.
THREADS_QUERY = """
query($owner: String!, $name: String!, $pr: Int!, $pageSize: Int!, $after: String) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $pr) {
      reviewThreads(first: $pageSize, after: $after) {
        nodes {
          id
          isResolved
          root: comments(first: 1) {
            nodes { author { login } createdAt body databaseId url }
          }
          latest: comments(last: 20) {
            nodes { author { login } createdAt body databaseId url }
          }
        }
        pageInfo { hasNextPage endCursor }
      }
    }
  }
}
"""


def _login(node):
    return (node or {}).get("login")


def _paginate_pr_connection(owner, name, pr, query, field, label):
    """Every node of one pull-request connection (`reviews` or
    `reviewThreads`), followed to its last page.

    A fixed `first: 100` with no `pageInfo` silently drops everything past the
    hundredth review or thread. A pull request that had accumulated that many
    over several review rounds could then report `cleared` over a finding
    nobody read. Returns the nodes and the last page's `pullRequest` object,
    so a caller can also read `author` or confirm the pull request exists off
    whichever connection it paged."""
    nodes = []
    pull = {}
    after = None
    while True:
        args = [
            "api",
            "graphql",
            "-F",
            f"owner={owner}",
            "-F",
            f"name={name}",
            "-F",
            f"pr={pr}",
            "-F",
            f"pageSize={PAGE_SIZE}",
            "-f",
            f"query={query}",
        ]
        if after is not None:
            args += ["-f", f"after={after}"]
        docs = gh(args, label)
        payload = docs[0] if docs else {}
        repository = ((payload.get("data") or {}).get("repository")) or {}
        pull = repository.get("pullRequest") or {}
        connection = pull.get(field) or {}
        nodes.extend(connection.get("nodes") or [])
        page_info = connection.get("pageInfo") or {}
        after = page_info.get("endCursor")
        if not page_info.get("hasNextPage") or after is None:
            break
    return nodes, pull


def gather(pr):
    """The bundle shape, read from `gh`.

    Four calls, because no one of them has all of it. REST carries the
    reactions and the issue comments. GraphQL carries the author, the
    reviews, and the review threads with their resolved flag. Reviews and
    threads are two calls, not one, because each paginates on its own
    cursor. Only a hand run exercises this path. Every fixture goes through
    `--input`, so the smoke suite does not cover a change here."""
    repo_docs = gh(["repo", "view", "--json", "nameWithOwner"], "gh repo view")
    name_with_owner = (repo_docs[0] if repo_docs else {}).get("nameWithOwner", "")
    if "/" not in name_with_owner:
        raise GhError(f"gh repo view: no owner/name in {name_with_owner!r}")
    owner, name = name_with_owner.split("/", 1)

    reactions = flatten_pages(
        gh(
            ["api", "--paginate", f"repos/{owner}/{name}/issues/{pr}/reactions"],
            f"gh api repos/{owner}/{name}/issues/{pr}/reactions",
        ),
        "reactions",
    )
    comments = flatten_pages(
        gh(
            ["api", "--paginate", f"repos/{owner}/{name}/issues/{pr}/comments"],
            f"gh api repos/{owner}/{name}/issues/{pr}/comments",
        ),
        "comments",
    )

    review_nodes, reviews_pull = _paginate_pr_connection(
        owner, name, pr, REVIEWS_QUERY, "reviews", "gh api graphql (reviews)"
    )
    if not reviews_pull:
        raise GhError(f"gh api graphql: no pull request {pr} in {name_with_owner}")
    thread_nodes, _ = _paginate_pr_connection(
        owner, name, pr, THREADS_QUERY, "reviewThreads", "gh api graphql (reviewThreads)"
    )

    threads = []
    for node in thread_nodes:
        roots = ((node.get("root") or {}).get("nodes")) or []
        root = roots[0] if roots else {}
        # The thread's recent comments ride along with the root. A reviewer who
        # answers inside an old thread after a repair push writes no new root,
        # and a bundle carrying only roots scored that thread against the old
        # date. The whole tail travels, not the last comment alone: when the
        # author answers after the reviewer, the last comment is the author's
        # and the reviewer's follow-up sat behind it unseen.
        tail = [
            {
                "author": _login(c.get("author")),
                "created_at": c.get("createdAt"),
                "body": c.get("body"),
                "id": c.get("databaseId"),
                "url": c.get("url"),
            }
            for c in (((node.get("latest") or {}).get("nodes")) or [])
        ]
        latest = tail[-1] if tail else {}
        threads.append(
            {
                "id": node.get("id"),
                "is_resolved": node.get("isResolved"),
                "root_created_at": root.get("createdAt"),
                "root_author": _login(root.get("author")),
                "root_body": root.get("body"),
                "root_comment_id": root.get("databaseId"),
                "root_url": root.get("url"),
                "last_comment_at": latest.get("created_at"),
                "last_comment_author": latest.get("author"),
                "last_comment_body": latest.get("body"),
                "last_comment_id": latest.get("id"),
                "last_comment_url": latest.get("url"),
                "comments": tail,
            }
        )

    return {
        "state": reviews_pull.get("state"),
        "author": _login(reviews_pull.get("author")),
        "reactions": [
            {
                "content": r.get("content"),
                "user": _login(r.get("user")),
                "created_at": r.get("created_at"),
            }
            for r in reactions
        ],
        "reviews": [
            {
                "state": n.get("state"),
                "author": _login(n.get("author")),
                "submitted_at": n.get("submittedAt"),
                "id": n.get("databaseId"),
                "body": n.get("body"),
                "url": n.get("url"),
            }
            for n in review_nodes
        ],
        "threads": threads,
        "comments": [
            {
                "author": _login(c.get("user")),
                "created_at": c.get("created_at"),
                "body": c.get("body"),
                "id": c.get("id"),
                "url": c.get("html_url"),
            }
            for c in comments
        ],
    }


def parse_ts(value, label, problems):
    """`value` as an aware UTC datetime, or None when it is null or unreadable.

    Downstream, None reads as older than any cutoff. A thread whose root
    comment GitHub did not return therefore cannot set the state on a timestamp
    that is not there."""
    if value is None:
        return None
    if not isinstance(value, str) or not value.strip():
        problems.append(f"{label}: {value!r} is not an ISO 8601 timestamp")
        return None
    raw = value.strip()
    if raw[-1] in "Zz":
        raw = raw[:-1] + "+00:00"
    try:
        moment = datetime.fromisoformat(raw)
    except ValueError:
        problems.append(f"{label}: {value!r} is not an ISO 8601 timestamp")
        return None
    if moment.tzinfo is None:
        moment = moment.replace(tzinfo=timezone.utc)
    return moment.astimezone(timezone.utc)


def show_ts(moment):
    return moment.strftime("%Y-%m-%dT%H:%M:%SZ") if moment else "unknown"


def show_or_unknown(value):
    """`value`, or `unknown` where an older bundle has no value for it.

    An `--input` fixture written before this field existed has no
    `root_comment_id`, review `url`, or comment `url` at all. `check_bundle`
    does not require them, and `classify` reads the gap as null through
    `.get`. The reply target is optional information about a deciding item,
    not a condition of reading one."""
    return "unknown" if value is None else value


def normalize_login(login):
    """A login as it compares.

    REST spells an app `chatgpt-codex-connector[bot]` and GraphQL spells the
    same account `chatgpt-codex-connector`. Leave the suffix on and the two
    halves of one bundle disagree about whether a reaction and a thread came
    from the same reviewer. GitHub logins are case-insensitive, so the fold to
    lowercase happens here too."""
    if not isinstance(login, str):
        return ""
    name = login.strip()
    if name.lower().endswith("[bot]"):
        name = name[: -len("[bot]")]
    return name.lower()


def is_bare_approval(body):
    if not isinstance(body, str):
        return False
    text = " ".join(body.split()).strip(_STRIPPABLE).lower()
    text = re.sub(r"^:(\+1|thumbsup|white_check_mark|tada):$", "thumbsup", text)
    return text.strip(_STRIPPABLE) in BARE_APPROVALS


def severity(body):
    """P0, P1, or `-`. Codex writes the severity as the first bold run of a
    finding's body. The triage rule reads that severity to settle an ambiguous
    in-scope call, so the thread's line carries it."""
    if not isinstance(body, str):
        return "-"
    for level in ("P0", "P1"):
        if re.search(r"(?<![A-Za-z0-9])" + level + r"(?![A-Za-z0-9])", body):
            return level
    return "-"


def require_keys(obj, keys, label, problems):
    missing = [key for key in keys if key not in obj]
    if missing:
        problems.append(f"{label}: missing {', '.join(missing)}")
        return False
    return True


def check_bundle(bundle):
    problems = []
    if not isinstance(bundle, dict):
        raise InputError([f"bundle: expected a JSON object, got {type(bundle).__name__}"])
    for key, types in BUNDLE_KEYS:
        if key not in bundle:
            problems.append(f"bundle: missing {key}")
        elif not isinstance(bundle[key], types):
            wanted = " or ".join(t.__name__ for t in types)
            problems.append(
                f"bundle: {key} is {type(bundle[key]).__name__}, expected {wanted}"
            )
    if "state" in bundle and bundle["state"] not in PR_STATES:
        problems.append(
            f"bundle: state is {bundle['state']!r}, expected one of {', '.join(PR_STATES)}"
        )
    if problems:
        raise InputError(problems)
    for index, thread in enumerate(bundle["threads"]):
        if not isinstance(thread, dict):
            problems.append(f"threads[{index}]: expected an object")
            continue
        require_keys(
            thread,
            ("id", "is_resolved", "root_created_at", "root_author", "root_body"),
            f"threads[{index}]",
            problems,
        )
    for index, reaction in enumerate(bundle["reactions"]):
        if not isinstance(reaction, dict):
            problems.append(f"reactions[{index}]: expected an object")
            continue
        require_keys(
            reaction, ("content", "user", "created_at"), f"reactions[{index}]", problems
        )
    for index, review in enumerate(bundle["reviews"]):
        if not isinstance(review, dict):
            problems.append(f"reviews[{index}]: expected an object")
            continue
        require_keys(
            review, ("state", "author", "submitted_at"), f"reviews[{index}]", problems
        )
    for index, comment in enumerate(bundle["comments"]):
        if not isinstance(comment, dict):
            problems.append(f"comments[{index}]: expected an object")
            continue
        require_keys(
            comment, ("author", "created_at", "body"), f"comments[{index}]", problems
        )
    if problems:
        raise InputError(problems)


def classify(bundle, since, author):
    """The state and the lines that justify it.

    The lines cover every item past the cutoff, not only the ones that set the
    state. This script answered `findings` for PR #100 while an approving
    reaction sat on it, and a human reading that answer needs to see the
    reaction that lost."""
    problems = []
    author_key = normalize_login(author)
    lines = []
    findings = False
    approving = False

    def newer(moment):
        # Inclusive: GitHub stamps to the second and so does pushed_at, and the
        # marker is written just before the push, so an event in the cutoff's
        # own second reviewed the new push. Strict `>` lost it for good.
        return moment is not None and (since is None or moment >= since)

    for index, thread in enumerate(bundle["threads"]):
        created = parse_ts(
            thread["root_created_at"], f"threads[{index}].root_created_at", problems
        )
        if thread["is_resolved"]:
            continue
        # An unresolved thread counts on its root, or on a later comment from
        # anyone but the author: the reviewer's "still wrong" after a repair
        # push lands as a reply, not as a new thread. The comment that counts
        # is the newest one not by the author, read from the thread's tail
        # where the bundle carries one; a bundle from before the tail existed
        # carries only the last comment, and that is what it is read from.
        tail = [c for c in (thread.get("comments") or []) if isinstance(c, dict)]
        reviewer_tail = [
            c for c in tail if normalize_login(c.get("author")) != author_key
        ]
        if tail:
            reply = reviewer_tail[-1] if reviewer_tail else {}
        else:
            reply = {
                "author": thread.get("last_comment_author"),
                "created_at": thread.get("last_comment_at"),
                "url": thread.get("last_comment_url"),
            }
        last = parse_ts(reply.get("created_at"), f"threads[{index}].reply", problems)
        reviewer_replied = (
            newer(last) and normalize_login(reply.get("author")) != author_key
        )
        if not newer(created) and not reviewer_replied:
            continue
        findings = True
        stamp = f"created {show_ts(created)}"
        if reviewer_replied and not newer(created):
            # The reply is the finding here, so its URL rides along; the
            # reply-to id stays the root's, which is where a reply is posted.
            stamp = (
                f"created {show_ts(created)}, reply {show_ts(last)} "
                f"{show_or_unknown(reply.get('url'))}"
            )
        lines.append(
            f"thread {thread['id']} unresolved, {stamp}, "
            f"{severity(thread['root_body'])}, reply-to "
            f"{show_or_unknown(thread.get('root_comment_id'))} "
            f"{show_or_unknown(thread.get('root_url'))}"
        )

    for index, reaction in enumerate(bundle["reactions"]):
        created = parse_ts(
            reaction["created_at"], f"reactions[{index}].created_at", problems
        )
        if reaction["content"] != "+1" or not newer(created):
            continue
        if normalize_login(reaction["user"]) == author_key:
            continue
        approving = True
        lines.append(f"reaction +1 by {reaction['user']} {show_ts(created)}")

    for index, review in enumerate(bundle["reviews"]):
        submitted = parse_ts(
            review["submitted_at"], f"reviews[{index}].submitted_at", problems
        )
        state = review["state"]
        if state not in DECIDING_REVIEWS or not newer(submitted):
            continue
        if normalize_login(review["author"]) == author_key:
            continue
        if state == "CHANGES_REQUESTED":
            findings = True
        else:
            approving = True
        lines.append(
            f"review {state} by {review['author']} {show_ts(submitted)} "
            f"{show_or_unknown(review.get('url'))}"
        )

    for index, comment in enumerate(bundle["comments"]):
        created = parse_ts(
            comment["created_at"], f"comments[{index}].created_at", problems
        )
        if not newer(created):
            continue
        if normalize_login(comment["author"]) == author_key:
            continue
        if is_bare_approval(comment["body"]):
            continue
        findings = True
        lines.append(
            f"comment by {comment['author']} {show_ts(created)} "
            f"{show_or_unknown(comment.get('url'))}"
        )

    if problems:
        raise InputError(problems)

    if findings:
        state = "findings"
    elif approving:
        state = "cleared"
    else:
        state = "pending"
    return state, lines


def cmd_review(args):
    if not re.fullmatch(r"[1-9][0-9]*", args.pr):
        sys.stderr.write(f"run-state: review PR must be a number, got {args.pr!r}\n")
        return 3

    problems = []
    since = parse_ts(args.since, "--since", problems) if args.since else None
    if problems:
        for problem in problems:
            sys.stderr.write(f"run-state: {problem}\n")
        return 3

    try:
        if args.input:
            bundle = load_json(args.input, "bundle")
            check_bundle(bundle)
        else:
            bundle = gather(args.pr)
            check_bundle(bundle)
        author = args.author or bundle.get("author")
        state, lines = classify(bundle, since, author)
        if args.save:
            try:
                with open(args.save, "w", encoding="utf-8") as handle:
                    json.dump(bundle, handle, indent=2)
                    handle.write("\n")
            except OSError as e:
                raise InputError([f"--save {args.save}: {e.strerror or e}"])
    except (InputError, GhError) as e:
        for problem in getattr(e, "problems", [str(e)]):
            sys.stderr.write(f"run-state: {problem}\n")
        return 3

    print(state)
    for line in lines:
        print(line)
    return 0


def check_probe(probe):
    """Every field present. Null is allowed and reads as unknown.

    An absent field means the prose that gathers the probe skipped a command.
    Reading that as a false answers with a phase nobody probed for."""
    if not isinstance(probe, dict):
        raise InputError([f"probe: expected a JSON object, got {type(probe).__name__}"])
    problems = []
    for name, kind, allowed in PROBE_FIELDS:
        if name not in probe:
            problems.append(f"probe: missing field {name}")
            continue
        value = probe[name]
        if value is None:
            continue
        if kind == "bool" and not isinstance(value, bool):
            problems.append(f"probe: {name} is {value!r}, expected a boolean")
        elif kind == "int" and (isinstance(value, bool) or not isinstance(value, int)):
            problems.append(f"probe: {name} is {value!r}, expected an integer")
        elif kind == "enum" and value not in allowed:
            problems.append(
                f"probe: {name} is {value!r}, expected one of {', '.join(allowed)}"
            )
    if problems:
        raise InputError(problems)


def flag(probe, name):
    return bool(probe[name])


def count(probe, name):
    value = probe[name]
    return 0 if value is None else int(value)


def budget_stop(row):
    """Row `row`'s answer when review time has passed its budget.

    The probe carries only the verdict, so the reason names the command that
    prints both totals rather than the totals themselves."""
    return (
        "stop",
        f"row {row}: review time is over budget against build time; print "
        "`run-state.py budget --timing RUN_DIR/timing.log` for both totals and "
        "ask whether to stop here or raise the ratio, which appends "
        "`budget-raised <ratio>` to timing.log",
    )


def phase_of(probe):
    """The Resume table, in its own order, first match wins.

    One branch per row, even where two rows answer the same phase. Rows 8 and 9
    both land on Step 3 and rows 12 and 13 both on Step 5, at different points
    inside the step, and the reason line names the point. Folding two rows
    together loses it, and leaves the table in references/resume.md with no
    branch here to fail against."""
    pr_state = probe["pr_state"]
    review_state = probe["review_state"]
    if pr_state in ("MERGED", "CLOSED"):
        return "done", "row 1: the PR is " + pr_state + ", so offer cleanup and stop"
    # A null anywhere else is a probe that could not answer, and every row
    # below reads a null as "no": no branch, no run dir, no report. A transient
    # failed `git ls-remote` would then restart a run three steps in as fresh.
    # `pr_state` and `review_state` are the two fields where null is an answer
    # (no pull request yet), so they are exempt.
    unknown = [
        name
        for name, _, _ in PROBE_FIELDS
        if name not in ("pr_state", "review_state") and probe[name] is None
    ]
    if unknown:
        return (
            "stop",
            "unknown probe fields: " + ", ".join(unknown)
            + "; a null here would read as no, so gather them again per references/resume.md",
        )
    herdr = probe["herdr_agent_state"]
    branch_anywhere = flag(probe, "branch_local") or flag(probe, "branch_remote")
    wave_tasks = count(probe, "wave_tasks")
    wave_reports = count(probe, "wave_reports")
    every_wave_report = wave_tasks > 0 and wave_reports >= wave_tasks
    redteam_rounds = count(probe, "redteam_rounds")
    redteam_clean = redteam_rounds > 0 and not flag(probe, "redteam_last_failed")
    triage_rounds = count(probe, "triage_rounds")
    repair_reports = count(probe, "repair_reports")
    # The Nth round is the capped one, not the one after it: with the default
    # of 2, round 1 is repaired and round 2 is answered and queued (#159).
    max_review_rounds = count(probe, "max_review_rounds")
    at_review_cap = triage_rounds > 0 and triage_rounds >= max_review_rounds
    # Rows 10, 11, 16, and row 17's re-fire leg each start another review
    # cycle, and only those are gated. Rows past them publish, reply to, or
    # report on work already done, and stopping there would strand it. On
    # cambium #23/#26, about 50 min of build drew about 5 h of review.
    over_budget = flag(probe, "review_over_budget")

    if herdr == "working":
        return "wait", "row 2: the herdr agent is working; wait and re-probe"
    if herdr == "blocked":
        return "stop", "row 3: the herdr agent is blocked; show its UI and stop"
    # Step 5 item 2 rewrites base_sha after every proven rebase (#137), so a
    # base that has drifted from the live merge-base is a rebase nobody
    # recorded, and every review after it diffs other merged PRs as this
    # change. On cambium #78 the file held f08cc20 while the real merge-base
    # was 3d6209f. Row 12's state goes first: a rebase stopped on a conflict,
    # or finished by hand, is the one Step 5 item 2 is about to record.
    base_state = probe["base_sha_state"]
    if base_state in ("not-merge-base", "not-ancestor") and not (
        flag(probe, "conflict") or flag(probe, "rebase_in_progress")
    ):
        if base_state == "not-ancestor":
            return (
                "stop",
                "base_sha mismatch (not-ancestor): RUN_DIR/base_sha is not an ancestor "
                "of the branch, so a diff from it reads commits the branch never had; "
                "the default branch was rewritten or the file was edited by hand, so "
                "stop for a human",
            )
        return (
            "stop",
            "base_sha mismatch (not-merge-base): RUN_DIR/base_sha is not the live "
            "merge-base of origin/<DEFAULT> and the branch, so every later review would "
            "diff against a base the branch has left; if this run's own rebase finished "
            "before Step 5 item 2 rewrote the file, write git merge-base "
            "origin/<DEFAULT> issue-<N> to it and re-invoke, else stop for whoever "
            "rebased the branch",
        )
    if not branch_anywhere and not flag(probe, "run_dir"):
        return "0", "row 4: no branch anywhere and no run dir, so this issue is fresh"
    if flag(probe, "run_dir") and not branch_anywhere:
        # Step 0 writes plan.md's Waves table before Step 1 makes the branch,
        # so a stop between the two is a live run, not a dead one: the table
        # is the gate's own artifact, and archiving it re-ran the gate.
        if flag(probe, "has_waves"):
            return "0", "row 5: the gate ran but Step 1 never created the branch; resume at the confirmation, then Step 1"
        return "0", "row 5: a run dir with no branch anywhere; move it to closed/ first"
    if branch_anywhere and not flag(probe, "has_waves"):
        return "0", "row 6: the branch exists but plan.md has no ## Waves table; resume at the plan gate"
    # Step 1 ends by writing base_sha and baseline.txt, and every later gate
    # reads them. A run that stopped inside Step 1 has the branch and the Waves
    # table and none of the reports, which used to read as "resume at wave 0"
    # and dispatched workers with no fixed point and no baseline.
    if flag(probe, "has_waves") and not (flag(probe, "base_sha") and flag(probe, "baseline")):
        return "1", "row 7: the Waves table is written but Step 1 left no base_sha or baseline.txt; resume at Step 1"
    if flag(probe, "has_waves") and wave_reports < wave_tasks:
        # A commit past base_sha on an unreported task's owned paths is a
        # gated wave whose report is missing, not a half-written one. On
        # cambium #78 a filename glob read five committed waves as 0 of 5,
        # and this row's revert would have thrown them away.
        committed = count(probe, "wave_unreported_committed")
        if committed > 0:
            return (
                "stop",
                f"row 7: {wave_reports} of {wave_tasks} wave tasks count as reported, but "
                f"{committed} unreported task(s) own paths a commit in git log "
                "base_sha..HEAD touched; the reports and git log disagree, so stop "
                "rather than revert committed work",
            )
        return "2", f"row 7: {wave_reports} of {wave_tasks} wave tasks count as reported (a report, clean owned paths, and a gate marker, or a commit where no gated/ exists); resume at that wave"
    if every_wave_report and count(probe, "self_reviews") == 0:
        return "3", "row 8: every wave report is in and no self-review; resume at the code-review invocation"
    if count(probe, "self_reviews") > 0 and not flag(probe, "build_final"):
        return "3", "row 9: a self-review with no build-final report; resume at the fix dispatch"
    if flag(probe, "build_final") and redteam_rounds == 0:
        if over_budget:
            return budget_stop(10)
        return "4", "row 10: a build-final report with no red-team round yet"
    # A failed round owns the run until a later round is clean. Which way it
    # resumes turns on order, not on counts: a repair report that predates the
    # failed round is the code that round just refuted, and re-running the
    # round over it re-tests unchanged code. Two failed rounds in a row is
    # Step 4's stop, and a resume that kept cycling past it would never honor
    # the stop.
    if flag(probe, "build_final") and flag(probe, "redteam_last_failed"):
        if flag(probe, "redteam_failed_twice"):
            return "stop", "row 10: two red-team rounds in a row have NOT_REPRODUCED; stop and report with the evidence"
        if over_budget:
            return budget_stop(10)
        if flag(probe, "repair_after_last_round"):
            return "4", "row 10: the newest red-team round has NOT_REPRODUCED and a repair followed it; run round k+1"
        return "4", "row 10: the newest red-team round has NOT_REPRODUCED and no repair has followed it; dispatch the repair"
    # `ar_complete` reads Step 4's record of adversarial-review's final ledger
    # state, not its run directory: the directory exists from that skill's
    # preflight onward, and a review interrupted after preflight left one
    # behind that this row once took for a finished review.
    # `trigger_fired` is three-valued. A run that stopped after its clean
    # round file but before Step 4 wrote trigger.txt has no verdict, and a
    # bool read that as "no" and let row 13 publish a diff whose trigger was
    # never evaluated.
    trigger = probe["trigger_fired"]
    if redteam_clean and trigger == "absent":
        if over_budget:
            return budget_stop(11)
        return "4", "row 11: red-team is clean and trigger.txt is not written yet; resume at the trigger"
    if redteam_clean and trigger == "yes" and not flag(probe, "ar_complete"):
        if over_budget:
            return budget_stop(11)
        return "4", "row 11: trigger.txt says fired and adversarial-review has not finished"
    if flag(probe, "conflict") or flag(probe, "rebase_in_progress"):
        return "5", "row 12: a rebase conflict is in progress; resume at Step 5 item 1"
    # A review repair committed at Step 7 is also "ahead of origin" with a clean
    # build red-team behind it, and that belongs to row 17 (red-team the repair,
    # then push and reply), never to a fresh publish.
    if (
        redteam_clean
        and trigger != "absent"
        and triage_rounds == 0
        and (pr_state is None or flag(probe, "ahead_of_origin"))
    ):
        return "5", "row 13: red-team is clean, the trigger is recorded, no triage round yet, and the branch is unpublished or ahead of origin"
    # Step 8 pushes before it replies, so a stop between those two leaves rows
    # that still owe a reply under a review that now reads `pending`. Without
    # this guard the poll preempts row 17 and the old findings are never
    # answered.
    if (
        pr_state == "OPEN"
        and review_state == "pending"
        and count(probe, "triage_rows_unanswered") == 0
        and not flag(probe, "deferred_comment_needed")
    ):
        return "6", "row 14: the PR is open and no review has landed since the last push; keep polling"
    if (
        pr_state == "OPEN"
        and review_state == "findings"
        and not flag(probe, "triage_newer_than_since")
    ):
        return "6", "row 15: the PR has findings and no triage round newer than SINCE"
    # Counted totals cannot say whether the newest round was repaired: an
    # all-queued round writes no repair report on purpose, so one queued round
    # followed by a repaired one has two rounds and one report, and a count
    # comparison re-dispatches a repair that already landed.
    if (
        triage_rounds > 0
        and count(probe, "triage_inscope_rows") > 0
        and not flag(probe, "newest_repair_report")
    ):
        # A fresh review of new code nearly always finds something, so an
        # uncapped loop let P2 threads hold a lane in repair indefinitely. A
        # round at the cap is never repaired, so it gets no repair report and
        # would match this row forever if it answered Step 8 here; it falls
        # through to row 17's replies instead. Only an in-scope P0 or blocking
        # row stops it: queueing one ships a known blocker, and repairing it
        # breaks the cap, so that call goes to a human. The cap is checked
        # before the budget because a capped round starts no review cycle,
        # and a budget stop here stranded its replies.
        if at_review_cap:
            stop_rows = count(probe, "triage_stop_rows")
            if stop_rows > 0:
                return (
                    "stop",
                    f"row 16: the newest triage round is at the review round cap "
                    f"({triage_rounds} of {max_review_rounds}) and holds {stop_rows} "
                    "in-scope P0 or blocking row(s), which the cap never queues; stop and "
                    "report the blocker to a human",
                )
        elif over_budget:
            return budget_stop(16)
        else:
            return "7", "row 16: the newest triage round has in-scope rows and no repair report of its own"
    # Step 8 item 1's re-fire leg, ahead of the push. A repair is a candidate
    # for adversarial-review when its triage round held a P0, P1, or blocking
    # row, or when its own diff hits a money, authz, or schema trigger row: a
    # reviewer can label a real blocker P2 (#162). Step 8 item 1's reading
    # then settles it, and a `fired: no` there sets repair_ar_settled (#120).
    # One with neither gets the
    # reproducer and moves on. `repair_diff_triggers` reads the repair's diff
    # alone, since the whole branch already fired the trigger at Step 4.
    # The reason names the reproducer first: `repair_ar_settled` is false until
    # a file exists, which includes a stop before the reproducer ran.
    # Re-firing after every repair ran cambium #23/#26 to 7 cycles per lane,
    # because each fix drew a new advisory and the review never came back
    # empty. `repair_ar_settled` is also true where the repair's own trigger
    # re-evaluation said `fired: no`, so a P1 repair with no trigger-table hit
    # doesn't wait on a review nobody will run.
    if (
        pr_state == "OPEN"
        and flag(probe, "newest_repair_report")
        and (count(probe, "triage_blocking_rows") > 0 or flag(probe, "repair_diff_triggers"))
        and not flag(probe, "repair_ar_settled")
    ):
        if over_budget:
            return budget_stop(17)
        return (
            "8",
            "row 17: the repaired triage round held a P0, P1, or blocking row, "
            "or the repair's own diff hits a money, authz, or schema trigger row, "
            "and the repair's adversarial-review has not settled; resume at "
            "Step 8 item 1 from the reproducer where trigger-repair-<k>.txt is "
            "absent, else at the adversarial-review invocation",
        )
    # Post-PR only: Step 8 pushes and replies but never opens a pull request,
    # so a repair with no PR behind it belongs to row 10 (unverified) or row
    # 13 (clean), never here. The repair-report leg still stands alone: a
    # post-PR repair round may have no triage round of its own.
    # An owed deferred-findings comment reaches Step 8 on its own. A worker's
    # plan_concerns row lands in the queue at Step 4, before any triage round
    # or repair report exists, and a resume that required one of those first
    # matched no row at all and stranded the run.
    # A capped round reads as all-queued here: it has in-scope rows and, under
    # --max-review-rounds 1, no repair report anywhere, so a stop between the
    # deferred comment and the replies fell through to row 18 with replies owed.
    if pr_state == "OPEN" and (
        flag(probe, "deferred_comment_needed")
        or (
            (
                repair_reports > 0
                or (triage_rounds > 0 and count(probe, "triage_inscope_rows") == 0)
                or at_review_cap
            )
            and (flag(probe, "ahead_of_origin") or count(probe, "triage_rows_unanswered") > 0)
        )
    ):
        return (
            "8",
            "row 17: the deferred-findings comment is owed, or a repair report or an "
            "all-queued or capped triage round leaves work unpushed or a triage row unanswered",
        )
    if pr_state == "OPEN" and review_state == "cleared":
        return "done", "row 18: the PR is open and the review is cleared; print the final report"
    # `findings` never clears itself: resolving is the reviewer's act, and a
    # queue-only round pushes nothing, so SINCE never moves past the threads
    # it answered. Once rows 15 through 17 find nothing left to do, the run
    # is finished with this round and waits on the reviewer.
    if pr_state == "OPEN" and review_state == "findings" and flag(probe, "triage_newer_than_since"):
        return "done", "row 18: every finding is answered and the queue is published; print the final report and wait on the reviewer"
    return (
        "stop",
        "no resume row matches this probe; gather it again per references/resume.md",
    )


HERDR_STATES = ("working", "blocked", "idle", "done", "absent")

GIT_TIMEOUT = 60

# The installed sibling Step 0 already refuses to run without, found beside
# this skill rather than on PATH or relative to the caller's cwd.
MATCH_TRIGGERS = (
    Path(__file__).resolve().parents[2] / "adversarial-review" / "scripts" / "match-triggers.py"
)

# grep's [[:space:]] and \s, spelled out: Python's \s also matches Unicode
# spaces, which neither the vendored parser nor the old grep did.
_WS = "[ \t\r\f\v]"
WAVES_HEADING = re.compile(rf"^{_WS}*## Waves{_WS}*$")
TABLE_LINE = re.compile(rf"^{_WS}*\|")
NUMBERED_ROW = re.compile(rf"^{_WS}*\|{_WS}*[0-9]+{_WS}*\|")
FAILED_ROUND = re.compile(r'NOT_REPRODUCED|"holds": *false')
TRIAGE_ROUND = re.compile(r"round-([0-9]+)\.md")
SINCE_HEADING = re.compile(r"# Triage round .* since ([^ ]*)")
QUEUE_ROW = re.compile(r"^\| [0-9]+ \|")
SEPARATOR_CELL = re.compile(r":?-+:?")

GATHERERS = {}


class ProbeError(Exception):
    """One field could not be answered. `probe` prints it and writes null."""


class ProbeContext:
    """What every gatherer reads: RUN_DIR, the work tree, the issue, and the
    bundle. The tree is the worktree holding `issue-<N>`, found from ROOT."""

    def __init__(self, run_dir, tree, issue, bundle, author, herdr_state, review_state):
        self.run_dir = run_dir
        self.tree = tree
        self.issue = issue
        self.branch = f"issue-{issue}"
        self.bundle = bundle
        self.author = author
        self.herdr_state = herdr_state
        self.review_state = review_state
        self._remote = None

    def git(self, *args):
        return run_git(self.tree, *args)

    def path(self, *parts):
        return self.run_dir.joinpath(*parts)

    def git_ok(self, *args):
        """stdout of a git call that has to succeed, else ProbeError."""
        done = self.git(*args)
        if done.returncode != 0:
            raise ProbeError(git_failure(args, done))
        return done.stdout

    def branch_local(self):
        done = self.git("show-ref", "--verify", "--quiet", f"refs/heads/{self.branch}")
        if done.returncode in (0, 1):
            return done.returncode == 0
        raise ProbeError(git_failure(("show-ref",), done))

    def branch_remote(self):
        """The live remote's answer, asked once per probe. `ls-remote` exit 2
        is no such branch; any other failure, no network included, raises."""
        if self._remote is None:
            done = self.git("ls-remote", "--exit-code", "--heads", "origin", self.branch)
            if done.returncode == 0:
                self._remote = True
            elif done.returncode == 2:
                self._remote = False
            else:
                self._remote = ProbeError(git_failure(("ls-remote", "origin"), done))
        if isinstance(self._remote, ProbeError):
            raise self._remote
        return self._remote


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


def gatherer(name):
    def register(fn):
        GATHERERS[name] = fn
        return fn

    return register


def read_text(path):
    with open(path, encoding="utf-8", errors="surrogateescape") as handle:
        return handle.read()


def read_or_none(path):
    """The file's text, or None where it does not exist. Any other read
    failure raises: a file that exists and can't be read is not an absent one."""
    try:
        return read_text(path)
    except FileNotFoundError:
        return None


def first_line(path):
    text = read_or_none(path)
    return None if text is None else text.split("\n", 1)[0]


def chomp(text):
    """What `$(cat FILE)` gives: trailing newlines gone, nothing else."""
    return text.rstrip("\n")


def find_count(directory, pattern):
    """`find DIR -name PATTERN | wc -l`: entries at any depth, 0 with no DIR."""
    total = 0
    for _, dirs, files in os.walk(directory):
        total += sum(1 for name in dirs + files if fnmatch.fnmatchcase(name, pattern))
    return total


def _round_number(name):
    digits = re.findall(r"[0-9]+", name)
    return int(digits[-1]) if digits else -1


def newest_by_mtime(directory, pattern):
    """Entries of DIR matching PATTERN, newest first, as `ls -t` orders them,
    with a tie going to the higher round number. For the fields whose
    resume.md row reads the newest round by file time."""
    try:
        names = [n for n in os.listdir(directory) if fnmatch.fnmatchcase(n, pattern)]
    except FileNotFoundError:
        return []
    paths = [directory / n for n in names]
    return sorted(
        paths, key=lambda p: (p.stat().st_mtime_ns, _round_number(p.name)), reverse=True
    )


def newest_round_by_k(directory):
    """`(k, path)` of the highest-numbered `round-<k>.md`, or None.

    By number, never by file time: Step 8 writes reply URLs into a round
    after the push that answers it, so an answered earlier round can be the
    newest file on disk (#139)."""
    try:
        names = os.listdir(directory)
    except FileNotFoundError:
        return None
    rounds = []
    for name in names:
        match = TRIAGE_ROUND.fullmatch(name)
        if match:
            rounds.append((int(match.group(1)), match.group(1), directory / name))
    if not rounds:
        return None
    _, k, path = max(rounds)
    return k, path


def triage_table(path):
    """`(columns, rows)` of a triage round's table: header names to field
    index, and each body row's fields split on `|`.

    Escaped `\\|` pipes drop before the split so a quoted `\\|\\|` can't shift a
    column. The first pipe-table line is the header, the separator row is
    skipped, and the table ends at the first non-table line after it."""
    columns = None
    rows = []
    for line in read_text(path).split("\n"):
        line = line.replace("\\|", "")
        if not TABLE_LINE.match(line):
            if columns is not None:
                break
            continue
        fields = line.split("|")
        if columns is None:
            columns = {}
            for index, field in enumerate(fields):
                columns.setdefault(squeeze(field), index)
            continue
        cells = [squeeze(f) for f in fields[1:]]
        if cells and all(not c or SEPARATOR_CELL.fullmatch(c) for c in cells):
            continue
        rows.append(fields)
    return columns or {}, rows


def squeeze(text):
    """A cell with its spaces and tabs dropped, as the old awk compared it:
    `in scope` reads `inscope`, and a padded `P0` reads `P0`."""
    return re.sub(r"[ \t]", "", text)


def cell(fields, index):
    return squeeze(fields[index]) if index < len(fields) else ""


def waves_rows(ctx):
    """The `## Waves` table's lines and no others. The table ends at its first
    non-table line, where the vendored parser ends it."""
    text = read_or_none(ctx.path("plan.md"))
    if text is None:
        return []
    rows = []
    in_section = False
    started = False
    for line in text.split("\n"):
        if WAVES_HEADING.match(line):
            in_section = True
            continue
        if not in_section:
            continue
        if TABLE_LINE.match(line):
            started = True
            rows.append(line)
        elif started:
            break
    return rows


def wave_tasks_rows(ctx):
    """`(wave, task, owned paths)` per task row, as the vendored parser reads
    the first three cells: each loses only its outer spaces and tabs, so
    `my task` and `docs/my notes.md` keep theirs, and paths split on commas."""
    tasks = []
    for line in waves_rows(ctx):
        cells = [c.strip(" \t") for c in line.split("|")]
        wave = cells[1] if len(cells) > 1 else ""
        task = cells[2] if len(cells) > 2 else ""
        owned = re.sub(r"[ \t]*,[ \t]*", ",", cells[3] if len(cells) > 3 else "")
        if re.fullmatch(r"[0-9]+", wave) and task:
            tasks.append((wave, task, owned))
    return tasks


def owned_paths(owned):
    # Bash's IFS=, split: a trailing comma ends the list rather than naming an
    # empty path.
    parts = owned.split(",")
    if parts and parts[-1] == "":
        parts.pop()
    return parts


def reported(ctx, wave, task):
    return (
        ctx.path("reports", f"{wave}-{task}.json").is_file()
        or ctx.path("reports", f"{task}.json").is_file()
    )


@gatherer("herdr_agent_state")
def g_herdr_agent_state(ctx):
    """herdr's answer for the issue agent, passed in by `--herdr-state`.
    Rows 2 and 3 outrank every RUN_DIR row: an agent still `working` is
    waited on rather than duplicated by a second dispatch into its tree."""
    return ctx.herdr_state


@gatherer("branch_local")
def g_branch_local(ctx):
    """`refs/heads/issue-<N>` exists in the repo."""
    return ctx.branch_local()


@gatherer("branch_remote")
def g_branch_remote(ctx):
    """origin has `issue-<N>`, asked of the live remote. No origin, or no
    answer from it, is null rather than a no."""
    return ctx.branch_remote()


@gatherer("run_dir")
def g_run_dir(ctx):
    """RUN_DIR exists. Read, never created: a probe that made it would turn a
    fresh issue into row 5's dead run."""
    return ctx.run_dir.is_dir()


@gatherer("base_sha")
def g_base_sha(ctx):
    """Step 1's last write, with `baseline`. Row 7 sends a run missing either
    back to Step 1 rather than dispatching workers against no fixed point."""
    return ctx.path("base_sha").is_file()


@gatherer("baseline")
def g_baseline(ctx):
    """`baseline.txt` exists; see `base_sha`."""
    return ctx.path("baseline.txt").is_file()


def default_branch(ctx):
    """origin's default branch, from the live remote's HEAD symref.

    SKILL.md resolves DEFAULT with `gh repo view`, which `probe` never calls;
    a GitHub remote's HEAD names the same branch."""
    out = ctx.git_ok("ls-remote", "--symref", "origin", "HEAD")
    for line in out.split("\n"):
        match = re.match(r"ref: refs/heads/(\S+)\tHEAD$", line)
        if match:
            return match.group(1)
    raise ProbeError("git ls-remote --symref origin HEAD: origin names no default branch")


@gatherer("base_sha_state")
def g_base_sha_state(ctx):
    """`current` where the file holds the live merge-base of origin/<DEFAULT>
    and the branch; `not-merge-base` where it is an ancestor but not that
    merge-base, which an unrecorded rebase leaves; `not-ancestor` where the
    branch never had it; `absent` with no file, or no issue branch locally or
    on origin, which rows 4 through 7 own. Null where the branch survives only
    on origin, since no row owns that run, and where git can't answer. An empty
    file is null too: Step 5 item 2 writes only once `git merge-base`
    resolves, so an empty file is a write that went wrong (#137). It reads
    refs rather than HEAD, so a rebase stopped mid-way still reads `current`."""
    base_file = ctx.path("base_sha")
    if not base_file.is_file():
        return "absent"
    if not ctx.branch_local():
        # ls-remote exit 2 is no such branch; the branch on origin alone, or
        # an origin that can't answer, is a run no row owns.
        try:
            return "absent" if ctx.branch_remote() is False else None
        except ProbeError:
            return None
    base = chomp(read_text(base_file))
    if not base:
        return None
    done = ctx.git("merge-base", "--is-ancestor", base, ctx.branch)
    if done.returncode == 1:
        return "not-ancestor"
    if done.returncode != 0:
        raise ProbeError(git_failure(("merge-base", "--is-ancestor"), done))
    default = default_branch(ctx)
    merge_base = chomp(ctx.git_ok("merge-base", f"origin/{default}", ctx.branch))
    return "current" if merge_base == base else "not-merge-base"


@gatherer("pr_state")
def g_pr_state(ctx):
    """The bundle's `state`; null with no bundle, which phase reads as no
    pull request yet."""
    return None if ctx.bundle is None else ctx.bundle["state"]


@gatherer("review_state")
def g_review_state(ctx):
    """`review`'s answer on an OPEN bundle against SINCE; null with no bundle,
    and null on a MERGED or CLOSED one, which row 1 ends before any row reads
    this. Scored before any gatherer runs, since an OPEN bundle that can't be
    scored exits 3 rather than reading as no pull request."""
    return ctx.review_state


@gatherer("has_waves")
def g_has_waves(ctx):
    """plan.md has a `## Waves` heading, whitespace allowed on either side,
    because the vendored parser strips the line before comparing, and a
    column-1 match sent an indented table back to row 6's plan gate on every
    invocation."""
    text = read_or_none(ctx.path("plan.md"))
    return text is not None and any(WAVES_HEADING.match(l) for l in text.split("\n"))


@gatherer("wave_tasks")
def g_wave_tasks(ctx):
    """Numbered rows of the Waves table and no other. A cut that ran to the
    next `## ` heading counted a numbered row under a `### ` heading inside the
    section. Whitespace-tolerant inside the row, for a compact
    `|0|one|a.py|sonnet|done||`, and ahead of it, for an indented table."""
    return sum(1 for line in waves_rows(ctx) if NUMBERED_ROW.match(line))


@gatherer("wave_reports")
def g_wave_reports(ctx):
    """Tasks, not files, that count as reported: a report under either name
    Step 2 writes, clean owned paths, and gate evidence, which is Step 3's
    `gated/<wave>-<task>` marker, or, on a run with no `gated/` directory, a
    commit in `git log <base_sha>..HEAD` on its owned paths. A report is the
    worker's word and never says the gate ran; dirty owned paths say it did
    not. A run that writes markers counts only markers, since an earlier
    wave's commit on a shared path would pass a later task whose gate never
    ran. A filename glob read five committed waves on cambium #78 as 0 of 5.
    A git status or log that fails is null."""
    base = chomp(read_or_none(ctx.path("base_sha")) or "")
    has_gated = ctx.path("gated").is_dir()
    counted = 0
    failures = []
    for wave, task, owned in wave_tasks_rows(ctx):
        if not reported(ctx, wave, task):
            continue
        paths = owned_paths(owned)
        if owned:
            done = ctx.git("status", "--porcelain", "--untracked-files=all", "--", *paths)
            if done.returncode != 0:
                failures.append(git_failure(("status",), done))
                continue
            if chomp(done.stdout):
                continue
        if ctx.path("gated", f"{wave}-{task}").is_file():
            counted += 1
            continue
        # With no range or no paths there is nothing for git log to read, and
        # git log with no paths reads the whole tree.
        if not base or not owned or has_gated:
            continue
        done = ctx.git("log", "--format=%H", f"{base}..HEAD", "--", *paths)
        if done.returncode != 0:
            failures.append(git_failure(("log",), done))
        elif chomp(done.stdout):
            counted += 1
    if failures:
        raise ProbeError(failures[0])
    return counted


@gatherer("wave_unreported_committed")
def g_wave_unreported_committed(ctx):
    """Tasks `wave_reports` does not count, with no report or a report beside
    dirty owned paths, whose owned paths a commit in `git log
    <base_sha>..HEAD` touched. Only the orchestrator commits, so that is
    committed work whose report is missing, and row 7 stops on it rather than
    reverting. A reported task with clean paths is skipped: with no gate
    evidence it has no commit either. A missing or empty `base_sha` is 0, since
    Step 1 writes it before any wave can commit, which keeps row 7's Step 1
    leg reachable. A base that doesn't resolve is null."""
    base_file = ctx.path("base_sha")
    if not (base_file.exists() and base_file.stat().st_size > 0):
        return 0
    base = chomp(read_text(base_file))
    counted = 0
    failures = []
    for wave, task, owned in wave_tasks_rows(ctx):
        if not owned:
            continue
        paths = owned_paths(owned)
        if reported(ctx, wave, task):
            done = ctx.git("status", "--porcelain", "--untracked-files=all", "--", *paths)
            if done.returncode != 0:
                failures.append(git_failure(("status",), done))
                continue
            if not chomp(done.stdout):
                continue
        if not base:
            failures.append("base_sha holds only newlines")
            continue
        done = ctx.git("log", "--format=%H", f"{base}..HEAD", "--", *paths)
        if done.returncode != 0:
            failures.append(git_failure(("log",), done))
        elif chomp(done.stdout):
            counted += 1
    if failures:
        raise ProbeError(failures[0])
    return counted


@gatherer("self_reviews")
def g_self_reviews(ctx):
    """`review/self-*.md` files."""
    return find_count(ctx.path("review"), "self-*.md")


@gatherer("build_final")
def g_build_final(ctx):
    """`reports/build-final.json` exists."""
    return ctx.path("reports", "build-final.json").is_file()


@gatherer("redteam_rounds")
def g_redteam_rounds(ctx):
    """`redteam/round-*.json` files."""
    return find_count(ctx.path("redteam"), "round-*.json")


def round_failed(path):
    return bool(FAILED_ROUND.search(read_text(path)))


@gatherer("redteam_last_failed")
def g_redteam_last_failed(ctx):
    """The newest round, by file time, holds a NOT_REPRODUCED claim or a
    `left_checks` entry with `holds` false, which routes the same way. The
    newest only: an earlier round's failures are why a later round exists."""
    rounds = newest_by_mtime(ctx.path("redteam"), "round-*.json")
    return bool(rounds) and round_failed(rounds[0])


@gatherer("redteam_failed_twice")
def g_redteam_failed_twice(ctx):
    """The two newest rounds both failed. Step 4 stops after two failed rounds,
    and row 10 has to honor that stop rather than start a third cycle."""
    rounds = newest_by_mtime(ctx.path("redteam"), "round-*.json")[:2]
    return sum(1 for path in rounds if round_failed(path)) == 2


@gatherer("repair_after_last_round")
def g_repair_after_last_round(ctx):
    """The newest repair report of either kind is newer than the newest
    red-team round. Order, not count: a repair older than the failed round is
    the code that round refuted. A tie goes to the round, as `ls -t` sorts it
    ahead of the reports on equal times."""
    candidates = [
        (p.stat().st_mtime_ns, 0, p)
        for p in newest_by_mtime(ctx.path("reports"), "redteam-repair-*.json")
        + newest_by_mtime(ctx.path("reports"), "repair-*.json")
    ] + [(p.stat().st_mtime_ns, 1, p) for p in newest_by_mtime(ctx.path("redteam"), "round-*.json")]
    if not candidates:
        return False
    return max(candidates, key=lambda c: (c[0], c[1]))[1] == 0


@gatherer("trigger_fired")
def g_trigger_fired(ctx):
    """`yes`, `no`, or `absent` from `redteam/trigger.txt`'s first line, exactly.
    Three values, because a missing file is not a `no`: a run that stopped
    between its clean round and the trigger never evaluated it, and row 13
    must not publish it."""
    line = first_line(ctx.path("redteam", "trigger.txt"))
    return {"fired: yes": "yes", "fired: no": "no"}.get(line, "absent")


@gatherer("ar_complete")
def g_ar_complete(ctx):
    """`redteam/ar-state.txt` holds `UNVERIFIED: 0`. Step 4 writes it from
    `ledger.py state` after reading the report, so it exists only for a review
    that finished. The run directory under `.adversarial-review/runs/` is not
    the signal: it exists from preflight onward."""
    text = read_or_none(ctx.path("redteam", "ar-state.txt"))
    return text is not None and "UNVERIFIED: 0" in text


@gatherer("conflict")
def g_conflict(ctx):
    """`conflict.txt` exists. Step 5 item 2 removes it once the rebase is
    proven, so a marker with no rebase in progress is a run that stopped
    between items 1 and 2."""
    return ctx.path("conflict.txt").is_file()


@gatherer("rebase_in_progress")
def g_rebase_in_progress(ctx):
    """A rebase-merge or rebase-apply directory exists in the tree's git dir,
    resolved through `--git-path`, because in a linked worktree the
    hardcoded spelling under `.git/` does not exist. A relative answer is
    relative to the tree, not to the caller's cwd."""
    for name in ("rebase-merge", "rebase-apply"):
        where = Path(chomp(ctx.git_ok("rev-parse", "--git-path", name)))
        if not where.is_absolute():
            where = ctx.tree / where
        if where.is_dir():
            return True
    return False


@gatherer("ahead_of_origin")
def g_ahead_of_origin(ctx):
    """The branch has commits `origin/issue-<N>` lacks; where origin has no
    such branch, commits past BASE_SHA. No local branch has nothing ahead,
    and no base_sha has no fixed point to count from, so both are false."""
    if not ctx.branch_local():
        return False
    if ctx.branch_remote():
        spec = f"origin/{ctx.branch}..{ctx.branch}"
    else:
        base = chomp(read_or_none(ctx.path("base_sha")) or "")
        if not base:
            return False
        spec = f"{base}..{ctx.branch}"
    return int(chomp(ctx.git_ok("rev-list", "--count", spec))) > 0


@gatherer("triage_rounds")
def g_triage_rounds(ctx):
    """`triage/round-*.md` files."""
    return find_count(ctx.path("triage"), "round-*.md")


@gatherer("triage_newer_than_since")
def g_triage_newer_than_since(ctx):
    """The newest round, by its number k, was triaged against the SINCE now in
    `pushed_at`: its first line's recorded `since` equals `pushed_at` as a
    string. Never the file time: Step 8 writes reply URLs into a round after
    the push, so a file-time check read every answered round as current, and
    on PR #134 a P0 posted after the replies resumed as done (#139). Line 1
    alone, since a quoted finding further down can look like a heading. No
    round is false; a heading with no `since`, or no `pushed_at`, is null,
    because that round can't say which push it answered."""
    newest = newest_round_by_k(ctx.path("triage"))
    if newest is None:
        return False
    match = SINCE_HEADING.fullmatch(first_line(newest[1]) or "")
    recorded = match.group(1) if match else ""
    pushed = chomp(read_or_none(ctx.path("pushed_at")) or "")
    if not recorded or not pushed:
        return None
    return recorded == pushed


def newest_round_table(ctx, by_k):
    """The newest triage round's table, or None with no round."""
    if by_k:
        newest = newest_round_by_k(ctx.path("triage"))
        return None if newest is None else triage_table(newest[1])
    rounds = newest_by_mtime(ctx.path("triage"), "round-*.md")
    return triage_table(rounds[0]) if rounds else None


@gatherer("triage_inscope_rows")
def g_triage_inscope_rows(ctx):
    """Rows of the newest round, by number, whose Scope cell begins `in scope`.
    A capped round's `in scope; queued: review round cap reached (N)` counts,
    and row 17 reads that round as all-queued anyway. No Scope column is null."""
    table = newest_round_table(ctx, by_k=True)
    if table is None:
        return 0
    columns, rows = table
    if "Scope" not in columns:
        return None
    return sum(1 for r in rows if cell(r, columns["Scope"]).startswith("inscope"))


@gatherer("repair_reports")
def g_repair_reports(ctx):
    """`reports/repair-*.json`: Step 7's triage repairs only. Step 4's are
    `redteam-repair-<k>.json` and don't match, which keeps a build repair from
    reading as a triage round's."""
    return find_count(ctx.path("reports"), "repair-*.json")


@gatherer("newest_repair_report")
def g_newest_repair_report(ctx):
    """`reports/repair-<k>.json` exists for the newest round k. Row 16 reads
    this rather than comparing counts, because an all-queued round writes no
    repair report and the counts drift apart."""
    newest = newest_round_by_k(ctx.path("triage"))
    return newest is not None and ctx.path("reports", f"repair-{newest[0]}.json").is_file()


URL = re.compile(r"https?://")


@gatherer("triage_rows_unanswered")
def g_triage_rows_unanswered(ctx):
    """Rows, across every round, whose Reply cell holds no URL. Not cut off at
    SINCE: Step 8 pushes before it replies, so the rows it owes are always
    older than the push that answered them. A round with no Reply column is
    null, since it can't say which rows were answered."""
    try:
        names = sorted(n for n in os.listdir(ctx.path("triage")) if fnmatch.fnmatchcase(n, "round-*.md"))
    except FileNotFoundError:
        return 0
    total = 0
    for name in names:
        columns, rows = triage_table(ctx.path("triage", name))
        if "Reply" not in columns:
            return None
        index = columns["Reply"]
        total += sum(1 for r in rows if not (index < len(r) and URL.search(r[index])))
    return total


@gatherer("deferred_comment_needed")
def g_deferred_comment_needed(ctx):
    """Some `queue.md` row is missing, whole, from the author's `## Deferred
    findings` comment. The whole row, because a Status moved from `queued` to
    `filed #M` is a row the comment no longer carries: comparing Sources alone
    missed that, and testing for the heading alone missed a later round's
    rows. True with no comment, false with no queue rows, and false with no
    bundle, where there is no pull request; null there would stop every
    pre-PR resume, a fresh issue included."""
    if ctx.bundle is None:
        return False
    queue = read_or_none(ctx.path("queue.md"))
    rows = [l for l in (queue or "").split("\n") if QUEUE_ROW.match(l)]
    if not rows:
        return False
    author = normalize_login(ctx.author)
    carried = []
    seen_heading = False
    # The heading opens the section for good, across later comments too, as
    # the awk over the concatenated bodies read it.
    for comment in ctx.bundle["comments"]:
        if normalize_login(comment.get("author")) != author:
            continue
        body = comment.get("body") if isinstance(comment.get("body"), str) else ""
        for line in body.split("\n"):
            if line.startswith("## Deferred findings"):
                seen_heading = True
            if seen_heading:
                carried.append(line)
    return any(not any(row in line for line in carried) for row in rows)


def count_rows(table, severities, need_scope):
    if table is None:
        return 0
    columns, rows = table
    if "Severity" not in columns or (need_scope and "Scope" not in columns):
        return None
    total = 0
    for r in rows:
        if cell(r, columns["Severity"]) not in severities:
            continue
        if need_scope and not cell(r, columns["Scope"]).startswith("inscope"):
            continue
        total += 1
    return total


@gatherer("triage_blocking_rows")
def g_triage_blocking_rows(ctx):
    """Rows of the newest round, by file time, whose Severity cell is P0, P1,
    or blocking. The cell and nothing else, because a quoted finding can say
    "P1" on a row the reviewer marked lower. No Severity column is null
    rather than 0; no round is 0."""
    return count_rows(newest_round_table(ctx, by_k=False), ("P0", "P1", "blocking"), False)


@gatherer("max_review_rounds")
def g_max_review_rounds(ctx):
    """The `--max-review-rounds` value Step 0 wrote, and 2 with no file, so a
    run started before the flag existed is capped at the default rather than
    stopped on a field nobody could have written."""
    text = read_or_none(ctx.path("max_review_rounds"))
    if text is None:
        return 2
    try:
        return int(text.strip())
    except ValueError:
        raise ProbeError(f"max_review_rounds holds {text.strip()!r}, not a number")


@gatherer("triage_stop_rows")
def g_triage_stop_rows(ctx):
    """In-scope rows of the newest round, by file time, whose Severity is P0
    or blocking. Narrower than `triage_blocking_rows` because a capped round
    holding P1 rows has to reach Step 8, and in-scope only because the cap
    queues only in-scope rows. No Severity or no Scope column is null."""
    return count_rows(newest_round_table(ctx, by_k=False), ("P0", "blocking"), True)


@gatherer("repair_ar_settled")
def g_repair_ar_settled(ctx):
    """For the newest round k, `redteam/trigger-repair-<k>.txt` starts
    `fired: no` or `redteam/ar-state-repair-<k>.txt` holds `UNVERIFIED: 0`.
    The repair's own files, apart from Step 4's, which record the build's
    review. False with neither."""
    newest = newest_round_by_k(ctx.path("triage"))
    if newest is None:
        return False
    k = newest[0]
    if first_line(ctx.path("redteam", f"trigger-repair-{k}.txt")) == "fired: no":
        return True
    text = read_or_none(ctx.path("redteam", f"ar-state-repair-{k}.txt"))
    return text is not None and "UNVERIFIED: 0" in text


@gatherer("review_over_budget")
def g_review_over_budget(ctx):
    """`budget`'s verdict on `timing.log`, with no `--now`: a crashed step's
    open start closes at the last stamp the run recorded, so the hours it sat
    dead stay out. No log is false; a malformed log is null rather than under
    budget."""
    try:
        text = read_text(ctx.path("timing.log"))
    except FileNotFoundError:
        text = ""
    try:
        return budget_over(text)[2]
    except InputError as e:
        raise ProbeError("; ".join(e.problems))


@gatherer("repair_diff_triggers")
def g_repair_diff_triggers(ctx):
    """The repair's own diff, from the `repair-base-<k>` SHA Step 7 recorded to
    HEAD, hits trigger row 1, 2, or 4 (money, authz, schema), since a reviewer
    can label a real blocker P2. The repair's diff and never the branch's:
    re-reading the branch after every repair re-fired every repair, the loop
    #151 removed. No base file is false. A base no longer an ancestor of HEAD
    is false too, since a rebase after Step 8 item 1 orphans it and a diff from
    it reads upstream lines as the repair's (#137). A diff or matcher failure
    is null, never a quiet false."""
    newest = newest_round_by_k(ctx.path("triage"))
    base_file = ctx.path("redteam", f"repair-base-{newest[0] if newest else ''}")
    if not base_file.is_file():
        return False
    base = chomp(read_text(base_file))
    if ctx.git("merge-base", "--is-ancestor", base, "HEAD").returncode == 1:
        return False
    diff = ctx.git("diff", f"{base}..HEAD")
    if diff.returncode != 0:
        raise ProbeError(git_failure(("diff",), diff))
    if not MATCH_TRIGGERS.is_file():
        raise ProbeError(f"no matcher at {MATCH_TRIGGERS}")
    matched = subprocess.run(
        [sys.executable, str(MATCH_TRIGGERS), "rows", "--only", "1,2,4"],
        input=chomp(diff.stdout) + "\n",
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="surrogateescape",
        timeout=GIT_TIMEOUT,
    )
    if matched.returncode != 0:
        raise ProbeError(f"match-triggers.py: exit {matched.returncode}")
    return bool(chomp(matched.stdout))


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
    for line in done.stdout.split("\n"):
        if line.startswith("worktree "):
            current = line[len("worktree "):]
        elif line == f"branch refs/heads/{branch}" and current:
            return Path(current), None
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


def probe_since(run_dir, root, branch):
    """SINCE as SKILL.md defines it: `pushed_at`, else the committer date of
    the branch head. `(moment, problems)`; a None moment is no SINCE at all.

    Only an absent `pushed_at` falls back. One that exists but is empty,
    unreadable, or not a timestamp is a damaged cutoff: falling back to the
    commit date read a `garbage` marker beside a 13:00 commit as a 13:00
    cutoff, and a 12:00 finding scored `pending` (PR #177 review)."""
    problems = []
    try:
        pushed = read_or_none(run_dir / "pushed_at")
    except OSError as e:
        return None, [f"pushed_at: {e.strerror or e}"]
    if pushed is not None:
        moment = parse_ts(chomp(pushed), "pushed_at", problems)
        return (moment, []) if moment is not None else (None, problems)
    problems.append("no pushed_at")
    done = run_git(root, "log", "-1", "--format=%cI", f"refs/heads/{branch}")
    if done.returncode == 0 and chomp(done.stdout):
        moment = parse_ts(chomp(done.stdout), f"{branch} committer date", problems)
        if moment is not None:
            return moment, []
    problems.append(f"no {branch} branch to read a committer date from")
    return None, problems


def probe_field_ok(kind, allowed, value):
    if value is None:
        return True
    if kind == "bool":
        return isinstance(value, bool)
    if kind == "int":
        return isinstance(value, int) and not isinstance(value, bool)
    return value in allowed


def cmd_probe(args):
    def usage(problems):
        for problem in problems:
            sys.stderr.write(f"run-state: probe: {problem}\n")
        return 3

    names = [name for name, _, _ in PROBE_FIELDS]
    missing = [n for n in names if n not in GATHERERS]
    extra = [n for n in GATHERERS if n not in names]
    if missing or extra:
        return usage(
            [f"no gatherer for {n}" for n in missing]
            + [f"a gatherer for {n}, which PROBE_FIELDS does not name" for n in extra]
        )
    if not re.fullmatch(r"[1-9][0-9]*", args.issue):
        return usage([f"--issue must be a number, got {args.issue!r}"])
    herdr_state = args.herdr_state
    if herdr_state is None:
        # Under HERDR a defaulted `absent` skips row 2's wait and dispatches a
        # second agent into a tree one is still working in.
        if os.environ.get("HERDR_ENV") == "1":
            return usage(["HERDR_ENV=1 but no --herdr-state; read the issue agent's state from herdr and pass it"])
        herdr_state = "absent"
    root = Path(args.root).absolute()
    try:
        inside = run_git(root, "rev-parse", "--is-inside-work-tree")
    except (OSError, subprocess.TimeoutExpired) as e:
        return usage([f"--root {args.root}: {e}"])
    if inside.returncode != 0 or chomp(inside.stdout) != "true":
        return usage([f"--root {args.root} is not a git work tree"])
    run_dir = Path(args.run_dir).absolute()
    branch = f"issue-{args.issue}"

    bundle = None
    review_state = None
    if args.pr_bundle:
        try:
            bundle = load_json(args.pr_bundle, "bundle")
            check_bundle(bundle)
        except InputError as e:
            return usage(e.problems)
        if "state" not in bundle:
            return usage(["bundle: missing state; save it with this script's review --save"])
    author = args.author or (bundle or {}).get("author")
    # A merged or closed PR is row 1 whatever else is missing, and cleanup can
    # leave no pushed_at and no branch, so its review is never scored: `phase`
    # reads row 1 before anything reads review_state (PR #177 review).
    if bundle is not None and bundle["state"] == "OPEN":
        since, problems = probe_since(run_dir, root, branch)
        if since is None:
            return usage([f"review_state: no SINCE to score the bundle against: {'; '.join(problems)}"])
        try:
            review_state, _ = classify(bundle, since, author)
        except InputError as e:
            return usage(e.problems)

    tree, problem = find_tree(
        root, branch, terminal=bundle is not None and bundle["state"] in ("MERGED", "CLOSED")
    )
    if tree is None:
        return usage([problem])
    ctx = ProbeContext(
        run_dir, tree, args.issue, bundle, author, herdr_state, review_state
    )
    probe = {}
    for name, kind, allowed in PROBE_FIELDS:
        try:
            value = GATHERERS[name](ctx)
        except Exception as e:  # one field's failure is that field's null
            sys.stderr.write(f"run-state: probe: {name}: {e}\n")
            value = None
        if not probe_field_ok(kind, allowed, value):
            sys.stderr.write(f"run-state: probe: {name}: gathered {value!r}, not a {kind}\n")
            value = None
        probe[name] = value
    print(json.dumps(probe, indent=2))
    return 0


def _overlap_seconds(start, end, spans):
    """Seconds of [start, end) that any of `spans` covers. `spans` is sorted
    and non-overlapping, so no second is subtracted twice."""
    covered = 0.0
    for span_start, span_end in spans:
        low = max(start, span_start)
        high = min(end, span_end)
        if high > low:
            covered += (high - low).total_seconds()
    return covered


def _merge(spans):
    merged = []
    for start, end in sorted(spans):
        if merged and start <= merged[-1][1]:
            merged[-1] = (merged[-1][0], max(merged[-1][1], end))
        else:
            merged.append((start, end))
    return merged


def parse_timing_log(text, label, now=None):
    """`(build_seconds, review_seconds, raised_ratio)` from a timing.log's text.

    `raised_ratio` is the last `budget-raised <ratio>` line's value, or None
    if the log never raised it—the caller decides what it yields to. An
    unpaired start closes at `now` when given, else at the log's latest
    stamp. Every malformed line is collected before raising, same discipline
    as `check_bundle`: a hand-edited log is usually wrong in more than one
    place, and one problem per run turns that into one round trip per typo.
    """
    problems = []
    events = []
    moments = []
    raised = None
    for line_no, raw_line in enumerate(text.splitlines(), start=1):
        line = raw_line.strip()
        if not line:
            continue
        at = f"{label}:{line_no}"
        parts = line.split()
        if parts[0] == "budget-raised":
            if len(parts) != 2:
                problems.append(f"{at}: 'budget-raised' takes exactly one value: {raw_line!r}")
                continue
            try:
                raised = float(parts[1])
            except ValueError:
                problems.append(f"{at}: budget-raised value {parts[1]!r} is not a number")
            continue
        if len(parts) != 3:
            problems.append(f"{at}: expected '<phase> <start|end> <timestamp>': {raw_line!r}")
            continue
        phase, kind, ts_raw = parts
        if phase not in TIMING_LABELS:
            problems.append(f"{at}: unknown phase {phase!r}")
            continue
        if kind not in ("start", "end"):
            problems.append(f"{at}: expected 'start' or 'end', got {kind!r}")
            continue
        moment = parse_ts(ts_raw, at, problems)
        if moment is None:
            continue
        events.append((phase, kind, moment))
        moments.append(moment)
    if problems:
        raise InputError(problems)

    # A phase may run many cycles, so each label gets its own FIFO of open
    # starts rather than a single pending slot: "next end of same label"
    # pairs the earliest unclosed start, not the most recent.
    open_starts = {}
    intervals = {}
    seen = None
    for phase, kind, moment in events:
        if kind == "start" and phase != "poll":
            # Steps run one at a time, so a new step's start ends any other
            # step a crash left open. The resume table often jumps a run to a
            # different step than the one that crashed, and SKILL.md's
            # close-first rule only reaches the label about to start: a `3`
            # left open grew build with the clock and hid every review minute.
            # The close lands on the newest stamp before this line, the last
            # thing the run recorded, so a crash's dead hours count toward
            # nothing. An open `poll` closes the same way: a nested poll
            # writes `poll end` before the next start, so only a crashed one
            # is still open here, and left open it ran to the log's end and
            # its subtraction ate every later review minute. A `poll start`
            # closes nothing, since it opens inside a running `6`.
            for other, pending in open_starts.items():
                if other == phase:
                    continue
                while pending:
                    intervals.setdefault(other, []).append((pending.pop(0), seen))
        if kind == "start":
            open_starts.setdefault(phase, []).append(moment)
        else:
            pending = open_starts.get(phase)
            if not pending:
                problems.append(f"{label}: {phase!r} end with no open start")
                continue
            intervals.setdefault(phase, []).append((pending.pop(0), moment))
        seen = moment if seen is None else max(seen, moment)
    if problems:
        raise InputError(problems)

    # Without `now`, the resume probe closes a crashed run's open start at
    # the last thing the run recorded, so the hours it sat dead stay out. An
    # in-run check passes `now`, or a Step 4 still running reads as 0 min of
    # review for as long as it runs, since its own start is the newest stamp.
    close_at = now if now is not None else (max(moments) if moments else None)
    for phase, pending in open_starts.items():
        for start in pending:
            intervals.setdefault(phase, []).append((start, max(start, close_at)))

    def seconds(phase):
        return sum((end - start).total_seconds() for start, end in intervals.get(phase, ()))

    # Step 6 writes its poll inside its own `6` bracket, so ignoring `poll`
    # lines alone still counted the reviewer's wait as review. Subtracting
    # the covered time zeroes a poll nested in a bracket, before it, or after it.
    polls = _merge(intervals.get("poll", ()))
    build_seconds = sum(seconds(p) for p in BUILD_LABELS)
    review_seconds = sum(
        (end - start).total_seconds() - _overlap_seconds(start, end, polls)
        for p in REVIEW_LABELS
        for start, end in intervals.get(p, ())
    )
    return build_seconds, review_seconds, raised


def cmd_budget(args):
    now = None
    if args.now is not None:
        problems = []
        now = parse_ts(args.now, "--now", problems)
        if problems:
            for problem in problems:
                sys.stderr.write(f"run-state: {problem}\n")
            return 3
    try:
        with open(args.timing, encoding="utf-8") as handle:
            text = handle.read()
    except FileNotFoundError:
        # Every run started before this change has no log. Reading a missing
        # log as `over: no` rather than failing keeps those old runs off the
        # stop this feature adds; a probe that turned this into `null` would
        # halt them instead.
        text = ""
    except (OSError, UnicodeDecodeError) as e:
        # Only absence means "no log yet". A directory, an unreadable file, or
        # a binary file is a log that exists and can't be read, and reading
        # that as under budget fails in the permissive direction.
        why = e.strerror if isinstance(e, OSError) and e.strerror else e
        sys.stderr.write(f"run-state: --timing {args.timing}: {why}\n")
        return 3

    try:
        build_seconds, review_seconds, over = budget_over(text, args.ratio, now)
    except InputError as e:
        for problem in e.problems:
            sys.stderr.write(f"run-state: {problem}\n")
        return 3

    ratio_text = "n/a" if build_seconds == 0 else f"{review_seconds / build_seconds:.2f}"
    print(
        f"build: {round(build_seconds / 60)}m review: {round(review_seconds / 60)}m "
        f"ratio: {ratio_text} over: {'yes' if over else 'no'}"
    )
    return 0


def budget_over(text, ratio=None, now=None):
    """`(build_seconds, review_seconds, over)` for a timing.log's text.

    One threshold rule for `budget` and the probe's `review_over_budget`, so
    the stop the probe reports is the one `budget` prints. Raises InputError
    on a malformed log."""
    build_seconds, review_seconds, raised = parse_timing_log(text, "timing.log", now)
    # A flag typed for this one check outranks the log, and the log's last
    # raise outranks the 2.0 the issue set. `--ratio` has no preset value
    # so an explicit `--ratio 2.0` still counts as explicit.
    if ratio is not None:
        threshold = ratio
    elif raised is not None:
        threshold = raised
    else:
        threshold = DEFAULT_BUDGET_RATIO
    # Zero seconds, not zero rounded minutes: a 25 s build rounds to 0m, and
    # gating on that read 5 h of review as under budget.
    if build_seconds == 0:
        return build_seconds, review_seconds, False
    return build_seconds, review_seconds, review_seconds / build_seconds > threshold


def cmd_phase(args):
    try:
        probe = load_json(args.probe, "probe")
        check_probe(probe)
    except InputError as e:
        for problem in e.problems:
            sys.stderr.write(f"run-state: {problem}\n")
        return 3
    phase, reason = phase_of(probe)
    print(f"phase: {phase} reason: {reason}")
    return 0


def parse_args(argv=None):
    ap = argparse.ArgumentParser(
        description="Read a PR's review state, or map a resume probe to a phase."
    )
    sub = ap.add_subparsers(dest="command", required=True)

    r = sub.add_parser("review", help="findings, cleared, or pending for one PR")
    r.add_argument("pr", metavar="PR", help="pull request number")
    r.add_argument("--since", metavar="ISO8601", help="ignore items at or before this")
    r.add_argument("--author", metavar="LOGIN", help="the PR author, who cannot clear it")
    r.add_argument(
        "--input",
        metavar="BUNDLE_JSON",
        help="read a gathered bundle instead of calling gh; '-' for stdin",
    )
    r.add_argument(
        "--save",
        metavar="PATH",
        help="write the gathered bundle as JSON to PATH; allowed with --input",
    )
    r.set_defaults(func=cmd_review)

    p = sub.add_parser("phase", help="where a half-finished run resumes")
    p.add_argument("--probe", metavar="PROBE_JSON", required=True)
    p.set_defaults(func=cmd_phase)

    b = sub.add_parser("budget", help="build vs. review minutes from a timing.log, and whether review is over budget")
    b.add_argument("--timing", metavar="TIMING_LOG", required=True, help="path to timing.log; a missing file reads as under budget")
    b.add_argument("--ratio", metavar="RATIO", type=float, help="review:build ratio that trips 'over'; beats any 'budget-raised' line, which beats 2.0")
    b.add_argument("--now", metavar="ISO8601", help="close open starts at this UTC moment rather than the log's latest stamp")
    b.set_defaults(func=cmd_budget)

    g = sub.add_parser("probe", help="gather the resume probe that phase reads")
    g.add_argument("--run-dir", metavar="DIR", required=True, help="RUN_DIR; read, never created")
    g.add_argument("--root", metavar="ROOT", required=True, help="the repo's work tree; the issue branch's worktree is found from it")
    g.add_argument("--issue", metavar="N", required=True, help="the issue number")
    g.add_argument("--pr-bundle", metavar="FILE", help="a bundle `review PR --save FILE` wrote; omit where there is no pull request")
    g.add_argument("--herdr-state", metavar="STATE", choices=HERDR_STATES, help="the issue agent's state from herdr: " + ", ".join(HERDR_STATES))
    g.add_argument("--author", metavar="LOGIN", help="the PR author; defaults to the bundle's author")
    g.set_defaults(func=cmd_probe)

    return ap.parse_args(argv)


def main(argv=None):
    argv = sys.argv[1:] if argv is None else list(argv)
    try:
        args = parse_args(argv)
    except SystemExit as e:
        # probe follows the validator convention's 3 for usage; the other
        # subcommands keep argparse's 2, which this docstring has always said.
        if e.code == 2 and argv[:1] == ["probe"]:
            return 3
        raise
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
