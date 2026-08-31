#!/usr/bin/env bash
# Pin the writer-half of #57's scaffold_digest contract: the template carries
# the key, and SKILL.md's Step 5 tells the agent to stamp at mint time and to
# re-stamp after a Log append. The script those instructions name is what
# actually computes the digest, and the round-trip below proves it
# discriminates on a real Overview.
#
# A naive pass here would just grep for the string "scaffold_digest" anywhere
# in the two files and call it done -- that would go green even if the prose
# described a digest that never changes, or a template with the key spelled
# in a comment nobody reads. Pinning the instruction to run the script catches
# prose drift; the round-trip in section 5 catches the case where the key
# exists but nothing actually recomputes or discriminates on it -- without
# the mismatch assert in step (c), a no-op digest would still pass every
# other check here.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

template="jd-file/assets/overview.template.md"
skill="jd-file/SKILL.md"

if [[ ! -f "$template" ]]; then
  echo "SKIP: $template does not exist -- jd-file-overview-smoke.sh has nothing to run against." >&2
  exit 0
fi

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

# Lifted from handoff-smoke.sh -- there is no shared library in tests/, every
# script redefines its own. Routed through fail() so a broken prose pin reports
# with the same FAIL: prefix as every other assertion in this file.
require_text() {
  local file="$1"
  local text="$2"
  grep -Fq -- "$text" "$file" || fail "missing expected text in $file: $text"
}

echo "== jd-file-overview-smoke: checking scaffold_digest contract in $template and $skill =="

# --- 1. Template carries the key ------------------------------------------

require_text "$template" 'scaffold_digest:'
require_text "$template" 'sha256:'
echo "template-key: OK (scaffold_digest and sha256 both present)"

# --- 2. Mint-time stamp pinned in SKILL.md ---------------------------------

# The pin is the pointer, not the algorithm. Step 5 used to spell the hash out
# in prose, which made it a fourth place the rule was written down; the script
# is the authority now, so what has to survive an edit is the instruction to
# run it.
require_text "$skill" 'scripts/scaffold_digest.py --stamp'
echo "mint-stamp-prose: OK (Step 5 points at the script)"

# --- 3. Re-stamp rule pinned in SKILL.md -----------------------------------

require_text "$skill" 're-stamp `scaffold_digest`'
echo "re-stamp-rule: OK (post-Log-append re-stamp instruction pinned)"

# --- 4. Done-when clause pinned in SKILL.md --------------------------------

require_text "$skill" 'whose `scaffold_digest` matches its body'
echo "done-when: OK (Step 5 done-when clause pinned)"

# --- 5. Round-trip: the algorithm is implementable and discriminates ------

overview_path="$work_dir/Overview.md"

python3 - "$overview_path" <<'PY'
import re
import sys

path = sys.argv[1]

# Exercise the shipped script, not a copy of it. This file used to carry its
# own implementation of the algorithm, which made it one more place the rule
# could drift; jd-file/scripts/scaffold_digest.py is the authority now, and a
# round-trip that reimplemented it would pass while the real writer was broken.
# The digest's exact byte range is pinned by a known-answer vector in
# tests/scaffold-digest-smoke.sh.
sys.path.insert(0, "jd-file/scripts")
from scaffold_digest import compute as scaffold_digest

def render(digest, log_extra=""):
    return (
        "---\n"
        "type: overview\n"
        f'scaffold_digest: "{digest}"\n'
        "stakeholders:\n"
        "tags:\n"
        "  - overview\n"
        "---\n"
        "\n"
        "# 11.01 Riverton Analytics\n"
        "\n"
        "> [!info] This ID's purpose lives in the register, not here.\n"
        "\n"
        "## Context\n"
        "\n"
        "- Riverton's onboarding notes and the first quarter's decisions.\n"
        "\n"
        "## Log\n"
        "\n"
        "- **2026-08-31** — created\n"
        f"{log_extra}"
    )

def stored_digest(text):
    m = re.search(r'scaffold_digest: "([^"]+)"', text)
    assert m, f"no scaffold_digest line found in:\n{text}"
    return m.group(1)

# a/b. Mint: stamp a fresh body, write it, re-read from disk, and confirm a
# fresh mint matches -- the digest is computed over the body only, so the
# placeholder value doesn't matter until we substitute the real one in.
draft = render("PENDING")
minted_digest = scaffold_digest(draft)
minted = render(minted_digest)
with open(path, "w", encoding="utf-8", newline="\n") as f:
    f.write(minted)

on_disk = open(path, encoding="utf-8", newline="").read()
assert scaffold_digest(on_disk) == stored_digest(on_disk) == minted_digest, (
    "a fresh mint must match its own stamped digest"
)

# c. Append a Log line WITHOUT re-stamping. This is the assertion that proves
# the key discriminates -- a digest that never changes would sail through
# every other check in this file and still be a no-op.
appended = on_disk + "- **2026-09-01** — filed example.md\n"
with open(path, "w", encoding="utf-8", newline="\n") as f:
    f.write(appended)

on_disk = open(path, encoding="utf-8", newline="").read()
stale_stored = stored_digest(on_disk)
stale_recomputed = scaffold_digest(on_disk)
assert stale_recomputed != stale_stored, (
    "an unstamped append must break the digest match -- if this holds, "
    "scaffold_digest cannot tell a scaffold from a human edit"
)

# d. Re-stamp from the new body and confirm it matches again.
restamped = on_disk.replace(
    f'scaffold_digest: "{stale_stored}"', f'scaffold_digest: "{stale_recomputed}"'
)
with open(path, "w", encoding="utf-8", newline="\n") as f:
    f.write(restamped)

on_disk = open(path, encoding="utf-8", newline="").read()
assert scaffold_digest(on_disk) == stored_digest(on_disk), (
    "re-stamping from the current body must produce a matching digest"
)

# e. A CRLF copy of the same body hashes identically to the LF copy -- this
# pins the normalization clause, not just its existence.
crlf_copy = on_disk.replace("\n", "\r\n")
assert scaffold_digest(crlf_copy) == scaffold_digest(on_disk), (
    "CRLF and LF copies of the same body must hash identically"
)

print("round-trip: fresh mint matches, unstamped append mismatches, "
      "re-stamp matches again, CRLF/LF are equivalent")
PY

[[ -f "$overview_path" ]] || fail "round-trip heredoc did not leave $overview_path behind"
grep -Fq -- "2026-09-01" "$overview_path" || fail "round-trip file is missing the appended Log line"
echo "round-trip: OK (digest is implementable, discriminates, and normalizes CRLF)"

echo "== all jd-file-overview-smoke assertions passed =="
