#!/usr/bin/env bash
# Pin the inbox-to-memory lint's contract and the fixture scopes it runs against.
# This is the seam every later v2 ticket hangs off: each one plants a defect in a
# fixture and asserts the named failure here, so the shapes below are load-bearing
# well beyond what they currently check.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

lint=inbox-to-memory/scripts/lint-scope.sh
fixtures=tests/fixtures/inbox-to-memory

require_file() {
  [[ -f "$1" ]] || {
    echo "missing required file: $1" >&2
    exit 1
  }
}

require_dir() {
  [[ -d "$1" ]] || {
    echo "missing required directory: $1" >&2
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

require_line() {
  local output="$1"
  local line="$2"
  local label="$3"
  grep -Fqx -- "$line" <(printf '%s\n' "$output") || {
    echo "lint on $label did not report: $line" >&2
    printf '%s\n' "$output" >&2
    exit 1
  }
}

require_file "$lint"
[[ -x "$lint" ]] || {
  echo "$lint must be executable" >&2
  exit 1
}
bash -n "$lint"

require_dir "$fixtures/old-only"
require_dir "$fixtures/mixed"
require_dir "$fixtures/broken"

# Every fixture is a real opted-in scope. Pointing the lint at a directory the
# skill itself would refuse to touch is not a meaningful test of anything.
for scope in old-only mixed broken; do
  require_dir "$fixtures/$scope/_inbox"
  require_dir "$fixtures/$scope/_memory"
done

old_only_out="$(bash "$lint" "$fixtures/old-only")"
require_line "$old_only_out" "scope: $fixtures/old-only" old-only
require_line "$old_only_out" "v1 files: 4" old-only
require_line "$old_only_out" "v2 files: 0" old-only
require_line "$old_only_out" "total files: 4" old-only
require_line "$old_only_out" "failures: 0" old-only

mixed_out="$(bash "$lint" "$fixtures/mixed")"
require_line "$mixed_out" "scope: $fixtures/mixed" mixed
require_line "$mixed_out" "v1 files: 3" mixed
require_line "$mixed_out" "v2 files: 2" mixed
require_line "$mixed_out" "total files: 5" mixed
require_line "$mixed_out" "failures: 0" mixed

# No correctness checks land until #6, so the defect fixture is still clean. The
# ticket that plants the first defect flips this to a nonzero expectation.
broken_out="$(bash "$lint" "$fixtures/broken")"
require_line "$broken_out" "failures: 0" broken

# Classification reads one key and stops. The mixed fixture carries a note built
# to v2 shape in every respect except the schema key, and it has to come back v1
# anyway. Anything else means the lint is sniffing contents, which turns every
# compatibility promise into a bet on what old files happen to look like.
require_file "$fixtures/mixed/notes/2026-01-13-atlas-cutover-readiness-JJuYgImRWn.md"
refute_text "$fixtures/mixed/notes/2026-01-13-atlas-cutover-readiness-JJuYgImRWn.md" "schema:"
require_text "$fixtures/mixed/notes/2026-01-13-atlas-cutover-readiness-JJuYgImRWn.md" "tags: [cutover, readiness]"

# A directory with no opt-in markers is refused outright. Reporting it as an
# empty scope would let a mistyped path pass for a clean bill of health.
not_a_scope="$(mktemp -d "${TMPDIR:-/tmp}/i2m-not-a-scope.XXXXXX")"
trap 'rm -rf "$not_a_scope"' EXIT
if bash "$lint" "$not_a_scope" >/dev/null 2>&1; then
  echo "lint accepted a directory that is not an opted-in scope" >&2
  exit 1
fi

# The skill has to name the lint, or nothing invokes it in the field.
require_text inbox-to-memory/SKILL.md "scripts/lint-scope.sh"

# yq arrives as a prerequisite here and gets consumed by the contract checks in
# #6. It is not installed by default anywhere, so the README has to say so next
# to nanoid or the first verify run fails for a confusing reason.
require_text inbox-to-memory/README.md "nanoid"
require_text inbox-to-memory/README.md "brew install yq"

echo "inbox-to-memory smoke: ok"
