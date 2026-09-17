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
# Two more row-17 shapes: a stop between the repair push and the replies, and
# a red-team repair with no triage round behind it. Each was a probe the table
# once sent somewhere else (row 14's poll and row 18's done).
require_file tests/fixtures/work-issue/probes/row-17-postpush.json
require_file tests/fixtures/work-issue/probes/row-17-redteam-repair.json
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
require_text work-issue/SKILL.md "| findings | any unresolved review thread whose root comment is newer than SINCE; or a \`CHANGES_REQUESTED\` review newer than SINCE; or a pull-request-level or issue comment newer than SINCE from a login other than the author that is not a bare approval |"
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
grep -Fq "OK: plan cites #101, 3 tasks with files, 0 open markers, 2/2 criteria covered" <<<"$good_out" || {
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
# The second box sits under `### Storage`, a subheading inside Open Questions.
# Tracking only the nearest heading let that one through, so D4 has to fire
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
  "row-01:done" "row-02:wait" "row-03:stop" "row-04:0" "row-05:0" "row-06:0"
  "row-07:2" "row-08:3" "row-09:3" "row-10:4" "row-11:4" "row-12:5" "row-13:5"
  "row-14:6" "row-15:6" "row-16:7" "row-17:8" "row-17-queued:8" "row-17-postpush:8"
  "row-17-redteam-repair:8" "row-18:done"
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
require_text work-issue/SKILL.md "repair report, or a triage round with no in-scope rows"
# The resume path reads references/resume.md, so its copy of the table is the
# one that matters at run time, and it has to say the same thing.
require_text work-issue/references/resume.md "repair report, or a triage round with no in-scope rows"
# Row 14's guard is what keeps a stop between the repair push and the replies
# out of the poll. Both copies carry it.
require_text work-issue/SKILL.md "| 14 | PR open; review \`pending\`; no triage row without a reply URL | Step 6 poll |"
require_text work-issue/references/resume.md "| 14 | PR open; review \`pending\`; no triage row without a reply URL | Step 6 poll |"
# The preamble is the only part of worker-prompt.md a worker sees, so the
# nine-field contract has to be inside it, not only documented after it.
require_text work-issue/references/worker-prompt.md "This shape replaces the six-field"

# The root README carries this skill's own install flag, in the map
# table's third column. The command form around it is pinned once, in
# repo-docs-smoke.sh, so this does not re-pin it twelve times.
require_text README.md "--skill work-issue"

echo "work-issue smoke: OK"
