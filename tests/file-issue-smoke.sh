#!/usr/bin/env bash
# Pin the file-issue skill's load-bearing behavior. Most of these are refutes:
# the failure modes worth guarding are features the research explicitly cut,
# and a well-meaning edit is exactly how they come back.
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

require_file file-issue/SKILL.md
require_file file-issue/README.md
require_file file-issue/references/issue-forms.md
require_file file-issue/references/evidence-map.md
require_file file-issue/assets/bug.template.md
require_file file-issue/assets/feature.template.md
require_file file-issue/assets/task.template.md
require_file file-issue/assets/spike.template.md
require_file _maintenance/file-issue/RATIONALE.md
require_file _maintenance/file-issue/EVALS.md
require_file _docs/file-issue-research.md

[[ "$(find file-issue -maxdepth 1 -type f | wc -l | tr -d ' ')" == "2" ]] || {
  echo "file-issue/ must ship only SKILL.md and README.md at top level" >&2
  exit 1
}

# Frontmatter. The to-tickets exclusion is what keeps two skills with adjacent
# trigger surfaces from firing on each other's work.
require_text file-issue/SKILL.md "name: file-issue"
require_text file-issue/SKILL.md "use to-tickets instead"
require_text file-issue/SKILL.md "Never edits, closes, triages, or ranks existing issues."

# The description must not enumerate the step sequence. A description that
# summarizes a workflow becomes a shortcut the model takes instead of reading
# the body, which is how a multi-stage skill silently collapses to one stage.
refute_text file-issue/SKILL.md "description: \"Step 1"

# Depth governor. Without the ladder the skill interrogates every ask equally,
# which is the failure the whole design exists to avoid.
require_text file-issue/SKILL.md "## Step 2 — Assign Depth"
require_text file-issue/SKILL.md "\`--deep\` pins Depth 2, \`--fast\` pins Depth 0"
require_text file-issue/SKILL.md "Depth 1 — 4 gaps to fill."
require_text file-issue/SKILL.md "Every question names the empty slot it fills."

# Elicit stays inline and stays contract-shaped. Both halves matter: inline is
# the decision, the contract is what keeps it extractable later.
require_text file-issue/SKILL.md "## Step 3 — Elicit"
require_text file-issue/SKILL.md "**Exit:** the moment the rubric in Step 6 becomes satisfiable."
refute_text file-issue/SKILL.md "references/elicit"

# No runtime delegation to an external interrogation skill.
refute_text file-issue/SKILL.md "/grill-me"
refute_text file-issue/SKILL.md "grill-with-docs"

# Escape hatch numbers are load-bearing and uncalibrated; changing them should
# be a deliberate act that fails this test first.
require_text file-issue/SKILL.md "**≥7 independent acceptance criteria**"
require_text file-issue/SKILL.md "**≥4 distinct components**"

# Duplicates are surfaced, never blocked. This is the evidence-contradicted
# feature most likely to get "fixed" back in by someone who assumes blocking is
# the responsible default.
require_text file-issue/SKILL.md "Surface what you find and let the user choose"
require_text file-issue/SKILL.md "Never block."

# Write guard and scope.
require_text file-issue/SKILL.md "wait for explicit confirmation before \`gh issue create\`"
require_text file-issue/SKILL.md "\`--dry-run\` renders and stops."
require_text file-issue/SKILL.md "Creation only."
require_text file-issue/SKILL.md "gh auth status"

# No epic or tracking template — multi-issue decomposition is to-tickets' job.
[[ ! -e file-issue/assets/epic.template.md ]] || {
  echo "epic template is deliberately out of scope; see the RATIONALE ledger" >&2
  exit 1
}

# Every gate in the self-check needs a row in the evidence map, or the tiering
# claim in the README is false.
require_text file-issue/references/evidence-map.md "Stranger test"
require_text file-issue/references/evidence-map.md "Runnable repro"
require_text file-issue/references/evidence-map.md "Agent-readiness"
require_text file-issue/references/evidence-map.md "Things Deliberately Not in the Rubric"

# The uncited Gherkin statistic is marketing. It may appear only in the evidence
# map's do-not-cite row, never in anything the skill reads or emits.
for f in file-issue/SKILL.md file-issue/README.md file-issue/assets/*.md file-issue/references/issue-forms.md; do
  refute_text "$f" "56%"
done
require_text file-issue/references/evidence-map.md "Do not cite it."

require_text _maintenance/file-issue/RATIONALE.md "## Decision Ledger"
require_text _maintenance/file-issue/RATIONALE.md "## Known Limitations"
require_text README.md "npx skills add kendrick/skills --skill file-issue"
