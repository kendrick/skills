#!/usr/bin/env bash
# Pin the memory-consolidate skill. `ltm` is a PATH shim that prints a saved
# doctor array, so every case but one runs without the kit installed. Where a
# real `ltm` is on PATH, one case also runs it on the fixture bank and requires
# the same report bytes, which keeps the saved doctor.json honest.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

require_file() {
  [[ -f "$1" ]] || {
    echo "missing required file: $1" >&2
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

expect_rc() {
  local want="$1"
  local got="$2"
  local what="$3"
  [[ "$got" == "$want" ]] || {
    echo "$what: expected exit $want, got $got" >&2
    exit 1
  }
}

same_file() {
  local want="$1"
  local got="$2"
  local what="$3"
  cmp -s "$want" "$got" || {
    echo "$what: report differs from expected" >&2
    diff "$want" "$got" >&2 || true
    exit 1
  }
}

script=memory-consolidate/scripts/consolidate.py
fixture=tests/fixtures/memory-consolidate

require_file memory-consolidate/SKILL.md
require_file memory-consolidate/README.md
require_file "$script"
require_file _maintenance/memory-consolidate/RATIONALE.md
require_file "$fixture/doctor.json"
require_file "$fixture/unseen-check.json"

# Invoked through python3 below, so a lost executable bit would pass every case.
[[ -x "$script" ]] || {
  echo "$script is not executable" >&2
  exit 1
}

[[ "$(find memory-consolidate -maxdepth 1 -type f | wc -l | tr -d ' ')" == "2" ]] || {
  echo "memory-consolidate/ must ship only SKILL.md and README.md at top level" >&2
  exit 1
}

require_text README.md "--skill memory-consolidate"
require_text memory-consolidate/README.md "npx skills add kendrick/skills --skill memory-consolidate"

# Model-invocable on purpose (ledger row 6): a misfire writes one report.
refute_text memory-consolidate/SKILL.md "disable-model-invocation"
require_text memory-consolidate/SKILL.md "python3 SCRIPT --scope SCOPE_ROOT"
require_text memory-consolidate/SKILL.md "Phase 5"
require_text memory-consolidate/SKILL.md 'ltm confirm <id>'
require_text memory-consolidate/SKILL.md 'ltm deprecate <id>'

# The cuts in Deliberately Not Built. A list of known checks would name them,
# so no current check name may appear in the script.
refute_text "$script" "stale-confirmed"
refute_text "$script" "long-chain"
refute_text "$script" "orphan"
# A similarity search of its own: near-duplicate detection is the kit's (#130).
refute_text "$script" "near-duplicate"
refute_text "$script" "similarity"
refute_text memory-consolidate/SKILL.md "near-duplicate"
# Writing records: the kit's record-writing commands stay in the user's hands.
refute_text "$script" "confirm"
refute_text "$script" "deprecate"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/bin" "$tmp/pybin"
cat >"$tmp/bin/ltm" <<'SHIM'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$LTM_LOG"
[[ -n "${LTM_STUB_RC:-}" ]] && { echo "stub ltm failing" >&2; exit "$LTM_STUB_RC"; }
cat "$LTM_STUB_JSON"
SHIM
chmod +x "$tmp/bin/ltm"
# python3 alone, so a PATH built from this dir has no ltm on it.
ln -s "$(command -v python3)" "$tmp/pybin/python3"
shim_path="$tmp/bin:$PATH"
bare_path="$tmp/pybin:/usr/bin:/bin"
PATH="$bare_path" command -v ltm >/dev/null 2>&1 && {
  echo "test setup: ltm reachable on $bare_path, the no-ltm case would prove nothing" >&2
  exit 1
}

# A git repo around the scope copy, so `git status` can see what a run wrote.
scope="$tmp/scope"
cp -R "$fixture/scope" "$scope"
git -C "$scope" init -q
git -C "$scope" add -A
git -C "$scope" -c user.name=smoke -c user.email=smoke@example.invalid commit -qm fixture
abs="$(cd "$scope" && pwd)"
report="$scope/notes/reports/2026-10-01-consolidation.md"

run() {
  local json="$1"
  shift
  LTM_TODAY=2026-10-01 LTM_LOG="$tmp/ltm.log" LTM_STUB_JSON="$json" PATH="$shim_path" \
    python3 "$script" --scope "$scope" "$@"
}

# Case 1: the fixture's three findings, and nothing else, in doctor's order.
# Written out by hand from doctor.json and the records' titles, not derived
# from the script, so a wrong title or a dropped field shows as a diff.
expected="$tmp/expected.md"
cat >"$expected" <<'EOF'
---
schema: 2
date: 2026-10-01
type: report
unpromoted_candidates: 3
---

# Memory Consolidation 2026-10-01

[memory candidate: update existing [[billing-vendor-landscape-Mc2VndLnd2|Billing vendor landscape]]] stale-confirmed: date 2026-05-04 is 150 days old and there's no last_confirmed (threshold 90)
[memory candidate: update existing [[prefixed-entity-invoice-numbers-Mc7InvNum4|Prefixed entity invoice numbers]]] long-chain: Supersession chain holds 4 Records (threshold 3) related: [[per-entity-invoice-sequences-Mc6InvNum3]], [[per-region-invoice-sequences-Mc5InvNum2]], [[sequential-invoice-numbers-Mc4InvNum1]]
[memory candidate: update existing [[quarter-close-billing-freeze-Mc8Orphan8|Quarter-close billing freeze]]] orphan: no related, supersedes, or superseded_by, and no Record relates to it (date 2026-07-15, 78 days old, threshold 30)
EOF
: >"$tmp/ltm.log"
out="$(run "$fixture/doctor.json")"
[[ "$out" == "$abs/notes/reports/2026-10-01-consolidation.md" ]] || {
  echo "case 1: stdout is not the report path; got: $out" >&2
  exit 1
}
same_file "$expected" "$report" "case 1 three findings"
[[ "$(cat "$tmp/ltm.log")" == "doctor --bank $scope --json" ]] || {
  echo "case 1: ltm was not called as 'doctor --bank <scope> --json'; got: $(cat "$tmp/ltm.log")" >&2
  exit 1
}

# Case 2: every finding traces to one doctor entry, by check name and file.
python3 - "$fixture/doctor.json" "$report" <<'PY'
import json, pathlib, sys
entries = json.loads(pathlib.Path(sys.argv[1]).read_text())
lines = [l for l in pathlib.Path(sys.argv[2]).read_text().splitlines() if l.startswith("[memory candidate:")]
assert len(lines) == len(entries), f"{len(lines)} candidate lines for {len(entries)} doctor entries"
for e, l in zip(entries, lines):
    stem = pathlib.PurePosixPath(e["file"]).stem
    assert l.startswith(f"[memory candidate: update existing [[{stem}|"), f"line does not name {stem}: {l}"
    assert f"]]] {e['check']}: " in l, f"line does not carry check {e['check']}: {l}"
PY

# Case 3: same scope, same date, same bytes.
cp "$report" "$tmp/first.md"
run "$fixture/doctor.json" >/dev/null
same_file "$tmp/first.md" "$report" "case 3 second run"

# Case 4: a run touches nothing under _memory/, and writes only the report.
[[ -z "$(git -C "$scope" status --porcelain _memory/)" ]] || {
  echo "case 4: _memory/ changed after a run:" >&2
  git -C "$scope" status --porcelain _memory/ >&2
  exit 1
}
[[ "$(git -C "$scope" status --porcelain --untracked-files=all)" == "?? notes/reports/2026-10-01-consolidation.md" ]] || {
  echo "case 4: a run wrote something besides the report:" >&2
  git -C "$scope" status --porcelain --untracked-files=all >&2
  exit 1
}

# Case 5: a check name the skill has never seen comes through as a candidate.
run "$fixture/unseen-check.json" >/dev/null
require_text "$report" "[memory candidate: update existing [[tax-engine-overview-Mc3TaxEng3|Tax engine overview]]] unseen-check: a check name memory-consolidate has never seen, stubbed in to prove it routes like any other related: [[invoices-carry-tax-id-Mc1TaxIdR1]]"
require_text "$report" "unpromoted_candidates: 4"

# Case 6: --json reads a saved array and never runs ltm.
: >"$tmp/ltm.log"
LTM_TODAY=2026-10-01 PATH="$bare_path" python3 "$script" --scope "$scope" --json "$fixture/doctor.json" >/dev/null
same_file "$expected" "$report" "case 6 --json with no ltm on PATH"

# Case 7: an empty doctor array is a clean bank.
printf '[]\n' >"$tmp/empty.json"
run "$tmp/empty.json" >/dev/null
require_text "$report" "unpromoted_candidates: 0"
require_text "$report" "No findings."
refute_text "$report" "[memory candidate:"

# Case 8: exit 1 when doctor fails, can't run, or prints something other than
# an array of {file, check} objects. A failed run leaves the old report alone.
cp "$report" "$tmp/before.md"
printf 'not json\n' >"$tmp/bad.json"
printf '{"file": "a.md", "check": "x"}\n' >"$tmp/object.json"
printf '[{"file": "a.md"}]\n' >"$tmp/nocheck.json"
for bad in bad object nocheck; do
  set +e
  err="$(run "$tmp/$bad.json" 2>&1 >/dev/null)"
  rc=$?
  set -e
  expect_rc 1 "$rc" "case 8 doctor printed $bad"
  [[ -n "$err" ]] || {
    echo "case 8 ($bad): exit 1 with nothing on stderr" >&2
    exit 1
  }
done
set +e
err="$(LTM_STUB_RC=1 run "$fixture/doctor.json" 2>&1 >/dev/null)"
rc=$?
set -e
expect_rc 1 "$rc" "case 8 doctor exits 1"
grep -Fq 'stub ltm failing' <<<"$err" || {
  echo "case 8: stderr does not quote doctor; got: $err" >&2
  exit 1
}
set +e
LTM_TODAY=2026-10-01 PATH="$bare_path" python3 "$script" --scope "$scope" 2>/dev/null
rc=$?
set -e
expect_rc 1 "$rc" "case 8 no ltm on PATH"
same_file "$tmp/before.md" "$report" "case 8 failed runs"

# Case 9: exit 3 for a missing scope, an unreadable --json file, or a malformed
# LTM_TODAY; exit 2 for an argparse usage error.
set +e
LTM_TODAY=2026-10-01 PATH="$shim_path" LTM_LOG="$tmp/ltm.log" LTM_STUB_JSON="$fixture/doctor.json" \
  python3 "$script" --scope "$tmp/nope" 2>/dev/null
rc=$?
set -e
expect_rc 3 "$rc" "case 9 missing scope"
set +e
run "$fixture/doctor.json" --json "$tmp/nope.json" 2>/dev/null
rc=$?
set -e
expect_rc 3 "$rc" "case 9 unreadable --json"
set +e
LTM_TODAY=2026-1-1 LTM_LOG="$tmp/ltm.log" LTM_STUB_JSON="$fixture/doctor.json" PATH="$shim_path" \
  python3 "$script" --scope "$scope" 2>/dev/null
rc=$?
set -e
expect_rc 3 "$rc" "case 9 LTM_TODAY 2026-1-1"
set +e
python3 "$script" 2>/dev/null
rc=$?
set -e
expect_rc 2 "$rc" "case 9 no --scope"
[[ ! -e "$scope/notes/reports/2026-1-1-consolidation.md" ]] || {
  echo "case 9: a malformed LTM_TODAY still wrote a report" >&2
  exit 1
}

# Case 10: real ltm on the fixture bank gives case 1's bytes. LTM_TODAY is the
# only date doctor.json reproduces at; unpinned, more records age out.
if command -v ltm >/dev/null 2>&1; then
  rm -f "$report"
  LTM_TODAY=2026-10-01 python3 "$script" --scope "$scope" >/dev/null
  same_file "$expected" "$report" "case 10 real ltm"
  [[ -z "$(git -C "$scope" status --porcelain _memory/)" ]] || {
    echo "case 10: _memory/ changed after a real ltm run" >&2
    exit 1
  }
else
  echo "memory-consolidate smoke: ltm not on PATH, skipping the real-ltm case" >&2
fi

echo "memory-consolidate smoke: OK"
