#!/usr/bin/env bash
# Pin mutation-testing's four artifacts and the rules inside them. Every string
# here is one whose removal leaves every other suite green while the behavior it
# names quietly stops happening: a trigger that drifts from "what the diff adds"
# back to "which files changed", a restore rule that loses the failure that
# taught it, a report row that stops naming the runner's own line.
#
# The refutes carry more weight than the requires. Every row in Deliberately Not
# Built has at least one, and each of those cuts is a reasonable-sounding idea
# somebody will re-propose. A parallel mutation runner is the obvious
# optimization; a directory-form restore is the obvious shorthand. The refute is
# what makes re-adding one a red suite rather than a quiet regression. The
# mapping runs row-to-assertion and not the reverse: the disable-model-invocation
# refute below pins the invocation mode and answers to no row.
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

# Guards against a migration regressing. The trailing `return 0` matters: under
# `set -e`, a function ending on a failed grep aborts the script.
refute_text() {
  local file="$1"
  local text="$2"
  grep -Fq -- "$text" "$file" && {
    echo "unexpected text in $file: $text" >&2
    exit 1
  }
  return 0
}

# --- The four artifacts. ---

require_file mutation-testing/SKILL.md
require_file mutation-testing/README.md
require_file _maintenance/mutation-testing/RATIONALE.md
require_file _maintenance/mutation-testing/EVALS.md

[[ "$(find mutation-testing -maxdepth 1 -type f | wc -l | tr -d ' ')" == "2" ]] || {
  echo "mutation-testing/ must ship only SKILL.md and README.md" >&2
  exit 1
}

# --- Invocation. This skill is model-invoked, the opposite call from its
# user-invoked neighbors, and the whole premise is that nothing else asks for
# the measurement. A `disable-model-invocation: true` added by pattern-matching
# on adversarial-review or work-issue would silently end the triggering. ---

require_text mutation-testing/SKILL.md "name: mutation-testing"
refute_text mutation-testing/SKILL.md "disable-model-invocation"
require_text mutation-testing/SKILL.md "This skill is model-invoked"

# --- The trigger is stated by what the diff adds, never by kind of file. This
# is acceptance criterion 1 on the issue, and the failure it prevents is a
# description that reads "use on test files" and so never fires on the
# controller line that added the guard. ---

require_text mutation-testing/SKILL.md "Use when a diff adds a rejection, a validation, an invariant, a limit, a permission or ownership check, a branch that refuses input, or a test pinning one of those"
require_text mutation-testing/SKILL.md "Read the diff for what it **adds**, not for which files it touches."
require_text mutation-testing/SKILL.md "A formatting change to a file full of guards adds none"

# --- Two questions, two mutations. Collapsing them back into one rule with a
# caveat is the edit ledger row 2 exists to prevent: a plausible mutation cannot
# answer the quantity question, because a guard watching the wrong quantity
# survives every reasonable edit to the right one. ---

require_text mutation-testing/SKILL.md "asks whether a reasonable refactor would slip past this suite"
require_text mutation-testing/SKILL.md "asks whether the guard is watching the right quantity at all"
require_text mutation-testing/SKILL.md "a guard watching the wrong quantity survives every reasonable edit to the right one"

# --- The plausible-refactor rule keeps the measurement that taught it.
# Acceptance criterion 2: the rule is stated with the failure it prevents, and
# "21" is that failure. A rule stated without its number reads as taste. ---

require_text mutation-testing/SKILL.md "produced 21 failures"
require_text mutation-testing/SKILL.md "Reach for the plausible version rather than an arbitrary break"

# --- Restore by name, with the near miss named. Acceptance criterion 3. The
# green-suite-without-the-test sentence is the load-bearing half: without it the
# rule is an unexplained preference, and the next author picks the shorter
# command. ---

require_text mutation-testing/SKILL.md "**Restore by copying item 1's backup back**"
require_text mutation-testing/SKILL.md "the suite came back green without it"
require_text mutation-testing/SKILL.md "against BASELINE's snapshot: \`git status --porcelain\` matches it"

# --- Re-measuring is required before a count leaves the run, not before the run
# ends. Acceptance criterion 4. The trigger matters: bound to the run's end, a
# number quoted mid-run into a PR description escapes the check entirely. ---

require_text mutation-testing/SKILL.md "So before any count leaves this run"
require_text mutation-testing/SKILL.md "moved from 2 failures to 4"

# --- The report names the failing tests and the passing count, per mutation.
# Acceptance criterion 5. ---

require_text mutation-testing/SKILL.md "the runner's summary line verbatim, the failing tests by name, how many passed"
require_text mutation-testing/SKILL.md "\`fails N, leaves M green\`"
require_text mutation-testing/SKILL.md "that is a defect in the guard rather than a measurement of the suite"

# --- The boundary. One mutation, one checkout. ---

require_text mutation-testing/SKILL.md "One mutation, one working tree, in sequence."
require_text mutation-testing/SKILL.md "worktree per mutation"

# --- Two preconditions that make every count downstream meaningful. A red
# baseline makes a failure unattributable; an unproved edit makes a green suite
# read as "no test catches this", which is the inverse of what happened. ---

require_text mutation-testing/SKILL.md "A red baseline stops the run"
require_text mutation-testing/SKILL.md "An edit that silently failed to apply leaves the suite green"

# --- Cuts. Each maps to a row in Deliberately Not Built. The refutes run
# against SKILL.md alone, because the ledger names every cut by its own spelling
# and a refute there would fail on the row that justifies it. ---

# A CLI token is not the mechanism. The first version of this block pinned
# `--parallel` and `--jobs` alone, and a scratch SKILL.md carrying "Dispatch the
# mutations concurrently, one git worktree per mutation" passed green. Each row
# now gets its tooling names AND the ordinary words somebody would write.

# Row: parallel mutations or a worktree fan-out.
refute_text mutation-testing/SKILL.md "--parallel"
refute_text mutation-testing/SKILL.md "--jobs"
refute_text mutation-testing/SKILL.md "concurrently"
refute_text mutation-testing/SKILL.md "in parallel"

# Row: a mutation-operator engine.
refute_text mutation-testing/SKILL.md "mutmut"
refute_text mutation-testing/SKILL.md "Stryker"
refute_text mutation-testing/SKILL.md "mutation operator"

# Row: a persisted run directory.
refute_text mutation-testing/SKILL.md "RUN_DIR"
refute_text mutation-testing/SKILL.md "run directory"

# Row: parsing the runner's output into structured numbers. Previously unpinned.
refute_text mutation-testing/SKILL.md "structured numbers"
refute_text mutation-testing/SKILL.md "Parse the runner"
require_text mutation-testing/SKILL.md "rather than a count assembled by hand"

# Row: mutating anything the diff did not add. Previously unpinned. The positive
# rule is pinned above at Step 1; this catches the wording that would undo it.
refute_text mutation-testing/SKILL.md "nearby guard"
refute_text mutation-testing/SKILL.md "outside the diff"

# Row: a directory-form restore.
refute_text mutation-testing/SKILL.md "git checkout -- ."

# --- Three rules added after round 1 of code-review found them contradicting
# their own neighbors. Each pin below goes red if the contradiction comes back. ---

# The copy-aside lands outside the repo. Inside it, the backup is untracked, so
# it trips the status comparison two items later and halts every valid run.
require_text mutation-testing/SKILL.md "to a scratch location outside the repository"

# Step 4's re-measure re-takes BASELINE, and does it from a restored tree. Both
# halves matter: without the re-take the re-measure deadlocks against the restore
# check, and without the ordering the re-take disarms that check for good.
require_text mutation-testing/SKILL.md "re-take BASELINE and re-run every mutation"
require_text mutation-testing/SKILL.md "so every mutation is already restored"
# The past-event reading is the whole of item 1. Read as a check to run at Step 4
# time it is unsatisfiable, since the grown suite is itself the difference, and a
# red-team round found exactly that ambiguity in the first wording.
require_text mutation-testing/SKILL.md "never a check to run now"
require_text mutation-testing/SKILL.md "BASELINE was re-taken from a fully restored tree"

# An unpinned guard gets no mutation: zero failures there is indistinguishable
# from the reading this skill gives a real gap.
require_text mutation-testing/SKILL.md "Two per guard that Step 1 paired with a test"
require_text mutation-testing/SKILL.md "every guard with a pinning test carries one mutation of each kind"

# --- The dirty-tree divergence, ledger row 15. Both sibling skills refuse a
# dirty tree; this one snapshots it, because it fires DURING the work on a guard
# nobody has committed yet, so refusing one would refuse every run the trigger
# describes. A maintainer pattern-matching on adversarial-review or divvy-up
# would reintroduce their precondition in their words, so the refutes pin that
# wording rather than a phrase invented here. ---

require_text mutation-testing/SKILL.md "The tree does not have to be clean, and usually is not"
refute_text mutation-testing/SKILL.md "commit or stash first"
refute_text mutation-testing/SKILL.md "dirty tree stops"

# --- Codex found both of these on the pull request, and both are the same
# shape: a rule stated in one document and contradicted or unimplemented in the
# one that executes. ---

# The restore check is two comparisons. Status alone cannot see a failed restore
# on a dirty tree, which is the tree this skill always runs in: an
# already-modified file reads " M path" before the mutation and after it.
require_text mutation-testing/SKILL.md "matches its backup in both contents and mode"
# cmp passes on a file whose executable bit moved, and so does the status check,
# so a mode-only restore failure cleared both until this clause landed.
require_text mutation-testing/SKILL.md "Contents alone is not enough"
require_text mutation-testing/SKILL.md "reports status codes rather than contents"
require_text mutation-testing/SKILL.md "Verify the restore twice"

# A slipped verdict is a defect only where behaviour a caller could observe
# changed. README, RATIONALE and EVALS all promised the report marks an
# equivalent mutant as unresolved; SKILL.md, the file that executes, did not.
require_text mutation-testing/SKILL.md "That is an equivalent mutant"
require_text mutation-testing/SKILL.md "awaiting a human ruling, and it is not reported as a defect"
refute_text mutation-testing/SKILL.md "A \`slipped\` adversarial verdict is a defect in the guard, not a measurement"

# --- Found by a reproducer after two external passes had cleared this area.
# git checkout -- <dir> restores tracked files from the index, so an untracked
# file is never the casualty; the run looks for a tracked file's " M" line to
# vanish. SKILL.md said "?? to absent" while EVALS.md said the opposite. ---

require_text mutation-testing/SKILL.md "leaves untracked ones where they are"
refute_text mutation-testing/SKILL.md "the new test went from \`??\` to absent"

# The mode comparison runs against the backup, never against HEAD: git diff
# --summary is relative to the commit, so on the dirty tree this skill runs in
# it reports nothing while the restored mode is wrong.
require_text mutation-testing/SKILL.md "Compare against the backup rather than against HEAD"
require_text mutation-testing/SKILL.md "matches its backup in contents and in mode"

# The README stated the unqualified slipped rule twice; only one was fixed.
require_text mutation-testing/README.md "A slipped verdict that names a real gap goes first"
refute_text mutation-testing/README.md "A slipped adversarial verdict goes first"

# Scenario 4 named a directory its own fixture never defines.
require_text _maintenance/mutation-testing/EVALS.md "uncommitted edit to the tracked \`tests/test_storage.py\`"
refute_text _maintenance/mutation-testing/EVALS.md "app/storage/impl.py"

# --- Two P0s from the second Codex round, both the dirty tree biting again.
# Every git-vs-index comparison in this skill is blind to the difference between
# the user's uncommitted guard and the run's own mutation. ---

# The mutation proof runs against the backup. `git diff -- <path>` is non-empty
# because of the guard itself, so it reports success for a mutation that never
# applied, and the unchanged suite then reports a false coverage gap.
require_text mutation-testing/SKILL.md "prove it landed **against item 1's backup**"
require_text mutation-testing/SKILL.md "reports success for a mutation that never applied"

# Restore is a copy-back, never git checkout: on this tree the index holds the
# state before the guard existed, so checkout deletes the user's work.
require_text mutation-testing/SKILL.md "Never with \`git checkout\`"
require_text mutation-testing/SKILL.md "deletes the very work the run was called to measure"
require_text mutation-testing/SKILL.md "Never by directory either."

# --- Third time an offered alternative defeated the check beside it: first
# `git diff --summary` for mode, then a grep for the mutation proof. The backup
# comparison is the proof and carries no alternatives.
require_text mutation-testing/SKILL.md "That comparison is the proof, and it has no alternatives."
refute_text mutation-testing/SKILL.md "or a grep finds the inserted text with its line number"

# `git checkout` is a forbidden command in this document, so "checkout" as a
# noun for the working copy is a collision an agent should not have to resolve.
refute_text mutation-testing/SKILL.md "one checkout, in sequence"

# --- The README is a separate document that can drift from the skill. Pin the
# install flag the root README's map table is checked against, and the two rules
# a reader would act on without opening SKILL.md. ---

require_text mutation-testing/README.md "--skill mutation-testing"
require_text mutation-testing/README.md "copying the backup back"
# The README must name the destructive command as forbidden, not merely omit it.
require_text mutation-testing/README.md "never with \`git checkout\`"
require_text mutation-testing/README.md "The only safe fan-out is a worktree per mutation, and this skill builds none."

# --- The README and the evals carry rules of their own now, and reverting
# either stayed green until these landed. ---

require_text mutation-testing/README.md "compared against the backup taken outside the repo, in contents and in mode"
require_text mutation-testing/README.md "An equivalent mutant is reported unresolved, not as a defect."
require_text mutation-testing/README.md "a \`cmp\` against the backup and a \`git status\` comparison"

# Scenario 4 could not fail as first written, twice over: a collateral file in a
# sibling directory is never reached, and an untracked one under the restored
# path is not either, since git checkout -- <dir> restores tracked files only.
require_text _maintenance/mutation-testing/EVALS.md "has to be an edit to a **tracked** file"
require_text _maintenance/mutation-testing/EVALS.md "restores tracked files from the index and leaves untracked ones alone"

# --- The ledger. The tier legend is what makes an [E] row a claim about a
# measurement rather than a confidence marker, and the refute intro is what ties
# each cut to the assertion above that pins it. ---

require_text _maintenance/mutation-testing/RATIONALE.md "**[E]** measured or observed in a real run"
require_text _maintenance/mutation-testing/RATIONALE.md "## Deliberately Not Built"
require_text _maintenance/mutation-testing/RATIONALE.md "## Known Limitations"
require_text _maintenance/mutation-testing/RATIONALE.md "pinned by at least one \`refute_text\` assertion"

# --- The evals record no results, and say so. A file that starts recording them
# becomes a claim that somebody ran these, which is exactly what it cannot be. ---

require_text _maintenance/mutation-testing/EVALS.md "**Scenarios are unrun until somebody runs them.**"
require_text _maintenance/mutation-testing/EVALS.md "cannot be pinned by grep"

echo "mutation-testing smoke: OK"
