#!/usr/bin/env bash
# Pin scaffold_digest.py against issue #65: the same script now lives in
# jd-file/scripts/, jd-audit/scripts/, and inbox-to-memory/scripts/, and the
# three copies are only one contract if they can never quietly fork. jd-file
# owns the algorithm (see the module docstring); the other two are dumb
# copies pulled in by standalone-skill installs, so nothing here imports a
# shared module -- everything runs against the owner copy directly, then
# section 0 checks the other two haven't drifted.
#
# A naive smoke test here would reimplement the digest in Python and compare
# the two implementations -- that passes even when both have the same bug,
# because a change to the algorithm and a change to this test's mirror of it
# move together. Section 1 pins a hardcoded known-answer literal instead:
# nothing in this file can drift with the script, so a change to the
# algorithm or to the document it's hashed against shows up as a failure
# here, not a silent agreement between two copies of the same mistake.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

owner="jd-file/scripts/scaffold_digest.py"
jd_audit_copy="jd-audit/scripts/scaffold_digest.py"
i2m_copy="inbox-to-memory/scripts/scaffold_digest.py"

if [[ ! -f "$owner" ]]; then
  echo "SKIP: $owner does not exist -- scaffold-digest-smoke.sh has nothing to run against." >&2
  exit 0
fi

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

echo "== scaffold-digest-smoke: pinning $owner's contract =="

# --- 0. byte-identical: the two downstream copies must not drift ----------
# Copies land on their own schedule -- jd-audit and inbox-to-memory each get
# their own guard so a copy that hasn't shipped yet skips instead of failing
# the whole suite. Wording matches jd-file-resolve-smoke.sh section 0.

if [[ -f "$jd_audit_copy" ]]; then
  cmp -s "$owner" "$jd_audit_copy" \
    || fail "byte-identical: $owner and $jd_audit_copy have diverged -- the two skills owe each other a byte-identical copy, not a fork"
  echo "byte-identical-jd-audit: OK ($owner and $jd_audit_copy match byte-for-byte)"
else
  echo "byte-identical-jd-audit: SKIP ($jd_audit_copy not yet landed)"
fi

if [[ -f "$i2m_copy" ]]; then
  cmp -s "$owner" "$i2m_copy" \
    || fail "byte-identical: $owner and $i2m_copy have diverged -- the two skills owe each other a byte-identical copy, not a fork"
  echo "byte-identical-inbox-to-memory: OK ($owner and $i2m_copy match byte-for-byte)"
else
  echo "byte-identical-inbox-to-memory: SKIP ($i2m_copy not yet landed)"
fi

# --- 1. Known-answer vector -------------------------------------------------
# The most important assertion in this file. This literal is the digest
# jd-file mints today for a freshly scaffolded Overview; changing it is a
# breaking change to every file already stamped in the wild, so this assert
# is the tripwire for that, not just a regression check on today's code.

python3 - "$owner" <<'PY'
import importlib.util
import sys

owner_path = sys.argv[1]
spec = importlib.util.spec_from_file_location("scaffold_digest", owner_path)
scaffold_digest = importlib.util.module_from_spec(spec)
spec.loader.exec_module(scaffold_digest)

text = (
    "---\n"
    "type: overview\n"
    "stakeholders:\n"
    "tags:\n"
    "  - overview\n"
    "---\n"
    "\n"
    "# 11.01 Riverton Analytics\n"
    "\n"
    "## Log\n"
    "\n"
    "- **2026-08-31** created\n"
)
expected = "sha256:1e484994c6a42dabfcbb82cae847980ea5d55f07f54cc2a5193ccfd2ae3ade6e"
digest = scaffold_digest.compute(text)
assert digest == expected, (
    f"known-answer vector mismatched: got {digest}, want {expected} -- "
    "this is either a real algorithm regression or a breaking change to "
    "every scaffold_digest already stamped on disk"
)
print("known-answer: OK (compute() matches the pinned literal)")
PY

# --- 2. compute() properties ------------------------------------------------

python3 - "$owner" <<'PY'
import importlib.util
import re
import sys

owner_path = sys.argv[1]
spec = importlib.util.spec_from_file_location("scaffold_digest", owner_path)
scaffold_digest = importlib.util.module_from_spec(spec)
spec.loader.exec_module(scaffold_digest)

body_doc = (
    "---\n"
    "type: overview\n"
    "---\n"
    "\n"
    "same body, different line endings\n"
)
lf_digest = scaffold_digest.compute(body_doc)
crlf_digest = scaffold_digest.compute(body_doc.replace("\n", "\r\n"))
assert lf_digest == crlf_digest, "LF and CRLF encodings of the same body must hash identically"

assert re.fullmatch(r"sha256:[0-9a-f]{64}", lf_digest), f"digest format or case is wrong: {lf_digest}"

# Malformed input must raise ValueError, not IndexError -- a caller catching
# ValueError (the CLI does, to report EXIT_STRUCTURE) would let an IndexError
# straight through uncaught.
for bad in ("no frontmatter here\n", "---\nunterminated\n", ""):
    for fn in (scaffold_digest.compute, scaffold_digest.stored):
        try:
            fn(bad)
        except ValueError:
            pass
        except Exception as exc:
            raise AssertionError(
                f"{fn.__name__}({bad!r}) raised {type(exc).__name__}, not ValueError"
            )
        else:
            raise AssertionError(f"{fn.__name__}({bad!r}) did not raise")

print("compute-properties: OK (CRLF normalizes, format is lowercase hex, malformed input raises ValueError)")
PY

# --- 3. stamp inserts and replaces ------------------------------------------

python3 - "$owner" <<'PY'
import importlib.util
import sys

owner_path = sys.argv[1]
spec = importlib.util.spec_from_file_location("scaffold_digest", owner_path)
scaffold_digest = importlib.util.module_from_spec(spec)
spec.loader.exec_module(scaffold_digest)

def key_names(frontmatter_lines):
    names = []
    for line in frontmatter_lines:
        name, sep, _ = line.partition(":")
        if sep:
            names.append(name.strip())
    return names

# -- key absent: restamp inserts, every other line survives untouched --
doc_no_key = (
    "---\n"
    "type: overview\n"
    "stakeholders:\n"
    "tags:\n"
    "  - overview\n"
    "---\n"
    "\n"
    "# Body\n"
    "\n"
    "content here\n"
)
restamped = scaffold_digest.restamp(doc_no_key)
assert scaffold_digest.stored(restamped) == scaffold_digest.compute(restamped), (
    "a freshly inserted key must match the body it was stamped from"
)

before_lines = doc_no_key.splitlines(keepends=True)
after_lines = [
    line for line in restamped.splitlines(keepends=True)
    if line.partition(":")[0].strip() != scaffold_digest.KEY
]
assert after_lines == before_lines, "restamp must not touch any line besides the one it inserts"

# -- key present: value replaced in place, idempotent, order unchanged --
doc_with_key = (
    "---\n"
    "type: overview\n"
    'scaffold_digest: "sha256:' + "0" * 64 + '"\n'
    "stakeholders:\n"
    "tags:\n"
    "  - overview\n"
    "---\n"
    "\n"
    "# Body\n"
    "\n"
    "content here\n"
)
before_order = key_names(scaffold_digest._split(doc_with_key)[0].splitlines())

restamped_once = scaffold_digest.restamp(doc_with_key)
after_order = key_names(scaffold_digest._split(restamped_once)[0].splitlines())
assert after_order == before_order, (
    f"restamp reordered frontmatter keys: {before_order} -> {after_order}"
)
assert scaffold_digest.stored(restamped_once) == scaffold_digest.compute(restamped_once), (
    "the replaced value must match the body"
)
assert scaffold_digest.stored(restamped_once) != scaffold_digest.stored(doc_with_key), (
    "a bogus placeholder digest must actually get overwritten, not left alone"
)

restamped_twice = scaffold_digest.restamp(restamped_once)
assert restamped_twice == restamped_once, "restamp must be idempotent once the digest already matches"

# -- CRLF file keeps CRLF endings through a stamp --
crlf_doc = doc_no_key.replace("\n", "\r\n")
restamped_crlf = scaffold_digest.restamp(crlf_doc)
assert restamped_crlf.replace("\r\n", "").count("\n") == 0, (
    "restamping a CRLF file must not introduce bare LF endings"
)
assert scaffold_digest.stored(restamped_crlf) == scaffold_digest.compute(crlf_doc), (
    "the stamped digest for a CRLF file must match its (CRLF-normalized) body"
)

print("stamp-insert-replace: OK (insert leaves other lines untouched, replace preserves key order and is idempotent, CRLF survives)")
PY

# --- 4. CLI exit codes -------------------------------------------------------
# The CLI is what jd-audit and inbox-to-memory actually shell out to, so the
# exit codes are the real contract -- not just what compute()/stored() raise
# in-process.

cli_dir="$work_dir/cli"
mkdir -p "$cli_dir"

fresh_doc() {
  cat <<'EOF'
---
type: overview
tags:
  - overview
---

# Body

content here
EOF
}

ok_file="$cli_dir/ok.md"
fresh_doc >"$ok_file"

python3 "$owner" --stamp "$ok_file" >/dev/null

set +e
check_err="$(python3 "$owner" --check "$ok_file" 2>&1 >/dev/null)"; code=$?
set -e
[[ "$code" == 0 ]] || fail "cli-ok: --check after --stamp expected exit 0, got $code
$check_err"
echo "cli-ok: OK (stamp then check exits 0)"

mismatch_file="$cli_dir/mismatch.md"
cp "$ok_file" "$mismatch_file"
printf 'an unstamped edit\n' >>"$mismatch_file"

set +e
mismatch_err="$(python3 "$owner" --check "$mismatch_file" 2>&1 >/dev/null)"; code=$?
set -e
[[ "$code" == 1 ]] || fail "cli-mismatch: expected exit 1, got $code
$mismatch_err"
grep -qF "$mismatch_file" <<<"$mismatch_err" || fail "cli-mismatch: stderr does not name the file: $mismatch_err"
echo "cli-mismatch: OK (exit 1, stderr names the file)"

nofm_file="$cli_dir/no-frontmatter.md"
printf 'just a plain file, no frontmatter at all\n' >"$nofm_file"

set +e
python3 "$owner" --check "$nofm_file" >/dev/null 2>&1; code=$?
set -e
[[ "$code" == 2 ]] || fail "cli-no-frontmatter: expected exit 2, got $code"
echo "cli-no-frontmatter: OK (no frontmatter block exits 2)"

nokey_file="$cli_dir/no-key.md"
fresh_doc >"$nokey_file"

set +e
python3 "$owner" --check "$nokey_file" >/dev/null 2>&1; code=$?
set -e
[[ "$code" == 2 ]] || fail "cli-no-key: a frontmatter with no scaffold_digest key must exit 2 (structure), not 1 (mismatch) -- got $code"
echo "cli-no-key: OK (missing key is exit 2, not collapsed into a mismatch)"

set +e
usage_err="$(python3 "$owner" --stamp --check "$ok_file" 2>&1 >/dev/null)"; usage_code=$?
set -e
[[ "$usage_code" != 0 ]] || fail "cli-usage-error: --stamp and --check together must not succeed"
grep -qi "not allowed" <<<"$usage_err" || fail "cli-usage-error: stderr doesn't read like an argparse usage error: $usage_err"
echo "cli-usage-error: OK (--stamp and --check together is rejected)"

# --- 5. Round-trip through the CLI ------------------------------------------

roundtrip_file="$work_dir/roundtrip.md"
fresh_doc >"$roundtrip_file"

set +e
python3 "$owner" --stamp "$roundtrip_file" >/dev/null 2>&1; code_a=$?
python3 "$owner" --check "$roundtrip_file" >/dev/null 2>&1; code_b=$?
set -e

printf '\nanother unstamped line\n' >>"$roundtrip_file"

set +e
python3 "$owner" --check "$roundtrip_file" >/dev/null 2>&1; code_c=$?
set -e

python3 "$owner" --stamp "$roundtrip_file" >/dev/null

set +e
python3 "$owner" --check "$roundtrip_file" >/dev/null 2>&1; code_d=$?
set -e

[[ "$code_a" == 0 ]] || fail "round-trip: initial --stamp expected exit 0, got $code_a"
[[ "$code_b" == 0 ]] || fail "round-trip: --check after --stamp expected exit 0, got $code_b"
[[ "$code_c" == 1 ]] || fail "round-trip: --check after an unstamped append expected exit 1, got $code_c"
[[ "$code_d" == 0 ]] || fail "round-trip: --check after re-stamping expected exit 0, got $code_d"
echo "round-trip: OK (stamp -> check 0 -> append -> check 1 -> stamp -> check 0)"

echo "== all scaffold-digest-smoke assertions passed =="
