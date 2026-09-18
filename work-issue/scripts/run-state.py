#!/usr/bin/env python3
"""Read a pull request's review state, and map a resume probe to a phase.

    work-issue/scripts/run-state.py review PR [--since ISO8601] [--author LOGIN] [--save PATH]
    work-issue/scripts/run-state.py review PR --input BUNDLE.json [--save PATH]
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

Exit codes: 0 with an answer on stdout; 3 usage, a `gh` failure, an unwritable
`--save` path, or input this script cannot read (an unparseable bundle, a
bundle missing a top-level key, a probe missing a field). Argparse supplies 2
for a mistyped flag.

Stdlib only, so the skill stays copy-in portable.
"""
import argparse
import json
import re
import subprocess
import sys
from datetime import datetime, timezone

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
    ("pr_state", "enum", ("OPEN", "MERGED", "CLOSED")),
    ("review_state", "enum", ("findings", "cleared", "pending")),
    ("has_waves", "bool", ()),
    ("wave_tasks", "int", ()),
    ("wave_reports", "int", ()),
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
)

BUNDLE_KEYS = (
    ("author", (str, type(None))),
    ("reactions", (list,)),
    ("reviews", (list,)),
    ("threads", (list,)),
    ("comments", (list,)),
)


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
      reviews(first: $pageSize, after: $after) {
        nodes { state author { login } submittedAt databaseId body url }
        pageInfo { hasNextPage endCursor }
      }
    }
  }
}
"""

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
          latest: comments(last: 1) {
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
        # The newest comment rides along with the root. A reviewer who answers
        # inside an old thread after a repair push writes no new root, and a
        # bundle carrying only roots scored that thread against the old date.
        latests = ((node.get("latest") or {}).get("nodes")) or []
        latest = latests[0] if latests else {}
        threads.append(
            {
                "id": node.get("id"),
                "is_resolved": node.get("isResolved"),
                "root_created_at": root.get("createdAt"),
                "root_author": _login(root.get("author")),
                "root_body": root.get("body"),
                "root_comment_id": root.get("databaseId"),
                "root_url": root.get("url"),
                "last_comment_at": latest.get("createdAt"),
                "last_comment_author": _login(latest.get("author")),
                "last_comment_body": latest.get("body"),
                "last_comment_id": latest.get("databaseId"),
                "last_comment_url": latest.get("url"),
            }
        )

    return {
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
        # push lands as a reply, not as a new thread.
        last = parse_ts(
            thread.get("last_comment_at"), f"threads[{index}].last_comment_at", problems
        )
        reviewer_replied = (
            newer(last)
            and normalize_login(thread.get("last_comment_author")) != author_key
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
                f"{show_or_unknown(thread.get('last_comment_url'))}"
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

    if herdr == "working":
        return "wait", "row 2: the herdr agent is working; wait and re-probe"
    if herdr == "blocked":
        return "stop", "row 3: the herdr agent is blocked; show its UI and stop"
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
        return "2", f"row 7: {wave_reports} of {wave_tasks} wave reports on disk; resume at that wave"
    if every_wave_report and count(probe, "self_reviews") == 0:
        return "3", "row 8: every wave report is in and no self-review; resume at the code-review invocation"
    if count(probe, "self_reviews") > 0 and not flag(probe, "build_final"):
        return "3", "row 9: a self-review with no build-final report; resume at the fix dispatch"
    if flag(probe, "build_final") and redteam_rounds == 0:
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
        return "4", "row 11: red-team is clean and trigger.txt is not written yet; resume at the trigger"
    if redteam_clean and trigger == "yes" and not flag(probe, "ar_complete"):
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
        return "7", "row 16: the newest triage round has in-scope rows and no repair report of its own"
    # Post-PR only: Step 8 pushes and replies but never opens a pull request,
    # so a repair with no PR behind it belongs to row 10 (unverified) or row
    # 13 (clean), never here. The repair-report leg still stands alone: a
    # post-PR repair round may have no triage round of its own.
    # An owed deferred-findings comment reaches Step 8 on its own. A worker's
    # plan_concerns row lands in the queue at Step 4, before any triage round
    # or repair report exists, and a resume that required one of those first
    # matched no row at all and stranded the run.
    if pr_state == "OPEN" and (
        flag(probe, "deferred_comment_needed")
        or (
            (repair_reports > 0 or (triage_rounds > 0 and count(probe, "triage_inscope_rows") == 0))
            and (flag(probe, "ahead_of_origin") or count(probe, "triage_rows_unanswered") > 0)
        )
    ):
        return (
            "8",
            "row 17: the deferred-findings comment is owed, or a repair report or an "
            "all-queued triage round leaves work unpushed or a triage row unanswered",
        )
    if pr_state == "OPEN" and review_state == "cleared":
        return "done", "row 18: the PR is open and the review is cleared; print the final report"
    return (
        "stop",
        "no resume row matches this probe; gather it again per references/resume.md",
    )


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

    return ap.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
