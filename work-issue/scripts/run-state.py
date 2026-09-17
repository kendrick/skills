#!/usr/bin/env python3
"""Read a pull request's review state, and map a resume probe to a phase.

    work-issue/scripts/run-state.py review PR [--since ISO8601] [--author LOGIN]
    work-issue/scripts/run-state.py review PR --input BUNDLE.json
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
every item at or before it is ignored.

`--input` reads the shape the `gh` calls below produce, so the fixtures under
tests/fixtures/work-issue/review/ exercise the state rules with no network.
Nothing shells out while `--input` is given.

Exit codes: 0 with an answer on stdout; 3 usage, a `gh` failure, or input this
script cannot read (an unparseable bundle, a bundle missing a top-level key, a
probe missing a field). Argparse supplies 2 for a mistyped flag.

Stdlib only, so the skill stays copy-in portable.
"""
import argparse
import json
import re
import subprocess
import sys
from datetime import datetime, timezone

GH_TIMEOUT = 60

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
    ("pr_state", "enum", ("OPEN", "MERGED", "CLOSED")),
    ("review_state", "enum", ("findings", "cleared", "pending")),
    ("has_waves", "bool", ()),
    ("wave_tasks", "int", ()),
    ("wave_reports", "int", ()),
    ("self_reviews", "int", ()),
    ("build_final", "bool", ()),
    ("redteam_rounds", "int", ()),
    ("redteam_last_failed", "bool", ()),
    ("trigger_fired", "bool", ()),
    ("ar_run_dir", "bool", ()),
    ("conflict", "bool", ()),
    ("rebase_in_progress", "bool", ()),
    ("ahead_of_origin", "bool", ()),
    ("triage_rounds", "int", ()),
    ("triage_newer_than_since", "bool", ()),
    ("triage_inscope_rows", "int", ()),
    ("repair_reports", "int", ()),
    ("triage_rows_unanswered", "int", ()),
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


GRAPHQL_QUERY = """
query($owner: String!, $name: String!, $pr: Int!) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $pr) {
      author { login }
      reviews(first: 100) {
        nodes { state author { login } submittedAt }
      }
      reviewThreads(first: 100) {
        nodes {
          id
          isResolved
          comments(first: 1) {
            nodes { author { login } createdAt body }
          }
        }
      }
    }
  }
}
"""


def _login(node):
    return (node or {}).get("login")


def gather(pr):
    """The bundle shape, read from `gh`.

    Three calls, because no one of them has all of it. REST carries the
    reactions and the issue comments. GraphQL carries the author, the reviews,
    and the review threads with their resolved flag. Only a hand run exercises
    this path. Every fixture goes through `--input`, so the smoke suite does
    not cover a change here."""
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
    graph = gh(
        [
            "api",
            "graphql",
            "-F",
            f"owner={owner}",
            "-F",
            f"name={name}",
            "-F",
            f"pr={pr}",
            "-f",
            f"query={GRAPHQL_QUERY}",
        ],
        "gh api graphql",
    )
    payload = graph[0] if graph else {}
    repository = ((payload.get("data") or {}).get("repository")) or {}
    pull = repository.get("pullRequest") or {}
    if not pull:
        raise GhError(f"gh api graphql: no pull request {pr} in {name_with_owner}")

    threads = []
    for node in ((pull.get("reviewThreads") or {}).get("nodes")) or []:
        roots = ((node.get("comments") or {}).get("nodes")) or []
        root = roots[0] if roots else {}
        threads.append(
            {
                "id": node.get("id"),
                "is_resolved": node.get("isResolved"),
                "root_created_at": root.get("createdAt"),
                "root_author": _login(root.get("author")),
                "root_body": root.get("body"),
            }
        )

    return {
        "author": _login(pull.get("author")),
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
            }
            for n in ((pull.get("reviews") or {}).get("nodes")) or []
        ],
        "threads": threads,
        "comments": [
            {
                "author": _login(c.get("user")),
                "created_at": c.get("created_at"),
                "body": c.get("body"),
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
        return moment is not None and (since is None or moment > since)

    for index, thread in enumerate(bundle["threads"]):
        created = parse_ts(
            thread["root_created_at"], f"threads[{index}].root_created_at", problems
        )
        if thread["is_resolved"] or not newer(created):
            continue
        findings = True
        lines.append(
            f"thread {thread['id']} unresolved, created {show_ts(created)}, "
            f"{severity(thread['root_body'])}"
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
        lines.append(f"review {state} by {review['author']} {show_ts(submitted)}")

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
        lines.append(f"comment by {comment['author']} {show_ts(created)}")

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
    herdr = probe["herdr_agent_state"]
    branch_anywhere = flag(probe, "branch_local") or flag(probe, "branch_remote")
    wave_tasks = count(probe, "wave_tasks")
    wave_reports = count(probe, "wave_reports")
    every_wave_report = wave_tasks > 0 and wave_reports >= wave_tasks
    redteam_rounds = count(probe, "redteam_rounds")
    redteam_clean = redteam_rounds > 0 and not flag(probe, "redteam_last_failed")
    triage_rounds = count(probe, "triage_rounds")
    repair_reports = count(probe, "repair_reports")

    if pr_state in ("MERGED", "CLOSED"):
        return "done", f"row 1: the PR is {pr_state}, so offer cleanup and stop"
    if herdr == "working":
        return "wait", "row 2: the herdr agent is working; wait and re-probe"
    if herdr == "blocked":
        return "stop", "row 3: the herdr agent is blocked; show its UI and stop"
    if not branch_anywhere and not flag(probe, "run_dir"):
        return "0", "row 4: no branch anywhere and no run dir, so this issue is fresh"
    if flag(probe, "run_dir") and not branch_anywhere:
        return "0", "row 5: a run dir with no branch anywhere; move it to closed/ first"
    if branch_anywhere and not flag(probe, "has_waves"):
        return "0", "row 6: the branch exists but plan.md has no ## Waves table; resume at the plan gate"
    if flag(probe, "has_waves") and wave_reports < wave_tasks:
        return "2", f"row 7: {wave_reports} of {wave_tasks} wave reports on disk; resume at that wave"
    if every_wave_report and count(probe, "self_reviews") == 0:
        return "3", "row 8: every wave report is in and no self-review; resume at the code-review invocation"
    if count(probe, "self_reviews") > 0 and not flag(probe, "build_final"):
        return "3", "row 9: a self-review with no build-final report; resume at the fix dispatch"
    if flag(probe, "build_final") and redteam_rounds == 0:
        return "4", "row 10: a build-final report with no red-team round yet"
    if (
        flag(probe, "build_final")
        and flag(probe, "redteam_last_failed")
        and repair_reports == 0
    ):
        return "4", "row 10: the newest red-team round has NOT_REPRODUCED and no repair followed it"
    if redteam_clean and flag(probe, "trigger_fired") and not flag(probe, "ar_run_dir"):
        return "4", "row 11: trigger.txt says fired and adversarial-review has no run dir"
    if flag(probe, "conflict") or flag(probe, "rebase_in_progress"):
        return "5", "row 12: a rebase conflict is in progress; resume at Step 5 item 1"
    if redteam_clean and (pr_state is None or flag(probe, "ahead_of_origin")):
        return "5", "row 13: red-team is clean and the branch is unpublished or ahead of origin"
    if pr_state == "OPEN" and review_state == "pending":
        return "6", "row 14: the PR is open and no review has landed since the last push; keep polling"
    if (
        pr_state == "OPEN"
        and review_state == "findings"
        and not flag(probe, "triage_newer_than_since")
    ):
        return "6", "row 15: the PR has findings and no triage round newer than SINCE"
    if (
        triage_rounds > 0
        and count(probe, "triage_inscope_rows") > 0
        and repair_reports < triage_rounds
    ):
        return "7", "row 16: a triage round has in-scope rows and no matching repair report"
    if repair_reports > 0 and (
        flag(probe, "ahead_of_origin") or count(probe, "triage_rows_unanswered") > 0
    ):
        return "8", "row 17: a repair report with work unpushed or a triage row still unanswered"
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
