#!/usr/bin/env bash
# Pin the work-wave skill's load-bearing behavior. The skill fans N work-issue
# runs out at once and holds their push grants back until a merge test is green,
# so the rules that make that safe have to survive every edit to every document
# a lane's dispatch is built from. Many assertions below are refutes, because
# each mechanism this design cut is a reasonable-sounding idea somebody will
# propose again.
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

skill=work-wave/SKILL.md
brief=work-wave/references/lane-brief.md
merge_test=work-wave/references/merge-test.md
script=work-wave/scripts/check-footprints.py
ledger=_maintenance/work-wave/RATIONALE.md
fixtures=tests/fixtures/work-wave

# --- Inventory: every document and script the skill ships, plus the fixtures
# the functional section drives. ---

require_file "$skill"
require_file work-wave/README.md
require_file "$brief"
require_file "$merge_test"
require_file "$script"
require_file "$ledger"
require_file _maintenance/work-wave/EVALS.md

require_file "$fixtures/lane-a.md"
require_file "$fixtures/lane-b.md"
require_file "$fixtures/lib-noslash.md"
require_file "$fixtures/lib-slash.md"
require_file "$fixtures/backtick.md"
require_file "$fixtures/empty.md"
require_file "$fixtures/plan-waves.md"
require_file "$fixtures/plan-badwaves.md"
require_file "$fixtures/runs/issue-7/plan.md"
require_file "$fixtures/runs-tableless/issue-8/plan.md"
# Its table owns `src/a.py` in backticks, which lane-a owns bare.
require_file "$fixtures/runs-malformed/issue-6/plan.md"
# The closed run overlaps lane-a on purpose. Without it on disk, the check that
# closed/ is ignored passes because there is nothing to ignore.
require_file "$fixtures/runs/closed/issue-9/plan.md"
# The footprint Step 1 derives from runs-tableless/issue-8/plan.md's `Files:`
# line when issue-8 is an already-started lane whose copy has no table yet.
require_file "$fixtures/copy-issue-8.md"
require_file work-wave/scripts/handback.py
require_file "$fixtures/handback/terminal-build.txt"
require_file "$fixtures/handback/midrun-build.txt"

[[ "$(find work-wave -maxdepth 1 -type f | wc -l | tr -d ' ')" == "2" ]] || {
  echo "work-wave/ must ship only SKILL.md and README.md at top level" >&2
  exit 1
}

# --- Frontmatter. User-invoked is deliberate: a misfire during ordinary
# planning spends a whole fan-out, and no sibling skill calls this one, so
# AGENTS.md's reachability condition does not apply. ---

require_text "$skill" "name: work-wave"
require_text "$skill" 'description: "Run N GitHub issues at once, one work-issue run per issue in its own worktree, with the footprints proved disjoint, the cross-lane coupling question answered and recorded, the merge order fixed, and the branches merged together and verified before any lane opens a pull request. Use ONLY when the user explicitly invokes work-wave. It never plans an issue, never merges one, and never advances a single issue: for one issue, use work-issue."'
require_text "$skill" "argument-hint: '<issue> <issue> [<issue>...] [--plan N=PATH ...] [--lane-model opus|fable] [--review-loop[=<comment>]] [--auto-budget <ratio>] [--defer-after <k>] [--repair-class <class>] [--dry-run]'"
require_text "$skill" "disable-model-invocation: true"

# --- The steps. A dropped heading is a dropped step, and the resume table
# jumps to these by number. ---

require_text "$skill" "## Step 0 — Gate"
require_text "$skill" "## Step 1 — Footprint"
require_text "$skill" "## Step 2 — Couple and order"
require_text "$skill" "## Step 3 — Confirm"
require_text "$skill" "## Step 4 — Baseline and dispatch"
require_text "$skill" "## Step 5 — Gate a lane"
require_text "$skill" "## Step 6 — Merge test before publish"
require_text "$skill" "## Step 7 — Publish"
require_text "$skill" "## Step 8 — Report"
require_text "$skill" "## Resume"
require_text "$skill" "## Further Reading"

# The steps use these constants by name. A constant that loses its definition
# line still appears downstream, where it reads as a word rather than a value.
for constant in ISSUES REPO DEFAULT ROOT COMMON PROJECT WAVE_ID WAVE_DIR HANDBACK "PLAN[N]" "LANE[N]" LANE_MODEL MERGE_TREE VERIFY_CMD INSTALL_CMD CONTRACT_PATHS FLAGS; do
  require_text "$skill" "**$constant**"
done

# The resume table reads first match wins. Lose the clause and two rows that
# both match pick a step by whichever a reader happens to see first.
require_text "$skill" "The world outranks WAVE_DIR, and WAVE_DIR outranks memory."
require_text "$skill" "WAVE_DIR says only what this skill has already produced. First match wins:"

# --- The safety property. These are the assertions the whole design rests on. ---

# A disjointness check run after the lanes start finds an overlap only as a
# rebase conflict, after the user has walked away.
require_text "$skill" "proved by a script before anything is dispatched"
require_text "$skill" "A non-zero exit is a hard stop, not a warning."

# The lanes' own check-inflight.py gates race each other, so this skill's
# proof is the one that counts. Losing the reason invites someone to delete
# the script as redundant.
require_text "$skill" "that script skips a sibling whose table is not there yet"
# Codex finding 1 on PR #141: skipping a tableless sibling here recreated the
# very race this step exists to close.
require_text "$skill" "A tableless in-flight sibling stops the wave until it writes its table, or until the user moves its run directory to \`<COMMON>/work-issue/closed/\` because the run is dead."
# Codex finding 1 of the third review on PR #141: dropping a sibling's
# malformed entry and counting the run as checked passed a backticked twin of
# a lane's path.
require_text "$skill" "An in-flight sibling with no parseable \`## Waves\` table, or whose table carries an entry the script rejects as malformed, prints an \`unchecked:\` line and exits 1"

# Step 2 exists because disjoint paths do not make two lanes independent.
require_text "$skill" "Disjoint paths prove two lanes cannot lose each other's writes. They do not prove the two lanes are independent"

# One dispatch per message serializes the wave, and it looks identical in the
# transcript to the real thing.
require_text "$skill" "Dispatch every lane in a SINGLE message so they run concurrently"
require_text "$skill" "Name LANE_MODEL on every dispatch."

# --isolate keeps an unattended lane off work-issue's isolation ask row, which
# nobody is there to answer.
require_text "$skill" "told to invoke \`work-issue\` by name with \`<N> <PLAN[N]> --isolate --no-publish\`"

# Step 3's collision check refuses before dispatch rather than letting a lane
# meet the ask row, and the exemption keeps a wave that includes an
# already-started issue passable.
require_text "$skill" "Any hit refuses the wave here, naming every such path at once."
require_text "$skill" "A lane already started (Step 0 item 4) is exempt when the tree at its WORKTREE holds its own \`issue-N\`, checked out or mid-rebase"

# The orchestrator's git boundary. A wave that commits or pushes on a lane's
# branch races the lane doing the same.
require_text "$skill" "This skill itself never commits, never pushes, and never touches \`issue-N\` or DEFAULT."

# The merge test's four trigger points, each by the sentence that fires it. A
# one-word pin like "baseline" would pass on any prose that mentions one.
require_text "$skill" "Run the merge test once with no branches"
require_text "$skill" "triggers a merge test now over every lane branch that has commits, returned or not"
require_text "$skill" "Run the merge test per [references/merge-test.md](references/merge-test.md) over the merge set in \`order.md\`'s order"
require_text "$skill" "run the merge test once more, in order, before anything is reported"
require_text "$skill" "Merge test: baseline now, on any contract change, before any pull request, and before the final report."
require_text "$skill" "git worktree add --detach MERGE_TREE origin/DEFAULT"

# git status once read a copied tree as clean over a staged index. diff --stat
# HEAD compares against the commit, which the index can't hide, but it never
# lists an untracked file, so a suite that writes a non-ignored file read as
# clean until ls-files joined it (Codex finding 2 of the second review on PR
# #141).
require_text "$skill" "Green, with \`git -C MERGE_TREE diff --stat HEAD\` and \`git -C MERGE_TREE ls-files --others --exclude-standard\` both empty, proceeds."
require_text "$skill" "either non-empty is \`dirty after verify:\` and red, the untracked paths listed"

# Codex finding 3 of the second review on PR #141: with three lanes, a branch
# can conflict with any branch already merged, and blaming the one merged just
# before it corrects the wrong coupling row.
require_text "$skill" "each branch already merged in this run whose own diff against the \`base:\` touches a conflicted path, or DEFAULT where none does."

# Codex finding 1 of the second review on PR #141: a started lane's resume
# builds from its cached copy, and the script skips its lane-named run dir, so
# proving it on PLAN[N] let an edited source plan hide the copy's overlap.
require_text "$skill" "A lane already started (Step 0 item 4) is proved on its \`RUN_DIR/plan.md\`, the copy its own \`work-issue\` builds from, never on PLAN[N]"
# A tableless copy passed straight to the script reads as a bare path list and
# passes a real overlap, so the instruction to pass the derived file instead is
# the half of this rule that does the work.
require_text "$skill" "Where it has none yet, derive \`footprint/issue-<N>.md\` from the copy's \`Files:\` lines and pass that file instead, never the tableless copy"

# The lane fills in pr itself, so a check on the field alone passes a lane
# that opened a pull request and reported pr as null. gh pr list asks GitHub
# instead (#224, ledger row 40).
require_text "$skill" "| a \`build\` report whose \`pr\` is non-null, or for which \`gh pr list --head issue-<N> --state all --json url --jq '.[].url'\` prints a URL | The lane published before the merge test"
require_text "$skill" "gh pr list --head issue-<N> --state all"
# A failed gh call recorded as a stop would re-stop every resume under a label
# saying a pull request exists. With no gate record the resume re-runs the
# check instead (ledger row 40).
require_text "$skill" "A non-zero exit stops the wave with its stderr quoted and writes no gate record for that report"

# The orchestrator writes its merge-test line into its own facts file. Writing
# into a lane's file breaks the single-writer rule the facts log rests on.
require_text "$skill" "\`WAVE_DIR/facts/wave.md\`, the one facts file the orchestrator owns"

# Codex finding 2 on PR #141: a build report on disk proves the lane returned,
# not that Step 5 gated it. Without the record and its resume row, a crash
# between the two skips the pr check, the re-check, and the merge test.
require_text "$skill" "\`reports/issue-<N>-<phase>.json\`, \`gate/issue-<N>.md\`, \`baseline.txt\`"
require_text "$skill" "5. **Gate record.** Last, after items 1 through 4, write \`WAVE_DIR/gate/issue-<N>.md\`"
# The gate row sits ahead of the re-dispatch row. With the re-dispatch row
# first, a crash that leaves one lane's report ungated while another lane is
# still building sends the wave to Step 4. Step 5 fires as a report returns,
# the saved one never returns again, and it reaches Step 6 ungated.
require_text "$skill" "| 6 | \`merge-test/0.md\`; some saved build report has no \`gate/issue-<N>.md\`, or some gate record recorded a stop | Step 5 for the ungated reports only, then probe again; a recorded stop stops the wave again, naming the lane and its pull-request URL or the re-check's stderr lines, until the user rules on it |"
require_text "$skill" "| 7 | \`merge-test/0.md\`; some unheld lane has no \`reports/issue-N-build.json\` | Step 4 for those lanes only, in one message;"
require_text "$skill" "Enter when every unheld lane has returned, every build report in the merge set has its \`gate/issue-<N>.md\`, and no gate record is a recorded stop; otherwise go back to Step 5."

# A probe that asks only whether a gate record exists sends a record of a
# failed re-check straight to Step 6. The route row and the recorded-stop
# definition make what the record says count.
require_text "$skill" "| the footprint re-check (item 2) exited non-zero | Stop the wave with the script's stderr lines quoted, the way Step 1 stops on a non-zero exit. Nothing proceeds to Step 6. |"
require_text "$skill" "A gate record whose route is the early-publish stop or the failed re-check stop is a recorded stop, and the resume probe stops the wave again on it."

# Resume row 4 reads any check.txt as a passed proof, so a failing Step 1
# must never write one.
require_text "$skill" "Save the output to \`WAVE_DIR/footprint/check.txt\` on exit 0 only. A non-zero exit's output goes to \`WAVE_DIR/footprint/check-failed.txt\`"

# Codex finding 2 of the third review on PR #141: Step 0 item 3 creates
# WAVE_DIR, so a probe that asked only for WAVE_DIR resumed an interrupted
# Step 0 at Step 1 with no siblings found and no commands harvested.
require_text "$skill" "6. Last, after items 1 through 5, write \`WAVE_DIR/harvest.md\`"
require_text "$skill" "| 2 | no WAVE_DIR, or WAVE_DIR with \`lanes.md\` or \`harvest.md\` missing | Step 0 |"
require_text "$skill" "| 3 | \`lanes.md\` and \`harvest.md\`; no \`footprint/check.txt\` | Step 1 |"

# Codex finding 3 of the third review on PR #141: Step 6 records SHAs for the
# merge set alone, so a probe comparing every lane's HEAD looped back to Step 6
# forever once a lane was held or failed.
require_text "$skill" "| 8 | every gate record; some lane in the merge set has no \`reports/issue-N-publish.json\`, and the newest \`merge-test/<k>.md\` with k > 0 whose recorded branches are exactly the merge set, each at its current HEAD, is missing or not green | Step 6, which stops again on a red or conflicted record |"
require_text "$skill" "Where the HEAD of any lane in the merge set differs from its SHA in the newest \`merge-test/<k>.md\`"
refute_text "$skill" "every lane's current HEAD"
refute_text "$ledger" "**The Resume table is prose the orchestrator walks by hand.**"
require_text "$ledger" "| 51 | The Resume table is executable"

# Codex finding 3 on PR #141: each lane rebases before it publishes, so a
# merge test over a stale base tested a tree nobody will merge.
require_text "$skill" "Check the base before any dispatch: \`git -C ROOT fetch origin DEFAULT\`, then compare \`git -C ROOT rev-parse origin/DEFAULT\` with the \`base:\` line of the newest \`merge-test/<k>.md\` over exactly the merge set at its current HEADs, which must be green."
require_text "$skill" "Step 7 for those lanes only, when the fetched \`origin/DEFAULT\` equals that merge test's \`base:\`; where it differs, Step 6, then Step 7"
# The re-run proves the combined tree, and the published SHAs are rebased
# ones no merge test recorded. Claiming more would hide the gap the ledger's
# Known Limitations carries.
require_text "$skill" "A merge onto the current tip tests the combined tree the lanes' clean rebases produce, not the SHAs they will publish"
require_text "$ledger" "**The published SHAs are rebased SHAs that no merge test recorded.**"

# A report path the orchestrator cannot open costs a round trip, which is one
# of #113's four measured losses. handback.py catches it before a report is
# saved, since a saved one can't be replaced by a re-prompt's answer.
require_text "$skill" "| A contract field missing (\`facts\` excepted) or of the wrong type, \`worktree\` or \`run_dir\` not absolute, or \`head\` not a SHA, where only a \`refused\` or \`failed\` report may leave \`worktree\` and \`head\` null | Never reaches this step: \`handback.py\` catches it at Step 4 and saves the message as a hand-back"
require_text "$skill" "a \`refused\` or \`failed\` report may carry a null \`worktree\`, which reports no location"

# Fewer than two issues is work-issue's job, and a plan held only in the
# conversation is unreachable from a fresh lane subagent.
require_text "$skill" "Fewer than two stops the run with \"one issue is \`work-issue N\`\"."
require_text "$skill" "Its route 4—the plan held in the conversation—is unreachable from a fresh subagent"

# The skill ends by handing a human the merge order, and merges nothing itself.
require_text "$skill" "\"a human merges, in this order\""

# --- The references. The brief is the whole prompt a lane receives, so every
# placeholder, report field, and status the gate reads has to be in it. ---

for placeholder in SIBLINGS ISSUE PLAN N WORKTREE RUN_DIR PHASE GRANT WAVE_DIR FACTS FACTS_PATH COUPLING ORDER REVIEW_LOOP POLICY; do
  require_text "$brief" "- \`{{$placeholder}}\` —"
done

for field in lane phase status head worktree run_dir files_changed contract_changed facts pr detail question; do
  require_text "$brief" "  \"$field\": "
done

require_text "$brief" "\`status\` is one of four: \`done\` (work-issue reached the Done-when"
require_text "$brief" "\`stopped\` (work-issue stopped for want of an answer, or a worker did"
require_text "$brief" "\`failed\` (a gate failed twice, a merge test inside work-issue went red"
require_text "$brief" "\`refused\` (work-issue's Step 0 refused the plan or the cross-run check"

# Without --isolate a lane meets work-issue's isolation ask row, and nobody is
# there to answer it.
require_text "$brief" "\`--isolate\` is not optional: your siblings are"

# #224: the build line's --no-publish holds the withheld push when a lane
# misreads the grant. The publish line has to go without it, or no lane ever
# reaches work-issue's Step 5.
require_text "$brief" "In the publish phase, exactly as:"
# grep -F matches the build line as a substring, so pin the publish line whole.
publish_line="$(grep -F -A2 "In the publish phase, exactly as:" "$brief" | tail -1)"
[ "$publish_line" = "    work-issue {{N}} {{PLAN}} --isolate{{REVIEW_LOOP}}{{POLICY}}" ] || {
  echo "publish line in $brief is not exactly: work-issue {{N}} {{PLAN}} --isolate{{REVIEW_LOOP}}{{POLICY}}" >&2
  exit 1
}
require_text "$skill" "again, with \`--no-publish\` dropped"

# #230: a hand-written \`echo 99 >\` into seven run dirs is what the flag
# replaces. Each pin ties the forwarding to a place a lane can be reached:
# the flag line, and a resumed wave's next dispatch.
require_text "$skill" "\`--review-loop[=<comment>]\` goes on every lane's \`work-issue\` invocation this run dispatches"
require_text "$skill" "A wave re-invoked with \`--review-loop\` passes it on the next dispatch of every merge-set lane whose RUN_DIR is still open"
# #361: Step 8 re-polls a lane stopped at work-issue's review poll cap, once,
# with the record written before the dispatch and ahead of the re-test.
require_text "$skill" "A merge-set lane whose open RUN_DIR holds \`triage/waiting\` and that has no \`WAVE_DIR/repoll/issue-<N>\` is re-polled once."
require_text "$skill" "Write every such lane's \`WAVE_DIR/repoll/issue-<N>\` before the dispatch,"
require_text "$skill" "a resumed wave never re-polls a lane twice"
require_text "$skill" "The re-polls run before the merge-test re-check below"
require_text "$skill" "Step 8 re-polls it once before the report."
refute_text "$skill" "until #361 lands"
require_text "$brief" "In the repoll phase, run the publish-phase line above unchanged."
require_text "$brief" "- \`{{PHASE}}\` — \`build\` at Step 4, \`publish\` at Step 7, \`repoll\` at Step 8's re-poll."
# A failed gh check writes no gate record, so resume runs it again rather than reading a record that says none.
require_text "$skill" "the wave stops with no gate record for that report"

# A lane that ends its turn with background workers running hands back a wave nobody gated, as issue-165's lane did in #198.
require_text "$brief" "Do not end your turn while any worker or repair dispatch you made is outstanding."

# The seam that carries facts past the lane agent to the workers who would
# otherwise relearn them. Losing it makes decision 3's row false.
require_text "$brief" "divvy-up's {{CALLER_NOTES}} placeholder; append the current contents of"

# One writer per facts file. Concurrent lanes appending to one file race.
require_text "$brief" "{{FACTS_PATH}}—that file is yours alone, and you write to no other file"

# The build grant is the one lever that holds the merge test ahead of every
# pull request. Reword it loosely and a lane publishes early.
require_text "$brief" "The push and pull-request half is withheld for this invocation: treat it as a no for Steps 5 through 8, stop once Step 4's Done-when holds, and report."
require_text "$brief" "Yes to all of it: rebase, push issue-{{N}} to origin as issue-{{N}}, open a pull request against {{DEFAULT}}"

require_text "$brief" "Your final message is exactly one fenced json block and nothing else"

require_text "$merge_test" "- **Baseline**, Step 4, with no branches, before any lane is dispatched."
require_text "$merge_test" "- **Contract change**, Step 5, over every lane branch with commits"
require_text "$merge_test" "- **Before publish**, Step 6, over the full merge set in \`order.md\` order"
require_text "$merge_test" "- **HEAD moved**, Step 8, re-run once more before the final report"
require_text "$merge_test" "git -C ROOT worktree add --detach MERGE_TREE origin/DEFAULT"
require_text "$merge_test" "Record \`base: origin/<DEFAULT> <sha>\` from \`git -C MERGE_TREE rev-parse HEAD\`."
require_text "$merge_test" "6. **Record the run.** Write \`WAVE_DIR/merge-test/<k>.md\`, in this order: the \`base:\` line"
require_text "$merge_test" "Sequential, never octopus, so a conflict names the one branch that failed to merge and the branches it hit"
require_text "$merge_test" "for each branch issue-M already merged into MERGE_TREE in this run, its own paths from \`git -C ROOT diff --name-only <base>...issue-M\`"
require_text "$merge_test" "Record \`conflict: issue-N with <issue-M, ...> — <paths>\`, listing every issue-M whose paths include a conflicted one, or \`conflict: issue-N with DEFAULT — <paths>\` where none does."
require_text "$merge_test" "\`git -C MERGE_TREE diff --stat HEAD\` and \`git -C MERGE_TREE ls-files --others --exclude-standard\`. Either non-empty is \`dirty after verify:\` and red, with the untracked paths listed."
require_text "$merge_test" "Checked this way, never with \`git status\`"
require_text "$merge_test" "\`git worktree remove --force MERGE_TREE\`, on every route out"

# Every commit message, pull request body, and dispatch these documents shape
# goes out without an attribution trailer or a generated-by footer. The
# ledger's Deliberately Not Built table carries the row, and says why this
# refute alone reaches past SKILL.md.
for doc in "$skill" "$brief" "$merge_test"; do
  refute_text "$doc" "Co-Authored-By"
  refute_text "$doc" "Generated with"
done

# --- The cut features, one per Deliberately Not Built row in the ledger.
# They run against SKILL.md alone, because merge-test.md, the README, and the
# ledger name `cp -R` and `git archive` in order to refuse them, and a refute
# there would fail on the row that justifies it. ---

# Row 6: a copied tree's .git file points at the original gitdir, and an
# archived tree has no .git, so check-waves.py skips every on-disk check.
refute_text "$skill" "cp -R"
refute_text "$skill" "git archive"

# Row 6: an N-way conflict names no branch it hit, and no human merges that way.
refute_text "$skill" "octopus"
refute_text "$skill" "branch before"
refute_text "$merge_test" "branch before"

# Row 8: SKILL.md names the retry in order to refuse it, so the pin is the
# refusing sentence rather than a refute.
require_text "$skill" "no rung-up retry, because \`work-issue\` has already applied \`divvy-up\`'s retry inside the lane and LANE_MODEL is already the rung a retry would reach"

# Rows 12 and 21: one shared file races under concurrent appends.
refute_text "$skill" "facts.md"

# Row 15: a phase note outlives the crash that invalidates it.
refute_text "$skill" "phase.txt"
require_text "$skill" "nothing in it says which step the wave believes it reached"

# Row 11: a lane runs gates whose judgment divvy-up keeps on the session model.
refute_text "$skill" "sonnet"
refute_text "$skill" "haiku"
require_text "$skill" "Never lower"

# Row 9: order.md's After column carries the dependency, and a second column
# would restate it until the two drift.
refute_text "$skill" "Dependencies"

# Row 1: a tree pre-made at a lane's own path lands it on work-issue's ask row.
require_text "$skill" "nothing about its worktree, its branch, or its run directory is made here"
refute_text "$skill" "worktree add -b"

# #113's third Non-Goal: a human merges.
refute_text "$skill" "gh pr merge"

# Row 25 and #113's second Non-Goal. There is no mechanism to refute, so the
# refusal itself is the pin.
require_text "$skill" "Plan them first: \`writing-plans\`, then \`work-wave <ISSUES> --plan N=PATH\`."

# #224's first Non-Goal: whether an early pull request stays open is the
# user's call, so the wave stops and leaves it open.
refute_text "$skill" "gh pr close"

# A description that lists the workflow becomes the shortcut the model takes
# instead of reading the body.
refute_text "$skill" "description: \"Step"

# #198's second Non-Goal: Step 5 holds a stopped lane's question for the user.
# The #198 orchestrator resumed its stopped lanes by hand with SendMessage, so
# an automatic route would likely name it too.
refute_text "$skill" "SendMessage"
require_text "$skill" "The lane's question is held for the user with the wave's next message."

# --- Maintenance ledger. A ledger without its section headings is prose nobody
# can navigate under time pressure. ---

require_text "$ledger" "## Where This Came From"
require_text "$ledger" "## Decision Ledger"
require_text "$ledger" "## Deliberately Not Built"
require_text "$ledger" "## Known Limitations"
# #230: the work-wave half of the review-loop ledger row.
require_text "$ledger" "work-wave forwards \`--review-loop[=<comment>]\` on every lane dispatch"
# #361: the re-poll ledger row.
require_text "$ledger" "Step 8 re-polls each merge-set lane stopped at \`work-issue\`'s review poll cap once"
require_text "$ledger" "| 40 | The build dispatch runs \`work-issue <N> <PLAN> --isolate --no-publish\`, and Step 5 runs \`gh pr list --head issue-<N> --state all\` for every build report"
# The root README carries this skill's own install flag, in the map table's
# third column. The command form around it is pinned once, in
# repo-docs-smoke.sh.
require_text README.md "--skill work-wave"

# --- The vendored block. check-footprints.py carries paths_overlap,
# owns_entry_problem, path_within, and the table parser out of
# check-inflight.py byte for byte. Extracted by function and constant names
# rather than line numbers, since both files reflow as their skills grow. ---

require_text "$script" "Vendored verbatim from work-issue/scripts/check-inflight.py"
# The header wraps between "Upstream is" and "authoritative", so the pin
# takes the rule from the half of the sentence that holds it.
require_text "$script" "authoritative: fix a bug there first, then re-copy"

extract_vendored() {
  local file="$1"
  sed -n '/^def paths_overlap/,/^    return path\.startswith(prefix)$/p' "$file"
  sed -n '/^COLUMNS = /,/^Row = collections\.namedtuple/p' "$file"
  sed -n '/^def split_row/,/^    return rows, problems$/p' "$file"
}

extract_vendored work-issue/scripts/check-inflight.py > "$tmp/upstream.txt"
extract_vendored "$script" > "$tmp/vendored.txt"

# Two empty extractions `cmp` clean against each other, so a renamed function
# would read as a passing identity check. The line floor catches that first.
[[ "$(wc -l < "$tmp/upstream.txt" | tr -d ' ')" -gt 200 ]] || {
  echo "the vendored-block markers matched almost nothing in check-inflight.py; fix the markers, not the floor" >&2
  exit 1
}

# owns_entry_problem's invisible-character test holds four zero-width code
# points in a string literal: U+200B, U+200C, U+200D, U+FEFF. A transcript copy
# drops them, and the function then looks identical in every editor while
# rejecting nothing. Checked before `cmp` so that failure gets named for what
# it is, rather than reported as generic drift a maintainer "fixes" by
# re-copying the same stripped transcript.
zero_width="$(printf '\xe2\x80\x8b\xe2\x80\x8c\xe2\x80\x8d\xef\xbb\xbf')"
LC_ALL=C grep -Fq -- "$zero_width" "$script" || {
  echo "check-footprints.py lost the zero-width characters in owns_entry_problem; re-copy with sed from check-inflight.py, never from a transcript" >&2
  exit 1
}

cmp "$tmp/upstream.txt" "$tmp/vendored.txt" || {
  echo "check-footprints.py's vendored functions have drifted from work-issue/scripts/check-inflight.py" >&2
  exit 1
}

# A SyntaxWarning prints on every invocation, as noise a caller cannot silence.
python3 -W error::SyntaxWarning -c "import ast; ast.parse(open('$script').read())" || {
  echo "check-footprints.py raises a SyntaxWarning" >&2
  exit 1
}

# --- Functional checks. Cheap, deterministic, no subagents. Every exit code is
# asserted as the exact number the contract promises: Step 1 branches on it,
# and a "non-zero" assertion would pass a script that exits 3 on an overlap. ---

# Runs the script, capturing stdout, stderr, and the exit code apart, since
# the pass lines go to stdout and every problem line to stderr.
footprints() {
  set +e
  python3 "$script" "$@" >"$tmp/out" 2>"$tmp/err"
  status=$?
  set -e
  out="$(cat "$tmp/out")"
  err="$(cat "$tmp/err")"
}

expect_status() {
  local want="$1"
  local what="$2"
  [[ "$status" == "$want" ]] || {
    echo "$what should exit $want, got $status: stdout: $out stderr: $err" >&2
    exit 1
  }
}

expect_line() {
  local stream="$1"
  local line="$2"
  local what="$3"
  grep -Fxq -- "$line" <<<"$stream" || {
    echo "$what should print the whole line '$line', got: $stream" >&2
    exit 1
  }
}

# Step 2's worklist is the pair: lines, one per pair of lanes and no fewer, so
# the coupling record cannot skip one.
expect_pairs() {
  local want="$1"
  local what="$2"
  local got
  got="$(grep -c '^pair: ' <<<"$out" || true)"
  [[ "$got" == "$want" ]] || {
    echo "$what should print exactly $want pair: lines, got $got: $out" >&2
    exit 1
  }
}

footprints --lane issue-1="$fixtures/lane-a.md" --lane issue-2="$fixtures/lane-b.md"
expect_status 0 "two disjoint lanes"
expect_pairs 1 "two disjoint lanes"
expect_line "$out" "pair: issue-1 issue-2" "two disjoint lanes"
expect_line "$out" "OK: 2 lanes disjoint (checked 0 in-flight runs)" "two disjoint lanes"

# The third lane is a plan with a ## Waves table, so this also proves the
# script reads the post-build shape Step 5 hands it, every wave included.
footprints --lane issue-1="$fixtures/lane-a.md" --lane issue-2="$fixtures/lane-b.md" --lane issue-3="$fixtures/plan-waves.md"
expect_status 0 "three disjoint lanes"
expect_pairs 3 "three disjoint lanes"
expect_line "$out" "footprint: issue-2 1 path" "three disjoint lanes"
expect_line "$out" "footprint: issue-3 3 paths" "three disjoint lanes"
expect_line "$out" "OK: 3 lanes disjoint (checked 0 in-flight runs)" "three disjoint lanes"

# #162: `src/lib` and `src/lib/` are one territory spelled two ways, and the
# predicate once answered no.
footprints --lane issue-1="$fixtures/lib-noslash.md" --lane issue-2="$fixtures/lib-slash.md"
expect_status 1 "the #162 pair"
expect_line "$err" "check-footprints: overlap: src/lib — issue-1 owns src/lib, issue-2 owns src/lib/" "the #162 pair"

# A backticked path differs from a peer's bare spelling of the same file, so
# it is refused rather than compared.
footprints --lane issue-1="$fixtures/lane-a.md" --lane issue-2="$fixtures/backtick.md"
expect_status 1 "a backticked entry"
expect_line "$err" "check-footprints: malformed: issue-2: '\`src/x.py\`': backtick; write the path bare, without markdown decoration" "a backticked entry"

# A lane that owns nothing overlaps nothing, so it would pass the proof
# vacuously.
footprints --lane issue-1="$fixtures/lane-a.md" --lane issue-2="$fixtures/empty.md"
expect_status 1 "an empty lane"
expect_line "$err" "check-footprints: empty: issue-2 owns no paths" "an empty lane"

footprints --lane issue-1="$fixtures/lane-a.md" --lane issue-2="$fixtures/lane-b.md" --runs "$fixtures/runs"
expect_status 1 "a lane overlapping an in-flight run"
expect_line "$err" "check-footprints: overlap: src/b.py — issue-2 owns src/b.py, in-flight issue-7 task t7 owns src/b.py" "a lane overlapping an in-flight run"

# One tabled run that overlaps nothing, and a closed run that overlaps lane-a.
# The closed run is ignored without a word, so stderr stays empty.
footprints --lane issue-1="$fixtures/lane-a.md" --lane issue-3="$fixtures/plan-waves.md" --runs "$fixtures/runs"
expect_status 0 "a tabled run and a closed run"
expect_line "$out" "OK: 2 lanes disjoint (checked 1 in-flight run)" "a tabled run and a closed run"
[[ -z "$err" ]] || {
  echo "a tabled run and a closed run should print nothing on stderr, got: $err" >&2
  exit 1
}
if grep -Fq "issue-9" <<<"$out$err"; then
  echo "a run under closed/ must be ignored silently, got: $out $err" >&2
  exit 1
fi
# The closed run sits one level down, so a script that stops excluding closed/
# never reaches issue-9. It reads closed/ itself as a tableless run and says
# so on stderr, and the issue-9 check above can't see that.
if grep -Fq "closed" <<<"$err"; then
  echo "closed/ must be skipped without a stderr line, got: $err" >&2
  exit 1
fi

# Ledger row 22, Codex finding 1 on PR #141. issue-8's plan says only
# `Files: src/a.py`, which lane-a owns. Skipping it passed that overlap, so a
# tableless run fails the proof even though every compared path is disjoint.
footprints --lane issue-1="$fixtures/lane-a.md" --lane issue-3="$fixtures/plan-waves.md" --runs "$fixtures/runs-tableless"
expect_status 1 "a tableless in-flight run"
expect_line "$err" "check-footprints: unchecked: issue-8 has no ## Waves table; wait for it to write one, or move its run dir to closed/ if the run is dead" "a tableless in-flight run"
# The skip lived in this script, so its refute runs here rather than against
# SKILL.md with the other cuts.
refute_text "$script" "skipped:"

# Ledger row 36, Codex finding 1 of the third review on PR #141. issue-6's
# table owns `src/a.py` in backticks beside lane-a's bare src/a.py. Dropping
# the bad entry exited 0 and counted the run as checked, so the whole run is
# unchecked instead.
footprints --lane issue-1="$fixtures/lane-a.md" --lane issue-2="$fixtures/lane-b.md" --runs "$fixtures/runs-malformed"
expect_status 1 "an in-flight run with a malformed entry"
expect_line "$err" "check-footprints: unchecked: issue-6 has a malformed entry: '\`src/a.py\`': backtick; write the path bare, without markdown decoration; its footprint cannot be proved" "an in-flight run with a malformed entry"
refute_text "$script" "owns_entry_problem(entry) is None"

# Ledger row 27: at the Step 5 re-check a lane's own RUN_DIR sits under --runs
# while its plan.md is passed as --lane, and without the exclusion a lane
# always overlaps itself.
footprints --lane issue-1="$fixtures/lane-a.md" --lane issue-7="$fixtures/runs/issue-7/plan.md" --runs "$fixtures/runs"
expect_status 0 "a lane whose own run sits under --runs"
expect_line "$out" "OK: 2 lanes disjoint (checked 0 in-flight runs)" "a lane whose own run sits under --runs"

# Ledger row 34, Codex finding 1 of the second review on PR #141. issue-7 is
# already started, so it is proved on its cached copy, which owns src/b.py
# beside lane-b. Proved on a source plan edited since (lane-a), it passed.
footprints --lane issue-7="$fixtures/runs/issue-7/plan.md" --lane issue-2="$fixtures/lane-b.md" --runs "$fixtures/runs"
expect_status 1 "an already-started lane proved on its cached copy"
expect_line "$err" "check-footprints: overlap: src/b.py — issue-2 owns src/b.py, issue-7 task t7 owns src/b.py" "an already-started lane proved on its cached copy"

# The same lane before its copy has a table: Step 1 derives the footprint from
# the copy's Files: line. Its tableless run dir is the lane itself, so it must
# not also print unchecked:, which would stop the wave on a run already proved.
footprints --lane issue-1="$fixtures/lane-a.md" --lane issue-8="$fixtures/copy-issue-8.md" --runs "$fixtures/runs-tableless"
expect_status 1 "an already-started lane whose copy has no table"
expect_line "$err" "check-footprints: overlap: src/a.py — issue-1 owns src/a.py, issue-8 owns src/a.py" "an already-started lane whose copy has no table"
if grep -Fq "unchecked:" <<<"$err"; then
  echo "a lane's own tableless run dir must not print unchecked:, got: $err" >&2
  exit 1
fi

footprints --lane issue-1="$fixtures/lane-a.md"
expect_status 3 "one lane"

footprints --lane issue-1="$fixtures/lane-a.md" --lane issue-1="$fixtures/lane-b.md"
expect_status 3 "a lane named twice"

footprints --lane issue-1 --lane issue-2="$fixtures/lane-b.md"
expect_status 3 "a malformed --lane"

# An unreadable footprint read as empty text would own nothing and pass.
footprints --lane issue-1="$fixtures/lane-a.md" --lane issue-2="$tmp/does-not-exist.md"
expect_status 3 "an unreadable lane path"

# An unparseable table read as no entries would likewise own nothing.
footprints --lane issue-1="$fixtures/lane-a.md" --lane issue-4="$fixtures/plan-badwaves.md"
expect_status 3 "a lane plan whose ## Waves table will not parse"

footprints --lanes issue-1="$fixtures/lane-a.md"
expect_status 2 "a mistyped flag"

# --- wave-state.py. The Resume table is executable through probe and phase,
# and RESUME_ROWS is the table's copy, so the prose and the script can't drift
# apart without this section failing. ---

wave_state=work-wave/scripts/wave-state.py
require_file "$wave_state"

# The two record lines the probe parses. Lose either from the prose and the
# orchestrator writes records the probe reads as unreadable, so every resume
# stops.
require_text "$skill" "Its first line is \`route: <done|stopped|failed|refused|early-publish|recheck-failed>\`"
require_text "$merge_test" "a \`result: <green|red|conflict>\` line, and VERIFY_CMD's saved tail"

# #359: the baseline's header order is a format work-issue's reuse-baseline reads by position.
require_text "$merge_test" "\`exit: <status>\`, the same \`base:\` line, \`install: <INSTALL_CMD>\`, and \`verify: <VERIFY_CMD>\`"
require_text "$skill" "saved to \`WAVE_DIR/baseline.txt\` with \`exit: <status>\`, the \`base:\` line, \`install: <INSTALL_CMD>\`, and \`verify: <VERIFY_CMD>\` ahead of its tail"
require_text "$skill" "plus \`--wave-baseline <WAVE_DIR>/baseline.txt\`"
require_text "$brief" "    work-issue {{N}} {{PLAN}} --isolate --no-publish --wave-baseline {{WAVE_DIR}}/baseline.txt{{REVIEW_LOOP}}{{POLICY}}"
require_text "$ledger" "| 60 | The no-branch baseline records \`exit:\`, \`base:\`, \`install:\` and \`verify:\` lines, and every build lane is handed it as \`--wave-baseline\`"
require_text "$skill" "Then \`work-wave/scripts/wave-state.py probe --wave-dir WAVE_DIR --root ROOT --default DEFAULT [--pr-bundle FILE]\`"
require_text "$skill" "Exit 1 is a stop: report its reason and every null field the probe's stderr names, and stop the wave."

# The table pin. RESUME_ROWS is copied from SKILL.md, never edited to match
# phase_of, and phase_of answers every row it copies.
python3 - "$skill" "$wave_state" <<'PY' || exit 1
import ast, importlib.util, re, sys
skill, script = sys.argv[1:]
lines = open(skill, encoding="utf-8").read().split("\n")
heads = [i for i, line in enumerate(lines) if line == "| # | Probe | Resume at |"]
if len(heads) != 1:
    sys.exit(f"{skill}: expected one | # | Probe | Resume at | table, found {len(heads)}")
rows = []
for line in lines[heads[0] + 2:]:
    if not line.startswith("|"):
        break
    cells = [c.strip() for c in line.strip()[1:-1].split("|")]
    rows.append((int(cells[0]), cells[1], cells[2]))
spec = importlib.util.spec_from_file_location("wave_state", script)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
if tuple(module.RESUME_ROWS) != tuple(rows):
    for want, got in zip(rows, module.RESUME_ROWS):
        if want != got:
            print(f"RESUME_ROWS differs from {skill} at row {want[0]}:\n  table: {want}\n  copy:  {got}", file=sys.stderr)
            break
    sys.exit(f"RESUME_ROWS must equal {skill}'s Resume table cell for cell ({len(rows)} rows in the table, {len(module.RESUME_ROWS)} in the copy)")
func = next(n for n in ast.parse(open(script, encoding="utf-8").read()).body if isinstance(n, ast.FunctionDef) and n.name == "phase_of")
answered = set()
for node in ast.walk(func):
    if isinstance(node, ast.Return) and isinstance(node.value, ast.Tuple) and len(node.value.elts) == 2:
        reason = node.value.elts[1]
        if isinstance(reason, ast.Constant) and isinstance(reason.value, str):
            match = re.match(r"row ([0-9]+):", reason.value)
            if match:
                answered.add(int(match.group(1)))
missing = [n for n, _, _ in rows if n not in answered]
if missing:
    sys.exit(f"phase_of has no return whose reason starts row <n>: for rows {missing}")
PY

# The cases below call wave-state.py through python3, which hides a missing executable bit the Resume section's direct invocation needs (PR #347 review).
[[ -x work-wave/scripts/wave-state.py ]] || {
  echo "wave-state.py is not executable: work-wave/scripts/wave-state.py" >&2
  exit 1
}

# Runs wave-state.py, capturing stdout, stderr, and the exit code apart.
wave_state() {
  set +e
  python3 "$wave_state" "$@" >"$tmp/out" 2>"$tmp/err"
  status=$?
  set -e
  out="$(cat "$tmp/out")"
  err="$(cat "$tmp/err")"
}

# A full probe: every bool false and every count 0, then the overrides, as
# name=json pairs. `-name` drops a field.
make_probe() {
  local file="$1"
  shift
  python3 - "$wave_state" "$file" "$@" <<'PY'
import importlib.util, json, sys
script, file, *pairs = sys.argv[1:]
spec = importlib.util.spec_from_file_location("wave_state", script)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
probe = {name: False if kind == "bool" else 0 for name, kind, _ in module.PROBE_FIELDS}
for pair in pairs:
    if pair.startswith("-"):
        del probe[pair[1:]]
    else:
        name, value = pair.split("=", 1)
        probe[name] = json.loads(value)
json.dump(probe, open(file, "w"))
PY
}

expect_null() {
  python3 - "$tmp/probe.json" "$1" <<'PY' || exit 1
import json, sys
probe = json.load(open(sys.argv[1]))
if probe[sys.argv[2]] is not None:
    sys.exit(f"{sys.argv[2]} should be null, got {probe[sys.argv[2]]!r}")
PY
}

expect_prefix() {
  local line="$1"
  local what="$2"
  [[ "$out" == "$line"* ]] || {
    echo "$what should print a line starting '$line', got: $out stderr: $err" >&2
    exit 1
  }
}

make_probe "$tmp/probe.json"
wave_state phase --probe "$tmp/probe.json"
expect_status 0 "a probe with no WAVE_DIR"
expect_prefix "phase: 0 reason: row 2:" "a probe with no WAVE_DIR"

through_baseline=(wave_dir=true lanes_md=true harvest_md=true footprint_check=true coupling_md=true order_md=true baseline_test=true)
make_probe "$tmp/probe.json" "${through_baseline[@]}" gate_stops=1
wave_state phase --probe "$tmp/probe.json"
expect_status 1 "a recorded stop"
expect_prefix "phase: stop reason: row 6:" "a recorded stop"

# #361: the re-poll ranks ahead of the re-test, and a null count stops rather
# than reading as 0 and skipping the re-poll.
make_probe "$tmp/probe.json" "${through_baseline[@]}" merge_test_matches=true merge_test_green=true base_current=true heads_moved=true merge_set_size=2 repoll_due=1
wave_state phase --probe "$tmp/probe.json"
expect_status 0 "a re-poll due with a HEAD moved"
expect_prefix "phase: 8 reason: row 10:" "a re-poll due with a HEAD moved"
make_probe "$tmp/probe.json" "${through_baseline[@]}" merge_test_matches=true merge_test_green=true base_current=true heads_moved=true merge_set_size=2 repoll_due=null
wave_state phase --probe "$tmp/probe.json"
expect_status 1 "an unreadable repoll_due"
expect_prefix "phase: stop reason: unknown probe fields: repoll_due" "an unreadable repoll_due"

make_probe "$tmp/probe.json" -heads_moved
wave_state phase --probe "$tmp/probe.json"
expect_status 3 "a probe missing heads_moved"
grep -Fq "heads_moved" <<<"$err" || {
  echo "a probe missing heads_moved should name it on stderr, got: $err" >&2
  exit 1
}

# A null must stop. Row 1's lane count read as 0 would answer done over a
# closed wave whose lanes nobody could count.
make_probe "$tmp/probe.json" wave_closed=true lane_run_dirs_open=null
wave_state phase --probe "$tmp/probe.json"
expect_status 1 "a closed wave with an unreadable lane count"
expect_prefix "phase: stop reason: unknown probe fields: lane_run_dirs_open" "a closed wave with an unreadable lane count"

wave_state phase
expect_status 3 "phase without --probe"

mkdir "$tmp/not-a-repo"
wave_state probe --wave-dir "$tmp/not-a-repo/wave-7-8" --root "$tmp/not-a-repo" --default main
expect_status 3 "probe on a ROOT that isn't a repo"

# A scratch repo with a bare origin, the shape the orchestrator probes.
repo="$tmp/repo"
git init -q -b main "$repo"
git -C "$repo" -c user.name=t -c user.email=t@t -c commit.gpgsign=false commit -q --allow-empty -m init
git clone -q --bare "$repo" "$tmp/origin.git"
git -C "$repo" remote add origin "$tmp/origin.git"
git -C "$repo" fetch -q origin main
wd="$repo/.git/work-wave/wave-7"

wave_state probe --wave-dir "$wd" --root "$repo" --default main
expect_status 0 "probe with no WAVE_DIR"
python3 - "$wave_state" "$tmp/out" <<'PY' || exit 1
import importlib.util, json, sys
spec = importlib.util.spec_from_file_location("wave_state", sys.argv[1])
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
probe = json.load(open(sys.argv[2]))
missing = [name for name, _, _ in module.PROBE_FIELDS if name not in probe]
if missing:
    sys.exit(f"probe printed no {', '.join(missing)}")
if probe["wave_dir"] is not False:
    sys.exit(f"probe with no WAVE_DIR should say wave_dir false, got {probe['wave_dir']!r}")
PY

# Ledger row 43: a gate record without its route: line is unreadable. Read as
# done, it would carry an early publish or a failed re-check on to Step 6.
mkdir -p "$wd/footprint" "$wd/merge-test" "$wd/reports" "$wd/gate"
touch "$wd/lanes.md" "$wd/harvest.md" "$wd/footprint/check.txt" "$wd/merge-test/0.md" "$wd/reports/issue-7-build.json"
printf '| Pair | Answer | Evidence | Resolution |\n|---|---|---|---|\n' >"$wd/coupling.md"
printf '| Order | Lane | After | Why |\n|---|---|---|---|\n| 1 | issue-7 | — | no coupling; number order |\n' >"$wd/order.md"
printf 'footprint re-check: exit 0\n' >"$wd/gate/issue-7.md"
wave_state probe --wave-dir "$wd" --root "$repo" --default main
expect_status 0 "probe over a gate record with no route: line"
cp "$tmp/out" "$tmp/probe.json"
expect_null gate_stops
grep -Fq "gate/issue-7.md" <<<"$err" || {
  echo "a gate record with no route: line should be named on stderr, got: $err" >&2
  exit 1
}
wave_state phase --probe "$tmp/probe.json"
expect_status 1 "phase over a gate record with no route: line"
expect_prefix "phase: stop" "phase over a gate record with no route: line"

# Ledger row 43: a merge-set lane whose branch is missing. Its HEAD can't be
# compared, so whether the merge test matches is unknown rather than no.
printf 'route: done\nfootprint re-check: exit 0\n' >"$wd/gate/issue-7.md"
base_sha="$(git -C "$repo" rev-parse origin/main)"
printf 'base: origin/main %s\nissue-7 %s\nresult: green\n' "$base_sha" "$base_sha" >"$wd/merge-test/1.md"
wave_state probe --wave-dir "$wd" --root "$repo" --default main
expect_status 0 "probe over a merge-set lane with no branch"
cp "$tmp/out" "$tmp/probe.json"
expect_null merge_test_matches
wave_state phase --probe "$tmp/probe.json"
expect_status 1 "phase over a merge-set lane with no branch"
expect_prefix "phase: stop" "phase over a merge-set lane with no branch"

# Ledger row 43's other half: a merge test without its result: line is never
# green. With the branch in place, only the missing line can null the field.
git -C "$repo" branch issue-7
printf 'base: origin/main %s\nissue-7 %s\n' "$base_sha" "$base_sha" >"$wd/merge-test/1.md"
wave_state probe --wave-dir "$wd" --root "$repo" --default main
expect_status 0 "probe over a merge test with no result: line"
cp "$tmp/out" "$tmp/probe.json"
expect_null merge_test_green
grep -Fq "merge-test/1.md" <<<"$err" || {
  echo "a merge test with no result: line should be named on stderr, got: $err" >&2
  exit 1
}
wave_state phase --probe "$tmp/probe.json"
expect_status 1 "phase over a merge test with no result: line"

# And with the line back, the same wave reads as ready to publish, so the
# nulls above came from the missing pieces and nothing else.
printf 'base: origin/main %s\nissue-7 %s\nresult: green\n' "$base_sha" "$base_sha" >"$wd/merge-test/1.md"
printf '{"issue-7": []}\n' >"$tmp/bundle.json"
wave_state probe --wave-dir "$wd" --root "$repo" --default main --pr-bundle "$tmp/bundle.json"
expect_status 0 "probe over a green merge test at the current HEAD"
[[ -z "$err" ]] || {
  echo "probe over a readable wave should print nothing on stderr, got: $err" >&2
  exit 1
}
cp "$tmp/out" "$tmp/probe.json"
wave_state phase --probe "$tmp/probe.json"
expect_status 0 "phase over a green merge test at the current HEAD"
expect_prefix "phase: 7 reason: row 9:" "phase over a green merge test at the current HEAD"

# A note after the result token, and a VERIFY tail that prints `issue-<N> <sha>`,
# must neither null the record nor add a lane to its set. The wave that wrote
# this suite annotated its own record "result: green (only baseline's ... failure)".
printf 'base: origin/main %s\nissue-7 %s\nresult: green (only baseline'"'"'s failure)\nissue-9 %s\n' "$base_sha" "$base_sha" "$base_sha" >"$wd/merge-test/1.md"
wave_state probe --wave-dir "$wd" --root "$repo" --default main --pr-bundle "$tmp/bundle.json"
expect_status 0 "probe over a result line with a trailing note"
[[ -z "$err" ]] || {
  echo "a result line with a trailing note should read cleanly, got: $err" >&2
  exit 1
}
cp "$tmp/out" "$tmp/probe.json"
wave_state phase --probe "$tmp/probe.json"
expect_prefix "phase: 7 reason: row 9:" "phase over a result line with a trailing note"
# The note never rescues an unknown token.
printf 'base: origin/main %s\nissue-7 %s\nresult: greenish (looks fine)\n' "$base_sha" "$base_sha" >"$wd/merge-test/1.md"
wave_state probe --wave-dir "$wd" --root "$repo" --default main --pr-bundle "$tmp/bundle.json"
cp "$tmp/out" "$tmp/probe.json"
expect_null merge_test_green
printf 'base: origin/main %s\nissue-7 %s\nresult: green\n' "$base_sha" "$base_sha" >"$wd/merge-test/1.md"

# PR #347 review: a red re-test at the SHAs and base a green one passed is Step
# 6's stop. A crash before Step 6 stops must not let the older green publish.
printf 'base: origin/main %s\nissue-7 %s\nresult: red\n' "$base_sha" "$base_sha" >"$wd/merge-test/2.md"
wave_state probe --wave-dir "$wd" --root "$repo" --default main --pr-bundle "$tmp/bundle.json"
expect_status 0 "probe over a red record newer than a green one"
cp "$tmp/out" "$tmp/probe.json"
python3 -c 'import json,sys; p=json.load(open(sys.argv[1])); sys.exit(0 if (p["merge_test_matches"], p["merge_test_green"], p["base_current"]) == (True, False, False) else 1)' "$tmp/probe.json" || {
  echo "a red record newer than a green one at the same SHAs should probe matches true, green false, base_current false, got: $(cat "$tmp/probe.json")" >&2
  exit 1
}
wave_state phase --probe "$tmp/probe.json"
expect_prefix "phase: 6 reason: row 8:" "phase over a red record newer than a green one"
rm "$wd/merge-test/2.md"

# PR #347 review: a failed lane and its held successor leave an empty merge set,
# which no publish report or green record can ever satisfy. Step 8's report,
# not the unmatched stop.
wd2="$repo/.git/work-wave/wave-7-8"
mkdir -p "$wd2/footprint" "$wd2/merge-test" "$wd2/reports" "$wd2/gate"
touch "$wd2/lanes.md" "$wd2/harvest.md" "$wd2/footprint/check.txt"
printf '| Pair | Answer | Evidence | Resolution |\n|---|---|---|---|\n' >"$wd2/coupling.md"
printf '| Order | Lane | After | Why |\n|---|---|---|---|\n| 1 | issue-7 | — | no coupling |\n| held | issue-8 | issue-7 | hold: issue-8 until issue-7 merges |\n' >"$wd2/order.md"
printf 'base: origin/main %s\nresult: green\n' "$base_sha" >"$wd2/merge-test/0.md"
printf '{"lane": "issue-7", "status": "failed"}\n' >"$wd2/reports/issue-7-build.json"
printf 'route: failed\nfootprint re-check: exit 0\n' >"$wd2/gate/issue-7.md"
wave_state probe --wave-dir "$wd2" --root "$repo" --default main
cp "$tmp/out" "$tmp/probe.json"
wave_state phase --probe "$tmp/probe.json"
expect_status 0 "phase over an empty merge set"
expect_prefix "phase: 8 reason: row 12:" "phase over an empty merge set"

# PR #347 review: an order.md torn after issue-7's row. Read as complete, issue-8
# had no build or hold and still answered row 12, so it must null and stop.
printf '| Order | Lane | After | Why |\n|---|---|---|---|\n| 1 | issue-7 | — | no coupling |\n' >"$wd2/order.md"
wave_state probe --wave-dir "$wd2" --root "$repo" --default main
cp "$tmp/out" "$tmp/probe.json"
expect_null merge_set_size
expect_null unheld_unreported
grep -Fq "order.md has no row for issue-8" <<<"$err" || {
  echo "an order.md missing issue-8 should say so on stderr, got: $err" >&2
  exit 1
}
wave_state phase --probe "$tmp/probe.json"
expect_status 1 "phase over an order.md missing a lane"
expect_prefix "phase: stop" "phase over an order.md missing a lane"
printf '| Order | Lane | After | Why |\n|---|---|---|---|\n| 1 | issue-7 | — | no coupling |\n| held | issue-8 | issue-7 | hold |\n| 2 | issue-8 | — | again |\n' >"$wd2/order.md"
wave_state probe --wave-dir "$wd2" --root "$repo" --default main
cp "$tmp/out" "$tmp/probe.json"
expect_null merge_set_size
grep -Fq "order.md names issue-8 2 times" <<<"$err" || {
  echo "an order.md naming issue-8 twice should say so on stderr, got: $err" >&2
  exit 1
}
wave_state phase --probe "$tmp/probe.json"
expect_prefix "phase: stop" "phase over an order.md naming a lane twice"
printf '| Order | Lane | After | Why |\n|---|---|---|---|\n| 1 | issue-7 | — | no coupling |\n| held | issue-8 | issue-7 | hold |\n| 2 | issue-9 | — | not this wave |\n' >"$wd2/order.md"
wave_state probe --wave-dir "$wd2" --root "$repo" --default main
cp "$tmp/out" "$tmp/probe.json"
expect_null merge_set_size
grep -Fq "order.md names issue-9, not a lane of wave-7-8" <<<"$err" || {
  echo "an order.md naming a lane outside the wave should say so on stderr, got: $err" >&2
  exit 1
}

# PR #347 review: Step 7 routes a publish report by Step 5's table, so a lane
# that failed publishing leaves the merge set even though its gate said done.
wd3="$repo/.git/work-wave/wave-17-18"
mkdir -p "$wd3/footprint" "$wd3/merge-test" "$wd3/reports" "$wd3/gate"
touch "$wd3/lanes.md" "$wd3/harvest.md" "$wd3/footprint/check.txt"
printf '| Pair | Answer | Evidence | Resolution |\n|---|---|---|---|\n' >"$wd3/coupling.md"
printf '| Order | Lane | After | Why |\n|---|---|---|---|\n| 1 | issue-17 | — | no coupling |\n| 2 | issue-18 | — | no coupling |\n' >"$wd3/order.md"
printf 'base: origin/main %s\nresult: green\n' "$base_sha" >"$wd3/merge-test/0.md"
git -C "$repo" branch issue-17
git -C "$repo" branch issue-18
for n in 17 18; do
  printf '{"lane": "issue-%s", "status": "done"}\n' "$n" >"$wd3/reports/issue-$n-build.json"
  printf 'route: done\nfootprint re-check: exit 0\n' >"$wd3/gate/issue-$n.md"
done
printf 'base: origin/main %s\nissue-17 %s\nissue-18 %s\nresult: green\n' "$base_sha" "$base_sha" "$base_sha" >"$wd3/merge-test/1.md"
printf '{"lane": "issue-17", "status": "done"}\n' >"$wd3/reports/issue-17-publish.json"
printf '{"lane": "issue-18", "status": "failed"}\n' >"$wd3/reports/issue-18-publish.json"
# The newest record still merged issue-18, so Step 8 re-tests over issue-17.
wave_state probe --wave-dir "$wd3" --root "$repo" --default main
cp "$tmp/out" "$tmp/probe.json"
wave_state phase --probe "$tmp/probe.json"
expect_prefix "phase: 8 reason: row 11:" "phase after a lane failed publishing"
printf 'base: origin/main %s\nissue-17 %s\nresult: green\n' "$base_sha" "$base_sha" >"$wd3/merge-test/2.md"
wave_state probe --wave-dir "$wd3" --root "$repo" --default main
cp "$tmp/out" "$tmp/probe.json"
wave_state phase --probe "$tmp/probe.json"
expect_status 0 "phase over a green re-test of the publish survivors"
expect_prefix "phase: 8 reason: row 12:" "phase over a green re-test of the publish survivors"
# A publish report with no status is unknown, never in the set or out of it.
printf '{"lane": "issue-18"}\n' >"$wd3/reports/issue-18-publish.json"
wave_state probe --wave-dir "$wd3" --root "$repo" --default main
cp "$tmp/out" "$tmp/probe.json"
expect_null merge_set_size
wave_state phase --probe "$tmp/probe.json"
expect_status 1 "phase over a publish report with no status"

# PR #347 review: a lane that fails publishing holds the lanes ordered after
# it, as at Step 5. Without the order.md rewrite issue-18 stays in the set and
# Step 8 re-tests it alone, without the lane it waits on.
wd4="$repo/.git/work-wave/wave-18-17"
mkdir -p "$wd4/footprint" "$wd4/merge-test" "$wd4/reports" "$wd4/gate"
touch "$wd4/lanes.md" "$wd4/harvest.md" "$wd4/footprint/check.txt"
printf '| Pair | Answer | Evidence | Resolution |\n|---|---|---|---|\n' >"$wd4/coupling.md"
printf '| Order | Lane | After | Why |\n|---|---|---|---|\n| 1 | issue-17 | — | no coupling |\n| 2 | issue-18 | issue-17 | reads what issue-17 adds |\n' >"$wd4/order.md"
printf 'base: origin/main %s\nresult: green\n' "$base_sha" >"$wd4/merge-test/0.md"
for n in 17 18; do
  printf '{"lane": "issue-%s", "status": "done"}\n' "$n" >"$wd4/reports/issue-$n-build.json"
  printf 'route: done\nfootprint re-check: exit 0\n' >"$wd4/gate/issue-$n.md"
done
printf 'base: origin/main %s\nissue-17 %s\nissue-18 %s\nresult: green\n' "$base_sha" "$base_sha" "$base_sha" >"$wd4/merge-test/1.md"
printf '{"lane": "issue-18", "status": "done"}\n' >"$wd4/reports/issue-18-publish.json"
# Step 7 writes order.md before issue-17's report, so a crash between the two
# merge-tests issue-17 alone and runs Step 7 for it again.
printf '| Order | Lane | After | Why |\n|---|---|---|---|\n| 1 | issue-17 | — | no coupling |\n| held | issue-18 | issue-17 | issue-17 failed publishing |\n' >"$wd4/order.md"
wave_state probe --wave-dir "$wd4" --root "$repo" --default main
cp "$tmp/out" "$tmp/probe.json"
wave_state phase --probe "$tmp/probe.json"
expect_prefix "phase: 6 reason: row 8:" "phase with a successor held and the failed lane unreported"
printf '{"lane": "issue-17", "status": "failed"}\n' >"$wd4/reports/issue-17-publish.json"
wave_state probe --wave-dir "$wd4" --root "$repo" --default main
cp "$tmp/out" "$tmp/probe.json"
python3 - "$tmp/probe.json" <<'PY' || exit 1
import json, sys
probe = json.load(open(sys.argv[1]))
if probe["merge_set_size"] != 0 or probe["heads_moved"] is not False:
    sys.exit(f"a failed lane and its held successor should leave an empty set, got merge_set_size={probe['merge_set_size']!r} heads_moved={probe['heads_moved']!r}")
PY
wave_state phase --probe "$tmp/probe.json"
expect_status 0 "phase after a lane failed publishing and its successor was held"
expect_prefix "phase: 8 reason: row 12:" "phase after a lane failed publishing and its successor was held"

# #361: a merge-set lane whose open RUN_DIR holds triage/waiting and that has no
# WAVE_DIR/repoll/issue-<N> is re-polled once. The rule keys on the file, never on
# the publish report's status.
wd5="$repo/.git/work-wave/wave-27-28"
mkdir -p "$wd5/footprint" "$wd5/merge-test" "$wd5/reports" "$wd5/gate"
touch "$wd5/lanes.md" "$wd5/harvest.md" "$wd5/footprint/check.txt"
printf '| Pair | Answer | Evidence | Resolution |\n|---|---|---|---|\n' >"$wd5/coupling.md"
printf '| Order | Lane | After | Why |\n|---|---|---|---|\n| 1 | issue-27 | — | no coupling |\n| 2 | issue-28 | — | no coupling |\n' >"$wd5/order.md"
printf 'base: origin/main %s\nresult: green\n' "$base_sha" >"$wd5/merge-test/0.md"
git -C "$repo" branch issue-27
git -C "$repo" branch issue-28
for n in 27 28; do
  printf '{"lane": "issue-%s", "status": "done"}\n' "$n" >"$wd5/reports/issue-$n-build.json"
  printf 'route: done\nfootprint re-check: exit 0\n' >"$wd5/gate/issue-$n.md"
done
printf 'base: origin/main %s\nissue-27 %s\nissue-28 %s\nresult: green\n' "$base_sha" "$base_sha" "$base_sha" >"$wd5/merge-test/1.md"
printf '{"status": "done"}\n' >"$wd5/reports/issue-27-publish.json"
printf '{"status": "stopped"}\n' >"$wd5/reports/issue-28-publish.json"
mkdir -p "$repo/.git/work-issue/issue-28/triage"
touch "$repo/.git/work-issue/issue-28/triage/waiting"

# CASE WANT_REPOLL_DUE. Probes wd5 and checks repoll_due; the caller checks phase.
probe_repoll() {
  wave_state probe --wave-dir "$wd5" --root "$repo" --default main
  cp "$tmp/out" "$tmp/probe.json"
  python3 -c 'import json,sys; sys.exit(0 if json.load(open(sys.argv[1]))["repoll_due"] == int(sys.argv[2]) else 1)' "$tmp/probe.json" "$2" || {
    echo "$1 should probe repoll_due $2, got: $(cat "$tmp/probe.json") stderr: $err" >&2
    exit 1
  }
  wave_state phase --probe "$tmp/probe.json"
}
probe_repoll "case A, waiting with no record" 1
expect_prefix "phase: 8 reason: row 10:" "case A, waiting with no record"
mkdir -p "$wd5/repoll"
printf 'dispatched: 2026-11-18T00:00:00Z\n' >"$wd5/repoll/issue-28"
probe_repoll "case B, waiting with the record" 0
expect_prefix "phase: 8 reason: row 12:" "case B, waiting with the record"
# A lane stopped for a question has no triage/waiting, so it leaves the merge set,
# isn't re-polled, and row 11 re-tests without it.
rm "$wd5/repoll/issue-28" "$repo/.git/work-issue/issue-28/triage/waiting"
probe_repoll "case C, stopped with no triage/waiting" 0
[[ "$out" != "phase: 8 reason: row 10:"* ]] || {
  echo "case C, stopped with no triage/waiting, should not re-poll, got: $out" >&2
  exit 1
}
expect_prefix "phase: 8 reason: row 11:" "case C, stopped with no triage/waiting"
printf '{"status": "done"}\n' >"$wd5/reports/issue-28-publish.json"
probe_repoll "case D, done with no triage/waiting" 0
expect_prefix "phase: 8 reason: row 12:" "case D, done with no triage/waiting"
# A closed RUN_DIR still counts as done for the merge set (ledger row 55), but
# work-issue N can't resume a finished run, so the lane isn't re-polled.
printf '{"status": "stopped"}\n' >"$wd5/reports/issue-28-publish.json"
rm -r "$repo/.git/work-issue/issue-28"
mkdir -p "$repo/.git/work-issue/closed/issue-28/triage"
touch "$repo/.git/work-issue/closed/issue-28/triage/waiting"
probe_repoll "case E, triage/waiting only under closed/" 0
expect_prefix "phase: 8 reason: row 12:" "case E, triage/waiting only under closed/"

printf '{"issue-7": "not a list"}\n' >"$tmp/bundle.json"
wave_state probe --wave-dir "$wd" --root "$repo" --default main --pr-bundle "$tmp/bundle.json"
expect_status 3 "probe with a malformed --pr-bundle"

wave_state probe --wave-dir "$wd" --root "$repo"
expect_status 3 "probe without --default"

# --- resume_checks.py, vendored. The checker replays the wave's write order
# against wave-state.py, and it's a byte-for-byte copy of work-issue's, so a fix
# made here alone would be lost at the next re-copy. ---

checks=work-wave/scripts/resume_checks.py
wave_model=work-wave/scripts/wave-order.json
require_file "$checks"
require_file "$wave_model"
require_text "$checks" "fix a bug there first, then re-copy"
cmp work-issue/scripts/resume_checks.py "$checks" || {
  echo "$checks has drifted from work-issue/scripts/resume_checks.py; fix the upstream, then cp it across" >&2
  exit 1
}

# Runs the vendored checker, capturing stdout, stderr, and the exit code apart.
resume_checks() {
  set +e
  python3 "$checks" "$@" >"$tmp/out" 2>"$tmp/err"
  status=$?
  set -e
  out="$(cat "$tmp/out")"
  err="$(cat "$tmp/err")"
}

# Vectors multiply per lane, and the 2-3 lane bound keeps `crash-points` to tens of seconds.
# A one-lane block is a model typo, so it exits 3 before any replay.
python3 - "$wave_model" "$tmp/one-lane.json" <<'PY'
import json, sys
model = json.load(open(sys.argv[1]))
seq = model["sequences"][0]
block = next(e for e in seq["entries"] if "interleave" in e)
block["interleave"] = block["interleave"][:1]
json.dump(model, open(sys.argv[2], "w"))
PY
resume_checks crash-points --model "$tmp/one-lane.json"
expect_status 3 "crash-points over a one-lane interleave block"
grep -Eq "^resume_checks: sequence main#[0-9]+: interleave needs 2 or 3 lane lists, got 1$" <<<"$err" || {
  echo "a one-lane block should be named on stderr, got: $err" >&2
  exit 1
}

# --- The three checks over the whole wave model. Each hole they found in the
# Resume table (ledger rows 48-50) is a sequence or an invariant here, so a
# table edit that reopens one fails this section. ---

# CHECKS SUBCOMMAND MODEL OUT, the shape tests/work-issue-smoke.sh uses. No
# subshell body, so the trap's `pkill -P` reaches python itself.
logic_run() {
  local status=0
  python3 "$1" "$2" --model "$3" >"$4.out" 2>"$4.err" || status=$?
  echo "$status" >"$4.status"
}
logic_run "$checks" liveness "$wave_model" "$tmp/live" &
# A check failing before the `wait` would leave liveness running past the
# suite's exit. Each kill carries `|| true` because `set -e` holds in a trap.
trap 'for job in $(jobs -p); do pkill -P "$job" || true; kill "$job" 2>/dev/null || true; done; rm -rf "$tmp"' EXIT

logic_run "$checks" invariants "$wave_model" "$tmp/inv"
[[ "$(cat "$tmp/inv.status")" == "0" ]] && [[ ! -s "$tmp/inv.err" ]] \
  && [[ "$(tail -n 1 "$tmp/inv.out")" =~ ^probes:\ [0-9]+\ leaves,\ [0-9]+\ pruned$ ]] || {
  echo "invariants over wave-order.json should exit 0 with only a probes: line, got $(cat "$tmp/inv.status"):" >&2
  cat "$tmp/inv.out" "$tmp/inv.err" >&2
  exit 1
}

resume_checks crash-points --model "$wave_model"
expect_status 0 "crash-points over wave-order.json"
[[ "$(tail -n 1 "$tmp/out")" == "rows covered: 1 2 3 4 5 6 7 8 9 10 11 12" ]] || {
  echo "crash-points over wave-order.json should cover rows 1-12, got: $out stderr: $err" >&2
  exit 1
}

# --- The four PR #141 holes as falsifiers (ledger row 51). Each copies work-wave/
# outside any repo, rewrites the copy's wave-state.py with ast to reintroduce
# one hole, and expects the matching check to fail with the stated line. A
# rewrite that matched nothing exits 2 here, because a falsifier that changed
# nothing would leave the check passing for the wrong reason. ---

cat >"$tmp/rewrite.py" <<'PY'
import ast, sys

kind, path = sys.argv[1], sys.argv[2]
src = open(path).read()
tree = ast.parse(src)
hits = 0


def is_call(node, fn, field):
    return (
        isinstance(node, ast.Call)
        and isinstance(node.func, ast.Name)
        and node.func.id == fn
        and len(node.args) == 2
        and isinstance(node.args[1], ast.Constant)
        and node.args[1].value == field
    )


class Swap(ast.NodeTransformer):
    def __init__(self, fn, field, value):
        self.fn, self.field, self.value = fn, field, value

    def visit_FunctionDef(self, node):
        if node.name != "phase_of":
            return node
        return self.generic_visit(node)

    def visit_Call(self, node):
        global hits
        if is_call(node, self.fn, self.field):
            hits += 1
            return ast.copy_location(ast.Constant(self.value), node)
        return self.generic_visit(node)


# Module level only: the Wave class has a merge_set method that delegates to it.
def all_lanes(module):
    global hits
    for node in module.body:
        if isinstance(node, ast.FunctionDef) and node.name == "merge_set":
            for stmt in ast.walk(node):
                if isinstance(stmt, ast.Return):
                    stmt.value = ast.parse("[lane for order, lane in order_rows]", mode="eval").body
                    hits += 1
    return module


# Wave.repoll_due's `not self.has(...)` becomes `not False`, so the record never
# stops a second re-poll (#361).
def ignore_repoll_record(module):
    global hits
    for cls in module.body:
        if isinstance(cls, ast.ClassDef) and cls.name == "Wave":
            for fn in cls.body:
                if isinstance(fn, ast.FunctionDef) and fn.name == "repoll_due":
                    for node in ast.walk(fn):
                        if (
                            isinstance(node, ast.UnaryOp)
                            and isinstance(node.op, ast.Not)
                            and isinstance(node.operand, ast.Call)
                            and isinstance(node.operand.func, ast.Attribute)
                            and node.operand.func.attr == "has"
                        ):
                            node.operand = ast.Constant(False)
                            hits += 1
    return module


if kind == "ignore-ungated":
    tree = Swap("count", "build_ungated", 0).visit(tree)
elif kind == "ignore-stop":
    tree = Swap("count", "gate_stops", 0).visit(tree)
elif kind == "ignore-harvest":
    tree = Swap("flag", "harvest_md", True).visit(tree)
elif kind == "merge-set-all-lanes":
    tree = all_lanes(tree)
elif kind == "ignore-repoll-record":
    tree = ignore_repoll_record(tree)
else:
    sys.exit(f"unknown falsifier {kind}")
if hits == 0:
    print(f"falsifier {kind}: the ast rewrite matched nothing", file=sys.stderr)
    sys.exit(2)
open(path, "w").write(ast.unparse(ast.fix_missing_locations(tree)) + "\n")
PY

# The merge-set falsifier needs a model holding main and out-of-set only, so
# crash-points names the one sequence a held-and-failed lane breaks.
python3 - "$wave_model" "$tmp/two-seq.json" <<'PY'
import json, sys
model = json.load(open(sys.argv[1]))
model["sequences"] = [q for q in model["sequences"] if q["name"] in ("main", "out-of-set")]
assert len(model["sequences"]) == 2
json.dump(model, open(sys.argv[2], "w"))
PY
# The re-poll falsifier likewise needs only main and publish-waiting.
python3 - "$wave_model" "$tmp/waiting-seq.json" <<'PY'
import json, sys
model = json.load(open(sys.argv[1]))
model["sequences"] = [q for q in model["sequences"] if q["name"] in ("main", "publish-waiting")]
assert len(model["sequences"]) == 2
json.dump(model, open(sys.argv[2], "w"))
PY

# NAME CHECK MODEL. Leaves NAME.{out,err,status,cmp} in $tmp.
falsifier() {
  local name="$1" check="$2" model="$3" copy="$tmp/fals-$1" status=0
  mkdir -p "$copy"
  cp -R work-wave "$copy/work-wave"
  cp "$model" "$copy/work-wave/scripts/model.json"
  cp "$copy/work-wave/scripts/wave-state.py" "$copy/before.py"
  python3 "$tmp/rewrite.py" "$name" "$copy/work-wave/scripts/wave-state.py" >"$copy.rewrite" 2>&1 || status=$?
  if [[ "$status" != 0 ]]; then
    echo "$status" >"$copy.status"
    cp "$copy.rewrite" "$copy.err"
    : >"$copy.out"
    return 0
  fi
  if cmp -s "$copy/before.py" "$copy/work-wave/scripts/wave-state.py"; then
    echo 98 >"$copy.status"
    echo "falsifier $name left wave-state.py byte-identical" >"$copy.err"
    : >"$copy.out"
    return 0
  fi
  python3 "$copy/work-wave/scripts/resume_checks.py" "$check" --model "$copy/work-wave/scripts/model.json" >"$copy.out" 2>"$copy.err" || status=$?
  echo "$status" >"$copy.status"
}

falsifier ignore-ungated invariants "$wave_model" &
falsifier ignore-stop invariants "$wave_model" &
falsifier ignore-harvest invariants "$wave_model" &
falsifier merge-set-all-lanes crash-points "$tmp/two-seq.json" &
falsifier ignore-repoll-record crash-points "$tmp/waiting-seq.json" &

# Subpaths pin: the WAVE_DIR bullet and the model's subpath labels name the same
# artifacts, so a write the skill documents can't go unmodeled and a modeled
# write can't go undocumented. Placeholders match anything; the world-side
# names label edits the probe can see but WAVE_DIR doesn't hold.
cat >"$tmp/subpaths.py" <<'PY'
import json, re, sys

skill, model_path = sys.argv[1], sys.argv[2]
WORLD = {"branch", "commit", "origin", "lane-run-dir", "closed"}
bullet = next(l for l in open(skill).read().split("\n") if l.startswith("- **WAVE_DIR**"))
listed = re.findall(r"`([^`]+)`", bullet.split("Subpaths:")[1].split("A finished wave")[0])
problems = []
if len(listed) < 11:
    problems.append(f"the WAVE_DIR bullet lists {len(listed)} subpaths, expected at least 11")


def pattern(sub):
    return re.compile("".join(".+" if part.startswith("<") else re.escape(part) for part in re.split(r"(<[^>]+>)", sub)))


model = json.load(open(model_path))
entries = []


def walk(es):
    for e in es:
        if "interleave" in e:
            for lane in e["interleave"]:
                walk(lane)
        else:
            entries.append(e)


for seq in model["sequences"]:
    walk(seq.get("setup", []))
    walk(seq["entries"])
labels = {e["subpath"] for e in entries}
for sub in listed:
    if not any(pattern(sub).fullmatch(l) for l in labels):
        problems.append(f"WAVE_DIR lists {sub} but no model entry writes it")
for l in sorted(labels - WORLD):
    if not any(pattern(sub).fullmatch(l) for sub in listed):
        problems.append(f"the model writes {l} but the WAVE_DIR bullet does not list it")
for e in entries:
    if "blind" in e and not str(e["blind"]).strip():
        problems.append(f"entry {e['subpath']} is blind with no reason")
for p in problems:
    print(p, file=sys.stderr)
sys.exit(1 if problems else 0)
PY
python3 "$tmp/subpaths.py" "$skill" "$wave_model" || {
  echo "the WAVE_DIR subpaths and wave-order.json disagree" >&2
  exit 1
}
# The pin must bite: with every harvest.md entry gone, it fails naming harvest.md.
python3 - "$wave_model" "$tmp/no-harvest.json" <<'PY'
import json, sys
model = json.load(open(sys.argv[1]))
def strip(es):
    out = []
    for e in es:
        if "interleave" in e:
            e["interleave"] = [strip(l) for l in e["interleave"]]
        elif e.get("subpath") == "harvest.md":
            continue
        out.append(e)
    return out
for seq in model["sequences"]:
    seq["entries"] = strip(seq["entries"])
    if "setup" in seq:
        seq["setup"] = strip(seq["setup"])
json.dump(model, open(sys.argv[2], "w"))
PY
if python3 "$tmp/subpaths.py" "$skill" "$tmp/no-harvest.json" 2>"$tmp/pin.err"; then
  echo "the subpaths pin passed over a model with no harvest.md entry" >&2
  exit 1
fi
grep -Fq "WAVE_DIR lists harvest.md but no model entry writes it" "$tmp/pin.err" || {
  echo "the subpaths pin should name harvest.md, got: $(cat "$tmp/pin.err")" >&2
  exit 1
}

wait

# Each falsifier must fail its check with the stated line, never exit 2 or 98,
# which mean the rewrite matched nothing or changed nothing.
expect_falsified() {
  local name="$1" stream="$2" pattern="$3"
  [[ "$(cat "$tmp/fals-$name.status")" == "1" ]] || {
    echo "falsifier $name should make its check exit 1, got $(cat "$tmp/fals-$name.status"):" >&2
    cat "$tmp/fals-$name.out" "$tmp/fals-$name.err" >&2
    exit 1
  }
  grep -Eq -- "$pattern" "$tmp/fals-$name.$stream" || {
    echo "falsifier $name should print a line matching $pattern on $stream, got:" >&2
    cat "$tmp/fals-$name.out" "$tmp/fals-$name.err" >&2
    exit 1
  }
}
expect_falsified ignore-ungated err '^step-6-needs-every-report-gated: 6 row 8 on'
expect_falsified ignore-stop err '^step-6-never-past-a-recorded-stop: 6 row 8 on'
expect_falsified ignore-harvest err '^step-1-needs-harvest: 1 row 3 on'
expect_falsified merge-set-all-lanes out '^out-of-set#[0-9@.]+[^:]*: expected 7 row 9, got 6 row 8'
expect_falsified ignore-repoll-record out '^publish-waiting#[0-9]+ end: expected 8 row 12, got 8 row 10'

[[ "$(cat "$tmp/live.status")" == "0" ]] && [[ ! -s "$tmp/live.err" ]] \
  && [[ "$(tail -n 1 "$tmp/live.out")" =~ ^paths:\ [0-9]+$ ]] || {
  echo "liveness over wave-order.json should exit 0 with only a paths: line, got $(cat "$tmp/live.status"):" >&2
  cat "$tmp/live.out" "$tmp/live.err" >&2
  exit 1
}

# --- merge-test.py (#383). The runner is merge-test.md's procedure as a script,
# so every check below reads what git and the record say, never the script's own
# arithmetic. ---

runner=work-wave/scripts/merge-test.py
require_file "$runner"
require_text "$runner" "TAIL_LINES = 200"
require_text "$skill" "as one background call to \`scripts/merge-test.py --baseline\`"
require_text "$skill" "triggers a merge test now over every lane branch that has commits, returned or not, as one \`scripts/merge-test.py\` call with a \`--lane\` per branch"
require_text "$skill" "as one \`scripts/merge-test.py\` call with a \`--lane\` per branch, which does one"
require_text "$skill" "as one \`scripts/merge-test.py\` call over the merge set"
require_text "$skill" "- [scripts/merge-test.py](scripts/merge-test.py) — run at Steps 4, 5, 6, and 8"
require_text "$merge_test" "\`scripts/merge-test.py\` runs the Procedure below in one call"
require_text "$merge_test" "Exit 3 on usage or a git failure before any merge, with nothing written under \`merge-test/\`."
require_text "$merge_test" "a \`git failed: <command>\` line"
require_text "$merge_test" "a \`merge failed: issue-N\` line"
require_text "$merge_test" "It keeps the last 200 lines of the suite's output as the tail."
require_text "$merge_test" "VERIFY_CMD's whole run blocks the call"
# stdlib only: any import outside this set is a dependency the skill can't carry.
python3 - "$runner" <<'PY' || exit 1
import ast, sys
allowed = set(sys.stdlib_module_names)
bad = [n for node in ast.walk(ast.parse(open(sys.argv[1]).read()))
       for n in ([a.name for a in node.names] if isinstance(node, ast.Import)
                 else [node.module] if isinstance(node, ast.ImportFrom) else [])
       if n.split(".")[0] not in allowed]
sys.exit(f"merge-test.py imports outside the stdlib: {bad}" if bad else 0)
PY

export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
mt="$tmp/mt"
mkdir -p "$mt"
mrepo="$mt/repo"
git init -q -b main "$mrepo"
printf 'x0\n' >"$mrepo/x"
printf 'y0\n' >"$mrepo/y"
printf 'z0\n' >"$mrepo/z"
git -C "$mrepo" add -A
git -C "$mrepo" -c commit.gpgsign=false commit -q -m init
git clone -q --bare "$mrepo" "$mt/origin.git"
git -C "$mrepo" remote add origin "$mt/origin.git"
git -C "$mrepo" fetch -q origin main
mk_branch() { # name file content
  git -C "$mrepo" checkout -q -b "$1" main
  printf '%s\n' "$3" >"$mrepo/$2"
  git -C "$mrepo" -c commit.gpgsign=false commit -q -am "$1"
  git -C "$mrepo" checkout -q main
}
mk_branch issue-1 x "x from A"
mk_branch issue-2 y "y from B"
mk_branch issue-3 x "x from C"
mk_branch issue-4 z "z from D"
mk_branch issue-5 z "z from A2"
mkdir -p "$mt/wave-7"

mtree="$mt/merge-tree"
merge_test() { # args after the fixed ones: VERIFY_CMD then lanes/flags
  local verify="$1"; shift
  python3 "$runner" --wave-dir "$mt/wave-7" --root "$mrepo" --default main \
    --merge-tree "$mtree" --install absent --verify "$verify" "$@" >"$mt/out" 2>"$mt/err"
}
expect_gone() { # the merge tree is neither registered nor on disk
  [[ ! -e "$mtree" ]] || { echo "$1: MERGE_TREE still exists" >&2; exit 1; }
  ! git -C "$mrepo" worktree list --porcelain | grep -Fq "$mtree" || {
    echo "$1: MERGE_TREE still in worktree list" >&2; exit 1; }
}
expect_record() { # description, pattern
  grep -Eq -- "$3" "$2" || { echo "$1: record lacks $3:" >&2; cat "$2" >&2; exit 1; }
}

# Green: record k=1, lanes in order, result line, probe-readable, tree gone.
merge_test 'echo suite ok' --lane issue-1 --lane issue-2
rec="$(cat "$mt/out")"
[[ "$rec" == "$mt/wave-7/merge-test/1.md" ]] || { echo "green run should print merge-test/1.md, got $rec" >&2; exit 1; }
expect_record "green run" "$rec" '^base: origin/main [0-9a-f]{40}$'
expect_record "green run" "$rec" '^issue-1 [0-9a-f]{40}$'
expect_record "green run" "$rec" '^issue-2 [0-9a-f]{40}$'
expect_record "green run" "$rec" '^result: green$'
expect_gone "green run"

# VERIFY_CMD exits non-zero: red record, exit 1, tree gone.
set +e; merge_test 'echo boom; exit 4' --lane issue-1; st=$?; set -e
[[ $st -eq 1 ]] || { echo "a red suite should exit 1, got $st" >&2; exit 1; }
rec="$(cat "$mt/out")"
[[ "$rec" == "$mt/wave-7/merge-test/2.md" ]] || { echo "k should be one past the highest record, got $rec" >&2; exit 1; }
expect_record "red run" "$rec" '^result: red$'
expect_record "red run" "$rec" '^boom$'
expect_gone "red run"

# The rule (row 35): A and C both change x, B only y. C conflicts with A across
# B, and B, the branch merged just before C, is never named.
set +e; merge_test 'echo never' --lane issue-1 --lane issue-2 --lane issue-3; st=$?; set -e
[[ $st -eq 1 ]] || { echo "a conflict should exit 1, got $st" >&2; exit 1; }
rec="$(cat "$mt/out")"
expect_record "conflict run" "$rec" '^conflict: issue-3 with issue-1 — x$'
expect_record "conflict run" "$rec" '^result: conflict$'
! grep -Eq '^conflict:.*issue-2' "$rec" || { echo "the conflict line names the neighbor issue-2" >&2; exit 1; }
expect_gone "conflict run"

# A VERIFY_CMD that leaves an untracked, non-ignored file is red and names it.
set +e; merge_test 'touch stray.txt' --lane issue-2; st=$?; set -e
[[ $st -eq 1 ]] || { echo "a dirty tree should exit 1, got $st" >&2; exit 1; }
rec="$(cat "$mt/out")"
expect_record "dirty run" "$rec" '^dirty after verify: untracked — stray.txt$'
expect_record "dirty run" "$rec" '^result: red$'
expect_gone "dirty run"

# A tracked file the suite changed is the other half of the dirty check.
set +e; merge_test 'echo more >>y' --lane issue-2; st=$?; set -e
[[ $st -eq 1 ]] || { echo "a tracked change should exit 1, got $st" >&2; exit 1; }
expect_record "tracked dirty run" "$(cat "$mt/out")" '^dirty after verify: tracked changes — y$'

# A lane with no branch exits 3, writes no record, and leaves nothing behind.
before="$(ls "$mt/wave-7/merge-test" | wc -l)"
set +e; merge_test 'echo ok' --lane issue-2 --lane issue-99; st=$?; set -e
[[ $st -eq 3 ]] || { echo "a --lane with no branch should exit 3, got $st" >&2; exit 1; }
[[ "$(ls "$mt/wave-7/merge-test" | wc -l)" == "$before" ]] || { echo "exit 3 wrote a record" >&2; exit 1; }
expect_gone "unknown lane"
set +e; merge_test 'echo ok' --baseline --lane issue-2; st=$?; set -e
[[ $st -eq 3 ]] || { echo "--baseline with --lane should exit 3, got $st" >&2; exit 1; }

# The probe reads every record the runner wrote. A tail that prints
# `result: green` and `issue-7 <sha>` after a red run still probes false.
tailverify='echo "result: green"; echo "issue-7 $(git rev-parse HEAD)"; exit 1'
rm -rf "$mt/wave-7/merge-test"
git -C "$mrepo" branch -q -f issue-7 issue-2
set +e
python3 "$runner" --wave-dir "$mt/wave-7" --root "$mrepo" --default main --merge-tree "$mtree" \
  --install absent --verify "$tailverify" --lane issue-7 >"$mt/out" 2>"$mt/err"
st=$?
set -e
[[ $st -eq 1 ]] || { echo "a red run with a lying tail should exit 1, got $st" >&2; exit 1; }
printf '| Pair | Answer | Evidence | Resolution |\n|---|---|---|---|\n' >"$mt/wave-7/coupling.md"
printf '| Order | Lane | After | Why |\n|---|---|---|---|\n| 1 | issue-7 | — | no coupling; number order |\n' >"$mt/wave-7/order.md"
python3 "$wave_state" probe --wave-dir "$mt/wave-7" --root "$mrepo" --default main >"$mt/probe.json" 2>"$mt/perr"
python3 - "$mt/probe.json" <<'PY' || { cat "$mt/perr" >&2; exit 1; }
import json, sys
p = json.load(open(sys.argv[1]))
if p["merge_test_green"] is not False:
    sys.exit(f"a red record whose tail prints result: green should probe merge_test_green false, got {p['merge_test_green']!r}")
PY
python3 "$runner" --wave-dir "$mt/wave-7" --root "$mrepo" --default main --merge-tree "$mtree" \
  --install absent --verify 'echo ok' --lane issue-7 >"$mt/out" 2>"$mt/err"
python3 "$wave_state" probe --wave-dir "$mt/wave-7" --root "$mrepo" --default main >"$mt/probe.json" 2>"$mt/perr"
python3 - "$mt/probe.json" <<'PY' || { cat "$mt/perr" >&2; exit 1; }
import json, sys
p = json.load(open(sys.argv[1]))
if p["merge_test_green"] is not True:
    sys.exit(f"the runner's green record should probe merge_test_green true, got {p['merge_test_green']!r}")
PY

# --baseline: the four header lines in order, then run-state accepts it.
rm -rf "$mt/wave-7/merge-test"
python3 "$runner" --wave-dir "$mt/wave-7" --root "$mrepo" --default main --merge-tree "$mtree" \
  --install absent --verify 'echo base ok' --baseline >"$mt/out" 2>"$mt/err"
[[ "$(cat "$mt/out")" == "$mt/wave-7/merge-test/0.md" ]] || { echo "--baseline should write merge-test/0.md" >&2; exit 1; }
header="$(head -n 4 "$mt/wave-7/baseline.txt" | cut -d: -f1 | tr '\n' ' ')"
[[ "$header" == "exit base install verify " ]] || { echo "baseline.txt header should be exit/base/install/verify, got: $header" >&2; exit 1; }
bsha="$(sed -n 's/^base: origin\/main //p' "$mt/wave-7/baseline.txt")"
mkdir -p "$mt/run"
python3 work-issue/scripts/run-state.py reuse-baseline --wave-baseline "$mt/wave-7/baseline.txt" \
  --base-sha "$bsha" --install absent --verify 'echo base ok' --out "$mt/run/baseline.txt" >"$mt/out" 2>"$mt/err" || {
  echo "run-state reuse-baseline should accept the runner's baseline.txt:" >&2; cat "$mt/err" >&2; exit 1; }
expect_gone "baseline run"

# Falsifier: a runner that blames the branch merged just before must fail the
# A/B/C case above. Cut loose from the repo's git before the copy runs anything.
fals="$mt/fals"
mkdir -p "$fals"
python3 - "$runner" "$fals/merge-test.py" <<'PY'
import sys
s = open(sys.argv[1]).read()
old = "        if theirs & set(conflicted):\n"
assert old in s, "falsifier matched nothing"
open(sys.argv[2], "w").write(s.replace(old, "        if other == merged[-1]:\n"))
PY
rm -rf "$mt/wave-7/merge-test"
set +e
python3 "$fals/merge-test.py" --wave-dir "$mt/wave-7" --root "$mrepo" --default main --merge-tree "$mtree" \
  --install absent --verify 'echo never' --lane issue-1 --lane issue-2 --lane issue-3 >"$mt/out" 2>"$mt/err"
set -e
! grep -Fxq 'conflict: issue-3 with issue-1 — x' "$(cat "$mt/out")" || {
  echo "falsifier: blaming the branch merged just before should break the A/B/C case" >&2; exit 1; }
grep -Fxq 'conflict: issue-3 with issue-2 — x' "$(cat "$mt/out")" || {
  echo "falsifier: the neighbor-blaming copy should name issue-2" >&2; exit 1; }
git -C "$mrepo" worktree prune

# Perturb what the rule keys on, the other way: with A touching z, C meets no
# merged branch and nothing conflicts at all. issue-5 stands in for that A.
set +e; merge_test 'echo ok' --lane issue-5 --lane issue-2 --lane issue-3; st=$?; set -e
[[ $st -eq 0 ]] || { echo "A(z), B(y), C(x) should merge clean and exit 0, got $st" >&2; exit 1; }
! grep -q '^conflict:' "$(cat "$mt/out")" || { echo "A(z), B(y), C(x) should record no conflict" >&2; exit 1; }
expect_gone "A(z) perturbation"

# A merge that fails with no unmerged path (a hook here) is red with its own
# line, never a conflict that sends the conductor hunting for overlapping paths.
printf '#!/bin/sh\necho refused >&2\nexit 1\n' >"$mrepo/.git/hooks/pre-merge-commit"
chmod +x "$mrepo/.git/hooks/pre-merge-commit"
set +e; merge_test 'echo never' --lane issue-2; st=$?; set -e
rm -f "$mrepo/.git/hooks/pre-merge-commit"
[[ $st -eq 1 ]] || { echo "a failed merge with no conflict should exit 1, got $st" >&2; exit 1; }
rec="$(cat "$mt/out")"
expect_record "merge failed" "$rec" '^merge failed: issue-2$'
expect_record "merge failed" "$rec" '^result: red$'
! grep -q '^conflict:' "$rec" || { echo "a hook refusal should not record a conflict" >&2; exit 1; }
expect_gone "merge failed"

# A git failure after merging has started is a red record, never exit 3, which
# is reserved for failures before any merge. VERIFY_CMD breaks the tree's .git.
set +e; merge_test 'rm .git' --lane issue-2; st=$?; set -e
rec="$(cat "$mt/out")"
[[ -n "$rec" && -f "$rec" ]] || { echo "a git failure after the first merge should write a record, got none" >&2; exit 1; }
[[ $st -eq 1 ]] || { echo "a git failure after the first merge should exit 1, got $st" >&2; exit 1; }
expect_record "git failed" "$rec" '^git failed: git '
expect_record "git failed" "$rec" '^result: red$'
expect_gone "git failed"

# A baseline red only because the suite dirtied the tree writes a non-zero
# exit:, since reuse-baseline copies that line to each lane and divvy-up reads it.
python3 "$runner" --wave-dir "$mt/wave-7" --root "$mrepo" --default main --merge-tree "$mtree" \
  --install absent --verify 'touch stray.txt' --baseline >"$mt/out" 2>"$mt/err" && {
  echo "a dirty baseline should exit 1" >&2; exit 1; }
[[ "$(head -n 1 "$mt/wave-7/baseline.txt")" == "exit: 1" ]] || {
  echo "a dirty baseline should write exit: 1, got: $(head -n 1 "$mt/wave-7/baseline.txt")" >&2; exit 1; }
expect_record "dirty baseline" "$mt/wave-7/merge-test/0.md" '^result: red$'

# SIGTERM mid-suite still removes MERGE_TREE. SIGKILL can't be trapped and is
# not covered.
python3 "$runner" --wave-dir "$mt/wave-7" --root "$mrepo" --default main --merge-tree "$mtree" \
  --install absent --verify 'sleep 30' --lane issue-2 >/dev/null 2>&1 &
runner_pid=$!
for _ in $(seq 100); do [[ -e "$mtree/.git" ]] && break; sleep 0.1; done
[[ -e "$mtree/.git" ]] || { echo "SIGTERM case: the merge tree never appeared" >&2; kill "$runner_pid" 2>/dev/null; exit 1; }
sleep 0.3
kill -TERM "$runner_pid"
set +e; wait "$runner_pid"; st=$?; set -e
[[ $st -eq 143 ]] || { echo "a SIGTERM should exit 143, got $st" >&2; exit 1; }
expect_gone "SIGTERM"

# A lane that has not returned can advance its branch after build() captured
# the SHA. The record names the captured commit, so that commit is what must be
# merged. A post-checkout hook, which `worktree add` fires, moves issue-2 once.
old2="$(git -C "$mrepo" rev-parse issue-2)"
cat >"$mrepo/.git/hooks/post-checkout" <<HOOK
#!/bin/sh
rm -f "$mrepo/.git/hooks/post-checkout"
g="git --git-dir=$mrepo/.git"
blob=\$(echo moved | \$g hash-object -w --stdin)
tree=\$({ \$g ls-tree issue-2; printf '100644 blob %s\tmoved\n' "\$blob"; } | \$g mktree)
new=\$(\$g commit-tree "\$tree" -p issue-2 -m moved)
\$g update-ref refs/heads/issue-2 "\$new"
HOOK
chmod +x "$mrepo/.git/hooks/post-checkout"
merge_test 'git rev-parse HEAD^2 >"'"$mt"'/tested"' --lane issue-2
rm -f "$mrepo/.git/hooks/post-checkout"
[[ "$(git -C "$mrepo" rev-parse issue-2)" != "$old2" ]] || { echo "moved-branch case: the hook never moved issue-2" >&2; exit 1; }
rec="$(cat "$mt/out")"
expect_record "moved branch" "$rec" "^issue-2 $old2\$"
[[ "$(cat "$mt/tested")" == "$old2" ]] || { echo "moved branch: tested $(cat "$mt/tested"), recorded $old2" >&2; exit 1; }
expect_record "moved branch" "$rec" '^result: green$'
expect_gone "moved branch"
git -C "$mrepo" branch -q -f issue-2 "$old2"

# Perturb what the rule keys on: with A touching z instead, C no longer meets
# any merged branch, so the line names DEFAULT. issue-5 stands in for that A.
git -C "$mrepo" checkout -q -b issue-6 main
printf 'x from D2\n' >"$mrepo/x"
git -C "$mrepo" -c commit.gpgsign=false commit -q -am issue-6
git -C "$mrepo" checkout -q main
# issue-6 alone changes x on top of DEFAULT; make DEFAULT itself carry an x
# change on origin, so a conflict has to name DEFAULT.
git -C "$mrepo" checkout -q -b bump main
printf 'x from main\n' >"$mrepo/x"
git -C "$mrepo" -c commit.gpgsign=false commit -q -am bump
git -C "$mrepo" push -q origin bump:main
git -C "$mrepo" checkout -q main
git -C "$mrepo" branch -q -D bump
set +e; merge_test 'echo never' --lane issue-5 --lane issue-6; st=$?; set -e
[[ $st -eq 1 ]] || { echo "a DEFAULT conflict should exit 1, got $st" >&2; exit 1; }
rec="$(cat "$mt/out")"
expect_record "DEFAULT conflict" "$rec" '^conflict: issue-6 with DEFAULT — x$'
expect_gone "DEFAULT conflict"


# --- check-worktrees.py: Step 3's collision check (#391). A lane that stopped
# on a Step 5 rebase conflict has a detached HEAD, so its porcelain entry has
# no branch line, and a hand comparison refused the wave over its own lane. ---

wtscript=work-wave/scripts/check-worktrees.py
require_file "$wtscript"

# The vendored block. find_tree and the helpers it calls come out of
# work-issue/scripts/run-state.py byte for byte. Extracted by name, since
# run-state.py reflows as work-issue grows. Each function in the block has no
# blank line inside it, so the first blank line ends the extraction.
require_text "$wtscript" "Vendored verbatim from work-issue/scripts/run-state.py"
require_text "$wtscript" "Upstream is authoritative: fix it there, then re-copy."

extract_tree_block() {
  local file="$1"
  sed -n '/^GIT_TIMEOUT = /p' "$file"
  local name
  for name in run_git git_failure read_text chomp rebasing_branch; do
    sed -n "/^def $name(/,/^\$/p" "$file"
  done
  # find_tree's docstring holds a blank line, so it ends on its last statement.
  sed -n '/^def find_tree(/,/^    return root, None$/p' "$file"
}

extract_tree_block work-issue/scripts/run-state.py > "$tmp/tree-upstream.txt"
extract_tree_block "$wtscript" > "$tmp/tree-vendored.txt"

# Two empty extractions `cmp` clean, so a renamed function would read as a
# passing identity check. The floor fails first.
[[ "$(wc -l < "$tmp/tree-upstream.txt" | tr -d ' ')" -gt 45 ]] || {
  echo "the find_tree markers matched almost nothing in run-state.py; fix the markers, not the floor" >&2
  exit 1
}
for fn in run_git git_failure read_text chomp rebasing_branch find_tree; do
  grep -q "^def $fn(" "$tmp/tree-vendored.txt" || {
    echo "check-worktrees.py is missing vendored $fn" >&2
    exit 1
  }
done
cmp "$tmp/tree-upstream.txt" "$tmp/tree-vendored.txt" || {
  echo "check-worktrees.py's vendored find_tree block has drifted from work-issue/scripts/run-state.py" >&2
  exit 1
}

# Stdlib only, so the skill stays copy-in portable.
python3 - "$wtscript" <<'PY' || { echo "check-worktrees.py imports outside the standard library" >&2; exit 1; }
import ast, sys
tree = ast.parse(open(sys.argv[1]).read())
for node in ast.walk(tree):
    names = []
    if isinstance(node, ast.Import):
        names = [a.name for a in node.names]
    elif isinstance(node, ast.ImportFrom):
        names = [node.module or ""]
    for name in names:
        if name.split(".")[0] not in sys.stdlib_module_names:
            sys.exit(1)
PY
python3 -W error::SyntaxWarning -c "import ast; ast.parse(open('$wtscript').read())" || {
  echo "check-worktrees.py raises a SyntaxWarning" >&2
  exit 1
}

check_worktrees() {
  set +e
  python3 "$wtscript" "$@" >"$tmp/out" 2>"$tmp/err"
  status=$?
  set -e
  out="$(cat "$tmp/out")"
  err="$(cat "$tmp/err")"
}

wgit() { git -c user.name=t -c user.email=t@t -c commit.gpgsign=false "$@"; }

# A scratch ROOT at $tmp/wt/<name>/skills with branches issue-7 and main that
# edit one line of f differently, so a rebase of issue-7 onto main conflicts.
make_wt_repo() {
  local root="$tmp/wt/$1/skills"
  mkdir -p "$root"
  git init -q -b main "$root"
  printf 'base\n' >"$root/f"
  wgit -C "$root" add f
  wgit -C "$root" commit -q -m base
  wgit -C "$root" branch issue-7
  wgit -C "$root" checkout -q issue-7
  printf 'from issue\n' >"$root/f"
  wgit -C "$root" commit -q -am issue
  wgit -C "$root" checkout -q main
  printf 'from main\n' >"$root/f"
  wgit -C "$root" commit -q -am main
  echo "$root"
}

# The lane's own tree, `issue-7` checked out, then a rebase onto main that
# stops on the conflict and leaves HEAD detached.
make_rebasing_tree() {
  local root="$1"
  wgit -C "$root" worktree add -q "$root/../skills-issue-7" issue-7
  set +e
  wgit -C "$root/../skills-issue-7" rebase main >/dev/null 2>&1
  local st=$?
  set -e
  [[ $st -ne 0 ]] || { echo "the scratch rebase should stop on a conflict" >&2; exit 1; }
  [[ -d "$root/../skills-issue-7/.git" || -f "$root/../skills-issue-7/.git" ]]
  grep -Fxq detached <<<"$(git -C "$root" worktree list --porcelain)" || {
    echo "the scratch tree should be detached mid-rebase" >&2
    exit 1
  }
}

# Criterion: an already-started lane mid-rebase of issue-N exits 0, with
# WORKTREE spelled the way Step 0 derives it, `..` and a trailing slash,
# while porcelain prints the resolved path.
r1="$(make_wt_repo midrebase)"
make_rebasing_tree "$r1"
check_worktrees --root "$r1" --lane "issue-7=$r1/../skills-issue-7/" --started issue-7
expect_status 0 "a started lane mid-rebase of its own branch, WORKTREE spelled with .. and a slash"
refute_text "$tmp/err" "collision:"

# The same tree, but the lane isn't passed as --started: the exemption keys on
# the lane being started, so a tree on issue-N for any other lane collides.
check_worktrees --root "$r1" --lane "issue-7=$r1/../skills-issue-7/"
expect_status 1 "an unstarted lane whose tree holds its own branch"
expect_line "$err" "collision: issue-7 $(cd "$r1/../skills-issue-7" && pwd -P)" "an unstarted lane on its own branch"

# A tree on its branch normally, no rebase, is exempt too.
wgit -C "$r1/../skills-issue-7" rebase --abort
check_worktrees --root "$r1" --lane "issue-7=$r1/../skills-issue-7" --started issue-7
expect_status 0 "a started lane with issue-7 checked out"
expect_line "$out" "OK: 1 lane, 1 exempt" "an exempted started lane"

# Criterion: the same tree with `other` checked out collides, mid-rebase's
# neighbor on the exemption's key.
wgit -C "$r1/../skills-issue-7" checkout -q -b other
check_worktrees --root "$r1" --lane "issue-7=$r1/../skills-issue-7" --started issue-7
expect_status 1 "a started lane whose tree has other checked out"
expect_line "$err" "collision: issue-7 $(cd "$r1/../skills-issue-7" && pwd -P)" "a started lane on other"

# A tree mid-rebase of some other branch is no one's own lane either.
r2="$(make_wt_repo otherrebase)"
wgit -C "$r2" branch issue-8 issue-7
make_rebasing_tree "$r2"
check_worktrees --root "$r2" --lane "issue-8=$r2/../skills-issue-7" --started issue-8
expect_status 1 "issue-8's WORKTREE pointing at a tree mid-rebase of issue-7"

# A stale directory nothing registered is a hit, started or not.
r3="$(make_wt_repo plaindir)"
mkdir "$r3/../skills-issue-7"
check_worktrees --root "$r3" --lane "issue-7=$r3/../skills-issue-7" --started issue-7
expect_status 1 "a started lane whose WORKTREE is an unregistered directory"
check_worktrees --root "$r3" --lane "issue-7=$r3/../skills-issue-9"
expect_status 0 "a lane whose WORKTREE does not exist"
expect_line "$out" "OK: 1 lane, 0 exempt" "a clean single lane"
# --started names a lane whose tree is gone: nothing to exempt, nothing to
# collide with, so the count says 0 rather than counting the flag.
check_worktrees --root "$r3" --lane "issue-7=$r3/../skills-issue-9" --started issue-7
expect_status 0 "a started lane whose WORKTREE does not exist"
expect_line "$out" "OK: 1 lane, 0 exempt" "a started lane with no tree"

# A prunable entry, registered with its directory gone, is still a hit.
r4="$(make_wt_repo prunable)"
wgit -C "$r4" worktree add -q "$r4/../skills-issue-7" issue-7
rm -rf "$r4/../skills-issue-7"
check_worktrees --root "$r4" --lane "issue-7=$r4/../skills-issue-7"
expect_status 1 "a prunable registered WORKTREE"

# A lane whose WORKTREE is ROOT itself is never exempted by find_tree's ROOT
# fallback, which answers ROOT for a branch that doesn't exist locally.
check_worktrees --root "$r4" --lane "issue-99=$r4" --started issue-99
expect_status 1 "a started lane whose WORKTREE is ROOT"

# A lane whose branch is local but checked out nowhere has no tree to exempt.
r5="$(make_wt_repo nowhere)"
mkdir "$r5/../skills-issue-7"
check_worktrees --root "$r5" --lane "issue-7=$r5/../skills-issue-7" --started issue-7
expect_status 1 "a started lane with issue-7 checked out in no worktree"

# Criterion: two colliding lanes print two collision lines in one run, so one
# refusal names every hit.
r6="$(make_wt_repo twohits)"
mkdir "$r6/../skills-issue-8" "$r6/../skills-issue-9"
check_worktrees --root "$r6" --lane "issue-9=$r6/../skills-issue-9" --lane "issue-8=$r6/../skills-issue-8" --lane "issue-7=$r6/../skills-issue-7"
expect_status 1 "two colliding lanes beside a clear one"
[[ "$(grep -c '^collision: ' "$tmp/err")" == 2 ]] || {
  echo "two colliding lanes should print two collision lines, got: $err" >&2
  exit 1
}
[[ "$(grep '^collision: ' "$tmp/err" | head -1)" == "collision: issue-8 "* ]] || {
  echo "collision lines should print in ascending issue order, got: $err" >&2
  exit 1
}

# Exit 3: usage errors and a failed `git worktree list`, each before any lane
# is judged.
check_worktrees --root "$r6" --lane "issue-7"
expect_status 3 "a --lane with no ="
check_worktrees --root "$r6" --lane "feature=$r6/../x"
expect_status 3 "a --lane not named issue-N"
check_worktrees --root "$r6" --lane "issue-7=$r6/../a" --lane "issue-7=$r6/../b"
expect_status 3 "a lane named twice"
check_worktrees --root "$r6" --lane "issue-7=$r6/../a" --started issue-8
expect_status 3 "a --started lane with no matching --lane"
check_worktrees --root "$r6" --lane "issue-7=$r6/../a" --started feature
expect_status 3 "a malformed --started"
check_worktrees --root "$r6"
expect_status 3 "no lanes"
check_worktrees --lane "issue-7=$r6/../a"
expect_status 3 "a missing --root"
check_worktrees --root "$r6" --lane "issue-7=$r6/../a" --bogus
expect_status 3 "an unknown flag"
# Collisions are problems, so they go to stderr with the other validators'.
check_worktrees --root "$r6" --lane "issue-8=$r6/../skills-issue-8"
refute_text "$tmp/out" "collision:"
check_worktrees --root "$tmp/not-a-repo" --lane "issue-7=$tmp/not-a-repo/../x"
expect_status 3 "a ROOT that isn't a repo"
grep -Fq "worktree list" <<<"$err" || {
  echo "a failed git worktree list should name the command on stderr, got: $err" >&2
  exit 1
}

# Step 3 and its ledger rows name the script and the widened exemption.
require_text "$skill" "work-wave/scripts/check-worktrees.py --root ROOT --lane issue-N=WORKTREE"
require_text "$skill" "is exempt when the tree at its WORKTREE holds its own \`issue-N\`, checked out or mid-rebase"
refute_text "$skill" "is exempt when its WORKTREE is registered in \`git worktree list --porcelain\` on its own \`issue-N\` branch"
require_text "$skill" "line per hit on stderr"
require_text "$skill" "A held lane gets neither flag, since the script exits 3 on a \`--started\` with no \`--lane\`."
require_text work-wave/README.md "check-worktrees.py"
require_text "$ledger" "| 64 | \`check-worktrees.py\` runs Step 3's collision check"
require_text "$ledger" "when the tree at its WORKTREE holds \`issue-N\`, checked out or mid-rebase of it"
require_text "$ledger" "| Judging the already-started exemption by the porcelain's \`branch\` line |"

# --- order.py: Step 2's order.md, built from coupling.md, and Steps 5 and 7's
# hold (#397). Sorted by hand, the order nothing checked was the order Step 6
# merged, and an ask that Step 3 settled into order: never reached it. ---

oscript=work-wave/scripts/order.py
require_file "$oscript"
[[ -x "$oscript" ]] || {
  echo "order.py is not executable: $oscript" >&2
  exit 1
}

python3 - "$oscript" <<'PY' || { echo "order.py imports outside the standard library" >&2; exit 1; }
import ast, sys
tree = ast.parse(open(sys.argv[1]).read())
for node in ast.walk(tree):
    names = []
    if isinstance(node, ast.Import):
        names = [a.name for a in node.names]
    elif isinstance(node, ast.ImportFrom):
        names = [node.module or ""]
    for name in names:
        if name.split(".")[0] not in sys.stdlib_module_names:
            sys.exit(1)
PY

order_py() {
  set +e
  python3 "$oscript" "$@" >"$tmp/out" 2>"$tmp/err"
  status=$?
  set -e
  out="$(cat "$tmp/out")"
  err="$(cat "$tmp/err")"
}

# A repo of its own, so the probe's git reads can't meet the other sections'
# branches.
orepo="$tmp/orepo"
git init -q -b main "$orepo"
git -C "$orepo" -c user.name=t -c user.email=t@t -c commit.gpgsign=false commit -q --allow-empty -m init

# The consumer check: what order.py writes is right only if the probe reads a
# merge set from it. A byte comparison alone passes a table the probe nulls.
order_probes() {
  local dir="$1"
  local what="$2"
  wave_state probe --wave-dir "$dir" --root "$orepo" --default main
  expect_status 0 "probe over $what"
  python3 - "$tmp/out" "$what" <<'PY' || exit 1
import json, sys
probe = json.load(open(sys.argv[1]))
if probe["merge_set_size"] is None:
    sys.exit(f"probe over {sys.argv[2]} read merge_set_size as null")
PY
}

# The Order and Lane columns top to bottom, as one line.
order_lanes() {
  python3 - "$1/order.md" <<'PY'
import sys
rows = [l for l in open(sys.argv[1]).read().split("\n") if l.startswith("| ")][1:]
print(" ".join(f"{r.split('|')[1].strip()}:{r.split('|')[2].strip()}" for r in rows))
PY
}

expect_lanes() {
  local dir="$1"
  local want="$2"
  local what="$3"
  local got
  got="$(order_lanes "$dir")"
  [[ "$got" == "$want" ]] || {
    echo "$what should order $want, got: $got" >&2
    exit 1
  }
}

coupling_header='| Pair | Answer | Evidence | Resolution |\n|---|---|---|---|\n'
ow="$orepo/.git/work-wave/wave-113-114-115"
mkdir -p "$ow"

# The rule's falsifier, first half: the order: row is what moves issue-113.
printf "$coupling_header"'| issue-113 issue-114 | independent | nothing shared | none |\n| issue-113 issue-115 | directional 115→113 | 113 tests what 115 adds | order: issue-113 after issue-115 |\n| issue-114 issue-115 | independent | nothing shared | none |\n' >"$ow/coupling.md"
order_py build --wave-dir "$ow"
expect_status 0 "build with order: issue-113 after issue-115"
expect_lanes "$ow" "1:issue-114 2:issue-115 3:issue-113" "build with order: issue-113 after issue-115"
require_text "$ow/order.md" "| 3 | issue-113 | issue-115 | order: issue-113 after issue-115 |"
require_text "$ow/order.md" "| 1 | issue-114 | — | no coupling; number order |"
order_probes "$ow" "a built order.md"
cp "$ow/order.md" "$tmp/order-forward.md"

# Second half: the nearest wrong key is the row order in coupling.md, so
# reversing it must leave the bytes alone.
printf "$coupling_header"'| issue-114 issue-115 | independent | nothing shared | none |\n| issue-113 issue-115 | directional 115→113 | 113 tests what 115 adds | order: issue-113 after issue-115 |\n| issue-113 issue-114 | independent | nothing shared | none |\n' >"$ow/coupling.md"
order_py build --wave-dir "$ow"
expect_status 0 "build over reversed coupling rows"
cmp "$tmp/order-forward.md" "$ow/order.md" || {
  echo "reversing coupling.md's rows changed order.md" >&2
  exit 1
}
# A lane behind two others joins both Resolutions into Why, and an order
# taken from the rows would flip that join when they're reversed.
printf "$coupling_header"'| issue-113 issue-115 | directional 113→115 | reads 113 | order: issue-115 after issue-113 |\n| issue-114 issue-115 | directional 114→115 | reads 114 | order: issue-115 after issue-114 |\n' >"$ow/coupling.md"
order_py build --wave-dir "$ow"
expect_status 0 "build with issue-115 after two lanes"
require_text "$ow/order.md" "| 3 | issue-115 | issue-113, issue-114 | order: issue-115 after issue-113; order: issue-115 after issue-114 |"
cp "$ow/order.md" "$tmp/order-forward.md"
printf "$coupling_header"'| issue-114 issue-115 | directional 114→115 | reads 114 | order: issue-115 after issue-114 |\n| issue-113 issue-115 | directional 113→115 | reads 113 | order: issue-115 after issue-113 |\n' >"$ow/coupling.md"
order_py build --wave-dir "$ow"
cmp "$tmp/order-forward.md" "$ow/order.md" || {
  echo "reversing two order: rows for one lane changed order.md" >&2
  exit 1
}

printf "$coupling_header"'| issue-113 issue-114 | independent | nothing shared | none |\n| issue-113 issue-115 | independent | nothing shared | none |\n| issue-114 issue-115 | independent | nothing shared | none |\n' >"$ow/coupling.md"
order_py build --wave-dir "$ow"
expect_status 0 "build with the order: row dropped"
expect_lanes "$ow" "1:issue-113 2:issue-114 3:issue-115" "build with the order: row dropped"
order_probes "$ow" "an uncoupled order.md"

# A hold: row holds its lane with After naming what it waits on, and a lane
# ordered after the held one leaves with it, as Step 5 holds a failed lane's
# successors.
printf "$coupling_header"'| issue-113 issue-114 | directional 113→114 | 114 writes against 113 | hold: issue-114 until issue-113 merges |\n| issue-113 issue-115 | independent | nothing shared | none |\n| issue-114 issue-115 | directional 114→115 | 115 reads 114 | order: issue-115 after issue-114 |\n' >"$ow/coupling.md"
order_py build --wave-dir "$ow"
expect_status 0 "build with a hold: row"
expect_lanes "$ow" "1:issue-113 held:issue-114 held:issue-115" "build with a hold: row"
require_text "$ow/order.md" "| held | issue-114 | issue-113 | hold: issue-114 until issue-113 merges |"
require_text "$ow/order.md" "| held | issue-115 | issue-114 |"
order_probes "$ow" "an order.md with held lanes"

# hold on a held lane changes nothing, and a lane outside the table is usage.
cp "$ow/order.md" "$tmp/order-held.md"
order_py hold --wave-dir "$ow" --lane issue-114 --why "again"
expect_status 0 "hold on a lane already held"
cmp "$tmp/order-held.md" "$ow/order.md" || {
  echo "hold on a held lane rewrote order.md" >&2
  exit 1
}
order_py hold --wave-dir "$ow" --lane issue-9 --why "not here"
expect_status 3 "hold on a lane order.md doesn't name"
grep -Fq "issue-9" <<<"$err" || {
  echo "hold on a missing lane should name it on stderr, got: $err" >&2
  exit 1
}

# hold goes by Order position: issue-115 has no After and is still held, and
# issue-114 keeps Order 3 across the gap. A hold that followed After edges or
# renumbered would write another table; see the ledger's matching DNB rows.
printf '| Order | Lane | After | Why |\n|---|---|---|---|\n| 1 | issue-113 | — | no coupling; number order |\n| 3 | issue-114 | — | no coupling; number order |\n| 4 | issue-115 | — | no coupling; number order |\n' >"$ow/order.md"
order_py hold --wave-dir "$ow" --lane issue-114 --why "issue-114 failed"
expect_status 0 "hold across a gap in Order"
expect_lanes "$ow" "1:issue-113 3:issue-114 held:issue-115" "hold --lane issue-114 across a gap"
order_probes "$ow" "an order.md with a gap after hold"

# refuse and a two-lane cycle exit 1 naming the lanes, and write nothing.
rm -f "$ow/order.md"
printf "$coupling_header"'| issue-113 issue-114 | mutual | each half of one change | refuse |\n| issue-113 issue-115 | independent | nothing shared | none |\n| issue-114 issue-115 | independent | nothing shared | none |\n' >"$ow/coupling.md"
order_py build --wave-dir "$ow"
expect_status 1 "build with a refuse row"
{ grep -Fq "issue-113" <<<"$err" && grep -Fq "issue-114" <<<"$err"; } || {
  echo "a refuse row should name both lanes on stderr, got: $err" >&2
  exit 1
}
[[ ! -e "$ow/order.md" ]] || { echo "a refused build wrote order.md" >&2; exit 1; }

printf "$coupling_header"'| issue-113 issue-114 | directional | loop | order: issue-114 after issue-113 |\n| issue-113 issue-115 | directional | after the loop | order: issue-115 after issue-114 |\n| issue-114 issue-113 | directional | loop | order: issue-113 after issue-114 |\n' >"$ow/coupling.md"
order_py build --wave-dir "$ow"
expect_status 1 "build over a two-lane cycle"
{ grep -Fq "issue-113" <<<"$err" && grep -Fq "issue-114" <<<"$err"; } || {
  echo "a cycle should name both lanes on stderr, got: $err" >&2
  exit 1
}
# issue-115 waits on the cycle without being in it.
if grep -Fq "issue-115" <<<"$err"; then
  echo "a cycle named issue-115, which only waits on it: $err" >&2
  exit 1
fi
[[ ! -e "$ow/order.md" ]] || { echo "a cyclic build wrote order.md" >&2; exit 1; }

# Exit 3: no coupling.md, no table in it, a lane outside the wave, a
# Resolution it can't read, and a WAVE_DIR whose name names no lanes.
rm -f "$ow/coupling.md"
order_py build --wave-dir "$ow"
expect_status 3 "build with no coupling.md"
printf 'no table here\n' >"$ow/coupling.md"
order_py build --wave-dir "$ow"
expect_status 3 "build over a coupling.md with no table"
printf "$coupling_header"'| issue-113 issue-114 | directional | reads | order: issue-114 after issue-9 |\n' >"$ow/coupling.md"
order_py build --wave-dir "$ow"
expect_status 3 "build naming a lane outside the wave"
grep -Fq "issue-9" <<<"$err" || {
  echo "a Resolution naming a lane outside the wave should name it on stderr, got: $err" >&2
  exit 1
}
printf "$coupling_header"'| issue-113 issue-114 | directional | reads | merge them somehow |\n' >"$ow/coupling.md"
order_py build --wave-dir "$ow"
expect_status 3 "build over an unreadable Resolution"
# none and ask match as whole words, so a Resolution like nonexistent exits 3.
printf "$coupling_header"'| issue-113 issue-114 | directional | reads | nonexistent |\n' >"$ow/coupling.md"
order_py build --wave-dir "$ow"
expect_status 3 "build over a Resolution that only starts with none"
mkdir -p "$orepo/.git/work-wave/not-a-wave"
cp "$ow/coupling.md" "$orepo/.git/work-wave/not-a-wave/coupling.md"
order_py build --wave-dir "$orepo/.git/work-wave/not-a-wave"
expect_status 3 "build in a WAVE_DIR not named wave-<N>"
[[ ! -e "$ow/order.md" ]] || { echo "a build that exited 3 wrote order.md" >&2; exit 1; }

# The model's tables, read at run time so a hand copy can't drift from them.
# build on main's Step 2 coupling.md writes main's Step 2 order.md byte for
# byte, and so does the asks sequence's ask row, which counts as none until
# Step 3 settles it. hold --lane issue-7 on that table writes
# publish-failed-holds' Step 7 order.md, Why aside.
wm="$orepo/.git/work-wave/wave-7-8"
mkdir -p "$wm"
python3 - "$wave_model" "$tmp" <<'PY' || exit 1
import json, sys
model = json.load(open(sys.argv[1]))
seqs = {s["name"]: s for s in model["sequences"]}
def write(seq, step, path):
    hits = [e for e in seqs[seq]["entries"] if e.get("step") == step and e.get("path") == path and e.get("op") == "write"]
    if len(hits) != 1:
        sys.exit(f"wave-order.json: {seq} has {len(hits)} step {step} writes of {path}")
    return hits[0]["content"]
for name, text in (
    ("main-coupling.md", write("main", 2, "coupling.md")),
    ("main-order.md", write("main", 2, "order.md")),
    ("asks-coupling.md", write("asks", 2, "coupling.md")),
    ("held-order.md", write("publish-failed-holds", 7, "order.md")),
):
    open(f"{sys.argv[2]}/{name}", "w").write(text)
PY
cp "$tmp/main-coupling.md" "$wm/coupling.md"
order_py build --wave-dir "$wm"
expect_status 0 "build on wave-order.json's Step 2 coupling.md"
cmp "$tmp/main-order.md" "$wm/order.md" || {
  echo "build on wave-order.json's Step 2 coupling.md differs from its Step 2 order.md" >&2
  exit 1
}
order_probes "$wm" "the model's Step 2 order.md, as built"
cp "$tmp/asks-coupling.md" "$wm/coupling.md"
order_py build --wave-dir "$wm"
expect_status 0 "build over an ask row"
cmp "$tmp/main-order.md" "$wm/order.md" || {
  echo "build over an ask row should write the uncoupled order" >&2
  exit 1
}
order_py hold --wave-dir "$wm" --lane issue-7 --why "issue-7 failed publishing here"
expect_status 0 "hold --lane issue-7 on the model's Step 2 order.md"
order_probes "$wm" "the model's order.md after hold"
python3 - "$tmp/held-order.md" "$wm/order.md" <<'PY' || exit 1
import sys
def masked(path):
    out = []
    for line in open(path).read().split("\n"):
        cells = line.split("|")
        if len(cells) > 4 and cells[1].strip() == "held":
            line = "|".join(cells[:4] + [" WHY "] + cells[5:])
        out.append(line)
    return out
want, got = masked(sys.argv[1]), masked(sys.argv[2])
if want != got:
    sys.exit(f"hold --lane issue-7 should write publish-failed-holds' table, Why aside:\nwant {want}\ngot  {got}")
PY
require_text "$wm/order.md" "| held | issue-8 | issue-7 | issue-7 failed publishing here |"

# The prose that routes the conductor through the script, and its ledger rows.
require_text "$skill" "After every \`ask\` row is settled, run \`work-wave/scripts/order.py build --wave-dir WAVE_DIR\` again"
require_text "$skill" "work-wave/scripts/order.py hold --wave-dir WAVE_DIR --lane issue-N --why TEXT"
require_text work-wave/README.md "order.py"
require_text "$ledger" "| 65 | \`order.py\` writes \`order.md\`"
require_text "$ledger" "| 66 | A lane whose \`order:\` row puts it after a held lane is held"
require_text "$ledger" "| 67 | \`hold\` stays positional"
# Row 67's two cuts, refuted where either would have to be stated or built.
for f in "$skill" "$oscript"; do
  refute_text "$f" "whose \`After\` names"
  refute_text "$f" "renumber"
done

# --- #460: lane hand-backs. A lane whose worker outlives its turn returns
# prose instead of its report, and handback.py is what tells the two apart. ---

handback=work-wave/scripts/handback.py
[[ -x "$handback" ]] || {
  echo "handback.py is not executable: $handback" >&2
  exit 1
}

# Runs the script at $1 over a fresh WAVE_DIR and fails unless a terminal
# report prints terminal, lands as issue-7-build.json, and leaves no interim
# file. The mutation below runs this on a copy with the check removed.
assert_terminal_report() {
  local script="$1" wd out
  wd="$(mktemp -d "$tmp/hb-terminal.XXXXXX")"
  out="$(python3 "$script" --wave-dir "$wd" --lane issue-7 --phase build --text "$fixtures/handback/terminal-build.txt")" || {
    echo "a terminal report should exit 0, got: $out" >&2
    return 1
  }
  [[ "$out" == "terminal $wd/reports/issue-7-build.json" ]] || {
    echo "a terminal report should print terminal, got: $out" >&2
    return 1
  }
  [[ -f "$wd/reports/issue-7-build.json" ]] || {
    echo "a terminal report should be saved as issue-7-build.json" >&2
    return 1
  }
  if compgen -G "$wd/reports/*interim*" >/dev/null; then
    echo "a terminal report should write no interim file" >&2
    return 1
  fi
}
assert_terminal_report "$handback"

hb="$tmp/hb-wave"
mkdir -p "$hb"
hb_run() {
  set +e
  python3 "$handback" --wave-dir "$1" --lane issue-7 --phase build --text "$fixtures/handback/midrun-build.txt" >"$tmp/out" 2>"$tmp/err"
  status=$?
  set -e
  out="$(cat "$tmp/out")"
  err="$(cat "$tmp/err")"
}

hb_run "$hb"
expect_status 0 "the first hand-back"
[[ "$out" == "redispatch 1 $hb/reports/issue-7-build-interim-1.json" ]] || {
  echo "the first hand-back should print redispatch 1, got: $out" >&2
  exit 1
}
[[ ! -e "$hb/reports/issue-7-build.json" ]] || {
  echo "a hand-back must not write the terminal report" >&2
  exit 1
}
python3 - "$hb/reports/issue-7-build-interim-1.json" "$fixtures/handback/midrun-build.txt" <<'PY' || exit 1
import json, sys
interim = json.load(open(sys.argv[1]))
if interim.get("text") != open(sys.argv[2]).read():
    sys.exit("the interim report should hold the returned text verbatim")
if "status" in interim:
    sys.exit("the interim report must carry no status key, or it reads as a report")
PY
hb_run "$hb"
expect_status 0 "the second hand-back"
[[ "$out" == "redispatch 2 $hb/reports/issue-7-build-interim-2.json" ]] || {
  echo "the second hand-back should print redispatch 2, got: $out" >&2
  exit 1
}
hb_run "$hb"
expect_status 1 "the third hand-back"
for k in 1 2 3; do
  for stream in "$out" "$err"; do
    grep -Fq "$hb/reports/issue-7-build-interim-$k.json" <<<"$stream" || {
      echo "the third hand-back should name interim-$k on stdout and stderr, got: $out / $err" >&2
      exit 1
    }
  done
done
[[ "$out" == "stop "* ]] || {
  echo "the third hand-back should print stop, got: $out" >&2
  exit 1
}

# A report for another phase or lane isn't this lane's report for this phase.
mismatch_run() {
  local wd
  wd="$(mktemp -d "$tmp/hb-mismatch.XXXXXX")"
  python3 "$handback" --wave-dir "$wd" --lane "$1" --phase "$2" --text "$fixtures/handback/terminal-build.txt" >"$tmp/out"
  [[ "$(cut -d' ' -f1,2 "$tmp/out")" == "redispatch 1" && ! -e "$wd/reports/issue-7-build.json" ]] || {
    echo "terminal-build.txt run as $1 $2 should be a hand-back, got: $(cat "$tmp/out")" >&2
    exit 1
  }
}
mismatch_run issue-7 publish
mismatch_run issue-8 build

# A saved report is never overwritten, even by a later hand-back.
saved="$(mktemp -d "$tmp/hb-saved.XXXXXX")"
python3 "$handback" --wave-dir "$saved" --lane issue-7 --phase build --text "$fixtures/handback/terminal-build.txt" >/dev/null
cp "$saved/reports/issue-7-build.json" "$tmp/saved-before.json"
hb_run "$saved"
expect_status 3 "a hand-back over a saved report"
cmp "$tmp/saved-before.json" "$saved/reports/issue-7-build.json" || {
  echo "handback.py overwrote a saved report" >&2
  exit 1
}
if compgen -G "$saved/reports/*interim*" >/dev/null; then
  echo "handback.py wrote an interim file beside a saved report" >&2
  exit 1
fi

# F-r1-authz-01: a report with a relative path or a short head saved as
# terminal can't be replaced, so the re-prompt's answer hit exit 3 and the
# wave stopped. It has to land as a hand-back instead.
rel_report() {
  printf '```json\n{"lane":"issue-7","phase":"build","status":"done","worktree":"%s","run_dir":"%s","head":"%s","files_changed":[],"contract_changed":[],"facts":[],"pr":null,"detail":"d","question":""}\n```\n' "$1" "$2" "$3" >"$tmp/rel.txt"
}
for bad in "rel/path /r/7 0123456789abcdef0123456789abcdef01234567" \
           "/w/7 rel 0123456789abcdef0123456789abcdef01234567" \
           "/w/7 /r/7 abc"; do
  rel_report $bad
  wd="$(mktemp -d "$tmp/hb-rel.XXXXXX")"
  python3 "$handback" --wave-dir "$wd" --lane issue-7 --phase build --text "$tmp/rel.txt" >"$tmp/out"
  [[ "$(cut -d' ' -f1 "$tmp/out")" == redispatch && ! -e "$wd/reports/issue-7-build.json" ]] || {
    echo "a report with worktree/run_dir/head $bad should be a hand-back, got: $(cat "$tmp/out")" >&2
    exit 1
  }
done
rel_report /w/7 /r/7 0123456789abcdef0123456789abcdef01234567
wd="$(mktemp -d "$tmp/hb-abs.XXXXXX")"
python3 "$handback" --wave-dir "$wd" --lane issue-7 --phase build --text "$tmp/rel.txt" >"$tmp/out"
[[ "$(cat "$tmp/out")" == "terminal $wd/reports/issue-7-build.json" ]] || {
  echo "the same report with absolute paths and a 40-hex head should be terminal, got: $(cat "$tmp/out")" >&2
  exit 1
}

# A non-string status (list or object) is unhashable; it used to raise and exit 1,
# which Step 4 reads as the third-hand-back stop.
for badstatus in '[]' '{}'; do
  printf '```json\n{"lane":"issue-7","phase":"build","status":%s,"worktree":"/w/7","run_dir":"/r/7","head":"0123456789abcdef0123456789abcdef01234567"}\n```\n' "$badstatus" >"$tmp/badstatus.txt"
  wd="$(mktemp -d "$tmp/hb-badstatus.XXXXXX")"
  python3 "$handback" --wave-dir "$wd" --lane issue-7 --phase build --text "$tmp/badstatus.txt" >"$tmp/out"
  [[ "$(cut -d' ' -f1 "$tmp/out")" == redispatch && ! -e "$wd/reports/issue-7-build.json" ]] || {
    echo "a report with status $badstatus should be a hand-back, got: $(cat "$tmp/out")" >&2
    exit 1
  }
  wd="$(mktemp -d "$tmp/hb-badstatus.XXXXXX")"
  [[ "$(python3 "$handback" --wave-dir "$wd" --lane issue-7 --phase build --text "$tmp/badstatus.txt" --check)" == handback ]] || {
    echo "--check on status $badstatus should print handback" >&2
    exit 1
  }
done

# Undecodable bytes in the lane's text used to raise UnicodeDecodeError and exit 1.
printf '\xff\xfe bad' >"$tmp/badbytes.txt"
wd="$(mktemp -d "$tmp/hb-badbytes.XXXXXX")"
python3 "$handback" --wave-dir "$wd" --lane issue-7 --phase build --text "$tmp/badbytes.txt" >"$tmp/out"
[[ "$(cut -d' ' -f1 "$tmp/out")" == redispatch && ! -e "$wd/reports/issue-7-build.json" ]] || {
  echo "undecodable text should be a hand-back, got: $(cat "$tmp/out")" >&2
  exit 1
}
wd="$(mktemp -d "$tmp/hb-badbytes.XXXXXX")"
[[ "$(python3 "$handback" --wave-dir "$wd" --lane issue-7 --phase build --text "$tmp/badbytes.txt" --check)" == handback ]] || {
  echo "--check on undecodable text should print handback" >&2
  exit 1
}

# A truncated or mistyped report saved as terminal is immutable, so the
# completed one the re-prompt returns would hit exit 3. Each contract field
# dropped in turn, and one wrong type each, must land as a hand-back.
contract_cases() {
  python3 - "$fixtures/handback/terminal-build.txt" "$tmp" <<'PY'
import json, re, sys
src = open(sys.argv[1]).read()
rep = json.loads(re.search(r"```json\n(.*?)\n```", src, re.S).group(1))
cases = {}
for k in ("files_changed", "contract_changed", "pr", "detail", "question"):
    cases["drop-" + k] = {a: b for a, b in rep.items() if a != k}
for k, v in (("files_changed", "a"), ("contract_changed", [1]), ("facts", None), ("pr", 3), ("detail", []), ("question", None)):
    cases["type-" + k] = dict(rep, **{k: v})
for name, r in cases.items():
    open(f"{sys.argv[2]}/contract-{name}.txt", "w").write("```json\n" + json.dumps(r) + "\n```\n")
    print(name)
PY
}
for name in $(contract_cases); do
  wd="$(mktemp -d "$tmp/hb-contract.XXXXXX")"
  python3 "$handback" --wave-dir "$wd" --lane issue-7 --phase build --text "$tmp/contract-$name.txt" >"$tmp/out"
  [[ "$(cut -d' ' -f1 "$tmp/out")" == redispatch && ! -e "$wd/reports/issue-7-build.json" ]] || {
    echo "a report failing the contract ($name) should be a hand-back, got: $(cat "$tmp/out")" >&2
    exit 1
  }
  wd="$(mktemp -d "$tmp/hb-contract.XXXXXX")"
  [[ "$(python3 "$handback" --wave-dir "$wd" --lane issue-7 --phase build --text "$tmp/contract-$name.txt" --check)" == handback ]] || {
    echo "--check on a report failing the contract ($name) should print handback" >&2
    exit 1
  }
done

# --check classifies and writes nothing, so Step 7 can take its hold before
# the write without holding for a message that saves as a hand-back.
check_run() {
  local wd
  wd="$(mktemp -d "$tmp/hb-check.XXXXXX")"
  set +e
  python3 "$handback" --wave-dir "$wd" --lane issue-7 --phase build --text "$1" --check >"$tmp/out"
  status=$?
  set -e
  [[ "$status" == 0 && "$(cat "$tmp/out")" == "$2" ]] || {
    echo "--check on $1 should print '$2' and exit 0, got $status: $(cat "$tmp/out")" >&2
    exit 1
  }
  [[ -z "$(ls -A "$wd")" ]] || {
    echo "--check wrote into WAVE_DIR: $(find "$wd" -mindepth 1)" >&2
    exit 1
  }
}
check_run "$fixtures/handback/terminal-build.txt" "terminal done"
check_run "$fixtures/handback/midrun-build.txt" "handback"
rel_report rel/path /r/7 0123456789abcdef0123456789abcdef01234567
check_run "$tmp/rel.txt" "handback"
sed 's/"status": "done"/"status": "failed"/' "$fixtures/handback/terminal-build.txt" >"$tmp/failed.txt"
check_run "$tmp/failed.txt" "terminal failed"

# An interim-only lane is still unreported to the probe (row 7), so a wave
# re-invoked after the third-hand-back stop re-dispatches it once.
iwd="$repo/.git/work-wave/wave-37-38"
mkdir -p "$iwd/reports"
printf '| Order | Lane | After | Why |\n|---|---|---|---|\n| 1 | issue-37 | — | no coupling; number order |\n| 2 | issue-38 | — | no coupling; number order |\n' >"$iwd/order.md"
printf '{"lane": "issue-38", "phase": "build", "status": "done"}\n' >"$iwd/reports/issue-38-build.json"
cp "$hb/reports/issue-7-build-interim-1.json" "$iwd/reports/issue-37-build-interim-1.json"
wave_state probe --wave-dir "$iwd" --root "$repo" --default main
expect_status 0 "probe over an interim-only WAVE_DIR"
python3 - "$tmp/out" <<'PY' || exit 1
import json, sys
probe = json.load(open(sys.argv[1]))
if probe["unheld_unreported"] != 1:
    sys.exit(f"an interim report should leave issue-37 unreported, got {probe['unheld_unreported']!r}")
PY

# The falsifier. With the terminal-report check gone, every message is a
# hand-back, so a finished lane would be re-dispatched, and the assertion has
# to notice. The copy loses the real check; the assertion stays whole.
mutant="$tmp/handback-mutant.py"
python3 - "$handback" "$mutant" <<'PY' || exit 1
import sys
src = open(sys.argv[1]).read()
head = "def terminal_report(text, lane, phase):"
start = src.index(head)
end = src.index("\ndef write_atomic", start)
open(sys.argv[2], "w").write(src[:start] + head + "\n    return None\n\n" + src[end:])
PY
if cmp -s "$handback" "$mutant"; then
  echo "the mutation left handback.py unchanged" >&2
  exit 1
fi
if (assert_terminal_report "$mutant") 2>"$tmp/mutant.err"; then
  echo "the terminal assertion passed with the terminal-report check removed" >&2
  exit 1
fi
grep -Fq "a terminal report should print terminal" "$tmp/mutant.err" || {
  echo "the mutant should fail on the terminal verdict, got: $(cat "$tmp/mutant.err")" >&2
  exit 1
}

# A gap in the interim numbers must not let a hand-back overwrite a saved one:
# counting files instead of reading the highest number reused interim-2 here.
hbgap="$tmp/hb-gap-wave"
mkdir -p "$hbgap/reports"
echo sentinel > "$hbgap/reports/issue-7-build-interim-2.json"
hb_run "$hbgap"
expect_status 0 "a hand-back after a numbering gap"
[[ "$out" == "redispatch 3 $hbgap/reports/issue-7-build-interim-3.json" ]] || {
  echo "a hand-back after a gap should take the number past the highest, got: $out" >&2
  exit 1
}
[[ "$(cat "$hbgap/reports/issue-7-build-interim-2.json")" == sentinel ]] || {
  echo "a hand-back overwrote interim-2" >&2
  exit 1
}

# The prose that sends every lane return through the script. Without these the
# script passes every case above while Step 4 still saves prose verbatim as a
# report and Step 5 gates it.
require_text "$skill" "work-wave/scripts/handback.py --wave-dir WAVE_DIR --lane issue-N --phase build --text FILE"
require_text "$skill" "Resume it without asking: continue that lane's own agent with the lane brief's resume line"
require_text "$skill" "Stop the wave on that lane and quote the stderr line, which names every interim report."
require_text "$skill" "Run every returned message through \`handback.py\` as Step 4 does, with \`--phase publish\`"
require_text "$skill" "Run every returned message through \`handback.py\` as Step 4 does, with \`--phase repoll\`"
require_text "$skill" "every report is on disk, written by \`handback.py\`, or the wave stopped on a lane's third hand-back with its interim reports named"
# Question 1 of #460's plan: a hand-back and a malformed report look alike, so
# the old re-prompt rule would have guessed which one a message is.
refute_text "$skill" "re-prompted once with the contract restated"
# The tracked herdr dispatch. issue-393's first hand-back sat on a herdr repair
# prompt sent with nothing to wait on.
require_text "$brief" "--wait --until done --until idle --until blocked --timeout <ms>\` in a background shell call, so its exit wakes you"
require_text "$brief" "A herdr prompt sent without \`--wait\`, or in a foreground call, leaves you nothing to wait on."
require_text "$brief" "## The resume line"
require_text "$brief" "Your last turn ended without the report your brief asks for"
require_text "$skill" "and ends on the line the state earns—or the wave stopped on a lane's third hand-back with its interim reports named."
# F-r1-authz-02: order.py has no release, so a hold taken on a message that
# then saves as a hand-back strands the successors.
require_text "$skill" "Classify each message first: run the same command with \`--check\` added, which writes nothing and prints \`terminal <status>\` or \`handback\`."
require_text "$skill" "so the hold lands before the report does and never lands for a message the script saves as a hand-back."
require_text work-wave/README.md "handback.py"
require_text "$ledger" "| 70 | \`handback.py\` checks \`worktree\`, \`run_dir\`, and \`head\` itself"
require_text "$ledger" "| 68 | Step 4 runs every message a lane returns through \`handback.py\`"
require_text "$ledger" "| 69 | The lane brief names one tracked shape for every herdr prompt a lane sends"

# --- #461: lane policy. Nobody watches a lane, so the wave hands each one a
# ruling policy for the budget and red-team stops, and the orchestrator copies
# every ruling a lane made into facts/wave.md, the file it alone writes. ---

lane_policy=work-wave/scripts/lane-policy.py
require_file "$lane_policy"
[[ -x "$lane_policy" ]] || {
  echo "lane-policy.py is not executable: $lane_policy" >&2
  exit 1
}

lp_run() {
  set +e
  python3 "$lane_policy" "$@" >"$tmp/out" 2>"$tmp/err"
  status=$?
  set -e
  out="$(cat "$tmp/out")"
  err="$(cat "$tmp/err")"
}

# The lane defaults, each applied only where the wave left the flag out.
lp_run flags
expect_status 0 "lane-policy.py flags with no flags"
[[ "$out" == " --auto-budget 4.0 --defer-after 3 --repair-class unowned-write" ]] || {
  echo "lane-policy.py flags with no flags should print the lane defaults, got: '$out'" >&2
  exit 1
}
lp_run flags --repair-class unowned-write --defer-after 5 --auto-budget 6
expect_status 0 "lane-policy.py flags with all three flags"
[[ "$out" == " --auto-budget 6.0 --defer-after 5 --repair-class unowned-write" ]] || {
  echo "lane-policy.py flags should print the wave's flags in fixed order, got: '$out'" >&2
  exit 1
}
lp_run flags --defer-after 7
expect_status 0 "lane-policy.py flags with one flag"
[[ "$out" == " --auto-budget 4.0 --defer-after 7 --repair-class unowned-write" ]] || {
  echo "lane-policy.py flags should default only the flags the wave left out, got: '$out'" >&2
  exit 1
}
for bad in "--auto-budget 0" "--auto-budget nan" "--repair-class lossy" "--defer-after 0"; do
  # shellcheck disable=SC2086
  lp_run flags $bad
  expect_status 3 "lane-policy.py flags $bad"
  expect_line "$err" "lane-policy: ${bad/ /: }" "lane-policy.py flags $bad"
done

# The one place this suite runs work-issue's policy.py: the two scripts re-state
# one set of flag rules, so they have to accept, refuse, and print each value
# alike. The other two flags stay valid so no lane default fills in.
wi_policy=work-issue/scripts/policy.py
require_file "$wi_policy"
lp_compare() {
  local flag="$1" value="$2" lp_status wi_status lp_out wi_out
  local -a args=(--auto-budget 5 --defer-after 2 --repair-class unowned-write)
  case "$flag" in
    --auto-budget) args[1]="$value" ;;
    --defer-after) args[3]="$value" ;;
    --repair-class) args[5]="$value" ;;
  esac
  set +e
  lp_out="$(python3 "$lane_policy" flags "${args[@]}" 2>/dev/null)"
  lp_status=$?
  wi_out="$(python3 "$wi_policy" flags "${args[@]}" 2>/dev/null)"
  wi_status=$?
  set -e
  [[ "$lp_status" == "$wi_status" ]] || {
    echo "$flag $value: lane-policy.py exits $lp_status, policy.py exits $wi_status" >&2
    exit 1
  }
  [[ "$lp_status" != 0 || "$lp_out" == " $wi_out" ]] || {
    echo "$flag $value: lane-policy.py prints '$lp_out', policy.py prints '$wi_out'" >&2
    exit 1
  }
}
for value in 4 4.0 0.5 1e3 0 -1 nan inf 1e400 abc ""; do lp_compare --auto-budget "$value"; done
for value in 1 3 03 0 -1 1.5 abc ""; do lp_compare --defer-after "$value"; done
for value in unowned-write lossy Unowned-Write ""; do lp_compare --repair-class "$value"; done

# facts: two policy.log lines land once each after the existing merge-test
# line, a re-run adds nothing, and nothing else under facts/ changes.
lp_wave="$tmp/lp-wave"
lp_run_dir="$tmp/lp-run/issue-7"
mkdir -p "$lp_wave/facts" "$lp_run_dir"
printf -- '- [wave] merge test 1: green\n' >"$lp_wave/facts/wave.md"
printf -- '- [issue-7] gh needs --repo here — gh pr list\n' >"$lp_wave/facts/issue-7.md"
cp "$lp_wave/facts/issue-7.md" "$tmp/lp-issue-7.before"
cat >"$lp_run_dir/policy.log" <<'LOG'
- [wave] policy: issue-7 budget at step 7: raise 4.0 (--auto-budget 4.0) — build: 30m review: 90m ratio: 3.00 over: yes
- [wave] policy: issue-7 red-team round 2: repair (--repair-class unowned-write) — 1 /tmp/peer/a1.txt
LOG
lp_run facts --run-dir "$lp_run_dir" --wave-dir "$lp_wave"
expect_status 0 "lane-policy.py facts"
[[ "$out" == "facts: 2 appended" ]] || {
  echo "lane-policy.py facts should report two lines appended, got: $out" >&2
  exit 1
}
{ printf -- '- [wave] merge test 1: green\n'; cat "$lp_run_dir/policy.log"; } >"$tmp/lp-wave.want"
cmp -s "$tmp/lp-wave.want" "$lp_wave/facts/wave.md" || {
  echo "facts/wave.md should hold the merge-test line, then both policy lines:" >&2
  cat "$lp_wave/facts/wave.md" >&2
  exit 1
}
lp_run facts --run-dir "$lp_run_dir" --wave-dir "$lp_wave"
expect_status 0 "lane-policy.py facts, run again"
[[ "$out" == "facts: 0 appended" ]] || {
  echo "a second lane-policy.py facts should append nothing, got: $out" >&2
  exit 1
}
cmp -s "$tmp/lp-wave.want" "$lp_wave/facts/wave.md" || {
  echo "a second lane-policy.py facts changed facts/wave.md" >&2
  exit 1
}
lp_run facts --run-dir "$tmp/lp-run/issue-8" --wave-dir "$lp_wave"
expect_status 0 "lane-policy.py facts with no policy.log"
cmp -s "$tmp/lp-wave.want" "$lp_wave/facts/wave.md" || {
  echo "lane-policy.py facts with no policy.log changed facts/wave.md" >&2
  exit 1
}
cmp -s "$tmp/lp-issue-7.before" "$lp_wave/facts/issue-7.md" || {
  echo "lane-policy.py facts changed a lane's own facts file" >&2
  exit 1
}
[[ "$(find "$lp_wave/facts" -type f | wc -l | tr -d ' ')" == "2" ]] || {
  echo "lane-policy.py facts wrote a new file under facts/" >&2
  exit 1
}

# The prose that carries the policy to every lane and its rulings back. Without
# these pins the script passes every case above while no lane is handed a flag.
require_text "$skill" "\`--auto-budget <ratio>\`, \`--defer-after <k>\`, and \`--repair-class <class>\` set the ruling policy every lane's \`work-issue\` invocation carries"
require_text "$skill" "Before the resume probe, run \`work-wave/scripts/lane-policy.py flags\` with whichever of the three the user gave"
require_text "$skill" "with \`--review-loop[=<comment>]\` and the policy \` --auto-budget 4.0 --defer-after 3 --repair-class unowned-write\` added"
require_text "$skill" "work-wave/scripts/lane-policy.py facts --run-dir <run_dir> --wave-dir WAVE_DIR"
require_text "$brief" "- \`{{POLICY}}\` —"
require_text "$brief" "Fifteen substitutions. Fourteen stand for a single value"
require_text work-wave/README.md "and \`lane-policy.py\` copies those lines into the wave's \`facts/wave.md\` as each lane reports"
require_text work-wave/README.md "--auto-budget 4.0 --defer-after 3 --repair-class unowned-write"
require_text "$ledger" "| 71 | Every lane's \`work-issue\` invocation carries \`--auto-budget 4.0 --defer-after 3 --repair-class unowned-write\`"

# --- #480: null head on a refused or failed lane. A Step 0 refusal makes no
# worktree, so its honest report carries a null head and worktree. Read as a
# hand-back, it was resumed twice and stopped the whole wave on the third. ---

# The issue's repro, byte for byte.
printf '%s' '{"lane":"issue-7","phase":"build","status":"refused","worktree":null,"run_dir":"/tmp/x/.git/work-issue/issue-7","head":null,"pr":null,"files_changed":[],"contract_changed":[],"facts":[],"detail":"refused at Step 0","question":"plan fails check-plan"}' >"$tmp/hb480-repro.txt"
# The Falsifier: `status` alone decides, so each variant changes one field.
sed 's/"status":"refused"/"status":"done"/' "$tmp/hb480-repro.txt" >"$tmp/hb480-done.txt"
sed 's/"status":"refused"/"status":"stopped"/' "$tmp/hb480-repro.txt" >"$tmp/hb480-stopped.txt"
sed 's/"status":"refused"/"status":"failed"/; s|"worktree":null|"worktree":"/w/7"|' "$tmp/hb480-repro.txt" >"$tmp/hb480-failed.txt"
sed 's/"detail":"refused at Step 0"/"detail":"done"/' "$tmp/hb480-repro.txt" >"$tmp/hb480-detail.txt"
sed 's/"question":"plan fails check-plan"/"question":""/' "$tmp/hb480-repro.txt" >"$tmp/hb480-question.txt"
# A lane that sends a head meant it to be read, so a short one stays a hand-back.
sed 's/"head":null/"head":"abc"/' "$tmp/hb480-repro.txt" >"$tmp/hb480-shorthead.txt"
python3 - "$fixtures/handback/terminal-build.txt" "$tmp" <<'PY' || exit 1
import json, re, sys
rep = json.loads(re.search(r"```json\n(.*?)\n```", open(sys.argv[1]).read(), re.S).group(1))
open(f"{sys.argv[2]}/hb480-nofacts.txt", "w").write("```json\n" + json.dumps({k: v for k, v in rep.items() if k != "facts"}) + "\n```\n")
open(f"{sys.argv[2]}/hb480-factsx.txt", "w").write("```json\n" + json.dumps(dict(rep, facts="x")) + "\n```\n")
open(f"{sys.argv[2]}/hb480-deep.txt", "w").write('{"a":' + "[" * 200000 + "]" * 200000 + "}")
PY
for f in done stopped failed detail question shorthead; do
  cmp -s "$tmp/hb480-repro.txt" "$tmp/hb480-$f.txt" && {
    echo "the #480 $f variant is identical to the repro; its sed missed" >&2
    exit 1
  }
done

# Runs script $1 on text $2 over WAVE_DIR $3, with extra args after.
hb480() {
  local script="$1" text="$2" wd="$3"
  shift 3
  set +e
  python3 "$script" --wave-dir "$wd" --lane issue-7 --phase build --text "$text" "$@" >"$tmp/hb480.out" 2>"$tmp/hb480.err"
  status=$?
  set -e
  out="$(cat "$tmp/hb480.out")"
  err="$(cat "$tmp/hb480.err")"
}

# Returns non-zero on the wrong verdict, so the same case runs against the
# real script and against each mutant below.
hb480_case() {
  local script="$1" name="$2" wd text want check
  wd="$(mktemp -d "$tmp/hb480-$name.XXXXXX")"
  case "$name" in
    repro | failed | detail | question | nofacts)
      text="$tmp/hb480-$name.txt"; want=terminal ;;
    done | stopped | shorthead | factsx | deep)
      text="$tmp/hb480-$name.txt"; want=redispatch ;;
    ro-terminal)
      text="$tmp/hb480-repro.txt"; want=readonly ;;
    ro-handback)
      text="$fixtures/handback/midrun-build.txt"; want=readonly ;;
  esac
  if [[ "$want" == readonly ]]; then
    mkdir -p "$wd/reports"
    chmod 555 "$wd/reports"
    hb480 "$script" "$text" "$wd"
    chmod 755 "$wd/reports"
    local saving="$wd/reports/issue-7-build.json"
    [[ "$name" == ro-handback ]] && saving="$wd/reports/issue-7-build-interim-1.json"
    [[ "$status" == 3 && "$err" == *"$saving"* && "$err" != *Traceback* ]] || {
      echo "#480 $name: a read-only reports/ should exit 3 naming $saving with no traceback, got $status: $err" >&2
      return 1
    }
    return 0
  fi
  hb480 "$script" "$text" "$wd"
  if [[ "$want" == terminal ]]; then
    [[ "$status" == 0 && "$out" == "terminal $wd/reports/issue-7-build.json" ]] || {
      echo "#480 $name should print terminal and exit 0, got $status: $out $err" >&2
      return 1
    }
    if compgen -G "$wd/reports/*interim*" >/dev/null; then
      echo "#480 $name should write no interim file" >&2
      return 1
    fi
    check="terminal $(python3 -c 'import json,re,sys; t=open(sys.argv[1]).read(); m=re.search(r"```json\n(.*?)\n```", t, re.S); print(json.loads(m.group(1) if m else t)["status"])' "$text")"
  else
    [[ "$status" == 0 && "$out" == "redispatch 1 $wd/reports/issue-7-build-interim-1.json" ]] || {
      echo "#480 $name should print redispatch 1 and exit 0, got $status: $out $err" >&2
      return 1
    }
    [[ ! -e "$wd/reports/issue-7-build.json" ]] || {
      echo "#480 $name must not write the terminal report" >&2
      return 1
    }
    check=handback
  fi
  wd="$(mktemp -d "$tmp/hb480-$name-check.XXXXXX")"
  hb480 "$script" "$text" "$wd" --check
  [[ "$status" == 0 && "$out" == "$check" ]] || {
    echo "#480 $name: --check should print '$check' and exit 0, got $status: $out $err" >&2
    return 1
  }
}

hb480_cases="repro failed detail question nofacts done stopped shorthead factsx deep"
# Root ignores the mode bits, so the read-only cases can't fail as root.
if [[ "$(id -u)" == 0 ]]; then
  echo "work-wave smoke: running as root, skipping the #480 read-only reports/ cases"
else
  hb480_cases="$hb480_cases ro-terminal ro-handback"
fi
for name in $hb480_cases; do
  hb480_case "$handback" "$name" || exit 1
done

# Each mutant reverts one fix and has to fail that fix's case, or the case
# pins nothing.
hb480_mutant() {
  local name="$1" case="$2" from="$3" to="$4" copy="$tmp/hb480-$1.py"
  python3 - "$handback" "$copy" "$from" "$to" <<'PY' || exit 1
import re, sys
src = open(sys.argv[1]).read()
open(sys.argv[2], "w").write(re.sub(sys.argv[3], sys.argv[4], src))
PY
  if cmp -s "$handback" "$copy"; then
    echo "the #480 $name mutant left handback.py unchanged" >&2
    exit 1
  fi
  if hb480_case "$copy" "$case" 2>/dev/null; then
    echo "the #480 $case case passed against the $name mutant" >&2
    exit 1
  fi
}
hb480_mutant null-head repro 'NULL_HEAD = \{"refused", "failed"\}' 'NULL_HEAD = set()'
hb480_mutant null-head-all done 'NULL_HEAD = \{"refused", "failed"\}' 'NULL_HEAD = STATUSES'
hb480_mutant facts nofacts 'report\.get\(k, \[\] if k == "facts" else None\)' 'report.get(k)'
hb480_mutant facts-any factsx 'for k in \("files_changed", "contract_changed", "facts"\):' 'for k in ("files_changed", "contract_changed"):'
hb480_mutant recursion deep 'except \(ValueError, RecursionError\):' 'except ValueError:'
if [[ "$(id -u)" != 0 ]]; then
  hb480_mutant oserror ro-terminal 'except OSError as e:(\n\s+print\(f"handback: cannot save)' 'except ZeroDivisionError as e:\1'
  hb480_mutant oserror ro-handback 'except OSError as e:(\n\s+print\(f"handback: cannot save)' 'except ZeroDivisionError as e:\1'
fi

# Prose pins for the same rule. The head and worktree lines sit in both report
# blocks of the brief, so each is counted twice.
require_text "$skill" "- Exit 3 — a usage error, an unreadable FILE, a terminal report already on disk that the script refused to overwrite, or a report or hand-back it could not save."
require_text "$brief" "null only when \`status\` is \`refused\` or \`failed\` and you have none"
require_text "$brief" "absolute path, or null when \`status\` is \`refused\` or \`failed\` and work-issue made none"
for want in 'null only when `status` is `refused` or `failed` and you have none' 'absolute path, or null when `status` is `refused` or `failed` and work-issue made none'; do
  if [[ "$(grep -cF "$want" "$brief")" != 2 ]]; then
    echo "$brief must carry '$want' in both report blocks" >&2
    exit 1
  fi
done
require_text "$ledger" "| 72 | A \`refused\` or \`failed\` report may carry a null \`head\`"
require_text "$ledger" "(except as row 72 allows)"

echo "work-wave smoke: OK"
