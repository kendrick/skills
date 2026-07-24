#!/usr/bin/env bash
# Compare fresh upstream files without replacing local snapshots or deliberate merge choices.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
snapshot_dir="$script_dir/upstream"
temporary_dir="$(mktemp -d "${TMPDIR:-/tmp}/handoff-upstream.XXXXXX")"
trap 'rm -rf "$temporary_dir"' EXIT

harpb_url="https://gist.githubusercontent.com/harpb/3f4ff1899db04a0957c66634ca549292/raw/handoff.md"
mattpocock_url="https://raw.githubusercontent.com/mattpocock/skills/main/skills/productivity/handoff/SKILL.md"

fetch() {
  curl --fail --location --silent --show-error "$1" --output "$2"
}

compare() {
  local name="$1"
  local url="$2"
  local snapshot="$3"
  local fresh="$temporary_dir/$name"

  fetch "$url" "$fresh"
  if diff -u "$snapshot" "$fresh"; then
    printf 'No upstream changes: %s\n' "$name"
  else
    printf 'Upstream changed: %s\n' "$name" >&2
    return 1
  fi
}

status=0
compare harpb-handoff.md "$harpb_url" "$snapshot_dir/harpb-handoff.md" || status=1
compare mattpocock-SKILL.md "$mattpocock_url" "$snapshot_dir/mattpocock-SKILL.md" || status=1
exit "$status"
