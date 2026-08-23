#!/usr/bin/env bash
# Pin jd-audit's validate.py against the fixture mini-systems in
# tests/fixtures/jd-audit/. Most of these are refutes: drift-split-name only
# proves itself by NOT firing once excepted, and structure-deep-numbering only
# proves itself by NOT firing on the deep unnumbered nesting every real client
# scope has on purpose. A validator that flags everything passes the
# positive-finding checks just as easily as a correct one; the refutes are
# what catches that failure mode.
#
# validate.py, its skill, and its README are owned by a parallel build and are
# not touched here. If validate.py does not exist yet this script says so and
# exits 0 (skip, not fail) rather than block an unrelated CI run.
#
# Every fixture's conventions note carries the literal placeholder
# __FIXTURE_ROOT__ in its [hosts.*] table instead of a baked-in absolute path,
# because the fixture's on-disk location depends on where this repo is
# checked out. This script copies each fixture to a scratch directory and
# substitutes the real path before invoking validate.py, so the fixtures
# themselves stay portable and checked-in as-is.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

fixtures_dir="tests/fixtures/jd-audit"
validator="jd-audit/scripts/validate.py"
host="jdaudit-fixture"

if [[ ! -f "$validator" ]]; then
  echo "SKIP: $validator does not exist yet -- jd-audit-smoke.sh has nothing to run against." >&2
  echo "Fixtures are in place at $fixtures_dir/; rerun this script once validate.py lands." >&2
  exit 0
fi

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

# --- small helpers, house style: name the predicate, echo to stderr, exit 1 ---

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

# Stage one fixture into a scratch copy and rewrite __FIXTURE_ROOT__ to the
# copy's real path, so hosts.jdaudit-fixture.{vault,office,code} resolve.
# Prints the path to the staged conventions note on stdout.
stage_fixture() {
  local name="$1"
  local dest="$work_dir/$name"
  cp -R "$fixtures_dir/$name" "$dest"
  local conventions="$dest/vault/00-09 Admin & Meta/00 System/00.03 Vault Conventions.md"
  [[ -f "$conventions" ]] || fail "$name: staged copy is missing its conventions note at $conventions"
  # Substitute in every text file under the staged copy, not just the
  # conventions note -- the links fixture also embeds the placeholder in a
  # file:// URL inside a vault note.
  local f
  while IFS= read -r -d '' f; do
    sed -i '' "s#__FIXTURE_ROOT__#${dest}#g" "$f"
  done < <(find "$dest" -type f -print0)
  printf '%s' "$conventions"
}

# Runs validate.py --json against a staged fixture. Writes stdout JSON to
# $2, stderr to $3, and returns validate.py's exit code as this function's
# own exit code (the caller checks $? explicitly, so `set -e` is suspended
# around the call site rather than here).
run_validator_json() {
  local conventions="$1" out_file="$2" err_file="$3"
  python3 "$validator" --conventions "$conventions" --host "$host" --json \
    >"$out_file" 2>"$err_file"
}

assert_exit_code() {
  local label="$1" expected="$2" actual="$3"
  [[ "$actual" == "$expected" ]] || fail "$label: expected exit $expected, got $actual (stderr follows)
$(cat "$4" 2>/dev/null || true)"
}

# A small python module, generated once into the scratch dir, shared by every
# fixture's assertion block below so each block stays a few lines of plain
# assert statements instead of re-deriving JSON-shape tolerance each time.
# The --json envelope isn't nailed down by VALIDATOR-SPEC.md (a bare array?
# {"findings": [...]}?), so load_findings() accepts either.
helpers_py="$work_dir/jd_audit_helpers.py"
cat >"$helpers_py" <<'PY'
import json
import sys


def load_findings(path):
    with open(path) as f:
        text = f.read()
    try:
        data = json.loads(text)
    except json.JSONDecodeError as exc:
        sys.exit(f"could not parse --json output as JSON: {exc}\n--- raw output ---\n{text}")
    if isinstance(data, list):
        return data
    if isinstance(data, dict):
        for key in ("findings", "results"):
            if key in data:
                return data[key]
    sys.exit(f"--json output has neither a top-level array nor a 'findings'/'results' key: {text[:500]}")


def where(findings, **fields):
    out = []
    for f in findings:
        if all(str(f.get(k, "")) == str(v) for k, v in fields.items()):
            out.append(f)
    return out


def contains_substr(findings, key, substr):
    return [f for f in findings if substr in str(f.get(key, ""))]
PY

echo "== jd-audit-smoke: staging fixtures and running $validator =="

# --- 1. clean: zero findings, exit 0 -----------------------------------

conv="$(stage_fixture clean)"
out="$work_dir/clean.out.json"; err="$work_dir/clean.err"
set +e
run_validator_json "$conv" "$out" "$err"; code=$?
set -e
assert_exit_code clean 0 "$code" "$err"
python3 - "$out" <<'PY'
import sys
sys.path.insert(0, sys.argv[1].rsplit("/", 1)[0])
from jd_audit_helpers import load_findings

findings = load_findings(sys.argv[1])
assert findings == [], f"clean fixture: expected zero findings, got {len(findings)}: {findings}"
print("clean: OK (0 findings, exit 0)")
PY

# --- 2. drift: drift-undocumented, drift-orphaned, drift-name-mismatch --

conv="$(stage_fixture drift)"
out="$work_dir/drift.out.json"; err="$work_dir/drift.err"
set +e
run_validator_json "$conv" "$out" "$err"; code=$?
set -e
assert_exit_code drift 1 "$code" "$err"
python3 - "$out" <<'PY'
import sys
sys.path.insert(0, sys.argv[1].rsplit("/", 1)[0])
from jd_audit_helpers import load_findings, where

findings = load_findings(sys.argv[1])

undoc = where(findings, check="drift-undocumented", severity="error", id="11.05")
assert undoc, f"drift: expected drift-undocumented/error for 11.05 (Sable Freight, no register entry); findings={findings}"

orphaned = where(findings, check="drift-orphaned", severity="error", id="11.02")
assert orphaned, f"drift: expected drift-orphaned/error for 11.02 (Amber Fleet, register claims code but it's absent); findings={findings}"

mismatch = where(findings, check="drift-name-mismatch", severity="error", id="11.03")
assert mismatch, f"drift: expected drift-name-mismatch/error for 11.03 (Vantage Auto Group vs Vantage Auto); findings={findings}"

print("drift: OK (drift-undocumented, drift-orphaned, drift-name-mismatch all fired)")
PY

# --- 3. split: drift-split-name fires at warn ---------------------------

conv="$(stage_fixture split)"
out="$work_dir/split.out.json"; err="$work_dir/split.err"
set +e
run_validator_json "$conv" "$out" "$err"; code=$?
set -e
assert_exit_code split 0 "$code" "$err"
python3 - "$out" <<'PY'
import sys
sys.path.insert(0, sys.argv[1].rsplit("/", 1)[0])
from jd_audit_helpers import load_findings, where

findings = load_findings(sys.argv[1])
split = where(findings, check="drift-split-name", severity="warn")
assert split, f"split: expected drift-split-name/warn for the Nightlark Studio 13.02/14.02 split; findings={findings}"
print("split: OK (drift-split-name/warn fired)")
PY

# --- 4. split-excepted: REFUTE -- the identical split, now suppressed ---

conv="$(stage_fixture split-excepted)"
out="$work_dir/split-excepted.out.json"; err="$work_dir/split-excepted.err"
set +e
run_validator_json "$conv" "$out" "$err"; code=$?
set -e
assert_exit_code split-excepted 0 "$code" "$err"
python3 - "$out" <<'PY'
import sys
sys.path.insert(0, sys.argv[1].rsplit("/", 1)[0])
from jd_audit_helpers import load_findings, where

findings = load_findings(sys.argv[1])
split = where(findings, check="drift-split-name")
assert not split, (
    "split-excepted: drift-split-name fired even though [[exceptions]] lists it -- "
    f"the suppression mechanism is not working; findings={findings}. "
    "The exception in this fixture keys on path = the normalized label "
    "('nightlark studio'), confirmed against a real validate.py run -- see "
    "gen_fixtures.py's comment on drift-split-name for how that was found."
)
print("split-excepted: OK (drift-split-name suppressed, REFUTE holds)")
PY

# --- 5. deep-numbering: fires on the 4th tier; REFUTE on deep unnumbered nesting

conv="$(stage_fixture deep-numbering)"
out="$work_dir/deep-numbering.out.json"; err="$work_dir/deep-numbering.err"
set +e
run_validator_json "$conv" "$out" "$err"; code=$?
set -e
assert_exit_code deep-numbering 1 "$code" "$err"
python3 - "$out" <<'PY'
import sys
sys.path.insert(0, sys.argv[1].rsplit("/", 1)[0])
from jd_audit_helpers import load_findings, where, contains_substr

findings = load_findings(sys.argv[1])

deep = where(findings, check="structure-deep-numbering", severity="error")
assert deep, f"deep-numbering: expected structure-deep-numbering/error for 80.02.01 Site Photos; findings={findings}"

# The single most important refute in the suite: the real vault nests ten
# directories deep below an ID on purpose (_memory/, projects/, its own git
# repos). A validator that flags unnumbered nesting below an ID would be
# worse than no validator, because it would train the user to ignore output.
nesting_hits = contains_substr(findings, "path", "Thornbridge") + contains_substr(findings, "path", "redacted")
assert not nesting_hits, (
    "deep-numbering: found a finding referencing the deep UNNUMBERED nesting under "
    f"11.01 Thornbridge Legal (projects/discovery/exhibits/redacted/); this must stay "
    f"silent. findings={nesting_hits}"
)
print("deep-numbering: OK (structure-deep-numbering fired on the 4th tier; unnumbered nesting stayed silent)")
PY

# --- 6. triangle: both triangle checks fire, at warn --------------------

conv="$(stage_fixture triangle)"
out="$work_dir/triangle.out.json"; err="$work_dir/triangle.err"
set +e
run_validator_json "$conv" "$out" "$err"; code=$?
set -e
assert_exit_code triangle 0 "$code" "$err"
python3 - "$out" <<'PY'
import sys
sys.path.insert(0, sys.argv[1].rsplit("/", 1)[0])
from jd_audit_helpers import load_findings, where

findings = load_findings(sys.argv[1])

folders = where(findings, check="triangle-constitution-folders", severity="warn")
assert folders, f"triangle: expected triangle-constitution-folders/warn (folder 'Product Design' vs constitution 'UX Practice'); findings={findings}"

register = where(findings, check="triangle-register-constitution", severity="warn")
assert register, f"triangle: expected triangle-register-constitution/warn (register 'Design Systems' vs constitution 'UX Practice'); findings={findings}"

print("triangle: OK (both triangle checks fired at warn)")
PY

# --- 7. links: link-broken/error, link-unverifiable/info, one silent link

conv="$(stage_fixture links)"
out="$work_dir/links.out.json"; err="$work_dir/links.err"
set +e
run_validator_json "$conv" "$out" "$err"; code=$?
set -e
assert_exit_code links 1 "$code" "$err"
python3 - "$out" <<'PY'
import sys
sys.path.insert(0, sys.argv[1].rsplit("/", 1)[0])
from jd_audit_helpers import load_findings, where

findings = load_findings(sys.argv[1])

broken = where(findings, check="link-broken", severity="error")
assert len(broken) == 1, f"links: expected exactly one link-broken/error (the missing Scope Change Memo); got {len(broken)}: {findings}"

unverifiable = where(findings, check="link-unverifiable", severity="info")
assert len(unverifiable) == 1, f"links: expected exactly one link-unverifiable/info (the colleague's-machine link); got {len(unverifiable)}: {findings}"

# link-unverifiable must never be reported as an error -- absolute file://
# URLs encode one machine's mounts, and flagging them as errors everywhere
# would train the user to ignore the whole report.
unverifiable_as_error = where(findings, check="link-unverifiable", severity="error")
assert not unverifiable_as_error, f"links: link-unverifiable must never be severity=error; findings={unverifiable_as_error}"

# REFUTE: the third link (same host, resolves) must produce no finding at all,
# leaving exactly these two findings total.
assert len(findings) == 2, f"links: expected exactly 2 findings total (1 broken + 1 unverifiable), the resolving link should be silent; got {len(findings)}: {findings}"

print("links: OK (link-broken/error x1, link-unverifiable/info x1, resolving link silent)")
PY

# --- 8. bad-schema: unrecognized schema_version, exit 2, refuses to run -

conv="$(stage_fixture bad-schema)"
out="$work_dir/bad-schema.out"; err="$work_dir/bad-schema.err"
set +e
python3 "$validator" --conventions "$conv" --host "$host" >"$out" 2>"$err"
code=$?
set -e
assert_exit_code bad-schema 2 "$code" "$err"
combined="$(cat "$out" "$err" 2>/dev/null || true)"
grep -qi "schema" <<<"$combined" || fail "bad-schema: exit code was 2 as expected, but nothing in stdout/stderr mentions 'schema' -- the spec requires naming the version found and the versions supported
$combined"
echo "bad-schema: OK (exit 2, refused to run, mentions schema)"

echo "== all jd-audit-smoke assertions passed =="
