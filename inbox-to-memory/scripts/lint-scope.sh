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
NOTE_KEY_ORDER="schema id date type summary attendees tags topics entities source_file transcript_corrections open_questions resolved_questions deferred_tensions unpromoted_candidates related"
RECORD_KEY_ORDER="schema id memory_type title status date effective_from effective_to last_confirmed source_refs applies_to owners tags themes related supersedes superseded_by"

# The closed token vocabulary, as the prefixes a scan actually produces. A token
# shape missing from this list is one nothing can retrieve later, which is the
# failure the vocabulary exists to prevent.
REGISTERED_TOKENS="[memory candidate:
[journal candidate:
[working-state candidate]
[contradicts accepted:
[open question:
[open question resolved:
[tension:"

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

  if [[ "$end" -gt "$FRONTMATTER_LINE_BUDGET" ]]; then
    fail frontmatter-budget "closing --- on line $end, past the $FRONTMATTER_LINE_BUDGET-line budget"
    return
  fi

  local block
  block="$(sed -n "2,$((end - 1))p" "$file")"

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

# Scanning stops at Raw Content. That zone is a verbatim capture of someone else's
# writing, and whatever brackets it happens to contain are not this skill's tokens.
check_tokens() {
  local file="$1"
  local body
  body="$(awk 'f && /^## Raw Content/ { exit } f { print } /^---$/ { c++; if (c == 2) f = 1 }' "$file")"

  # Wiki links go first: an unlabeled [[target]] would otherwise read as a token
  # whose name happens to be the filename.
  local scanned
  scanned="$(printf '%s\n' "$body" | sed 's/\[\[[^]]*\]\]//g')"

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

shopt -s nullglob

# Only files the skill itself creates. CLAUDE.md and README.md live alongside them
# in the same directories and are hand-maintained, so they carry no schema key and
# would otherwise inflate the v1 count with files that can never be migrated.
for file in "$scope"/notes/*.md "$scope"/_memory/*/*.md "$scope"/entries/*.md; do
  case "${file##*/}" in
    CLAUDE.md | README.md) continue ;;
  esac
  if ! has_schema_key "$file"; then
    v1=$((v1 + 1))
    continue
  fi
  v2=$((v2 + 1))
  current_file="$file"
  check_frontmatter "$file"
  check_tokens "$file"
done

echo "scope: $scope"
echo "v1 files: $v1"
echo "v2 files: $v2"
echo "total files: $((v1 + v2))"
echo "failures: $failures"

[[ "$failures" -eq 0 ]]
