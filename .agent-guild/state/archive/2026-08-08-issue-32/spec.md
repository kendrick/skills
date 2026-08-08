---
source: github-issue
ref: kendrick/skills#32
issue: 32
title: inbox-to-memory: A Broken Wiki Link Goes Unreported in a v1 Note
fetched_at: 2026-08-08T14:47:08Z
---

# inbox-to-memory: A Broken Wiki Link Goes Unreported in a v1 Note

The lint reports a broken wiki link in a v2 note and stays silent on the identical link in a v1 note. The comment that governs this says the opposite should happen, and gives the reason: a link that resolves nowhere is broken in any generation.

Found while building the eval fixtures for #17, where several fixtures are v1 by necessity.

## Steps to Reproduce

From a clean checkout at the repo root:

```bash
S="$(mktemp -d)"; mkdir -p "$S/v1" "$S/v2"
cp -R tests/fixtures/inbox-to-memory/old-only/. "$S/v1/"
cp -R tests/fixtures/inbox-to-memory/mixed/. "$S/v2/"

# The same broken wiki link into one note of each generation. It goes above
# `## Raw Content` because that fence is where extract_body stops, and a link
# below it is out of scope by design rather than by this defect.
V1N="$(ls "$S"/v1/notes/*.md | head -1)"
V2N="$(grep -l '^schema: 2' "$S"/v2/notes/*.md | head -1)"
for f in "$V1N" "$V2N"; do
  python3 - "$f" <<'PY'
import sys
p = sys.argv[1]; t = open(p).read()
i = t.find("## Raw Content")
open(p, "w").write(t[:i] + "\nSee [[this-target-does-not-exist-AAAAAAAAAA]] for background.\n" + t[i:])
PY
done

bash inbox-to-memory/scripts/lint-scope.sh "$S/v1"
bash inbox-to-memory/scripts/lint-scope.sh "$S/v2"
rm -rf "$S"
```

## Observed vs. Expected

**Observed.** The v1 scope passes clean. The v2 scope reports the link.

```
=== v1 scope ===
failures: 0

=== v2 scope ===
FAIL .../notes/2026-01-27-atlas-freeze-check-o7fhuG__gc.md: link-broken: `this-target-does-not-exist-AAAAAAAAAA` resolves neither by name nor by id `AAAAAAAAAA`
failures: 1
```

**Expected.** Both scopes report `link-broken`. The target does not exist in either scope, and the file's schema generation has no bearing on whether the link resolves.

## Where It Happens

Pass one at `inbox-to-memory/scripts/lint-scope.sh:414-424` classifies each file and collects only the v2 ones:

```bash
if ! has_schema_key "$file"; then
  v1=$((v1 + 1))
  continue
fi
v2=$((v2 + 1))
v2_files+=("$file")
```

Pass two then iterates `v2_files` alone, so a v1 file never reaches `check_links` at all. The `continue` predates the body-grammar gate and is doing more work than that gate intends.

## The Comment Is the Contract

`lint-scope.sh:441-443`, inside pass two:

```bash
# The body grammar checks are the ones a v1 body cannot satisfy and was never
# asked to. Links and counts stay on either way: a link that resolves nowhere is
# broken in any generation, and the migrator computes the counts it writes.
```

That is a deliberate design statement with its reasoning attached, not loose wording. The `has_v1_body` guard immediately below it correctly holds back the four body-grammar checks. Links were meant to run regardless, and the pass-one `continue` takes them out before that guard ever gets a say.

## Acceptance Criteria

- [ ] The reproduction above prints `link-broken` for the v1 scope as well as the v2 scope.
- [ ] A v1 note whose wiki links all resolve still passes, including links that resolve only by the trailing ten-character id fallback.
- [ ] `check_tokens`, `check_open_questions`, `check_tensions`, `check_contradictions`, `check_decisions`, and `check_anchors` still do not run on a v1 body. A v1 note carrying `[open-question: foo]` must stay passing, because v1 predates the token grammar and `references/machine-contracts.md:65` scopes that rule to v2 on its face.
- [ ] The `v1 files:` and `v2 files:` counts in the summary are unchanged for every fixture under `tests/fixtures/inbox-to-memory/`.
- [ ] `bash tests/inbox-to-memory-smoke.sh` exits 0.
- [ ] The comment at `:441-443` is reworded so it describes what the code does. Its "and counts" half is misleading whatever else changes: a v1 note carries none of the four derived count keys, so there is nothing on it for a counts check to compare.

## A Risk Worth Naming Before Fixing

No v1 note in any existing scope has ever been link-checked. Turning the check on may surface a real backlog of breakage on the first run against a live vault, and that output will look like the fix caused it. It did not. Anyone running this against real notes should expect the first pass to be a report on accumulated drift rather than a clean bill.

## Out of Scope

- Token grammar on v1 files. That exclusion is deliberate and documented at `references/machine-contracts.md:65`.
- A counts check for v1 files. There are no count keys on a v1 note to check, so the fix here is to the comment's wording rather than to behavior.
- The four body-grammar checks behind `has_v1_body`. They are correct as they stand.

## For a Coding Agent

- **Verify with:** `bash tests/inbox-to-memory-smoke.sh`, plus the reproduction above, which should print `link-broken` twice after the fix.
- **Setup:** bash and python3, both already required by the suite. No other dependencies.
- **Start here:** `inbox-to-memory/scripts/lint-scope.sh`, pass one at `:414-424` and pass two at `:436-450`. `check_links` is at `:365-380`.
- **Done when:** the v1 scope in the reproduction reports `link-broken`, every existing smoke assertion still passes, and no body-grammar check has begun running on a v1 body.
- **Out of scope:** everything under the Out of Scope heading above. Do not widen this into a general v1 linting pass.
