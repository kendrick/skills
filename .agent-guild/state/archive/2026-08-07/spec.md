---
source: github-issue
ref: kendrick/skills#28
issue: 28
title: 'inbox-to-memory: The Budget Claim Overstates Record Headroom, and a tags/themes Mixup Reports as a Budget Overrun'
fetched_at: 2026-08-07T02:26:57Z
---

# inbox-to-memory: The Budget Claim Overstates Record Headroom, and a tags/themes Mixup Reports as a Budget Overrun

Two defects in the v2 frontmatter contract, with one root cause: the record key order has spent all its headroom, and nothing says so.

`references/machine-contracts.md:29` tells you both key orders "fit inside the budget with room left over." Records have none. `NOTE_KEY_ORDER` holds 17 names and closes on line 19, leaving one spare line. `RECORD_KEY_ORDER` holds 19 and closes on line 21, past the budget. The realistic maximum for a record is 18 keys, because `themes` belongs to journal entries and `tags` to everything else, and 18 keys lands on exactly line 20. It passes with nothing to spare.

The same sentence goes on to say an overrun "is almost always accumulated commented-out keys rather than real content." For a fully-populated record the opposite holds: one comment line tips it over.

The second defect is what makes the first one visible. The lint never checks that `tags` and `themes` are mutually exclusive, so a file carrying both is caught only indirectly, as a `frontmatter-budget` failure at line 21. That names the wrong cause—someone reading it deletes a comment to get back under the budget and never learns the file confused a journal entry with a record. It is the failure `lint-scope.sh` was built to avoid: "a defect whose cause changes gets a different message rather than the same generic one."

## Steps to Reproduce

1. From the repo root, build a scope holding a record with every key in `RECORD_KEY_ORDER`:

   ```bash
   t=$(mktemp -d)
   mkdir -p "$t/_inbox" "$t/_memory/decisions"
   cat > "$t/_memory/decisions/full-record-AbCdEfGhIj.md" <<'EOF'
   ---
   schema: 2
   body_schema: 2
   id: AbCdEfGhIj
   memory_type: Decision
   title: 'A fully populated record'
   status: accepted
   date: 2026-03-01
   effective_from: 2026-03-01
   effective_to: 2026-12-31
   last_confirmed: 2026-03-01
   source_refs: [ZGulgExW0q]
   applies_to: [atlas]
   owners: [Kendrick Arnett]
   tags: [cutover]
   themes: [governance]
   related: [extends::JJuYgImRWn]
   exception_to: G2k65qG3Nc
   supersedes: o7fhuG__gc
   superseded_by: zFpm-hfD5u
   ---

   Body.
   EOF
   ```

2. Lint it:

   ```bash
   bash inbox-to-memory/scripts/lint-scope.sh "$t"
   ```

3. Delete the `themes:` line and lint again. The file now closes on line 20 and passes.

## Observed vs. Expected

**Observed:** the record fails with `frontmatter-budget`, pointing at line 21. Nothing mentions that `themes` and `tags` cannot both be present, which is the actual defect in the file. Meanwhile `machine-contracts.md` tells a reader this key order fits with room left over.

**Expected:** the file fails on the key-domain violation and says so. The contract states the real headroom, one spare line for notes and none for records, so anyone adding a key knows what it costs.

## Error Output

```
FAIL /tmp/budget.Y4yKpA/_memory/decisions/full-record-AbCdEfGhIj.md: frontmatter-budget: closing --- on line 21, past the 20-line budget
failures: 1
```

## Minimal Reproduction

The heredoc above is the whole reproduction and needs no fixture. For the passing half, the same record with `tags` and no `themes` is 18 keys, closes on line 20, and reports `failures: 0`.

## Environment

macOS (darwin 25.5.0), bash, `yq`. Repo at branch `inbox-to-memory-v2`; lint at `inbox-to-memory/scripts/lint-scope.sh`.

## For a Coding Agent

- **Verify with:** `bash tests/inbox-to-memory-smoke.sh`
- **Setup:** `bash`, `awk`, and `yq` (`brew install yq`). There is no package manifest; the smoke suites under `tests/` are the whole test surface.
- **Start here:** `inbox-to-memory/scripts/lint-scope.sh` (key orders at :20-21, `check_frontmatter` at :146, `check_key_order` at :117), and `inbox-to-memory/references/machine-contracts.md:29` with the key-order table just below it.
- **Done when:**
  - [ ] A file carrying both `tags` and `themes` fails a named key-domain check instead of `frontmatter-budget`, and the message names both keys.
  - [ ] A journal entry with `themes` and no `tags` still passes, as does a record with `tags` and no `themes`.
  - [ ] The new check is registered in the "What the Lint Checks" table in `machine-contracts.md`.
  - [ ] `machine-contracts.md:29` states the real headroom for each order and drops the claim that overruns are "almost always accumulated commented-out keys."
  - [ ] The smoke suite gains a fixture for the mixup and asserts the named failure, matching how `tests/fixtures/inbox-to-memory/broken/` plants one defect per file.
  - [ ] All three suites under `tests/` exit 0.
- **Out of scope:** raising the 20-line budget, and changing either key order. Both are v2 contract changes with their own blast radius: a migrated scope on disk already assumes the current numbers. This issue makes the existing contract honest and enforced, nothing more.
