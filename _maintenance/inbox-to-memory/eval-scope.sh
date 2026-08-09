#!/usr/bin/env bash
# Stage a private copy of an eval fixture for a single scenario run. Process
# mode empties _inbox/ and writes new notes into the scope it runs against,
# so a run against the committed fixture destroys it for every scenario
# after the first; the migration tests hold themselves to the same rule and
# say why beside the comment "The checked-in fixtures are never migrated or
# stamped in place." in tests/inbox-to-memory-smoke.sh. Each call mints its
# own scratch directory instead of reusing one, since the with-skill and
# without-skill runs of a scenario each need an unemptied _inbox/ to start
# from.
set -euo pipefail

usage() {
  echo "usage: ${0##*/} <fixture-name>" >&2
}

name="${1-}"
[[ -n "$name" ]] || {
  usage
  exit 2
}

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fixture="$root/tests/fixtures/inbox-to-memory/evals/$name"

if [[ ! -d "$fixture" ]]; then
  echo "no such eval fixture: $fixture" >&2
  exit 1
fi

staged="$(mktemp -d "${TMPDIR:-/tmp}/i2m-eval-scope.XXXXXX")"
cp -R "$fixture/." "$staged/"

echo "$staged"
