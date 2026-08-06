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
# arithmetic is off by one because a contradiction has to point at something
# accepted: the lone record in this scope is link bait, carries no defect, and is
# the reason failures trail the file count.
broken_out="$(run_lint "$fixtures/broken")"
require_line "$broken_out" "v1 files: 0" broken
require_line "$broken_out" "v2 files: 19" broken
require_line "$broken_out" "failures: 18" broken

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

# The record the flag points at is clean. Asserting that here is what keeps the
# link bait from quietly becoming an eighteenth defect nobody planted.
refute_failure "$broken_out" "vendor-lock-window-WJicoHVdFw.md"

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
require_text inbox-to-memory/SKILL.md "one sanctioned exception to preserving raw content"
collapsed="$(bash "$vtt" "$fixtures/steerco-excerpt.vtt")"
[[ "$(printf '%s\n' "$collapsed" | wc -l | tr -d ' ')" == "3" ]] || {
  echo "six cues from three speakers' turns should collapse to three lines" >&2
  printf '%s\n' "$collapsed" >&2
  exit 1
}
require_line "$collapsed" "[00:00:01] Priya Raghavan: Cutover is a date, not a readiness state, and that is the problem." vtt
require_line "$collapsed" "[00:00:06] Marcus Dell: Finance gave us a date. It is in writing. That one is done." vtt
# The last turn exercises the other speaker form and a continuation line with no
# speaker of its own, which is where a naive collapser drops half a sentence.
require_line "$collapsed" "[00:00:11] Priya Raghavan: Third meeting, same question, still nobody's name on it." vtt

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

echo "inbox-to-memory smoke: ok"
