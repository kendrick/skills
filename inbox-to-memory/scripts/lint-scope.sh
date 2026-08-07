#!/usr/bin/env bash
# Walk one opted-in scope and check every v2 note and record against the machine
# contracts in references/machine-contracts.md.
#
# This ships as a script rather than prose the agent follows because most of what
# the v2 schema promises is arithmetic: keys in a fixed order, a block that fits
# in a header read, a closed token vocabulary. An agent asked to check that by
# reading will report success it never verified.
#
# Nothing here ever flags a v1 file. Files without a `schema` key predate the
# contract, they stay legal indefinitely, and a scope holding both generations is
# a supported state rather than a migration someone abandoned halfway.
#
# Requires bash, awk, and yq (brew install yq).
set -euo pipefail

# Contract key orders. Duplicated by hand into the templates and, later, the
# migrator; the smoke test pins all three copies to the same string so a drift
# fails there before it reaches a scope.
NOTE_KEY_ORDER="schema body_schema id date type summary attendees tags topics entities source_file transcript_corrections open_questions resolved_questions deferred_tensions unpromoted_candidates related"
RECORD_KEY_ORDER="schema body_schema id memory_type title status date effective_from effective_to last_confirmed source_refs applies_to owners tags themes related exception_to supersedes superseded_by"

# The closed token vocabulary, as the prefixes a scan actually produces. A token
# shape missing from this list is one nothing can retrieve later, which is the
# failure the vocabulary exists to prevent.
REGISTERED_TOKENS="[memory candidate:
[journal candidate:
[working-state candidate]
[contradicts accepted:
[open question:
[open question resolved:
[tension:
[decision:"

FRONTMATTER_LINE_BUDGET=20

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

if ! command -v yq >/dev/null 2>&1; then
  echo "yq is required and not on PATH (brew install yq)" >&2
  exit 2
fi

v1=0
v2=0
failures=0
current_file=""
declare -a body_for_index=()

fail() {
  echo "FAIL $current_file: $1: $2"
  failures=$((failures + 1))
}

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

# Migration rewrites frontmatter and leaves the body exactly as it was, so a
# migrated file is v2 above the fence and v1 below it. `body_schema: 1` is that
# file saying so. Without it the first migration run would turn every bare line
# anchor written in 2025 into a lint failure, and the only way to clear them
# would be editing notes whose whole value is being a record of that day.
has_v1_body() {
  awk '
    NR == 1 { if ($0 == "---") { in_fm = 1; next } else { exit } }
    in_fm && $0 == "---" { exit }
    in_fm && /^body_schema:[[:space:]]*1[[:space:]]*$/ { found = 1; exit }
    END { exit (found ? 0 : 1) }
  ' "$1"
}

# Line number of the closing fence, or 0 if the file doesn't open and close one.
frontmatter_end() {
  awk '
    NR == 1 && $0 != "---" { print 0; done = 1; exit }
    NR > 1 && $0 == "---" { print NR; done = 1; exit }
    END { if (!done) print 0 }
  ' "$1"
}

# Every present key must appear in the contract order, and in that order. Omitted
# keys are fine: the contract fixes sequence, not membership, so a note without a
# source file doesn't have to carry an empty one to stay compliant.
check_key_order() {
  local -a actual=() contract=()
  read -r -a contract <<<"$2"
  while IFS= read -r k; do
    [[ -n "$k" ]] && actual+=("$k")
  done <<<"$1"

  local key unknown=""
  for key in "${actual[@]}"; do
    local known=0 c
    for c in "${contract[@]}"; do
      [[ "$key" == "$c" ]] && known=1 && break
    done
    [[ "$known" -eq 0 ]] && unknown="$key" && break
  done
  if [[ -n "$unknown" ]]; then
    fail frontmatter-known-keys "\`$unknown\` is in neither key order"
    return
  fi

  local i=0 c
  for c in "${contract[@]}"; do
    [[ $i -lt ${#actual[@]} && "${actual[$i]}" == "$c" ]] && i=$((i + 1))
  done
  if [[ $i -ne ${#actual[@]} ]]; then
    fail frontmatter-key-order "expected contract order, got: ${actual[*]}"
  fi
}

check_frontmatter() {
  local file="$1"
  local end
  end="$(frontmatter_end "$file")"

  if [[ "$end" -eq 0 ]]; then
    fail frontmatter-fences "no closing --- for the frontmatter block"
    return
  fi

  local block
  block="$(sed -n "2,$((end - 1))p" "$file")"

  # Ahead of the budget guard on purpose: every file this check exists for is
  # 21 lines and hits that guard's `return` first if the check runs after it,
  # which is exactly the bug this check exists to fix.
  local tags_lines themes_lines
  tags_lines="$(printf '%s\n' "$block" | grep -cE '^tags:' || true)"
  themes_lines="$(printf '%s\n' "$block" | grep -cE '^themes:' || true)"
  if [[ "$tags_lines" -gt 0 && "$themes_lines" -gt 0 ]]; then
    fail frontmatter-key-domain "carries both \`tags\` and \`themes\`, a record's key and a journal entry's"
    return
  fi

  if [[ "$end" -gt "$FRONTMATTER_LINE_BUDGET" ]]; then
    fail frontmatter-budget "closing --- on line $end, past the $FRONTMATTER_LINE_BUDGET-line budget"
    return
  fi

  if ! printf '%s\n' "$block" | yq '.' >/dev/null 2>&1; then
    fail frontmatter-parses "yq could not parse the block"
    return
  fi

  # A comment or a `key: value` at column zero, and nothing else. This one textual
  # rule catches block-style lists, nested mappings, and wrapped values together,
  # which is why it is worth more than three separate structural checks.
  local offender
  offender="$(printf '%s\n' "$block" | grep -nvE '^[[:space:]]*$|^#|^[A-Za-z_][A-Za-z0-9_]*:' | head -1 || true)"
  if [[ -n "$offender" ]]; then
    local lineno="${offender%%:*}"
    fail frontmatter-single-line "line $((lineno + 1)) is not a comment or a single-line key: ${offender#*:}"
    return
  fi

  local keys order
  keys="$(printf '%s\n' "$block" | yq 'keys | .[]' 2>/dev/null || true)"
  if printf '%s\n' "$keys" | grep -qx 'memory_type'; then
    order="$RECORD_KEY_ORDER"
  else
    order="$NOTE_KEY_ORDER"
  fi
  check_key_order "$keys" "$order"
}

# Everything token-shaped is read from here, and it stops at Raw Content. That zone
# is a verbatim capture of someone else's writing, and whatever brackets it happens
# to contain are not this skill's tokens.
# HTML comments come out too. Section guidance ships commented in the templates
# precisely so it doesn't render, and its example tokens are illustrations rather
# than claims about this note. Stripping them here rather than per-check is what
# keeps the token scan and the derived counts reading the same body.
extract_body() {
  awk '
    f && /^## Raw Content/ { exit }
    f && /<!--/ { in_comment = 1 }
    f && in_comment { if (/-->/) in_comment = 0; next }
    f { print }
    /^---$/ { c++; if (c == 2) f = 1 }
  ' "$1"
}

check_tokens() {
  # Wiki links go first: an unlabeled [[target]] would otherwise read as a token
  # whose name happens to be the filename.
  local scanned
  scanned="$(sed 's/\[\[[^]]*\]\]//g' "$1")"

  local token
  while IFS= read -r token; do
    [[ -z "$token" ]] && continue
    if ! printf '%s\n' "$REGISTERED_TOKENS" | grep -Fqx -- "$token"; then
      fail token-grammar "\`$token\` is not in the grammar table"
    fi
  done < <(printf '%s\n' "$scanned" | grep -oE '\[[a-z][a-z0-9 -]*(:|\])' | sort -u)

  # The scope token is part of the registered shape, not free text after a colon.
  local bad_scope
  bad_scope="$(printf '%s\n' "$scanned" | grep -F '[memory candidate:' | grep -vE '\[memory candidate: (project|client|update existing )' | head -1 || true)"
  if [[ -n "$bad_scope" ]]; then
    fail token-grammar "memory candidate needs scope project, client, or update existing: $bad_scope"
  fi
}

# grep exits 1 on no match, and under `set -o pipefail` that would abort the run
# on the first clean file rather than reporting a zero.
count_matches() {
  { grep -oE -- "$2" "$1" 2>/dev/null || true; } | wc -l | tr -d ' '
}

# A dismissed contradiction is settled, not outstanding. It keeps its flag as
# provenance of what was considered, and counting it forever would make "every
# note with unfinished business" a query that never comes back empty.
count_open_contradictions() {
  { grep -F -- '[contradicts accepted:' "$1" || true; } |
    { grep -Fvc -- '| dismissed:' || true; } | tr -d ' '
}

frontmatter_number() {
  awk -v key="$2" '
    NR == 1 && $0 != "---" { exit }
    NR > 1 && $0 == "---" { exit }
    $0 ~ "^" key ":" { sub(/^[^:]*:[[:space:]]*/, ""); print; found = 1; exit }
    END { if (!found) print "absent" }
  ' "$1"
}

# Slugs carry a question's identity between notes, so they have to be stable and
# typo-visible. Two to five kebab words is short enough to retype from memory and
# long enough that two different questions don't collide.
SLUG_RE='^[a-z0-9]+(-[a-z0-9]+){1,4}$'

check_open_questions() {
  local body="$1"
  local line slug
  while IFS= read -r line; do
    slug="$(sed -E 's/^.*\[open question: ([^]]*)\].*$/\1/' <<<"$line")"
    if ! [[ "$slug" =~ $SLUG_RE ]]; then
      fail open-question-slug "\`$slug\` is not a 2-to-5-word kebab slug"
    fi
    local field
    for field in resolver blocks default; do
      grep -Fq -- "| $field:" <<<"$line" || fail open-question-fields "\`$slug\` is missing \`$field\`"
    done
  done < <(grep -F -- '[open question:' "$body" || true)
}

check_tensions() {
  local body="$1"
  local line disposition
  local -a claimed=()
  while IFS= read -r line; do
    disposition="$(sed -E 's/^.*\[tension: ([^]]*)\].*$/\1/' <<<"$line")"
    case "$disposition" in
      resolved | deferred | unacknowledged) ;;
      *)
        fail tension-fields "\`$disposition\` is not resolved, deferred, or unacknowledged"
        continue
        ;;
    esac
    grep -Fq -- '| stakes:' <<<"$line" || fail tension-fields "this $disposition tension is missing \`stakes\`"
    [[ "$disposition" == resolved ]] && ! grep -Fq -- '| resolved:' <<<"$line" &&
      fail tension-fields "a resolved tension does not record its resolution"

    [[ "$disposition" != deferred ]] && continue

    local slug
    slug="$(sed -E 's/^.*\| open question: ([a-z0-9-]+).*$/\1/' <<<"$line")"
    if [[ "$slug" == "$line" ]]; then
      fail tension-deferred-pairing "a deferred tension names no open question"
      continue
    fi
    # One to one, both ways. A slug claimed twice means two tensions are riding on
    # one thread, and closing the question would silently close both.
    local prior
    for prior in ${claimed[@]+"${claimed[@]}"}; do
      [[ "$prior" == "$slug" ]] && fail tension-deferred-pairing "two deferred tensions both claim \`$slug\`"
    done
    claimed+=("$slug")
    grep -Fq -- "[open question: $slug]" "$body" ||
      fail tension-deferred-pairing "deferred tension names \`$slug\`, which this note never opens"
  done < <(grep -F -- '[tension:' "$body" || true)
}

# A contradiction is the one flag that asserts something about a file other than
# the one it lives in, so it carries both halves of the disagreement. Without the
# record's own claim written down beside the new statement, settling it means
# opening the record to find out whether the two ever actually disagreed.
check_contradictions() {
  local body="$1"
  local line
  while IFS= read -r line; do
    if ! grep -qE '\[contradicts accepted: \[\[[^]|]+\|[^]]+\]\]\]' <<<"$line"; then
      fail contradiction-fields "this contradiction names no record it contradicts"
      continue
    fi
    grep -Fq -- '| claims:' <<<"$line" ||
      fail contradiction-fields "this contradiction does not state what the record claims"
  done < <(grep -F -- '[contradicts accepted:' "$body" || true)
}

check_decisions() {
  local body="$1"
  local line reversibility
  while IFS= read -r line; do
    reversibility="$(sed -E 's/^.*\[decision: ([^]]*)\].*$/\1/' <<<"$line")"
    case "$reversibility" in
      one-way | two-way) ;;
      *) fail decision-fields "\`$reversibility\` is not one-way or two-way" ;;
    esac
    # The discarded alternatives are the payload. What got decided is recoverable
    # from the transcript; what got ruled out, and why, is not.
    grep -Fq -- '| discarded:' <<<"$line" ||
      fail decision-fields "a decision records no discarded alternatives"
  done < <(grep -F -- '[decision:' "$body" || true)
}

# Line numbers move the first time raw content is reflowed, and a reference that
# silently points at the wrong line is worse than one that points nowhere.
check_anchors() {
  local offender
  offender="$(grep -oE '\(raw: [^")]*\)' "$1" | head -1 || true)"
  [[ -n "$offender" ]] && fail anchor-form "\`$offender\` is a bare line ref; quote 4-6 verbatim words"
  return 0
}

# Files are never renamed, so a link whose literal target is missing is usually a
# file that moved rather than one that vanished. The id is the last ten characters
# of the target and it never changes, which is why the fallback resolves before
# anything gets reported broken.
check_links() {
  local target
  while IFS= read -r target; do
    [[ -z "$target" ]] && continue
    # An unsubstituted placeholder is not a link. Templates ship with them, and
    # resolving one would mean asserting a file named `{{nanoid}}` should exist.
    case "$target" in
      *'{{'* | *'<'*) continue ;;
    esac
    find "$scope" -name "$target.md" -print -quit | grep -q . && continue
    local id="${target: -10}"
    find "$scope" -name "*$id*.md" -print -quit | grep -q . && continue
    fail link-broken "\`$target\` resolves neither by name nor by id \`$id\`"
  done < <(grep -oE '\[\[[^]|]*' "$1" | sed 's/^\[\[//' | sort -u || true)
}

check_counts() {
  local file="$1" body="$2"
  local key expected stated
  for key in open_questions resolved_questions deferred_tensions unpromoted_candidates; do
    case "$key" in
      open_questions) expected="$(count_matches "$body" '\[open question:')" ;;
      resolved_questions) expected="$(count_matches "$body" '\[open question resolved:')" ;;
      deferred_tensions) expected="$(count_matches "$body" '\[tension: deferred\]')" ;;
      unpromoted_candidates)
        expected="$(count_matches "$body" '\[(memory candidate:|journal candidate:|working-state candidate\])')"
        expected=$((expected + $(count_open_contradictions "$body")))
        ;;
    esac
    stated="$(frontmatter_number "$file" "$key")"
    if [[ "$stated" == "absent" ]]; then
      fail derived-counts "\`$key\` is missing; v2 notes carry all four even at zero"
    elif [[ "$stated" != "$expected" ]]; then
      fail derived-counts "\`$key\` says $stated, body has $expected"
    fi
  done
}

shopt -s nullglob

work="$(mktemp -d "${TMPDIR:-/tmp}/i2m-lint.XXXXXX")"
trap 'rm -rf "$work"' EXIT
: >"$work/open-slugs"

# Pass one classifies and caches each v2 body, because the resolution and
# recurrence checks are scope-wide: they can't be answered from inside one file.
v2_files=()
index=0
for file in "$scope"/notes/*.md "$scope"/_memory/*/*.md "$scope"/entries/*.md; do
  # Only files the skill itself creates. CLAUDE.md and README.md live alongside
  # them and are hand-maintained, so they carry no schema key and would otherwise
  # inflate the v1 count with files that can never be migrated.
  case "${file##*/}" in
    CLAUDE.md | README.md) continue ;;
  esac
  if ! has_schema_key "$file"; then
    v1=$((v1 + 1))
    continue
  fi
  v2=$((v2 + 1))
  v2_files+=("$file")
  index=$((index + 1))
  body_for_index[$index]="$work/body.$index"
  extract_body "$file" >"$work/body.$index"
  grep -oE -- '\[open question: [^]]*\]' "$work/body.$index" |
    sed -E 's/\[open question: (.*)\]/\1/' | sort -u >>"$work/open-slugs" || true
done

index=0
for file in ${v2_files[@]+"${v2_files[@]}"}; do
  index=$((index + 1))
  current_file="$file"
  body="${body_for_index[$index]}"
  check_frontmatter "$file"

  # The body grammar checks are the ones a v1 body cannot satisfy and was never
  # asked to. Links and counts stay on either way: a link that resolves nowhere is
  # broken in any generation, and the migrator computes the counts it writes.
  if ! has_v1_body "$file"; then
    check_tokens "$body"
    check_open_questions "$body"
    check_tensions "$body"
    check_contradictions "$body"
    check_decisions "$body"
    check_anchors "$body"
  fi
  check_links "$body"
  # Records carry no body tokens and no counts; the four keys are a note contract.
  grep -q '^memory_type:' "$file" || check_counts "$file" "$body"

  # A resolution whose slug was never opened is almost always a typo, and the cost
  # of missing it is a thread that looks closed while the question stays live.
  while IFS= read -r slug; do
    grep -Fqx -- "$slug" "$work/open-slugs" ||
      fail open-question-resolution "\`$slug\` is resolved here but never opened anywhere in scope"
  done < <(grep -oE -- '\[open question resolved: [^]]*\]' "$body" | sed -E 's/\[open question resolved: (.*)\]/\1/' | sort -u)
done

# A question open across three or more notes has outlived anyone's intention to
# answer it, and arithmetic is better at noticing that than memory is. Three is a
# guess and cheap to change; revisit it after a few weeks of real use.
#
# This reports rather than fails. A recurring question is a finding about the
# engagement, not a defect in a file, and process mode is what promotes it to an
# unacknowledged tension.
RECURRENCE_THRESHOLD=3
while read -r occurrences slug; do
  [[ "$occurrences" -ge "$RECURRENCE_THRESHOLD" ]] &&
    echo "RECURRING $slug: open in $occurrences notes"
done < <(sort "$work/open-slugs" | uniq -c | sort -rn) || true

echo "scope: $scope"
echo "v1 files: $v1"
echo "v2 files: $v2"
echo "total files: $((v1 + v2))"
echo "failures: $failures"

[[ "$failures" -eq 0 ]]
