#!/usr/bin/env bash
# Walk one opted-in scope and report what generation each note and record is.
#
# This ships as a script rather than prose the agent follows because most of what
# the v2 schema promises is arithmetic: counts that have to match body tokens,
# deferred tensions that have to pair one-to-one with open questions. An agent
# asked to check that by reading will report success it never verified. Only the
# classification is implemented today, so nothing here can fail a file yet.
#
# Requires bash and awk. The frontmatter checks arriving next parse YAML with yq
# (brew install yq).
set -euo pipefail

usage() {
  echo "usage: ${0##*/} <scope-path>" >&2
  echo "  scope-path: a directory containing _inbox/ plus _memory/ or entries/" >&2
}

if [[ $# -ne 1 ]]; then
  usage
  exit 2
fi

# Trailing slashes would otherwise show up in the reported path and in every
# assertion written against it.
scope="${1%/}"

if [[ ! -d "$scope" ]]; then
  echo "not a directory: $scope" >&2
  exit 2
fi

# The skill refuses to touch anything that hasn't opted in, and so does its lint.
# Reporting an empty scope for a mistyped path would read as a clean bill of health.
if [[ ! -d "$scope/_inbox" ]] || { [[ ! -d "$scope/_memory" ]] && [[ ! -d "$scope/entries" ]]; }; then
  echo "not an opted-in scope: $scope (needs _inbox/ plus _memory/ or entries/)" >&2
  exit 2
fi

# The version discriminant is the presence of the `schema` key and nothing else.
# Inferring a generation from file contents would make every compatibility
# guarantee downstream rest on a guess about what old files happen to look like.
has_schema_key() {
  awk '
    NR == 1 { if ($0 == "---") { in_fm = 1; next } else { exit } }
    in_fm && $0 == "---" { exit }
    in_fm && /^schema:/ { found = 1; exit }
    END { exit (found ? 0 : 1) }
  ' "$1"
}

shopt -s nullglob

v1=0
v2=0
failures=0

# Only files the skill itself creates. CLAUDE.md and README.md live alongside them
# in the same directories and are hand-maintained, so they carry no schema key and
# would otherwise inflate the v1 count with files that can never be migrated.
for file in "$scope"/notes/*.md "$scope"/_memory/*/*.md "$scope"/entries/*.md; do
  case "${file##*/}" in
    CLAUDE.md | README.md) continue ;;
  esac
  if has_schema_key "$file"; then
    v2=$((v2 + 1))
  else
    v1=$((v1 + 1))
  fi
done

echo "scope: $scope"
echo "v1 files: $v1"
echo "v2 files: $v2"
echo "total files: $((v1 + v2))"
echo "failures: $failures"

[[ "$failures" -eq 0 ]]
