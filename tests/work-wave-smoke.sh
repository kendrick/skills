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

[[ "$(find work-wave -maxdepth 1 -type f | wc -l | tr -d ' ')" == "2" ]] || {
  echo "work-wave/ must ship only SKILL.md and README.md at top level" >&2
  exit 1
}

# --- Frontmatter. User-invoked is deliberate: a misfire during ordinary
# planning spends a whole fan-out, and no sibling skill calls this one, so
# AGENTS.md's reachability condition does not apply. ---

require_text "$skill" "name: work-wave"
require_text "$skill" 'description: "Run N GitHub issues at once, one work-issue run per issue in its own worktree, with the footprints proved disjoint, the cross-lane coupling question answered and recorded, the merge order fixed, and the branches merged together and verified before any lane opens a pull request. Use ONLY when the user explicitly invokes work-wave. It never plans an issue, never merges one, and never advances a single issue: for one issue, use work-issue."'
require_text "$skill" "argument-hint: '<issue> <issue> [<issue>...] [--plan N=PATH ...] [--lane-model opus|fable] [--review-loop[=<comment>]] [--dry-run]'"
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
require_text "$skill" "A lane already started (Step 0 item 4) is exempt when its WORKTREE is registered in \`git worktree list --porcelain\` on its own \`issue-N\` branch"

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
# of #113's four measured losses.
require_text "$skill" "| \`worktree\` or \`run_dir\` not absolute, or \`head\` not a SHA | Re-prompt once for the absolute form and the SHA."

# Fewer than two issues is work-issue's job, and a plan held only in the
# conversation is unreachable from a fresh lane subagent.
require_text "$skill" "Fewer than two stops the run with \"one issue is \`work-issue N\`\"."
require_text "$skill" "Its route 4—the plan held in the conversation—is unreachable from a fresh subagent"

# The skill ends by handing a human the merge order, and merges nothing itself.
require_text "$skill" "\"a human merges, in this order\""

# --- The references. The brief is the whole prompt a lane receives, so every
# placeholder, report field, and status the gate reads has to be in it. ---

for placeholder in SIBLINGS ISSUE PLAN N WORKTREE RUN_DIR PHASE GRANT WAVE_DIR FACTS FACTS_PATH COUPLING ORDER REVIEW_LOOP; do
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
[ "$publish_line" = "    work-issue {{N}} {{PLAN}} --isolate{{REVIEW_LOOP}}" ] || {
  echo "publish line in $brief is not exactly: work-issue {{N}} {{PLAN}} --isolate{{REVIEW_LOOP}}" >&2
  exit 1
}
require_text "$skill" "again, with \`--no-publish\` dropped"

# #230: a hand-written \`echo 99 >\` into seven run dirs is what the flag
# replaces. Each pin ties the forwarding to a place a lane can be reached:
# the flag line, and a resumed wave's next dispatch.
require_text "$skill" "\`--review-loop[=<comment>]\` goes on every lane's \`work-issue\` invocation this run dispatches"
require_text "$skill" "A wave re-invoked with \`--review-loop\` passes it on the next dispatch of every merge-set lane whose RUN_DIR is still open"
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
require_text "$brief" "    work-issue {{N}} {{PLAN}} --isolate --no-publish --wave-baseline {{WAVE_DIR}}/baseline.txt{{REVIEW_LOOP}}"
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

echo "work-wave smoke: OK"
