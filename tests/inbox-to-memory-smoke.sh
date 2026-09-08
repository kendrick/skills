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

# Same grep as require_failure, different claim. That one asserts a lint caught a
# planted defect; this one asserts a script reported what it did.
require_output() {
  local output="$1"
  local text="$2"
  grep -Fq -- "$text" <(printf '%s\n' "$output") || {
    echo "expected output not reported: $text" >&2
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
require_line "$mixed_out" "v2 files: 5" mixed
require_line "$mixed_out" "total files: 8" mixed
require_line "$mixed_out" "failures: 0" mixed

# A question open across three notes is a finding about the engagement, not a
# defect in a file, so recurrence reports without failing. Both chains in the
# mixed scope are three deep and neither one may push the failure count off zero.
require_line "$mixed_out" "RECURRING rollback-execution-owner: open in 3 notes" mixed
require_line "$mixed_out" "RECURRING dry-run-date: open in 3 notes" mixed

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
# starts firing twice shows up as an arithmetic failure rather than a wash. The
# arithmetic still lands one short of the file count: vendor-lock-window is
# link bait for the contradiction check and stays clean; every other v2 file
# here, including the new tags/themes record, carries exactly one planted
# defect.
broken_out="$(run_lint "$fixtures/broken")"
require_line "$broken_out" "v1 files: 0" broken
require_line "$broken_out" "v2 files: 20" broken
require_line "$broken_out" "failures: 19" broken

if bash "$lint" "$fixtures/broken" >/dev/null 2>&1; then
  echo "lint exited zero on the broken fixture" >&2
  exit 1
fi

require_failure "$broken_out" "FAIL $fixtures/broken/notes/2026-03-01-block-style-list-G2WFweWKJf.md: frontmatter-single-line:"
require_failure "$broken_out" "FAIL $fixtures/broken/notes/2026-03-02-frontmatter-budget-kFtFA-Xh5P.md: frontmatter-budget:"
require_failure "$broken_out" "FAIL $fixtures/broken/notes/2026-03-03-key-order-fdTdMPSqFs.md: frontmatter-key-order:"
require_failure "$broken_out" "FAIL $fixtures/broken/notes/2026-03-04-unregistered-token-30z5F4kx6U.md: token-grammar:"
require_failure "$broken_out" "FAIL $fixtures/broken/notes/2026-03-05-open-question-fields-8ddZbhkxqw.md: open-question-fields:"
require_failure "$broken_out" "FAIL $fixtures/broken/notes/2026-03-06-deferred-tension-unpaired-oKZJNnBgR5.md: tension-deferred-pairing:"
require_failure "$broken_out" "FAIL $fixtures/broken/notes/2026-03-07-deferred-tension-double-claim-tTwfMfnuen.md: tension-deferred-pairing:"
require_failure "$broken_out" "FAIL $fixtures/broken/notes/2026-03-08-count-mismatch-NpLIlvzOGE.md: derived-counts:"
require_failure "$broken_out" "FAIL $fixtures/broken/notes/2026-03-09-missing-count-key-w8I9DG6qae.md: derived-counts:"
require_failure "$broken_out" "FAIL $fixtures/broken/notes/2026-03-10-orphan-resolution-Fb7y8W-jW6.md: open-question-resolution:"
require_failure "$broken_out" "FAIL $fixtures/broken/notes/2026-03-11-tension-missing-stakes-diU2GZ1m5r.md: tension-fields:"
require_failure "$broken_out" "FAIL $fixtures/broken/notes/2026-03-12-tension-bad-disposition-GAQIZYiAjU.md: tension-fields:"
require_failure "$broken_out" "FAIL $fixtures/broken/notes/2026-03-13-decision-no-alternatives-lHfh6YSmjI.md: decision-fields:"
require_failure "$broken_out" "FAIL $fixtures/broken/notes/2026-03-14-bare-line-anchor-oKaK8iH1B0.md: anchor-form:"
require_failure "$broken_out" "FAIL $fixtures/broken/notes/2026-03-15-multiline-summary-gcnwRBmRy_.md: frontmatter-single-line:"
require_failure "$broken_out" "FAIL $fixtures/broken/notes/2026-03-16-decision-bad-reversibility-w-6dqoA-ky.md: decision-fields:"
require_failure "$broken_out" "FAIL $fixtures/broken/notes/2026-03-18-contradiction-no-claims-19UymDD7Rt.md: contradiction-fields:"
require_failure "$broken_out" "FAIL $fixtures/broken/_memory/decisions/tags-themes-mixup-9YpQ2xLmZk.md: frontmatter-key-domain:"

# The record the flag points at is clean. Asserting that here is what keeps the
# link bait from quietly becoming a twentieth defect nobody planted.
refute_failure "$broken_out" "vendor-lock-window-WJicoHVdFw.md"

# The file that motivated this check: every RECORD_KEY_ORDER key populated,
# tags and themes both included, with the block closing on line 21, one line
# past the budget. check_frontmatter returns at the first fail() it hits, so
# the mixup has to win that race, or the 21-line record this check exists for
# keeps reporting frontmatter-budget instead.
overrun_scope="$(mktemp -d "${TMPDIR:-/tmp}/i2m-overrun.XXXXXX")"
trap 'rm -rf "$overrun_scope"' EXIT
mkdir -p "$overrun_scope/_inbox" "$overrun_scope/_memory/decisions"
overrun_file="$overrun_scope/_memory/decisions/tags-and-themes-both-populated-Kx3fQ7pRtN.md"
cat >"$overrun_file" <<'EOF'
---
schema: 2
body_schema: 1
id: Kx3fQ7pRtN
memory_type: Decision
title: 'A record with every RECORD_KEY_ORDER key populated'
status: accepted
date: 2026-02-22
effective_from: 2026-02-22
effective_to: null
last_confirmed: 2026-02-22
source_refs: [oKZJNnBgR5]
applies_to: [vendor-selection]
owners: [Marcus Dell]
tags: [vendor]
themes: [vendor-strategy]
related: []
exception_to: null
supersedes: null
superseded_by: null
---

Body content is irrelevant here; this file's frontmatter is the reproduction from the issue.
EOF

overrun_out="$(run_lint "$overrun_scope")"
require_line "$overrun_out" "v2 files: 1" overrun-record
require_line "$overrun_out" "failures: 1" overrun-record
require_failure "$overrun_out" "FAIL $overrun_file: frontmatter-key-domain: carries both \`tags\` and \`themes\`"
refute_failure "$overrun_out" "frontmatter-budget"

# V1 notes anchor to bare line numbers everywhere, and that has to stay legal. The
# check keys off the schema, never off the shape of the reference.
refute_failure "$old_only_out" "anchor-form"

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

# Both ends of the contradiction round-trip have to be legal in a passing scope:
# the amendment that became a wiki link, and the dismissal that kept its flag. The
# dismissed one is the assertion that matters. A flag deleted on dismissal takes
# with it the only evidence anyone ever looked.
round_trip="$fixtures/mixed/notes/2026-02-17-atlas-freeze-exceptions-SDy5SGVwfu.md"
require_file "$round_trip"
refute_failure "$mixed_out" "2026-02-17-atlas-freeze-exceptions-SDy5SGVwfu.md"
require_text "$round_trip" "| dismissed:"
require_text "$round_trip" "|memory — updated]]"

# The count reads the dismissal, not the prefix. Strip the field and the same note
# has two outstanding contradictions instead of one, which is what proves the rule
# is doing the work rather than the arithmetic happening to line up.
dismissal_scope="$(mktemp -d "${TMPDIR:-/tmp}/i2m-dismissal.XXXXXX")"
trap 'rm -rf "$not_a_scope" "$inline_scope" "$dismissal_scope"' EXIT
cp -R "$fixtures/mixed/." "$dismissal_scope/"
stripped="$dismissal_scope/notes/2026-02-17-atlas-freeze-exceptions-SDy5SGVwfu.md"
sed 's/ | dismissed: [^|]*$//' "$round_trip" >"$stripped"
dismissal_out="$(run_lint "$dismissal_scope")"
require_failure "$dismissal_out" "derived-counts: \`unpromoted_candidates\` says 1, body has 2"

# Phase 2.5 can only hold to five body reads per input if the scope it runs over
# has records to spare. This is the fixture-side half of that promise: the budget
# itself is a property of an agent run and nothing here can assert it.
mixed_records="$(find "$fixtures/mixed/_memory" -name '*.md' | wc -l | tr -d ' ')"
[[ "$mixed_records" -le 5 ]] || {
  echo "the mixed fixture holds $mixed_records records; phase 2.5 budgets five body reads per input" >&2
  exit 1
}

# A directory with no opt-in markers is refused outright. Reporting it as an
# empty scope would let a mistyped path pass for a clean bill of health.
not_a_scope="$(mktemp -d "${TMPDIR:-/tmp}/i2m-not-a-scope.XXXXXX")"
trap 'rm -rf "$not_a_scope"' EXIT
if bash "$lint" "$not_a_scope" >/dev/null 2>&1; then
  echo "lint accepted a directory that is not an opted-in scope" >&2
  exit 1
fi

# Scaffold mode puts the queue under notes/ for client and project scopes, so a
# scope shaped that way has to lint like any other. Every other fixture here is
# flat, and that uniformity is exactly what hid the guard's assumption that the
# queue sits at the scope root: it rejected every scaffolded vault in the field
# while this suite stayed green.
require_dir "$fixtures/scaffold-layout/notes/_inbox"
require_dir "$fixtures/scaffold-layout/_memory"
scaffold_out="$(run_lint "$fixtures/scaffold-layout")"
require_line "$scaffold_out" "scope: $fixtures/scaffold-layout" scaffold-layout
require_line "$scaffold_out" "v1 files: 2" scaffold-layout
require_line "$scaffold_out" "failures: 0" scaffold-layout

# The queue is looked for at the scope root and one level down, never by depth.
# A client root owns the directories its projects sit in but not their queues,
# so finding one below itself must not opt it in. Nested inside the temp dir
# above so it rides that cleanup rather than adding a second EXIT trap.
nested_root="$not_a_scope/client-with-nested-project"
mkdir -p "$nested_root/_memory" "$nested_root/projects/p1/_inbox" "$nested_root/projects/p1/_memory"
if bash "$lint" "$nested_root" >/dev/null 2>&1; then
  echo "lint opted a client root in on a queue belonging to a project beneath it" >&2
  exit 1
fi

# The skill has to name the scripts it runs, or nothing invokes them in the field.
require_text inbox-to-memory/SKILL.md "scripts/lint-scope.sh"
require_text inbox-to-memory/SKILL.md "scripts/stamp-confirmed.sh"

# Scaffold mode has to name the script it runs to stamp a minted file, because
# an agent that hand-computes the hash instead is the exact drift this key
# exists to catch.
require_text inbox-to-memory/SKILL.md "scripts/scaffold_digest.py --stamp"

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

# The facet shape <facet>::<value> is optional; nothing enforces it in lint or
# templates, so this doc is the only place the convention lives. Lose it here and
# the practice silently evaporates.
require_text "$contracts" '<facet>::<value>'
require_text "$contracts" 'applies_to: [regions::emea, systems::billing, topics::invoice-disputes]'

# Lint the shipped templates by standing them up as a scope. A template that
# doesn't satisfy the contract emits files that don't either, and the placeholders
# have to survive a YAML parse for that check to mean anything.
tpl_scope="$(mktemp -d "${TMPDIR:-/tmp}/i2m-templates.XXXXXX")"
trap 'rm -rf "$not_a_scope" "$inline_scope" "$dismissal_scope" "$tpl_scope"' EXIT
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

# ---------------------------------------------------------------------------
# Scaffold digest (#58)
# ---------------------------------------------------------------------------

# scaffold_digest.py refuses a file with no frontmatter block (exit 2), so a
# template that loses its opening fence or its scaffold_digest key silently
# stops being stampable, and scaffold mode would mint files nothing can verify.
scaffold_templates=(
  inbox-to-memory/assets/claude-md/client.template.md
  inbox-to-memory/assets/claude-md/project.template.md
  inbox-to-memory/assets/claude-md/notes.template.md
  inbox-to-memory/assets/claude-md/_memory.template.md
  inbox-to-memory/assets/claude-md/patterns-journal.template.md
  inbox-to-memory/assets/claude-md/journal.template.md
  inbox-to-memory/assets/readme/client.template.md
  inbox-to-memory/assets/readme/project.template.md
  inbox-to-memory/assets/readme/notes.template.md
  inbox-to-memory/assets/readme/_memory.template.md
  inbox-to-memory/assets/personal.template.md
  inbox-to-memory/assets/working-state.template.md
  inbox-to-memory/assets/patterns-journal/journal.template.md
)
for template in "${scaffold_templates[@]}"; do
  require_file "$template"
  [[ "$(head -n1 "$template")" == "---" ]] || {
    echo "$template does not open on a bare --- frontmatter fence" >&2
    exit 1
  }
  require_text "$template" "scaffold_digest:"
done

# Stand the templates up as a real scope, the same move #6 makes for
# note.template.md and the record templates, but for the CLAUDE.md/README
# scaffolds and the placeholders scaffold mode substitutes into them.
digest_script=inbox-to-memory/scripts/scaffold_digest.py
require_file "$digest_script"

# One substitution table for placeholders that don't vary by memory mode, and
# two more for the ones that do. Slashes inside a replacement value are
# sed-escaped, since the substitutions themselves are sed programs.
scaffold_subs_common=(
  's/{{ClientName}}/Riverton Analytics/g'
  's/{{ProjectName}}/Atlas Cutover/g'
  's/{{ScopeName}}/Riverton Analytics/g'
  's/{{Pursuit|Project}}/Project/g'
  's/{{pursuit|project}}/project/g'
  's/{{pursuits|projects}}/projects/g'
  's/{{NOTE_TYPE_ENUM}}/scoping-call | working-session | stakeholder-call | internal | reading | braindump | transcript | status/g'
  's/{{stakeholder-list}}/<!-- Fill in: stakeholder-list -->/g'
  's/{{tag-list}}/<!-- Fill in: tag-list -->/g'
  's/{{engagement-list}}/<!-- Fill in: engagement-list -->/g'
  's/{{type-enum-values}}/<!-- Fill in: type-enum-values -->/g'
  's/{{one-sentence-project-description}}/A cutover project for Riverton Analytics./g'
  's/{{date}}/2026-08-31/g'
  's/{{MEMORY_TYPE_LIST}}/- Decision -- a decision made and its discarded alternatives./g'
  's/{{MEMORY_TYPE_SUMMARY}}/Decisions, Context, and Rules, one record per file./g'
)
scaffold_subs_lightweight=(
  's/{{MEMORY_MODE}}/lightweight/g'
  's/{{MEMORY_TYPES}}/Decision, Context, Rule/g'
  's/{{MEMORY_TYPE_ENUM}}/Decision | Context | Rule/g'
  's/{{MEMORY_TYPE_FOLDERS}}/decisions\/, context\/, rules\//g'
  's/{{RULES_FOLDER}}/rules/g'
)
scaffold_subs_canonical=(
  's/{{MEMORY_MODE}}/canonical/g'
  's/{{MEMORY_TYPES}}/Decision, PolicyRule, Exception, Context/g'
  's/{{MEMORY_TYPE_ENUM}}/Decision | PolicyRule | Exception | Context/g'
  's/{{MEMORY_TYPE_FOLDERS}}/decisions\/, policy-rules\/, exceptions\/, context\//g'
  's/{{RULES_FOLDER}}/policy-rules/g'
)

apply_scaffold_subs() {
  local src="$1" dest="$2"
  shift 2
  local sed_args=()
  for expr in "${scaffold_subs_common[@]}" "$@"; do
    sed_args+=(-e "$expr")
  done
  sed "${sed_args[@]}" "$src" >"$dest"
}

sd_scope="$(mktemp -d "${TMPDIR:-/tmp}/i2m-scaffold-digest.XXXXXX")"
trap 'rm -rf "$not_a_scope" "$inline_scope" "$dismissal_scope" "$tpl_scope" "$sd_scope"' EXIT
sd_files=()
for template in "${scaffold_templates[@]}"; do
  rel="${template#inbox-to-memory/assets/}"
  dest="$sd_scope/${rel//\//_}"
  apply_scaffold_subs "$template" "$dest" "${scaffold_subs_lightweight[@]}"
  sd_files+=("$dest")
done

# A substituted scaffold has to stamp and then check clean: scaffold mode's
# own output is self-consistent at birth, which is the whole reason --stamp
# runs at mint time instead of leaving the key for a human to fill in.
python3 "$digest_script" --stamp "${sd_files[@]}" >/dev/null || {
  echo "scaffold_digest.py --stamp failed against a freshly substituted template set" >&2
  exit 1
}
python3 "$digest_script" --check "${sd_files[@]}" >/dev/null || {
  echo "scaffold_digest.py --check rejected templates it had just stamped" >&2
  exit 1
}

# The digest has to actually discriminate, or a check that passes no matter
# what would silence the whole mechanism -- the same reasoning
# tests/jd-file-overview-smoke.sh:8-15 gives for the Overview scaffold.
printf '\nan edit nobody stamped\n' >>"${sd_files[0]}"
if python3 "$digest_script" --check "${sd_files[0]}" >/dev/null 2>&1; then
  echo "scaffold_digest.py --check passed against ${sd_files[0]} after an unstamped edit" >&2
  exit 1
fi

# The memory mode lives in the substituted body, not the frontmatter, so the
# two modes have to be distinguishable by digest alone -- that's the
# mechanism behind the canonical-mode acceptance criterion.
mem_template=inbox-to-memory/assets/claude-md/_memory.template.md
mem_light="$sd_scope/_memory-lightweight.md"
mem_canonical="$sd_scope/_memory-canonical.md"
apply_scaffold_subs "$mem_template" "$mem_light" "${scaffold_subs_lightweight[@]}"
apply_scaffold_subs "$mem_template" "$mem_canonical" "${scaffold_subs_canonical[@]}"
python3 "$digest_script" --stamp "$mem_light" "$mem_canonical" >/dev/null

light_digest="$(grep '^scaffold_digest:' "$mem_light")"
canonical_digest="$(grep '^scaffold_digest:' "$mem_canonical")"
[[ "$light_digest" != "$canonical_digest" ]] || {
  echo "lightweight and canonical substitutions of _memory.template.md stamped the same digest" >&2
  exit 1
}

# The counts are the one exception to omit-if-empty, and the reason has to travel
# with the rule. Without it someone reads four always-present keys as redundant
# and starts omitting the zeros, which is exactly what breaks the query.
require_text "$contracts" "explicit exception to omit-if-empty"
require_text "$contracts" "**Absent is not zero.**"

# Never filling a missing field in is the whole design of the open-question
# contract. A fabricated resolver sends someone to chase a person who was never
# going to answer, which costs more than the admitted gap.
require_text "$contracts" "A missing field is reported and never filled in."

# Phrasing is judgment the lint can't reach, so it has to be taught in prose.
heuristics=inbox-to-memory/references/extraction-heuristics.md
require_text "$heuristics" "an answerable question, not a topic"
require_text "$heuristics" "unacknowledged"

# Prior notes are a record of what was known that day. Rewriting them to reflect a
# later answer is the convenience most likely to get added back, and it destroys
# the only thing the note was good for.
require_text inbox-to-memory/SKILL.md "Process mode never edits a prior note."

# The note template has to carry the field shapes, or the agent writes tokens the
# lint rejects and learns the contract by failing.
require_text inbox-to-memory/assets/note.template.md "[open question: <slug>]"
require_text inbox-to-memory/assets/note.template.md "[tension: deferred]"
require_text inbox-to-memory/assets/note.template.md "[decision: two-way]"

# The Decisions section sits after Tensions. A decision that lands before the
# disagreement that produced it reads as though there was never a disagreement.
[[ "$(grep -n '^## Tensions' inbox-to-memory/assets/note.template.md | cut -d: -f1)" \
   -lt "$(grep -n '^## Decisions' inbox-to-memory/assets/note.template.md | cut -d: -f1)" ]] || {
  echo "the Decisions section must sit after Tensions in the note template" >&2
  exit 1
}

# Discarded alternatives are the payload, and reversibility is what says whether a
# decision is worth reopening. Both have to be taught, not just accepted.
require_text "$contracts" "The discarded alternatives are a decision's payload."
require_text "$heuristics" "A decision that is still hedged does not belong here."
require_text "$heuristics" "working-state"

# Anchors survive a reflow only if the snippet is authoritative.
require_text "$contracts" "The snippet is authoritative and the line number is a convenience."

# The alias table generalizes the old mapping without stranding scopes that were
# scaffolded under the old heading, and normalization stops at raw content.
for scope_template in client project; do
  require_text "inbox-to-memory/assets/claude-md/$scope_template.template.md" "### Alias Table"
  require_text "inbox-to-memory/assets/claude-md/$scope_template.template.md" " <- ["
done
require_text inbox-to-memory/SKILL.md "### Transcription-error mapping"
require_text inbox-to-memory/SKILL.md "**Extracted sections only.** Never rewrite raw content."

# The key name is frozen for grep compatibility with v1 notes, whatever the
# section it reads from is called now.
require_text inbox-to-memory/SKILL.md "transcript_corrections:"

# Entities exist so one grep finds every note touching a person or system, which
# fails the moment the same person appears under three spellings.
require_text inbox-to-memory/SKILL.md "canonical forms only, never the variants"

# The read boundary has to land in all three places an agent might learn it: the
# operating rules it reads first, the scaffold a scope teaches from, and the funnel
# stage where the cost actually gets paid.
funnel=inbox-to-memory/references/retrieval-funnel.md
require_text inbox-to-memory/SKILL.md "Stop at \`## Raw Content\`."
require_text inbox-to-memory/assets/claude-md/notes.template.md "stop at \`## Raw Content\`"
require_text "$funnel" "**Stop at \`## Raw Content\`.**"
require_text "$funnel" "## Stage 4 — Read Full Body"

require_text inbox-to-memory/SKILL.md "Never rename, resolve by id."
require_text "$funnel" "## Links Resolve by ID"

# A grep that matches one generation returns half an answer and looks like a whole
# one, so every documented query says which files it reaches.
awk '
  /^[[:space:]]*#/ { block = block " " $0; next }
  /^[[:space:]]*grep / {
    if (block !~ /generation/ && block !~ /v1/ && block !~ /v2/) {
      print "grep with no compatibility note on line " NR ": " $0
      bad = 1
    }
    # Consume the block. Without this, one annotated grep vouches for every
    # unannotated grep that follows it.
    block = ""
    next
  }
  /^[[:space:]]*$/ { next }
  { block = "" }
  END { exit bad }
' "$funnel" || {
  echo "every grep in the funnel doc needs a v1/v2 compatibility note above it" >&2
  exit 1
}

# Run the documented index emitter rather than a paraphrase of it. A one-liner
# nobody executes is a one-liner that stopped working two refactors ago.
index_cmd="$(awk '/^## Materializing an Index/ { f = 1 } f && /^```bash$/ { c = 1; next } c && /^```$/ { exit } c' "$funnel")"
[[ -n "$index_cmd" ]] || {
  echo "could not extract the index one-liner from $funnel" >&2
  exit 1
}
case "$index_cmd" in
  *yq* | *python* | *jq* | *perl*)
    echo "the index emitter must need nothing beyond awk and grep" >&2
    exit 1
    ;;
esac

index_out="$(cd "$fixtures/mixed" && eval "$index_cmd")"
[[ "$(printf '%s\n' "$index_out" | wc -l | tr -d ' ')" == "2" ]] || {
  echo "index emitter should produce one row per record in the mixed scope" >&2
  printf '%s\n' "$index_out" >&2
  exit 1
}
require_text <(printf '%s\n' "$index_out") "mPmy8XBe5H"
require_text <(printf '%s\n' "$index_out") "ocPwdpeY0a"

# The v1 record has no last_confirmed, and the column has to come back empty
# rather than absent. An empty cell is what makes the ones with nothing to reason
# about visible in the output.
v1_row="$(printf '%s\n' "$index_out" | grep ocPwdpeY0a)"
[[ "$(printf '%s' "$v1_row" | cut -f5)" == "" ]] || {
  echo "v1 record should emit an empty last_confirmed cell, got: $v1_row" >&2
  exit 1
}
v2_row="$(printf '%s\n' "$index_out" | grep mPmy8XBe5H)"
[[ "$(printf '%s' "$v2_row" | cut -f5)" == "2026-02-10" ]] || {
  echo "v2 record should carry its last_confirmed date, got: $v2_row" >&2
  exit 1
}

# No index file in a memory directory, in any form, under any name. The on-demand
# emitter exists specifically so this stays true, and it is the convenience most
# likely to get added back by someone who finds globbing tedious.
require_text inbox-to-memory/SKILL.md "No \`MEMORY.md\` or \`INDEX.md\` summary file"
if find "$fixtures" -path '*_memory*' \( -name 'MEMORY.md' -o -name 'INDEX.md' -o -name 'index.md' \) | grep -q .; then
  echo "an index file landed in a fixture memory directory" >&2
  exit 1
fi

# VTT collapsing is the one sanctioned exception to verbatim raw content, so it
# ships as something runnable rather than a description of what to do by hand.
vtt=inbox-to-memory/scripts/collapse-vtt.sh
require_file "$vtt"
bash -n "$vtt"
require_text inbox-to-memory/SKILL.md "one sanctioned exception to preserving raw content"
collapsed="$(bash "$vtt" "$fixtures/steerco-excerpt.vtt")"
[[ "$(printf '%s\n' "$collapsed" | wc -l | tr -d ' ')" == "5" ]] || {
  echo "six cues from three speakers' turns should collapse to three turns separated by blank lines" >&2
  printf '%s\n' "$collapsed" >&2
  exit 1
}
# One blank line after every turn, the last included: a turn is a markdown
# paragraph, and a single newline renders the whole transcript as one (#48).
[[ "$(bash "$vtt" "$fixtures/steerco-excerpt.vtt" | grep -c '^$')" == "3" ]] || {
  echo "each collapsed turn should be followed by a blank line" >&2
  exit 1
}
require_line "$collapsed" "[00:00:01] Priya Raghavan: Cutover is a date, not a readiness state, and that is the problem." vtt
require_line "$collapsed" "[00:00:06] Marcus Dell: Finance gave us a date. It is in writing. That one is done." vtt
# The last turn exercises the other speaker form and a continuation line with no
# speaker of its own, which is where a naive collapser drops half a sentence.
require_line "$collapsed" "[00:00:11] Priya Raghavan: Third meeting, same question, still nobody's name on it." vtt

# NOTE, STYLE, and REGION each run from their keyword to the next blank line,
# and none of that body is speech. Skipping only the opening line left every
# later line reading as a continuation of the open turn, so an editor's comment
# came back out as words a named person said at a stated time, inside the zone
# the skill calls the source of truth, after phase 4 deleted the original (#85).
# The fixture puts a block in all three positions one can occupy: before the
# first cue, between two cues, and after the last.
blocks="$(bash "$vtt" "$fixtures/blocks.vtt")"
[[ "$(printf '%s\n' "$blocks" | wc -l | tr -d ' ')" == "3" ]] || {
  echo "two cues separated by comment blocks should collapse to two turns" >&2
  printf '%s\n' "$blocks" >&2
  exit 1
}
require_line "$blocks" "[00:00:01] Dan: Okay, the export times out on large reports and marketing keeps asking about it." blocks
require_line "$blocks" "[00:00:20] Kendrick: Right, and that work depends on the query layer landing first." blocks

# Every block body, by a distinctive string from each position, plus the two
# keywords that were never skipped at all and the header line that matches the
# `Name: ` speaker form.
for swallowed in \
  "reviewed by legal" \
  "a block runs until the blank" \
  "single-line comment" \
  "Trailing commentary" \
  "::cue" \
  "STYLE" \
  "REGION" \
  "Kind"; do
  refute_text <(printf '%s\n' "$blocks") "$swallowed"
done

# The rule that skipped a block by its first line only. Pinning its absence is
# what stops the one-line form from looking like a tidy simplification later.
refute_text "$vtt" "/^NOTE/ { next }"

# A cue identifier is recognized by where it sits, one line above the timing
# line, because position is all the spec guarantees. The old rule matched a bare
# integer, which covered the hand-numbered fixture above and nothing else, so a
# Teams or Zoom export keyed by <uuid>/<n>-<n> carried its identifier into the
# turn text of every cue. Exit 0, turn-shaped output, and a note that read as
# correct everywhere the retrieval funnel tells a reader to look (#78).
teams="$(bash "$vtt" "$fixtures/teams-export.vtt")"
[[ "$(printf '%s\n' "$teams" | wc -l | tr -d ' ')" == "3" ]] || {
  echo "four uuid-keyed cues across two speakers should collapse to two turns" >&2
  printf '%s\n' "$teams" >&2
  exit 1
}
require_line "$teams" "[00:00:03] Kendrick M. Arnett: So with so much of the team out tomorrow, plan for the rest of the stand-ups today." teams-export
refute_text <(printf '%s\n' "$teams") "f9a822e4"

# The last cue is a line reading only `42`, which is what the deleted rule
# matched. Nothing follows it, so it is speech and has to survive as speech,
# the reason the fix reads position rather than widening the pattern.
require_line "$teams" "[00:00:15] Priya Raghavan: Fine by me. How many people are we down? 42" teams-export

# The pattern itself, gone rather than widened. Widening it is the obvious fix
# and it only buys whichever identifier format someone thought of that day.
refute_text "$vtt" "/^[0-9]+$/ { next }"

# steerco-excerpt.vtt is the regression baseline for this change: its cues are
# numbered 1 through 6, the shape the old rule handled, and the three
# require_line calls plus the two counts above pin its output whole. No golden
# file, because a fixture small enough to read is a better assertion than a diff.

# A caption file carrying no speaker labels anywhere, which is what most
# machine-generated transcripts look like, produced nothing at all and exited 0.
# An unlabelled line inherited the empty speaker, flush() prints only when a
# speaker is set, and phase 4 then deleted the source on the stated grounds that
# the raw zone had preserved it. Empty note, deleted original, silent run (#84).
# The non-empty check is the one that fails if that comes back.
speakerless="$(bash "$vtt" "$fixtures/speakerless.vtt")"
[[ -n "$speakerless" ]] || {
  echo "a VTT with no speaker labels collapsed to nothing" >&2
  exit 1
}
[[ "$(printf '%s\n' "$speakerless" | wc -l | tr -d ' ')" == "7" ]] || {
  echo "four unlabelled cues should collapse to four turns, one per cue" >&2
  printf '%s\n' "$speakerless" >&2
  exit 1
}

# One turn per cue, each keeping its own timestamp. Merging them the way a
# labelled turn merges its continuations would leave the first cue's clock
# standing for a whole meeting, and every quote after it unlocatable.
require_line "$speakerless" "[00:00:01] @unknown: Okay, so the export times out on large reports and marketing keeps asking about it." speakerless
require_line "$speakerless" "[00:00:22] @unknown: 42" speakerless
require_line "$speakerless" "[00:00:25] @unknown: That is the number of reports over the threshold, if anyone is counting." speakerless

# Two physical lines under one cue are one utterance and still merge, which is
# what repairs a sentence the captioner split. The cue is the boundary here, not
# the line.
require_line "$speakerless" "[00:00:12] @unknown: Right, and that work depends on the query layer landing first before anything else can start." speakerless

# The label is the skill's own token for a person nobody named, so a reader
# meets the same word here and in an open question's resolver field. A name
# inferred from a neighbouring turn would be a fabrication that reads exactly
# like a fact.
require_text "$vtt" '@unknown'
require_text inbox-to-memory/SKILL.md '@unknown'
require_text inbox-to-memory/assets/note.template.md '@unknown is a true answer'

# reflow-raw.sh recognizes a collapsed zone by its turn lines, so the @unknown
# label has to satisfy that same shape or a speakerless note stops reflowing.
printf '%s\n' "$speakerless" | grep -qE '^\[[0-9][0-9]?:[0-9][0-9](:[0-9][0-9])?\] [^:]+: ' || {
  echo "an @unknown turn does not match the turn shape reflow-raw.sh looks for" >&2
  exit 1
}

# WebVTT permits a CRLF terminator and Windows tooling emits one. awk splits on
# the newline alone, so the carriage return rides along on every record and each
# rule reads a line one invisible character longer than it looks. `WEBVTT\r`
# missed the block opener, which put the header in a turn of its own and stopped
# the block skip working, so a NOTE body reached a speaker turn on exactly the
# input #85 was filed about while this suite stayed green on its LF fixtures.
#
# Generated here rather than checked in: a fixture whose whole point is its line
# endings is one `git config` away from being normalized into an LF file that
# asserts nothing.
crlf_dir="$(mktemp -d "${TMPDIR:-/tmp}/i2m-crlf.XXXXXX")"
trap 'rm -rf "$not_a_scope" "$inline_scope" "$dismissal_scope" "$crlf_dir"' EXIT
for f in blocks teams-export speakerless steerco-excerpt; do
  sed 's/$/\r/' "$fixtures/$f.vtt" >"$crlf_dir/$f.vtt"
done

# Same bytes out of a CRLF file as out of its LF twin. This is the assertion that
# matters: it holds every fixture above to the CRLF path without restating one of
# their expected turns, so a new fixture is covered by both the moment it lands.
for f in blocks teams-export speakerless steerco-excerpt; do
  diff <(bash "$vtt" "$fixtures/$f.vtt") <(bash "$vtt" "$crlf_dir/$f.vtt") >/dev/null || {
    echo "$f.vtt collapses differently with CRLF line endings than with LF" >&2
    diff <(bash "$vtt" "$fixtures/$f.vtt") <(bash "$vtt" "$crlf_dir/$f.vtt") >&2
    exit 1
  }
done

# No carriage return survives into the output. It rode into turn text long before
# the block rules were touched, so this pins the older half of the same defect.
for f in blocks speakerless; do
  bash "$vtt" "$crlf_dir/$f.vtt" | grep -q $'\r' && {
    echo "a carriage return survived into the collapsed output of $f.vtt" >&2
    exit 1
  }
done

# A UTF-8 byte-order mark is a legal, optional start to a WebVTT file. It sits
# in front of the signature, so the first record matches no rule and the
# @unknown fallback signs a name to it: `[] @unknown: <BOM>WEBVTT` ahead of the
# real transcript. Generated here for the same reason the CRLF copies are, and
# because a checked-in file whose first three bytes carry the assertion is one
# well-meaning editor save away from losing them.
bom_dir="$(mktemp -d "${TMPDIR:-/tmp}/i2m-bom.XXXXXX")"
trap 'rm -rf "$not_a_scope" "$inline_scope" "$dismissal_scope" "$crlf_dir" "$bom_dir"' EXIT
for f in blocks speakerless steerco-excerpt; do
  printf '\357\273\277' >"$bom_dir/$f.vtt"
  /bin/cat "$fixtures/$f.vtt" >>"$bom_dir/$f.vtt"
done
for f in blocks speakerless steerco-excerpt; do
  diff <(bash "$vtt" "$fixtures/$f.vtt") <(bash "$vtt" "$bom_dir/$f.vtt") >/dev/null || {
    echo "$f.vtt collapses differently when it opens with a byte-order mark" >&2
    diff <(bash "$vtt" "$fixtures/$f.vtt") <(bash "$vtt" "$bom_dir/$f.vtt") >&2
    exit 1
  }
done

# Both review findings were one shape: a preamble line the rules failed to
# classify, handed a speaker by the @unknown fallback. WebVTT allows no speech
# above the first timing line, so a turn opening with no cue behind it is always
# a parse failure. The collapser refuses the file instead of signing a name to
# the line, because phase 4 deletes the source once this output is written: a
# loud stop is recoverable and a fabricated turn is not.
preamble="$(mktemp -d "${TMPDIR:-/tmp}/i2m-preamble.XXXXXX")/bad.vtt"
printf 'GARBAGE HEADER\n\n1\n00:00:01.000 --> 00:00:05.000\n<v Alice>Hello</v>\n' >"$preamble"
if bash "$vtt" "$preamble" >/dev/null 2>&1; then
  echo "the collapser accepted a line of speech above the first cue" >&2
  exit 1
fi
guard_err="$(bash "$vtt" "$preamble" 2>&1 >/dev/null || true)"
require_output "$guard_err" "no cue has started; refusing to attribute this line: GARBAGE HEADER"

# The offending line, not the one that flushed it. emit() runs a record behind
# the read, so reporting FNR here names the blank line below the problem and
# sends a reader to the wrong place in a 1,388-line transcript.
require_output "$guard_err" "bad.vtt:1:"

# Every real fixture stays acceptable. A guard that fires on valid input would
# refuse the transcripts this skill exists to process.
for f in blocks teams-export speakerless steerco-excerpt; do
  bash "$vtt" "$fixtures/$f.vtt" >/dev/null 2>&1 || {
    echo "the preamble guard rejected $f.vtt, which is a valid transcript" >&2
    exit 1
  }
done

# The collapser carries a ledger; the skill as a whole still does not. Its rows
# are what stop the three fixes above from reading as arbitrary to whoever
# changes this script next, and every refute in this section corresponds to one
# Deliberately Not Built row.
rationale=_maintenance/inbox-to-memory/RATIONALE.md
require_file "$rationale"
require_text "$rationale" "## Decision Ledger"
require_text "$rationale" "## Deliberately Not Built"
require_text "$rationale" "## Known Limitations"

# Every ledger row carries its tier in the Tier column. Numbering the rows once
# dropped a separator from each, which markdown renders as the rationale under
# Decision, the tier under Why, and an empty Tier column: the ledger still reads
# as prose while the thing AGENTS.md asks it to record is gone from the table.
awk -F'|' '
  /^\| *# *\| *Decision/ { want = NF; next }
  want && /^\|---/ { next }
  want && /^\|/ {
    if (NF != want) { print "ledger row " NR " has " NF-1 " columns, header has " want-1; bad = 1 }
    next
  }
  want && !/^\|/ { want = 0 }
  END { exit bad }
' "$rationale" || {
  echo "the RATIONALE decision ledger has a malformed row" >&2
  exit 1
}


# ---------------------------------------------------------------------------
# Raw-zone reflow (#48)
# ---------------------------------------------------------------------------

# Notes groomed before the blank-line separator existed carry raw zones that
# render as one paragraph. The reflow migration repairs them in place and
# re-anchors the L refs the reflow moves, so it ships beside the collapser and
# is named where the collapser is documented.
reflow=inbox-to-memory/scripts/reflow-raw.sh
require_file "$reflow"
[[ -x "$reflow" ]] || {
  echo "$reflow must be executable" >&2
  exit 1
}
bash -n "$reflow"
require_text inbox-to-memory/SKILL.md "scripts/reflow-raw.sh"
require_text inbox-to-memory/references/migration.md "reflow-raw.sh"

# Same throwaway-repo pattern as the migrator: the dry-run promise and the
# one-file-modified claim are both read off git, so the fixture has to be a
# real repo and never the checked-in one. Cleaned up explicitly at the end of
# this section rather than joining the cumulative trap chain below.
rfl="$(mktemp -d "${TMPDIR:-/tmp}/i2m-reflow-test.XXXXXX")"
cp -R "$fixtures/reflow/." "$rfl/"
git -C "$rfl" init -q
git -C "$rfl" add -A
git -C "$rfl" -c user.email=t@t -c user.name=t commit -qm baseline

# A dry run writes nothing, proven by git rather than by the script's report.
rfl_dry="$(bash "$reflow" "$rfl" 2>&1)"
require_output "$rfl_dry" "dry run; nothing was written"
[[ -z "$(git -C "$rfl" status --porcelain)" ]] || {
  echo "the reflow dry run modified the scope" >&2
  git -C "$rfl" status --porcelain >&2
  exit 1
}

rfl_apply="$(bash "$reflow" "$rfl" --apply 2>&1)"
require_output "$rfl_apply" "reflowed: 1"
require_output "$rfl_apply" "refs rewritten: 3"
require_output "$rfl_apply" "left alone: 1"
require_output "$rfl_apply" "v1 bodies skipped: 2"

# Exactly one file changes: the v2 note with a collapsed-VTT zone. The v1
# note, the migrated-frontmatter note, and the pasted document are untouched.
[[ "$(git -C "$rfl" status --porcelain | wc -l | tr -d ' ')" == "1" ]] || {
  echo "reflow should modify exactly one file in the reflow fixture" >&2
  git -C "$rfl" status --porcelain >&2
  exit 1
}

rfl_note="$rfl/notes/2026-06-02-harbor-cutover-walkthrough-mHq8rT2wLp.md"

# Only whitespace changes below the fence: same words, same order. Flatten the
# zone to one word per line on both sides and diff.
diff <(sed -n '/## Raw Content/,$p' "$fixtures/reflow/notes/2026-06-02-harbor-cutover-walkthrough-mHq8rT2wLp.md" | tr -s '[:space:]' '\n' | grep -v '^$') \
  <(sed -n '/## Raw Content/,$p' "$rfl_note" | tr -s '[:space:]' '\n' | grep -v '^$') || {
  echo "reflow changed the words of the transcript, not just its whitespace" >&2
  exit 1
}

# Every rewritten ref lands on the line that now holds its snippet. All three
# refs must survive the rewrite for this loop to mean anything.
[[ "$(grep -cE '\(raw: "[^"]*",? L[0-9]+\)' "$rfl_note")" == "3" ]] || {
  echo "expected three snippet-carrying refs in the reflowed note" >&2
  exit 1
}
while IFS=$'\t' read -r snippet ln; do
  sed -n "${ln}p" "$rfl_note" | grep -Fq -- "$snippet" || {
    echo "ref L$ln does not land on its snippet: $snippet" >&2
    sed -n "${ln}p" "$rfl_note" >&2
    exit 1
  }
done < <(grep -oE '\(raw: "[^"]*",? L[0-9]+\)' "$rfl_note" | sed -E 's/^\(raw: "(.*)",? L([0-9]+)\)$/\1\t\2/')

# Idempotent: a second apply on the committed result changes nothing.
git -C "$rfl" add -A
git -C "$rfl" -c user.email=t@t -c user.name=t commit -qm reflowed
rfl_again="$(bash "$reflow" "$rfl" --apply 2>&1)"
require_output "$rfl_again" "reflowed: 0"
require_output "$rfl_again" "already reflowed: 1"
[[ -z "$(git -C "$rfl" status --porcelain)" ]] || {
  echo "a second reflow apply modified an already-migrated scope" >&2
  exit 1
}

# The migrated scope still lints clean.
rfl_lint="$(run_lint "$rfl")"
require_line "$rfl_lint" "failures: 0" reflowed

# The edge fixture holds the three refs the script must refuse to guess at: a
# snippet on two zone lines, a snippet on none, and a bare L ref with no
# snippet at all. Each is reported and left byte-identical while the zone
# itself still gains its blank line.
rfe="$(mktemp -d "${TMPDIR:-/tmp}/i2m-reflow-edge.XXXXXX")"
cp -R "$fixtures/reflow-edge/." "$rfe/"
rfe_out="$(bash "$reflow" "$rfe" --apply --allow-dirty 2>&1)"
require_output "$rfe_out" "reflowed: 1"
require_output "$rfe_out" "refs rewritten: 0"
require_output "$rfe_out" 'snippet "final walkthrough" sits on 2 zone lines; its L ref was left alone'
require_output "$rfe_out" 'snippet "in the filing cabinet" is not in the reflowed raw zone; its L ref was left alone'
require_output "$rfe_out" 'bare ref `(raw: L23)` carries no snippet to anchor to; left alone'
rfe_note="$rfe/notes/2026-02-11-walkthrough-scheduling-eJ7hL4xWgs.md"
require_text "$rfe_note" '(raw: "final walkthrough" L22)'
require_text "$rfe_note" '(raw: "in the filing cabinet" L23)'
require_text "$rfe_note" '(raw: L23)'

rm -rf "$rfl" "$rfe"

# The half number is the point. Phases 3 through 6 have carried those numbers
# since v1, and every scaffold that says "phase 5 sign-off" has to keep pointing
# at sign-off after a phase gets inserted ahead of it.
require_text inbox-to-memory/SKILL.md "### Phase 2.5 — Check Against Accepted Memory"
for phase in \
  "### Phase 3 — Groom Into a Single Note" \
  "### Phase 4 — Dispose Source" \
  "### Phase 5 — Propose and Crystallize (gated)" \
  "### Phase 6 — Verify"; do
  require_text inbox-to-memory/SKILL.md "$phase"
done

# Normalizing after the lookup instead of before it returns a clean no-conflict
# report on a scope that has the conflict, which is worse than not looking.
require_text inbox-to-memory/SKILL.md "**Normalize them through the scope's alias table** before any lookup"

# A budget quietly exceeded on every input is one that stopped bounding anything.
require_text inbox-to-memory/SKILL.md "**Five body reads per input, and the budget binds.**"
require_text inbox-to-memory/SKILL.md "read budget bound is named"

# All three outcomes, and the one that leaves the flag behind.
for outcome in "**Amend.**" "**Supersede.**" "**Dismiss.**"; do
  require_text inbox-to-memory/SKILL.md "$outcome"
done
require_text inbox-to-memory/SKILL.md "**A dismissed flag stays in the note permanently.**"

# The table is what a reader consults after hitting a failure, so a check
# missing from it ships a failure name that leads nowhere.
require_text "$contracts" "frontmatter-key-domain"

# Both halves of the disagreement travel together, and the contract says why.
require_text "$contracts" "contradiction-fields"
require_text "$contracts" "| claims: <what the record says>"
require_text "$heuristics" "Flag it only when the statements can't both be true."
require_text inbox-to-memory/assets/note.template.md "[contradicts accepted: [[<record>|<label>]]]"

# yq arrives as a prerequisite here and gets consumed by the contract checks in
# #6. It is not installed by default anywhere, so the README has to say so next
# to nanoid or the first verify run fails for a confusing reason.
require_text inbox-to-memory/README.md "nanoid"
require_text inbox-to-memory/README.md "brew install yq"

# ---------------------------------------------------------------------------
# Migration, Tier 1
# ---------------------------------------------------------------------------

# Snapshot the fixtures before any migration runs. Comparing against git would
# only tell us the tree is dirty, which it legitimately is while someone is
# editing a fixture; this compares the files to themselves.
fixtures_before="$(find "$fixtures" -type f -exec shasum {} + | sort)"

migrator=inbox-to-memory/scripts/migrate-scope.sh
require_file "$migrator"
[[ -x "$migrator" ]] || {
  echo "$migrator must be executable" >&2
  exit 1
}
bash -n "$migrator"

# The migrator has its own copy of the opt-in guard, so the scaffold layout has
# to reach its report rather than its refusal. A dry run writes nothing, which
# keeps this inside the no-fixture-is-modified guarantee asserted below.
scaffold_dry="$(bash "$migrator" "$fixtures/scaffold-layout" 2>&1 || true)"
grep -Fq 'migrated: 2' <<<"$scaffold_dry" || {
  echo "migrator did not reach its report on a scaffold-layout scope" >&2
  printf '%s\n' "$scaffold_dry" >&2
  exit 1
}

# The mode only exists if something routes to it, and the phrasing row is the
# only thing that does.
require_text inbox-to-memory/SKILL.md "| migrate  |"
require_text inbox-to-memory/SKILL.md "migrate this scope"
require_text inbox-to-memory/SKILL.md "scripts/migrate-scope.sh"
require_text inbox-to-memory/SKILL.md "references/migration.md"
require_file inbox-to-memory/references/migration.md

# Same reasoning one level down. A flag and a sibling script nobody names in
# SKILL.md are a tier and a sweep that never run in the field, and the
# migration.md line they replaced used to say Tier 2 wasn't implemented at all.
require_text inbox-to-memory/SKILL.md "--tier2-extract"
require_text inbox-to-memory/SKILL.md "--tier2 <dir>/proposals.yaml"
require_text inbox-to-memory/SKILL.md "scripts/verify-migration.sh"
refute_text inbox-to-memory/references/migration.md "is not implemented here"

# Both key orders are duplicated by hand into the lint, the templates, and now the
# migrator. The only thing keeping the four copies honest is that a drift fails here.
migrator_note_order="schema body_schema id date type summary attendees tags topics entities source_file transcript_corrections open_questions resolved_questions deferred_tensions unpromoted_candidates related"
migrator_record_order="schema body_schema id memory_type title status date effective_from effective_to last_confirmed source_refs applies_to owners tags themes related exception_to supersedes superseded_by"
require_text "$migrator" "$migrator_note_order"
require_text "$migrator" "$migrator_record_order"
require_text "$lint" "$migrator_note_order"
require_text "$lint" "$migrator_record_order"

# Stand up a throwaway git repo from the old-only fixture. Everything below reads
# `git status` and `git diff` to check the promises, so the fixture has to be a
# real repo and it can never be the checked-in one.
mig="$(mktemp -d "${TMPDIR:-/tmp}/i2m-migrate-test.XXXXXX")"
trap 'rm -rf "$not_a_scope" "$inline_scope" "$dismissal_scope" "$mig"' EXIT
cp -R "$fixtures/old-only/." "$mig/"
git -C "$mig" init -q
git -C "$mig" add -A
git -C "$mig" -c user.email=t@t -c user.name=t commit -qm baseline

# A dry run writes nothing. Proving that with git rather than with the script's
# own report is the point: the report is what would lie.
dry_out="$(bash "$migrator" "$mig" 2>&1)"
require_output "$dry_out" "dry run; nothing was written"
[[ -z "$(git -C "$mig" status --porcelain)" ]] || {
  echo "the dry run modified the scope" >&2
  git -C "$mig" status --porcelain >&2
  exit 1
}

# Every proposed change is reported, one file at a time.
for f in \
  notes/2025-11-04-atlas-scoping-call-3iMu15QJ_x.md \
  notes/2025-11-18-atlas-working-session-P5spzLt4Bz.md \
  _memory/context/legacy-billing-freeze-Hq3U2Su1gy.md \
  _memory/decisions/one-vendor-per-region-G2k65qG3Nc.md; do
  require_output "$dry_out" "--- $mig/$f"
done

# A dirty tree stops an apply. The whole verification story downstream is "read
# the diff," and a diff mixing migration with uncommitted work cannot be read.
echo scratch >"$mig/notes/scratch.md"
if bash "$migrator" "$mig" --apply >/dev/null 2>&1; then
  echo "the migrator applied against a dirty working tree" >&2
  exit 1
fi
rm "$mig/notes/scratch.md"

apply_out="$(bash "$migrator" "$mig" --apply 2>&1)"
require_output "$apply_out" "migrated: 4"
require_output "$apply_out" "already v2: 0"
require_output "$apply_out" "left alone: 0"

# Nothing is renamed and nothing is deleted, so every wiki link that resolved
# before still resolves. Anything other than a plain M here breaks that.
while read -r status _; do
  [[ "$status" == "M" ]] || {
    echo "migration produced a non-modification change: $status" >&2
    git -C "$mig" status --porcelain >&2
    exit 1
  }
done < <(git -C "$mig" status --porcelain)

[[ "$(git -C "$mig" status --porcelain | wc -l | tr -d ' ')" == "4" ]] || {
  echo "expected exactly four modified files after migration" >&2
  git -C "$mig" status --porcelain >&2
  exit 1
}

# The body is the record of what someone knew that day, and it has to come
# through untouched to the byte. This is the assertion the whole design serves.
for f in $(git -C "$mig" ls-files '*.md'); do
  before="$(git -C "$mig" show "HEAD:$f" | awk 'BEGIN { c = 0 } /^---$/ { c++; if (c == 2) { f = 1; next } } f' | shasum)"
  after="$(awk 'BEGIN { c = 0 } /^---$/ { c++; if (c == 2) { f = 1; next } } f' "$mig/$f" | shasum)"
  [[ "$before" == "$after" ]] || {
    echo "migration changed the body of $f" >&2
    exit 1
  }
done

# Filenames carry the nanoid, and the id inside has to keep matching it.
for f in $(git -C "$mig" ls-files '*.md'); do
  base="${f##*/}"
  base="${base%.md}"
  require_text "$mig/$f" "id: ${base: -10}"
done

# The migrated scope passes its own lint, and the v1 bodies underneath do not get
# flagged for a grammar that postdates them. Both halves matter: without the
# second, migration would hand back a scope full of new failures.
mig_out="$(run_lint "$mig")"
require_line "$mig_out" "v1 files: 0" migrated
require_line "$mig_out" "v2 files: 4" migrated
require_line "$mig_out" "failures: 0" migrated
refute_failure "$mig_out" "anchor-form"
require_text "$mig/notes/2025-11-04-atlas-scoping-call-3iMu15QJ_x.md" "(raw: L12)"
require_text "$mig/notes/2025-11-04-atlas-scoping-call-3iMu15QJ_x.md" "body_schema: 1"

# Counts are counted, not assumed. This note carries two memory candidates and no
# questions, so three zeros and a two is the only correct answer.
require_text "$mig/notes/2025-11-04-atlas-scoping-call-3iMu15QJ_x.md" "open_questions: 0"
require_text "$mig/notes/2025-11-04-atlas-scoping-call-3iMu15QJ_x.md" "unpromoted_candidates: 2"

# Block lists flatten, relationships become compound strings, and a record with
# no confirmation history is last confirmed the day it was written.
require_text "$mig/notes/2025-11-18-atlas-working-session-P5spzLt4Bz.md" "related: [extends::3iMu15QJ_x]"
require_text "$mig/notes/2025-11-04-atlas-scoping-call-3iMu15QJ_x.md" "attendees: [Priya Raghavan, Marcus Dell, Kendrick Arnett]"
require_text "$mig/_memory/decisions/one-vendor-per-region-G2k65qG3Nc.md" "date: 2025-11-04"
require_text "$mig/_memory/decisions/one-vendor-per-region-G2k65qG3Nc.md" "last_confirmed: 2025-11-04"

# A relation is the half that carries the meaning. The migrator has no way to
# recover one that was never written down, so it keeps the bare id and says so.
require_output "$dry_out" "\`related\` holds bare id \`G2k65qG3Nc\`"
require_text "$mig/_memory/context/legacy-billing-freeze-Hq3U2Su1gy.md" "related: [G2k65qG3Nc]"

# This apply never passed --tier2, so nothing here should carry a summary or
# entities key. Tier 2 is an opt-in second pass, not a wider meaning for --apply.
for f in $(git -C "$mig" ls-files '*.md'); do
  summary_lines="$(grep -c '^summary:' "$mig/$f" 2>/dev/null || true)"
  entities_lines="$(grep -c '^entities:' "$mig/$f" 2>/dev/null || true)"
  [[ "${summary_lines:-0}" -eq 0 && "${entities_lines:-0}" -eq 0 ]] || {
    echo "a Tier-1-only apply wrote a summary or entities key into $f" >&2
    exit 1
  }
done

# Running twice changes nothing. Migration is the kind of thing people rerun when
# they lose track of whether it finished.
second_out="$(bash "$migrator" "$mig" --allow-dirty 2>&1)"
require_output "$second_out" "migrated: 0"
require_output "$second_out" "already v2: 4"

# The journal source ref is the one compound built from a path instead of a
# relation, and the sub-field the compound cannot hold gets named before it goes.
jrn="$(mktemp -d "${TMPDIR:-/tmp}/i2m-journal.XXXXXX")"
trap 'rm -rf "$not_a_scope" "$inline_scope" "$dismissal_scope" "$mig" "$jrn"' EXIT
cp -R "$fixtures/journal-v1/." "$jrn/"
jrn_out="$(bash "$migrator" "$jrn" --apply --allow-dirty 2>&1)"
require_output "$jrn_out" "migrated: 1"
require_output "$jrn_out" "dropped \`scope: client\`"
jrn_entry="$jrn/entries/2025-12-09-freeze-dates-need-a-writer-6SMjpofI2b.md"
require_text "$jrn_entry" "source_refs: [11 Clients/northwind/pursuits/atlas::ZGulgExW0q]"
refute_text "$jrn_entry" "note_id:"
jrn_lint="$(run_lint "$jrn")"
require_line "$jrn_lint" "failures: 0" journal-migrated

# ---------------------------------------------------------------------------
# Migration, Tier 2
# ---------------------------------------------------------------------------

# The seam T-001 planted: this note's Raw Content names a vendor, "Cascade
# Analytics", that appears nowhere above the fence. Every C-1/C-2 assertion
# below keys on that exact string rather than on "Marcus". Marcus is also
# below the fence, but he's already in `attendees`, so an assertion against
# him would pass whether or not the fence held anything back.
seam_note="notes/2025-11-04-atlas-scoping-call-3iMu15QJ_x.md"
seam_id="3iMu15QJ_x"
seam_planted_name="Cascade Analytics"
other_note="notes/2025-11-18-atlas-working-session-P5spzLt4Bz.md"
other_id="P5spzLt4Bz"
seam_summary="Priya and Marcus disagreed over one-vendor-per-region in EMEA, with the billing freeze and contract renewal left as open questions."
other_summary="Priya pushed to have the exception process documented, and nobody in the room owns writing it down."

# --- Extraction stops at the fence (C-1) ----------------------------------

t2_extract_scope="$(mktemp -d "${TMPDIR:-/tmp}/i2m-tier2-extract.XXXXXX")"
trap 'rm -rf "$not_a_scope" "$inline_scope" "$dismissal_scope" "$mig" "$jrn" "$t2_extract_scope"' EXIT
cp -R "$fixtures/old-only/." "$t2_extract_scope/"
t2x_dir="$(mktemp -d "${TMPDIR:-/tmp}/i2m-tier2-sidecar.XXXXXX")"
trap 'rm -rf "$not_a_scope" "$inline_scope" "$dismissal_scope" "$mig" "$jrn" "$t2_extract_scope" "$t2x_dir"' EXIT
bash "$migrator" "$t2_extract_scope" --tier2-extract "$t2x_dir" >/dev/null

seam_extract="$t2x_dir/$seam_id.extract.md"
require_file "$seam_extract"
require_text "$seam_extract" "## Notable Quotes"
refute_text "$seam_extract" "$seam_planted_name"

# Tier 2 is a note concept; a record has no extracted sections of its own, so
# its id never gets an extract file.
[[ ! -e "$t2x_dir/Hq3U2Su1gy.extract.md" ]] || {
  echo "a memory record got a tier2 extract; tier2 only reaches notes" >&2
  exit 1
}

# --- Sourced entities, the one-line summary, and subset approval (C-2, C-3, C-4) ---

# A proposals file names notes by id, matching the id already inside each
# frontmatter block. An id needs no quoting for yq, unlike a filename that
# carries a slash and a dot.
subset_scope="$(mktemp -d "${TMPDIR:-/tmp}/i2m-tier2-subset.XXXXXX")"
trap 'rm -rf "$not_a_scope" "$inline_scope" "$dismissal_scope" "$mig" "$jrn" "$t2_extract_scope" "$t2x_dir" "$subset_scope"' EXIT
cp -R "$fixtures/old-only/." "$subset_scope/"
git -C "$subset_scope" init -q
git -C "$subset_scope" add -A
git -C "$subset_scope" -c user.email=t@t -c user.name=t commit -qm baseline

subset_proposals="$t2x_dir/subset-proposals.yaml"
cat >"$subset_proposals" <<YAML
notes:
  $seam_id:
    summary: '$seam_summary'
    entities: [Priya Raghavan, Marcus Dell]
YAML

subset_out="$(bash "$migrator" "$subset_scope" --tier2 "$subset_proposals" --apply 2>&1)"
require_output "$subset_out" "migrated: 4"
require_output "$subset_out" "left alone: 0"
require_text "$subset_scope/$seam_note" "summary: '$seam_summary'"
require_text "$subset_scope/$seam_note" "entities: [Priya Raghavan, Marcus Dell]"

# The proposals file names only the seam note. The other note still migrates,
# since Tier 1 never waits on Tier 2, but carries no summary or entities key
# because nobody proposed any for it.
refute_text "$subset_scope/$other_note" "summary:"
refute_text "$subset_scope/$other_note" "entities:"

subset_lint="$(run_lint "$subset_scope")"
require_line "$subset_lint" "failures: 0" tier2-subset

# C-5: a note the proposals file never named comes out exactly as a
# Tier-1-only apply would have produced it. $mig never saw a --tier2 flag.
[[ "$(shasum "$subset_scope/$other_note" | awk '{print $1}')" \
  == "$(shasum "$mig/$other_note" | awk '{print $1}')" ]] || {
  echo "a note omitted from the tier2 proposals file diverged from a Tier-1-only apply" >&2
  diff "$subset_scope/$other_note" "$mig/$other_note" >&2 || true
  exit 1
}

# --- Grouping in the dry run, and batched approval (C-4) ------------------

batched_scope="$(mktemp -d "${TMPDIR:-/tmp}/i2m-tier2-batched.XXXXXX")"
trap 'rm -rf "$not_a_scope" "$inline_scope" "$dismissal_scope" "$mig" "$jrn" "$t2_extract_scope" "$t2x_dir" "$subset_scope" "$batched_scope"' EXIT
cp -R "$fixtures/old-only/." "$batched_scope/"
git -C "$batched_scope" init -q
git -C "$batched_scope" add -A
git -C "$batched_scope" -c user.email=t@t -c user.name=t commit -qm baseline

batched_proposals="$t2x_dir/batched-proposals.yaml"
cat >"$batched_proposals" <<YAML
notes:
  $seam_id:
    summary: '$seam_summary'
    entities: [Priya Raghavan, Marcus Dell]
  $other_id:
    summary: '$other_summary'
    entities: [Priya Raghavan]
YAML

# A reviewer edits one note's proposal without touching the rest, so each one
# has to land in the diff block for the file it belongs to, not float free at
# the end of the report where it could be approved against the wrong note.
batched_dry="$(bash "$migrator" "$batched_scope" --tier2 "$batched_proposals" 2>&1)"
seam_block="$(printf '%s\n' "$batched_dry" | awk -v hdr="--- $batched_scope/$seam_note" \
  '$0 == hdr { grab = 1; next } grab && /^--- / { exit } grab { print }')"
other_block="$(printf '%s\n' "$batched_dry" | awk -v hdr="--- $batched_scope/$other_note" \
  '$0 == hdr { grab = 1; next } grab && /^--- / { exit } grab { print }')"
[[ -n "$(printf '%s\n' "$seam_block" | grep -F '+summary:' || true)" ]] || {
  echo "the seam note's tier2 proposal did not appear grouped under its own file" >&2
  printf '%s\n' "$batched_dry" >&2
  exit 1
}
[[ -n "$(printf '%s\n' "$other_block" | grep -F '+summary:' || true)" ]] || {
  echo "the other note's tier2 proposal did not appear grouped under its own file" >&2
  printf '%s\n' "$batched_dry" >&2
  exit 1
}
[[ -z "$(git -C "$batched_scope" status --porcelain)" ]] || {
  echo "the tier2 dry run modified the scope" >&2
  exit 1
}

batched_out="$(bash "$migrator" "$batched_scope" --tier2 "$batched_proposals" --apply 2>&1)"
require_output "$batched_out" "migrated: 4"
require_output "$batched_out" "left alone: 0"
require_text "$batched_scope/$seam_note" "summary: '$seam_summary'"
require_text "$batched_scope/$other_note" "summary: '$other_summary'"
require_text "$batched_scope/$other_note" "entities: [Priya Raghavan]"

batched_lint="$(run_lint "$batched_scope")"
require_line "$batched_lint" "failures: 0" tier2-batched

# --- Refusal leaves the note untouched, never partial (C-2, C-3 mechanical) ---

lifecycle_scope="$(mktemp -d "${TMPDIR:-/tmp}/i2m-tier2-lifecycle.XXXXXX")"
trap 'rm -rf "$not_a_scope" "$inline_scope" "$dismissal_scope" "$mig" "$jrn" "$t2_extract_scope" "$t2x_dir" "$subset_scope" "$batched_scope" "$lifecycle_scope"' EXIT
cp -R "$fixtures/old-only/." "$lifecycle_scope/"
git -C "$lifecycle_scope" init -q
git -C "$lifecycle_scope" add -A
git -C "$lifecycle_scope" -c user.email=t@t -c user.name=t commit -qm baseline

seam_baseline_hash="$(git -C "$lifecycle_scope" show "HEAD:$seam_note" | shasum | awk '{print $1}')"

unsourced_proposals="$t2x_dir/unsourced-proposals.yaml"
cat >"$unsourced_proposals" <<YAML
notes:
  $seam_id:
    summary: '$seam_summary'
    entities: [$seam_planted_name]
YAML

unsourced_out="$(bash "$migrator" "$lifecycle_scope" --tier2 "$unsourced_proposals" --apply 2>&1)"
require_output "$unsourced_out" "$lifecycle_scope/$seam_note: tier2-entity-unsourced: \"$seam_planted_name\""
[[ "$(shasum "$lifecycle_scope/$seam_note" | awk '{print $1}')" == "$seam_baseline_hash" ]] || {
  echo "an unsourced-entity refusal still modified the note" >&2
  exit 1
}
refute_text "$lifecycle_scope/$seam_note" "schema:"

multiline_proposals="$t2x_dir/multiline-proposals.yaml"
cat >"$multiline_proposals" <<YAML
notes:
  $seam_id:
    summary: |
      $seam_summary
      A second line no reviewer approved.
    entities: []
YAML

multiline_out="$(bash "$migrator" "$lifecycle_scope" --tier2 "$multiline_proposals" --apply --allow-dirty 2>&1)"
require_output "$multiline_out" "$lifecycle_scope/$seam_note: tier2-summary-multiline"
[[ "$(shasum "$lifecycle_scope/$seam_note" | awk '{print $1}')" == "$seam_baseline_hash" ]] || {
  echo "a multiline-summary refusal still modified the note" >&2
  exit 1
}
refute_text "$lifecycle_scope/$seam_note" "schema:"

# A corrected proposal for the same note now succeeds, proving the two
# refusals above were about the proposal, not about the note.
seam_proposals="$t2x_dir/seam-proposals.yaml"
cat >"$seam_proposals" <<YAML
notes:
  $seam_id:
    summary: '$seam_summary'
    entities: [Priya Raghavan, Marcus Dell]
YAML

seam_out="$(bash "$migrator" "$lifecycle_scope" --tier2 "$seam_proposals" --apply --allow-dirty 2>&1)"
require_output "$seam_out" "migrated: 1"
require_text "$lifecycle_scope/$seam_note" "summary: '$seam_summary'"

lifecycle_lint="$(run_lint "$lifecycle_scope")"
require_line "$lifecycle_lint" "failures: 0" tier2-lifecycle

# --- A second run over a Tier-2-applied scope stays a no-op too (C-11) ----

idem_dir="$(mktemp -d "${TMPDIR:-/tmp}/i2m-tier2-idem.XXXXXX")"
trap 'rm -rf "$not_a_scope" "$inline_scope" "$dismissal_scope" "$mig" "$jrn" "$t2_extract_scope" "$t2x_dir" "$subset_scope" "$batched_scope" "$lifecycle_scope" "$idem_dir"' EXIT
idem_out="$(bash "$migrator" "$lifecycle_scope" --tier2-extract "$idem_dir" 2>&1)"
require_output "$idem_out" "migrated: 0"
require_output "$idem_out" "already v2: 4"
[[ ! -e "$idem_dir/proposals.yaml" ]] || {
  echo "a fully Tier-2-applied scope still produced a tier2 proposals skeleton on re-run" >&2
  exit 1
}

# ---------------------------------------------------------------------------
# Verification
# ---------------------------------------------------------------------------

verify=inbox-to-memory/scripts/verify-migration.sh
require_file "$verify"
[[ -x "$verify" ]] || {
  echo "$verify must be executable" >&2
  exit 1
}
bash -n "$verify"

verify_note_a="notes/2025-11-04-atlas-scoping-call-3iMu15QJ_x.md"
verify_note_b="notes/2025-11-18-atlas-working-session-P5spzLt4Bz.md"
verify_record_r2="_memory/decisions/one-vendor-per-region-G2k65qG3Nc.md"

# Every scenario below starts from the same shape: a fresh copy of old-only,
# a wiki link appended to note A pointing at note B, migrated for real with
# Tier 1 --apply and committed. The link target drops the date prefix that
# note B's filename carries, so a lookup by exact name can't succeed and the
# id fallback is what actually resolves it -- the shape a hand-typed
# reference to a dated note tends to take, and the only way to exercise the
# fallback count without renaming anything migration itself wouldn't rename.
setup_verify_scope() {
  local dest="$1"
  cp -R "$fixtures/old-only/." "$dest/"
  printf '\nSee [[atlas-working-session-P5spzLt4Bz]] for background.\n' >>"$dest/$verify_note_a"
  git -C "$dest" init -q
  git -C "$dest" add -A
  git -C "$dest" -c user.email=t@t -c user.name=t commit -qm baseline
}

# The only mechanical way to make a migrated note fail its own lint: an extra
# key the contract never named. `frontmatter-known-keys` is deterministic and
# planting it costs one line, so the report has something exact to name.
plant_unknown_key() {
  local file="$1"
  awk '{ print } /^schema: 2$/ && !p { print "bogus_key: true"; p = 1 }' "$file" >"$file.verify-tmp"
  mv "$file.verify-tmp" "$file"
}

hash_scope() {
  find "$1" -type f -not -path '*/.git/*' -exec shasum {} + | sort
}

# --- A clean, passing run (C-7 fallback count, C-10) ------------------------

v_pass="$(mktemp -d "${TMPDIR:-/tmp}/i2m-verify-pass.XXXXXX")"
trap 'rm -rf "$not_a_scope" "$inline_scope" "$dismissal_scope" "$mig" "$jrn" "$t2_extract_scope" "$t2x_dir" "$subset_scope" "$batched_scope" "$lifecycle_scope" "$idem_dir" "$v_pass"' EXIT
setup_verify_scope "$v_pass"
v_pass_since="$(git -C "$v_pass" rev-parse HEAD)"
bash "$migrator" "$v_pass" --apply >/dev/null
git -C "$v_pass" add -A
git -C "$v_pass" -c user.email=t@t -c user.name=t commit -qm migrated

# Planted after the migration commit -- it only has to exist for the run
# below, not survive as part of the history verify-migration.sh diffs against.
mkdir -p "$v_pass/patterns-journal"
echo sentinel >"$v_pass/patterns-journal/.keep"

pass_out="$(bash "$verify" "$v_pass" --since "$v_pass_since")" && pass_status=0 || pass_status=$?
[[ "$pass_status" -eq 0 ]] || {
  echo "verify-migration.sh failed against a clean, fully migrated scope" >&2
  printf '%s\n' "$pass_out" >&2
  exit 1
}
require_output "$pass_out" "lint failures: 0"
require_output "$pass_out" "links checked: 1 (id fallback: 1)"
require_output "$pass_out" "renames: 0"
require_output "$pass_out" "deletions: 0"
require_output "$pass_out" "failures: 0"
require_output "$pass_out" "Verified $v_pass against $v_pass_since"
# The summary block above prints these same numbers on a failing run too, so
# on its own it can't pin the record to the counts of THIS run. This checks
# the paragraph's own interior instead, where a hard-coded record would show.
require_output "$pass_out" "0 lint failures, 1 link checked (1 by id fallback), 0 renames, 0 deletions"

# The paste instruction stands on its own line above the record, and
# require_output is blind to that: it greps the whole capture, so it matches
# either way, whether the sentence stands alone or rides the record's tail.
# The two checks below pin the separation itself. First the instruction as a
# whole line -- require_line is grep -Fqx, so a copy welded into the paragraph
# will not satisfy it.
require_line "$pass_out" "Paste the paragraph below into the scope's patterns journal." verify-pass
# Then the record on its own, pulled out of the capture, which is where a
# welded instruction would show. The needle is deliberately the widest
# fragment any paste directive has to carry, so a reworded one trips it too.
pass_record="$(printf '%s\n' "$pass_out" | grep -F "Verified $v_pass against" || true)"
[[ -n "$pass_record" ]] || {
  echo "a passing verify-migration.sh run printed no record paragraph" >&2
  printf '%s\n' "$pass_out" >&2
  exit 1
}
record_directive="$(printf '%s\n' "$pass_record" | grep -F "patterns journal" || true)"
[[ -z "$record_directive" ]] || {
  echo "the record paragraph still tells the reader to paste it: $pass_record" >&2
  exit 1
}

# The record is stdout only. Nothing under the scope repeats it, and
# patterns-journal/ -- the place a human actually pastes it -- is untouched.
# Two needles because there are two lines: the record caught by its opening,
# the instruction by its whole sentence. A needle here that went stale would
# pass forever and read later as coverage, which is worse than no check.
record_leak="$(grep -rlF -- "Verified $v_pass against" "$v_pass" --exclude-dir=.git 2>/dev/null || true)"
[[ -z "$record_leak" ]] || {
  echo "the record paragraph leaked into a file under the scope: $record_leak" >&2
  exit 1
}
instruction_leak="$(grep -rlF -- "Paste the paragraph below into the scope's patterns journal." "$v_pass" --exclude-dir=.git 2>/dev/null || true)"
[[ -z "$instruction_leak" ]] || {
  echo "the paste instruction leaked into a file under the scope: $instruction_leak" >&2
  exit 1
}
[[ "$(cat "$v_pass/patterns-journal/.keep")" == "sentinel" ]] || {
  echo "a passing verify-migration.sh run touched patterns-journal/" >&2
  exit 1
}

# --- An aborting lint still fails verification, honestly (C-6) -------------
#
# Resolved as a sibling, so this copy of scripts/ makes verify-migration.sh
# run *this* stub instead of the real lint checked into the repo -- the seam
# the abort case can only be tested through.
scripts_copy="$(mktemp -d "${TMPDIR:-/tmp}/i2m-verify-scripts.XXXXXX")"
trap 'rm -rf "$not_a_scope" "$inline_scope" "$dismissal_scope" "$mig" "$jrn" "$t2_extract_scope" "$t2x_dir" "$subset_scope" "$batched_scope" "$lifecycle_scope" "$idem_dir" "$v_pass" "$scripts_copy"' EXIT
cp -R inbox-to-memory/scripts/. "$scripts_copy/"
cat >"$scripts_copy/lint-scope.sh" <<'STUB'
#!/usr/bin/env bash
# Stand-in for the abort case: exits before it ever prints a summary line, so
# a check reading for one instead of the exit status would call this clean.
echo "stub lint: refusing on purpose" >&2
exit 2
STUB
chmod +x "$scripts_copy/lint-scope.sh"

abort_out="$(bash "$scripts_copy/verify-migration.sh" "$v_pass" --since "$v_pass_since" 2>&1)" && abort_status=0 || abort_status=$?
[[ "$abort_status" -ne 0 ]] || {
  echo "verify-migration.sh exited zero against an aborting lint" >&2
  exit 1
}
require_output "$abort_out" "verify-lint: lint-scope.sh aborted with exit status 2"
clean_lint_claim="$(printf '%s\n' "$abort_out" | grep -F "lint failures: 0" || true)"
[[ -z "$clean_lint_claim" ]] || {
  echo "an aborting lint got reported as a clean sweep" >&2
  printf '%s\n' "$abort_out" >&2
  exit 1
}

# --- A committed rename, a committed deletion, and the link that breaks with
#     it -- distinguishing the diff-based read from a porcelain one (C-7, C-8, C-9) ---

v_combo="$(mktemp -d "${TMPDIR:-/tmp}/i2m-verify-combo.XXXXXX")"
trap 'rm -rf "$not_a_scope" "$inline_scope" "$dismissal_scope" "$mig" "$jrn" "$t2_extract_scope" "$t2x_dir" "$subset_scope" "$batched_scope" "$lifecycle_scope" "$idem_dir" "$v_pass" "$scripts_copy" "$v_combo"' EXIT
setup_verify_scope "$v_combo"
v_combo_since="$(git -C "$v_combo" rev-parse HEAD)"
bash "$migrator" "$v_combo" --apply >/dev/null
git -C "$v_combo" add -A
git -C "$v_combo" mv "$verify_record_r2" "_memory/decisions/one-vendor-per-region-renamed-G2k65qG3Nc.md"
git -C "$v_combo" rm -f -q "$verify_note_b"
git -C "$v_combo" -c user.email=t@t -c user.name=t commit -qm "post-migration edits"

# The whole reason this script stands alone: the migration and both edits
# above are committed, so the working tree is clean by porcelain's read.
[[ -z "$(git -C "$v_combo" status --porcelain)" ]] || {
  echo "the combo scope has uncommitted changes; the rename/deletion must be committed" >&2
  exit 1
}

combo_before="$(hash_scope "$v_combo")"
combo_out="$(bash "$verify" "$v_combo" --since "$v_combo_since")" && combo_status=0 || combo_status=$?
combo_after="$(hash_scope "$v_combo")"

[[ "$combo_status" -ne 0 ]] || {
  echo "verify-migration.sh exited zero on a scope with a committed rename, deletion, and broken link" >&2
  printf '%s\n' "$combo_out" >&2
  exit 1
}
[[ "$combo_before" == "$combo_after" ]] || {
  echo "a failing verify-migration.sh run changed files under the scope" >&2
  exit 1
}
require_output "$combo_out" "verify-link: \`atlas-working-session-P5spzLt4Bz\` resolves neither by name nor by id \`P5spzLt4Bz\`"
require_output "$combo_out" "verify-rename: \`$verify_record_r2\` renamed to \`_memory/decisions/one-vendor-per-region-renamed-G2k65qG3Nc.md\`"
require_output "$combo_out" "verify-rename: \`$verify_note_b\` deleted"
require_output "$combo_out" "failures: 3"
combo_record="$(printf '%s\n' "$combo_out" | grep -F "Verified $v_combo against" || true)"
[[ -z "$combo_record" ]] || {
  echo "a failing verify-migration.sh run still printed the record paragraph" >&2
  exit 1
}
# The instruction prints as a line of its own, so its absence on a failing run
# is its own claim. Without this, a regression that offered the paste line
# above a record that correctly never came would go unnoticed.
combo_instruction="$(printf '%s\n' "$combo_out" | grep -F "patterns journal" || true)"
[[ -z "$combo_instruction" ]] || {
  echo "a failing verify-migration.sh run still printed the paste instruction" >&2
  exit 1
}

# --- The link's own note survives; only the ref remembers the link (C-7) ---
#
# v_combo above can't tell a since-ref sweep from a tree sweep: note A, which
# carries the link, is never touched post-migration, so both readings find it.
# Here note A stays in the tree but the sentence carrying the link is edited
# out of its current body -- an ordinary M, not a rename or deletion, so C-8
# stays out of it -- while note B, the link's target, is renamed away. A sweep
# that reads the current tree finds no link at all and reports zero checked;
# only a sweep reading the --since ref still sees it, and then has to fail
# because the target it names no longer resolves either way.
v_linkdrop="$(mktemp -d "${TMPDIR:-/tmp}/i2m-verify-linkdrop.XXXXXX")"
trap 'rm -rf "$not_a_scope" "$inline_scope" "$dismissal_scope" "$mig" "$jrn" "$t2_extract_scope" "$t2x_dir" "$subset_scope" "$batched_scope" "$lifecycle_scope" "$idem_dir" "$v_pass" "$scripts_copy" "$v_combo" "$v_linkdrop"' EXIT
setup_verify_scope "$v_linkdrop"
v_linkdrop_since="$(git -C "$v_linkdrop" rev-parse HEAD)"
bash "$migrator" "$v_linkdrop" --apply >/dev/null
git -C "$v_linkdrop" add -A
git -C "$v_linkdrop" -c user.email=t@t -c user.name=t commit -qm migrated

grep -vF 'See [[atlas-working-session-P5spzLt4Bz]] for background.' \
  "$v_linkdrop/$verify_note_a" >"$v_linkdrop/$verify_note_a.tmp"
mv "$v_linkdrop/$verify_note_a.tmp" "$v_linkdrop/$verify_note_a"
git -C "$v_linkdrop" mv "$verify_note_b" "notes/renamed-target.md"
git -C "$v_linkdrop" add -A
git -C "$v_linkdrop" -c user.email=t@t -c user.name=t commit -qm "post-migration edits"

linkdrop_out="$(bash "$verify" "$v_linkdrop" --since "$v_linkdrop_since")" && linkdrop_status=0 || linkdrop_status=$?
[[ "$linkdrop_status" -ne 0 ]] || {
  echo "verify-migration.sh exited zero when a link only visible at --since had its target renamed away" >&2
  printf '%s\n' "$linkdrop_out" >&2
  exit 1
}
require_output "$linkdrop_out" "links checked: 1 (id fallback: 0)"
require_output "$linkdrop_out" "verify-link: \`atlas-working-session-P5spzLt4Bz\` resolves neither by name nor by id \`P5spzLt4Bz\`"

# --- One planted lint defect, named and counted (C-6, C-9) ------------------

v_lintdefect="$(mktemp -d "${TMPDIR:-/tmp}/i2m-verify-lintdefect.XXXXXX")"
trap 'rm -rf "$not_a_scope" "$inline_scope" "$dismissal_scope" "$mig" "$jrn" "$t2_extract_scope" "$t2x_dir" "$subset_scope" "$batched_scope" "$lifecycle_scope" "$idem_dir" "$v_pass" "$scripts_copy" "$v_combo" "$v_linkdrop" "$v_lintdefect"' EXIT
setup_verify_scope "$v_lintdefect"
v_lintdefect_since="$(git -C "$v_lintdefect" rev-parse HEAD)"
bash "$migrator" "$v_lintdefect" --apply >/dev/null
git -C "$v_lintdefect" add -A
git -C "$v_lintdefect" -c user.email=t@t -c user.name=t commit -qm migrated
plant_unknown_key "$v_lintdefect/$verify_note_a"

lintdefect_before="$(hash_scope "$v_lintdefect")"
lintdefect_out="$(bash "$verify" "$v_lintdefect" --since "$v_lintdefect_since")" && lintdefect_status=0 || lintdefect_status=$?
lintdefect_after="$(hash_scope "$v_lintdefect")"

[[ "$lintdefect_status" -ne 0 ]] || {
  echo "verify-migration.sh exited zero against a scope with a planted lint defect" >&2
  exit 1
}
[[ "$lintdefect_before" == "$lintdefect_after" ]] || {
  echo "a failing verify-migration.sh run changed files under the scope" >&2
  exit 1
}
require_output "$lintdefect_out" "lint failures: 1"
require_output "$lintdefect_out" "verify-lint: FAIL $v_lintdefect/$verify_note_a: frontmatter-known-keys: \`bogus_key\` is in neither key order"

# ---------------------------------------------------------------------------
# v1 link checking (#32)
# ---------------------------------------------------------------------------
#
# check_links now runs against v1 notes instead of skipping them outright.
# Nothing above this line exercises that path, so a later refactor could
# silently drop it again and nothing here would notice.

# Body content lands above the `## Raw Content` fence: extract_body stops
# there, so anything injected below it never reaches check_links.
inject_above_fence() {
  python3 - "$1" "$2" <<'PY'
import sys
p, block = sys.argv[1], sys.argv[2]
t = open(p).read()
i = t.find("## Raw Content")
open(p, "w").write(t[:i] + "\n" + block + "\n" + t[i:])
PY
}

# --- A broken link in a v1 note is reported ---------------------------------

v1_broken_scope="$(mktemp -d "${TMPDIR:-/tmp}/i2m-v1-broken.XXXXXX")"
trap 'rm -rf "$not_a_scope" "$inline_scope" "$dismissal_scope" "$mig" "$jrn" "$t2_extract_scope" "$t2x_dir" "$subset_scope" "$batched_scope" "$lifecycle_scope" "$idem_dir" "$v_pass" "$scripts_copy" "$v_combo" "$v_linkdrop" "$v_lintdefect" "$v1_broken_scope"' EXIT
cp -R "$fixtures/old-only/." "$v1_broken_scope/"
v1_broken_note="$v1_broken_scope/notes/2025-11-04-atlas-scoping-call-3iMu15QJ_x.md"
inject_above_fence "$v1_broken_note" \
  'See [[this-target-does-not-exist-AAAAAAAAAA]] for context.'

v1_broken_out="$(run_lint "$v1_broken_scope")"
require_failure "$v1_broken_out" "FAIL $v1_broken_note: link-broken: \`this-target-does-not-exist-AAAAAAAAAA\` resolves neither by name nor by id \`AAAAAAAAAA\`"
require_line "$v1_broken_out" "failures: 1" v1-broken

# --- A v1 link that resolves stays silent, by filename and by id alone, and
#     the six body-grammar checks stay off a v1 body even when every one of
#     them would fire under pass two -----------------------------------------
#
# `one-vendor-per-region-G2k65qG3Nc` matches a filename directly.
# `was-renamed-away-G2k65qG3Nc` matches no filename; only the trailing
# ten-character id resolves it, through the fallback in check_links
# (lint-scope.sh:376-377). The rest of the block is the same six-way body
# C-3 uses to prove token-grammar, open-question-fields, tension-fields,
# contradiction-fields, decision-fields, and anchor-form all stay off a v1
# file.

v1_pass_scope="$(mktemp -d "${TMPDIR:-/tmp}/i2m-v1-pass.XXXXXX")"
trap 'rm -rf "$not_a_scope" "$inline_scope" "$dismissal_scope" "$mig" "$jrn" "$t2_extract_scope" "$t2x_dir" "$subset_scope" "$batched_scope" "$lifecycle_scope" "$idem_dir" "$v_pass" "$scripts_copy" "$v_combo" "$v_linkdrop" "$v_lintdefect" "$v1_broken_scope" "$v1_pass_scope"' EXIT
cp -R "$fixtures/old-only/." "$v1_pass_scope/"
v1_pass_note="$v1_pass_scope/notes/2025-11-04-atlas-scoping-call-3iMu15QJ_x.md"
inject_above_fence "$v1_pass_note" \
'By name [[one-vendor-per-region-G2k65qG3Nc]], by id only [[was-renamed-away-G2k65qG3Nc]].
[invented token: x] not in the grammar table.
[open question: never-opened-anywhere] a question.
[open question resolved: opened-by-nobody] and its answer.
[tension: bogus-state] not resolved, deferred, or unacknowledged.
[contradicts accepted: nothing] naming no record and no claim.
[decision: sideways] neither one-way nor two-way, and no discarded alternatives.
(raw: line 12)'

v1_pass_out="$(run_lint "$v1_pass_scope")"
require_line "$v1_pass_out" "failures: 0" v1-pass
refute_failure "$v1_pass_out" "link-broken: \`one-vendor-per-region-G2k65qG3Nc\`"
refute_failure "$v1_pass_out" "link-broken: \`was-renamed-away-G2k65qG3Nc\`"
refute_failure "$v1_pass_out" "token-grammar"
refute_failure "$v1_pass_out" "open-question-fields"
refute_failure "$v1_pass_out" "tension-fields"
refute_failure "$v1_pass_out" "contradiction-fields"
refute_failure "$v1_pass_out" "decision-fields"
refute_failure "$v1_pass_out" "anchor-form"

# ---------------------------------------------------------------------------
# last_confirmed write-through (#27)
# ---------------------------------------------------------------------------
#
# The one sanctioned write into _memory/ that skips per-item sign-off, so it
# has a script instead of a prose promise. Every case below runs the real
# stamp-confirmed.sh against a copy of the mixed fixture, which supplies a
# forward stamp, a backward one, an exactly-equal one, a cross-group dedupe,
# and the v1 record the whole feature exists to leave alone.

stamper=inbox-to-memory/scripts/stamp-confirmed.sh

# The headline: a run naming both the v1 and the v2 record in one invocation
# leaves the v1 record byte-identical while the v2 one moves to the
# confirming note's date. Byte comparison, not output text — a stamper that
# prints the right skip line while writing the file anyway would sail
# through a check that only reads what it said.
wt_headline="$(mktemp -d "${TMPDIR:-/tmp}/i2m-wt-headline.XXXXXX")"
trap 'rm -rf "$not_a_scope" "$inline_scope" "$dismissal_scope" "$mig" "$jrn" "$t2_extract_scope" "$t2x_dir" "$subset_scope" "$batched_scope" "$lifecycle_scope" "$idem_dir" "$v_pass" "$scripts_copy" "$v_combo" "$v_linkdrop" "$v_lintdefect" "$v1_broken_scope" "$v1_pass_scope" "$wt_headline"' EXIT
cp -R "$fixtures/mixed/." "$wt_headline/"
wt_v1="$wt_headline/_memory/decisions/freeze-window-owned-by-ops-ocPwdpeY0a.md"
wt_v2="$wt_headline/_memory/context/atlas-region-topology-mPmy8XBe5H.md"
wt_v1_before="$(shasum "$wt_v1" | cut -d' ' -f1)"
wt_headline_out="$(bash "$stamper" "$wt_headline" \
  --note notes/2026-02-17-atlas-freeze-exceptions-SDy5SGVwfu.md \
  _memory/decisions/freeze-window-owned-by-ops-ocPwdpeY0a.md \
  _memory/context/atlas-region-topology-mPmy8XBe5H.md)"
[[ "$wt_v1_before" == "$(shasum "$wt_v1" | cut -d' ' -f1)" ]] || {
  echo "the v1 record was written by a run that also stamped a v2 record" >&2
  exit 1
}
require_output "$wt_headline_out" "skipped: _memory/decisions/freeze-window-owned-by-ops-ocPwdpeY0a.md (no schema key, v1)"
require_line "$wt_headline_out" "stamped: _memory/context/atlas-region-topology-mPmy8XBe5H.md 2026-02-10 -> 2026-02-17" wt-headline
require_line "$wt_headline_out" "stamped: 1  skipped: 1" wt-headline
[[ "$(grep '^last_confirmed:' "$wt_v2")" == "last_confirmed: 2026-02-17" ]] || {
  echo "the v2 record did not move to the confirming note's date" >&2
  exit 1
}

# Backward and equal both hold. Draining a backlog of old transcripts must
# not walk a record's date back, and a note dated exactly the record's
# current value confirms nothing new.
wt_backward="$(mktemp -d "${TMPDIR:-/tmp}/i2m-wt-backward.XXXXXX")"
trap 'rm -rf "$not_a_scope" "$inline_scope" "$dismissal_scope" "$mig" "$jrn" "$t2_extract_scope" "$t2x_dir" "$subset_scope" "$batched_scope" "$lifecycle_scope" "$idem_dir" "$v_pass" "$scripts_copy" "$v_combo" "$v_linkdrop" "$v_lintdefect" "$v1_broken_scope" "$v1_pass_scope" "$wt_headline" "$wt_backward"' EXIT
cp -R "$fixtures/mixed/." "$wt_backward/"
wt_backward_r="$wt_backward/_memory/context/atlas-region-topology-mPmy8XBe5H.md"
wt_backward_before="$(shasum "$wt_backward_r" | cut -d' ' -f1)"
for wt_n in 2025-12-02-atlas-steerco-ZGulgExW0q.md 2026-02-10-atlas-runbook-review-j5jLCGc5il.md; do
  wt_backward_out="$(bash "$stamper" "$wt_backward" --note "notes/$wt_n" _memory/context/atlas-region-topology-mPmy8XBe5H.md)"
  require_line "$wt_backward_out" "stamped: 0  skipped: 1" wt-backward
done
[[ "$wt_backward_before" == "$(shasum "$wt_backward_r" | cut -d' ' -f1)" ]] || {
  echo "a backward or equal-date confirmation moved last_confirmed" >&2
  exit 1
}

# The cross-group dedupe: two --note groups naming the same record in one
# invocation collapse to one candidate, so the record is written once and
# named once in the output. This is the issue's "confirmed twice in one run
# is stamped once."
wt_dedupe="$(mktemp -d "${TMPDIR:-/tmp}/i2m-wt-dedupe.XXXXXX")"
trap 'rm -rf "$not_a_scope" "$inline_scope" "$dismissal_scope" "$mig" "$jrn" "$t2_extract_scope" "$t2x_dir" "$subset_scope" "$batched_scope" "$lifecycle_scope" "$idem_dir" "$v_pass" "$scripts_copy" "$v_combo" "$v_linkdrop" "$v_lintdefect" "$v1_broken_scope" "$v1_pass_scope" "$wt_headline" "$wt_backward" "$wt_dedupe"' EXIT
cp -R "$fixtures/mixed/." "$wt_dedupe/"
wt_dedupe_out="$(bash "$stamper" "$wt_dedupe" \
  --note notes/2026-02-10-atlas-runbook-review-j5jLCGc5il.md _memory/context/atlas-region-topology-mPmy8XBe5H.md \
  --note notes/2026-02-17-atlas-freeze-exceptions-SDy5SGVwfu.md _memory/context/atlas-region-topology-mPmy8XBe5H.md)"
[[ "$(printf '%s\n' "$wt_dedupe_out" | grep -c 'atlas-region-topology')" == 1 ]] || {
  echo "a record named by two groups in one run produced more than one output line" >&2
  printf '%s\n' "$wt_dedupe_out" >&2
  exit 1
}
require_line "$wt_dedupe_out" "stamped: _memory/context/atlas-region-topology-mPmy8XBe5H.md 2026-02-10 -> 2026-02-17" wt-dedupe
require_line "$wt_dedupe_out" "stamped: 1  skipped: 0" wt-dedupe

# The status gate: a record mutated to a non-accepted status is left alone,
# even though it is otherwise the same record the headline case stamps.
wt_status="$(mktemp -d "${TMPDIR:-/tmp}/i2m-wt-status.XXXXXX")"
trap 'rm -rf "$not_a_scope" "$inline_scope" "$dismissal_scope" "$mig" "$jrn" "$t2_extract_scope" "$t2x_dir" "$subset_scope" "$batched_scope" "$lifecycle_scope" "$idem_dir" "$v_pass" "$scripts_copy" "$v_combo" "$v_linkdrop" "$v_lintdefect" "$v1_broken_scope" "$v1_pass_scope" "$wt_headline" "$wt_backward" "$wt_dedupe" "$wt_status"' EXIT
cp -R "$fixtures/mixed/." "$wt_status/"
wt_status_r="$wt_status/_memory/context/atlas-region-topology-mPmy8XBe5H.md"
python3 - "$wt_status_r" <<'PY'
import sys
p = sys.argv[1]
t = open(p).read()
open(p, "w").write(t.replace("status: accepted", "status: proposed", 1))
PY
wt_status_before="$(shasum "$wt_status_r" | cut -d' ' -f1)"
wt_status_out="$(bash "$stamper" "$wt_status" --note notes/2026-02-17-atlas-freeze-exceptions-SDy5SGVwfu.md _memory/context/atlas-region-topology-mPmy8XBe5H.md)"
require_output "$wt_status_out" "skipped: _memory/context/atlas-region-topology-mPmy8XBe5H.md (status: proposed, not accepted)"
[[ "$wt_status_before" == "$(shasum "$wt_status_r" | cut -d' ' -f1)" ]] || {
  echo "a proposed record was stamped" >&2
  exit 1
}

# Key insertion: a v2 record with last_confirmed removed gains it back in
# contract position, directly after date and before source_refs, and the
# scope still lints clean afterwards.
wt_keyins="$(mktemp -d "${TMPDIR:-/tmp}/i2m-wt-keyins.XXXXXX")"
trap 'rm -rf "$not_a_scope" "$inline_scope" "$dismissal_scope" "$mig" "$jrn" "$t2_extract_scope" "$t2x_dir" "$subset_scope" "$batched_scope" "$lifecycle_scope" "$idem_dir" "$v_pass" "$scripts_copy" "$v_combo" "$v_linkdrop" "$v_lintdefect" "$v1_broken_scope" "$v1_pass_scope" "$wt_headline" "$wt_backward" "$wt_dedupe" "$wt_status" "$wt_keyins"' EXIT
cp -R "$fixtures/mixed/." "$wt_keyins/"
wt_keyins_r="$wt_keyins/_memory/context/atlas-region-topology-mPmy8XBe5H.md"
python3 - "$wt_keyins_r" <<'PY'
import re, sys
p = sys.argv[1]
t = open(p).read()
open(p, "w").write(re.sub(r"^last_confirmed:.*\n", "", t, count=1, flags=re.M))
PY
[[ "$(grep -c '^last_confirmed:' "$wt_keyins_r")" == 0 ]] || {
  echo "the key-insertion fixture still carried last_confirmed before the run" >&2
  exit 1
}
bash "$stamper" "$wt_keyins" --note notes/2026-02-17-atlas-freeze-exceptions-SDy5SGVwfu.md _memory/context/atlas-region-topology-mPmy8XBe5H.md >/dev/null
wt_keyins_head="$(sed -n '1,20p' "$wt_keyins_r")"
wt_keyins_date_ln="$(printf '%s\n' "$wt_keyins_head" | grep -n '^date:' | cut -d: -f1)"
wt_keyins_lc_ln="$(printf '%s\n' "$wt_keyins_head" | grep -n '^last_confirmed:' | cut -d: -f1)"
wt_keyins_src_ln="$(printf '%s\n' "$wt_keyins_head" | grep -n '^source_refs:' | cut -d: -f1)"
[[ -n "$wt_keyins_lc_ln" && "$wt_keyins_lc_ln" -eq "$((wt_keyins_date_ln + 1))" && "$wt_keyins_lc_ln" -eq "$((wt_keyins_src_ln - 1))" ]] || {
  echo "last_confirmed did not land between date: and source_refs:" >&2
  printf '%s\n' "$wt_keyins_head" >&2
  exit 1
}
wt_keyins_lint="$(run_lint "$wt_keyins")"
require_line "$wt_keyins_lint" "failures: 0" wt-keyins

# --- A scope below the repo root still gets its history read (C-7) ----------
#
# Every other verify test makes the scope its own git root, the one shape where
# a scope-relative path and a repo-root-relative path are the same string. Real
# vaults are the other shape: a client sits some directories down from the vault
# root. Reading history with the wrong one swept zero links and still reported a
# pass, so this asserts a non-zero count rather than an exit code.
v_subdir="$(mktemp -d "${TMPDIR:-/tmp}/i2m-verify-subdir.XXXXXX")"
trap 'rm -rf "$not_a_scope" "$inline_scope" "$dismissal_scope" "$mig" "$jrn" "$t2_extract_scope" "$t2x_dir" "$subset_scope" "$batched_scope" "$lifecycle_scope" "$idem_dir" "$v_pass" "$scripts_copy" "$v_combo" "$v_linkdrop" "$v_lintdefect" "$v1_broken_scope" "$v1_pass_scope" "$wt_headline" "$wt_backward" "$wt_dedupe" "$wt_status" "$wt_keyins" "$v_subdir"' EXIT
mkdir -p "$v_subdir/clients/acme"
cp -R "$fixtures/old-only/." "$v_subdir/clients/acme/"
printf '\nSee [[atlas-working-session-P5spzLt4Bz]] for background.\n' >>"$v_subdir/clients/acme/$verify_note_a"
git -C "$v_subdir" init -q
git -C "$v_subdir" add -A
git -C "$v_subdir" -c user.email=t@t -c user.name=t commit -qm baseline
v_subdir_since="$(git -C "$v_subdir" rev-parse HEAD)"
bash "$migrator" "$v_subdir/clients/acme" --apply >/dev/null
git -C "$v_subdir" add -A
git -C "$v_subdir" -c user.email=t@t -c user.name=t commit -qm migrated

v_subdir_out="$(bash "$verify" "$v_subdir/clients/acme" --since "$v_subdir_since")"
require_output "$v_subdir_out" "links checked: 1 (id fallback: 1)"

# The checked-in fixtures are never migrated or stamped in place. Every
# migration or write-through test works on a copy, and a test that forgets
# to copy would otherwise rewrite the fixture it is asserting against and
# pass forever after.
[[ "$(find "$fixtures" -type f -exec shasum {} + | sort)" == "$fixtures_before" ]] || {
  echo "a migration or stamping test wrote to a checked-in fixture" >&2
  exit 1
}

# The third row of the generation table is the one that makes migration possible,
# so the contract has to state it rather than leaving it to the lint's source.
require_text "$contracts" "body_schema"
require_text "$contracts" "A body-shape check therefore keys off \`body_schema\`, never off \`schema: 2\`."

echo "inbox-to-memory smoke: ok"
