#!/usr/bin/env bash
# Write the mechanical half of a confirmation: given the notes that confirmed
# them, set `last_confirmed` on the records they confirmed. Detecting that an
# input confirms a record is judgment and stays in SKILL.md's phase 2.5; this
# script only ever moves a date forward on a record something already named.
#
# One invocation covers the whole run, not one input at a time. That is the
# only way "a record confirmed twice in one run is stamped once" can be a
# property of this script rather than of how the caller happens to loop, and
# it is why resolution is two stages: collapse every --note group's claim on
# a record to one candidate date first, then decide once per record against
# its own current state. Deciding per group instead would let an older group,
# processed after a newer one already wrote, undo part of what the newer one
# did.
#
# It writes by default. The migrator dry-runs first because a migration is a
# batch a human approves; this write is the one the user has agreed in
# advance never to be asked about, so a confirmation prompt in front of it
# would be exactly the thing being removed.
#
# A stamped record changes in exactly one line (the value, or one inserted
# line). This never goes through yq: reserializing the frontmatter reshapes
# quoting and flow-style choices the record's author made on purpose, and
# turns one field's worth of change into a diff over the whole block.
#
# The only bash here is 3.2.57, Apple's — no associative arrays, no mapfile.
# The stage-1 dedupe below is parallel indexed arrays with a linear scan
# instead of a keyed lookup.
set -euo pipefail

FRONTMATTER_LINE_BUDGET=20

usage() {
  cat >&2 <<'USAGE'
usage: stamp-confirmed.sh <scope-root> [--dry-run] \
         --note <note-path> <record-path>... \
         [--note <note-path> <record-path>...]...

  <scope-root>  a directory containing _inbox/ plus _memory/ or entries/
  --dry-run     print what would happen; write nothing. Must sit directly
                after <scope-root>, before the first --note.
  --note        a groomed note whose date confirms the record paths that
                follow it, up to the next --note or the end of the args.
                Note and record paths are absolute, or relative to
                <scope-root>. At least one --note group is required, and
                every group needs at least one record path.
USAGE
}

fail_usage() {
  echo "$1" >&2
  exit 2
}

# --- frontmatter readers, scoped to the block between the two fence lines ---

has_schema_key() {
  awk '
    NR == 1 { if ($0 == "---") { in_fm = 1; next } else { exit } }
    in_fm && $0 == "---" { exit }
    in_fm && /^schema:/ { found = 1; exit }
    END { exit (found ? 0 : 1) }
  ' "$1"
}

# 0 if the file never opens or never closes a frontmatter block. A record in
# that state cannot be classified, so it is validation-time "does not parse"
# rather than a stage-2 branch.
frontmatter_end() {
  awk '
    NR == 1 && $0 != "---" { print 0; done = 1; exit }
    NR > 1 && $0 == "---" { print NR; done = 1; exit }
    END { if (!done) print 0 }
  ' "$1"
}

record_status() {
  awk '
    NR == 1 { if ($0 == "---") { in_fm = 1; next } else { exit } }
    in_fm && $0 == "---" { exit }
    in_fm && /^status:/ { sub(/^status:[[:space:]]*/, ""); print; exit }
  ' "$1"
}

record_last_confirmed() {
  awk '
    NR == 1 { if ($0 == "---") { in_fm = 1; next } else { exit } }
    in_fm && $0 == "---" { exit }
    in_fm && /^last_confirmed:/ { sub(/^last_confirmed:[[:space:]]*/, ""); print; exit }
  ' "$1"
}

# Exits nonzero (and prints nothing) when the note has no `date:` key in its
# frontmatter block. Used both to read the date and, at validation time, to
# tell a note that exists from one that parses.
note_date() {
  awk '
    NR == 1 { if ($0 == "---") { in_fm = 1; next } else { exit } }
    in_fm && $0 == "---" { exit }
    in_fm && /^date:/ { sub(/^date:[[:space:]]*/, ""); print; found = 1; exit }
    END { exit (found ? 0 : 1) }
  ' "$1"
}

# --- path handling ---

resolve_path() {
  local scope="$1" given="$2"
  case "$given" in
    /*) printf '%s\n' "$given" ;;
    *) printf '%s\n' "$scope/$given" ;;
  esac
}

# --- argument parsing ---

[[ $# -ge 1 ]] || {
  usage
  exit 2
}

scope="${1%/}"
shift
[[ -d "$scope" ]] || fail_usage "not a directory: $scope"
scope_real="$(realpath "$scope")"

dry_run=0
if [[ "${1:-}" == "--dry-run" ]]; then
  dry_run=1
  shift
fi

# Groups are two parallel structures: group_note[g] is the g-th --note's
# path, and rec_group[k]/rec_path[k] tag the k-th record argument (in
# command-line order, across every group) with which group it belongs to.
# Bash 3.2 has no associative arrays, so "which group does this record
# belong to" is a lookup into a second indexed array rather than a hash key.
group_count=0
declare -a group_note=()
declare -a group_rec_count=()
declare -a rec_group=()
declare -a rec_path=()

gi=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --note)
      shift
      [[ $# -gt 0 ]] || fail_usage "--note requires a note path"
      gi=$((gi + 1))
      group_note[$gi]="$1"
      group_rec_count[$gi]=0
      group_count=$gi
      shift
      ;;
    *)
      [[ $gi -gt 0 ]] || fail_usage "expected --note, got: $1"
      rec_group+=("$gi")
      rec_path+=("$1")
      group_rec_count[$gi]=$((${group_rec_count[$gi]} + 1))
      shift
      ;;
  esac
done

[[ $group_count -gt 0 ]] || fail_usage "no --note group given"

g=1
while [[ $g -le $group_count ]]; do
  [[ "${group_rec_count[$g]}" -gt 0 ]] || fail_usage "--note ${group_note[$g]} names no records"
  g=$((g + 1))
done

# --- validate every note and record whole, before anything is written ---

problems=""

g=1
declare -a group_full=()
while [[ $g -le $group_count ]]; do
  full="$(resolve_path "$scope" "${group_note[$g]}")"
  group_full[$g]="$full"
  if [[ ! -f "$full" ]]; then
    problems="${problems}${group_note[$g]}: note not found"$'\n'
  elif ! note_date "$full" >/dev/null; then
    problems="${problems}${group_note[$g]}: note has no date: key, does not parse"$'\n'
  fi
  g=$((g + 1))
done

k=0
declare -a rec_full=()
while [[ $k -lt ${#rec_path[@]} ]]; do
  full="$(resolve_path "$scope" "${rec_path[$k]}")"
  rec_full[$k]="$full"
  if [[ ! -f "$full" ]]; then
    problems="${problems}${rec_path[$k]}: record not found"$'\n'
  elif [[ "$(frontmatter_end "$full")" -eq 0 ]]; then
    problems="${problems}${rec_path[$k]}: no closing frontmatter fence, does not parse"$'\n'
  fi
  k=$((k + 1))
done

if [[ -n "$problems" ]]; then
  echo "stamp-confirmed.sh: refusing to write anything; the following did not validate:" >&2
  printf '%s' "$problems" >&2
  exit 2
fi

# --- stage 1: collapse every group's claim on a record to one candidate ---
#
# Nothing here reads a record's own state. A record named by two groups
# takes the later of their note dates; the group that loses is not written
# down anywhere, because it produced no candidate, not a decision.

cand_count=0
declare -a cand_real=()
declare -a cand_rel=()
declare -a cand_date=()

find_candidate() {
  local real="$1" i=0
  while [[ $i -lt $cand_count ]]; do
    if [[ "${cand_real[$i]}" == "$real" ]]; then
      printf '%s\n' "$i"
      return 0
    fi
    i=$((i + 1))
  done
  return 1
}

k=0
while [[ $k -lt ${#rec_path[@]} ]]; do
  g="${rec_group[$k]}"
  date="$(note_date "${group_full[$g]}")"
  real="$(realpath "${rec_full[$k]}")"
  rel="${real#"$scope_real"/}"

  if idx="$(find_candidate "$real")"; then
    if [[ "$date" > "${cand_date[$idx]}" ]]; then
      cand_date[$idx]="$date"
    fi
  else
    cand_real[$cand_count]="$real"
    cand_rel[$cand_count]="$rel"
    cand_date[$cand_count]="$date"
    cand_count=$((cand_count + 1))
  fi
  k=$((k + 1))
done

# --- stage 2: exactly one decision per resolved candidate ---

stamped=0
skipped=0
work="$(mktemp -d "${TMPDIR:-/tmp}/i2m-stamp.XXXXXX")"
trap 'rm -rf "$work"' EXIT
: >"$work/lines"

# Insert `last_confirmed: <date>` in contract position: right after the last
# of schema/body_schema/id/memory_type/title/status/date/effective_from/
# effective_to that the record actually carries, which — because the record
# already lints clean going in — is also the line right before wherever
# source_refs (or the next present key) already sits.
insert_last_confirmed() {
  local file="$1" newdate="$2" anchor
  anchor="$(awk '
    NR == 1 { next }
    $0 == "---" { exit }
    /^(schema|body_schema|id|memory_type|title|status|date|effective_from|effective_to):/ { a = NR }
    END { print a + 0 }
  ' "$file")"
  awk -v anchor="$anchor" -v line="last_confirmed: $newdate" \
    'NR == anchor { print; print line; next } { print }' "$file"
}

update_last_confirmed() {
  local file="$1" newdate="$2"
  sed "s/^last_confirmed:.*/last_confirmed: $newdate/" "$file"
}

i=0
while [[ $i -lt $cand_count ]]; do
  real="${cand_real[$i]}"
  rel="${cand_rel[$i]}"
  candidate_date="${cand_date[$i]}"

  if ! has_schema_key "$real"; then
    line="skipped: $rel (no schema key, v1)"
    skipped=$((skipped + 1))
  else
    status="$(record_status "$real")"
    if [[ "$status" != "accepted" ]]; then
      line="skipped: $rel (status: $status, not accepted)"
      skipped=$((skipped + 1))
    else
      existing="$(record_last_confirmed "$real")"
      if [[ -n "$existing" ]]; then
        if [[ "$candidate_date" > "$existing" ]]; then
          line="stamped: $rel $existing -> $candidate_date"
          stamped=$((stamped + 1))
          [[ "$dry_run" -eq 1 ]] || {
            update_last_confirmed "$real" "$candidate_date" >"$work/new"
            cat "$work/new" >"$real"
          }
        else
          line="skipped: $rel ($candidate_date is not later than $existing)"
          skipped=$((skipped + 1))
        fi
      else
        old_end="$(frontmatter_end "$real")"
        new_end=$((old_end + 1))
        if [[ "$new_end" -gt "$FRONTMATTER_LINE_BUDGET" ]]; then
          line="skipped: $rel (last_confirmed insertion would close frontmatter at line $new_end, past the $FRONTMATTER_LINE_BUDGET-line budget)"
          skipped=$((skipped + 1))
        else
          line="stamped: $rel none -> $candidate_date"
          stamped=$((stamped + 1))
          [[ "$dry_run" -eq 1 ]] || {
            insert_last_confirmed "$real" "$candidate_date" >"$work/new"
            cat "$work/new" >"$real"
          }
        fi
      fi
    fi
  fi

  printf '%s\t%s\n' "$rel" "$line" >>"$work/lines"
  i=$((i + 1))
done

sort -t "$(printf '\t')" -k1,1 "$work/lines" | cut -f2-
printf 'stamped: %d  skipped: %d\n' "$stamped" "$skipped"
