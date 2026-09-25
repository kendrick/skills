#!/usr/bin/env bash
# Pin the Resume phase table's three copies to each other: the one in
# work-issue/SKILL.md, the one in references/resume.md, and the one
# run-state.py's phase subcommand encodes, as the probe fixtures exercise it.
# The copies drifted before this suite existed (#161), and a drifted row sends a
# resumed run to the wrong step with nothing to say so. Both tables are parsed
# from the real files and every fixture runs through the real script, so no
# copy of either table lives here to drift in its turn.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

skill_md=work-issue/SKILL.md
resume_md=work-issue/references/resume.md
run_state=work-issue/scripts/run-state.py
probes=tests/fixtures/work-issue/probes
header='| # | Probe | Resume at |'

# A fixture named for one row that deliberately lands on another. Each entry is
# `fixture:landing-row:reason`, and nothing goes here without a reason a
# reviewer can check against the fixture itself.
allowlist=(
  "row-16-earlier-queued.json:17:row 16's guard case: a queued round then a repaired one has two rounds and one report, so it must skip row 16 and land on row 17"
)

failures=0
fail() {
  echo "$1" >&2
  failures=$((failures + 1))
}

for f in "$skill_md" "$resume_md" "$run_state"; do
  [[ -f "$f" ]] || { echo "missing required file: $f" >&2; exit 1; }
done

# Print the table under $header as `row<TAB>cell1<TAB>cell2...`, cells trimmed.
# Stops at the first line that is not a table row. Exits 3 when the header is
# missing or appears twice, since either makes "the table" ambiguous.
extract_table() {
  awk -v header="$header" '
    $0 == header { seen++; in_table = 1; getline; next }
    in_table && /^\|/ {
      n = split($0, cells, "|")
      out = ""
      for (i = 2; i < n; i++) {
        c = cells[i]
        gsub(/^[ \t]+|[ \t]+$/, "", c)
        out = out (i == 2 ? "" : "\t") c
      }
      print out
      next
    }
    in_table { in_table = 0 }
    END { if (seen != 1) exit 3 }
  ' "$1"
}

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

extract_table "$skill_md" >"$tmp/skill.tsv" || { echo "$skill_md: expected exactly one '$header' table" >&2; exit 1; }
extract_table "$resume_md" >"$tmp/resume.tsv" || { echo "$resume_md: expected exactly one '$header' table" >&2; exit 1; }

# An empty parse would compare equal and pass, so demand rows first.
for t in skill resume; do
  [[ -s "$tmp/$t.tsv" ]] || { echo "no rows parsed under '$header' in the $t table" >&2; exit 1; }
done

# --- Check 1: the two prose tables agree cell for cell, keyed by row number. ---

rows="$(cut -f1 "$tmp/skill.tsv" "$tmp/resume.tsv" | sort -n | uniq)"
for row in $rows; do
  s="$(awk -F'\t' -v r="$row" '$1 == r' "$tmp/skill.tsv")"
  m="$(awk -F'\t' -v r="$row" '$1 == r' "$tmp/resume.tsv")"
  if [[ -z "$s" ]]; then
    fail "row $row: in $resume_md but missing from $skill_md"
    continue
  fi
  if [[ -z "$m" ]]; then
    fail "row $row: in $skill_md but missing from $resume_md"
    continue
  fi
  [[ "$s" == "$m" ]] && continue
  IFS=$'\t' read -r -a sc <<<"$s"
  IFS=$'\t' read -r -a mc <<<"$m"
  names=("#" "Probe" "Resume at")
  width=${#sc[@]}
  (( ${#mc[@]} > width )) && width=${#mc[@]}
  for ((i = 0; i < width; i++)); do
    if [[ "${sc[i]-}" != "${mc[i]-}" ]]; then
      fail "row $row: '${names[i]-column $((i + 1))}' differs between $skill_md and $resume_md
  $skill_md: ${sc[i]-<absent>}
  $resume_md: ${mc[i]-<absent>}"
    fi
  done
done

# --- Check 2: every row-<nn> fixture lands on row <nn> under run-state.py. ---

allowed_row() {
  local entry
  for entry in "${allowlist[@]}"; do
    [[ "${entry%%:*}" == "$1" ]] && { entry="${entry#*:}"; echo "${entry%%:*}"; return 0; }
  done
  return 1
}

# A stale allowlist entry would excuse a fixture nobody runs anymore.
for entry in "${allowlist[@]}"; do
  [[ -f "$probes/${entry%%:*}" ]] || fail "allowlist names $probes/${entry%%:*}, which does not exist"
done

checked=0
for path in "$probes"/row-[0-9][0-9]*.json; do
  [[ -f "$path" ]] || continue
  name="$(basename "$path")"
  nn="${name#row-}"
  nn="$((10#${nn:0:2}))"
  expected="$nn"
  if want="$(allowed_row "$name")"; then
    expected="$want"
  fi
  out="$(python3 "$run_state" phase --probe "$path" 2>&1)" || {
    fail "$name: run-state.py phase exited non-zero: $out"
    continue
  }
  got="$(sed -n 's/^phase: [^ ]* reason: row \([0-9][0-9]*\):.*/\1/p' <<<"$out")"
  checked=$((checked + 1))
  if [[ -z "$got" ]]; then
    fail "$name: named for row $nn, but run-state.py gave no row: $out"
  elif [[ "$got" != "$expected" ]]; then
    if [[ "$expected" == "$nn" ]]; then
      fail "$name: named for row $nn, but run-state.py placed it at row $got"
    else
      fail "$name: allowlisted to land on row $expected, but run-state.py placed it at row $got"
    fi
  fi
done

(( checked > 0 )) || fail "no row-<nn> fixtures found under $probes"

if (( failures > 0 )); then
  echo "work-issue resume tables: $failures problem(s)" >&2
  exit 1
fi
echo "work-issue resume tables smoke test passed"
