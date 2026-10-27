#!/usr/bin/env bash
# Move each v2 note's `## Raw Content` zone into a `notes/raw/<id>.md` sidecar,
# so an embedding index can exclude notes/raw/ and stop drowning the reviewed
# layer in transcript chunks (#193). The contract is the "Raw Sidecar" section
# of references/machine-contracts.md.
#
# The sidecar is every byte after the heading line, copied with tail rather
# than rebuilt line by line, because the contract promises note plus sidecar
# reproduce the raw text exactly, trailing newline or not. Anchor numbers shift
# by the heading's line number and nothing else: the text moved verbatim, so
# arithmetic is exact here, unlike reflow-raw.sh, which has to search.
#
# V1 bodies are never split (no `schema` key, or `body_schema: 1`), nor are
# notes already carrying `raw_file` or with nothing under the heading. An
# existing sidecar is never overwritten: that note is refused and left alone.
#
# Exit codes follow check-territories.py: 0 done, 1 a note was refused,
# 3 usage or an unreadable scope.
set -euo pipefail

# Copied from lint-scope.sh, which the smoke test pins this copy against. The
# split only needs the keys after raw_file, but a partial copy would drift unseen.
NOTE_KEY_ORDER="schema body_schema id date type summary attendees tags topics entities source_file raw_file transcript_corrections open_questions resolved_questions deferred_tensions unpromoted_candidates related"

mode=""
scope=""

usage() {
  cat >&2 <<'USAGE'
usage: split-raw.sh --dry-run|--apply <scope-path>

  <scope-path>  a directory with _inbox/ or notes/_inbox/, plus _memory/ or entries/
  --dry-run     list each note that would be split; write nothing
  --apply       write each sidecar and rewrite its note
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run | --apply)
      [[ -z "$mode" || "$mode" == "$1" ]] || {
        echo "--dry-run and --apply are exclusive" >&2
        exit 3
      }
      mode="$1"
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*)
      echo "unknown option: $1" >&2
      usage
      exit 3
      ;;
    *)
      [[ -z "$scope" ]] || {
        echo "split one scope at a time" >&2
        exit 3
      }
      scope="${1%/}"
      ;;
  esac
  shift
done

[[ -n "$mode" && -n "$scope" ]] || {
  usage
  exit 3
}

[[ -d "$scope" && -r "$scope" ]] || {
  echo "not a readable directory: $scope" >&2
  exit 3
}

# Same opt-in guard as the sibling scripts: the queue marks the scope.
if { [[ ! -d "$scope/_inbox" ]] && [[ ! -d "$scope/notes/_inbox" ]]; } ||
   { [[ ! -d "$scope/_memory" ]] && [[ ! -d "$scope/entries" ]]; }; then
  echo "not an opted-in scope: $scope (needs _inbox/ or notes/_inbox/, plus _memory/ or entries/)" >&2
  exit 3
fi

work="$(mktemp -d "${TMPDIR:-/tmp}/i2m-split.XXXXXX")"
trap 'rm -rf "$work"' EXIT

split=0
v1_skipped=0
already=0
empty=0
refused=0
: >"$work/findings"

# Copied from reflow-raw.sh: the body generation, not the frontmatter
# generation, decides whether a body gets touched.
body_is_v1() {
  awk '
    NR == 1 { if ($0 == "---") { in_fm = 1; next } else { exit } }
    in_fm && $0 == "---" { exit }
    in_fm && /^schema:/ { has_schema = 1 }
    in_fm && /^body_schema: 1$/ { body_v1 = 1 }
    END { exit ((has_schema && !body_v1) ? 1 : 0) }
  ' "$1"
}

frontmatter_value() {
  awk -v key="$2" '
    NR == 1 { if ($0 == "---") { in_fm = 1; next } else { exit } }
    in_fm && $0 == "---" { exit }
    in_fm && index($0, key ":") == 1 {
      sub(/^[^:]*:[[:space:]]*/, ""); sub(/[[:space:]]+$/, ""); gsub(/^["\047]|["\047]$/, ""); print; exit
    }
  ' "$1"
}

refuse() {
  echo "  $1: $2" >>"$work/findings"
  refused=$((refused + 1))
}

# Read the raw zone with awk rather than `tail | grep -q`. Under pipefail,
# grep's early exit kills tail with SIGPIPE once the zone outgrows a pipe
# buffer (~64 KB), and the pipeline reads as no match.
raw_zone_has() {
  awk -v h="$2" -v re="$3" 'NR > h && $0 ~ re { found = 1; exit } END { exit !found }' "$1"
}

shopt -s nullglob

for file in "$scope"/notes/*.md; do
  case "${file##*/}" in
    CLAUDE.md | README.md) continue ;;
  esac

  if body_is_v1 "$file"; then
    v1_skipped=$((v1_skipped + 1))
    continue
  fi

  if [[ -n "$(frontmatter_value "$file" raw_file)" ]]; then
    already=$((already + 1))
    continue
  fi

  heading="$(awk '$0 == "## Raw Content" { print NR; exit }' "$file")"
  if [[ -z "$heading" ]] || ! raw_zone_has "$file" "$heading" '[^[:space:]]'; then
    empty=$((empty + 1))
    continue
  fi

  # A pointer with no key is lint's raw-file failure. Splitting it would bury
  # the pointer in a sidecar and make the lint pass on raw text that may be gone.
  if raw_zone_has "$file" "$heading" '[]][(]raw/'; then
    refuse "$file" "\`## Raw Content\` already links into raw/ with no \`raw_file\`; left alone"
    continue
  fi

  id="$(frontmatter_value "$file" id)"
  if [[ -z "$id" ]]; then
    refuse "$file" "no \`id\` to name the sidecar after; left alone"
    continue
  fi

  sidecar="$scope/notes/raw/$id.md"
  if [[ -e "$sidecar" ]]; then
    refuse "$file" "$sidecar already exists; left alone"
    continue
  fi

  echo "split: $file -> $sidecar"
  split=$((split + 1))
  [[ "$mode" == --apply ]] || continue

  # raw_file goes in front of the first key that follows it in NOTE_KEY_ORDER,
  # or last if none is present, which keeps lint's key-order check passing.
  # Each `L<n>` above the heading drops by the heading's line number; one that
  # never pointed into the raw zone is reported rather than made negative.
  head -n "$heading" "$file" | awk -v rf="raw/$id.md" -v h="$heading" -v f="$file" -v order="$NOTE_KEY_ORDER" '
    BEGIN {
      n = split(order, keys, " ")
      for (i = 1; i <= n; i++) { if (seen) after[keys[i]] = 1; if (keys[i] == "raw_file") seen = 1 }
    }
    NR == 1 && $0 == "---" { in_fm = 1; print; next }
    in_fm && !done && ($0 == "---" || (match($0, /^[A-Za-z_][A-Za-z0-9_]*:/) && (substr($0, 1, RLENGTH - 1) in after))) {
      print "raw_file: " rf; done = 1
    }
    in_fm && $0 == "---" { in_fm = 0; print; next }
    in_fm { print; next }
    {
      out = ""; rest = $0
      while (match(rest, /\(raw: ("[^"]*",? )?L[0-9]+\)/)) {
        ref = substr(rest, RSTART, RLENGTH)
        out = out substr(rest, 1, RSTART - 1)
        rest = substr(rest, RSTART + RLENGTH)
        match(ref, /L[0-9]+\)$/)
        old = substr(ref, RSTART + 1, RLENGTH - 2) + 0
        if (old > h) ref = substr(ref, 1, RSTART) (old - h) ")"
        else printf "  %s: `%s` points above `## Raw Content`; left as written\n", f, ref > "/dev/stderr"
        out = out ref
      }
      print out rest
    }
  ' >"$work/note" 2>>"$work/findings"
  printf '\nIn [raw/%s.md](raw/%s.md). Open it only to verify a quote.\n' "$id" "$id" >>"$work/note"

  mkdir -p "$scope/notes/raw"
  tail -n "+$((heading + 1))" "$file" >"$sidecar"
  cat "$work/note" >"$file"
done

echo
echo "scope: $scope"
echo "split: $split"
echo "v1 bodies skipped: $v1_skipped"
echo "already split: $already"
echo "empty raw zones skipped: $empty"
echo "refused: $refused"

if [[ -s "$work/findings" ]]; then
  echo
  echo "needs a human:"
  cat "$work/findings"
fi

if [[ "$mode" == --dry-run ]]; then
  echo
  echo "dry run; nothing was written. rerun with --apply to split these notes."
fi

[[ "$refused" -eq 0 ]] || exit 1
