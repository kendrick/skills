#!/usr/bin/env bash
# Pin jd-file's build_moc.py against the fixture in tests/fixtures/jd-file/moc/,
# and moc-stale's detection against the same staged copy. The map README ships
# with an empty generated block on purpose: stale is the fixture's ground state,
# so --check and moc-stale both have something real to catch before the builder
# runs, and the after-state proves regeneration closed exactly that finding.
#
# The prose outside the markers is the load-bearing assertion. A builder that
# rewrites the whole file passes every "table looks right" check; comparing the
# pre/post text outside the markers byte-for-byte is what catches it.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

fixture="tests/fixtures/jd-file/moc"
builder="jd-file/scripts/build_moc.py"
validator="jd-audit/scripts/validate.py"
host="jd-moc-fixture"

if [[ ! -f "$builder" ]]; then
  echo "SKIP: $builder does not exist -- jd-file-moc-smoke.sh has nothing to run against." >&2
  exit 0
fi

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

# Stage the fixture and rewrite __FIXTURE_ROOT__, same contract as
# jd-audit-smoke.sh: fixtures stay portable, the staged copy gets real paths.
dest="$work_dir/moc"
cp -R "$fixture" "$dest"
conventions="$dest/vault/00-09 Admin & Meta/00 System/00.03 Vault Conventions.md"
[[ -f "$conventions" ]] || fail "staged copy is missing its conventions note at $conventions"
while IFS= read -r -d '' f; do
  sed -i '' "s#__FIXTURE_ROOT__#${dest}#g" "$f"
done < <(find "$dest" -type f -print0)

vault="$dest/vault"
moc_file="$vault/10-19 Work/11 Clients/README.md"

run_builder() {
  python3 "$builder" --vault "$vault" --conventions "$conventions" --host "$host" "$@"
}

echo "== jd-file-moc-smoke: running $builder against staged fixture =="

# --- 1. --check on the stale ground state: exit 1, file untouched --------

before="$(cat "$moc_file")"
set +e
check_out="$(run_builder --check 2>&1)"; code=$?
set -e
[[ "$code" == 1 ]] || fail "--check on a stale table: expected exit 1, got $code
$check_out"
grep -q "out of date" <<<"$check_out" || fail "--check output never says 'out of date': $check_out"
[[ "$(cat "$moc_file")" == "$before" ]] || fail "--check modified the map file; it must write nothing"
echo "check-stale: OK (exit 1, wrote nothing)"

# --- 2. moc-stale agrees with --check on the same staged copy ------------

if [[ -f "$validator" ]]; then
  stale_json="$work_dir/stale.json"
  python3 "$validator" --conventions "$conventions" --host "$host" --only moc-stale --json >"$stale_json"
  python3 - "$stale_json" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
findings = data["findings"] if isinstance(data, dict) else data
stale = [f for f in findings if f.get("check") == "moc-stale"]
assert stale, f"expected moc-stale to fire on the empty generated block; findings={findings}"
assert all(f.get("severity") == "warn" for f in stale), f"moc-stale must be warn: {stale}"
print("moc-stale-before: OK (fired at warn)")
PY
else
  echo "moc-stale-before: SKIP ($validator absent)"
fi

# --- 3. Regenerate: table lands between the markers, prose survives ------

run_builder >/dev/null
after="$(cat "$moc_file")"
[[ "$after" != "$before" ]] || fail "builder claimed to run but the map file is unchanged"

# The prose outside the markers must survive byte-for-byte.
outside_before="$(python3 -c "
import sys
t = sys.stdin.read()
pre, rest = t.split('<!-- moc:begin -->', 1)
_, post = rest.split('<!-- moc:end -->', 1)
sys.stdout.write(pre + '|SPLIT|' + post)" <<<"$before")"
outside_after="$(python3 -c "
import sys
t = sys.stdin.read()
pre, rest = t.split('<!-- moc:begin -->', 1)
_, post = rest.split('<!-- moc:end -->', 1)
sys.stdout.write(pre + '|SPLIT|' + post)" <<<"$after")"
[[ "$outside_before" == "$outside_after" ]] || fail "content outside the markers changed:
--- before ---
$outside_before
--- after ---
$outside_after"

grep -q '| 11.01 | \*\*Riverton Analytics\*\*' <<<"$after" || fail "regenerated table is missing the 11.01 row: $after"
grep -q '| 11.02 | \*\*Fogline Robotics\*\*' <<<"$after" || fail "regenerated table is missing the 11.02 row: $after"
grep -q '| ID | Client | Notes |' <<<"$after" || fail "regenerated table is missing the labeled header: $after"
echo "regenerate: OK (both rows present, prose outside markers untouched)"

# --- 4. Idempotence: a second run changes nothing -------------------------

second_out="$(run_builder)"
grep -q "already current" <<<"$second_out" || fail "second run should say 'already current': $second_out"
[[ "$(cat "$moc_file")" == "$after" ]] || fail "second run modified an already-current map"
set +e
run_builder --check >/dev/null 2>&1; code=$?
set -e
[[ "$code" == 0 ]] || fail "--check after regeneration: expected exit 0, got $code"
echo "idempotent: OK (second run inert, --check exits 0)"

# --- 5. moc-stale is closed by the regeneration ---------------------------

if [[ -f "$validator" ]]; then
  fresh_json="$work_dir/fresh.json"
  python3 "$validator" --conventions "$conventions" --host "$host" --only moc-stale --json >"$fresh_json"
  python3 - "$fresh_json" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
findings = data["findings"] if isinstance(data, dict) else data
stale = [f for f in findings if f.get("check") == "moc-stale"]
assert not stale, f"moc-stale still fires after regeneration: {stale}"
print("moc-stale-after: OK (closed by the builder)")
PY
else
  echo "moc-stale-after: SKIP ($validator absent)"
fi

# --- 6. Unknown column fails loudly, not as a silent dash column ----------
# status and updated moved to the Dataview rollups block; a config still
# naming them must get an actionable error rather than a column of dashes.

bad_conv="$work_dir/bad-conventions.md"
sed 's/columns = \["id", "name", "vault"\]/columns = ["id", "name", "status"]/' "$conventions" >"$bad_conv"
set +e
bad_out="$(python3 "$builder" --vault "$vault" --conventions "$bad_conv" --host "$host" 2>&1)"; code=$?
set -e
[[ "$code" != 0 ]] || fail "a column that is neither built-in nor a substrate must fail: $bad_out"
grep -q "status" <<<"$bad_out" || fail "the unknown-column error never names the offending column: $bad_out"
grep -qi "rollups" <<<"$bad_out" || fail "the unknown-column error should point at the Dataview rollups block: $bad_out"
echo "unknown-column: OK (fails loudly, names the column, points at rollups)"

echo "== all jd-file-moc-smoke assertions passed =="
