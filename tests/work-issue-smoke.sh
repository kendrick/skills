#!/usr/bin/env bash
# Pin the work-issue skill's load-bearing behavior. The skill runs unattended
# past one confirmation and holds a push grant, so the two rules that bound
# it—prove every mutation, never the default branch—have to survive every edit
# to every document a dispatch is built from. Many of the assertions below are
# refutes, because each mechanism this design cut is a reasonable-sounding idea
# somebody will propose again.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

require_file() {
  [[ -f "$1" ]] || {
    echo "missing required file: $1" >&2
    exit 1
  }
}

require_text() {
  local file="$1"
  local text="$2"
  grep -Fq -- "$text" "$file" || {
    echo "missing expected text in $file: $text" >&2
    exit 1
  }
}

# The trailing `return 0` matters: under `set -e`, a function ending on a failed
# grep aborts the script.
refute_text() {
  local file="$1"
  local text="$2"
  grep -Fq -- "$text" "$file" && {
    echo "unexpected text in $file: $text" >&2
    exit 1
  }
  return 0
}

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# --- Inventory: every document and script the skill ships, plus the fixtures
# the functional section drives. ---

require_file work-issue/SKILL.md
require_file work-issue/README.md
require_file work-issue/references/worker-prompt.md
require_file work-issue/references/redteam.md
require_file work-issue/references/resume.md
require_file work-issue/references/triage.md
require_file work-issue/scripts/check-plan.py
require_file work-issue/scripts/check-inflight.py
require_file work-issue/scripts/run-state.py
require_file _maintenance/work-issue/RATIONALE.md
require_file _maintenance/work-issue/EVALS.md

require_file tests/fixtures/work-issue/plans/issue.md
require_file tests/fixtures/work-issue/plans/plan-good.md
require_file tests/fixtures/work-issue/plans/plan-nofiles.md
require_file tests/fixtures/work-issue/plans/plan-thin.md
require_file tests/fixtures/work-issue/plans/plan-uncited.md
require_file tests/fixtures/work-issue/plans/inflight/issue-38/plan.md
# A sibling under `closed/` is the run the overlap check must skip, so the
# fixture that proves the skip has to exist for that check to mean anything.
require_file tests/fixtures/work-issue/plans/inflight/closed/issue-7/plan.md
require_file tests/fixtures/work-issue/review/author-reaction.json
require_file tests/fixtures/work-issue/review/cleared-by-reaction.json
require_file tests/fixtures/work-issue/review/cleared-by-review.json
require_file tests/fixtures/work-issue/review/findings-with-reaction.json
require_file tests/fixtures/work-issue/review/pending.json
require_file tests/fixtures/work-issue/review/stale-reaction.json
# One probe fixture per row of the Resume table. A missing one is a row nobody
# ever exercised, and that is how two rows end up sharing one branch with
# nothing to notice it.
for i in $(seq -w 1 18); do
  require_file "tests/fixtures/work-issue/probes/row-$i.json"
done
# Row 17 gained a second shape — a repair report, or a triage round with no
# in-scope rows — and the fixture proving the first shape does not also cover
# the second, so it gets its own file rather than replacing row-17.json.
require_file tests/fixtures/work-issue/probes/row-17-queued.json
# A stop between the repair push and the replies, once sent to row 14's poll;
# and a red-team repair not yet re-verified, once sent to row 18's done and
# later to row 17's Step 8, which never opens the pull request.
require_file tests/fixtures/work-issue/probes/row-17-postpush.json
require_file tests/fixtures/work-issue/probes/row-10-repair-unverified.json
# A pre-PR repair, clean after its own round: Step 5 with the PR create, never
# Step 8, which only pushes and replies.
require_file tests/fixtures/work-issue/probes/row-13-prepr-repair-clean.json
# The two ways a failed round resumes, and the one way it stops: no repair
# since the round, a repair since the round, and two failed rounds in a row.
require_file tests/fixtures/work-issue/probes/row-10-repair-needed.json
require_file tests/fixtures/work-issue/probes/row-10-failed-twice.json
# Every row answered, the queue not yet posted: Step 8 item 4 still owed.
require_file tests/fixtures/work-issue/probes/row-17-deferred-owed.json
# A worker's plan_concerns row queued at Step 4, before any triage round: the
# owed comment alone has to reach Step 8.
require_file tests/fixtures/work-issue/probes/row-17-worker-queue.json
# A gated run that stopped before Step 1 made its branch: live, not dead.
require_file tests/fixtures/work-issue/probes/row-05-gated.json
# An all-queued round with everything answered and published: done, waiting
# on the reviewer, since a queue-only round pushes nothing and SINCE stays.
require_file tests/fixtures/work-issue/probes/row-18-answered.json
# A reviewer follow-up with the author's answer after it: the follow-up is
# still the finding, and the last comment alone would have hidden it.
require_file tests/fixtures/work-issue/review/thread-followup-then-author.json
# A reviewer's reply inside an old thread after a repair push, and the same
# thread where the only reply is the author's own.
require_file tests/fixtures/work-issue/review/thread-followup.json
require_file tests/fixtures/work-issue/review/thread-author-reply.json
# A queued round followed by a repaired one, which a count comparison sent back
# to Step 7; and a probe with one null, which a bool coercion read as "no".
require_file tests/fixtures/work-issue/probes/row-16-earlier-queued.json
require_file tests/fixtures/work-issue/probes/unknown-branch-remote.json
# A review repair committed but unpushed: ahead of origin with a clean build
# red-team, which row 13 once took for a fresh publish.
require_file tests/fixtures/work-issue/probes/row-17-review-repair-unpushed.json
# Two stops the table once misread: inside Step 1 with no base_sha or baseline
# (read as "dispatch wave 0"), and after a clean round with no trigger verdict
# (read as "not fired", then published).
require_file tests/fixtures/work-issue/probes/row-07-isolation-incomplete.json
require_file tests/fixtures/work-issue/probes/row-11-trigger-unrecorded.json
require_file tests/fixtures/work-issue/review/changes-requested.json
require_file tests/fixtures/work-issue/review/pr-comment-finding.json

[[ "$(find work-issue -maxdepth 1 -type f | wc -l | tr -d ' ')" == "2" ]] || {
  echo "work-issue/ must ship only SKILL.md and README.md at top level" >&2
  exit 1
}

# Frontmatter. Manual invocation is deliberate: a misfire spends a whole
# fan-out and then pushes a branch and opens a pull request nobody asked for,
# while a missed trigger costs the user one word.
require_text work-issue/SKILL.md "name: work-issue"
require_text work-issue/SKILL.md "disable-model-invocation: true"
require_text work-issue/SKILL.md "argument-hint: '<issue number or URL> [plan path] [--isolate | --no-isolate] [--deep] [--dry-run]'"

# A description that summarizes the steps becomes the shortcut the model takes
# instead of reading the body, which is how a nine-step skill collapses into
# whatever the description happened to mention.
refute_text work-issue/SKILL.md 'description: "Step 1'

# --- The two rules. Every other assertion in this file is downstream of
# these. ---

# The session this skill was written out of lost five separate edits to silent
# mutation failures, and every one of them produced a passing suite because the
# suite ran against a file nothing had changed. The rule has to reach a worker
# as well as the orchestrator, so it is pinned in both places it is stated.
require_text work-issue/SKILL.md "proved before anything reads a result"
require_text work-issue/references/worker-prompt.md "proved before anything reads a result"

# An unattended run holds a push grant. The one thing it must never be able to
# do is write over the branch everybody else builds on.
require_text work-issue/SKILL.md "never the default branch"

# --- Resolve. These three are read off disk rather than re-derived, because a
# run that re-derives them reviews or pushes something other than what it
# gated. ---

require_text work-issue/SKILL.md "**RUN_DIR** — \`<COMMON>/work-issue/issue-<N>/\`"
require_text work-issue/SKILL.md "**BASE_SHA** — \`git merge-base origin/<DEFAULT> <BRANCH>\`"
require_text work-issue/SKILL.md "**SINCE** — the contents of \`RUN_DIR/pushed_at\`"

# --- Every step heading. The resume table, the references, and the README all
# point at steps by number, so a step folded into its neighbor leaves every one
# of those cross-references aimed at nothing. ---

require_text work-issue/SKILL.md "## Step 0 — Gate and confirm"
require_text work-issue/SKILL.md "## Step 1 — Isolate"
require_text work-issue/SKILL.md "## Step 2 — Dispatch"
require_text work-issue/SKILL.md "## Step 3 — Build and self-review"
require_text work-issue/SKILL.md "## Step 4 — Red-team"
require_text work-issue/SKILL.md "## Step 5 — Publish"
require_text work-issue/SKILL.md "## Step 6 — Triage"
require_text work-issue/SKILL.md "## Step 7 — Repair"
require_text work-issue/SKILL.md "## Step 8 — Close"

# --- The worker preamble. SKILL.md names two of its sentences as going across
# verbatim, and worker-prompt.md is where a dispatch actually reads them from,
# so both spellings are pinned where each one is written. ---

require_text work-issue/SKILL.md "flag rather than route around"
require_text work-issue/SKILL.md "what you left and why"
require_text work-issue/references/worker-prompt.md "Flag rather than route around"
require_text work-issue/references/worker-prompt.md "what you left and why"

# Step 4 re-derives its grep from adversarial-review's table at run time rather
# than copying the signals, but which rows it reads is fixed here. Drop a row
# and the red-team phase stops firing on money, authz, or schema diffs while
# the step still reads as intact, with nothing in the output to say otherwise.
require_text work-issue/SKILL.md "rows 1 (money), 2 (authz), and 4 (schema) of \`adversarial-review/references/trigger-table.md\`"

# Step 6's three review states, copied off the table a poll scores against.
# `findings` outranks `cleared` for a reason: a reviewer can leave an approving
# reaction and a blocking thread in one pass. A dropped row here is a state the
# triage step can no longer reach.
require_text work-issue/SKILL.md "| findings | any unresolved review thread whose root comment, or whose latest comment from a login other than the author, is newer than SINCE; or a \`CHANGES_REQUESTED\` review newer than SINCE; or a pull-request-level or issue comment newer than SINCE from a login other than the author that is not a bare approval |"
require_text work-issue/SKILL.md "| cleared | no findings, and either an \`APPROVED\` review newer than SINCE, or a \`+1\` reaction on the pull request (\`gh api repos/{owner}/{repo}/issues/<pr>/reactions\`) newer than SINCE from a login other than the author |"
require_text work-issue/SKILL.md "| pending | neither |"

# Marking a thread resolved is the reviewer's own signal that somebody read
# their finding. Taking that act for them hides the thread from the view they
# use to check it.
require_text work-issue/SKILL.md "Answer, never resolve"

# --- The cut features. Each sounds reasonable on its own, and each has a row
# in the RATIONALE ledger's Deliberately Not Built table. Applied across
# SKILL.md and every reference, since those five documents are what a dispatch
# is built from. ---

work_issue_docs=(
  work-issue/SKILL.md
  work-issue/references/worker-prompt.md
  work-issue/references/redteam.md
  work-issue/references/resume.md
  work-issue/references/triage.md
)

for doc in "${work_issue_docs[@]}"; do
  # Merging. A diff no human has read is the one place this design refuses to
  # act unattended, so the run stops one step short of the merge button.
  refute_text "$doc" "gh pr merge"

  # Resolving a review thread on the reviewer's behalf. It destroys the only
  # signal they have that anybody read the finding.
  refute_text "$doc" "resolveReviewThread"

  # A phase flag in RUN_DIR. It outlives the crash that invalidated it, and
  # then a resume trusts the flag over the world it should have re-probed.
  refute_text "$doc" "phase.txt"

  # Filing the queued findings as issues. A walk-away run that opens the
  # tickets itself turns one reviewer's aside into backlog nobody triaged.
  refute_text "$doc" "gh issue create"

  # A lock file for the cross-run race. check-inflight.py closes the race that
  # actually happens; a lock trades it for a stale-lock story that stops a run
  # nothing is racing.
  refute_text "$doc" ".lock"

  # A bare force push. `--force-with-lease=issue-<N>` refuses to overwrite a
  # branch that moved under the run, and a bare `--force` cannot tell its own
  # rebase from somebody else's push. The trailing space is what keeps
  # `--force-with-lease` out of this refute's reach.
  refute_text "$doc" "push --force "

  # Attribution trailers and generation footers. Every commit message, pull
  # request body, and thread reply this skill authors goes out without one.
  refute_text "$doc" "Co-Authored-By"
  refute_text "$doc" "Generated with"
done

# --- The vendored block. check-inflight.py carries paths_overlap,
# owns_entry_problem, path_within, and the table parser out of check-waves.py
# byte for byte, and divergence is the one thing the provenance comment
# promises never happens. Extracted by the function and constant names rather
# than by line number, since both files reflow as their skills grow. ---

require_text work-issue/scripts/check-inflight.py "Vendored verbatim from divvy-up/scripts/check-waves.py"
require_text work-issue/scripts/check-inflight.py "Upstream is authoritative"

extract_vendored() {
  local file="$1"
  sed -n '/^def paths_overlap/,/^    return path\.startswith(prefix)$/p' "$file"
  sed -n '/^COLUMNS = /,/^Row = collections\.namedtuple/p' "$file"
  sed -n '/^def split_row/,/^    return rows, problems$/p' "$file"
}

extract_vendored divvy-up/scripts/check-waves.py > "$tmp/upstream.txt"
extract_vendored work-issue/scripts/check-inflight.py > "$tmp/vendored.txt"

# Two empty extractions `cmp` clean against each other, so a renamed function
# would read as a passing identity check. The line floor catches that before
# `cmp` gets to answer.
[[ "$(wc -l < "$tmp/upstream.txt" | tr -d ' ')" -gt 200 ]] || {
  echo "the vendored-block markers matched almost nothing in check-waves.py; fix the markers, not the floor" >&2
  exit 1
}

cmp "$tmp/upstream.txt" "$tmp/vendored.txt" || {
  echo "check-inflight.py's vendored functions have drifted from divvy-up/scripts/check-waves.py" >&2
  exit 1
}

# --- Functional checks. Cheap, deterministic, no subagents. Every exit code is
# asserted as the exact number the design contract promises. A script that
# prints its complaint and then exits 0 fails the orchestrator that branches on
# the code, and a "non-zero" assertion would wave that regression through. ---

plans=tests/fixtures/work-issue/plans
check_plan=work-issue/scripts/check-plan.py
check_inflight=work-issue/scripts/check-inflight.py
run_state=work-issue/scripts/run-state.py

# The pass line carries the counts the gate derived. A plan that passes while
# miscounting its tasks or its covered criteria has told the user something
# untrue about what was checked.
set +e
good_out="$(python3 "$check_plan" "$plans/plan-good.md" --issue 101 --criteria "$plans/issue.md" 2>&1)"
good_status=$?
set -e
[[ "$good_status" == "0" ]] || {
  echo "plan-good.md should exit 0, got: $good_status: $good_out" >&2
  exit 1
}
# 4/4: the third criterion sits under `### Fixtures`, a subheading inside
# Acceptance Criteria, which the nearest-heading scan dropped. The fourth is
# indented and marked with `*` rather than a column-1 `-`, which D6's pattern
# ignored until it was widened to match D4's CHECKBOX_RE. And plan-good
# carries a box under `## OpenAPI changes`, which a substring match on `open`
# once refused as a decision section.
grep -Fq "OK: plan cites #101, 3 tasks with files, 0 open markers, 4/4 criteria covered" <<<"$good_out" || {
  echo "plan-good.md should print its full OK line, got: $good_out" >&2
  exit 1
}

# One fixture, two rules: a bare TODO and an unchecked box under a heading the
# plan calls Open Questions. Both have to fire, because a plan carrying either
# one is a plan whose author had not finished deciding.
set +e
thin_out="$(python3 "$check_plan" "$plans/plan-thin.md" --issue 101 2>&1)"
thin_status=$?
set -e
[[ "$thin_status" == "1" ]] || {
  echo "plan-thin.md should exit 1, got: $thin_status: $thin_out" >&2
  exit 1
}
grep -Fq "D3 open marker 'TODO'" <<<"$thin_out" || {
  echo "plan-thin.md should fail D3 on its bare TODO, got: $thin_out" >&2
  exit 1
}
# `???` is the one marker with no word characters, so a boundary written for
# words never matches it. The first version of the scan let a live `???` through
# with `0 open markers` on its OK line.
grep -Fq "D3 open marker '???'" <<<"$thin_out" || {
  echo "plan-thin.md should fail D3 on its bare ???, got: $thin_out" >&2
  exit 1
}
grep -Fq "D4 unchecked box under heading 'Open Questions'" <<<"$thin_out" || {
  echo "plan-thin.md should fail D4 on its Open Questions box, got: $thin_out" >&2
  exit 1
}
# The second box sits under `### Storage`, a subheading inside Open Questions,
# and it is indented. Tracking only the nearest heading let it through once,
# and a column-1 checkbox pattern let it through again, so D4 has to fire
# twice here, both times naming the ancestor that makes the box a decision.
[[ "$(grep -c "D4 unchecked box under heading 'Open Questions'" <<<"$thin_out")" == "2" ]] || {
  echo "plan-thin.md should fail D4 on both boxes, the nested one included, got: $thin_out" >&2
  exit 1
}

# A task with nowhere to write its output is a task whose worker picks a file
# and nobody proved that file is unowned.
set +e
nofiles_out="$(python3 "$check_plan" "$plans/plan-nofiles.md" --issue 101 2>&1)"
nofiles_status=$?
set -e
[[ "$nofiles_status" == "1" ]] || {
  echo "plan-nofiles.md should exit 1, got: $nofiles_status: $nofiles_out" >&2
  exit 1
}
grep -Fq "D2 task" <<<"$nofiles_out" || {
  echo "plan-nofiles.md should fail D2 naming the task, got: $nofiles_out" >&2
  exit 1
}
# The first task is an indented `* [ ] Task` checkbox, which D2's column-1
# dash pattern never saw, so a plan of nothing but such tasks passed with
# `0 tasks with files`. Both tasks have to fire.
[[ "$(grep -c "D2 task" <<<"$nofiles_out")" == "2" ]] || {
  echo "plan-nofiles.md should fail D2 on both tasks, the indented checkbox included, got: $nofiles_out" >&2
  exit 1
}

# A plan that never names the issue is a plan nobody can tie to the ticket the
# whole run closes.
set +e
uncited_out="$(python3 "$check_plan" "$plans/plan-uncited.md" --issue 101 2>&1)"
uncited_status=$?
set -e
[[ "$uncited_status" == "1" ]] || {
  echo "plan-uncited.md should exit 1, got: $uncited_status: $uncited_out" >&2
  exit 1
}
grep -Fq "D1 plan does not cite #101" <<<"$uncited_out" || {
  echo "plan-uncited.md should fail D1, got: $uncited_out" >&2
  exit 1
}

# A missing plan is an environment problem, not a planning one, and it keeps
# its own exit code so the caller's refusal message can say which happened.
set +e
python3 "$check_plan" "$plans/does-not-exist.md" --issue 101 >/dev/null 2>&1
missing_plan_status=$?
set -e
[[ "$missing_plan_status" == "3" ]] || {
  echo "a missing plan file should exit 3, got: $missing_plan_status" >&2
  exit 1
}

# Two runs whose plans both own run-state.py. The overlap has to stop the second
# run before either one dispatches, rather than surfacing as a rebase conflict
# at Step 5 that a walk-away run cannot resolve. The line names both tasks,
# because "these two files overlap" without the owners leaves the user to find
# them.
set +e
inflight_out="$(python3 "$check_inflight" "$plans/plan-good.md" --runs "$plans/inflight" --self issue-101 2>&1)"
inflight_status=$?
set -e
[[ "$inflight_status" == "1" ]] || {
  echo "plan-good.md against issue-38 should exit 1, got: $inflight_status: $inflight_out" >&2
  exit 1
}
grep -Fq "overlap: work-issue/scripts/run-state.py — issue-101 task check-inflight-script, issue-38 task run-state-task" <<<"$inflight_out" || {
  echo "the overlap must name the path and both owning tasks, got: $inflight_out" >&2
  exit 1
}
# closed/issue-7 owns the same path and must not be reported. A substring grep
# on the issue-38 line and an exit code of 1 both stay true when the closed/
# skip is lost: dropping the guard adds a "skipped: closed" line, and a rewrite
# that recurses adds an issue-7 overlap. Only the whole output pins the skip.
[[ "$inflight_out" == "check-inflight: overlap: work-issue/scripts/run-state.py — issue-101 task check-inflight-script, issue-38 task run-state-task" ]] || {
  echo "check-inflight.py should report the issue-38 overlap and nothing else (closed/ is skipped), got: $inflight_out" >&2
  exit 1
}

# The first run of a fresh repo has no runs directory at all, and refusing it
# would stop every first invocation on a machine.
set +e
no_runs_out="$(python3 "$check_inflight" "$plans/plan-good.md" --runs "$plans/does-not-exist" 2>&1)"
no_runs_status=$?
set -e
[[ "$no_runs_status" == "0" ]] || {
  echo "a missing --runs directory should exit 0, got: $no_runs_status: $no_runs_out" >&2
  exit 1
}
grep -Fq "OK: no in-flight run owns a path this plan owns (checked 0 runs)" <<<"$no_runs_out" || {
  echo "a missing --runs directory should pass as 0 checked runs, got: $no_runs_out" >&2
  exit 1
}

# An unreadable plan cannot be proved disjoint from anything, and that is a
# different answer from "checked and clean".
set +e
python3 "$check_inflight" "$plans/does-not-exist.md" --runs "$plans/inflight" >/dev/null 2>&1
inflight_missing_status=$?
set -e
[[ "$inflight_missing_status" == "3" ]] || {
  echo "check-inflight.py on a missing plan should exit 3, got: $inflight_missing_status" >&2
  exit 1
}

# The six review bundles, all scored against one cutoff. `author-reaction` and
# `stale-reaction` are the two a cutoff-free reading calls cleared: a `+1` from
# the run's own author, and a `+1` older than the last push. Both score pending.
# `findings-with-reaction` is the case PR #100 of this repo really produced, an
# approving reaction and open finding threads at the same moment.
review_dir=tests/fixtures/work-issue/review
declare -a review_cases=(
  "author-reaction.json:pending"
  "cleared-by-reaction.json:cleared"
  "cleared-by-review.json:cleared"
  "findings-with-reaction.json:findings"
  "pending.json:pending"
  "stale-reaction.json:pending"
  "changes-requested.json:findings"
  "pr-comment-finding.json:findings"
  "thread-followup.json:findings"
  "thread-author-reply.json:pending"
  "thread-followup-then-author.json:findings"
)
for case in "${review_cases[@]}"; do
  fixture="${case%%:*}"
  expected="${case##*:}"
  set +e
  review_out="$(python3 "$run_state" review 1 --since 2026-09-17T16:00:00Z --author kendrick \
    --input "$review_dir/$fixture" 2>&1)"
  review_status=$?
  set -e
  # `review` is an artifact producer, never a gate. `findings` is an answer, so
  # exit 1 here would tell the caller the script failed when review simply had
  # something to say.
  [[ "$review_status" == "0" ]] || {
    echo "run-state.py review on $fixture should exit 0, got: $review_status: $review_out" >&2
    exit 1
  }
  [[ "$(head -1 <<<"$review_out")" == "$expected" ]] || {
    echo "run-state.py review should score $fixture as $expected, got: $review_out" >&2
    exit 1
  }
done

# A thread's deciding line has to carry the id Step 8 replies to, not just the
# thread's own GraphQL node id — `comments/<id>/replies` takes the root
# comment's REST id, which findings-with-reaction.json's first thread pins
# at 2199481001.
set +e
reply_out="$(python3 "$run_state" review 1 --since 2026-09-17T16:00:00Z --author kendrick \
  --input "$review_dir/findings-with-reaction.json" 2>&1)"
reply_status=$?
set -e
[[ "$reply_status" == "0" ]] || {
  echo "run-state.py review on findings-with-reaction.json should exit 0, got: $reply_status: $reply_out" >&2
  exit 1
}
grep -Fq "reply-to 2199481001" <<<"$reply_out" || {
  echo "run-state.py review should print a reply-to target for an unresolved thread, got: $reply_out" >&2
  exit 1
}

# A CHANGES_REQUESTED review whose findings live in its body is what --save
# exists for. Its deciding line has to end with the review's URL, and the
# saved file has to carry the body Step 6 quotes; a file that only parses
# would pass with both stripped. --save also has to work alongside --input,
# since Step 6 always has a bundle in hand by the time it polls.
set +e
cr_out="$(python3 "$run_state" review 1 --since 2026-09-17T16:00:00Z --author kendrick \
  --input "$review_dir/changes-requested.json" --save "$tmp/saved-bundle.json" 2>&1)"
save_status=$?
set -e
[[ "$save_status" == "0" ]] || {
  echo "run-state.py review --save should exit 0, got: $save_status: $cr_out" >&2
  exit 1
}
grep -Fq "review CHANGES_REQUESTED by someone-else 2026-09-17T16:30:00Z https://github.com/kendrick/skills/pull/1#pullrequestreview-5100000001" <<<"$cr_out" || {
  echo "a CHANGES_REQUESTED deciding line should end with the review's URL, got: $cr_out" >&2
  exit 1
}
set +e
python3 - "$tmp/saved-bundle.json" <<'PY'
import json, sys
bundle = json.load(open(sys.argv[1]))
review = bundle["reviews"][0]
sys.exit(0 if "author" in bundle and review.get("body", "").startswith("**P1**") and review.get("url") else 1)
PY
saved_bundle_status=$?
set -e
[[ "$saved_bundle_status" == "0" ]] || {
  echo "--save should write the bundle with the review's body and url intact" >&2
  exit 1
}

# An event stamped the same second as the cutoff reviewed the push that wrote
# the cutoff, so it counts. The fixture's review is at 16:30:00Z exactly, and a
# strict comparison scored this bundle pending.
set +e
same_second_out="$(python3 "$run_state" review 1 --since 2026-09-17T16:30:00Z --author kendrick \
  --input "$review_dir/changes-requested.json" 2>&1)"
same_second_status=$?
set -e
[[ "$same_second_status" == "0" && "$(head -1 <<<"$same_second_out")" == "findings" ]] || {
  echo "a review stamped the same second as --since should count, got: $same_second_status: $same_second_out" >&2
  exit 1
}

# A finding that arrives as a pull-request-level comment has no thread to
# reply into, and its triage row still needs a Source URL. The comment line
# carries it.
set +e
pc_out="$(python3 "$run_state" review 1 --since 2026-09-17T16:00:00Z --author kendrick \
  --input "$review_dir/pr-comment-finding.json" 2>&1)"
pc_status=$?
set -e
[[ "$pc_status" == "0" ]] || {
  echo "run-state.py review on pr-comment-finding.json should exit 0, got: $pc_status: $pc_out" >&2
  exit 1
}
grep -Fq "comment by someone-else 2026-09-17T16:45:00Z https://github.com/kendrick/skills/pull/1#issuecomment-3300000001" <<<"$pc_out" || {
  echo "a pull-request comment's deciding line should end with its URL, got: $pc_out" >&2
  exit 1
}

# A bundle this script cannot read must not score as `pending`, which is the
# state that tells the caller to keep waiting for a review that already landed.
echo '{"bad": 1}' > "$tmp/bad-bundle.json"
set +e
python3 "$run_state" review 1 --since 2026-09-17T16:00:00Z --author kendrick \
  --input "$tmp/bad-bundle.json" >/dev/null 2>&1
bad_bundle_status=$?
set -e
[[ "$bad_bundle_status" == "3" ]] || {
  echo "a malformed review bundle should exit 3, got: $bad_bundle_status" >&2
  exit 1
}

# One case per row of the Resume table, in the table's own order, because first
# match wins. Rows 4, 5, and 6 all resume at Step 0, and rows 1 and 18 both end
# the run, so a phase on its own cannot show that each row is still reachable.
# The grep stops at `reason:` so a reworded reason does not fail the suite.
probes_dir=tests/fixtures/work-issue/probes
declare -a probe_cases=(
  "row-01:done" "row-02:wait" "row-03:stop" "row-04:0" "row-05:0" "row-05-gated:0" "row-06:0"
  "row-07:2" "row-07-isolation-incomplete:1" "row-08:3" "row-09:3" "row-10:4" "row-11:4" "row-11-trigger-unrecorded:4" "row-12:5" "row-13:5"
  "row-14:6" "row-15:6" "row-16:7" "row-17:8" "row-17-queued:8" "row-17-postpush:8"
  "row-10-repair-unverified:4" "row-10-repair-needed:4" "row-10-failed-twice:stop" "row-13-prepr-repair-clean:5" "row-16-earlier-queued:8" "row-17-review-repair-unpushed:8" "row-17-deferred-owed:8" "row-17-worker-queue:8" "row-18-answered:done" "row-18:done"
)
for case in "${probe_cases[@]}"; do
  fixture="${case%%:*}"
  expected="${case##*:}"
  set +e
  probe_out="$(python3 "$run_state" phase --probe "$probes_dir/$fixture.json" 2>&1)"
  probe_status=$?
  set -e
  [[ "$probe_status" == "0" ]] || {
    echo "run-state.py phase on $fixture should exit 0, got: $probe_status: $probe_out" >&2
    exit 1
  }
  grep -Fq "phase: $expected reason:" <<<"$probe_out" || {
    echo "run-state.py phase should place $fixture at phase $expected, got: $probe_out" >&2
    exit 1
  }
done

# A null is a probe that could not answer, and every row below row 1 reads a
# null as "no". Rather than restart a run three steps in as fresh, the script
# stops and names the field.
set +e
null_out="$(python3 "$run_state" phase --probe "$probes_dir/unknown-branch-remote.json" 2>&1)"
null_status=$?
set -e
[[ "$null_status" == "0" ]] || {
  echo "run-state.py phase on a null field should exit 0 with a stop, got: $null_status: $null_out" >&2
  exit 1
}
grep -Fq "phase: stop reason: unknown probe fields: branch_remote" <<<"$null_out" || {
  echo "a null branch_remote should stop the run naming the field, got: $null_out" >&2
  exit 1
}

# Rows 5's two readings share a phase too: archive, or resume at the confirmation.
grep -Fq "resume at the confirmation" <<<"$(python3 "$run_state" phase --probe "$probes_dir/row-05-gated.json")" || {
  echo "row-05-gated.json should resume at the confirmation, not archive the run" >&2
  exit 1
}
grep -Fq "move it to closed/" <<<"$(python3 "$run_state" phase --probe "$probes_dir/row-05.json")" || {
  echo "row-05.json should still archive a run dir with no Waves table" >&2
  exit 1
}

# The two row-10 resumes share a phase, so the reason line is what tells them
# apart: a repair that predates the failed round is the code it refuted.
grep -Fq "dispatch the repair" <<<"$(python3 "$run_state" phase --probe "$probes_dir/row-10-repair-needed.json")" || {
  echo "row-10-repair-needed.json should resume at the repair dispatch, not at round k+1" >&2
  exit 1
}
grep -Fq "run round k+1" <<<"$(python3 "$run_state" phase --probe "$probes_dir/row-10-repair-unverified.json")" || {
  echo "row-10-repair-unverified.json should resume at round k+1, not at the repair dispatch" >&2
  exit 1
}

# A field the probe could not answer is written as null. A field that is absent
# entirely must stop the run instead of defaulting, because a silent `false`
# reads as "no branch yet" and sends a run three steps in back to Step 0.
python3 - "$probes_dir/row-01.json" "$tmp/short-probe.json" <<'PY'
import json, sys
probe = json.load(open(sys.argv[1]))
del probe["pr_state"]
json.dump(probe, open(sys.argv[2], "w"))
PY
set +e
short_probe_out="$(python3 "$run_state" phase --probe "$tmp/short-probe.json" 2>&1)"
short_probe_status=$?
set -e
[[ "$short_probe_status" == "3" ]] || {
  echo "a probe missing pr_state should exit 3, got: $short_probe_status: $short_probe_out" >&2
  exit 1
}
grep -Fq "pr_state" <<<"$short_probe_out" || {
  echo "a probe missing pr_state should name the field, got: $short_probe_out" >&2
  exit 1
}

# Row 17 used to strand an all-queued triage round: a repair dispatch never
# ran, so the old test (`repair_reports > 0`) never matched, and nothing else
# in the table did either. The Resume table's own copy has to say what the
# script now checks.
require_text work-issue/SKILL.md "or a repair report or an all-queued triage round with local ahead of origin"
# The resume path reads references/resume.md, so its copy of the table is the
# one that matters at run time, and it has to say the same thing.
require_text work-issue/references/resume.md "or a repair report or an all-queued triage round with local ahead of origin"
# Row 14's guard is what keeps a stop between the repair push and the replies
# out of the poll. Both copies carry it.
require_text work-issue/SKILL.md "| 14 | PR open; review \`pending\`; no triage row without a reply URL; no queue row missing from its comment | Step 6 poll |"
require_text work-issue/references/resume.md "| 14 | PR open; review \`pending\`; no triage row without a reply URL; no queue row missing from its comment | Step 6 poll |"
# The preamble is the only part of worker-prompt.md a worker sees, so the
# nine-field contract has to be inside it, not only documented after it.
require_text work-issue/references/worker-prompt.md "This shape replaces the six-field"
# The reproducer greps each claim's path at HEAD before it runs the command,
# and never sees files_changed, so a claim without a path cannot be checked.
require_text work-issue/references/worker-prompt.md '"path": "the repo-relative file the claim rests on"'
require_text work-issue/references/redteam.md "\`claim\`, \`path\`, \`command\`, \`output\`"
# Step 4's repairs and Step 7's carry different names, or a build repair
# reads as the repair for triage round 1 and Step 7 is skipped.
require_text work-issue/SKILL.md "lands at \`RUN_DIR/reports/redteam-repair-<k>.json\`"
require_text work-issue/references/resume.md "reports/redteam-repair-*.json <RUN_DIR>/reports/repair-*.json"
# Step 8's repair and push items run only where there is a repair and where
# there is something to push; a queue-only entry goes straight to its replies.
require_text work-issue/SKILL.md "Where the newest triage round has a repair report, red-team it"
require_text work-issue/SKILL.md "Never a no-op push"
# The follow-up's own URL, not the author's later answer, is what the line
# names, so triage quotes the reviewer and not the author.
grep -Fq "reply 2026-09-17T16:20:00Z https://github.com/kendrick/skills/pull/1#discussion_r2199481010" <<<"$(python3 "$run_state" review 1 --since 2026-09-17T16:00:00Z --author kendrick --input "$review_dir/thread-followup-then-author.json")" || {
  echo "thread-followup-then-author.json should name the reviewer's follow-up, not the author's answer" >&2
  exit 1
}
require_text work-issue/SKILL.md "or \`findings\` with the round triaged, answered, and its queue published | done: final report, then wait on the reviewer |"
require_text work-issue/references/resume.md "or \`findings\` with the round triaged, answered, and its queue published | done: final report, then wait on the reviewer |"
require_text work-issue/scripts/run-state.py "comments(last: 20)"
require_text work-issue/SKILL.md "With it: Step 0 redoes items 4, 6, and 7 (isolation, cross-run check, red-team mode) before the confirmation, then Step 1 |"
require_text work-issue/references/resume.md "With it: Step 0 redoes items 4, 6, and 7 (isolation, cross-run check, red-team mode) before the confirmation, then Step 1 |"
# None of items 4, 6, or 7 write anything durable, so a resume that named only
# the confirmation could skip item 6's cross-run check on stale values.
require_text work-issue/references/resume.md "item 6's cross-run check most of all"
# Step 0 probes before it writes, or every fresh issue reads as row 5's dead run.
require_text work-issue/SKILL.md "before anything is written under RUN_DIR"
# Row 13 stays out of the way of a review repair, in both copies of the table.
require_text work-issue/SKILL.md "| 13 | red-team clean; trigger recorded; no triage round yet; no PR, or local HEAD ahead of \`origin/issue-N\` | Step 5 |"
require_text work-issue/references/resume.md "| 13 | red-team clean; trigger recorded; no triage round yet; no PR, or local HEAD ahead of \`origin/issue-N\` | Step 5 |"
# The trigger record has an exact first line; a substring grep read `not
# fired` as fired and sent a docs diff to adversarial-review.
require_text work-issue/references/redteam.md "exactly \`fired: yes\` or \`fired: no\`"
require_text work-issue/references/resume.md "'fired: yes') echo yes"
# A missing trigger.txt is `absent`, never `no`; both copies of row 11 and
# row 13 say so.
require_text work-issue/SKILL.md "| 11 | red-team clean; \`trigger.txt\` absent, or its first line"
require_text work-issue/references/resume.md "| 11 | red-team clean; \`trigger.txt\` absent, or its first line"
require_text work-issue/SKILL.md "| 13 | red-team clean; trigger recorded;"
require_text work-issue/references/resume.md "| 13 | red-team clean; trigger recorded;"
# Step 1's two closing writes are probed, and row 7 sends a run missing either
# back to Step 1 in both copies of the table.
require_text work-issue/SKILL.md "no \`base_sha\` or no \`baseline.txt\`, or \`reports/\` lacks a report"
require_text work-issue/references/resume.md "no \`base_sha\` or no \`baseline.txt\`, or \`reports/\` lacks a report"
# The wave count reads the Waves section and nothing after it.
require_text work-issue/references/resume.md "f&&/^[[:space:]]*\\|/{t=1;print;next} f&&t{exit}"
# A false left check is a red-team failure, and the probe has to read it.
require_text work-issue/references/resume.md "\"holds\": *false"
# A reviewer's reply inside an old thread is the finding; its body has to
# reach the saved poll file, or the repair worker is handed the stale root.
set +e
python3 "$run_state" review 1 --since 2026-09-17T16:00:00Z --author kendrick \
  --input "$review_dir/thread-followup.json" --save "$tmp/followup-bundle.json" >/dev/null 2>&1
followup_status=$?
set -e
[[ "$followup_status" == "0" ]] || {
  echo "run-state.py review --save on thread-followup.json should exit 0, got: $followup_status" >&2
  exit 1
}
python3 -c "import json,sys; t=json.load(open(sys.argv[1]))['threads'][0]; sys.exit(0 if t.get('last_comment_body','').startswith('Still wrong') and t.get('last_comment_url') else 1)" "$tmp/followup-bundle.json" || {
  echo "the saved bundle should carry the reply's body and URL" >&2
  exit 1
}
# The deciding line itself has to carry the reply's URL, not just the saved
# bundle: Step 6's triage row cites the deciding line, and a fix that only
# reached --save would leave the printed line still naming the stale root.
set +e
followup_line="$(python3 "$run_state" review 1 --since 2026-09-17T16:00:00Z --author kendrick \
  --input "$review_dir/thread-followup.json" 2>&1)"
set -e
grep -Fq "reply 2026-09-17T16:20:00Z https://github.com/kendrick/skills/pull/1#discussion_r2199481010" <<<"$followup_line" || {
  echo "the deciding line for thread-followup.json should carry the reply's timestamp and URL, got: $followup_line" >&2
  exit 1
}
require_text work-issue/references/triage.md "the newest one not by the author, not always the last"
# Row 17 is post-PR; a pre-PR repair goes to row 10 or row 13, both of which
# still open the pull request.
require_text work-issue/SKILL.md "| 17 | PR open; a queue row missing from the \`Deferred findings\` comment, or a repair report"
require_text work-issue/references/resume.md "| 17 | PR open; a queue row missing from the \`Deferred findings\` comment, or a repair report"
# The queue's comment is probed, and rows 14 and 17 both read it.
require_text work-issue/SKILL.md "or a triage row without a reply URL | Step 8 |"
require_text work-issue/references/resume.md "or a triage row without a reply URL | Step 8 |"
# The probe compares the queue's rows to the comment, never just the heading:
# a comment from an earlier round satisfied the heading test while a later
# round's rows had never reached it.
require_text work-issue/references/resume.md "check every queue row, whole, against it"
# Whole rows, not Source cells: a Status moved to filed #M is a change the
# comment has to carry, and a Source-only compare read it as published.
refute_text work-issue/references/resume.md 'grep -qF -- "\| $src \|"'
refute_text work-issue/references/resume.md "grep -q '^## Deferred findings'"
# Step 8 item 4 and triage.md both described the Source-only compare the
# whole-row recipe replaced; a reader told only Sources are checked can skip
# a row whose Status changed without its Source changing.
require_text work-issue/SKILL.md "The resume probe compares every queue row, whole, against that comment"
require_text work-issue/references/triage.md "checks every queue row, whole, against it"
# The row-17 reason string named a repair report or triage round as if the
# deferred-findings comment were conjoined with them, which stopped being
# true once the comment could reach row 17 on its own.
require_text work-issue/scripts/run-state.py "row 17: the deferred-findings comment is owed, or a repair report"
# The refute above needs its own Deliberately Not Built row, or the repo's
# own rule that every refute pins a cut goes unmet.
require_text _maintenance/work-issue/RATIONALE.md "Comparing only a queue row's Source cell against the deferred-findings comment"
# The probe's exact-text comparison means a Source cell reformatted as a link
# or wrapped in backticks compares as disjoint from the queue's bare cell —
# the same failure divvy-up's owns entries hit before #97. Both places that
# describe the comment say it is copied byte-for-byte, not paraphrased.
require_text work-issue/SKILL.md "carries the queue table copied byte-for-byte"
require_text work-issue/references/triage.md "carrying the queue table copied byte-for-byte"
require_text work-issue/SKILL.md "two failed rounds in a row stop with the evidence"
require_text work-issue/references/resume.md "two failed rounds in a row stop with the evidence"
# pushed_at goes down before the push, so a same-second review still counts.
require_text work-issue/SKILL.md "Write \`date -u +%FT%TZ\` to \`RUN_DIR/pushed_at\`, then push"
# Completion of adversarial-review is read from Step 4's record of its ledger
# state, never from its run directory, which exists from preflight onward.
require_text work-issue/references/resume.md "redteam/ar-state.txt"
require_text work-issue/SKILL.md "no \`redteam/ar-state.txt\` showing \`UNVERIFIED: 0\`"
refute_text work-issue/references/resume.md "ar_run_dir"
# Step 5 item 2 clears the conflict marker, or row 12 re-runs item 1 forever.
require_text work-issue/SKILL.md "remove \`RUN_DIR/conflict.txt\`"
# The wave_tasks count reads compact rows, since the vendored parser does.
require_text work-issue/references/resume.md "grep -cE '^\\s*\\|\\s*[0-9]+\\s*\\|'"

# `--save` writes gather()'s output, before classify() ever runs on it. Ledger
# row 34 called it the "classified" bundle until a code-review pass on this
# diff caught the drift between the doc and the code it describes.
require_text _maintenance/work-issue/RATIONALE.md "gathered bundle to disk"
refute_text _maintenance/work-issue/RATIONALE.md "classified bundle to disk"

# Row 36's reproduction cites the fixture that actually carries the values it
# quotes. `row-16.json` has `triage_inscope_rows: 2`, not 0 — a code-review
# pass caught the row pointing at the wrong file.
require_text _maintenance/work-issue/RATIONALE.md "Reproduced against \`row-17-queued.json\`"

# Rows 63 and 64 named fixtures that don't carry the values they describe:
# `row-17.json` has one round, never two, and `row-10-repair-unverified.json`
# has one round too. The fixtures that actually have two rounds, the newest
# failed, are `row-10-repair-needed.json` and `row-10-failed-twice.json`.
require_text _maintenance/work-issue/RATIONALE.md "Reproduced: \`row-10-repair-needed.json\`, with two rounds"
require_text _maintenance/work-issue/RATIONALE.md "Reproduced: \`row-10-failed-twice.json\`, with two rounds"

# EVALS.md's own count of review bundles, so it can't drift from
# tests/fixtures/work-issue/review/ the way it did when this diff added two
# fixtures without touching the summary line.
require_text _maintenance/work-issue/EVALS.md "against eleven review bundles"
[[ "$(find tests/fixtures/work-issue/review -maxdepth 1 -type f | wc -l | tr -d ' ')" == "11" ]] || {
  echo "tests/fixtures/work-issue/review holds a different count than EVALS.md's 'eleven review bundles'" >&2
  exit 1
}

# The row-10/row-13 split (ledger row 58) pulled two of the "row-17 shapes"
# off row 17 entirely. A code-review pass caught EVALS.md still labeling
# them that way after the split, describing four items under a header that
# said "three more row-17 shapes" while two of the four no longer are.
require_text _maintenance/work-issue/EVALS.md "two shapes a red-team repair no longer lands on row 17 for"

# An in-session edit spliced the row-10 sentence into the middle of the
# `baseline.txt` token, leaving the coverage claim unreadable. Pin the
# repaired boundary on both sides of the splice.
require_text _maintenance/work-issue/EVALS.md "no \`base_sha\` or \`baseline.txt\`, which resumes Step 1 rather than dispatching"
require_text _maintenance/work-issue/EVALS.md "a failed round whose only repair report predates it, which resumes at the repair dispatch, and two failed rounds in a row, which stop"

# EVALS.md's own count of D6 criteria, so it can't drift from plan-good.md's
# actual OK line the way it did when this diff's own D6 fix moved the count
# from 2/2 to 3/3 and left EVALS.md quoting 2/2.
require_text _maintenance/work-issue/EVALS.md "4/4 criteria covered"
grep -Fq "OK: plan cites #101, 3 tasks with files, 0 open markers, 4/4 criteria covered" <<<"$good_out" || {
  echo "plan-good.md's OK line no longer matches EVALS.md's '4/4 criteria covered'" >&2
  exit 1
}

# The root README carries this skill's own install flag, in the map
# table's third column. The command form around it is pinned once, in
# repo-docs-smoke.sh, so this does not re-pin it twelve times.
require_text README.md "--skill work-issue"

echo "work-issue smoke: OK"
