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

require_text handoff/SKILL.md "disable-model-invocation: true"
require_text handoff/SKILL.md "argument-hint: \"[handoff id to resume | a prompt to hand off | empty for whole session]\""
require_text handoff/SKILL.md "## How to Verify"
require_text handoff/SKILL.md "**Skills.**"
require_text handoff/SKILL.md 'mkdir -p "$HANDOFF_DIR"'
require_text handoff/SKILL.md 'if [[ "$ARGUMENTS" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4}- ]]'
require_text handoff/SKILL.md "a write is complete when the document exists"
require_text _maintenance/handoff/PROVENANCE.md "## Deviations From Upstream"

bash -n _maintenance/handoff/sync-upstream.sh

if [[ "${HANDOFF_VERIFY_UPSTREAM:-0}" == "1" ]]; then
  sync_output="$(bash _maintenance/handoff/sync-upstream.sh)"
  require_text <(printf '%s\n' "$sync_output") "No upstream changes: harpb-handoff.md"
  require_text <(printf '%s\n' "$sync_output") "No upstream changes: mattpocock-SKILL.md"
fi
