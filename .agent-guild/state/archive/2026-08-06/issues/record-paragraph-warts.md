`verify-migration.sh` ends a passing run by printing one paragraph for the user to paste into the scope's patterns journal. Two things about that paragraph are wrong, and the reason they shipped is worth recording alongside them.

## Steps to Reproduce

1. Build a scope, migrate it with Tier 1 `--apply`, and commit.
2. Run the sweep against the pre-migration ref:

   ```bash
   bash inbox-to-memory/scripts/verify-migration.sh <scope> --since <pre-migration-ref>
   ```

3. Read the final paragraph, then paste it into a patterns journal as the paragraph itself instructs.

## Observed vs. Expected

**Observed**, on a run that checked exactly one link:

```
... 0 lint failures, 1 links checked (1 by id fallback), 0 renames, 0 deletions. Paste this paragraph into the scope's patterns journal.
```

Two defects:

1. `1 links checked` is ungrammatical at count 1. The other counters read naturally at their observed values, so this is the only one that shows.
2. The closing sentence is an instruction to the reader, and it is inside the thing the reader is told to paste. Follow it literally and the journal entry ends with a direction to paste it into the journal.

**Expected:** the count agrees with its noun (`1 link checked`), and the paste instruction sits outside the record rather than inside it, so what lands in the journal is the record alone.

## Why this shipped

Caught by T-004's checker in the guild run for `kendrick/skills#16`, recorded, and deliberately not failed. Both strings are pinned verbatim by the C-10 suite assertions that a prior task wrote, and a separate clause (C-12) forbids removing or loosening any existing assertion. So the only route to fixing the prose ran through editing a protected assertion, which the task had been told not to do.

That is a constitution-shaped problem rather than a worker mistake, and the retrospective records it as one: a clause that pins an exact literal string buys precision and pays in rigidity. Fixing this issue means changing the assertion and the template together, which is legitimate now that no clause forbids it.

## Acceptance Criteria

- [ ] The link counter agrees with its noun at count 1, and still reads correctly at 0 and at values above 1.
- [ ] The paste instruction is printed outside the record paragraph, so the pasteable text contains no instruction to paste it.
- [ ] The C-10 assertions in `tests/inbox-to-memory-smoke.sh` are updated in step with the template, not deleted.
- [ ] The assertion still discriminates: hard-coding the paragraph's counts to zeros on a run that really checked a link makes the suite fail.
- [ ] All three suites under `tests/` exit 0.

## For a Coding Agent

- **Verify with:** `bash tests/inbox-to-memory-smoke.sh && bash tests/file-issue-smoke.sh && bash tests/handoff-smoke.sh`
- **Setup:** `yq` must be on PATH (`brew install yq`); the scripts refuse without it.
- **Start here:** the record template and its `printf` in `inbox-to-memory/scripts/verify-migration.sh`, and the C-10 assertions in `tests/inbox-to-memory-smoke.sh` that pin the paragraph's prefix, interior counts, and trailing sentence.
- **Done when:** a passing run's pasteable paragraph reads correctly at count 1 and carries no instruction to paste it, with the suite still failing against a zeroed-counts mutant.
- **Out of scope:** the sweep's actual checks. Only the emitted prose and the assertions pinning it change.
