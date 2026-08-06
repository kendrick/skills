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

# Each planted defect has to name itself. A lint that reports "this file is bad"
# will keep reporting it after the cause changes, which is how a check quietly
# stops testing what its name claims.
require_failure() {
  local output="$1"
  local prefix="$2"
  grep -Fq -- "$prefix" <(printf '%s\n' "$output") || {
    echo "lint did not report the failure: $prefix" >&2
    printf '%s\n' "$output" >&2
    exit 1
  }
}

refute_failure() {
  local output="$1"
  local needle="$2"
  grep -F -- "$needle" <(printf '%s\n' "$output") | grep -q '^FAIL' && {
    echo "lint flagged something it should have left alone: $needle" >&2
    printf '%s\n' "$output" >&2
    exit 1
  }
  return 0
}

# The lint exits nonzero once it finds anything, so `set -e` would otherwise kill
# the run before the assertions about what it found.
run_lint() {
  bash "$lint" "$1" 2>&1 || true
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

old_only_out="$(run_lint "$fixtures/old-only")"
require_line "$old_only_out" "scope: $fixtures/old-only" old-only
require_line "$old_only_out" "v1 files: 4" old-only
require_line "$old_only_out" "v2 files: 0" old-only
require_line "$old_only_out" "total files: 4" old-only
require_line "$old_only_out" "failures: 0" old-only

mixed_out="$(run_lint "$fixtures/mixed")"
require_line "$mixed_out" "scope: $fixtures/mixed" mixed
require_line "$mixed_out" "v1 files: 3" mixed
require_line "$mixed_out" "v2 files: 2" mixed
require_line "$mixed_out" "total files: 5" mixed
require_line "$mixed_out" "failures: 0" mixed

# The v1 files in the mixed scope carry every shape the contract now forbids:
# block-style lists, a nested relationship mapping, no schema key. They are legal
# forever, so naming them here is the guard against the contract checks leaking
# onto the generation they were never written for.
for legacy in \
  2025-12-02-atlas-steerco-ZGulgExW0q.md \
  2026-01-13-atlas-cutover-readiness-JJuYgImRWn.md \
  freeze-window-owned-by-ops-ocPwdpeY0a.md; do
  refute_failure "$mixed_out" "$legacy"
done

# One defect per file, so a count is a meaningful assertion and a check that
# starts firing twice shows up as an arithmetic failure rather than a wash.
broken_out="$(run_lint "$fixtures/broken")"
require_line "$broken_out" "v1 files: 0" broken
require_line "$broken_out" "v2 files: 4" broken
require_line "$broken_out" "failures: 4" broken

if bash "$lint" "$fixtures/broken" >/dev/null 2>&1; then
  echo "lint exited zero on the broken fixture" >&2
  exit 1
fi

require_failure "$broken_out" "FAIL $fixtures/broken/notes/2026-03-01-block-style-list-G2WFweWKJf.md: frontmatter-single-line:"
require_failure "$broken_out" "FAIL $fixtures/broken/notes/2026-03-02-frontmatter-budget-kFtFA-Xh5P.md: frontmatter-budget:"
require_failure "$broken_out" "FAIL $fixtures/broken/notes/2026-03-03-key-order-fdTdMPSqFs.md: frontmatter-key-order:"
require_failure "$broken_out" "FAIL $fixtures/broken/notes/2026-03-04-unregistered-token-30z5F4kx6U.md: token-grammar:"

# Fail the block-style list and pass its inline-array equivalent, proved on the
# same file rather than on two files that differ in other ways too. Without the
# second half, a check that flagged every list whatsoever would look correct.
inline_scope="$(mktemp -d "${TMPDIR:-/tmp}/i2m-inline.XXXXXX")"
trap 'rm -rf "$not_a_scope" "$inline_scope"' EXIT
mkdir -p "$inline_scope/_inbox" "$inline_scope/_memory/decisions" "$inline_scope/notes"
awk '
  /^attendees:$/ { print "attendees: [Priya Raghavan, Marcus Dell]"; skip = 1; next }
  skip && /^  - / { next }
  { skip = 0; print }
' "$fixtures/broken/notes/2026-03-01-block-style-list-G2WFweWKJf.md" \
  >"$inline_scope/notes/2026-03-01-block-style-list-G2WFweWKJf.md"

inline_out="$(run_lint "$inline_scope")"
require_line "$inline_out" "v2 files: 1" inline-equivalent
require_line "$inline_out" "failures: 0" inline-equivalent

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

# Both key orders get pinned verbatim. They are duplicated by hand into the
# templates, the lint, and eventually the migrator, and the only thing keeping
# those three copies honest is that changing the order fails here first.
contracts=inbox-to-memory/references/machine-contracts.md
note_key_order="schema, id, date, type, summary, attendees, tags, topics, entities, source_file, transcript_corrections, open_questions, resolved_questions, deferred_tensions, unpromoted_candidates, related"
record_key_order="schema, id, memory_type, title, status, date, effective_from, effective_to, last_confirmed, source_refs, applies_to, owners, tags, themes, related, exception_to, supersedes, superseded_by"
require_file "$contracts"
require_text "$contracts" "$note_key_order"
require_text "$contracts" "$record_key_order"

# SKILL.md carries the same two strings verbatim rather than a paraphrase. A quick
# reference that drifts from the contract is worse than no quick reference: it is
# the copy an agent actually reads before writing a file.
require_text inbox-to-memory/SKILL.md "$note_key_order"
require_text inbox-to-memory/SKILL.md "$record_key_order"

# Twenty lines is what makes a header read a contract instead of a habit. It is
# the number every retrieval claim in the funnel doc rests on.
require_text "$contracts" "first 20 lines"

# Every token the skill emits needs a row with a grep. A token invented at the
# point of use is one nothing can find later, which is the whole failure the
# closed vocabulary exists to prevent.
for token in \
  "[memory candidate: project]" \
  "[memory candidate: client]" \
  "[memory candidate: update existing" \
  "[journal candidate:" \
  "[working-state candidate]" \
  "[contradicts accepted:" \
  "[open question:" \
  "[open question resolved:" \
  "[tension:"; do
  require_text "$contracts" "$token"
done

# The doc is reference material the skill reads on demand, so it has to be
# reachable from SKILL.md rather than sitting in the directory unmentioned.
require_text inbox-to-memory/SKILL.md "references/machine-contracts.md"

# Lint the shipped templates by standing them up as a scope. A template that
# doesn't satisfy the contract emits files that don't either, and the placeholders
# have to survive a YAML parse for that check to mean anything.
tpl_scope="$(mktemp -d "${TMPDIR:-/tmp}/i2m-templates.XXXXXX")"
trap 'rm -rf "$not_a_scope" "$inline_scope" "$tpl_scope"' EXIT
mkdir -p "$tpl_scope/_inbox" "$tpl_scope/_memory/decisions" "$tpl_scope/notes" "$tpl_scope/entries"
cp inbox-to-memory/assets/note.template.md "$tpl_scope/notes/"
for record in context decision exception policy-rule rule; do
  cp "inbox-to-memory/assets/records/$record.template.md" "$tpl_scope/_memory/decisions/"
done
cp inbox-to-memory/assets/records/journal-entry.template.md "$tpl_scope/entries/"

tpl_out="$(run_lint "$tpl_scope")"
require_line "$tpl_out" "v1 files: 0" templates
require_line "$tpl_out" "v2 files: 7" templates
require_line "$tpl_out" "failures: 0" templates

for template in inbox-to-memory/assets/note.template.md inbox-to-memory/assets/records/*.template.md; do
  require_text "$template" "schema: 2"
done

# Relationships and journal sources are flat compound strings now. The refutes are
# the load-bearing half: the nested forms are what v1 files carry, and a template
# that reintroduces one starts minting files no documented grep will match.
require_text inbox-to-memory/assets/note.template.md "related: [extends::"
refute_text inbox-to-memory/assets/note.template.md "note_id:"
require_text inbox-to-memory/assets/records/journal-entry.template.md "source_refs: ["
refute_text inbox-to-memory/assets/records/journal-entry.template.md "- scope:"

# The scaffolds document the shape the agent writes from, so they have to agree
# with the templates. A scaffold left behind teaches the old schema to every scope
# stood up after this, and those files would be born needing migration.
for scaffold in notes journal _memory; do
  require_text "inbox-to-memory/assets/claude-md/$scaffold.template.md" "schema: 2"
done
refute_text inbox-to-memory/assets/claude-md/journal.template.md "note_id: <nanoid>"

# yq arrives as a prerequisite here and gets consumed by the contract checks in
# #6. It is not installed by default anywhere, so the README has to say so next
# to nanoid or the first verify run fails for a confusing reason.
require_text inbox-to-memory/README.md "nanoid"
require_text inbox-to-memory/README.md "brew install yq"

echo "inbox-to-memory smoke: ok"
