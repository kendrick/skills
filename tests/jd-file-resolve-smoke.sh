#!/usr/bin/env bash
# Pin jd-file's resolve_vault.py -- the vault-root ladder that both jd-file
# and jd-audit climb when the caller doesn't say --vault/--conventions. Most
# of these cases prove little on their own: any resolver that just returns
# the first thing it finds passes cases 1-4. Case 5 is the actual pin -- it
# proves rung order is a hard short-circuit (verified $JD_VAULT wins even
# when obsidian.json also names a verified vault) rather than a pooled
# candidate set that happens to resolve the same way when only one rung has
# a hit. Case 3 pins that verification is glob-tolerant against the
# "00.02 Vault Conventions.md" vs "00.03 Vault Conventions.md" naming
# collision already baked into the jd-audit fixtures. Case 0 pins the
# byte-identical duplication rule: jd-file owns this script and jd-audit
# carries a copy, and the two are only useful as one contract if they can
# never quietly drift apart.
#
# resolve_vault.py and the two skills that consume it are owned by parallel
# builds and are not touched here. If jd-file's copy does not exist yet this
# script says so and exits 0 (skip, not fail) rather than block an unrelated
# CI run; the jd-audit copy and validate.py's ladder integration (cases 0,
# 7, 8) get their own finer-grained skip since they land on their own
# schedule.
#
# Every invocation below runs under a sandboxed HOME (and either an
# explicit JD_VAULT or `env -u JD_VAULT`) so the developer's real
# ~/Library/Application Support/obsidian and ~/Documents can never leak
# into a test run and turn it into a false pass or a flaky failure.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

resolver="jd-file/scripts/resolve_vault.py"

if [[ ! -f "$resolver" ]]; then
  echo "SKIP: $resolver does not exist yet -- jd-file-resolve-smoke.sh has nothing to run against." >&2
  echo "Rerun this script once resolve_vault.py lands." >&2
  exit 0
fi

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

# --- small helpers, house style: name the predicate, echo to stderr, exit 1 ---

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

assert_exit_code() {
  local label="$1" expected="$2" actual="$3"
  [[ "$actual" == "$expected" ]] || fail "$label: expected exit $expected, got $actual (stderr follows)
$(cat "$4" 2>/dev/null || true)"
}

# Builds a verifiable vault at $1: a conventions note under
# 00-09 Admin & Meta/00 System/, named $2 (default the canonical 00.02 name)
# so callers can also exercise the glob-tolerant 00.03 collision.
make_vault() {
  local dir="$1" note_name="${2:-00.02 Vault Conventions.md}"
  mkdir -p "$dir/00-09 Admin & Meta/00 System"
  touch "$dir/00-09 Admin & Meta/00 System/$note_name"
}

# Builds a fake $HOME at $1. With no further args it's just an empty home
# (rungs 2 and 3 both miss). With vault paths given, writes
# Library/Application Support/obsidian/obsidian.json listing each as a
# vaults entry (hash keys h1, h2, ...; ts 1700000000; only the first "open").
make_home() {
  local dir="$1"
  shift
  mkdir -p "$dir"
  if [[ $# -eq 0 ]]; then
    return 0
  fi
  local obsidian_dir="$dir/Library/Application Support/obsidian"
  mkdir -p "$obsidian_dir"
  local obsidian_json="$obsidian_dir/obsidian.json"
  local total=$#
  local idx=0
  {
    echo '{'
    echo '  "vaults": {'
    for path in "$@"; do
      idx=$((idx + 1))
      local open="false"
      [[ "$idx" -eq 1 ]] && open="true"
      printf '    "h%d": {"path": "%s", "ts": 1700000000, "open": %s}' "$idx" "$path" "$open"
      if [[ "$idx" -lt "$total" ]]; then
        printf ','
      fi
      printf '\n'
    done
    echo '  }'
    echo '}'
  } >"$obsidian_json"
}

echo "== jd-file-resolve-smoke: pinning $resolver's ladder =="

# --- 0. byte-identical: jd-audit's copy must not drift from jd-file's ---

if [[ -f jd-audit/scripts/resolve_vault.py ]]; then
  cmp -s jd-file/scripts/resolve_vault.py jd-audit/scripts/resolve_vault.py \
    || fail "byte-identical: jd-file/scripts/resolve_vault.py and jd-audit/scripts/resolve_vault.py have diverged -- the two skills owe each other a byte-identical copy, not a fork"
  echo "byte-identical: OK (jd-file and jd-audit copies match byte-for-byte)"
else
  echo "byte-identical: SKIP (jd-audit copy not yet landed)"
fi

# --- 1. \$JD_VAULT hit: rung 1 wins outright -----------------------------

vault_a="$work_dir/vault-a"
make_vault "$vault_a"
home1="$work_dir/home1"
make_home "$home1"
out="$work_dir/case1.out"; err="$work_dir/case1.err"
set +e
env JD_VAULT="$vault_a" HOME="$home1" python3 "$resolver" >"$out" 2>"$err"
code=$?
set -e
assert_exit_code jd-vault-hit 0 "$code" "$err"
[[ "$(cat "$out")" == "$vault_a" ]] \
  || fail "jd-vault-hit: expected stdout '$vault_a', got '$(cat "$out")'"
echo "jd-vault-hit: OK (verified \$JD_VAULT resolves at rung 1, stdout is exactly the vault path)"

# --- 2. \$JD_VAULT unverifiable falls through to obsidian.json -----------

unverifiable="$work_dir/not-a-vault"
mkdir -p "$unverifiable"
vault_b="$work_dir/vault-b"
make_vault "$vault_b"
home2="$work_dir/home2"
make_home "$home2" "$vault_b"
out="$work_dir/case2.out"; err="$work_dir/case2.err"
set +e
env JD_VAULT="$unverifiable" HOME="$home2" python3 "$resolver" >"$out" 2>"$err"
code=$?
set -e
assert_exit_code jd-vault-unverifiable-falls-through 0 "$code" "$err"
[[ "$(cat "$out")" == "$vault_b" ]] \
  || fail "jd-vault-unverifiable-falls-through: expected stdout '$vault_b', got '$(cat "$out")'"
echo "jd-vault-unverifiable-falls-through: OK (a \$JD_VAULT with no conventions note doesn't abort the run; the ladder keeps climbing)"

# --- 3. obsidian.json hit, verified via the 00.03-named note ------------

vault_c="$work_dir/vault-c"
make_vault "$vault_c" "00.03 Vault Conventions.md"
home3="$work_dir/home3"
make_home "$home3" "$vault_c"
out="$work_dir/case3.out"; err="$work_dir/case3.err"
set +e
env -u JD_VAULT HOME="$home3" python3 "$resolver" >"$out" 2>"$err"
code=$?
set -e
assert_exit_code obsidian-json-glob-verify 0 "$code" "$err"
[[ "$(cat "$out")" == "$vault_c" ]] \
  || fail "obsidian-json-glob-verify: expected stdout '$vault_c', got '$(cat "$out")'"
echo "obsidian-json-glob-verify: OK (a 00.03-named conventions note verifies via the glob fallback, not just the exact 00.02 path)"

# --- 4. nothing found: exit 4, miss notes name JD_VAULT and obsidian ----

home4="$work_dir/home4"
make_home "$home4"
mkdir -p "$home4/Documents"
out="$work_dir/case4.out"; err="$work_dir/case4.err"
set +e
env -u JD_VAULT HOME="$home4" python3 "$resolver" >"$out" 2>"$err"
code=$?
set -e
assert_exit_code nothing-found 4 "$code" "$err"
grep -q 'JD_VAULT' "$err" || fail "nothing-found: stderr does not mention JD_VAULT: $(cat "$err")"
grep -qi 'obsidian' "$err" || fail "nothing-found: stderr does not mention obsidian: $(cat "$err")"
echo "nothing-found: OK (exit 4, per-rung miss notes mention JD_VAULT and obsidian)"

# --- 5. REFUTE -- verified \$JD_VAULT short-circuits past obsidian.json --
#
# home5's obsidian.json names a DIFFERENT verified vault (B) than the
# $JD_VAULT we set (A). A resolver that pools every rung's verified
# candidates into one set -- instead of stopping hard at the first verified
# rung -- would either return B, or see two verified candidates and bail
# out ambiguous (exit 3). Neither is correct: rung 1 must win outright.

home5="$work_dir/home5"
make_home "$home5" "$vault_b"
out="$work_dir/case5.out"; err="$work_dir/case5.err"
set +e
env JD_VAULT="$vault_a" HOME="$home5" python3 "$resolver" >"$out" 2>"$err"
code=$?
set -e
assert_exit_code jd-vault-short-circuit-refute 0 "$code" "$err"
stdout_val="$(cat "$out")"
[[ "$stdout_val" == "$vault_a" ]] \
  || fail "jd-vault-short-circuit-refute: expected stdout '$vault_a' (rung 1 must short-circuit before obsidian.json is even consulted), got '$stdout_val'"
[[ "$stdout_val" != "$vault_b" ]] \
  || fail "jd-vault-short-circuit-refute: stdout was vault B -- the resolver pooled rungs instead of stopping at the first verified one"
echo "jd-vault-short-circuit-refute: OK (REFUTE holds -- verified \$JD_VAULT short-circuits before obsidian.json is consulted)"

# --- 6. ambiguous asks, never picks: two verified vaults, one rung ------

home6="$work_dir/home6"
make_home "$home6"
vault_d="$home6/Documents/vault-d"
vault_e="$home6/Documents/vault-e"
make_vault "$vault_d"
make_vault "$vault_e"
out="$work_dir/case6.out"; err="$work_dir/case6.err"
set +e
env -u JD_VAULT HOME="$home6" python3 "$resolver" >"$out" 2>"$err"
code=$?
set -e
assert_exit_code ambiguous-asks 3 "$code" "$err"
grep -qF "$vault_d" "$err" || fail "ambiguous-asks: stderr does not name candidate $vault_d: $(cat "$err")"
grep -qF "$vault_e" "$err" || fail "ambiguous-asks: stderr does not name candidate $vault_e: $(cat "$err")"
echo "ambiguous-asks: OK (exit 3, both candidates named on stderr, resolver refuses to guess)"

# --- 7 & 8. validate.py's own ladder climb (needs jd-audit's copy) ------

if [[ ! -f jd-audit/scripts/resolve_vault.py ]]; then
  echo "validate-ladder: SKIP (jd-audit copy not yet landed)"
else
  # --- 7. no --vault/--conventions: validate.py climbs the ladder itself -

  fixtures_dir="tests/fixtures/jd-audit"
  staged="$work_dir/clean"
  cp -R "$fixtures_dir/clean" "$staged"
  # Same fixture-portability substitution jd-audit-smoke.sh does: every
  # fixture's conventions note (and the links fixture's embedded file://
  # URLs) carries the literal placeholder __FIXTURE_ROOT__ instead of a
  # baked-in absolute path, rewritten here to the scratch copy's real path.
  while IFS= read -r -d '' f; do
    sed -i '' "s#__FIXTURE_ROOT__#${staged}#g" "$f"
  done < <(find "$staged" -type f -print0)

  empty_home7="$work_dir/empty-home7"
  mkdir -p "$empty_home7"
  out="$work_dir/case7.out"; err="$work_dir/case7.err"
  set +e
  env HOME="$empty_home7" JD_VAULT="$staged/vault" python3 jd-audit/scripts/validate.py \
    --host jdaudit-fixture --json >"$out" 2>"$err"
  code=$?
  set -e
  assert_exit_code validate-ladder-success 0 "$code" "$err"
  echo "validate-ladder-success: OK (validate.py with neither --vault nor --conventions climbs the ladder and runs the clean fixture)"

  # --- 8. empty ladder: validate.py exits 2 with a FATAL message ---------

  empty_home8="$work_dir/empty-home8"
  mkdir -p "$empty_home8"
  out="$work_dir/case8.out"; err="$work_dir/case8.err"
  set +e
  env -u JD_VAULT HOME="$empty_home8" python3 jd-audit/scripts/validate.py >"$out" 2>"$err"
  code=$?
  set -e
  assert_exit_code validate-ladder-empty 2 "$code" "$err"
  grep -qi 'FATAL' "$err" || fail "validate-ladder-empty: stderr does not contain a FATAL message: $(cat "$err")"
  grep -q 'JD_VAULT' "$err" || fail "validate-ladder-empty: FATAL message does not mention JD_VAULT: $(cat "$err")"
  grep -qi 'obsidian' "$err" || fail "validate-ladder-empty: FATAL message does not mention obsidian: $(cat "$err")"
  echo "validate-ladder-empty: OK (exit 2, FATAL message names the rungs tried: JD_VAULT and obsidian)"
fi

echo "== all jd-file-resolve-smoke assertions passed =="
