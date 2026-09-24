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
require_file "$fixtures/runs/issue-8/plan.md"
# The closed run overlaps lane-a on purpose. Without it on disk, the check that
# closed/ is ignored passes because there is nothing to ignore.
require_file "$fixtures/runs/closed/issue-9/plan.md"

[[ "$(find work-wave -maxdepth 1 -type f | wc -l | tr -d ' ')" == "2" ]] || {
  echo "work-wave/ must ship only SKILL.md and README.md at top level" >&2
  exit 1
}

# --- Frontmatter. User-invoked is deliberate: a misfire during ordinary
# planning spends a whole fan-out, and no sibling skill calls this one, so
# AGENTS.md's reachability condition does not apply. ---

require_text "$skill" "name: work-wave"
require_text "$skill" 'description: "Run N GitHub issues at once, one work-issue run per issue in its own worktree, with the footprints proved disjoint, the cross-lane coupling question answered and recorded, the merge order fixed, and the branches merged together and verified before any lane opens a pull request. Use ONLY when the user explicitly invokes work-wave. It never plans an issue, never merges one, and never advances a single issue: for one issue, use work-issue."'
require_text "$skill" "argument-hint: '<issue> <issue> [<issue>...] [--plan N=PATH ...] [--lane-model opus|fable] [--dry-run]'"
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

# Step 2 exists because disjoint paths do not make two lanes independent.
require_text "$skill" "Disjoint paths prove two lanes cannot lose each other's writes. They do not prove the two lanes are independent"

# One dispatch per message serializes the wave, and it looks identical in the
# transcript to the real thing.
require_text "$skill" "Dispatch every lane in a SINGLE message so they run concurrently"
require_text "$skill" "Name LANE_MODEL on every dispatch."

# --isolate keeps an unattended lane off work-issue's isolation ask row, which
# nobody is there to answer.
require_text "$skill" "told to invoke \`work-issue\` by name with \`<N> <PLAN[N]> --isolate\`"

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
# HEAD compares against the commit, which the index cannot hide.
require_text "$skill" "Green, and \`git -C MERGE_TREE diff --stat HEAD\` empty"

# The withheld grant is honored, not enforced, and this route row is the one
# check that sees a lane that published early.
require_text "$skill" "| \`pr\` non-null on a \`build\` report | The lane published before the merge test, against its withheld grant. Stop the wave"

# The orchestrator writes its merge-test line into its own facts file. Writing
# into a lane's file breaks the single-writer rule the facts log rests on.
require_text "$skill" "\`WAVE_DIR/facts/wave.md\`, the one facts file the orchestrator owns"

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

for placeholder in SIBLINGS ISSUE PLAN N WORKTREE RUN_DIR PHASE GRANT WAVE_DIR FACTS FACTS_PATH COUPLING ORDER; do
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
require_text "$merge_test" "Sequential, never octopus, so a conflict names one pair"
require_text "$merge_test" "\`git -C MERGE_TREE diff --stat HEAD\`. Non-empty is \`dirty after verify:\` and red. Checked this way, never with \`git status\`"
require_text "$merge_test" "\`git worktree remove --force MERGE_TREE\`, on every route out"

# Every commit message, pull request body, and dispatch these documents shape
# goes out without an attribution trailer or a generated-by footer.
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

# Row 6: an N-way conflict names no pair, and no human merges that way.
refute_text "$skill" "octopus"

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

# #113's first Non-Goal: the flag belongs in its own issue against work-issue.
refute_text "$skill" "--no-publish"

# A description that lists the workflow becomes the shortcut the model takes
# instead of reading the body.
refute_text "$skill" "description: \"Step"

# --- Maintenance ledger. A ledger without its section headings is prose nobody
# can navigate under time pressure. ---

require_text "$ledger" "## Where This Came From"
require_text "$ledger" "## Decision Ledger"
require_text "$ledger" "## Deliberately Not Built"
require_text "$ledger" "## Known Limitations"
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

# One tabled run that overlaps nothing, one tableless run, and a closed run
# that overlaps lane-a. The tableless run is skipped and not counted as
# checked (ledger row 22), and the closed run is ignored without a word.
footprints --lane issue-1="$fixtures/lane-a.md" --lane issue-3="$fixtures/plan-waves.md" --runs "$fixtures/runs"
expect_status 0 "a tableless run and a closed run"
expect_line "$err" "check-footprints: skipped: issue-8 has no ## Waves table" "a tableless run"
expect_line "$out" "OK: 2 lanes disjoint (checked 1 in-flight run)" "a tableless run and a closed run"
if grep -Fq "issue-9" <<<"$out$err"; then
  echo "a run under closed/ must be ignored silently, got: $out $err" >&2
  exit 1
fi

# Ledger row 27: at the Step 5 re-check a lane's own RUN_DIR sits under --runs
# while its plan.md is passed as --lane, and without the exclusion a lane
# always overlaps itself.
footprints --lane issue-1="$fixtures/lane-a.md" --lane issue-7="$fixtures/runs/issue-7/plan.md" --runs "$fixtures/runs"
expect_status 0 "a lane whose own run sits under --runs"
expect_line "$out" "OK: 2 lanes disjoint (checked 0 in-flight runs)" "a lane whose own run sits under --runs"

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

echo "work-wave smoke: OK"
