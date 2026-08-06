#!/usr/bin/env bash
# Rewrite one opted-in scope's v1 frontmatter onto the v2 contract, and touch
# nothing below the fence.
#
# Tier 1 is the mechanical half of migration: every transformation here has
# exactly one correct answer, which is why the whole tier can be approved in one
# go. Anything needing judgment (writing a summary, naming entities, choosing a
# relation for a bare id) is reported and left alone.
#
# The body is copied byte for byte, so a migrated file is v2 above the fence and
# v1 below it. It says so with `body_schema: 1`, which is what stops the lint from
# holding a note written in 2025 to a grammar that did not exist yet.
#
# Requires bash, awk, yq, and git. The awk does the frontmatter rewrite because
# the transform needs keyed lookups, and the bash that ships on macOS has none.
set -euo pipefail

NOTE_KEY_ORDER="schema body_schema id date type summary attendees tags topics entities source_file transcript_corrections open_questions resolved_questions deferred_tensions unpromoted_candidates related"
RECORD_KEY_ORDER="schema body_schema id memory_type title status date effective_from effective_to last_confirmed source_refs applies_to owners tags themes related exception_to supersedes superseded_by"

FRONTMATTER_LINE_BUDGET=20

apply=0
allow_dirty=0
scope=""

usage() {
  cat >&2 <<'USAGE'
usage: migrate-scope.sh <scope-path> [--apply] [--allow-dirty]

  <scope-path>    a directory containing _inbox/ plus _memory/ or entries/
  --apply         write the changes; without it nothing is written
  --allow-dirty   proceed even though the working tree has uncommitted changes
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) apply=1 ;;
    --allow-dirty) allow_dirty=1 ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*)
      echo "unknown option: $1" >&2
      usage
      exit 2
      ;;
    *)
      [[ -n "$scope" ]] && {
        echo "migrate one scope at a time" >&2
        exit 2
      }
      scope="${1%/}"
      ;;
  esac
  shift
done

[[ -n "$scope" ]] || {
  usage
  exit 2
}

[[ -d "$scope" ]] || {
  echo "not a directory: $scope" >&2
  exit 2
}

if [[ ! -d "$scope/_inbox" ]] || { [[ ! -d "$scope/_memory" ]] && [[ ! -d "$scope/entries" ]]; }; then
  echo "not an opted-in scope: $scope (needs _inbox/ plus _memory/ or entries/)" >&2
  exit 2
fi

command -v yq >/dev/null 2>&1 || {
  echo "yq is required and not on PATH (brew install yq)" >&2
  exit 2
}

# Every safety claim this script makes rests on `git diff` being readable
# afterward. Starting from a dirty tree makes a mistake here indistinguishable
# from whatever was already uncommitted, so the escape hatch is explicit.
if [[ "$apply" -eq 1 && "$allow_dirty" -eq 0 ]]; then
  if ! git -C "$scope" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "not inside a git repository; rerun with --allow-dirty if that is intended" >&2
    exit 2
  fi
  if [[ -n "$(git -C "$scope" status --porcelain .)" ]]; then
    echo "working tree has uncommitted changes under $scope" >&2
    echo "commit or stash first, or rerun with --allow-dirty" >&2
    exit 2
  fi
fi

work="$(mktemp -d "${TMPDIR:-/tmp}/i2m-migrate.XXXXXX")"
trap 'rm -rf "$work"' EXIT

migrated=0
skipped=0
refused=0
: >"$work/findings"

has_schema_key() {
  awk '
    NR == 1 { if ($0 == "---") { in_fm = 1; next } else { exit } }
    in_fm && $0 == "---" { exit }
    in_fm && /^schema:/ { found = 1; exit }
    END { exit (found ? 0 : 1) }
  ' "$1"
}

frontmatter_end() {
  awk '
    NR == 1 && $0 != "---" { print 0; done = 1; exit }
    NR > 1 && $0 == "---" { print NR; done = 1; exit }
    END { if (!done) print 0 }
  ' "$1"
}

# Byte-for-byte the extraction the lint uses. Two implementations of one counting
# rule is how a migrated scope ends up failing the check meant to certify it.
extract_body() {
  awk '
    f && /^## Raw Content/ { exit }
    f && /<!--/ { in_comment = 1 }
    f && in_comment { if (/-->/) in_comment = 0; next }
    f { print }
    /^---$/ { c++; if (c == 2) f = 1 }
  ' "$1"
}

count_matches() {
  { grep -oE -- "$2" "$1" 2>/dev/null || true; } | wc -l | tr -d ' '
}

count_open_contradictions() {
  { grep -F -- '[contradicts accepted:' "$1" || true; } |
    { grep -Fvc -- '| dismissed:' || true; } | tr -d ' '
}

props_value() {
  awk -v k="$2" '
    { sep = index($0, " = "); if (sep == 0) next }
    substr($0, 1, sep - 1) == k { print substr($0, sep + 3); exit }
  ' "$1"
}

render_frontmatter() {
  awk -v order="$2" -v extras="$3" -v label="$4" '
    # Inside a flow sequence a colon is only structural when a space follows it,
    # which is what lets `extends::JJuYgImRWn` stay bare and match the shape the
    # templates emit. Titles and summaries are prose and always get quoted, so a
    # migrated record reads the same as one the skill wrote today.
    function yamlize(k, v) {
      if (k == "title" || k == "summary" || v == "" ||
          v ~ /[#,[\]{}'"'"']/ || v ~ /: / || v ~ /:$/ ||
          v ~ /^[ ]/ || v ~ /[ ]$/) {
        gsub(/'"'"'/, "'"'"''"'"'", v)
        return "'"'"'" v "'"'"'"
      }
      return v
    }
    function note(msg) { print "  " label ": " msg > "/dev/stderr" }
    BEGIN {
      split(order, ord, " ")
      n_ex = split(extras, ex, ";")
      for (i = 1; i <= n_ex; i++) {
        if (ex[i] == "") continue
        p = index(ex[i], "=")
        k = substr(ex[i], 1, p - 1)
        scal[k] = substr(ex[i], p + 1)
        have[k] = 1
      }
    }
    {
      sep = index($0, " = ")
      if (sep == 0) next
      path = substr($0, 1, sep - 1)
      value = substr($0, sep + 3)
      nd = split(path, part, ".")
      key = part[1]
      if (!(key in seen)) { seen[key] = 1; order_in[++nk] = key }
      if (nd == 1) {
        if (!(key in have)) scal[key] = value
        have[key] = 1
      } else if (nd == 2) {
        idx = part[2] + 0
        item[key SUBSEP idx] = value
        if (idx + 1 > cnt[key]) cnt[key] = idx + 1
        islist[key] = 1
      } else {
        idx = part[2] + 0
        field[key SUBSEP idx SUBSEP part[3]] = value
        subfields[key SUBSEP idx] = subfields[key SUBSEP idx] " " part[3]
        if (idx + 1 > cnt[key]) cnt[key] = idx + 1
        islist[key] = 1
      }
    }
    END {
      # A relationship is one greppable string. The left half carries the meaning,
      # so an entry that never recorded one cannot be flattened without inventing
      # it: that entry keeps its bare id and gets named in the report instead.
      for (k in cnt) {
        for (i = 0; i < cnt[k]; i++) {
          if ((k SUBSEP i) in item) continue
          id = ((k SUBSEP i SUBSEP "note_id") in field) ? field[k SUBSEP i SUBSEP "note_id"] : ""
          lhs = ""
          if (k == "related" && (k SUBSEP i SUBSEP "relation") in field)
            lhs = field[k SUBSEP i SUBSEP "relation"]
          if (k == "source_refs" && (k SUBSEP i SUBSEP "path") in field)
            lhs = field[k SUBSEP i SUBSEP "path"]
          if (lhs != "" && id != "") item[k SUBSEP i] = lhs "::" id
          else if (id != "") item[k SUBSEP i] = id
          else item[k SUBSEP i] = ""

          # A compound string has room for exactly two halves. Anything else the
          # old mapping carried is about to stop existing, so it gets named here
          # rather than discovered missing a year from now.
          consumed = (k == "source_refs") ? " note_id path " : " note_id relation "
          n_sub = split(subfields[k SUBSEP i], subkey, " ")
          for (s = 1; s <= n_sub; s++) {
            if (subkey[s] == "" || index(consumed, " " subkey[s] " ")) continue
            note("`" k "` entry " i " dropped `" subkey[s] ": " field[k SUBSEP i SUBSEP subkey[s]] "`, which the compound form has no room for")
          }
        }
      }
      for (i = 0; i < cnt["related"]; i++) {
        v = item["related" SUBSEP i]
        if (v != "" && index(v, "::") == 0)
          note("`related` holds bare id `" v "`; a relation has to be chosen by hand")
      }

      for (i = 1; i in ord; i++) emit(ord[i])
      # Anything the contract never named survives at the end rather than being
      # dropped. Silent loss during a migration is the failure nobody notices
      # until the note they needed it from is a year old.
      for (i = 1; i <= nk; i++) {
        k = order_in[i]
        if (k in emitted) continue
        emit(k)
        note("`" k "` is in neither key order and was kept at the end")
      }
    }
    function emit(k,   i, items, v) {
      if (k in emitted) return
      if (islist[k]) {
        items = ""
        for (i = 0; i < cnt[k]; i++) {
          v = item[k SUBSEP i]
          if (v == "") continue
          items = items (items == "" ? "" : ", ") yamlize(k, v)
        }
        print k ": [" items "]"
        emitted[k] = 1
      } else if (k in have) {
        print k ": " yamlize(k, scal[k])
        emitted[k] = 1
      }
    }
  ' "$1"
}

shopt -s nullglob

for file in "$scope"/notes/*.md "$scope"/_memory/*/*.md "$scope"/entries/*.md; do
  case "${file##*/}" in
    CLAUDE.md | README.md) continue ;;
  esac

  if has_schema_key "$file"; then
    skipped=$((skipped + 1))
    continue
  fi

  end="$(frontmatter_end "$file")"
  if [[ "$end" -eq 0 ]]; then
    echo "  $file: no frontmatter block to migrate" >>"$work/findings"
    refused=$((refused + 1))
    continue
  fi

  sed -n "2,$((end - 1))p" "$file" >"$work/block"

  if ! yq -o=props '.' "$work/block" >"$work/props" 2>/dev/null; then
    echo "  $file: yq could not parse the existing frontmatter, left alone" >>"$work/findings"
    refused=$((refused + 1))
    continue
  fi

  extras="schema=2;body_schema=1"

  if grep -q '^memory_type = ' "$work/props"; then
    order="$RECORD_KEY_ORDER"
    # A record nobody has re-confirmed was last confirmed the day it was written.
    # Any later date would assert a review that never happened.
    if ! grep -q '^last_confirmed = ' "$work/props"; then
      record_date="$(props_value "$work/props" date)"
      [[ -n "$record_date" ]] && extras="$extras;last_confirmed=$record_date"
    fi
  else
    order="$NOTE_KEY_ORDER"
    extract_body "$file" >"$work/body"
    unpromoted="$(count_matches "$work/body" '\[(memory candidate:|journal candidate:|working-state candidate\])')"
    extras="$extras;open_questions=$(count_matches "$work/body" '\[open question:')"
    extras="$extras;resolved_questions=$(count_matches "$work/body" '\[open question resolved:')"
    extras="$extras;deferred_tensions=$(count_matches "$work/body" '\[tension: deferred\]')"
    extras="$extras;unpromoted_candidates=$((unpromoted + $(count_open_contradictions "$work/body")))"
  fi

  # The renderer writes findings to stderr, so a crash would otherwise land in the
  # report looking like one more thing needing a human. A migrator that fails
  # quietly is worse than one that fails.
  if ! render_frontmatter "$work/props" "$order" "$extras" "$file" \
    >"$work/new-fm" 2>"$work/notes"; then
    echo "could not rewrite the frontmatter of $file" >&2
    cat "$work/notes" >&2
    exit 1
  fi
  cat "$work/notes" >>"$work/findings"

  lines="$(wc -l <"$work/new-fm" | tr -d ' ')"
  if [[ $((lines + 2)) -gt "$FRONTMATTER_LINE_BUDGET" ]]; then
    echo "  $file: rewritten frontmatter needs $((lines + 2)) lines, past the $FRONTMATTER_LINE_BUDGET-line budget; left alone" >>"$work/findings"
    refused=$((refused + 1))
    continue
  fi

  if ! yq '.' "$work/new-fm" >/dev/null 2>&1; then
    echo "  $file: the rewritten frontmatter does not parse; left alone" >>"$work/findings"
    refused=$((refused + 1))
    continue
  fi

  {
    echo "---"
    cat "$work/new-fm"
    echo "---"
    tail -n +$((end + 1)) "$file"
  } >"$work/candidate"

  echo "--- $file"
  diff -u <(sed -n "1,${end}p" "$file") <(sed -n "1,$((lines + 2))p" "$work/candidate") |
    tail -n +3 || true

  [[ "$apply" -eq 1 ]] && cat "$work/candidate" >"$file"
  migrated=$((migrated + 1))
done

echo
echo "scope: $scope"
echo "migrated: $migrated"
echo "already v2: $skipped"
echo "left alone: $refused"

if [[ -s "$work/findings" ]]; then
  echo
  echo "needs a human:"
  cat "$work/findings"
fi

if [[ "$apply" -eq 0 ]]; then
  echo
  echo "dry run; nothing was written. rerun with --apply to write these changes."
fi
