#!/usr/bin/env bash
# Verify the shipped handoff skill and its maintainer-only companion stay separate.
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

require_file handoff/SKILL.md
require_file handoff/README.md
[[ "$(find handoff -maxdepth 1 -type f | wc -l | tr -d ' ')" == "2" ]] || {
  echo "handoff/ must ship only SKILL.md and README.md" >&2
  exit 1
}

require_file _maintenance/handoff/RATIONALE.md
require_file _maintenance/handoff/PROVENANCE.md
require_file _maintenance/handoff/upstream/harpb-handoff.md
require_file _maintenance/handoff/upstream/mattpocock-SKILL.md
require_file _maintenance/handoff/sync-upstream.sh
require_file _maintenance/handoff/sync-upstream.mjs
require_file _maintenance/handoff/sync-upstream.ps1
require_file _maintenance/handoff/template/SKILL.md

require_text handoff/SKILL.md "disable-model-invocation: true"
require_text handoff/SKILL.md "argument-hint: '[handoff id or pasted doc to resume | a prompt to hand off | md for a canvas | empty for whole session]'"
require_text handoff/SKILL.md "## How to Verify"
require_text handoff/SKILL.md "**Skills.**"
require_text handoff/SKILL.md "This workflow is designed to work across coding agents and operating systems."
require_text handoff/SKILL.md "a write is complete when the document is delivered"

# Storage lives in the OS temp directory now. The refute keeps the old in-repo
# path from creeping back through an upstream sync.
require_text handoff/SKILL.md "<TMP>/agent-handoff/<PROJECT>/"

# The durability test is what keeps a sandboxed host from writing into a
# container, so pin its wording along with the branch that serves those hosts.
require_text handoff/SKILL.md "still reachable after this session ends"
require_text handoff/SKILL.md "## Render a Canvas"
require_text handoff/SKILL.md "pasted into the message"
refute_text handoff/SKILL.md ".agents/handoff"

# Resume stops for the user instead of working. The refute matters most: this
# instruction arrived by inheriting harpb's "keep going", so a sync is exactly
# how it comes back.
# Both ends offer the user a session name, because Claude Code derives one from
# the project directory and only the user can change it. The write side must pass
# the name to /clear: a bare clear carries the old name onto the resumed session.
require_text handoff/SKILL.md "Name this session: /rename <slug>"
require_text handoff/SKILL.md "Clear this session: /clear <name for the work just finished>"

require_text handoff/SKILL.md "it does not start the work"
require_text handoff/SKILL.md "the response stops for the user's answer"
refute_text handoff/SKILL.md "Continuing:"
require_text handoff/README.md "agent-handoff"

require_text _maintenance/handoff/PROVENANCE.md "## Deviations From Upstream"

bash -n _maintenance/handoff/sync-upstream.sh
node --check _maintenance/handoff/sync-upstream.mjs

rendered_skill="$(mktemp "${TMPDIR:-/tmp}/handoff-rendered.XXXXXX")"
rm "$rendered_skill"
trap 'rm -f "$rendered_skill"' EXIT
node _maintenance/handoff/sync-upstream.mjs --skip-upstream --write --output "$rendered_skill"
cmp -s _maintenance/handoff/template/SKILL.md "$rendered_skill" || {
  echo "renderer output differs from the canonical template" >&2
  exit 1
}
node _maintenance/handoff/sync-upstream.mjs --skip-upstream --check

if [[ "${HANDOFF_VERIFY_UPSTREAM:-0}" == "1" ]]; then
  sync_output="$(bash _maintenance/handoff/sync-upstream.sh)"
  require_text <(printf '%s\n' "$sync_output") "No upstream changes: harpb-handoff.md"
  require_text <(printf '%s\n' "$sync_output") "No upstream changes: mattpocock-SKILL.md"
fi
