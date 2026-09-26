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
require_file tests/fixtures/work-issue/review/changes-requested.json
# One over-budget probe per gated row, and the timing logs the budget reads.
for gated in 10 11 16 17; do
  require_file "tests/fixtures/work-issue/probes/row-$gated-over-budget.json"
done
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

  # A fourth verdict value. Step 4's routing, references/resume.md's
  # `redteam_last_failed` grep, and run-state.py's row 10 all split on the
  # same three values, and that grep's alternation is unanchored:
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
  "row-07:2" "row-07-isolation-incomplete:1" "row-08:3" "row-09:3" "row-10:4" "row-11:4" "row-11-trigger-unrecorded:4" "row-12:5" "row-13:5"
  "row-14:6" "row-15:6" "row-16:7" "row-17:8" "row-17-queued:8" "row-17-postpush:8"
  "row-10-repair-unverified:4" "row-10-repair-needed:4" "row-10-failed-twice:stop" "row-13-prepr-repair-clean:5" "row-16-earlier-queued:8" "row-17-review-repair-unpushed:8" "row-17-deferred-owed:8" "row-17-worker-queue:8" "row-18-answered:done" "row-18:done"
  "row-17-repair-advisory-only:8" "row-17-repair-blocking:8" "row-17-repair-blocking-settled:8"
  "row-10-over-budget:stop" "row-11-over-budget:stop" "row-16-over-budget:stop" "row-17-over-budget:stop"
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

# The review_over_budget probe, run as resume.md writes it.
budget_probe="$(sed -n 's/^| `review_over_budget` | `\([^`]*\)`.*/\1/p' work-issue/references/resume.md)"
[[ -n "$budget_probe" ]] || {
  echo "could not extract the review_over_budget probe from work-issue/references/resume.md" >&2
  exit 1
}
for budget_case in "build30-review61:true" "build30-review59:false" "bad-label:null" "missing:false"; do
  budget_run="$tmp/budget-${budget_case%%:*}"
  mkdir -p "$budget_run"
  [[ "${budget_case%%:*}" == missing ]] || cp "$timing_dir/${budget_case%%:*}.txt" "$budget_run/timing.log"
  budget_got="$(bash -c "${budget_probe//<RUN_DIR>/$budget_run}" 2>/dev/null)"
  [[ "$budget_got" == "${budget_case##*:}" ]] || {
    echo "review_over_budget on ${budget_case%%:*} should print ${budget_case##*:}, got: $budget_got" >&2
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

# The triage_blocking_rows probe, run as resume.md writes it against a round
# whose finding text says "P1" on a row the reviewer marked none. Reading the
# Severity cell rather than the row is what keeps that row from counting.
# The command is the row's first code span, and a table cell escapes its
# pipes as `\|`, so unescape them the way the markdown renderer would.
blocking_probe="$(sed -n 's/^| `triage_blocking_rows` | `\([^`]*\)`.*/\1/p' work-issue/references/resume.md \
  | sed 's/\\|/|/g')"
[[ -n "$blocking_probe" ]] || {
  echo "could not extract the triage_blocking_rows probe from work-issue/references/resume.md" >&2
  exit 1
}
tri_run="$tmp/tri-run"
mkdir -p "$tri_run/triage"
cp tests/fixtures/work-issue/triage/round-1.md "$tri_run/triage/round-1.md"
blocking_count="$(bash -c "${blocking_probe//<RUN_DIR>/$tri_run}")"
[[ "$blocking_count" == "1" ]] || {
  echo "triage_blocking_rows should count the one P1 row in the fixture round, got: $blocking_count (probe: $blocking_probe)" >&2
  exit 1
}
# A Finding cell quoting a shell pipe escapes it as `\|`, which must not
# shift the Severity column. A round with no Severity column can't answer, so
# the probe prints null, which phase's null-field stop (checked below) turns
# into a stop naming the field rather than reading
# 0. No round yet prints 0 without reading stdin, where it once hung.
for tri_case in "triage-pipe:1" "triage-noseverity:null" "empty:0"; do
  tri_dir="$tmp/tri-${tri_case%%:*}"
  mkdir -p "$tri_dir/triage"
  [[ "${tri_case%%:*}" == empty ]] || cp "tests/fixtures/work-issue/${tri_case%%:*}/round-1.md" "$tri_dir/triage/round-1.md"
  tri_got="$(bash -c "${blocking_probe//<RUN_DIR>/$tri_dir}" </dev/null)"
  [[ "$tri_got" == "${tri_case##*:}" ]] || {
    echo "triage_blocking_rows on ${tri_case%%:*} should print ${tri_case##*:}, got: $tri_got" >&2
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
require_text work-issue/references/resume.md "awk '/^[[:space:]]*## Waves[[:space:]]*$/{f=1;next} f&&/^[[:space:]]*\\|/{t=1;print;next} f&&t{exit}"
# has_waves reads the heading the way the parser does, whitespace stripped.
require_text work-issue/references/resume.md "grep -qE '^[[:space:]]*## Waves[[:space:]]*$'"
# Row 81: a worker's queue can reach Step 8 and publish its comment before any
# review lands, and that state is deliberately routed back to Step 6's poll
# rather than to a special-cased final report—RUN_DIR has no note of which
# step ran last (row 13) to tell it apart from an ordinary unreviewed pull
# request. The URL is what closes the gap that decision leaves.
# The poll's stop is the only report a run gets when nothing has happened,
# and it names the pull request so a run that never printed its final report
# still leaves the user the URL.
require_text work-issue/SKILL.md "no review yet on <PR URL>"
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
# Step 8 re-fires adversarial-review on a repair only for a P0/P1/blocking
# round (work-issue row 97), into the repair's own files.
require_text work-issue/SKILL.md "The trigger re-fires only where that triage round held a row whose Severity is \`P0\`, \`P1\`, or \`blocking\`."
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
