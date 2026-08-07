# Constitution: inbox-to-memory — honest budget headroom and a named tags/themes check

Source: `kendrick/skills#28`, spec at `.agent-guild/state/spec.md`. The v2 contract work (#16) shipped at `d4ce6d2` on this branch; everything below builds on it and must leave it working.

Two decisions were settled with the user before drafting, and every clause assumes them:

- **The check is mutual exclusion, not domain assignment.** A file carrying both `tags` and `themes` fails. A record carrying only `tags`, or a journal entry carrying only `themes`, passes. The stricter rule (rejecting `themes` on a non-Journal, or `tags` on a Journal) was considered and deliberately declined: it goes past the issue's stated criteria. It is a non-goal below, not an oversight.
- **The diagnostic is `frontmatter-key-domain`**, matching the house `frontmatter-*` prefix its six siblings already use.

Two facts about the current code that shape several clauses, both reproduced against the tree at `d4ce6d2` rather than taken from the issue:

- `RECORD_KEY_ORDER` holds 19 names and closes on line 21, past the 20-line budget. `NOTE_KEY_ORDER` holds 17 and closes on line 19. Both key orders route by `memory_type`: a file carrying that key is checked against the record order, everything else against the note order. Journal entries carry `memory_type: Journal`, which is why one order legitimately holds both `tags` and `themes`.
- `check_frontmatter` **returns early** after `fail frontmatter-budget` (`lint-scope.sh:156-159`). A 21-line file therefore never reaches the key checks at all. This is the mechanism behind the reported bug: the mixup is not merely unchecked, it is unreachable. Adding a check without addressing the ordering fixes nothing.

A note on check methods. `tests/inbox-to-memory-smoke.sh` is this job's own deliverable, so "the suite exits 0" proves only that the worker passed whatever the worker chose to write. The previous job on this branch shipped two assertions that passed against a deliberately broken implementation, and only mutation testing caught them. Every clause below whose evidence lives in the suite therefore routes to `checker-judgment` and names the mutant the assertion must fail against.

## Clauses

### C-1: The mixup fails under its own name
- **text**: A file carrying both `tags:` and `themes:` fails with the diagnostic `frontmatter-key-domain`. The message names the file and both keys, so a reader learns the file confused a journal entry with a record rather than learning it is one line too long.
- **check**: checker-judgment: run the suite (must exit 0), then build the issue's reproduction by hand and confirm the shipped lint reports `frontmatter-key-domain` naming both `tags` and `themes`, and does not report `frontmatter-budget` for that file.
- **severity**: blocker
- **failing example**: the fully-populated record from the spec's heredoc lints with `frontmatter-budget: closing --- on line 21`, exactly as it does today, and nothing in the output mentions `tags` or `themes`.

### C-2: The check is reachable on the file that motivated it
- **text**: The key-domain check runs on a frontmatter block that overruns the 20-line budget, and takes precedence over the budget failure there. A 21-line record carrying both keys reports `frontmatter-key-domain` and does not report `frontmatter-budget`, per C-1. The mixup is the cause; the overrun is its symptom, and naming the symptom is the bug this job exists to fix.
- **check**: checker-judgment: confirm the suite asserts, against a file whose frontmatter block closes past line 20, both that `frontmatter-key-domain` is reported and that `frontmatter-budget` is not. Then verify the assertion discriminates: on a scratch copy of the tree, move the key-domain check to sit after the existing budget guard, re-run the suite there, and confirm it now fails. An assertion that stays green under that mutation is not testing reachability, whatever it appears to assert. Mutate a copy or restore the file before returning: a checker that leaves `lint-scope.sh` modified hands the next checker a dirty tree it will attribute to the worker, C-8's diff-scope run included.
- **severity**: blocker
- **failing example**: `frontmatter-key-domain` is implemented correctly and placed after the budget guard at `lint-scope.sh:156-159`. Every file the issue is about is 21 lines, hits the `return`, and never reaches the new check. The suite passes because its own fixture happens to be under 20 lines, and the reported bug is untouched.

### C-3: Both single-key cases still pass
- **text**: A journal entry carrying `themes` and no `tags` lints clean, and a record carrying `tags` and no `themes` lints clean. The check fires on the presence of both keys, never on either alone.
- **check**: checker-judgment: confirm the suite asserts both cases pass, and that neither assertion is satisfied vacuously by a file the lint skips for some other reason. A v1 file carrying no `schema` key is skipped entirely and proves nothing, so an assertion resting on one fails this clause.
- **severity**: blocker
- **failing example**: the check tests `memory_type` rather than key co-presence, so a journal entry carrying `themes` and no `tags` starts failing. The assertion that catches it is `require_line "$jrn_lint" "failures: 0" journal-migrated` at `tests/inbox-to-memory-smoke.sh:708`, which lints a *migrated* journal scope. The unmigrated `journal-v1` fixture cannot catch it: with no `schema` key the lint skips those files, so they stay green under any implementation.

### C-4: The contract states the real headroom
- **text**: `references/machine-contracts.md:29` no longer claims both key orders "fit inside the budget with room left over," and no longer claims an overrun "is almost always accumulated commented-out keys rather than real content." It states the actual headroom: one spare line for the note order, none for the record order, whose realistic maximum of 18 keys lands on exactly line 20.
- **check**: checker-judgment: confirm both false claims are gone, and that the replacement numbers match what the key orders in `lint-scope.sh` actually produce, recounted at check time rather than copied from this clause.
- **severity**: blocker
- **failing example**: the sentence is rewritten to read well but still says records have headroom, so the next person adding a record key reads the doc, believes there is room, and ships a file that cannot lint.

### C-5: The new check is registered where readers look for it
- **text**: `frontmatter-key-domain` appears in the "What the Lint Checks" table in `machine-contracts.md` with a "Fails when" description matching its behavior, alongside its six `frontmatter-*` siblings.
- **check**: checker-judgment: confirm the table row exists, that its description matches what the shipped check actually does, and that the suite pins the row the way it already pins `contradiction-fields` at `tests/inbox-to-memory-smoke.sh:521`.
- **severity**: blocker
- **failing example**: the check ships and the table doesn't mention it, so the table a reader consults after hitting a failure is missing the newest diagnostic, and the failure name leads nowhere.

### C-6: The fixture plants one defect, like its neighbours
- **text**: The smoke suite gains a fixture for the mixup under `tests/fixtures/inbox-to-memory/broken/`, carrying that one defect and no other, matching the one-defect-per-file convention the directory already follows.
- **check**: checker-judgment: confirm the new fixture exists under `broken/`, that linting it produces the `frontmatter-key-domain` failure and no unrelated failure, and that the suite's existing `failures:` arithmetic for the broken scope was updated to match rather than left stale.
- **severity**: major
- **note**: non-normative, for the worker's orientation rather than the checker's judgment. This fixture is under the budget and carries only the mixup, so it cannot also serve C-2, whose file must close past line 20 and therefore has a second thing wrong with it by construction. An inline scope built in the suite, the way the migration sections already build throwaway scopes, is the obvious home for C-2's case, but nothing here requires that siting. Two fixtures, two clauses, no conflict.
- **failing example**: the fixture also carries a bad key order, so it fails two checks at once and the assertion cannot tell which one caught it, which is the ambiguity the one-defect convention exists to prevent.

### C-7: No existing assertion is deleted or weakened
- **text**: The suites may gain assertions and may not lose them. Every `require_*` / `refute_*` call present at `d4ce6d2` still runs and still asserts the same thing.
- **check**: checker-judgment: extract every `require_*`/`refute_*` line from each suite at `d4ce6d2` and from the working copy, sort both, and confirm `comm -23` of base against current is empty. Then run `bash tests/inbox-to-memory-smoke.sh && bash tests/file-issue-smoke.sh && bash tests/handoff-smoke.sh` (all must exit 0). A green suite alone does not satisfy this clause.
- **severity**: blocker
- **failing example**: the broken scope's `failures: N` assertion is deleted rather than updated when the new fixture changes the count. All three suites still exit 0, and the arithmetic that proves every planted defect is caught stops being tested.

### C-8: The diff stays in scope
- **text**: The deliverable touches only the `inbox-to-memory/` skill and `tests/`. `.agent-guild/` is this job's own harness and is not part of the deliverable.
- **check**: `python3 .agent-guild/scripts/check-diff-scope.py inbox-to-memory/ tests/ --ignore .agent-guild/`
- **severity**: blocker
- **failing example**: a helper lands in `handoff/scripts/` because it was useful there too, and a job scoped to one skill has quietly changed another.

### C-9: The prose reads like a person wrote it
- **text**: Every human-facing string this job adds or rewrites — the `machine-contracts.md` headroom sentence, the new table row, the failure message itself, any new comment in `lint-scope.sh`, and the commit message — reads as though a person wrote it, judged against the `humanizer` skill's pattern list and the voice of the surrounding files: a technical writer in a hurry, comments explaining why rather than what.
- **check**: checker-judgment: read the added prose against the `humanizer` skill's pattern list and the surrounding files' voice; flag rule-of-three padding, promotional framing, bolded inline headers, and comments that restate the code. Title-case headings and occasional unspaced em dashes are correct here, not findings. Spaced em dashes are a finding.
- **severity**: major
- **note**: non-normative. The clause deliberately grades the artifact rather than the process, because no checker can see whether the `humanizer` skill was invoked. Running it is still the house habit and belongs in the worker's task brief as an instruction; it just cannot be a clause, since a promise nothing can falsify is decoration. Both the auditor and the codex lane flagged the earlier process-shaped wording independently.
- **failing example**: the new contract sentence opens with "It is important to note that the frontmatter budget plays a crucial role," and the lint comment above the new check reads "check if tags and themes are both present."

## Protected content

Nothing in this job ships verbatim author words, so there is no passages manifest.

## Non-goals

- Raising the 20-line budget, and changing either key order. Both are v2 contract changes with their own blast radius: a migrated scope on disk already assumes the current numbers.
- Domain assignment. Rejecting `themes` on a non-Journal record, or `tags` on a Journal entry, was considered and declined as past the issue's criteria. The check fires on co-presence only.
- Changing v1 legality. Files with no `schema` key stay legal and the lint keeps skipping them.
- Migrating or rewriting any file on disk. This job changes a lint and a doc, not anyone's notes.
- New lint checks unrelated to the tags/themes mixup.
- Reconciling the record order down to 18 names so it fits. That is a key-order change, which is out of scope above.
