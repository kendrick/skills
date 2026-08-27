#!/usr/bin/env bash
# Reflow collapsed-VTT raw zones so each speaker turn renders as its own
# markdown paragraph, and re-anchor the line refs the reflow moves.
#
# collapse-vtt.sh once separated turns with a single newline. CommonMark joins
# consecutive non-blank lines into one paragraph, so every transcript groomed
# before the fix renders its whole raw zone as a single wall of text; the words
# are right and only the separators are wrong. This script inserts the missing
# blank lines in place, then rewrites each `(raw: "..." L<n>)` anchor by
# locating its snippet in the reflowed zone rather than by arithmetic, so a ref
# survives a turn that was merged or split. A snippet it cannot place on
# exactly one line, and any bare `(raw: L<n>)` with nothing to anchor to, is
# reported and left alone.
#
# V1 bodies are never rewritten (references/machine-contracts.md), so a note
# with no `schema` key, or carrying `body_schema: 1`, is skipped and counted.
# A raw zone that is not wall-to-wall speaker turns is not collapsed VTT: pasted
# decks and documents carry their own paragraph breaks and are left alone.
set -euo pipefail

apply=0
allow_dirty=0
scope=""

usage() {
  cat >&2 <<'USAGE'
usage: reflow-raw.sh <scope-path> [--apply] [--allow-dirty]

  <scope-path>   a directory with _inbox/ or notes/_inbox/, plus _memory/ or entries/
  --apply        write the changes; without it nothing is written
  --allow-dirty  proceed even though the working tree has uncommitted changes
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
        echo "reflow one scope at a time" >&2
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

# Same opt-in guard as migrate-scope.sh, for the same reason: the queue marks
# the scope, and it sits in exactly two places depending on the layout.
if { [[ ! -d "$scope/_inbox" ]] && [[ ! -d "$scope/notes/_inbox" ]]; } ||
   { [[ ! -d "$scope/_memory" ]] && [[ ! -d "$scope/entries" ]]; }; then
  echo "not an opted-in scope: $scope (needs _inbox/ or notes/_inbox/, plus _memory/ or entries/)" >&2
  exit 2
fi

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

work="$(mktemp -d "${TMPDIR:-/tmp}/i2m-reflow.XXXXXX")"
trap 'rm -rf "$work"' EXIT

reflowed=0
refs_rewritten=0
already=0
left_alone=0
v1_skipped=0
: >"$work/findings"

# The body generation is what decides whether a body gets touched, so both
# markers of a v1 body count: a file with no `schema` key at all, and a
# migrated file whose `body_schema: 1` says the fence is the generation line.
body_is_v1() {
  awk '
    NR == 1 { if ($0 == "---") { in_fm = 1; next } else { exit } }
    in_fm && $0 == "---" { exit }
    in_fm && /^schema:/ { has_schema = 1 }
    in_fm && /^body_schema: 1$/ { body_v1 = 1 }
    END { exit ((has_schema && !body_v1) ? 1 : 0) }
  ' "$1"
}

# One pass per file: classify the raw zone, rebuild it with a blank line
# between turns, then re-anchor every snippet-carrying L ref against the
# rebuilt zone. The candidate lands on stdout; classification, findings, and
# the rewrite count land on stderr as tab-separated events for the caller.
reflow_file() {
  awk '
    { line[NR] = $0 }
    END {
      raw = 0
      for (i = 1; i <= NR; i++) if (line[i] == "## Raw Content") { raw = i; break }
      if (!raw) { verdict("no-raw"); passthrough(); exit }

      # A collapsed-VTT zone is nothing but turn lines: `[H:MM:SS] Name: said`.
      # One line of anything else means this zone was never VTT, and two turns
      # is the least a reflow can matter for.
      turn_re = "^\\[[0-9][0-9]?:[0-9][0-9](:[0-9][0-9])?\\] [^:]+: "
      turns = 0; nonturn = 0
      for (i = raw + 1; i <= NR; i++) {
        if (line[i] ~ /^[[:space:]]*$/) continue
        if (line[i] ~ turn_re) turns++
        else nonturn++
      }
      if (nonturn > 0 || turns < 2) { verdict("not-vtt"); passthrough(); exit }
      verdict("vtt")

      n = 0
      for (i = 1; i <= raw; i++) out[++n] = line[i]
      for (i = raw + 1; i <= NR; i++) {
        if (line[i] ~ /^[[:space:]]*$/) continue
        out[++n] = ""
        out[++n] = line[i]
      }

      # The snippet is authoritative and the number is a convenience, so the
      # number is recomputed from wherever the snippet now sits. Anything not
      # findable on exactly one zone line gets reported, never guessed.
      rewritten = 0
      for (i = 1; i < raw; i++) {
        result = ""; rest = out[i]
        while ((p = index(rest, "(raw: ")) > 0) {
          result = result substr(rest, 1, p + 5)
          rest = substr(rest, p + 6)
          if (substr(rest, 1, 1) != "\"") {
            if (match(rest, /^L[0-9]+\)/))
              finding("bare ref `(raw: " substr(rest, 1, RLENGTH - 1) ")` carries no snippet to anchor to; left alone")
            continue
          }
          q = index(substr(rest, 2), "\"")
          if (q == 0) continue
          snippet = substr(rest, 2, q - 1)
          after = substr(rest, q + 2)
          if (!match(after, /^,? L[0-9]+\)/)) continue
          tail = substr(after, 1, RLENGTH)
          rest = substr(after, RLENGTH + 1)
          hits = 0; where = 0
          for (k = raw + 1; k <= n; k++)
            if (out[k] != "" && index(out[k], snippet) > 0) { hits++; where = k }
          if (hits == 1) {
            newtail = tail
            sub(/L[0-9]+/, "L" where, newtail)
            if (newtail != tail) rewritten++
            result = result "\"" snippet "\"" newtail
          } else {
            if (hits == 0) finding("snippet \"" snippet "\" is not in the reflowed raw zone; its L ref was left alone")
            else finding("snippet \"" snippet "\" sits on " hits " zone lines; its L ref was left alone")
            result = result "\"" snippet "\"" tail
          }
        }
        out[i] = result rest
      }

      printf "refs\t%d\n", rewritten > "/dev/stderr"
      for (i = 1; i <= n; i++) print out[i]
    }
    function verdict(v) { printf "verdict\t%s\n", v > "/dev/stderr" }
    function finding(msg) { printf "finding\t%s\n", msg > "/dev/stderr" }
    function passthrough(   i) { for (i = 1; i <= NR; i++) print line[i] }
  ' "$1"
}

shopt -s nullglob

for file in "$scope"/notes/*.md "$scope"/_memory/*/*.md "$scope"/entries/*.md; do
  case "${file##*/}" in
    CLAUDE.md | README.md) continue ;;
  esac

  if body_is_v1 "$file"; then
    v1_skipped=$((v1_skipped + 1))
    continue
  fi

  reflow_file "$file" >"$work/candidate" 2>"$work/events"

  awk -F'\t' -v f="$file" '$1 == "finding" { print "  " f ": " $2 }' "$work/events" >>"$work/findings"

  verdict="$(awk -F'\t' '$1 == "verdict" { print $2; exit }' "$work/events")"
  if [[ "$verdict" != "vtt" ]]; then
    left_alone=$((left_alone + 1))
    continue
  fi

  if cmp -s "$file" "$work/candidate"; then
    already=$((already + 1))
    continue
  fi

  echo "--- $file"
  diff -u "$file" "$work/candidate" | tail -n +3 || true

  [[ "$apply" -eq 1 ]] && cat "$work/candidate" >"$file"
  reflowed=$((reflowed + 1))
  refs_rewritten=$((refs_rewritten + $(awk -F'\t' '$1 == "refs" { print $2; exit }' "$work/events")))
done

echo
echo "scope: $scope"
echo "reflowed: $reflowed"
echo "refs rewritten: $refs_rewritten"
echo "already reflowed: $already"
echo "left alone: $left_alone"
echo "v1 bodies skipped: $v1_skipped"

if [[ -s "$work/findings" ]]; then
  echo
  echo "needs a human:"
  cat "$work/findings"
fi

if [[ "$apply" -eq 0 ]]; then
  echo
  echo "dry run; nothing was written. rerun with --apply to write these changes."
fi
