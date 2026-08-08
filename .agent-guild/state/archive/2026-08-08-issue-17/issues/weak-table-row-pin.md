The smoke suite pins each lint diagnostic's row in the "What the Lint Checks" table by grepping `machine-contracts.md` for the diagnostic's name. That works only while the name appears exactly once in the file. For `frontmatter-key-domain` it now appears twice, so the assertion would survive deletion of the row it exists to protect.

Found by a checker during the guild run for #28. It did not fail the task, correctly: the clause asked for a pin "the way the suite already pins `contradiction-fields`," and the construct is identical to that precedent. The precedent was only ever safe by accident, because its own string happens to be unique in the file.

## Steps to Reproduce

1. Confirm the assertion passes today:

   ```bash
   bash tests/inbox-to-memory-smoke.sh    # exits 0
   ```

2. Delete the `frontmatter-key-domain` row from the table in `inbox-to-memory/references/machine-contracts.md`, leaving the precedence sentence below the table in place.

3. Re-run the suite.

## Observed vs. Expected

**Observed:** the suite still exits 0. `require_text "$contracts" "frontmatter-key-domain"` at `tests/inbox-to-memory-smoke.sh:565` is satisfied by the prose sentence under the table, which also names the diagnostic. The table row it was written to pin is gone and nothing notices.

**Expected:** removing a documented diagnostic's table row fails the suite. That is the entire job of the assertion.

## Why this is worth fixing beyond the one row

The same construct guards every diagnostic in that table. Each is safe only while its name stays unique across the whole file, which is a property nobody declared and nothing enforces. The next doc edit that mentions a diagnostic in prose silently disarms its pin, and the failure mode is invisible: the suite stays green either way.

Worth considering a pin that matches the row rather than the string, for example asserting a line that contains both the diagnostic name and the table's cell delimiter, or extracting the table and asserting membership in it. Whatever shape it takes, the property to preserve is that the assertion fails when the row is removed.

## Acceptance Criteria

- [ ] Deleting any diagnostic's table row from `machine-contracts.md` makes the suite fail, demonstrated for at least `frontmatter-key-domain` and one other row.
- [ ] Mentioning a diagnostic in prose elsewhere in the file does not, by itself, satisfy that diagnostic's pin.
- [ ] Every diagnostic currently pinned by name is covered by the new approach, not just the one that exposed the gap.
- [ ] All three suites under `tests/` exit 0.

## For a Coding Agent

- **Verify with:** `bash tests/inbox-to-memory-smoke.sh && bash tests/file-issue-smoke.sh && bash tests/handoff-smoke.sh`, plus the row-deletion check above run against a scratch copy.
- **Setup:** `bash`, `awk`, and `yq` (`brew install yq`).
- **Start here:** the `require_text "$contracts" ...` assertions in `tests/inbox-to-memory-smoke.sh`, and the "What the Lint Checks" table in `inbox-to-memory/references/machine-contracts.md`.
- **Done when:** each pinned diagnostic's assertion fails against a copy of the doc with that diagnostic's row deleted.
- **Out of scope:** the table's contents and the lint's behavior. This is about how the suite pins the table, not what the table says.
