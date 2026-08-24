#!/usr/bin/env bash
# Pin the readme-coauthorship skill's load-bearing decisions. The ledger this
# guards starts at the technical-writing polish step; most pins are on that
# coupling, because a soft dependency is exactly the kind of feature a
# well-meaning edit hardens or drops without noticing.
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

# --- Inventory ---------------------------------------------------------

require_file readme-coauthorship/SKILL.md
require_file readme-coauthorship/README.md
require_file readme-coauthorship/references/elicitation.md
require_file readme-coauthorship/references/readme-craft.md
require_file readme-coauthorship/references/section-templates.md
require_file readme-coauthorship/references/nested-readmes.md
require_file readme-coauthorship/references/agent-companions.md
require_file _maintenance/readme-coauthorship/RATIONALE.md
require_file _maintenance/readme-coauthorship/EVALS.md

# --- Step skeleton ------------------------------------------------------
# The polish step sits between generate and validate so validation checks the
# post-polish text; the renumbered steps downstream prove the insertion rather
# than an append.

require_text readme-coauthorship/SKILL.md "## Step 5 — Polish"
require_text readme-coauthorship/SKILL.md "## Step 6 — Validate"
require_text readme-coauthorship/SKILL.md "## Step 7 — Companions"

# --- Soft dependency on technical-writing -------------------------------
# Degrades to current behavior when absent—a caller with only this skill
# installed must see nothing broken or off. The caller names the callee, and
# technical-writing owns any downstream prose auditor, so this skill never
# names one directly.

require_text readme-coauthorship/SKILL.md "invoke it via the Skill tool on the drafted README"
require_text readme-coauthorship/SKILL.md "the draft stands"
require_text readme-coauthorship/SKILL.md "never reach past it to one directly"
refute_text readme-coauthorship/SKILL.md "humanizer"
refute_text readme-coauthorship/SKILL.md "unslop"

# Single point of dispatch: the Step 5 paragraph is the only place this skill
# names technical-writing at runtime. A second mention in a reference file is
# how the coupling spreads and the ping-pong starts.
refute_text readme-coauthorship/references/readme-craft.md "technical-writing"
refute_text readme-coauthorship/references/elicitation.md "technical-writing"
refute_text readme-coauthorship/references/section-templates.md "technical-writing"
refute_text readme-coauthorship/references/nested-readmes.md "technical-writing"
refute_text readme-coauthorship/references/agent-companions.md "technical-writing"

# The polish pass must stay a wording pass. Structure, badges, commands, and
# harvested facts belong to Steps 2-4, and the enhance posture's verbatim
# passages survive it.
require_text readme-coauthorship/SKILL.md "The pass changes wording only."
require_text readme-coauthorship/SKILL.md "passages Step 4 preserved verbatim stay verbatim"

# --- Renumber integrity -------------------------------------------------
# The reference files name step numbers in prose; these are the mentions the
# Step 5 insertion moved, pinned so a future renumber can't miss them.

require_text readme-coauthorship/references/readme-craft.md "the Step 6 voice check is the gate"
require_text readme-coauthorship/references/agent-companions.md "Loaded at Step 7"
require_text readme-coauthorship/references/nested-readmes.md "Step 7's companion offer"

# --- Pre-existing load-bearing decisions --------------------------------

require_text readme-coauthorship/SKILL.md "**Never fabricate.**"
require_text readme-coauthorship/SKILL.md "all 13 items are checked"
require_text readme-coauthorship/SKILL.md "Setup is the last question autopilot ever asks."

# --- Root README pin ----------------------------------------------------

require_text README.md "npx skills add kendrick/skills --skill readme-coauthorship"

echo "all pins passed"
