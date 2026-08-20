#!/usr/bin/env bash
# Pin the technical-writing skill's load-bearing decisions. Most of these are
# refutes: the failure modes worth guarding are features the plan explicitly
# cut (unslop, disable-model-invocation, a router that enumerates its own
# steps), and a well-meaning edit is exactly how they come back.
#
# Two pins are EXPECTED TO FAIL right now: the `## Example` requires on both
# reference files. Those sections are harvested from real eval runs later in
# the implementation plan and deliberately don't exist yet. Do not stub them
# to turn this script green — that would make the pins pass while verifying
# nothing.
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

# The trailing `return 0` matters: under `set -e`, a function ending on a
# failed grep aborts the script.
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

require_file technical-writing/SKILL.md
require_file technical-writing/README.md
require_file technical-writing/references/commit-messages.md
require_file technical-writing/references/comments.md
require_file _maintenance/technical-writing/PROVENANCE.md
require_file _maintenance/technical-writing/EVALS.md
require_file _maintenance/technical-writing/upstream/SKILL.md

# Top level ships exactly SKILL.md, README.md, and the references/ dir —
# nothing else. A plain file count (like the other smoke tests use) would
# miss a stray directory, so compare the full listing.
top_level="$(find technical-writing -maxdepth 1 -mindepth 1 | sort)"
expected_top_level=$'technical-writing/README.md\ntechnical-writing/SKILL.md\ntechnical-writing/references'
[[ "$top_level" == "$expected_top_level" ]] || {
  echo "technical-writing/ must ship only SKILL.md, README.md, and references/ at top level" >&2
  echo "found:" >&2
  echo "$top_level" >&2
  exit 1
}

# The three deferred profiles are a deliberate non-goal — the dispatch table
# falls back to the router's globals for these artifact types instead.
for f in technical-writing/references/pr-descriptions.md technical-writing/references/api-reference.md technical-writing/references/readme.md; do
  [[ ! -e "$f" ]] || {
    echo "deferred profile shipped early, contradicting the dispatch table's fallback: $f" >&2
    exit 1
  }
done

# --- SKILL.md decisions --------------------------------------------------

refute_text technical-writing/SKILL.md "disable-model-invocation"

# The description must not enumerate the step sequence: a description that
# summarizes a workflow becomes a shortcut the model takes instead of reading
# the body. Scoped to just the description line, since "Step 1" is a
# legitimate heading later in the file.
description_line="$(grep -m1 '^description:' technical-writing/SKILL.md)"
if [[ "$description_line" == *"Step 1"* ]]; then
  echo "SKILL.md description enumerates the step sequence (contains 'Step 1')" >&2
  exit 1
fi

require_text technical-writing/SKILL.md "never for anything addressed to a person: emails, DMs, and other messages"

# Upstream hard-depends on its `unslop` sibling. This skill ships publicly and
# names no auditor at all, so it must not acquire that dependency by any name.
refute_text technical-writing/SKILL.md "unslop"
refute_text technical-writing/SKILL.md "humanizer"

# Step 2 must still name a concrete action. "Run an audit" with no formal
# invocation is how the step decays into a self-assessment that always passes.
require_text technical-writing/SKILL.md "**Run the prose audit.**"
require_text technical-writing/SKILL.md "invoke it formally via the Skill tool"
require_text technical-writing/SKILL.md "**Layer the house rules.**"
require_text technical-writing/SKILL.md "**Self-check.**"

# The skill ships to people who have neither humanizer nor the author's private
# ~/.claude files. The body may name them as the setup it was built against, but
# the description must not: a hardcoded personal path there reads as a hard
# requirement, and a stranger installing this would get a Step 2 they cannot
# finish and two dead paths into someone else's home directory.
for personal_path in "~/.claude/PROSE.md" "~/.claude/VOICE.md"; do
  if [[ "$description_line" == *"$personal_path"* ]]; then
    echo "SKILL.md description hardcodes a personal path, which strangers won't have: $personal_path" >&2
    exit 1
  fi
done

# The Step 2 self-check must carry only checks valid for every artifact type.
# Diátaxis/mode compliance is a profile concern — it's excluded from commits,
# PR descriptions, and changesets, so a mode check here would fail
# universality. Scoped to the Step 2 section only: "Diátaxis" appears
# legitimately elsewhere in the file (the layers section, the dispatch
# table), so a whole-file refute would be wrong.
step2_section="$(awk '/^## Step 2/{flag=1; print; next} /^## /{if (flag) exit} flag' technical-writing/SKILL.md)"
[[ -n "$step2_section" ]] || {
  echo "could not locate a '## Step 2' section in technical-writing/SKILL.md" >&2
  exit 1
}
for term in "Diátaxis" "Diataxis" "one mode"; do
  if grep -Fq -- "$term" <<<"$step2_section"; then
    echo "Step 2 self-check contains a mode-check term that belongs to profiles, not the router: $term" >&2
    exit 1
  fi
done

require_text technical-writing/SKILL.md "not yet written"

# --- Anti-drift pins on the verbatim CLAUDE.md migrations ---------------
# These passages are copied word-for-word from the user's ~/.claude/CLAUDE.md,
# so the skill and the config can't drift apart while both are live. Paraphrasing
# one is a defect even when the rewrite reads better — the copy's whole job is to
# match. Pin whole passages rather than a phrase from each: a sentence-fragment
# pin passes happily while the rest of the section is reworded around it, which
# is the drift it was supposed to catch.
#
# CLAUDE.md is a user-level file outside this repo, so the test can't diff
# against the source. These strings are the stand-in — update them only when
# CLAUDE.md itself changes, and update the profiles in the same pass.

require_text technical-writing/references/commit-messages.md "Commit messages should focus on the WHY just as much as on the WHAT. They should be just long enough to cover what's essential and no longer."
require_text technical-writing/references/commit-messages.md "Write commit messages in the voice and tone of a helpful technical writer who is also in a hurry; commonly-recognized abbreviations and acronyms are acceptable."
require_text technical-writing/references/commit-messages.md "Never add \`Co-Authored-By\` trailers or any other \"coauthored\" attribution to commit messages or PR descriptions."
require_text technical-writing/references/commit-messages.md "Never manually wrap lines in prose of any sort with hard returns. Let the terminal or git's own pager handle wrapping at display time."

require_text technical-writing/references/comments.md "Comment proactively, but only when the comment carries weight. Every comment should explain the WHY behind the code — the constraint that forced this shape, the past incident this guards against, the surprising invariant a reader might miss, the broader context the code lives inside."
require_text technical-writing/references/comments.md "Comments that explain WHAT the code does are worthless when the code is well-named. Comments that explain HOW the code works shouldn't be necessary if the code is written cleanly. The only comment worth writing is the one that explains something the code itself can't."
require_text technical-writing/references/comments.md "Write comments in the voice and tone of a helpful technical writer who is also in a hurry; commonly-recognized abbreviations and acronyms are acceptable."

# --- Example-harvest pins -------------------------------------------------
# EXPECTED TO FAIL until the harvest step lands. The Example sections come
# from real eval runs later in the plan; do not stub them just to go green.

require_text technical-writing/references/commit-messages.md "## Example"
require_text technical-writing/references/comments.md "## Example"

# A placeholder stub must never ship and quietly satisfy the two pins above.
# refute_text takes a single file, so this one's a direct recursive grep
# rather than the helper.
if grep -rFq -- "pending-harvest" technical-writing/; then
  echo "unexpected text under technical-writing/: pending-harvest" >&2
  exit 1
fi

# --- PROVENANCE pins -------------------------------------------------------

require_text _maintenance/technical-writing/PROVENANCE.md "## Deviations From Upstream"
require_text _maintenance/technical-writing/PROVENANCE.md "MIT, Copyright (c) 2026 Lauren Tan"

# --- Root README pin --------------------------------------------------

require_text README.md "npx skills add kendrick/skills --skill technical-writing"

echo "all pins passed"
