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
require_file tests/fixtures/work-issue/plans/plan-settled.md
require_file tests/fixtures/work-issue/plans/plan-open-section.md
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
# A P2-only round whose repair diff hits a money, authz, or schema row (#162).
require_file tests/fixtures/work-issue/probes/row-17-repair-diff-trigger.json
# Row 7 with committed, unreported waves, and the run dir whose reports carry
# only the herdr agent's <task>.json names (cambium #78, #136).
require_file tests/fixtures/work-issue/probes/row-07-committed-unreported.json
require_file tests/fixtures/work-issue/reports-task-named/plan.md
require_file tests/fixtures/work-issue/review/changes-requested.json
# One over-budget probe per gated row, and the timing logs the budget reads.
for gated in 10 11 16 17; do
  require_file "tests/fixtures/work-issue/probes/row-$gated-over-budget.json"
done
# The review round cap (#159): one round under it, one at it with only P1/P2
# rows, the same round holding a P0, and a first round capped by
# --max-review-rounds 1 whose replies are still owed.
for capped in row-16-under-cap row-17-review-cap row-16-cap-blocker row-17-cap-replies-owed; do
  require_file "tests/fixtures/work-issue/probes/$capped.json"
done
# A base_sha that drifted from the live merge-base (#137), each kind of drift,
# and row 12's rebase, which moves the base on purpose and outranks the stop.
for drifted in base-sha-not-merge-base base-sha-not-ancestor row-12-stale-base row-12-stale-base-rebasing; do
  require_file "tests/fixtures/work-issue/probes/$drifted.json"
done
require_file tests/fixtures/work-issue/triage/round-2.md
require_file tests/fixtures/work-issue/triage/round-3.md
require_file tests/fixtures/work-issue/triage/round-noscope.md
for timing in build30-review61 build30-review59 poll-excluded poll-nested budget-raised open-start-closed-at-poll open-review build-25s crash-closed-at-latest open-earlier-step crash-open-other-step crash-open-poll bad-label end-with-no-start; do
  require_file "tests/fixtures/work-issue/timing/$timing.txt"
done
require_file tests/fixtures/work-issue/review/pr-comment-finding.json

[[ "$(find work-issue -maxdepth 1 -type f | wc -l | tr -d ' ')" == "2" ]] || {
  echo "work-issue/ must ship only SKILL.md and README.md at top level" >&2
  exit 1
}

# Frontmatter. Model-invocation is deliberate and load-bearing: a skill that
# runs a wave of issues reaches one lane through this one, and a user-invoked
# skill is one no sibling can call at all. The misfire guard the flag used to
# carry now sits at Step 0's confirmation, which is pinned below.
require_text work-issue/SKILL.md "name: work-issue"
# The flag coming back would not read as a bug. A sibling's Skill call
# would be refused outright, because a stripped description is stripped
# from siblings too—a wave reaches it once per lane. Refuted on the bare
# key so `: false` fails here as loudly as `: true`.
refute_text work-issue/SKILL.md "disable-model-invocation"
require_text work-issue/SKILL.md "argument-hint: '<issue number or URL> [plan path] [--isolate | --no-isolate] [--deep] [--max-review-rounds N] [--dry-run]'"

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

# --- Where the plan comes from. SKILL.md's PLAN bullet is the only place the
# four routes are written down: no script globs `docs/plans`, so a quiet edit to
# the search path changes what the skill resolves with nothing to catch it.
# Issue #112: a plan kept outside the working tree reaches a run through route 1
# or route 3 alone, and the silent fall-through to route 4 is what costs a resume. Pinned
# positively, because a refute passes just as happily on a file that dropped the
# whole bullet. ---

require_text work-issue/SKILL.md "2. \`<ROOT>/docs/plans/*issue-<N>*.md\` or \`<ROOT>/docs/plans/*-<N>-*.md\`, newest by name"
require_text work-issue/SKILL.md "reaches this run through route 1 or route 3 and no other: pass its path on the argument line, or link it from the issue"
require_text work-issue/SKILL.md "Route 4 is where missing both of those lands, and it lands silently"
require_text work-issue/SKILL.md "starts over at Step 0, where PLAN resolves in a session that no longer holds the plan"

# The README's resume line used to say "type the first line again", pointing at
# the pathless example. A user whose plan lives outside the tree would then
# resume without the path and land in exactly the row-5 window the paragraph
# below it warns about. Codex caught it on PR #115.
require_text work-issue/README.md "plan path included if you passed one"

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

# kendrick/skills#116: workers leave formatting to the orchestrator, and a
# repair re-gate never passes through divvy-up's Step 6, so it names the pass.
require_text work-issue/SKILL.md "Re-gate—the format pass"
require_text work-issue/SKILL.md "Gate it the way Step 3 gates: the format pass"
require_text work-issue/SKILL.md "scoped to the repair's reported \`files_changed\`"
# The red-team repair and the rebase repair also skip divvy-up's Step 6.
require_text work-issue/SKILL.md "Re-gate the repair as Step 3's repair is"
require_text work-issue/SKILL.md "repair dispatch, re-gated as Step 3's repair is"
# A format pass that errors reverts its writes outside the derived set before
# anything else. A repair has no WAVE_BASE, so SKILL.md says what stands in for it
# (PR #180).
require_text work-issue/SKILL.md "a repair does the same with its reported \`files_changed\` as the derived set"
# A repair has no manifest of its own, and without one the revert would
# delete every untracked file the user already had.
require_text work-issue/SKILL.md "Immediately before its format pass, a repair gate records an untracked manifest"
require_text work-issue/SKILL.md "uses HEAD plus that manifest as its WAVE_BASE"
# Step 4 item 4 and Step 5 item 2 re-gate as Step 3's repair is, so the stop
# fires there too.
require_text work-issue/SKILL.md "| The format pass's command errors naming no path in the derived set or the repair's \`files_changed\`, or none it can be tied to, or a repair already re-dispatched for a format-pass error fails it again | 3, 4, 5, 7 |"
# An error the repair caused gets a retry (PR #180 review, r4213929212), so
# the stop row names only the errors left over.
refute_text work-issue/SKILL.md "| The format pass's command itself errors |"
refute_text work-issue/SKILL.md "outside the derived set before it stops"
require_text work-issue/SKILL.md "An error naming only paths in \`files_changed\` is the repair's failure: re-dispatch the repair with the formatter's output attached"
# Mixed output can name a file the repair never touched, and a re-dispatch on
# it spends the one retry on that file (red-team round 5).
require_text work-issue/SKILL.md "output naming both a \`files_changed\` path and an outside one"
# An uncapped re-dispatch loops on a formatter the repair can't satisfy, so it
# gets the one retry divvy-up gives a failed task.
require_text work-issue/SKILL.md "once, one rung up, as \`divvy-up\`'s \`failed\` route does for a task"
require_text work-issue/SKILL.md "Where that re-dispatched repair fails the format pass the same way again, revert its writes as above and stop the run"
# The outside revert alone left the repair's own writes behind at the stop.
# Resume never reverts those, so it stopped on row 7 or re-dispatched onto
# them from row 9 (adversarial-review of #116, F-r1-authz-01).
require_text work-issue/SKILL.md "revert the repair's own writes on every branch"
require_text work-issue/SKILL.md "each one the pre-pass manifest lists as untracked is deleted"
require_text work-issue/SKILL.md "Delete any report already saved for the repair"
require_text work-issue/SKILL.md "stops the run with the tree clean"

# Step 4's trigger reads adversarial-review's table at run time through that
# skill's own script, so no signal is copied here, but which rows it reads is
# fixed here. Drop a row and the red-team phase stops firing on money, authz, or
# schema diffs while the step still reads as intact, with nothing in the output
# to say otherwise.
require_text work-issue/SKILL.md "rows 1 (money), 2 (authz), and 4 (schema) of \`adversarial-review/references/trigger-table.md\`"
# SKILL.md and redteam.md both run the match through the script (row 98). A
# grep rebuilt from the table's prose broke on the table's own `round(` recipe
# (#114), so the rebuild-the-grep wording is refuted in both files.
require_file adversarial-review/scripts/match-triggers.py
require_text work-issue/SKILL.md "git diff BASE_SHA..HEAD | adversarial-review/scripts/match-triggers.py rows --only 1,2,4"
require_text work-issue/references/redteam.md "git diff BASE_SHA..HEAD | adversarial-review/scripts/match-triggers.py rows --only 1,2,4"
# A failed script run prints nothing, and an empty output records `fired: no`.
require_text work-issue/SKILL.md "A non-zero exit decides nothing"
require_text work-issue/references/redteam.md "A non-zero exit decides nothing"
for f in work-issue/SKILL.md work-issue/references/redteam.md; do
  refute_text "$f" "Re-derive the grep from"
  refute_text "$f" "build the grep"
done
# The match only nominates the diff; a reading of each matched line decides
# (row 112, #120). The matcher is lexical, so prose "where" and "default" hit
# authz and schema, and every lane from #157 to #171 fired on docs that way.
# Both statements of the rule carry the same five sentences. The refutes pin
# the two cuts: firing on any match, and excluding markdown from the diff
# (SKILL.md is this repo's executable artifact).
for f in work-issue/SKILL.md work-issue/references/redteam.md; do
  require_text "$f" "Any output line makes the diff a candidate, and a candidate fires the trigger only where a reading confirms it."
  require_text "$f" "git diff BASE_SHA..HEAD | adversarial-review/scripts/match-triggers.py lines --only 1,2,4"
  require_text "$f" "A removed line counts as the change its removal makes."
  require_text "$f" "A line the reading cannot settle reads \`implements\`."
  require_text "$f" "\`--deep\` fires the trigger on its own, with no reading."
  require_text "$f" "an example prompt or sample session that names the hazard"
  require_text "$f" "\`reading: skipped, --deep\`"
  refute_text "$f" "any output line fires the trigger"
  refute_text "$f" "Any output line fires the trigger"
  refute_text "$f" "':!*.md'"
  refute_text "$f" "':(exclude)*.md'"
done
# Candidacy through the real script. A real money, authz, and schema change
# always reaches the reading, the removed tenant filter included, and a prose
# diff is still a candidate: the reading, not the matcher, reads it away.
trigger_fixtures=tests/fixtures/work-issue/trigger
require_file "$trigger_fixtures/hazard-code.diff"
require_file "$trigger_fixtures/prose-signal-words.diff"
hazard_rows="$(python3 adversarial-review/scripts/match-triggers.py rows --only 1,2,4 < "$trigger_fixtures/hazard-code.diff")"
[[ "$hazard_rows" == $'1 money\n2 authz\n4 schema' ]] || {
  echo "hazard-code.diff should match rows 1, 2, and 4, got: $hazard_rows" >&2
  exit 1
}
hazard_lines="$(python3 adversarial-review/scripts/match-triggers.py lines --only 1,2,4 < "$trigger_fixtures/hazard-code.diff")"
expected_hazard_lines="$(printf '%s\t%s\t%s\t%s\n' \
  "1 money" "app/billing.py" "round(" "+    total = round(order.price * order.qty, 2)" \
  "2 authz" "app/views.py" "filter(" "-    return Order.objects.filter(tenant_id=request.user.tenant_id)" \
  "4 schema" "db/0042_region.sql" "ALTER TABLE" "+ALTER TABLE orders ADD COLUMN region text NOT NULL DEFAULT 'us';")"
[[ "$hazard_lines" == "$expected_hazard_lines" ]] || {
  echo "hazard-code.diff lines output drifted, got: $hazard_lines" >&2
  exit 1
}
prose_rows="$(python3 adversarial-review/scripts/match-triggers.py rows --only 1,2,4 < "$trigger_fixtures/prose-signal-words.diff")"
[[ "$prose_rows" == $'2 authz\n4 schema' ]] || {
  echo "prose-signal-words.diff should be a candidate on rows 2 and 4, got: $prose_rows" >&2
  exit 1
}
require_text _maintenance/work-issue/RATIONALE.md "| 112 |"
require_text _maintenance/work-issue/RATIONALE.md "Firing the trigger on any matched signal, with no reading"
require_text _maintenance/work-issue/RATIONALE.md "Excluding markdown, prose, or fixture paths from the trigger diff"
require_text _maintenance/work-issue/EVALS.md "Reads Past Prose Signal Words"

# Step 0's yes answers `adversarial-review`'s own Step 2 question (row 93).
# Without that, an unattended run stops mid-run on a prompt nobody is there to
# answer. Both ends of the handoff are pinned: Step 0 item 7 says its yes
# covers the question, and Step 4 item 7 says the review fans out on it.
# references/redteam.md carries its own copy of the Step 4 sentence, and it is
# the copy an agent reads while running the trigger, so it is pinned too.
require_text work-issue/SKILL.md "Where the mode names \`adversarial-review\`, a yes to this confirmation also answers \`adversarial-review\`'s Step 2 question for this run, at any depth up to the forecast one."
require_text work-issue/SKILL.md "Where \`RUN_DIR/redteam/mode.txt\` names \`adversarial-review\`, the Step 0 yes carries into its Step 2 as that question's answer"
require_text work-issue/references/redteam.md "Where \`RUN_DIR/redteam/mode.txt\` names \`adversarial-review\`, the Step 0 yes carries into its Step 2 as that question's answer"
# The carry is only as good as its off switches. Without the missing-file
# sentence, a run that never wrote mode.txt has nothing telling it the yes did
# not carry.
require_text work-issue/SKILL.md "A missing file answers nothing, and the review asks its own question."
require_text work-issue/references/redteam.md "A missing file answers nothing, and the review asks its own question."
# The carry stops at the forecast depth (row 95). A yes to a forecast is not
# consent to a costlier real run, so a deeper derived depth has to reach the
# review's own question. Both copies of the Step 4 sentence carry the bound.
require_text work-issue/SKILL.md "but only while the depth \`adversarial-review\` derives at its Step 2 is at or below the depth forecast in \`mode.txt\`."
require_text work-issue/references/redteam.md "but only while the depth \`adversarial-review\` derives at its Step 2 is at or below the depth forecast in \`mode.txt\`."
require_text work-issue/SKILL.md "A deeper derived depth answers nothing"
require_text work-issue/references/redteam.md "A deeper derived depth answers nothing"
# The bound needs a depth to compare against, so Step 0 has to forecast one.
require_text work-issue/SKILL.md "Take \`<n>\` from the Depth table in \`adversarial-review\`'s Step 2, applied to the plan's owned paths."
# Step 0's forecast feeds the owned paths to Step 4's script as an all-added
# diff (row 99). Bare file contents carry no `+`, so the script matched nothing and
# every run without `--deep` forecast `reproduce claims`.
require_text work-issue/SKILL.md "git diff \$(git hash-object -t tree /dev/null) HEAD -- <the plan's owned paths> | adversarial-review/scripts/match-triggers.py rows --only 1,2,4"
# In a work-issue-only install the forecast pipe exits 127 with a bare shell
# error (row 100), so Step 0 checks for the sibling first and refuses by name.
# Vendoring the script and table instead is a Deliberately Not Built row: the
# review still could not run, and the copied table would stop gaining rows.
require_text work-issue/SKILL.md "Where either is missing, refuse the run here and name \`adversarial-review\` as the sibling to install, before anything is dispatched, because every Step 4 path needs it"
require_text work-issue/SKILL.md "\`adversarial-review\`'s script and trigger table were both found"
for f in work-issue/SKILL.md work-issue/references/redteam.md; do
  refute_text "$f" "work-issue/scripts/match-triggers.py"
done
require_text _maintenance/work-issue/RATIONALE.md "A vendored copy of \`match-triggers.py\` and the trigger table inside \`work-issue\`"
# The README promised a run that never asks again, and the forecast gap and
# the budget stop (#158) both mean one can. Pinned so both exceptions stay
# at the point a user decides to walk away.
require_text work-issue/README.md "After yes, the run is unattended, with two exceptions."
require_text work-issue/README.md "\`adversarial-review\` can ask again, when the real diff trips a review the confirmation didn't forecast"
require_text work-issue/README.md "the run stops before the next review cycle and asks whether to raise the ratio"

# `--deep` fires the trigger without a match, so Step 0 item 7 names the
# review for a `--deep` run as well. Without this clause, a `--deep` run whose
# forecast match missed reaches the review's Step 2 question with no yes
# covering it (row 93).
require_text work-issue/SKILL.md "or \`reproduce claims, then adversarial-review (--deep; depth 2 forecast)\` when \`--deep\` is set, since that flag fires the trigger on its own."
# Step 0 forecasts depth 2 for a `--deep` run, and the review pins Depth 2 only
# from its own `--deep`. Step 4 passes the flag on so the forecast is the depth
# that runs (row 95). Both copies of the invocation carry it.
require_text work-issue/SKILL.md "Pass \`--deep\` on to it where this run carries \`--deep\`, so the review pins the Depth 2 that Step 0 forecast for a \`--deep\` run."
require_text work-issue/references/redteam.md "Pass \`--deep\` on to it where this run carries \`--deep\`, so the review pins the Depth 2 that Step 0 forecast for a \`--deep\` run."
# The review's Step 2 checks its derived depth against a confirmation the
# wrapper hands it. A resumed run has no conversation holding the yes, so the
# mode.txt line travels in the invocation, or the review asks (row 94).
require_text work-issue/SKILL.md "hand the review that file's line, verbatim, in the same invocation, as the wrapping skill's confirmation its Step 2 checks the derived depth against"
require_text work-issue/references/redteam.md "hand the review that file's line, verbatim, in the same invocation, as the wrapping skill's confirmation its Step 2 checks the derived depth against"
# adversarial-review reads the handed-over line as quoted text, which only
# works if the sender marks where it starts; an unquoted --deep line would
# run into the flags beside it.
require_text work-issue/SKILL.md "Put the line last, after the fixed point and any flags, wrapped in double quotes"
require_text work-issue/references/redteam.md "Put the line last, after the fixed point and any flags, wrapped in double quotes"

# Step 4 tests mode.txt before it carries the yes. Resume rows 10 and 11 jump
# straight to Step 4, and a resumed session never saw the confirmation, so the
# file is the only record of what the user agreed to (row 94).
require_text work-issue/SKILL.md "Once the user answers yes, write the red-team mode line this message carried to \`RUN_DIR/redteam/mode.txt\`"
# A row-5 resume re-asks the confirmation, and a stale mode.txt from the first
# yes would otherwise carry a mode the latest confirmation never showed.
require_text work-issue/SKILL.md "to \`RUN_DIR/redteam/mode.txt\`, replacing any earlier copy"
require_text work-issue/references/resume.md "The yes to the re-asked confirmation rewrites \`redteam/mode.txt\`"

# Step 4 reaches `adversarial-review` by invoking it. Reading its SKILL.md and
# running the steps inline goes around the host's invocation gate and forks
# the review from the installed skill (row 93). #124 rules out any wording
# that treats a refusal as something to route past, and "by other means" is
# the likeliest wording of that route.
refute_text work-issue/SKILL.md "by other means"
refute_text work-issue/references/redteam.md "by other means"

# The absent-sibling branch. With no route past a refusal, a missing sibling
# has one outcome: the step that needs it stops and names it. Without this
# sentence, nothing tells a run what to do when a sibling is absent.
require_text work-issue/SKILL.md "Where one is not installed, the step that needs it stops and says which."

# --- Step 4's caller rule. The worker and the reproducer both build their
# fixtures by hand, so both hand the seam an input shaped by the same
# assumptions, and the production caller shares none of them. Issue #109
# records a seam that shipped with five mutations and a five-case probe behind
# it and its boundary never examined. Four documents state the rule. Drop it
# from one of them and the run stops following it with nothing in the output
# to say so, so each of the four gets a pin below. ---

# The rule itself, in Step 4 item 2. A sentence that names callers without
# telling the reproducer to drive one satisfies a grep while leaving the
# caller undriven, so the pin carries the verb. The ledger's "Moving the
# caller rule into `adversarial-review`" row names this pin as its hold. That
# skill fires on trigger rows 1, 2, and 4 only, and this rule has to run on
# every claim.
require_text work-issue/SKILL.md "Where a claim concerns a seam some production caller reaches at HEAD, its last reproduction drives that caller rather than the seam."

# Step 4's Done-when. Drop the caller-versus-seam clause and the step
# completes on a verdict that never says where it ran, so nobody reading the
# pull request can see the weaker case: the seam held against an input the
# reproducer built itself. The clause binds every verdict, which is what item
# 2 and EVALS Scenario 16 both require. A `NOT_REPRODUCED` verdict is the one
# whose repair depends on knowing where it failed.
require_text work-issue/SKILL.md "every verdict whose command ran says whether it was reproduced at the caller or at the seam, and a seam-only one carries the caller search that decided it, while a verdict where no command ran carries \`reproduced_at\` null"

# Step 4 item 4's repair evidence. On a caller-level failure the verdict's
# top-level `command` and `output` hold the seam run, which is green. A
# dispatch built from them hands the repair worker a passing command and no
# sign of the failure it has to fix. The `otherwise` is load-bearing: a claim
# the change-exists grep refuted carries `reproduced_at` null, and a branch
# written as `caller` versus `seam` leaves that dispatch no evidence to send.
require_text work-issue/SKILL.md "\`NOT_REPRODUCED\` sends a repair dispatch carrying the run that failed—\`caller.command\` and \`caller.output\` where \`reproduced_at\` is \`caller\`, and the top-level \`command\` and \`output\` otherwise"

# Step 5 item 5 is where the caller-versus-seam split reaches a reader. A
# label with no evidence under it reads the same for either, so the body
# carries each claim's own run: `caller.command` for a caller claim, the seam
# command plus the reason it stopped there for a seam one. The seam cases are
# enumerated in references/redteam.md and pointed at from here, so the list of
# them stays a one-place edit.
require_text work-issue/SKILL.md "a \`caller\` claim carries \`caller.command\` and the tail of \`caller.output\`, and a \`seam\` claim carries the seam's own command with the case from [references/redteam.md](references/redteam.md) that sent it there"

# Step 5's Done-when. Item 5 can be skipped without failing the step unless
# the step's completion criterion names it, and nothing after Step 5 writes
# the body again, so the omission ships.
require_text work-issue/SKILL.md "marks every claim its verification section names \`caller\` or \`seam\` with that claim's own command and output tail beneath it, leaves each \`UNVERIFIABLE\` claim to"

# The subsection heading. Step 4 item 2 sends the orchestrator to
# references/redteam.md before it dispatches, and this heading is where the
# rule the reproducer follows begins.
require_text work-issue/references/redteam.md "### Drive the nearest production caller"

# The search itself, pinned whole. A pathspec exclusion drops a whole file, so
# excluding the claim's path takes the seam's definition and every caller
# sitting beside it, and the reproducer then reads a called seam as a seam
# nothing calls. Row 87 holds the scratch repo where `normalize` and
# `production_handler` share one `app.py` and that search exits 1 with no
# output. Pinning the argument list whole catches a fourth exclusion added
# back in any spelling.
require_text work-issue/references/redteam.md "git -C TREE grep -n -w <symbol> HEAD -- . ':!*test*' ':!*spec*' ':!*fixture*'"

# The reason, which is what a later editor needs before deciding the claim's
# own file is noise. Without that sentence the inclusion reads like an
# oversight and the exclusion comes straight back.
require_text work-issue/references/redteam.md "The claim's own file stays in range. A seam and the production caller above it share a file often enough that excluding the claim path drops both"

# The ordering, which is issue #109's first non-goal: the caller reproduction
# is added to the seam reproduction, never swapped for it. A caller-only run
# loses the comparison that separates a seam wrong everywhere from a seam
# wrong only at its caller. The ledger's "Replacing the seam reproduction with
# the caller reproduction" row names this pin as its hold.
require_text work-issue/references/redteam.md "The seam reproduction stays and the caller reproduction comes last: run the claim's command at the seam first, then find the change's production callers at HEAD and drive the nearest one."

# Where the input goes in decides whether the caller run buys anything. A
# reproducer that hands the seam an argument it built itself has rebuilt the
# worker's fixture, however many hops it took to get there, and the boundary
# stays unexamined.
require_text work-issue/references/redteam.md "Whatever the reproducer supplies goes in at the caller's boundary, and the caller constructs what reaches the seam."

# No production caller among the hits is an answer, not a stop and not an
# `UNVERIFIABLE`. Step 4 item 5 spends `UNVERIFIABLE` on claims nobody could
# check at all, and this claim was checked. The search is the evidence for it,
# so the step has to record it rather than leave a reader to infer it from a
# missing field. Row 86 keeps the pathspec wide, so the usual answer is hits
# that name the symbol and run it nowhere; a bullet promising an empty
# `caller.output` leaves that case with no shape to write.
require_text work-issue/references/redteam.md "**No production caller among the hits.** \`caller.path\` is null, \`caller.search\` carries the grep and \`caller.output\` what it returned—nothing, or the hits that named the symbol and ran it nowhere—and \`reproduced_at\` is \`seam\`."

# The two fields every verdict entry carries beside `verdict`, pinned on the
# example the reproducer copies its shape from. `caller` is pinned whole: a
# file that keeps the key and drops `search` loses the one field that lets a
# reader audit a seam-only verdict.
require_text work-issue/references/redteam.md "\"reproduced_at\": \"caller\","
require_text work-issue/references/redteam.md "\"caller\": {\"search\": \"\", \"path\": \"\", \"command\": \"\", \"output\": \"\"}"

# The third route to `reproduced_at: seam`, beside the absent caller and the
# undrivable one. A reproducer that reaches the seam with an argument it built
# itself has rebuilt the worker's fixture however many hops it took, and the
# verdict has to say so. Step 5 item 5 sends the pull-request body to this
# list for the reason a claim stopped at the seam, so a route missing here is
# a seam claim the body cannot explain.
require_text work-issue/references/redteam.md "- **The seam's argument built by hand.** A run that hands the seam an argument the reproducer constructed has built the same fixture again"

# The prompt block is the only part of redteam.md the dispatched reproducer
# ever sees. A caller rule written into the prose above it and left out of the
# prompt reads correct to whoever reviews the file and never reaches the
# agent, which makes the subsection documentation of a step nothing performs.
# So every grep below is scoped to the block instead of to the file. The block
# is unwrapped first, because it is hard-wrapped and every sentence in it
# spans lines. Its bounds are the fence itself: the first inner `sed` drops
# everything through the opening ```, the second drops everything from the
# closing ``` onward. Ending the range at the next `### ` heading instead
# would be a bound the file can revoke—demote `### Verdict JSON` to `##
# Verdict JSON` and the range runs to end of file, so a prose copy of the rule
# pasted anywhere below satisfies every grep while the prompt itself has lost
# it. A fence has no level to demote.
prompt_block="$(sed -n '/^### The prompt$/,$p' work-issue/references/redteam.md | sed '1,/^```$/d' | sed '/^```$/,$d' | tr '\n' ' ' | tr -s ' ')"

grep -Fq -- "Drive the nearest one, and let the caller build the seam's input out of whatever you supply at its boundary" <<<"$prompt_block" || {
  echo "work-issue/references/redteam.md: the prompt block no longer tells the reproducer to drive the nearest production caller" >&2
  exit 1
}

grep -Fq -- "Where a command ran, report \`reproduced_at\` as \`caller\` or \`seam\`, and a \`caller\` object carrying that search" <<<"$prompt_block" || {
  echo "work-issue/references/redteam.md: the prompt block no longer asks the reproducer for reproduced_at and the caller object" >&2
  exit 1
}

# The third route to `reproduced_at: seam`, scoped to the block because the
# block is the only part of this file the dispatched reproducer reads. The
# prose above already tells it not to hand-build the seam's argument; without
# this sentence the block never says that a run which did it anyway records
# `seam`, so the reproducer reports `caller` and the weaker verdict goes
# invisible. The prose-level pin on the same route sits further up.
grep -Fq -- "Where you reached the seam with an argument you built yourself, say so" <<<"$prompt_block" || {
  echo "work-issue/references/redteam.md: the prompt block no longer sends a hand-built seam argument to reproduced_at: seam" >&2
  exit 1
}

# The caller search excludes tests and nothing else, so on a documentation
# repo it returns ledgers and agent docs that name the symbol without running
# it. The reproducer is the one holding that hit list, so the warning has
# to be in the prompt and not only in the prose a reviewer reads.
grep -Fq -- "The search is wide and returns prose that only names the symbol, so pick a hit that runs it." <<<"$prompt_block" || {
  echo "work-issue/references/redteam.md: the prompt block no longer warns that the caller search returns prose" >&2
  exit 1
}

# The search's argument list inside the prompt, which is the only copy the
# dispatched reproducer runs. The prose copy above can be right while the
# prompt still carries a claim-path exclusion, and the rule is then
# documentation of a search nobody performs.
grep -Fq -- "git -C TREE grep -n -w <symbol> HEAD -- . ':!*test*' ':!*spec*' ':!*fixture*'" <<<"$prompt_block" || {
  echo "work-issue/references/redteam.md: the prompt block's caller search no longer matches the documented exclusions" >&2
  exit 1
}

grep -Fq -- "The claim's own file stays in range, because a caller often sits in the same file as the seam it calls." <<<"$prompt_block" || {
  echo "work-issue/references/redteam.md: the prompt block no longer says the claim's own file stays in the caller search" >&2
  exit 1
}

# Neither `caller` nor `seam` is true of a claim nothing ran for, and two
# claims land there: one that arrived with no command, and one the
# change-exists grep refuted before its command ran. Left unsaid here, the
# reproducer fills the field from the two values it was given, and Step 5
# publishes a reproduction site for a claim nobody reproduced.
grep -Fq -- "\`reproduced_at\` is null wherever no command ran, and two claims reach that" <<<"$prompt_block" || {
  echo "work-issue/references/redteam.md: the prompt block no longer tells the reproducer to leave reproduced_at null wherever no command ran" >&2
  exit 1
}

# --- `reproduced_at` on a claim nothing ran for. Two claims land there. The
# report contract sends a claim with no command to `UNVERIFIABLE`, which Step 4
# item 5 routes to the pull request's "Not independently verified" section, and
# an empty change-exists grep refutes a claim before its command runs, which is
# a `NOT_REPRODUCED` bound for repair. Neither `caller` nor `seam` is true of
# either, so the field carries null and the verification section never marks
# them. Seven sites state that rule and all seven are pinned: the two
# Done-whens above, the prompt-block grep above, and the four below. A site
# that drops it leaves Step 5 inventing a reproduction site and an output tail
# for work nobody checked. ---

# Step 4 item 2, where the reproducer's contract is written.
require_text work-issue/SKILL.md "Every verdict carries \`reproduced_at\` beside its \`verdict\`: \`caller\` or \`seam\` where a command ran, and \`null\` wherever none did—an \`UNVERIFIABLE\` claim, which arrived with no command, and a claim the change-exists grep refuted before its command ran."

# Step 5 item 5, which builds the pull-request body. The label and the section
# have to move together: a claim marked neither `caller` nor `seam` with
# nothing saying where it went is a claim the body silently drops.
require_text work-issue/SKILL.md "an \`UNVERIFIABLE\` claim ran nothing, carries \`reproduced_at\` null, and belongs to the next section"

# The gloss under the verdict JSON, which is what the reproducer reads when it
# is deciding what to write into the field.
require_text work-issue/references/redteam.md "and \`null\` wherever no command ran. Two claims reach null: one that arrived with no command, which is \`UNVERIFIABLE\`, and one the change-exists grep refuted before its command ran"

# The README's summary of `reproduced_at` has to carry all three of its
# values. A copy naming only caller and seam describes a field that cannot
# say what happened to a claim nobody could run, which is the case Step 4
# item 5 routes to its own pull-request section.
require_text work-issue/README.md "and names neither where no command ran at all"

# The README's red-team paragraph is where a human learns what the phase does.
# A copy that stops at the seam describes a weaker check than the one Step 4
# runs, and no other assertion in this file covers that sentence.
require_text work-issue/README.md "the reproducer searches HEAD for the change's production callers and drives the nearest one, since the caller builds the seam's input by a route no hand-made fixture takes"

# The ledger row behind the `REPRODUCED_AT_CALLER` refute in the cut-features
# loop below. AGENTS.md asks every refute to correspond to a Deliberately Not
# Built row, so pinning the cut name keeps that refute traceable to the
# decision that made it instead of leaving a bare string nobody can account
# for.
require_text _maintenance/work-issue/RATIONALE.md "A fourth verdict value such as \`REPRODUCED_AT_CALLER\`"

# The ledger row behind the `:!<claim` refute in the same loop, held to the
# same AGENTS.md rule: a refute is traceable to the decision that made the cut.
require_text _maintenance/work-issue/RATIONALE.md "Excluding the claim's path from the caller search"

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

# #135: three lanes committed wave 0 and went idle with wave 1 ready,
# printing nothing. SKILL.md's "next gate and stops" and divvy-up's "move to
# the next wave" both held at a committed wave, so the opening now defines a
# gate as a listed stop and Step 2 says the wave loop runs to the last wave.
require_text work-issue/SKILL.md "A gate here means one of the stops listed under [Where a Run Stops](#where-a-run-stops)"
require_text work-issue/SKILL.md "A settled wave with a later wave pending is not a stopping point."
require_text work-issue/SKILL.md "Step 2 continues until every wave in \`## Waves\` is settled"
require_text work-issue/SKILL.md "the Step 0 yes covers every one of them, not wave 0 alone"
require_text work-issue/SKILL.md "the next wave in \`## Waves\` is dispatched in the same turn, or none is left"
require_text work-issue/SKILL.md "has stopped outside this list, and that is a defect in the run"
require_text work-issue/README.md "dispatches the next one in the same turn"
refute_text work-issue/SKILL.md "next gate and stops."
refute_text work-issue/README.md "next gate and stops."

# PR #178 review: a wave that changed nothing passes its gate with no
# commit, so a loop that waits on "committed" stalls there. The loop advances
# on "settled", which covers both.
require_text work-issue/SKILL.md "A wave is **settled** once its commit lands, or once its gate passes on a wave that changed nothing"
require_text work-issue/SKILL.md "Once the last wave in \`## Waves\` is settled"
require_text work-issue/SKILL.md "once Step 3 settles that wave"
require_text work-issue/SKILL.md "**Done when:** every wave in \`## Waves\` settled"
require_text work-issue/README.md "so its markers alone move the run on"
refute_text work-issue/SKILL.md "Step 2 continues until every wave in \`## Waves\` is committed"
refute_text work-issue/SKILL.md "Once the last wave in \`## Waves\` is committed"
refute_text work-issue/README.md "Once the last wave is committed"

# Where a Run Stops is the closed list of places an invocation may end
# (#135). A row with no message is a silent stop written into the contract,
# and a quoted message that only the table still carries describes a stop
# the step no longer prints.
stops_header='| Stop | Step | What the run prints or writes |'
require_text work-issue/SKILL.md "$stops_header"
awk -v h="$stops_header" '
  $0 == h { on = 1; getline; next }
  on && /^\|/ { print; next }
  on { exit }
' work-issue/SKILL.md > "$tmp/stops.txt"
stops_rows="$(wc -l < "$tmp/stops.txt" | tr -d ' ')"
[[ "$stops_rows" -eq 26 ]] || {
  echo "Where a Run Stops lists $stops_rows stops, expected 26" >&2
  exit 1
}
while IFS= read -r row; do
  msg="$(awk -F'|' '{ print $4 }' <<<"$row" | sed 's/^ *//; s/ *$//')"
  [[ -n "$msg" && "$msg" != "—" && "$msg" != "-" ]] || {
    echo "stop with no message or marker: $row" >&2
    exit 1
  }
  while IFS= read -r q; do
    [[ -n "$q" ]] || continue
    q="${q#\"}"; q="${q%\"}"
    [[ "$(grep -cF -- "$q" work-issue/SKILL.md || true)" -ge 2 ]] || {
      echo "quoted stop message appears only in the table: $q" >&2
      exit 1
    }
  done < <(grep -oE '"[^"]+"' <<<"$msg" || true)
done < "$tmp/stops.txt"

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

  # A fourth verdict value. Step 4's routing, the probe's `redteam_last_failed`
  # regex in run-state.py, and that script's row 10 all split on the
  # same three values, and that regex's alternation is unanchored:
  # REPRODUCED_AT_CALLER scores as nothing to it, and
  # NOT_REPRODUCED_AT_CALLER scores as a plain failure. `reproduced_at`
  # carries the distinction past all three readers instead. The substring
  # catches both spellings. RATIONALE.md stays outside work_issue_docs for
  # this refute's sake. The ledger row documenting the cut spells the value
  # out, so a refute reaching the ledger would fail on the row that records
  # the decision.
  refute_text "$doc" "REPRODUCED_AT_CALLER"

  # Excluding the claim's own path from the caller search. It was meant to skip
  # the symbol's definition line and a pathspec exclusion drops the whole file,
  # so a caller sharing a file with the seam it calls went with the definition
  # and the reproducer recorded a called seam as a seam nothing calls. The
  # prefix stops short of the closing quote so a reworded placeholder is
  # caught too.
  # RATIONALE.md stays outside work_issue_docs, which is what lets the row
  # documenting the cut spell the exclusion out.
  refute_text "$doc" ":!<claim"

  # Attribution trailers and generation footers. Every commit message, pull
  # request body, and thread reply this skill authors goes out without one.
  refute_text "$doc" "Co-Authored-By"
  refute_text "$doc" "Generated with"

  # Ending an invocation at a committed wave for the user to re-invoke. Row 7
  # resumes it, but every wave then costs a human turn in a run promised
  # unattended past one confirmation (#135).
  refute_text "$doc" "stop after each wave"
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
# The heading itself is indented two spaces in the fixture, which CommonMark
# allows and a column-1 heading pattern read as prose, losing both boxes.
[[ "$(grep -c "D4 unchecked box under heading 'Open Questions'" <<<"$thin_out")" == "2" ]] || {
  echo "plan-thin.md should fail D4 on both boxes, the nested one included, got: $thin_out" >&2
  exit 1
}

# #129: issue #113's plan was refused at "The four that settle an open
# question", a sentence closing questions, because `open question` sat in the
# phrase list with no gate. plan-settled's only candidate is that sentence, so
# any D3 line at all means the phrase is unconditional again.
set +e
settled_out="$(python3 "$check_plan" "$plans/plan-settled.md" --issue 101 2>&1)"
settled_status=$?
set -e
[[ "$settled_status" == "0" ]] || {
  echo "plan-settled.md should exit 0, got: $settled_status: $settled_out" >&2
  exit 1
}
grep -Fq "OK: plan cites #101, 1 tasks with files, 0 open markers, 0/0 criteria covered" <<<"$settled_out" || {
  echo "plan-settled.md should print its full OK line, got: $settled_out" >&2
  exit 1
}
if grep -Fq "D3" <<<"$settled_out"; then
  echo "plan-settled.md should carry no D3 line at all, got: $settled_out" >&2
  exit 1
fi
# Line 13 sits under `## Risks and uncertainties` and says how the plan handles
# the risk. A heading needs `open` before `uncertainties` to mark its items
# open, or every plan's mitigated-risks list is refused.
if grep -Fq "line 13:" <<<"$settled_out"; then
  echo "plan-settled.md should not name its answered risk at line 13, got: $settled_out" >&2
  exit 1
fi
# Line 17 sits under `## Counting unresolved threads`, a topic that happens to
# contain the word. `unresolved` marks a section open only when it opens the
# heading. Line 21's heading holds `open questions` inside backticks, which is
# a name being quoted, so the heading test skips backtick spans.
for settled_line in 17 21; do
  if grep -Fq "line $settled_line:" <<<"$settled_out"; then
    echo "plan-settled.md should not name its topic-heading item at line $settled_line, got: $settled_out" >&2
    exit 1
  fi
done
# Lines 26 and 28 record answers under a ticked and a struck item. Closing an
# item closes whatever is nested under it, or the answer fails the gate.
for settled_line in 26 28; do
  if grep -Fq "line $settled_line:" <<<"$settled_out"; then
    echo "plan-settled.md should not name the answer nested under a closed item at line $settled_line, got: $settled_out" >&2
    exit 1
  fi
done
# Line 30 settles one open question and answers another. Each occurrence has
# its own resolving verb, so a rule that fires on any second occurrence fails
# here.
if grep -Fq "line 30:" <<<"$settled_out"; then
  echo "plan-settled.md should not name its doubly settled sentence at line 30, got: $settled_out" >&2
  exit 1
fi
# Line 34's heading opens with a quoted command name, then `unresolved` as a
# topic word (F-r2-authz-02). Deleting the backtick span before the lead test
# put `unresolved` at the front and failed the item, so the lead test swaps the
# span for a placeholder word that keeps the name in first position.
if grep -Fq "line 34:" <<<"$settled_out"; then
  echo "plan-settled.md should not name the item under a quoted-name topic heading at line 34, got: $settled_out" >&2
  exit 1
fi
# Line 39 answers a struck `10.` item, nested at that item's content column,
# four spaces in. It is the passing case for a marker wider than `- `. A
# content column counted past the start of the item's text fails it.
if grep -Fq "line 39:" <<<"$settled_out"; then
  echo "plan-settled.md should not name the answer nested under a struck ordered item at line 39, got: $settled_out" >&2
  exit 1
fi

# The same #113 plan passed clean with a list of genuinely open items under
# `## Open uncertainties`, since none of them used a marker phrase. Line numbers
# are exact: a heading walk that fires on the wrong line, or a gate that lets the
# unresolved prose on line 9 through, is as broken as one that stays silent.
set +e
open_section_out="$(python3 "$check_plan" "$plans/plan-open-section.md" --issue 101 2>&1)"
open_section_status=$?
set -e
[[ "$open_section_status" == "1" ]] || {
  echo "plan-open-section.md should exit 1, got: $open_section_status: $open_section_out" >&2
  exit 1
}
grep -Fq "check-plan: line 9: D3 open marker 'open question'" <<<"$open_section_out" || {
  echo "plan-open-section.md should fail D3 on its unresolved open-question prose at line 9, got: $open_section_out" >&2
  exit 1
}
# Line 13 reads "Unresolved; settled by a live run." A resolving verb in the
# item's text must not close it; only striking or ticking the item does.
grep -Fq "check-plan: line 13: D3 unresolved item under heading 'Open uncertainties'" <<<"$open_section_out" || {
  echo "plan-open-section.md should fail D3 on the unresolved item at line 13, got: $open_section_out" >&2
  exit 1
}
# Line 14 is struck through. A walk that refused it would push authors to
# delete settled items rather than record them.
if grep -Fq "line 14:" <<<"$open_section_out"; then
  echo "plan-open-section.md should not name its struck item at line 14, got: $open_section_out" >&2
  exit 1
fi
# Line 18 is the colon label, and its tail carries "resolve". The phrase opens
# its sentence, so no resolving verb takes it as its object and the line fails.
grep -Fq "check-plan: line 18: D3 open marker 'open question'" <<<"$open_section_out" || {
  echo "plan-open-section.md should fail D3 on the label at line 18, got: $open_section_out" >&2
  exit 1
}
# Line 20 is the bold label, followed by "answer the open question". The verb
# clears the second occurrence only. The leading one has no verb in front of it,
# so the line still fails.
grep -Fq "check-plan: line 20: D3 open marker 'open question'" <<<"$open_section_out" || {
  echo "plan-open-section.md should fail D3 on the bold label at line 20, got: $open_section_out" >&2
  exit 1
}
# Line 22 reads "Whether the key is resolved remains an open question." The
# sentence holds `resolv`, but not as a verb taking the question, so the
# question stays open. A test for any resolving word anywhere lets it pass.
grep -Fq "check-plan: line 22: D3 open marker 'open question'" <<<"$open_section_out" || {
  echo "plan-open-section.md should fail D3 on the still-open question at line 22, got: $open_section_out" >&2
  exit 1
}
# Lines 26 and 30 are the D3/D4 handoff. A box under `## Open questions` is
# D4's alone, and a box under `## Unresolved`, which D4 does not read, is D3's
# alone.
grep -Fq "check-plan: line 26: D4 unchecked box under heading 'Open questions'" <<<"$open_section_out" || {
  echo "plan-open-section.md should fail D4 on the box at line 26, got: $open_section_out" >&2
  exit 1
}
if grep -Fq "line 26: D3" <<<"$open_section_out"; then
  echo "plan-open-section.md should not report the D4 box at line 26 under D3 too, got: $open_section_out" >&2
  exit 1
fi
grep -Fq "check-plan: line 30: D3 unresolved item under heading 'Unresolved'" <<<"$open_section_out" || {
  echo "plan-open-section.md should fail D3 on the box at line 30, got: $open_section_out" >&2
  exit 1
}
# The fixture's title avoids the word "open". D4 matches any heading above a
# box, the H1 included, so an "open-section" title would take line 30 from D3.
if grep -Fq "line 30: D4" <<<"$open_section_out"; then
  echo "plan-open-section.md should not report the box at line 30 under D4, got: $open_section_out" >&2
  exit 1
fi
# Lines 36, 37, 41, and 42 sit under task headings about unresolved threads,
# the second with the word in backticks. A task heading names work to do, so
# its title never marks its items open, and a plan about run-state.py's thread
# count stays passable.
# Those four pass on the leading-word rule too. Lines 61 and 62, under a task
# about parsing open questions, are the pin only the task exemption holds.
for open_line in 36 37 41 42 61 62; do
  if grep -Fq "line $open_line:" <<<"$open_section_out"; then
    echo "plan-open-section.md should not name the task item at line $open_line, got: $open_section_out" >&2
    exit 1
  fi
done
# Line 44 settles one open question and leaves another. The gate decides per
# occurrence: a resolved one in the same sentence must not clear the live one.
grep -Fq "check-plan: line 44: D3 open marker 'open question'" <<<"$open_section_out" || {
  echo "plan-open-section.md should fail D3 on the live second question at line 44, got: $open_section_out" >&2
  exit 1
}
# Under `## Open items`, the answer at line 49 is nested under a ticked item
# and line 53 under a struck one, so both are closed. Line 50 is a sibling at
# the ticked item's indent, which ends the exemption, and line 51 is nested
# under that open sibling. Line 57 is indented, but the unindented paragraph at
# line 55 ended the list the struck item closed.
for open_line in 49 53; do
  if grep -Fq "line $open_line:" <<<"$open_section_out"; then
    echo "plan-open-section.md should not name the answer nested under a closed item at line $open_line, got: $open_section_out" >&2
    exit 1
  fi
done
for open_line in 50 51 57; do
  grep -Fq "check-plan: line $open_line: D3 unresolved item under heading 'Open items'" <<<"$open_section_out" || {
    echo "plan-open-section.md should fail D3 on the open item at line $open_line, got: $open_section_out" >&2
    exit 1
  }
done
# Lines 66, 70, and 74 sit under state headings wrapped in emphasis
# (F-r2-authz-01). The lead test was anchored at the heading's first character,
# so `**` or `_` in front of the label hid it and all three items passed.
for open_pair in "66|**Unresolved**" "70|_Undecided_" "74|3. **Unresolved**"; do
  open_line="${open_pair%%|*}"
  open_heading="${open_pair#*|}"
  grep -Fq "check-plan: line $open_line: D3 unresolved item under heading '$open_heading'" <<<"$open_section_out" || {
    echo "plan-open-section.md should fail D3 on the item under '$open_heading' at line $open_line, got: $open_section_out" >&2
    exit 1
  }
done
# Lines 79 and 82 sit past a struck item's marker but short of its content
# column: one column in after `- `, two after `10. ` (F-r2-authz-03).
# CommonMark renders each as a new open item, not an answer nested under the
# struck one, so an exemption for anything deeper than the marker let both pass.
for open_line in 79 82; do
  grep -Fq "check-plan: line $open_line: D3 unresolved item under heading 'Open decisions'" <<<"$open_section_out" || {
    echo "plan-open-section.md should fail D3 on the sibling of a struck item at line $open_line, got: $open_section_out" >&2
    exit 1
  }
done
# Line 88 is indented under a new heading, right after the ticked item at line
# 84 closed the section above (F-r2-state-01). It is deep enough to pass as
# that item's answer, so only the heading's reset of the closed-item state
# catches it, and no other line in either fixture needs that reset.
grep -Fq "check-plan: line 88: D3 unresolved item under heading 'Still open items'" <<<"$open_section_out" || {
  echo "plan-open-section.md should fail D3 on the item under a new heading at line 88, got: $open_section_out" >&2
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
  "row-07:2" "row-07-isolation-incomplete:1" "row-07-committed-unreported:stop" "row-08:3" "row-09:3" "row-10:4" "row-11:4" "row-11-trigger-unrecorded:4" "row-12:5" "row-13:5"
  "row-14:6" "row-15:6" "row-16:7" "row-17:8" "row-17-queued:8" "row-17-postpush:8"
  "row-10-repair-unverified:4" "row-10-repair-needed:4" "row-10-failed-twice:stop" "row-13-prepr-repair-clean:5" "row-16-earlier-queued:8" "row-17-review-repair-unpushed:8" "row-17-deferred-owed:8" "row-17-worker-queue:8" "row-18-answered:done" "row-18:done"
  "row-17-repair-advisory-only:8" "row-17-repair-blocking:8" "row-17-repair-blocking-settled:8" "row-17-repair-diff-trigger:8"
  "row-10-over-budget:stop" "row-11-over-budget:stop" "row-16-over-budget:stop" "row-17-over-budget:stop"
  "row-16-under-cap:7" "row-17-review-cap:8" "row-16-cap-blocker:stop" "row-17-cap-replies-owed:8"
  "row-12-stale-base:5" "row-12-stale-base-rebasing:5" "base-sha-not-merge-base:stop" "base-sha-not-ancestor:stop"
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

# A base_sha that drifted from the live merge-base (#137) stops naming which
# drift, because the two have different causes: a rebase the run never
# recorded, or a default branch rewritten under it. On cambium #78 every review
# after the rebase diffed four other merged PRs as the issue's own change.
for drift in not-merge-base not-ancestor; do
  drift_out="$(python3 "$run_state" phase --probe "$probes_dir/base-sha-$drift.json")"
  grep -Fq "phase: stop reason: base_sha mismatch ($drift):" <<<"$drift_out" || {
    echo "base-sha-$drift.json should stop naming the $drift mismatch, got: $drift_out" >&2
    exit 1
  }
done
# The same probe with the base current is plain row 17, so the stop above is
# the field's doing and not something else the fixture carries.
python3 -c 'import json, sys
probe = json.load(open(sys.argv[1]))
assert probe["base_sha_state"] == "not-merge-base"
probe["base_sha_state"] = "current"
json.dump(probe, open(sys.argv[2], "w"))' "$probes_dir/base-sha-not-merge-base.json" "$tmp/base-sha-current.json"
current_out="$(python3 "$run_state" phase --probe "$tmp/base-sha-current.json")"
grep -Fq "phase: 8 reason: row 17:" <<<"$current_out" || {
  echo "base-sha-not-merge-base.json with base_sha_state current should land on row 17, got: $current_out" >&2
  exit 1
}
# git could not answer: the null-field stop, not a mismatch and not a pass.
python3 -c 'import json, sys
probe = json.load(open(sys.argv[1]))
probe["base_sha_state"] = None
json.dump(probe, open(sys.argv[2], "w"))' "$probes_dir/row-17.json" "$tmp/null-base-state.json"
null_base_out="$(python3 "$run_state" phase --probe "$tmp/null-base-state.json")"
grep -Fq "phase: stop reason: unknown probe fields: base_sha_state" <<<"$null_base_out" || {
  echo "a null base_sha_state should stop the run naming the field, got: $null_base_out" >&2
  exit 1
}
python3 -c 'import json, sys
probe = json.load(open(sys.argv[1]))
probe["base_sha_state"] = None
json.dump(probe, open(sys.argv[2], "w"))' "$probes_dir/unknown-branch-remote.json" "$tmp/null-both.json"
grep -Fq "phase: stop reason: unknown probe fields: branch_remote, base_sha_state" <<<"$(python3 "$run_state" phase --probe "$tmp/null-both.json")" || {
  echo "unknown-branch-remote.json with base_sha_state null too should stop naming both fields" >&2
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

# Step 8 item 1's re-fire rule (#151, work-issue row 97). A repair whose round
# held only P2 rows gets the reproducer and nothing more, so the run goes
# straight to pushing and replying. One P1 row sends it back into
# adversarial-review until that review settles. Re-firing after every repair
# is what ran cambium #23/#26 to 7 cycles per lane.
advisory_reason="$(python3 "$run_state" phase --probe "$probes_dir/row-17-repair-advisory-only.json")"
grep -Fq "adversarial-review" <<<"$advisory_reason" && {
  echo "a repair whose round held only P2 rows must not re-enter adversarial-review, got: $advisory_reason" >&2
  exit 1
}
blocking_reason="$(python3 "$run_state" phase --probe "$probes_dir/row-17-repair-blocking.json")"
# The resume starts item 1 from the reproducer until the repair's trigger
# file exists, so a stop before the reproducer ran can't skip it.
grep -Fq "resume at Step 8 item 1 from the reproducer where trigger-repair-<k>.txt is absent" <<<"$blocking_reason" || {
  echo "a repair whose round held a P1 row must re-enter Step 8 item 1 from the reproducer, got: $blocking_reason" >&2
  exit 1
}
settled_reason="$(python3 "$run_state" phase --probe "$probes_dir/row-17-repair-blocking-settled.json")"
grep -Fq "adversarial-review" <<<"$settled_reason" && {
  echo "a repair whose adversarial-review settled must move on to the push, got: $settled_reason" >&2
  exit 1
}
# The second re-fire condition (#162). A reviewer can label a real money,
# authz, or schema blocker P2, so a round of P2 rows alone still re-fires when
# the repair's own diff hits trigger rows 1, 2, or 4. The twin is the same
# probe with the flag false, and it must fall through to row 17's push leg.
# Both land at phase 8, so the reason is what tells them apart.
diff_reason="$(python3 "$run_state" phase --probe "$probes_dir/row-17-repair-diff-trigger.json")"
grep -Fq "phase: 8 reason: row 17:" <<<"$diff_reason" && grep -Fq "resume at Step 8 item 1 from the reproducer where trigger-repair-<k>.txt is absent" <<<"$diff_reason" || {
  echo "a P2-only repair whose own diff hits a trigger row must re-enter Step 8 item 1 from the reproducer, got: $diff_reason" >&2
  exit 1
}
python3 -c 'import json, sys
probe = json.load(open(sys.argv[1]))
assert probe["triage_blocking_rows"] == 0 and probe["repair_diff_triggers"] is True
probe["repair_diff_triggers"] = False
json.dump(probe, open(sys.argv[2], "w"))' "$probes_dir/row-17-repair-diff-trigger.json" "$tmp/repair-diff-quiet.json"
quiet_reason="$(python3 "$run_state" phase --probe "$tmp/repair-diff-quiet.json")"
grep -Fq "phase: 8 reason: row 17: the deferred-findings comment is owed" <<<"$quiet_reason" || {
  echo "the same P2-only repair with a quiet diff should land past the re-fire leg on row 17's push leg, got: $quiet_reason" >&2
  exit 1
}
grep -Fq "adversarial-review" <<<"$quiet_reason" && {
  echo "a P2-only repair with a quiet diff must not re-enter adversarial-review, got: $quiet_reason" >&2
  exit 1
}
# A candidate repair diff the reading reads away (row 112). The probe still
# flags the diff, and trigger-repair-<k>.txt holds `fired: no`, which settles
# the review. The flag is set by hand here, so this guards phase_of's routing
# of a settled candidate, not the probe gatherer that sets the flag.
python3 -c 'import json, sys
probe = json.load(open(sys.argv[1]))
assert probe["repair_diff_triggers"] is True
probe["repair_ar_settled"] = True
json.dump(probe, open(sys.argv[2], "w"))' "$probes_dir/row-17-repair-diff-trigger.json" "$tmp/repair-diff-read-away.json"
read_away_reason="$(python3 "$run_state" phase --probe "$tmp/repair-diff-read-away.json")"
grep -Fq "phase: 8 reason: row 17: the deferred-findings comment is owed" <<<"$read_away_reason" || {
  echo "a candidate repair diff read away to fired: no should move on to row 17's push leg, got: $read_away_reason" >&2
  exit 1
}
grep -Fq "adversarial-review" <<<"$read_away_reason" && {
  echo "a candidate repair diff read away to fired: no must not re-enter adversarial-review, got: $read_away_reason" >&2
  exit 1
}
# The #158 budget gate covers the new condition too: it starts a review cycle.
python3 -c 'import json, sys
probe = json.load(open(sys.argv[1]))
probe["review_over_budget"] = True
json.dump(probe, open(sys.argv[2], "w"))' "$probes_dir/row-17-repair-diff-trigger.json" "$tmp/repair-diff-over.json"
grep -Fq "phase: stop reason: row 17: review time is over budget" <<<"$(python3 "$run_state" phase --probe "$tmp/repair-diff-over.json")" || {
  echo "a P2-only repair re-firing on its own diff should hit the row-17 budget stop when over budget" >&2
  exit 1
}

# The budget stop (#158). The same row-16 probe gives Step 7 under budget and
# stops over it, and the stop keeps its row prefix so the Resume tables suite
# can hold it to row 16's cell. A null is a probe that could not read the log,
# and it stops like every other non-nullable field.
over_reason="$(python3 "$run_state" phase --probe "$probes_dir/row-16-over-budget.json")"
grep -Fq "phase: stop reason: row 16: review time is over budget" <<<"$over_reason" || {
  echo "a row-16 probe over budget should stop at row 16, got: $over_reason" >&2
  exit 1
}
grep -Fq "phase: 7 reason: row 16:" <<<"$(python3 "$run_state" phase --probe "$probes_dir/row-16.json")" || {
  echo "the same row-16 probe under budget should resume at Step 7" >&2
  exit 1
}
python3 -c 'import json, sys
probe = json.load(open(sys.argv[1]))
probe["review_over_budget"] = None
json.dump(probe, open(sys.argv[2], "w"))' "$probes_dir/row-16.json" "$tmp/null-budget.json"
grep -Fq "phase: stop reason: unknown probe fields: review_over_budget" <<<"$(python3 "$run_state" phase --probe "$tmp/null-budget.json")" || {
  echo "a null review_over_budget should stop the run naming the field" >&2
  exit 1
}

# The review round cap (#159). A fresh review of new code nearly always finds
# something, so without a cap P2 threads hold a lane in Steps 6-8 for good.
# The Nth round is triaged and answered but never repaired: it falls through
# row 16 to row 17's replies. The same probe one round earlier still repairs.
cap_reason="$(python3 "$run_state" phase --probe "$probes_dir/row-17-review-cap.json")"
grep -Fq "phase: 8 reason: row 17:" <<<"$cap_reason" || {
  echo "a round at the review cap with only P1/P2 rows should skip the repair and land on row 17, got: $cap_reason" >&2
  exit 1
}
under_reason="$(python3 "$run_state" phase --probe "$probes_dir/row-16-under-cap.json")"
grep -Fq "phase: 7 reason: row 16:" <<<"$under_reason" || {
  echo "the same round under the review cap should resume at Step 7, got: $under_reason" >&2
  exit 1
}
# A P0 or blocking row at the cap is never queued: queueing it ships a known
# blocker, and repairing it breaks the cap. The run stops for a human, and the
# reason says why so the human doesn't re-derive it.
blocker_reason="$(python3 "$run_state" phase --probe "$probes_dir/row-16-cap-blocker.json")"
grep -Fq "phase: stop reason: row 16:" <<<"$blocker_reason" \
  && grep -Fq "review round cap" <<<"$blocker_reason" \
  && grep -Fq "P0 or blocking" <<<"$blocker_reason" || {
  echo "a capped round holding a P0 row should stop at row 16 naming the cap and the blocker, got: $blocker_reason" >&2
  exit 1
}
# Under --max-review-rounds 1 no repair report exists anywhere, and the capped
# round has in-scope rows, so a stop after the deferred comment posted and
# before the replies finished once matched row 18's done with a reply owed.
owed_reason="$(python3 "$run_state" phase --probe "$probes_dir/row-17-cap-replies-owed.json")"
grep -Fq "phase: 8 reason: row 17:" <<<"$owed_reason" || {
  echo "a capped first round with a reply still owed should land on row 17, got: $owed_reason" >&2
  exit 1
}
# The cap sits ahead of the #158 budget gate on row 16. A capped round starts
# no review cycle, only replies and the queue, and the budget stop exists for
# the points that start one; ahead of the cap it stranded the replies.
for pair in "row-17-review-cap:phase: 8 reason: row 17:" "row-16-cap-blocker:phase: stop reason: row 16: the newest triage round is at the review round cap"; do
  python3 -c 'import json, sys
probe = json.load(open(sys.argv[1]))
probe["review_over_budget"] = True
json.dump(probe, open(sys.argv[2], "w"))' "$probes_dir/${pair%%:*}.json" "$tmp/cap-over.json"
  got="$(python3 "$run_state" phase --probe "$tmp/cap-over.json")"
  grep -Fq "${pair#*:}" <<<"$got" || {
    echo "an over-budget ${pair%%:*} should give '${pair#*:}' ahead of the budget stop, got: $got" >&2
    exit 1
  }
done

# The cap's prose (#159). phase_of only reads the probe; the agent is what
# writes the cap file, queues the capped rows, and stops on a blocker, so each
# of those instructions is pinned where the agent reads it. The flag reaches
# the probe only through Step 0's write, and a missing file silently reads 2.
require_text work-issue/SKILL.md "\`--max-review-rounds N\` caps the post-PR review loop at N triage rounds, default 2, and Step 0 writes it to \`RUN_DIR/max_review_rounds\`"
require_text work-issue/SKILL.md "Write the \`--max-review-rounds\` value, \`2\` where the flag is absent, to \`RUN_DIR/max_review_rounds\`."
require_text work-issue/SKILL.md "\`baseline.txt\`, \`max_review_rounds\`, \`pushed_at\`"
# N is a positive integer: 0 would cap round 1, so no post-PR finding ever got
# a repair, and nothing downstream checks the file's value. A resume skips
# Step 0, so the flag it passes changes nothing; the file is the lever.
require_text work-issue/SKILL.md "Where \`--max-review-rounds\` is given a value that is not a positive integer, \`0\` included, refuse the run naming that value, before anything is written under RUN_DIR."
require_text work-issue/SKILL.md "where a resume keeps it: to change the cap mid-run, write another positive integer to that file before the round it would cap is triaged"
require_text work-issue/README.md "\`--max-review-rounds N\` sets the review round cap (2 by default)"
# The queue sentence names what it queues. Written as "the rest" after the cap
# sentences, it read as the remainder of a capped round.
require_text work-issue/README.md "The out-of-scope ones go to a queue carrying the reason each is outside"
# The queue reason, which the Step 8 reply and the deferred-findings comment
# both carry to the reviewer, so it has to be the one string the issue names.
require_text work-issue/SKILL.md "Each in-scope row's Scope cell reads \`in scope; queued: review round cap reached (N)\`, and the row is appended to \`queue.md\` with Outside-because \`review round cap reached (N)\`."
require_text work-issue/references/triage.md "The review round cap is the one reason an in-scope row gets queued."
require_text work-issue/references/triage.md "each in-scope row's Scope cell reads \`in scope; queued: review round cap reached (N)\`, and the row is appended to \`queue.md\` with Outside-because \`review round cap reached (N)\`"
require_text work-issue/SKILL.md "A capped round (Step 6) skips this step: it gets no dispatch, no \`repair-base-<k>\`, and no \`repair-<k>.json\`"
require_text work-issue/SKILL.md "the rows the review round cap queued with \`review round cap reached (N)\`"
# The P0/blocking exception, and only those two: P1 stays under the cap, which
# is why the exception reads triage_stop_rows and not triage_blocking_rows.
require_text work-issue/SKILL.md "The exception is an in-scope row whose Severity is \`P0\` or \`blocking\`: its Scope cell stays \`in scope\`, and the run stops once the round is written, naming the cap and that row, for a human to decide."
require_text work-issue/references/triage.md "An in-scope row whose Severity is \`P0\` or \`blocking\` is never queued this way."
require_text _maintenance/work-issue/RATIONALE.md "| 106 | \`--max-review-rounds N\`, default 2, caps the post-PR review loop"
require_text _maintenance/work-issue/RATIONALE.md "\`P0\` and \`blocking\` are the exception because queueing one ships a known blocker, and repairing it breaks the cap"
require_text _maintenance/work-issue/RATIONALE.md "rather than reusing \`triage_blocking_rows\` as the issue proposed"

# Each timing fixture through the real `budget`. poll-excluded is the
# falsifier for what counts as review: counting wall-clock time since the
# build would put it at 80 min against 30 and print `over: yes`. poll-nested
# is the layout Step 6 actually writes, its poll inside the `6` bracket,
# which ignoring poll lines without subtracting them read as 80 min too.
# open-start-closed-at-poll's open `4` interval is covered by the poll after
# it, so only the 5 min before the poll counts. crash-closed-at-latest is a
# crashed `6` closed at its last stamp by SKILL.md's close-first rule, so the
# 4.5 h it sat dead counts toward nothing. build-25s is a build under 30 s,
# which rounds to 0m and once read 5 h of review as `ratio: n/a over: no`.
# open-earlier-step leaves `3` open when the run resumes at Step 4, and
# crash-open-other-step leaves `7` open across a crash before Step 8: the
# next step's start ends each at the stamp before it. Left open, the first
# grew build with the clock to 235m and the second charged 4 h of dead time
# to review.
# crash-open-poll leaves a `poll` open across a crash that resumes straight
# into triage, where no new poll triggers the close-first rule. The next `6`
# start ends it too; left open it covered the 61 min of triage after it and
# printed `review: 0m over: no`.
timing_dir=tests/fixtures/work-issue/timing
declare -a budget_cases=(
  "build30-review61:build: 30m review: 61m ratio: 2.03 over: yes"
  "build30-review59:build: 30m review: 59m ratio: 1.97 over: no"
  "poll-excluded:build: 30m review: 20m ratio: 0.67 over: no"
  "budget-raised:build: 20m review: 60m ratio: 3.00 over: no"
  "poll-nested:build: 30m review: 20m ratio: 0.67 over: no"
  "open-start-closed-at-poll:build: 30m review: 5m ratio: 0.17 over: no"
  "crash-closed-at-latest:build: 30m review: 15m ratio: 0.50 over: no"
  "build-25s:build: 0m review: 300m ratio: 720.00 over: yes"
  "open-earlier-step:build: 20m review: 210m ratio: 10.50 over: yes"
  "crash-open-other-step:build: 30m review: 40m ratio: 1.33 over: no"
  "crash-open-poll:build: 30m review: 61m ratio: 2.03 over: yes"
)
for case in "${budget_cases[@]}"; do
  fixture="${case%%:*}"
  expected="${case#*:}"
  got="$(python3 "$run_state" budget --timing "$timing_dir/$fixture.txt")"
  [[ "$got" == "$expected" ]] || {
    echo "budget on $fixture.txt should print '$expected', got: $got" >&2
    exit 1
  }
done
# budget-raised.txt minus its raise is the 3x run the raise clears.
grep -v '^budget-raised' "$timing_dir/budget-raised.txt" >"$tmp/unraised.txt"
[[ "$(python3 "$run_state" budget --timing "$tmp/unraised.txt")" == *"ratio: 3.00 over: yes" ]] || {
  echo "the 3x run without its budget-raised line should be over budget" >&2
  exit 1
}
# An in-run check passes --now, which closes the running step at that moment.
# Without it the open `4 start` is the log's newest stamp, and Step 4 reads as
# 0 min of review however long it runs.
[[ "$(python3 "$run_state" budget --timing "$timing_dir/open-review.txt" --now 2026-01-01T01:40:00Z)" == "build: 30m review: 70m ratio: 2.33 over: yes" ]] || {
  echo "budget --now should close the open 4 start 70 min on and print over: yes" >&2
  exit 1
}
[[ "$(python3 "$run_state" budget --timing "$timing_dir/open-review.txt")" == "build: 30m review: 0m ratio: 0.00 over: no" ]] || {
  echo "budget without --now should close the open 4 start at the log's newest stamp" >&2
  exit 1
}
set +e
python3 "$run_state" budget --timing "$timing_dir/open-review.txt" --now not-a-time >/dev/null 2>&1
bad_now_status=$?
set -e
[[ "$bad_now_status" == "3" ]] || {
  echo "budget with an unreadable --now should exit 3, got: $bad_now_status" >&2
  exit 1
}
# An explicit --ratio outranks the log's budget-raised line for that check;
# with none, the line outranks 2.0.
[[ "$(python3 "$run_state" budget --timing "$timing_dir/budget-raised.txt" --ratio 2.5)" == *"ratio: 3.00 over: yes" ]] || {
  echo "budget --ratio 2.5 should beat the log's budget-raised 4.0 on a 3x run" >&2
  exit 1
}
# A missing log is every run that predates timing.log: under budget. Anything
# else that can't be read exits 3, since reading it as under budget fails in
# the permissive direction.
[[ "$(python3 "$run_state" budget --timing "$tmp/no-such-timing.log")" == "build: 0m review: 0m ratio: n/a over: no" ]] || {
  echo "budget on a missing log should print over: no" >&2
  exit 1
}
for unreadable in "$timing_dir/bad-label.txt" "$timing_dir/end-with-no-start.txt" "$timing_dir"; do
  set +e
  python3 "$run_state" budget --timing "$unreadable" >/dev/null 2>&1
  unreadable_status=$?
  set -e
  [[ "$unreadable_status" == "3" ]] || {
    echo "budget on $unreadable should exit 3, got: $unreadable_status" >&2
    exit 1
  }
done

# The log's writers. Without them the budget reads an empty log as under
# budget forever.
require_text work-issue/SKILL.md 'echo "<n> start $(date -u +%FT%TZ)" >> RUN_DIR/timing.log'
require_text work-issue/SKILL.md "with \`poll start\` written to \`RUN_DIR/timing.log\` before the first poll and \`poll end\` after the last"
require_text work-issue/SKILL.md "A raise appends \`budget-raised <ratio>\` to the log"
# Every in-run check passes --now; the resume probe does not, so a crashed
# run's dead hours stay out.
require_text work-issue/SKILL.md 'budget --timing RUN_DIR/timing.log --now "$(date -u +%FT%TZ)"'
refute_text work-issue/references/resume.md "budget --timing <RUN_DIR>/timing.log --now"
# The close-first rule, which ends a crashed interval at the log's newest stamp.
require_text work-issue/SKILL.md "append \`<n> end <latest>\` first"
require_text work-issue/SKILL.md "awk 'NF == 3 { print \$3 }' RUN_DIR/timing.log | sort | tail -1"
require_text work-issue/references/resume.md "Passing \`--ratio <r>\` to one \`budget\` command outranks every \`budget-raised\` line"
require_text work-issue/SKILL.md "the queue, the \`budget\` line,"

# #139: a triage round is current by the SINCE its heading recorded, never by
# the file's time, because Step 8 edits the round after the push it answers.
require_text work-issue/SKILL.md "# Triage round <k>, since <SINCE>"
require_text work-issue/references/triage.md "# Triage round <k>, since <SINCE>"
require_text work-issue/references/resume.md "| 15 | PR open; \`findings\`; no triage round recorded against the current SINCE | Step 6 triage |"
require_text _maintenance/work-issue/RATIONALE.md "Comparing a triage round's file time against \`pushed_at\`"
refute_text work-issue/references/resume.md "compare its mtime against"
refute_text work-issue/SKILL.md "compare its mtime against"
refute_text work-issue/references/resume.md "no \`triage/round-<k>.md\` newer than SINCE"
refute_text work-issue/SKILL.md "no \`triage/round-<k>.md\` newer than SINCE"

# Step 2 names both report names as ones the probe accepts, so it and resume.md
# agree on what counts. Row 7's revert stops at HEAD in both Resume tables, and
# phase stops on the committed count rather than resuming past it (#136).
require_text work-issue/SKILL.md "The resume probe counts a task as reported when either \`<wave>-<task>.json\` or \`<task>.json\` exists"
require_text work-issue/SKILL.md "revert only the uncommitted changes the half-written wave left in its owned paths, back to HEAD, then re-record WAVE_BASE"
require_text work-issue/references/resume.md "revert only the uncommitted changes the half-written wave left in its owned paths, back to HEAD, then re-record WAVE_BASE"
require_text work-issue/scripts/run-state.py 'count(probe, "wave_unreported_committed")'
require_text _maintenance/work-issue/RATIONALE.md "Counting wave reports with a filename glob"
require_text _maintenance/work-issue/RATIONALE.md "Resuming past a committed, unreported wave as though it were reported"
refute_text work-issue/references/resume.md "find <RUN_DIR>/reports -name '[0-9]*-*.json'"
refute_text work-issue/scripts/run-state.py 'return "3", "row 7'
# A report counts only beside clean owned paths, and cells keep inner spaces
# (PR #176 review; rows 117 and 118).
require_text work-issue/SKILL.md "and gate evidence from Step 3: the task's \`gated/<wave>-<task>\` marker, or, on a run with no \`gated/\` directory, a commit past BASE_SHA on its owned paths"
require_text work-issue/references/resume.md "delete each unreported task's reports under both names and its \`gated/<wave>-<task>\` marker, then revert only"
require_text work-issue/SKILL.md "delete each unreported task's reports under both names and its \`gated/<wave>-<task>\` marker, then revert only"
require_text _maintenance/work-issue/RATIONALE.md "Counting a report on disk as a gated task"
require_text _maintenance/work-issue/RATIONALE.md "Stripping every space from a \`## Waves\` cell"
refute_text work-issue/SKILL.md "still reads as reported rather than as a half-written wave"
refute_text work-issue/references/resume.md 'gsub(/[ \t]/,"",k)'
# Clean owned paths don't prove the gate ran: a count needs a gate marker or a
# commit too, and Step 3 writes the marker (PR #176 review; row 119).
require_text work-issue/SKILL.md "write an empty \`RUN_DIR/gated/<wave>-<task>\` for each of that wave's tasks"
require_text _maintenance/work-issue/RATIONALE.md "Clean owned paths as proof the gate ran"
require_text _maintenance/work-issue/RATIONALE.md "A gate marker as the only gate evidence"
refute_text work-issue/references/resume.md 'elif [ -z "$s" ]; then echo 1; fi'
refute_text work-issue/references/resume.md "A reported task whose paths are clean counts"
refute_text work-issue/references/resume.md 'gated/$w-$k" ]; then echo 1; fi'
# A commit is gate evidence only on a run with no gated/ directory; on every
# run it let an earlier wave's commit pass a later task's gate (row 119).
require_text _maintenance/work-issue/RATIONALE.md "The commit leg on every run"
refute_text work-issue/references/resume.md '[ -z "$p" ]; then continue; elif ! o='

# The rewrite has one owner and one repeat. The BASE_SHA bullet names both and
# claims nothing else writes the file, and Step 8 item 2 names the rewrite
# outright, so an edit that inlines Step 8's steps cannot drop it silently.
require_text work-issue/SKILL.md "Written to \`RUN_DIR/base_sha\` by Step 1, and rewritten by Step 5 item 2 after each proven rebase, which Step 8 item 2 repeats; nothing else writes the file."
require_text work-issue/SKILL.md 'm="$(git merge-base origin/DEFAULT issue-N)" && printf '"'"'%s\n'"'"' "$m" > RUN_DIR/base_sha'
# Step 8 item 1 reads the repair's diff with the same ancestor check the
# repair_diff_triggers probe runs, or a resume after item 2's rebase re-fires
# adversarial-review over upstream code the probe already ignores.
require_text work-issue/SKILL.md "A \`repair-base-<k>\` that is no longer an ancestor of HEAD leaves this condition unmet too"
require_text work-issue/SKILL.md "rebase, rewrite \`RUN_DIR/base_sha\`, verify, write \`pushed_at\`, push — Step 5 items 1 through 4, the \`base_sha\` rewrite in item 2 included."
require_text work-issue/references/resume.md "answers \`stop\` naming the mismatch"
require_text work-issue/SKILL.md "answers \`stop\` naming the mismatch"
require_text _maintenance/work-issue/EVALS.md "A Rebase Mid-Run Moves the Fixed Point With It"
# A mismatch stops for a human. A probe that healed the file itself would adopt
# whatever base a manual rebase left, one taken before the red-team included.
refute_text work-issue/references/resume.md "> <RUN_DIR>/base_sha"
refute_text work-issue/references/resume.md ">\"<RUN_DIR>/base_sha"
refute_text work-issue/references/resume.md "> \"<RUN_DIR>/base_sha"
refute_text work-issue/references/resume.md ">><RUN_DIR>/base_sha"
# The refute above needs its own Deliberately Not Built row.
require_text _maintenance/work-issue/RATIONALE.md "The resume probe rewriting a stale \`base_sha\`"

# --- probe ---
# `run-state.py probe` gathers every field phase reads (#146). Every case below
# runs the real script and reads the field out of its JSON, and the whole-run
# cases hand that JSON to the real phase, so a gatherer is judged by what phase
# makes of it rather than by a copy of its logic. The fake gh and herdr lead
# PATH for the whole section: probe must never call either, because herdr's
# CLI is a cache and GitHub's answer arrives as --pr-bundle.
probe_bin="$tmp/fakebin"
mkdir -p "$probe_bin"
for fake in gh herdr; do
  printf '#!/bin/sh\ntouch "%s/called-$(basename "$0")"\nexit 99\n' "$tmp" >"$probe_bin/$fake"
  chmod +x "$probe_bin/$fake"
done
bundles_dir=tests/fixtures/work-issue/pr-bundles
probe_asserted="$tmp/probe-asserted"
: >"$probe_asserted"
# Pinned identity, no signing, no hooks, as scope_git: the user's global git
# config must not decide whether a throwaway commit succeeds.
probe_git() {
  git -C "$1" -c user.name=smoke -c user.email=smoke@example.invalid \
    -c commit.gpgsign=false -c core.hooksPath=/dev/null "${@:2}"
}
# DIR on main with one commit, pushed to a bare DIR.origin whose HEAD names main.
make_repo() {
  git init -q -b main "$1"
  git init -q --bare -b main "$1.origin"
  printf 'seed\n' >"$1/seed.txt"
  probe_git "$1" add seed.txt
  probe_git "$1" commit -q -m seed
  probe_git "$1" remote add origin "$1.origin"
  probe_git "$1" push -q origin main 2>/dev/null
}
# RUN REPO [ARGS...]: probe's stdout. Stderr lands in $tmp/probe-stderr, since
# a gatherer that answers null says why there.
run_probe() {
  PATH="$probe_bin:$PATH" env -u HERDR_ENV python3 "$run_state" probe \
    --run-dir "$1" --root "$2" --issue 1 "${@:3}" 2>"$tmp/probe-stderr"
}
# FIELD RUN REPO [ARGS...]: that field as JSON, recorded for the coverage check.
probe_field() {
  local out
  out="$(run_probe "${@:2}")" || { echo "probe exited non-zero: $(cat "$tmp/probe-stderr")"; return 0; }
  echo "$1" >>"$probe_asserted"
  python3 -c 'import json,sys; print(json.dumps(json.load(sys.stdin)[sys.argv[1]]))' "$1" <<<"$out"
}
# LABEL FIELD WANT RUN REPO [ARGS...]. The value stays in $probe_got for a
# case that goes on to hand it to phase.
expect_field() {
  probe_got="$(probe_field "$2" "${@:4}")"
  [[ "$probe_got" == "$3" ]] || { echo "probe $2 $1: expected $3, got: $probe_got" >&2; exit 1; }
}
# FIXTURE FIELD VALUE: phase's line for a hand-written probe with one field
# replaced by the value probe gathered.
field_phase() {
  python3 -c 'import json,sys; p=json.load(open(sys.argv[1])); p[sys.argv[2]]=json.loads(sys.argv[3]); json.dump(p,open(sys.argv[4],"w"))' \
    "$probes_dir/$1" "$2" "$3" "$tmp/field-phase.json"
  python3 "$run_state" phase --probe "$tmp/field-phase.json"
}
# FIXTURE RUN TREE: phase's line for a hand-written probe whose three wave
# fields come from probe on RUN and TREE, so row 7's routing is judged on
# gathered values rather than typed ones.
wave_phase() {
  run_probe "$2" "$3" >"$tmp/wave-gathered.json" || {
    echo "probe on $2 should exit 0, got: $(cat "$tmp/probe-stderr")" >&2; exit 1; }
  python3 -c 'import json,sys; p=json.load(open(sys.argv[1])); g=json.load(open(sys.argv[2])); p.update({k: g[k] for k in ("wave_tasks", "wave_reports", "wave_unreported_committed")}); json.dump(p,open(sys.argv[3],"w"))' \
    "$probes_dir/$1" "$tmp/wave-gathered.json" "$tmp/wave-phase.json"
  python3 "$run_state" phase --probe "$tmp/wave-phase.json"
}
# LABEL WANT OUT: phase's line OUT carries WANT.
expect_phase() {
  grep -Fq -- "$2" <<<"$3" || { echo "$1 should give '$2', got: $3" >&2; exit 1; }
}
# LABEL ARGS...: probe must exit 3 with nothing on stdout and a run-state: line.
expect_probe_usage() {
  local label="$1" out status
  shift
  set +e
  out="$(PATH="$probe_bin:$PATH" env -u HERDR_ENV python3 "$run_state" probe "$@" 2>"$tmp/probe-stderr")"
  status=$?
  set -e
  [[ "$status" == 3 && -z "$out" ]] || {
    echo "probe $label should exit 3 with nothing on stdout, got $status: $out $(cat "$tmp/probe-stderr")" >&2; exit 1; }
  # argparse's own complaint for a flag it rejects, a run-state: line for the rest.
  grep -qE '^run-state: |: error: ' "$tmp/probe-stderr" || {
    echo "probe $label should say why on stderr, got: $(cat "$tmp/probe-stderr")" >&2; exit 1; }
}
# The names phase checks, read from run-state.py itself rather than typed here,
# so a field added to PROBE_FIELDS without a case below fails the coverage check.
probe_names="$(python3 - "$run_state" <<'PY'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("run_state", sys.argv[1])
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
print("\n".join(name for name, _, _ in module.PROBE_FIELDS))
PY
)"

# Five whole run dirs, each holding only what its row needs. Each one's phase
# line has to equal the line phase prints for the hand-written probe of the
# same row, read from phase at test time so a reworded reason stays matched.
write_waves() {
  printf '# Plan\n\n## Waves\n\n| Wave | Task | Files owned | Model | Done when | Constraints |\n|---|---|---|---|---|---|\n' >"$1/plan.md"
  local t
  for t in 0 1 2 3 4 5; do
    printf '| %s | task-%s | t%s.py | sonnet | x | |\n' "$((t / 2))" "$t" "$t" >>"$1/plan.md"
  done
}
make_run() {
  local kind="$1" run="$tmp/whole-$1/run" repo="$tmp/whole-$1/repo" t
  mkdir -p "$tmp/whole-$kind"
  make_repo "$repo"
  [[ "$kind" == fresh ]] && return 0
  probe_git "$repo" checkout -q -b issue-1
  mkdir -p "$run/reports" "$run/gated"
  write_waves "$run"
  probe_git "$repo" rev-parse HEAD >"$run/base_sha"
  echo "verify: ok" >"$run/baseline.txt"
  if [[ "$kind" == midbuild || "$kind" == merged ]]; then
    # Three of six tasks reported and gated, under both names Step 2 writes.
    echo '{}' >"$run/reports/0-task-0.json"
    echo '{}' >"$run/reports/task-1.json"
    echo '{}' >"$run/reports/1-task-2.json"
    echo '{}' >"$run/reports/task-2.json"
    : >"$run/gated/0-task-0"
    : >"$run/gated/0-task-1"
    : >"$run/gated/1-task-2"
    return 0
  fi
  for t in 0 1 2 3 4 5; do
    echo '{}' >"$run/reports/task-$t.json"
    : >"$run/gated/$((t / 2))-task-$t"
  done
  mkdir -p "$run/review" "$run/redteam"
  echo "# Self-review" >"$run/review/self-1.md"
  echo '{}' >"$run/reports/build-final.json"
  echo '{"claims": [{"id": 1, "verdict": "REPRODUCED"}]}' >"$run/redteam/round-1.json"
  echo "fired: no" >"$run/redteam/trigger.txt"
  probe_git "$repo" push -q origin issue-1 2>/dev/null
  if [[ "$kind" == propen ]]; then echo 2026-09-20T11:00:00Z >"$run/pushed_at"; fi
  return 0
}
# KIND FIXTURE [ARGS...]
whole_case() {
  local kind="$1" fixture="$2" want got
  run_probe "$tmp/whole-$kind/run" "$tmp/whole-$kind/repo" "${@:3}" >"$tmp/whole-$kind.json" || {
    echo "probe on the $kind run dir should exit 0, got: $(cat "$tmp/probe-stderr")" >&2; exit 1; }
  got="$(python3 -c 'import json,sys; print("\n".join(json.load(open(sys.argv[1]))))' "$tmp/whole-$kind.json")"
  [[ "$got" == "$probe_names" ]] || {
    echo "probe on the $kind run dir should print exactly the PROBE_FIELDS names, got: $got" >&2; exit 1; }
  want="$(python3 "$run_state" phase --probe "$probes_dir/$fixture")"
  got="$(python3 "$run_state" phase --probe "$tmp/whole-$kind.json")"
  [[ -n "$want" && "$got" == "$want" ]] || {
    echo "phase on the $kind probe should print $fixture's line: $want, got: $got ($(cat "$tmp/whole-$kind.json"))" >&2; exit 1; }
}
for kind in fresh midbuild redteam propen merged; do make_run "$kind"; done
whole_case fresh row-04.json
whole_case midbuild row-07.json
whole_case redteam row-13.json
whole_case propen row-15.json --pr-bundle "$bundles_dir/open-findings.json"
whole_case merged row-01.json --pr-bundle "$bundles_dir/merged.json"
# A fresh issue's RUN_DIR does not exist yet, and a probe that made it would
# turn the next resume into row 5's dead run.
[[ ! -e "$tmp/whole-fresh/run" ]] || { echo "probe created the run dir it was only asked to read" >&2; exit 1; }

# One field at a time. The lab repo sits on issue-1, unpushed, and each case
# gets a run dir of its own.
lab_repo="$tmp/lab/repo"
mkdir -p "$tmp/lab"
make_repo "$lab_repo"
probe_git "$lab_repo" checkout -q -b issue-1
new_run() { rm -rf "$tmp/lab/$1"; mkdir -p "$tmp/lab/$1"; printf '%s' "$tmp/lab/$1"; }

# herdr's answer comes in by flag. Under HERDR a defaulted `absent` would skip
# row 2's wait and dispatch a second agent into a tree one is still working in.
r="$(new_run herdr)"
expect_field "with no --herdr-state" herdr_agent_state '"absent"' "$r" "$lab_repo"
expect_field "with --herdr-state working" herdr_agent_state '"working"' "$r" "$lab_repo" --herdr-state working
run_probe "$r" "$lab_repo" --herdr-state working >"$tmp/herdr-working.json"
grep -Fq "phase: wait reason: row 2:" <<<"$(python3 "$run_state" phase --probe "$tmp/herdr-working.json")" || {
  echo "a probe taken with --herdr-state working should answer wait" >&2; exit 1; }
set +e
herdr_out="$(PATH="$probe_bin:$PATH" HERDR_ENV=1 python3 "$run_state" probe --run-dir "$r" --root "$lab_repo" --issue 1 2>"$tmp/probe-stderr")"
herdr_status=$?
set -e
[[ "$herdr_status" == 3 && -z "$herdr_out" ]] || {
  echo "probe under HERDR_ENV=1 with no --herdr-state should exit 3, got $herdr_status: $herdr_out" >&2; exit 1; }

expect_field "on a repo with issue-1" branch_local true "$r" "$lab_repo"
expect_field "on a repo with no issue-1" branch_local false "$r" "$tmp/whole-fresh/repo"
expect_field "on an existing run dir" run_dir true "$r" "$lab_repo"
expect_field "on a missing run dir" run_dir false "$tmp/lab/nope" "$lab_repo"
[[ ! -e "$tmp/lab/nope" ]] || { echo "probe created a missing run dir" >&2; exit 1; }
expect_field "with no base_sha" base_sha false "$r" "$lab_repo"
expect_field "with no baseline.txt" baseline false "$r" "$lab_repo"
probe_git "$lab_repo" rev-parse HEAD >"$r/base_sha"
echo ok >"$r/baseline.txt"
expect_field "with base_sha" base_sha true "$r" "$lab_repo"
expect_field "with baseline.txt" baseline true "$r" "$lab_repo"

# branch_remote asks the live remote: false where origin lacks the branch, true
# once pushed, and null where there is no origin to ask.
remote_repo="$tmp/lab/remote-repo"
make_repo "$remote_repo"
probe_git "$remote_repo" checkout -q -b issue-1
expect_field "before the push" branch_remote false "$r" "$remote_repo"
probe_git "$remote_repo" push -q origin issue-1 2>/dev/null
expect_field "after the push" branch_remote true "$r" "$remote_repo"
bare_repo="$tmp/lab/no-origin"
git init -q -b main "$bare_repo"
expect_field "with no origin remote" branch_remote null "$r" "$bare_repo"

# ahead_of_origin: a local commit past origin/issue-1; with no remote branch, a
# commit past base_sha.
ahead_repo="$tmp/lab/ahead-repo"
make_repo "$ahead_repo"
probe_git "$ahead_repo" checkout -q -b issue-1
a="$(new_run ahead)"
probe_git "$ahead_repo" rev-parse HEAD >"$a/base_sha"
expect_field "with no remote branch and nothing past base_sha" ahead_of_origin false "$a" "$ahead_repo"
probe_git "$ahead_repo" commit -q --allow-empty -m work
expect_field "with no remote branch and a commit past base_sha" ahead_of_origin true "$a" "$ahead_repo"
probe_git "$ahead_repo" push -q origin issue-1 2>/dev/null
expect_field "level with origin/issue-1" ahead_of_origin false "$a" "$ahead_repo"
probe_git "$ahead_repo" commit -q --allow-empty -m repair
expect_field "with a local commit past origin/issue-1" ahead_of_origin true "$a" "$ahead_repo"

# base_sha_state (#137), the same moves as the block above, through probe.
bs_root="$tmp/bs"
bs_origin="$bs_root/origin.git"
bs_clone="$bs_root/clone"
bs_upstream="$bs_root/upstream"
bs_run="$bs_root/run"
mkdir -p "$bs_run"
git init -q -b main --bare "$bs_origin"
for bs_repo in "$bs_clone" "$bs_upstream"; do
  git clone -q "$bs_origin" "$bs_repo" 2>/dev/null
  git -C "$bs_repo" config user.email smoke@example.invalid
  git -C "$bs_repo" config user.name smoke
  git -C "$bs_repo" config commit.gpgsign false
  git -C "$bs_repo" config core.hooksPath /dev/null
done
printf 'a\n' >"$bs_clone/a.txt"
git -C "$bs_clone" add a.txt
git -C "$bs_clone" commit -q -m base
git -C "$bs_clone" push -q origin main 2>/dev/null
git -C "$bs_clone" checkout -q -b issue-1
printf 'x\n' >"$bs_clone/x.txt"
git -C "$bs_clone" add x.txt
git -C "$bs_clone" commit -q -m branch
git -C "$bs_clone" merge-base origin/main issue-1 >"$bs_run/base_sha"
expect_field "on a fresh branch" base_sha_state '"current"' "$bs_run" "$bs_clone"
git -C "$bs_upstream" pull -q origin main 2>/dev/null
printf 'total = round(price * qty)\n' >"$bs_upstream/billing.py"
git -C "$bs_upstream" add billing.py
git -C "$bs_upstream" commit -q -m upstream
git -C "$bs_upstream" push -q origin main 2>/dev/null
git -C "$bs_clone" fetch -q origin
expect_field "after upstream moved and the branch did not" base_sha_state '"current"' "$bs_run" "$bs_clone"
bs_kept="$(cat "$bs_run/base_sha")"
git -C "$bs_clone" rebase -q origin/main
expect_field "after a rebase with base_sha untouched" base_sha_state '"not-merge-base"' "$bs_run" "$bs_clone"
# A mismatch stops for a human. A probe that healed the file itself would
# adopt whatever base a manual rebase left, one taken before the red-team
# included.
[[ "$(cat "$bs_run/base_sha")" == "$bs_kept" ]] || {
  echo "probe rewrote a stale base_sha: $bs_kept became $(cat "$bs_run/base_sha")" >&2; exit 1; }
# Step 5 item 2's rewrite, run as SKILL.md writes it, is what heals the drift
# just probed (#137). The diff every later review takes from base_sha has to
# shrink from the upstream billing.py plus the branch's x.txt to x.txt alone,
# or code-review and adversarial-review read another PR's money line as ours.
base_rewrite="$(grep -o 'm="$(git merge-base origin/DEFAULT issue-N)" && printf .%s\\n. "$m" > RUN_DIR/base_sha' work-issue/SKILL.md | head -1 || true)"
[[ -n "$base_rewrite" ]] || {
  echo "could not extract the Step 5 base_sha rewrite from work-issue/SKILL.md" >&2
  exit 1
}
base_rewrite="${base_rewrite//DEFAULT/main}"
base_rewrite="${base_rewrite//issue-N/issue-1}"
base_rewrite="${base_rewrite//RUN_DIR/$bs_run}"
bs_diff() { git -C "$bs_clone" diff --name-only "$(cat "$bs_run/base_sha")"..HEAD | tr '\n' ' '; }
bs_before="$(bs_diff)"
[[ "$bs_before" == "billing.py x.txt " ]] || {
  echo "before the Step 5 rewrite, a diff from the pre-rebase base_sha should list billing.py and x.txt, got: $bs_before" >&2
  exit 1
}
(cd "$bs_clone" && bash -c "$base_rewrite" </dev/null)
bs_after="$(bs_diff)"
[[ "$bs_after" == "x.txt " ]] || {
  echo "after the Step 5 rewrite ($base_rewrite), a diff from base_sha should list only x.txt, got: $bs_after" >&2
  exit 1
}
expect_field "after Step 5 item 2 rewrites base_sha" base_sha_state '"current"' "$bs_run" "$bs_clone"
# A merge-base that fails must leave the recorded base alone. A bare redirect
# truncated the file before the command ran, and the probe then read an empty
# file as absent, so no row stopped the run (#137 self-review).
bs_kept="$(cat "$bs_run/base_sha")"
(cd "$bs_clone" && bash -c "${base_rewrite//origin\/main/origin/no-such-branch}" </dev/null 2>/dev/null) || true
[[ "$(cat "$bs_run/base_sha")" == "$bs_kept" ]] || {
  echo "a failed Step 5 merge-base should leave base_sha untouched, got: '$(cat "$bs_run/base_sha")'" >&2
  exit 1
}
: >"$bs_run/base_sha"
expect_field "with an empty base_sha file" base_sha_state null "$bs_run" "$bs_clone"
git -C "$bs_clone" commit-tree -p origin/main~1 -m side 'origin/main~1^{tree}' >"$bs_run/base_sha"
expect_field "holding a side-branch commit the branch never had" base_sha_state '"not-ancestor"' "$bs_run" "$bs_clone"
printf 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef\n' >"$bs_run/base_sha"
expect_field "holding a SHA that does not resolve" base_sha_state null "$bs_run" "$bs_clone"
rm "$bs_run/base_sha"
expect_field "with no base_sha file" base_sha_state '"absent"' "$bs_run" "$bs_clone"
git -C "$bs_clone" merge-base origin/main issue-1 >"$bs_run/base_sha"
git -C "$bs_clone" checkout -q --detach
git -C "$bs_clone" push -q origin issue-1 2>/dev/null
git -C "$bs_clone" branch -q -D issue-1
expect_field "with the issue branch only on origin" base_sha_state null "$bs_run" "$bs_clone"
git -C "$bs_clone" update-ref -d refs/remotes/origin/issue-1
expect_field "with the issue branch only on origin, never fetched" base_sha_state null "$bs_run" "$bs_clone"
git -C "$bs_clone" update-ref refs/remotes/origin/issue-1 "$(git -C "$bs_clone" rev-parse origin/main)"
git -C "$bs_origin" branch -q -D issue-1
expect_field "with a stale tracking ref and no branch on origin" base_sha_state '"absent"' "$bs_run" "$bs_clone"
git -C "$bs_clone" update-ref -d refs/remotes/origin/issue-1
expect_field "with no issue branch anywhere" base_sha_state '"absent"' "$bs_run" "$bs_clone"

# pr_state and review_state come off the bundle. SINCE is pushed_at, else the
# branch head's committer date, as SKILL.md defines it.
p="$(new_run pr)"
expect_field "with no bundle" pr_state null "$p" "$lab_repo"
expect_field "with no bundle" review_state null "$p" "$lab_repo"
expect_field "on a merged bundle" pr_state '"MERGED"' "$p" "$lab_repo" --pr-bundle "$bundles_dir/merged.json"
echo 2026-09-20T11:00:00Z >"$p/pushed_at"
expect_field "on an open bundle" pr_state '"OPEN"' "$p" "$lab_repo" --pr-bundle "$bundles_dir/open-findings.json"
expect_field "with a thread after pushed_at" review_state '"findings"' "$p" "$lab_repo" --pr-bundle "$bundles_dir/open-findings.json"
echo 2026-09-20T13:00:00Z >"$p/pushed_at"
expect_field "with the thread before pushed_at" review_state '"pending"' "$p" "$lab_repo" --pr-bundle "$bundles_dir/open-findings.json"
rm "$p/pushed_at"
since_repo="$tmp/lab/since-repo"
make_repo "$since_repo"
probe_git "$since_repo" checkout -q -b issue-1
GIT_COMMITTER_DATE=2026-09-20T11:30:00Z probe_git "$since_repo" commit -q --allow-empty -m work
expect_field "with no pushed_at and a head committed before the thread" review_state '"findings"' "$p" "$since_repo" --pr-bundle "$bundles_dir/open-findings.json"
GIT_COMMITTER_DATE=2026-09-20T12:30:00Z probe_git "$since_repo" commit -q --allow-empty -m more
expect_field "with no pushed_at and a head committed after the thread" review_state '"pending"' "$p" "$since_repo" --pr-bundle "$bundles_dir/open-findings.json"
# An existing pushed_at is SINCE, damaged or not. Falling back to the branch's
# committer date read a garbage marker as a 12:30 cutoff and hid the 12:00
# finding as pending (PR #177 review), so only an absent file falls back.
for since_bad in garbage empty blank; do
  case "$since_bad" in
    garbage) echo garbage >"$p/pushed_at" ;;
    empty) : >"$p/pushed_at" ;;
    blank) printf '  \n' >"$p/pushed_at" ;;
  esac
  expect_probe_usage "with a $since_bad pushed_at and a branch to fall back on" --run-dir "$p" --root "$since_repo" --issue 1 --pr-bundle "$bundles_dir/open-findings.json"
  grep -Fq "pushed_at" "$tmp/probe-stderr" || {
    echo "a $since_bad pushed_at should be named on stderr, got: $(cat "$tmp/probe-stderr")" >&2; exit 1; }
done
rm "$p/pushed_at"
require_text work-issue/references/resume.md "A \`pushed_at\` that exists is the cutoff even when damaged"
require_text _maintenance/work-issue/RATIONALE.md "An existing \`RUN_DIR/pushed_at\` is SINCE for \`review_state\`"
# A merged or closed pull request ends the run at row 1 whatever else is gone,
# SINCE included: after cleanup there may be no pushed_at and no branch. The
# probe skips scoring the review there, and phase answers row 1 (PR #177 review).
python3 - "$bundles_dir/merged.json" "$tmp/bundle-closed.json" <<'PY2'
import json, sys
bundle = json.load(open(sys.argv[1]))
bundle["state"] = "CLOSED"
json.dump(bundle, open(sys.argv[2], "w"))
PY2
require_text work-issue/references/resume.md "A \`MERGED\` or \`CLOSED\` bundle is \`null\` too and is never scored"
require_text _maintenance/work-issue/RATIONALE.md "A \`MERGED\` or \`CLOSED\` bundle gives its state as \`pr_state\` and a null \`review_state\`"
terminal_want="$(python3 "$run_state" phase --probe "$probes_dir/row-01.json")"
for terminal_bundle in "$bundles_dir/merged.json" "$tmp/bundle-closed.json"; do
  terminal_state="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["state"])' "$terminal_bundle")"
  expect_field "on a $terminal_state bundle with no pushed_at and no issue-1 branch" review_state null "$p" "$tmp/whole-fresh/repo" --pr-bundle "$terminal_bundle"
  run_probe "$p" "$tmp/whole-fresh/repo" --pr-bundle "$terminal_bundle" >"$tmp/terminal.json" || {
    echo "probe on a $terminal_state bundle with no SINCE should exit 0, got: $(cat "$tmp/probe-stderr")" >&2; exit 1; }
  terminal_got="$(python3 "$run_state" phase --probe "$tmp/terminal.json")"
  [[ "$terminal_got" == "${terminal_want/MERGED/$terminal_state}" ]] || {
    echo "phase on a $terminal_state bundle with no SINCE should print row 1's line, ${terminal_want/MERGED/$terminal_state}, got: $terminal_got" >&2; exit 1; }
done

# has_waves and wave_tasks read the table the way the vendored parser does:
# stripped lines, compact rows, and a table that ends at its first non-table line.
w="$(new_run waves)"
expect_field "with no plan.md" has_waves false "$w" "$lab_repo"
printf '# Plan\n\n## Tasks\n' >"$w/plan.md"
expect_field "with no Waves heading" has_waves false "$w" "$lab_repo"
printf '# Plan\n\n  ## Waves  \n\n  | Wave | Task | Files owned |\n  |---|---|---|\n  | 0 | one | a.py |\n' >"$w/plan.md"
expect_field "on an indented heading" has_waves true "$w" "$lab_repo"
expect_field "on an indented table" wave_tasks 1 "$w" "$lab_repo"
cp tests/fixtures/work-issue/reports-task-named/plan.md "$w/plan.md"
expect_field "with a compact row and a numbered row under a later heading" wave_tasks 5 "$w" "$lab_repo"
printf '# Plan\n\n## Waves\n\n| Wave | Task | Files owned |\n|---|---|---|\n|0|one|a.py|sonnet|done||\n\n### Notes\n\n| 1 | two | b.py |\n' >"$w/plan.md"
expect_field "with a numbered row under a ### heading after the table" wave_tasks 1 "$w" "$lab_repo"

# wave_reports and wave_unreported_committed (#136), the cases the extraction
# blocks above run, through probe. A report counts only beside clean owned
# paths and gate evidence, under either name, once.
rp_run="$tmp/probe-reports-run"
rp_tree="$tmp/probe-reports-tree"
git init -q "$rp_tree"
cp -R tests/fixtures/work-issue/reports-task-named "$rp_run"
mkdir -p "$rp_run/gated"
for g in 0-record-revision 0-fixtures 1-contract-rule 2-implementations 3-commit-revision; do
  : >"$rp_run/gated/$g"
done
expect_field "on five <task>.json reports and a decoy" wave_reports 5 "$rp_run" "$rp_tree"
mv "$rp_run/reports/fixtures.json" "$rp_run/reports/0-fixtures.json"
expect_field "with one report under <wave>-<task>.json" wave_reports 5 "$rp_run" "$rp_tree"
cp "$rp_run/reports/record-revision.json" "$rp_run/reports/0-record-revision.json"
expect_field "with one task reported under both names" wave_reports 5 "$rp_run" "$rp_tree"
rm "$rp_run/reports/0-fixtures.json"
expect_field "with one task unreported" wave_reports 4 "$rp_run" "$rp_tree"
rp_broken="$tmp/probe-reports-broken"
git init -q "$rp_broken"
printf 'garbage' >"$rp_broken/.git/index"
expect_field "on a tree whose git status fails" wave_reports null "$rp_run" "$rp_broken"
rm "$rp_run/gated/0-record-revision"
expect_field "with record-revision unmarked and no base_sha" wave_reports 3 "$rp_run" "$rp_tree"
: >"$rp_run/base_sha"
expect_field "with record-revision unmarked and an empty base_sha" wave_reports 3 "$rp_run" "$rp_tree"
rm -r "$rp_run/gated"
echo deadbeef >"$rp_run/base_sha"
expect_field "with no gated/ and a base_sha git log cannot resolve" wave_reports null "$rp_run" "$rp_tree"

cm_tree="$tmp/probe-committed-tree"
cm_run="$tmp/probe-committed-run"
git init -q "$cm_tree"
mkdir -p "$cm_run/reports"
cp tests/fixtures/work-issue/reports-task-named/plan.md "$cm_run/plan.md"
probe_git "$cm_tree" commit -q --allow-empty -m base
probe_git "$cm_tree" rev-parse HEAD >"$cm_run/base_sha"
mkdir -p "$cm_tree/fx"
echo a >"$cm_tree/a.py"
echo '{}' >"$cm_tree/fx/one.json"
probe_git "$cm_tree" add a.py fx/one.json
probe_git "$cm_tree" commit -q -m "wave 0"
echo d >"$cm_tree/d.py"
expect_field "with two committed tasks and no reports" wave_unreported_committed 2 "$cm_run" "$cm_tree"
echo '{}' >"$cm_run/reports/record-revision.json"
expect_field "with one committed task reported" wave_unreported_committed 1 "$cm_run" "$cm_tree"
cm_base="$(cat "$cm_run/base_sha")"
echo deadbeef >"$cm_run/base_sha"
expect_field "with a base_sha that does not resolve" wave_unreported_committed null "$cm_run" "$cm_tree"
rm "$cm_run/base_sha"
expect_field "with no base_sha" wave_unreported_committed 0 "$cm_run" "$cm_tree"
# Step 1 writes base_sha before any wave can commit, so its absence means no
# committed wave: 0, which leaves row 7's Step 1 leg reachable. A null here
# tripped the null-field stop ahead of every row and hid that leg.
expect_phase "a run with no base_sha" "phase: 1 reason: row 7:" \
  "$(field_phase row-07-isolation-incomplete.json wave_unreported_committed "$probe_got")"
echo "$cm_base" >"$cm_run/base_sha"
echo b >"$cm_tree/b.py"
echo c >"$cm_tree/c.py"
probe_git "$cm_tree" add b.py c.py
probe_git "$cm_tree" commit -q -m "wave 1"
echo e >"$cm_tree/e.py"
probe_git "$cm_tree" add e.py
probe_git "$cm_tree" commit -q -m "wave 3"
cp tests/fixtures/work-issue/reports-task-named/reports/*.json "$cm_run/reports/"
expect_field "with every report in and d.py dirty" wave_reports 4 "$cm_run" "$cm_tree"
expect_field "with a reported, dirty task and no commit" wave_unreported_committed 0 "$cm_run" "$cm_tree"
# The #78 shape mid-flight: every task has its <task>.json, but d.py is still
# untracked, because implementations' worker wrote its report and the session
# died before the Step 3 gate. That task is unbuilt, so row 7 reverts and
# re-dispatches it rather than row 8 skipping its gate (PR #176 review).
expect_phase "a reported task with dirty owned paths" "phase: 2 reason: row 7:" "$(wave_phase row-07.json "$cm_run" "$cm_tree")"
echo more >>"$cm_tree/a.py"
expect_field "with a reported task dirty on a committed path" wave_unreported_committed 1 "$cm_run" "$cm_tree"
# Dirt on a path a commit past base_sha already touched is not a half-written
# wave: stop rather than revert.
expect_phase "a reported task dirty on a committed path" "phase: stop reason: row 7:" "$(wave_phase row-07.json "$cm_run" "$cm_tree")"
probe_git "$cm_tree" checkout -q -- a.py
rm "$cm_tree/d.py"
expect_field "with implementations reported, clean, and ungated" wave_reports 4 "$cm_run" "$cm_tree"
expect_field "with a reported, clean, ungated task" wave_unreported_committed 0 "$cm_run" "$cm_tree"
# The worker's early report beside paths it never changed: clean, but neither
# a commit nor a gate marker says the gate ran, so row 7 re-dispatches it.
expect_phase "a reported, clean task with no gate evidence" "phase: 2 reason: row 7:" "$(wave_phase row-07.json "$cm_run" "$cm_tree")"
rm "$cm_run/reports/implementations.json"
echo d >"$cm_tree/d.py"
expect_phase "an uncommitted, unreported task" "phase: 2 reason: row 7:" "$(wave_phase row-07.json "$cm_run" "$cm_tree")"
cp tests/fixtures/work-issue/reports-task-named/reports/implementations.json "$cm_run/reports/"
probe_git "$cm_tree" add d.py
probe_git "$cm_tree" commit -q -m "wave 2"
expect_field "on the #78 shape: five committed tasks, <task>.json only, no markers" wave_reports 5 "$cm_run" "$cm_tree"
# #78 exactly: the commits are the gate evidence, so it reaches row 8.
expect_phase "every <task>.json report on a committed, clean run" "phase: 3 reason: row 8:" "$(wave_phase row-07.json "$cm_run" "$cm_tree")"
rm "$cm_run"/reports/*.json
expect_field "with five committed waves and no report" wave_unreported_committed 5 "$cm_run" "$cm_tree"
wave_out="$(wave_phase row-07.json "$cm_run" "$cm_tree")"
expect_phase "committed waves with no report" "phase: stop reason: row 7:" "$wave_out"
expect_phase "row 7's stop on committed waves with no report" "git log" "$wave_out"

# A failed task.json beside clean owned paths and an unowned b.py: no gate
# evidence, so it does not count until its marker exists (PR #176 review).
gt_tree="$tmp/probe-gate-tree"
gt_run="$tmp/probe-gate-run"
git init -q "$gt_tree"
mkdir -p "$gt_run/reports"
printf '# Plan\n\n## Waves\n\n| Wave | Task | Files owned | Model | Done when | Constraints |\n|---|---|---|---|---|---|\n| 0 | task | a.py | sonnet | x | |\n' >"$gt_run/plan.md"
probe_git "$gt_tree" commit -q --allow-empty -m base
probe_git "$gt_tree" rev-parse HEAD >"$gt_run/base_sha"
echo '{"status":"failed"}' >"$gt_run/reports/task.json"
echo b >"$gt_tree/b.py"
expect_field "on an ungated failed report" wave_reports 0 "$gt_run" "$gt_tree"
expect_phase "the ungated failed report" "phase: 2 reason: row 7:" "$(wave_phase row-07.json "$gt_run" "$gt_tree")"
mkdir -p "$gt_run/gated"
: >"$gt_run/gated/0-task"
expect_field "once the gate marker exists" wave_reports 1 "$gt_run" "$gt_tree"
expect_phase "a gated, reported task" "phase: 3 reason: row 8:" "$(wave_phase row-07.json "$gt_run" "$gt_tree")"
rm "$gt_tree/b.py" "$gt_run/reports/task.json"
echo '{"status":"done"}' >"$gt_run/reports/0-task.json"
expect_field "on a no-change task with a report and a marker" wave_reports 1 "$gt_run" "$gt_tree"
expect_field "on a counted no-change task" wave_unreported_committed 0 "$gt_run" "$gt_tree"
rm "$gt_run/reports/0-task.json"
expect_field "on a marker with no report" wave_reports 0 "$gt_run" "$gt_tree"
# Two tasks sharing a path in different waves: create's commit must not stand
# in for extend's gate (PR #176 code-review).
sh_tree="$tmp/probe-shared-tree"
sh_run="$tmp/probe-shared-run"
git init -q "$sh_tree"
mkdir -p "$sh_run/reports" "$sh_run/gated"
printf '# Plan\n\n## Waves\n\n| Wave | Task | Files owned | Model | Done when | Constraints |\n|---|---|---|---|---|---|\n| 0 | create | a.py | sonnet | x | |\n| 1 | extend | a.py | sonnet | x | |\n' >"$sh_run/plan.md"
probe_git "$sh_tree" commit -q --allow-empty -m base
probe_git "$sh_tree" rev-parse HEAD >"$sh_run/base_sha"
echo a >"$sh_tree/a.py"
probe_git "$sh_tree" add a.py
probe_git "$sh_tree" commit -q -m "wave 0"
: >"$sh_run/gated/0-create"
echo '{"status":"done"}' >"$sh_run/reports/0-create.json"
echo '{"status":"failed"}' >"$sh_run/reports/extend.json"
expect_field "with an ungated extend sharing create's committed a.py" wave_reports 1 "$sh_run" "$sh_tree"
expect_field "with an ungated, reported, clean extend" wave_unreported_committed 0 "$sh_run" "$sh_tree"
expect_phase "an ungated task on a path an earlier wave committed" "phase: 2 reason: row 7:" "$(wave_phase row-07.json "$sh_run" "$sh_tree")"
: >"$sh_run/gated/1-extend"
expect_field "with extend's own marker" wave_reports 2 "$sh_run" "$sh_tree"
expect_phase "extend with its own gate marker" "phase: 3 reason: row 8:" "$(wave_phase row-07.json "$sh_run" "$sh_tree")"
# Cells keep their inner spaces (PR #176 review).
sp_tree="$tmp/probe-space-tree"
sp_run="$tmp/probe-space-run"
git init -q "$sp_tree"
mkdir -p "$sp_run/reports" "$sp_tree/docs"
printf '# Plan\n\n## Waves\n\n| Wave | Task | Files owned | Model | Done when | Constraints |\n|---|---|---|---|---|---|\n| 0 | my task | docs/my notes.md | sonnet | x | |\n' >"$sp_run/plan.md"
probe_git "$sp_tree" commit -q --allow-empty -m base
probe_git "$sp_tree" rev-parse HEAD >"$sp_run/base_sha"
echo notes >"$sp_tree/docs/my notes.md"
probe_git "$sp_tree" add "docs/my notes.md"
probe_git "$sp_tree" commit -q -m "wave 0"
expect_field "on an unreported task owning committed docs/my notes.md" wave_unreported_committed 1 "$sp_run" "$sp_tree"
echo '{}' >"$sp_run/reports/0-my task.json"
expect_field "on reports/0-my task.json with clean paths" wave_reports 1 "$sp_run" "$sp_tree"
expect_field "on a reported, clean task with an inner space" wave_unreported_committed 0 "$sp_run" "$sp_tree"

# Counts under review/, reports/, redteam/, and triage/.
c="$(new_run counts)"
mkdir -p "$c/review" "$c/reports" "$c/redteam" "$c/triage"
expect_field "with an empty review/" self_reviews 0 "$c" "$lab_repo"
expect_field "with no build-final.json" build_final false "$c" "$lab_repo"
echo x >"$c/review/self-1.md"
echo x >"$c/review/self-2.md"
echo x >"$c/review/notes.md"
echo '{}' >"$c/reports/build-final.json"
echo '{}' >"$c/reports/repair-1.json"
echo '{}' >"$c/reports/redteam-repair-1.json"
expect_field "with two self-reviews and a note" self_reviews 2 "$c" "$lab_repo"
expect_field "with build-final.json" build_final true "$c" "$lab_repo"
# Step 4's red-team repairs are redteam-repair-<k>.json and never count as a
# triage round's repair.
expect_field "beside a redteam-repair-1.json" repair_reports 1 "$c" "$lab_repo"
cp tests/fixtures/work-issue/triage/round-1.md "$c/triage/round-1.md"
cp tests/fixtures/work-issue/triage/round-2.md "$c/triage/round-2.md"
expect_field "with two rounds" triage_rounds 2 "$c" "$lab_repo"

# The red-team round fields read order, not counts. mtimes are set by hand so
# the newest round is the one the case says it is.
rt="$(new_run redteam)"
mkdir -p "$rt/redteam" "$rt/reports"
echo '{"left_checks": [{"holds": false}]}' >"$rt/redteam/round-1.json"
echo '{"claims": [{"verdict": "REPRODUCED"}]}' >"$rt/redteam/round-2.json"
touch -t 202609200100 "$rt/redteam/round-1.json"
touch -t 202609200200 "$rt/redteam/round-2.json"
expect_field "with two rounds" redteam_rounds 2 "$rt" "$lab_repo"
expect_field "with a failed round older than a clean one" redteam_last_failed false "$rt" "$lab_repo"
expect_field "with one failed round of two" redteam_failed_twice false "$rt" "$lab_repo"
touch -t 202609200300 "$rt/redteam/round-1.json"
# A false left check is a red-team failure, and the probe has to read it.
expect_field "with a newest round holding only \"holds\": false" redteam_last_failed true "$rt" "$lab_repo"
echo '{"claims": [{"verdict": "NOT_REPRODUCED"}]}' >"$rt/redteam/round-2.json"
touch -t 202609200200 "$rt/redteam/round-2.json"
expect_field "with two failed rounds" redteam_failed_twice true "$rt" "$lab_repo"
echo '{}' >"$rt/reports/redteam-repair-1.json"
touch -t 202609200400 "$rt/reports/redteam-repair-1.json"
expect_field "with a repair newer than the failed round" repair_after_last_round true "$rt" "$lab_repo"
touch -t 202609200000 "$rt/reports/redteam-repair-1.json"
expect_field "with a repair older than the failed round" repair_after_last_round false "$rt" "$lab_repo"

# trigger_fired is three-valued, and the trigger reads line 1 exactly.
tg="$(new_run trigger)"
mkdir -p "$tg/redteam"
expect_field "with no trigger.txt" trigger_fired '"absent"' "$tg" "$lab_repo"
for tg_case in "fired: yes:yes" "fired: no:no" "not fired: yes:absent"; do
  printf '%s\nrows: 1\n' "${tg_case%:*}" >"$tg/redteam/trigger.txt"
  expect_field "on first line '${tg_case%:*}'" trigger_fired "\"${tg_case##*:}\"" "$tg" "$lab_repo"
done
# ar_complete reads Step 4's record, never the run directory preflight leaves.
mkdir -p "$lab_repo/.adversarial-review/runs/x"
expect_field "with an adversarial-review run dir and no ar-state.txt" ar_complete false "$tg" "$lab_repo"
echo "UNVERIFIED: 0" >"$tg/redteam/ar-state.txt"
expect_field "with UNVERIFIED: 0 in ar-state.txt" ar_complete true "$tg" "$lab_repo"
rm -r "$lab_repo/.adversarial-review"
expect_field "with no conflict.txt" conflict false "$tg" "$lab_repo"
echo "a.py" >"$tg/conflict.txt"
expect_field "with conflict.txt" conflict true "$tg" "$lab_repo"

# rebase_in_progress resolves through --git-path in the linked worktree that
# holds issue-1, which probe finds from --root rather than taking a second flag.
rb_repo="$tmp/lab/rebase-repo"
rb_tree="$tmp/lab/rebase-tree"
make_repo "$rb_repo"
probe_git "$rb_repo" worktree add -q -b issue-1 "$rb_tree"
expect_field "with no rebase" rebase_in_progress false "$tg" "$rb_repo"
mkdir -p "$(git -C "$rb_tree" rev-parse --path-format=absolute --git-path rebase-merge)"
expect_field "with rebase-merge in the linked worktree" rebase_in_progress true "$tg" "$rb_repo"

# The triage fields read a round's table by header name, and each newest round
# is the one its resume.md row names.
tr="$(new_run triage)"
mkdir -p "$tr/triage" "$tr/reports" "$tr/redteam"
expect_field "with no round" triage_rounds 0 "$tr" "$lab_repo"
expect_field "with no round" triage_inscope_rows 0 "$tr" "$lab_repo"
expect_field "with no round" triage_rows_unanswered 0 "$tr" "$lab_repo"
expect_field "with no round" newest_repair_report false "$tr" "$lab_repo"
expect_field "with no round" repair_ar_settled false "$tr" "$lab_repo"
cp tests/fixtures/work-issue/triage/round-1.md "$tr/triage/round-1.md"
expect_field "on round-1.md" triage_inscope_rows 2 "$tr" "$lab_repo"
expect_field "on round-1.md's three unanswered rows" triage_rows_unanswered 3 "$tr" "$lab_repo"
sed 's#| in scope | |$#| in scope | https://github.com/o/r/pull/9\#discussion_r20 |#' tests/fixtures/work-issue/triage/round-1.md >"$tr/triage/round-1.md"
expect_field "with two rows carrying a reply URL" triage_rows_unanswered 1 "$tr" "$lab_repo"
cp tests/fixtures/work-issue/triage/round-2.md "$tr/triage/round-2.md"
expect_field "across two rounds" triage_rows_unanswered 4 "$tr" "$lab_repo"
echo '{}' >"$tr/reports/repair-1.json"
expect_field "with repair-1.json and a newer round 2" newest_repair_report false "$tr" "$lab_repo"
echo '{}' >"$tr/reports/repair-2.json"
expect_field "with repair-2.json" newest_repair_report true "$tr" "$lab_repo"
expect_field "with neither repair file" repair_ar_settled false "$tr" "$lab_repo"
echo "fired: no" >"$tr/redteam/trigger-repair-2.txt"
expect_field "with fired: no in trigger-repair-2.txt" repair_ar_settled true "$tr" "$lab_repo"
rm "$tr/redteam/trigger-repair-2.txt"
echo "UNVERIFIED: 0" >"$tr/redteam/ar-state-repair-2.txt"
expect_field "with UNVERIFIED: 0 in ar-state-repair-2.txt" repair_ar_settled true "$tr" "$lab_repo"
printf '# Triage round 3\n\n| # | Source | Finding | Severity | Scope | Reply |\n|---|---|---|---|---|---|\n| 1 | https://github.com/o/r/pull/9#discussion_r30 | "Name it." | P2 | in scope; queued: review round cap reached (2) | |\n| 2 | https://github.com/o/r/pull/9#discussion_r31 | "Later." | P2 | out of scope: not in the diff | |\n' >"$tr/triage/round-3.md"
expect_field "on a capped round's queued in-scope cell" triage_inscope_rows 1 "$tr" "$lab_repo"
cp tests/fixtures/work-issue/triage/round-noscope.md "$tr/triage/round-3.md"
expect_field "on a round with no Scope column" triage_inscope_rows null "$tr" "$lab_repo"
sed 's/| Reply |$/|/; s/|---|---|---|---|---|$/|---|---|---|---|/; s/| in scope | |$/| in scope |/' tests/fixtures/work-issue/triage-noseverity/round-1.md >"$tr/triage/round-3.md"
expect_field "with a round that has no Reply column" triage_rows_unanswered null "$tr" "$lab_repo"

# triage_newer_than_since (#139): the newest round by number, compared by the
# SINCE its heading recorded, never by the file's time.
ts="$(new_run since)"
mkdir -p "$ts/triage"
since_fixture=tests/fixtures/work-issue/triage-since/round-1.md
expect_field "with no round" triage_newer_than_since false "$ts" "$lab_repo"
cp "$since_fixture" "$ts/triage/round-1.md"
echo 2026-09-23T13:55:25Z >"$ts/pushed_at"
expect_field "on a round written against the current pushed_at" triage_newer_than_since true "$ts" "$lab_repo"
expect_phase "a current, answered round" "phase: done reason: row 18" "$(field_phase row-18-answered.json triage_newer_than_since "$probe_got")"
expect_phase "a current round owing replies" "phase: 8 reason: row 17" "$(field_phase row-17.json triage_newer_than_since "$probe_got")"
echo 2026-09-23T18:03:09Z >"$ts/pushed_at"
sed 's#| in scope | |#| in scope | https://github.com/o/r/pull/134\#discussion_r10 |#' "$since_fixture" >"$ts/triage/round-1.md"
touch "$ts/triage/round-1.md"
expect_field "on the PR #134 replay" triage_newer_than_since false "$ts" "$lab_repo"
expect_phase "a finding after Step 8's replies" "phase: 6 reason: row 15" "$(field_phase row-18-answered.json triage_newer_than_since "$probe_got")"
cp "$since_fixture" "$ts/triage/round-1.md"
expect_field "on an unedited round after a later push" triage_newer_than_since false "$ts" "$lab_repo"
printf '# Triage round 1 — PR #134, since 2026-09-23T18:03:09Z\n' >"$ts/triage/round-1.md"
expect_field "on the #124 heading" triage_newer_than_since true "$ts" "$lab_repo"
printf '# Triage round 2, since 2026-09-23T18:03:09Z\n' >"$ts/triage/round-2.md"
cp "$since_fixture" "$ts/triage/round-1.md"
touch "$ts/triage/round-1.md"
expect_field "with round 2 current and round 1 edited later" triage_newer_than_since true "$ts" "$lab_repo"
rm "$ts"/triage/round-*.md
printf '# Triage round 9, since 2026-09-23T18:03:09Z\n' >"$ts/triage/round-9.md"
cp "$since_fixture" "$ts/triage/round-10.md"
expect_field "with round 10 beside round 9" triage_newer_than_since false "$ts" "$lab_repo"
rm "$ts"/triage/round-*.md
printf '# Triage round 1\n' >"$ts/triage/round-1.md"
expect_field "on a round with no recorded SINCE" triage_newer_than_since null "$ts" "$lab_repo"
expect_phase "a round with no recorded SINCE" "phase: stop reason: unknown probe fields: triage_newer_than_since" \
  "$(field_phase row-18-answered.json triage_newer_than_since "$probe_got")"
printf '# Triage round 1\n\n# Triage round bogus, since 2026-09-23T18:03:09Z\n' >"$ts/triage/round-1.md"
expect_field "on a round whose only since sits below line 1" triage_newer_than_since null "$ts" "$lab_repo"
printf '# Triage round 1, since 2026-09-23T18:03:09Z\n' >"$ts/triage/round-1.md"
rm "$ts/pushed_at"
expect_field "with no pushed_at" triage_newer_than_since null "$ts" "$lab_repo"

# triage_blocking_rows and triage_stop_rows, the cases the extraction blocks
# above run, through probe.
for tri_case in "triage:1:0" "triage-pipe:1:0" "triage-noseverity:null:null" "empty:0:0"; do
  IFS=: read -r tri_name tri_blocking tri_stop <<<"$tri_case"
  tri_dir="$(new_run "blocking-$tri_name")"
  mkdir -p "$tri_dir/triage"
  [[ "$tri_name" == empty ]] || cp "tests/fixtures/work-issue/$tri_name/round-1.md" "$tri_dir/triage/round-1.md"
  expect_field "on $tri_name" triage_blocking_rows "$tri_blocking" "$tri_dir" "$lab_repo"
  expect_field "on $tri_name" triage_stop_rows "$tri_stop" "$tri_dir" "$lab_repo"
done
tri_dir="$(new_run blocking-cap)"
mkdir -p "$tri_dir/triage"
cp tests/fixtures/work-issue/triage/round-2.md "$tri_dir/triage/round-2.md"
expect_field "on the P0/P1/P2 round" triage_stop_rows 1 "$tri_dir" "$lab_repo"
expect_field "on the P0/P1/P2 round" triage_blocking_rows 2 "$tri_dir" "$lab_repo"
for stop_case in "round-3:0" "round-noscope:null"; do
  tri_dir="$(new_run "stop-${stop_case%%:*}")"
  mkdir -p "$tri_dir/triage"
  cp "tests/fixtures/work-issue/triage/${stop_case%%:*}.md" "$tri_dir/triage/round-1.md"
  expect_field "on triage/${stop_case%%:*}.md" triage_stop_rows "${stop_case##*:}" "$tri_dir" "$lab_repo"
done

m="$(new_run rounds)"
expect_field "with no max_review_rounds file" max_review_rounds 2 "$m" "$lab_repo"
echo 3 >"$m/max_review_rounds"
expect_field "with 3 written" max_review_rounds 3 "$m" "$lab_repo"

# open-review.txt ends on an open Step 4 start. With no --now it closes at
# that start and reads 0 min of review; a --now at resume time would charge
# every hour since to review and read over (#146 keeps the resume probe off
# --now).
for budget_case in "build30-review61:true" "build30-review59:false" "bad-label:null" "missing:false" "open-review:false"; do
  b="$(new_run "budget-${budget_case%%:*}")"
  [[ "${budget_case%%:*}" == missing ]] || cp "$timing_dir/${budget_case%%:*}.txt" "$b/timing.log"
  expect_field "on ${budget_case%%:*}" review_over_budget "${budget_case##*:}" "$b" "$lab_repo"
done

# deferred_comment_needed compares every queue row, whole, with the author's
# Deferred findings comment in the bundle.
d="$(new_run deferred)"
deferred_row='| 1 | https://github.com/o/r/pull/9#discussion_r3 | "Consider a retry." | not in the diff | `file-issue` — retry | queued |'
expect_field "with no queue.md" deferred_comment_needed false "$d" "$lab_repo" --pr-bundle "$bundles_dir/open-deferred.json"
printf '| # | Source | Finding | Outside because | Recommendation | Status |\n|---|---|---|---|---|---|\n%s\n' "$deferred_row" >"$d/queue.md"
expect_field "with the queue row carried byte for byte" deferred_comment_needed false "$d" "$lab_repo" --pr-bundle "$bundles_dir/open-deferred.json"
expect_field "with no bundle" deferred_comment_needed false "$d" "$lab_repo"
# The comment counts only from the PR author, whom --author overrides.
expect_field "with --author naming someone else" deferred_comment_needed true "$d" "$lab_repo" --pr-bundle "$bundles_dir/open-deferred.json" --author someone-else
printf '| # | Source | Finding | Outside because | Recommendation | Status |\n|---|---|---|---|---|---|\n%s\n' "${deferred_row/queued |/filed #9 |}" >"$d/queue.md"
expect_field "with a queue row whose Status moved to filed #9" deferred_comment_needed true "$d" "$lab_repo" --pr-bundle "$bundles_dir/open-deferred.json"
printf '| # | Source | Finding | Outside because | Recommendation | Status |\n|---|---|---|---|---|---|\n%s\n| 2 | https://github.com/o/r/pull/9#discussion_r4 | "Log the retry." | not in the diff | `file-issue` — log | queued |\n' "$deferred_row" >"$d/queue.md"
expect_field "with round 2's row missing from the comment" deferred_comment_needed true "$d" "$lab_repo" --pr-bundle "$bundles_dir/open-deferred.json"

# repair_diff_triggers (#162, #137) reads the repair's own diff from
# repair-base-<k> for the newest round k: the billing/README repo the block
# above builds, rebuilt here.
dt_repo="$tmp/probe-scope-repo"
dt_run="$tmp/probe-scope-run"
mkdir -p "$dt_run/redteam" "$dt_run/triage"
cp tests/fixtures/work-issue/triage/round-1.md "$dt_run/triage/round-1.md"
git init -q -b main "$dt_repo"
printf 'amount = round(price * qty, 2)\n' >"$dt_repo/billing.py"
probe_git "$dt_repo" add billing.py
probe_git "$dt_repo" commit -q -m base
probe_git "$dt_repo" checkout -q -b issue-1
printf 'amount = round(price * qty * (1 - discount), 2)\n' >"$dt_repo/billing.py"
probe_git "$dt_repo" commit -q -am branch
probe_git "$dt_repo" rev-parse HEAD >"$dt_run/redteam/repair-base-1"
printf 'Run the tests before you push.\n' >"$dt_repo/README.md"
probe_git "$dt_repo" add README.md
probe_git "$dt_repo" commit -q -m repair
expect_field "with the base at the branch tip" repair_diff_triggers false "$dt_run" "$dt_repo"
probe_git "$dt_repo" merge-base main issue-1 >"$dt_run/redteam/repair-base-1"
expect_field "with the base at the merge-base" repair_diff_triggers true "$dt_run" "$dt_repo"
rm "$dt_run/redteam/repair-base-1"
expect_field "with no repair-base file" repair_diff_triggers false "$dt_run" "$dt_repo"
printf 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef\n' >"$dt_run/redteam/repair-base-1"
expect_field "with a base SHA that does not resolve" repair_diff_triggers null "$dt_run" "$dt_repo"
probe_git "$dt_repo" rev-parse issue-1~1 >"$dt_run/redteam/repair-base-1"
probe_git "$dt_repo" checkout -q main
printf 'total = round(price * qty)\n' >"$dt_repo/invoice.py"
probe_git "$dt_repo" add invoice.py
probe_git "$dt_repo" commit -q -m upstream
probe_git "$dt_repo" checkout -q issue-1
probe_git "$dt_repo" rebase -q main
expect_field "after a rebase orphans the base" repair_diff_triggers false "$dt_run" "$dt_repo"

# TREE is the worktree holding issue-1. A local issue-1 that no worktree has
# checked out has no TREE: ROOT's HEAD is some other branch, and reading it
# counted a committed, reported task as unreported and sent row 7 to redo it
# (PR #177 review). probe stops there instead.
wt_repo="$tmp/lab/wt-repo"
wt_tree="$tmp/lab/wt-tree"
wt_run="$(new_run worktree)"
make_repo "$wt_repo"
probe_git "$wt_repo" checkout -q -b issue-1
mkdir -p "$wt_run/reports"
printf '# Plan\n\n## Waves\n\n| Wave | Task | Files owned | Model | Done when | Constraints |\n|---|---|---|---|---|---|\n| 0 | task | owned.txt | sonnet | x | |\n' >"$wt_run/plan.md"
probe_git "$wt_repo" rev-parse HEAD >"$wt_run/base_sha"
echo "verify: ok" >"$wt_run/baseline.txt"
echo work >"$wt_repo/owned.txt"
probe_git "$wt_repo" add owned.txt
probe_git "$wt_repo" commit -q -m "wave 0"
echo '{}' >"$wt_run/reports/task.json"
wt_want="$(python3 "$run_state" phase --probe "$probes_dir/row-08.json")"
# $1 labels the case; probe must exit 0 and phase must print row 8's line.
wt_phase() {
  run_probe "$wt_run" "$wt_repo" >"$tmp/wt-probe.json" || {
    echo "probe $1 should exit 0, got: $(cat "$tmp/probe-stderr")" >&2; exit 1; }
  local got
  got="$(python3 "$run_state" phase --probe "$tmp/wt-probe.json")"
  [[ -n "$wt_want" && "$got" == "$wt_want" ]] || {
    echo "phase $1 should print row-08.json's line, $wt_want, got: $got" >&2; exit 1; }
}
expect_field "with issue-1 checked out in ROOT" wave_reports 1 "$wt_run" "$wt_repo"
wt_phase "with issue-1 checked out in ROOT"
probe_git "$wt_repo" checkout -q main
expect_probe_usage "with issue-1 local but in no worktree" --run-dir "$wt_run" --root "$wt_repo" --issue 1
grep -Fq "issue-1" "$tmp/probe-stderr" || {
  echo "a local issue-1 in no worktree should be named on stderr, got: $(cat "$tmp/probe-stderr")" >&2; exit 1; }
# A merged or closed PR is row 1 from pr_state alone, and the usual shape after
# a merge is ROOT back on main with issue-1 left in no worktree, so that stop
# is skipped there. An open PR still stops.
wt_row1="$(python3 "$run_state" phase --probe "$probes_dir/row-01.json")"
for wt_bundle in "$bundles_dir/merged.json" "$tmp/bundle-closed.json"; do
  wt_state="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["state"])' "$wt_bundle")"
  run_probe "$wt_run" "$wt_repo" --pr-bundle "$wt_bundle" >"$tmp/wt-terminal.json" || {
    echo "probe on a $wt_state bundle with issue-1 in no worktree should exit 0, got: $(cat "$tmp/probe-stderr")" >&2; exit 1; }
  wt_got="$(python3 "$run_state" phase --probe "$tmp/wt-terminal.json")"
  [[ "$wt_got" == "${wt_row1/MERGED/$wt_state}" ]] || {
    echo "phase on a $wt_state bundle with issue-1 in no worktree should print ${wt_row1/MERGED/$wt_state}, got: $wt_got" >&2; exit 1; }
done
require_text work-issue/references/resume.md "A \`MERGED\` or \`CLOSED\` bundle takes ROOT there instead"
require_text _maintenance/work-issue/RATIONALE.md "except on a \`MERGED\` or \`CLOSED\` bundle, which takes ROOT"
expect_probe_usage "on an OPEN bundle with issue-1 in no worktree" --run-dir "$wt_run" --root "$wt_repo" --issue 1 --pr-bundle "$bundles_dir/open-findings.json"
grep -Fq "issue-1" "$tmp/probe-stderr" || {
  echo "an OPEN bundle with issue-1 in no worktree should name issue-1 on stderr, got: $(cat "$tmp/probe-stderr")" >&2; exit 1; }
require_text work-issue/references/resume.md "A local \`issue-N\` that no worktree has checked out exits 3"
require_text _maintenance/work-issue/RATIONALE.md "a local \`issue-<N>\` that no worktree has checked out exits 3"
probe_git "$wt_repo" worktree add -q "$wt_tree" issue-1
expect_field "with issue-1 in a linked worktree and ROOT on main" wave_reports 1 "$wt_run" "$wt_repo"
wt_phase "with issue-1 in a linked worktree and ROOT on main"

# Exit 3 with nothing on stdout. A field probe cannot answer is a null; input it
# cannot read is a usage error, and pr_state or review_state read as null would
# say no pull request exists.
u="$(new_run usage)"
expect_probe_usage "with no --run-dir" --root "$lab_repo" --issue 1
expect_probe_usage "with --issue 0" --run-dir "$u" --root "$lab_repo" --issue 0
expect_probe_usage "with --issue abc" --run-dir "$u" --root "$lab_repo" --issue abc
expect_probe_usage "with a --root that is not a git work tree" --run-dir "$u" --root "$u" --issue 1
expect_probe_usage "with an unreadable --pr-bundle" --run-dir "$u" --root "$lab_repo" --issue 1 --pr-bundle "$tmp/no-such-bundle.json"
echo 'not json' >"$tmp/bundle-notjson.json"
expect_probe_usage "with a bundle that is not JSON" --run-dir "$u" --root "$lab_repo" --issue 1 --pr-bundle "$tmp/bundle-notjson.json"
python3 - "$bundles_dir/open-findings.json" "$tmp" <<'PY'
import json, sys
bundle = json.load(open(sys.argv[1]))
for name, edit in (
    ("nothreads", lambda b: b.pop("threads")),
    ("nostate", lambda b: b.pop("state")),
    ("draft", lambda b: b.update(state="DRAFT")),
):
    copy = json.loads(json.dumps(bundle))
    edit(copy)
    json.dump(copy, open(f"{sys.argv[2]}/bundle-{name}.json", "w"))
PY
expect_probe_usage "with a bundle missing threads" --run-dir "$u" --root "$lab_repo" --issue 1 --pr-bundle "$tmp/bundle-nothreads.json"
expect_probe_usage "with a bundle missing state" --run-dir "$u" --root "$lab_repo" --issue 1 --pr-bundle "$tmp/bundle-nostate.json"
grep -Fq "state" "$tmp/probe-stderr" || { echo "a bundle missing state should be named on stderr" >&2; exit 1; }
expect_probe_usage "with a bundle whose state is DRAFT" --run-dir "$u" --root "$lab_repo" --issue 1 --pr-bundle "$tmp/bundle-draft.json"
expect_probe_usage "with --herdr-state sleeping" --run-dir "$u" --root "$lab_repo" --issue 1 --herdr-state sleeping
echo yesterday >"$u/pushed_at"
expect_probe_usage "with pushed_at 'yesterday' and no issue-1 branch" --run-dir "$u" --root "$tmp/whole-fresh/repo" --issue 1 --pr-bundle "$bundles_dir/open-findings.json"

# Neither fake was ever called, across every probe above.
for fake in gh herdr; do
  [[ ! -e "$tmp/called-$fake" ]] || { echo "probe called $fake" >&2; exit 1; }
done
# Every PROBE_FIELDS name has a case above.
unasserted=""
while IFS= read -r name; do
  grep -qx -- "$name" "$probe_asserted" || unasserted="$unasserted $name"
done <<<"$probe_names"
[[ -z "$unasserted" ]] || { echo "probe fields with no behavior case:$unasserted" >&2; exit 1; }

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
# Row 18's second reading promises a "wait on the reviewer" ending in the
# Resume tables; Step 8 item 5 (the instruction an agent actually follows)
# has to print it, not just the unconditional cleared-only line, or the
# documents disagree with each other inside the same skill.
require_text work-issue/SKILL.md "\"a human merges\" where \`review_state\` is \`cleared\`; \"waiting on the reviewer\" where every finding is answered and the queue published but the round has not cleared (row 18's second reading)"
require_text work-issue/SKILL.md "once the review is \`cleared\` — or, once every finding is answered and the queue published but nothing has cleared the round yet, \"waiting on the reviewer\" instead"
require_text work-issue/README.md "The final report ends \"a human merges\" once the review clears — or \"waiting on the reviewer\" once every finding is answered and the queue published but nothing has cleared the round yet."
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
# A missing trigger.txt is `absent`, never `no`; both copies of row 11 and
# row 13 say so.
require_text work-issue/SKILL.md "| 11 | red-team clean; \`trigger.txt\` absent, or its first line"
require_text work-issue/references/resume.md "| 11 | red-team clean; \`trigger.txt\` absent, or its first line"
require_text work-issue/SKILL.md "| 13 | red-team clean; trigger recorded;"
require_text work-issue/references/resume.md "| 13 | red-team clean; trigger recorded;"
# Step 1's two closing writes are probed, and row 7 sends a run missing either
# back to Step 1 in both copies of the table.
require_text work-issue/SKILL.md "no \`base_sha\` or no \`baseline.txt\`, or some task is not counted as reported"
require_text work-issue/references/resume.md "no \`base_sha\` or no \`baseline.txt\`, or some task is not counted as reported"
# Row 81: a worker's queue can reach Step 8 and publish its comment before any
# review lands, and that state is deliberately routed back to Step 6's poll
# rather than to a special-cased final report—RUN_DIR has no note of which
# step ran last (row 13) to tell it apart from an ordinary unreviewed pull
# request. The URL is what closes the gap that decision leaves.
# The poll's stop is the only report a run gets when nothing has happened,
# and it names the pull request so a run that never printed its final report
# still leaves the user the URL.
require_text work-issue/SKILL.md "no review yet on <PR URL>"
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
require_text work-issue/SKILL.md "(resume at item 1: the reproducer until \`trigger-repair-<k>.txt\` exists, then the adversarial-review invocation); or a queue row missing from the \`Deferred findings\` comment, or a repair report"
require_text work-issue/references/resume.md "(resume at item 1: the reproducer until \`trigger-repair-<k>.txt\` exists, then the adversarial-review invocation); or a queue row missing from the \`Deferred findings\` comment, or a repair report"
# Both Resume tables once sent the re-fire leg straight to the invocation,
# skipping the repair's reproducer, after the script had stopped saying so.
refute_text work-issue/SKILL.md "(resume at item 1's adversarial-review invocation)"
refute_text work-issue/references/resume.md "(resume at item 1's adversarial-review invocation)"
# The queue's comment is probed, and rows 14 and 17 both read it.
require_text work-issue/SKILL.md "or a triage row without a reply URL | Step 8;"
require_text work-issue/references/resume.md "or a triage row without a reply URL | Step 8;"
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
# Step 5's "Left out" is where adversarial-review's LISTED advisories land
# (adversarial-review row 39, work-issue row 96), in place of one issue each.
require_text work-issue/SKILL.md "\"Left out\" names every finding \`adversarial-review\`'s report lists as \`LISTED\`"
# Step 8 re-fires adversarial-review on a repair on two conditions, into the
# repair's own files: the round held a P0/P1/blocking row and the full diff
# fires (work-issue row 97), or the repair's own diff hits rows 1, 2, or 4
# (row 104, #162). Each condition is pinned on its own, so dropping either one
# goes red, and the repair-diff one names its base so it can't drift back to
# the whole branch.
require_text work-issue/SKILL.md "Once the reproducer comes back clean, the trigger re-fires on either of two conditions."
require_text work-issue/SKILL.md "**Severity:** that triage round held a row whose Severity is \`P0\`, \`P1\`, or \`blocking\`, and the full diff fires the trigger as Step 4 item 7 evaluates it."
require_text work-issue/SKILL.md "**Repair diff:** run \`git diff \"\$(cat RUN_DIR/redteam/repair-base-<k>)\"..HEAD\` as its own command and check its exit, then pass its output to \`adversarial-review/scripts/match-triggers.py rows --only 1,2,4\`"
# Piped straight into the matcher, a failing diff reads as "no row" (#162
# review); Step 8 and the resume probe both run it apart and check its exit.
refute_text work-issue/SKILL.md "HEAD | adversarial-review/scripts/match-triggers.py rows --only 1,2,4\`, prints a row"
# The probe prints through if/elif; an \`exit\` in it closes a pasted-into shell.
refute_text work-issue/references/resume.md "{ echo null; exit; }"
require_text work-issue/SKILL.md "second line \`condition: repair-diff\`, \`condition: severity\`, \`condition: both\`, or \`condition: none\`, naming which fired"
require_text work-issue/SKILL.md "A repair whose round held no such row and whose own diff prints no row gets the reproducer and nothing more"
# Step 7 writes the base before its dispatch and never overwrites it: a base
# rewritten on resume would drop the commits an interrupted repair already made.
require_text work-issue/SKILL.md "Before the dispatch, write \`git rev-parse HEAD\` to \`RUN_DIR/redteam/repair-base-<k>\`, k the triage round this repair answers, unless that file already exists. Write it once and never overwrite it"
require_text _maintenance/work-issue/RATIONALE.md "The new condition reads the repair's own diff and never the whole branch."
require_text work-issue/SKILL.md "RUN_DIR/redteam/trigger-repair-<k>.txt"
require_text work-issue/references/redteam.md "RUN_DIR/redteam/ar-state-repair-<k>.txt"
require_text work-issue/references/triage.md "carries a \`Severity\` cell"
refute_text work-issue/SKILL.md "with the trigger re-evaluated on the full diff"
# A repair round's re-fired review can list advisories after Step 5 has
# already written the PR body, so Step 8 copies them in itself; Step 5's copy
# never sees them.
require_text work-issue/SKILL.md "add every finding its report lists as \`LISTED\` to the open pull request's \"Left out\" section"
require_text work-issue/SKILL.md "every \`LISTED\` finding from a re-fired review is in the pull request's \"Left out\" section"
# A repo's PR template doesn't get to drop listed advisories: the "Left out"
# section is added whatever the template carries.
require_text work-issue/SKILL.md "With a template or without one, the body carries a \"Left out\" section naming every finding"
# An existing pull request gets its "Left out" section updated too. It isn't
# only pushed to, or a Step 4 review that re-ran after the PR opened loses its
# listed advisories.
require_text work-issue/SKILL.md "an existing pull request keeps its number, receives the push, and has any \`LISTED\` finding its \"Left out\" section lacks added to it"
refute_text work-issue/SKILL.md "an existing pull request keeps its number and simply receives the push"
require_text work-issue/references/resume.md "redteam/ar-state.txt"
require_text work-issue/SKILL.md "no \`redteam/ar-state.txt\` showing \`UNVERIFIED: 0\`"
refute_text work-issue/references/resume.md "ar_run_dir"
# Step 5 item 2 clears the conflict marker, or row 12 re-runs item 1 forever.
require_text work-issue/SKILL.md "remove \`RUN_DIR/conflict.txt\`"

# The probe is gathered by `run-state.py probe`, never assembled by hand from
# per-field commands (#146): a hand-gathered field reached phase unchecked in
# #136 and #139. Every command in resume.md spelled its run dir <RUN_DIR>, so
# that placeholder coming back is a command coming back.
require_text work-issue/references/resume.md "work-issue/scripts/run-state.py probe --run-dir"
require_text work-issue/SKILL.md "work-issue/scripts/run-state.py probe --run-dir"
refute_text work-issue/references/resume.md "<RUN_DIR>"
refute_text work-issue/SKILL.md "one command per field"
# The refutes above, and the fake gh and herdr in the probe section, each need
# their own Deliberately Not Built row.
require_text _maintenance/work-issue/RATIONALE.md "| Per-field shell commands in \`references/resume.md\` |"
require_text _maintenance/work-issue/RATIONALE.md "| Calling \`gh\` or \`herdr\` inside \`probe\` |"
# The bundle goes outside RUN_DIR, or saving it creates the RUN_DIR a fresh
# issue must not have yet, and row 5 archives the issue as a dead run.
require_text work-issue/references/resume.md 'bundle="$(mktemp)"'

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

# #135's ledger and its live scenario. The suite can pin the sentences that
# say a run keeps going; only the scenario can watch one do it.
require_text _maintenance/work-issue/RATIONALE.md "A committed wave with a later wave pending is not a stop"
require_text _maintenance/work-issue/RATIONALE.md "\`divvy-up\`'s per-wave gate and Step 3's \`code-review\` are checks, not stops"
require_text _maintenance/work-issue/RATIONALE.md "only an EVALS scenario can show a run keeps going"
require_text _maintenance/work-issue/RATIONALE.md "| 135 | The per-wave alternation adds no timing rule"
require_text _maintenance/work-issue/RATIONALE.md "| 136 | The per-wave loop advances on a settled wave, not only a committed one"
require_text _maintenance/work-issue/RATIONALE.md "| Advancing the wave loop only on a committed wave | Row 136."
require_text _maintenance/work-issue/RATIONALE.md "Ending an invocation at a committed wave for the user to re-invoke"
require_text _maintenance/work-issue/EVALS.md "A Two-Wave Plan Runs Both Waves in One Invocation"
require_text _maintenance/work-issue/EVALS.md "fails as well if it ends there with a message"

# The root README carries this skill's own install flag, in the map
# table's third column. The command form around it is pinned once, in
# repo-docs-smoke.sh, so this does not re-pin it twelve times.
require_text README.md "--skill work-issue"

echo "work-issue smoke: OK"
