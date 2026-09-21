#!/usr/bin/env bash
# Pin mutation-testing's four artifacts and the rules inside them. Every string
# here is one whose removal leaves every other suite green while the behavior it
# names quietly stops happening: a trigger that drifts from "what the diff adds"
# back to "which files changed", a restore rule that loses the failure that
# taught it, a report row that stops naming the runner's own line.
#
# The refutes carry more weight than the requires. Each one maps to a row in
# Deliberately Not Built, and every one of those cuts is a reasonable-sounding
# idea somebody will re-propose. A parallel mutation runner is the obvious
# optimization; a directory-form restore is the obvious shorthand. The refute is
# what makes re-adding one a red suite rather than a quiet regression.
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

require_text mutation-testing/SKILL.md "**Restore by name**, one path at a time, never by directory."
require_text mutation-testing/SKILL.md "the suite came back green without it"
require_text mutation-testing/SKILL.md "Diff \`git status --porcelain\` against BASELINE's snapshot"

# --- Re-measuring is required before a count leaves the run, not before the run
# ends. Acceptance criterion 4. The trigger matters: bound to the run's end, a
# number quoted mid-run into a PR description escapes the check entirely. ---

require_text mutation-testing/SKILL.md "So before any count leaves this run"
require_text mutation-testing/SKILL.md "moved from 2 failures to 4"

# --- The report names the failing tests and the passing count, per mutation.
# Acceptance criterion 5. ---

require_text mutation-testing/SKILL.md "the runner's summary line verbatim, the failing tests by name, how many passed"
require_text mutation-testing/SKILL.md "\`fails N, leaves M green\`"
require_text mutation-testing/SKILL.md "A \`slipped\` adversarial verdict is a defect in the guard"

# --- The boundary. One mutation, one checkout. ---

require_text mutation-testing/SKILL.md "One mutation, one checkout, in sequence."
require_text mutation-testing/SKILL.md "worktree per mutation"

# --- Two preconditions that make every count downstream meaningful. A red
# baseline makes a failure unattributable; an unproved edit makes a green suite
# read as "no test catches this", which is the inverse of what happened. ---

require_text mutation-testing/SKILL.md "A red baseline stops the run"
require_text mutation-testing/SKILL.md "An edit that silently failed to apply leaves the suite green"

# --- Cuts. Each maps to a row in Deliberately Not Built. The refutes run
# against SKILL.md alone, because the ledger names every cut by its own spelling
# and a refute there would fail on the row that justifies it. ---

refute_text mutation-testing/SKILL.md "git checkout -- ."   # directory-form restore
refute_text mutation-testing/SKILL.md "--parallel"          # parallel mutations
refute_text mutation-testing/SKILL.md "--jobs"              # parallel mutations
refute_text mutation-testing/SKILL.md "mutmut"              # mutation-operator engine
refute_text mutation-testing/SKILL.md "Stryker"             # mutation-operator engine
refute_text mutation-testing/SKILL.md "RUN_DIR"             # persisted run directory

# --- The README is a separate document that can drift from the skill. Pin the
# install flag the root README's map table is checked against, and the two rules
# a reader would act on without opening SKILL.md. ---

require_text mutation-testing/README.md "--skill mutation-testing"
require_text mutation-testing/README.md "Restore happens **by name**, one path at a time."
require_text mutation-testing/README.md "The only safe fan-out is a worktree per mutation, and this skill builds none."

# --- The ledger. The tier legend is what makes an [E] row a claim about a
# measurement rather than a confidence marker, and the refute intro is what ties
# each cut to the assertion above that pins it. ---

require_text _maintenance/mutation-testing/RATIONALE.md "**[E]** measured or observed in a real run"
require_text _maintenance/mutation-testing/RATIONALE.md "## Deliberately Not Built"
require_text _maintenance/mutation-testing/RATIONALE.md "## Known Limitations"
require_text _maintenance/mutation-testing/RATIONALE.md "pinned by a \`refute_text\` assertion"

# --- The evals record no results, and say so. A file that starts recording them
# becomes a claim that somebody ran these, which is exactly what it cannot be. ---

require_text _maintenance/mutation-testing/EVALS.md "**Scenarios are unrun until somebody runs them.**"
require_text _maintenance/mutation-testing/EVALS.md "cannot be pinned by grep"

echo "mutation-testing smoke: OK"
