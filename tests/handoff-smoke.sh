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
require_text handoff/SKILL.md "argument-hint: '[handoff id to resume | a prompt to hand off | empty for whole session]'"
require_text handoff/SKILL.md "## How to Verify"
require_text handoff/SKILL.md "**Skills.**"
require_text handoff/SKILL.md "This workflow is designed to work across coding agents and operating systems."
require_text handoff/SKILL.md "a write is complete when the document exists"
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
