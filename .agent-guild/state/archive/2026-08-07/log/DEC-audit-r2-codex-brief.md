# Second-opinion audit brief: DEC-audit r2 (kendrick/skills#28)

You are `checker-courier` relaying a decomposition audit for a second opinion. Judge ONLY the material inlined below. You cannot read any repository, run any command, or see anything outside this prompt. Judge script-based checks against the "Evidence collected locally" section.

## Rubric

Two task files decompose a bug-fix job. Apply the DEC-audit rubric:

1. **Coverage** — every requirement in the spec's "Done when" list, and every constitution clause, maps to at least one task. Name anything uncovered.
2. **Clause citation** — each task's `check_method` is consistent with the FULL TEXT of every clause it cites. A check_method that cites a clause and checks only part of it is a defect, as is one whose assertion could pass vacuously.
3. **Routing** — mechanical work to worker-bulk (haiku), clear-spec implementation to worker-standard (sonnet), taste/prose to worker-craft (opus). Script-checked clauses route to checker-deterministic, rubric-checked clauses to checker-judgment.
4. **DAG** — `deps` is acyclic and every referenced task exists.

Context you need:
- The orchestrator's routing rationale: T-001 is clear-spec bash implementation, T-002 is prose and taste. Both check with checker-judgment because each mixes judgment clauses with C-8's deterministic script, and a judgment checker can run a script while a deterministic one cannot apply a rubric.
- `deps` is a two-node chain because T-002's docs must describe the check T-001 actually shipped rather than the one it was asked to ship.
- C-9 (prose quality) is deliberately split by author across both tasks rather than owned by one, because both write to the same test-suite file.
- The linter enforces a 20-line frontmatter budget. The bug: a record carrying both `tags` and `themes` is 21 lines, fails the budget check, and that check returns early — so the real defect is never named and is currently unreachable.

## Verdict you must produce

Emit ONLY a JSON object with exactly these nine fields:
- "task_id": "DEC-audit"
- "checker": "checker-courier"
- "vendor": "openai"
- "model": "gpt-5.6-terra"
- "verdict": "pass" | "fail" | "blocked"
- "summary": one paragraph
- "findings": array of {"clause_id", "severity", "description", "evidence"} — REQUIRED non-empty if verdict is "fail". For a finding about a task rather than a clause, put the task id in "clause_id" (e.g. "T-001"). Advisory notes belong in "summary", not "findings".
- "duration_ms": null
- "cost_usd": null

---

## The constitution (verbatim)

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

---

## The spec (verbatim)

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

---

## Task file: T-001.md (verbatim)

---
id: T-001
title: Add the frontmatter-key-domain check, reachable past the budget guard
spec: .agent-guild/state/spec.md#for-a-coding-agent
clauses: [C-1, C-2, C-3, C-6, C-7, C-8, C-9]
executor: worker-standard
executor_model: sonnet
checker: checker-judgment
check_method: >-
  C-1: checker-judgment: run the suite (must exit 0), then build the spec's
  reproduction heredoc by hand and confirm the shipped lint reports
  frontmatter-key-domain naming the file and both keys, and does NOT report
  frontmatter-budget for that file. C-2: checker-judgment: confirm the suite
  asserts, against a file whose frontmatter block closes past line 20, both that
  frontmatter-key-domain is reported and that frontmatter-budget is not. Then
  verify the assertion discriminates: on a SCRATCH COPY of the tree, move the
  key-domain check to sit after the existing budget guard, re-run the suite
  there, and confirm it now fails. Mutate a copy or restore the file before
  returning — a dirty lint-scope.sh is attributed to the worker by C-8's
  diff-scope run. C-3: checker-judgment: confirm the suite asserts a journal
  entry with themes and no tags lints clean, and a record with tags and no
  themes lints clean, and that neither assertion rests on a v1 file the lint
  skips for having no schema key. The live assertion a memory_type-based
  implementation breaks is require_line "$jrn_lint" "failures: 0"
  journal-migrated at tests/inbox-to-memory-smoke.sh:708. C-6: checker-judgment:
  confirm the new broken/ fixture carries the mixup and no other defect, that
  linting it produces frontmatter-key-domain and no unrelated failure, and that
  the broken scope's failures: N arithmetic was updated rather than left stale.
  Check for a MASKED second defect rather than trusting the single failure line:
  the new check returns before check_key_order runs, so a fixture with a second
  problem still reports exactly one failure. Confirm the fixture carries
  memory_type (routing it to RECORD_KEY_ORDER) and that every key in it appears
  in that order. Judge by the memory_type key, not by the directory: routing is
  keyed on that field, so a file carrying it lints as a record wherever it sits.
  A fixture with no memory_type fails this clause, because themes is absent from
  NOTE_KEY_ORDER and such a file therefore also violates frontmatter-known-keys,
  carrying two defects with the second one hidden. Also confirm the comment at
  tests/inbox-to-memory-smoke.sh:151-155 was rewritten to match the new
  arithmetic: it currently explains the off-by-one by calling the scope's lone
  record defect-free, which this fixture makes false.
  C-7: checker-judgment: extract every require_*/refute_* line from each suite
  at d4ce6d2 and from the working copy, sort both, and confirm comm -23 of base
  against current is empty; then run all three suites (must exit 0). A green
  suite alone does not satisfy this. C-8: python3
  .agent-guild/scripts/check-diff-scope.py inbox-to-memory/ tests/ --ignore
  .agent-guild/ C-9: checker-judgment: read the failure message string, and
  every comment this task ADDS OR REWRITES in lint-scope.sh and in
  tests/inbox-to-memory-smoke.sh — the rewritten :151-155 arithmetic comment
  included, since a rewritten comment is prose this job is responsible for just
  as much as a new one, matching constitution.md:69's "adds or rewrites" —
  against the humanizer skill's pattern list and each file's existing voice;
  flag comments that restate the next line rather than explaining why,
  rule-of-three padding, and promotional framing. Spaced em dashes are a
  finding; unspaced ones are not. The machine-contracts.md prose belongs to
  T-002, as does any suite comment T-002 adds.
status: pending
retries: 0
max_retries: 2
deps: []
escalations: []
artifacts: []
---

## Spec excerpt

Add a `frontmatter-key-domain` check to `inbox-to-memory/scripts/lint-scope.sh`, plus the fixture and suite assertions that pin it.

**The rule.** A file whose frontmatter carries both `tags:` and `themes:` fails with the diagnostic `frontmatter-key-domain`. The message names the file and both keys. A file carrying only one of them passes, whatever its `memory_type`. This is mutual exclusion, not domain assignment — do NOT reject `themes` on a non-Journal record or `tags` on a Journal entry. That stricter rule was considered and declined; it is a non-goal.

**The part that is easy to get wrong, and is the actual bug.** `check_frontmatter` currently does this at `lint-scope.sh:156-159`:

```bash
if [[ "$end" -gt "$FRONTMATTER_LINE_BUDGET" ]]; then
  fail frontmatter-budget "closing --- on line $end, past the $FRONTMATTER_LINE_BUDGET-line budget"
  return
fi
```

Every file this issue is about is 21 lines, hits that `return`, and never reaches the key checks. So a key-domain check added anywhere after that guard is correct and unreachable, and the reported bug survives. Your check must run on a block that overruns the budget, and must take precedence there: the 21-line record reports `frontmatter-key-domain` and does **not** report `frontmatter-budget`. The mixup is the cause; the overrun is its symptom, and naming the symptom is what this job exists to fix.

How you site the check is yours to choose — inside `check_frontmatter` ahead of the budget guard, or in its own function called earlier. Both are fine if the behavior above holds.

**Background you need.** The lint routes by `memory_type` (`lint-scope.sh:181-186`): a file carrying that key is checked against `RECORD_KEY_ORDER`, everything else against `NOTE_KEY_ORDER`. Journal entries carry `memory_type: Journal`, which is why one key order legitimately holds both `tags` and `themes`. `RECORD_KEY_ORDER` is 19 names and closes on line 21; dropping either key lands on exactly line 20.

**Reproduction to work against**, from the issue:

```bash
t=$(mktemp -d); mkdir -p "$t/_inbox" "$t/_memory/decisions"
# a record with all 19 RECORD_KEY_ORDER keys, including both tags: and themes:
bash inbox-to-memory/scripts/lint-scope.sh "$t"
```
Today that prints `frontmatter-budget: closing --- on line 21` and nothing about `tags` or `themes`. Deleting the `themes:` line makes it pass.

**Fixtures and assertions.** Two separate cases, and they cannot share a file:

- A fixture under `tests/fixtures/inbox-to-memory/broken/_memory/decisions/` carrying the mixup and nothing else, under the 20-line budget, matching the one-defect-per-file convention that directory already follows.

  **Three things at `tests/inbox-to-memory-smoke.sh:151-159` move together, and the comment is the one that bites.** The counts at `:158-159` are `v2 files: 19` and `failures: 18`; your fixture makes them 20 and 19. Update both rather than deleting either. The comment at `:151-155` explains the off-by-one this way: "the lone record in this scope is link bait, carries no defect, and is the reason failures trail the file count." Your fixture is a second record, and it does carry a defect, so that sentence stops being true the moment you add it. Rewrite it to explain the new arithmetic. A job that exists because a doc sentence lied about frontmatter arithmetic should not ship a suite comment lying about fixture arithmetic.

  **It must be a record, not a note, and this is not a style preference.** `themes` is in `RECORD_KEY_ORDER` and absent from `NOTE_KEY_ORDER`, so a file under `broken/notes/` carrying both keys is *already* defective today — it fails with `frontmatter-known-keys`, reporting that `themes` is in neither key order. That would be two defects in one file, breaking the one-defect convention. Worse, it would hide: once your key-domain check sits ahead of the budget guard as C-2 requires, it fires and returns before `check_key_order` is ever reached, so the second defect is masked by construction and a reader would never learn the fixture was malformed. Give the fixture a `memory_type`, keep every one of its keys inside `RECORD_KEY_ORDER`, and it carries exactly one defect.
- The over-budget case, which by construction has a second thing wrong with it and so does not belong in `broken/`. Build it as an inline scope in the suite, the way the migration sections already build throwaway scopes.
- Both passing cases: a journal entry with `themes` and no `tags`, and a record with `tags` and no `themes`. Do not rest either on an unmigrated `journal-v1` file — those carry no `schema` key, so the lint skips them and the assertion proves nothing.

**House constraints.**

- Only `inbox-to-memory/` and `tests/` may change (C-8). Do not touch `references/machine-contracts.md` — the docs are T-002.
- Suites gain assertions and never lose them (C-7). Baseline: all three suites exit 0 at `d4ce6d2`.
- Match the file's idiom: the `fail <diagnostic> <detail>` shape its six `frontmatter-*` siblings already use, comments explaining why rather than what.
- Before finishing, invoke the `humanizer` skill formally via the Skill tool — not from memory, which reliably misses tells — over every string a person will read that you added or changed: the failure message, any comment in `lint-scope.sh`, and any comment in `tests/inbox-to-memory-smoke.sh`, including the ones introducing your new inline scope. Then revise in place against its audit. C-9 grades the result, and the suite's comments are in scope for it.
- Environment gotcha: `grep -q` is unreliable here — an RTK hook rewrites commands, and `grep -cv` and `grep -qv` have disagreed on identical input. Prefer capturing output and testing with `test -z`/`test -n`, or counting.

**Prove your own assertions discriminate.** The previous job on this branch shipped two assertions that passed against a deliberately broken implementation. Before you finish, move your key-domain check to sit after the budget guard in a scratch copy, re-run the suite, and confirm it fails. An assertion you cannot demonstrate failing is not done. Report what you observed.

When done: set `status: needs-check` and list every changed file under `artifacts`.

## Rework diagnosis

<!-- ORCHESTRATOR appends here on each FAIL, copied verbatim from the checker's
verdict Diagnosis. Newest at the bottom, headed with the attempt it addresses
(e.g. "### sonnet r1"). Empty until the first failure. -->

## Courier comparison

<!-- ORCHESTRATOR writes this once the second opinion lands, while #34 is still
open. Read both verdicts directly and record three counts: findings only the
courier raised, findings only the checker of record raised, and the overlap.
Name the clause behind each unique finding — #34 rules on the unique-finding
rate, and a count with no clause attached can't be audited later.

Say which cited clauses were deterministic. Those cross as pre-run output for
the far side to judge, so they agree by construction and are worth nothing as
evidence either way.

A denied or blocked second opinion goes here too, with the reason. An absence
recorded is data; an absence unrecorded reads later as agreement.

This section never reaches the vendor: compose-brief.py extracts only the spec
excerpt and rework diagnosis. -->

---

## Task file: T-002.md (verbatim)

---
id: T-002
title: Make the contract state real headroom and register the new check
spec: .agent-guild/state/spec.md#for-a-coding-agent
clauses: [C-4, C-5, C-7, C-8, C-9]
executor: worker-craft
executor_model: opus
checker: checker-judgment
check_method: >-
  C-4: checker-judgment: confirm machine-contracts.md:29 no longer claims both
  key orders "fit inside the budget with room left over" and no longer claims an
  overrun "is almost always accumulated commented-out keys rather than real
  content". Then recount the key orders in lint-scope.sh at check time and
  confirm the replacement numbers match what they actually produce — do not copy
  the numbers from this task or from the constitution. C-5: checker-judgment:
  confirm a frontmatter-key-domain row exists in the "What the Lint Checks"
  table, that its "Fails when" description matches what the shipped check in
  lint-scope.sh actually does (read the check, not T-001's task file), and that
  the suite pins the row the way it already pins contradiction-fields at
  tests/inbox-to-memory-smoke.sh:521. C-7: checker-judgment: extract every
  require_*/refute_* line from each suite at d4ce6d2 and from the working copy,
  sort both, and confirm comm -23 of base against current is empty; then run all
  three suites (must exit 0). C-8: python3
  .agent-guild/scripts/check-diff-scope.py inbox-to-memory/ tests/ --ignore
  .agent-guild/ C-9: checker-judgment: read the rewritten headroom sentence, the
  new table row, and the drafted commit message at
  .agent-guild/state/commit-message.md against the humanizer skill's pattern
  list and the voice of the surrounding docs; flag rule-of-three padding,
  promotional framing, bolded inline headers, and prose that restates what the
  numbers already say. Any comment THIS task adds or rewrites in
  tests/inbox-to-memory-smoke.sh is in scope too. Title-case headings and
  occasional unspaced em dashes are correct here, not findings; spaced em dashes
  are a finding. The failure message, the lint comments, and the suite comments
  T-001 added or rewrote belong to T-001, not here. On attribution: T-001 and
  T-002 both edit the suite with no commit between them, so the diff carries no
  author boundary. Do not try to infer one. T-002's only required suite change
  is a single require_text assertion pinning the new table row, so if T-002
  added no comment, this fragment is vacuous and that is the correct outcome —
  T-001's checker has already graded everything else in that file.
status: pending
retries: 0
max_retries: 2
deps: [T-001]
escalations: []
artifacts: []
---

## Spec excerpt

Make `inbox-to-memory/references/machine-contracts.md` tell the truth about the frontmatter budget, and register the check T-001 shipped. Read the shipped check first — this documents actual behavior, not the plan.

**1. The headroom sentence, `machine-contracts.md:29`.** It currently ends:

> Both key orders below fit inside the budget with room left over, which means overrunning it is almost always accumulated commented-out keys rather than real content.

Both halves are false. Recount from `lint-scope.sh:20-21` yourself rather than trusting these numbers, but you should find: `NOTE_KEY_ORDER` holds 17 names and closes on line 19, leaving one spare line. `RECORD_KEY_ORDER` holds 19 and closes on line 21, past the budget. A record's realistic maximum is 18 keys, because `tags` and `themes` are now mutually exclusive, and 18 keys lands on exactly line 20, passing with nothing to spare. So for a fully-populated record the second claim inverts: one comment line tips it over.

Replace the sentence with what is actually true. State the real headroom for each order, so someone adding a key knows what it costs.

**2. The "What the Lint Checks" table**, starting at `machine-contracts.md:140`. Add a `frontmatter-key-domain` row with a "Fails when" description matching the shipped behavior. Read the check in `lint-scope.sh` to write it. The table's whole purpose is that "a defect whose cause changes gets a different message rather than the same generic one," so a row that misdescribes its check is worse than no row at all.

**3. Suite.** Pin the new row the way the suite already pins `contradiction-fields` at `tests/inbox-to-memory-smoke.sh:521`.

**4. The commit message.** Draft it to `.agent-guild/state/commit-message.md` and list it under `artifacts`. Not under `.agent-guild/state/notes/` — the orchestrator is barred from reading that directory and has to read this file at ship time. Focus on WHY as much as WHAT, just long enough to cover what's essential. No `Co-Authored-By` or other attribution trailer, and no hard-wrapped lines. It should close `#28`. The orchestrator commits; you write the words.

**House constraints.**

- In the deliverable, only `inbox-to-memory/` and `tests/` may change (C-8). Item 4's `.agent-guild/state/commit-message.md` is not an exception: `check-diff-scope.py` runs with `--ignore .agent-guild/`, which excludes it outright.
- Suites gain assertions and never lose them (C-7); all three exit 0 before and after.
- Do not touch `lint-scope.sh` or the fixtures. T-001 owns those and its checker has already passed them.

**Voice (C-9).** Before finishing, formally invoke the `humanizer` skill via the Skill tool rather than applying it from memory, which reliably misses tells, and revise the headroom sentence, the table row, the commit message, and any comment you add to the suite in place against its audit. House voice: a technical writer in a hurry. Title-case headings are correct. Em dashes stay unspaced and occasional, never spaced. Avoid lists of exactly three items where a fourth fits or one can drop, but never pad or trim just to dodge the pattern.

When done: set `status: needs-check` and list every changed file under `artifacts`.

## Rework diagnosis

<!-- ORCHESTRATOR appends here on each FAIL, copied verbatim from the checker's
verdict Diagnosis. Newest at the bottom, headed with the attempt it addresses
(e.g. "### opus r1"). Empty until the first failure. -->

## Courier comparison

<!-- ORCHESTRATOR writes this once the second opinion lands, while #34 is still
open. Read both verdicts directly and record three counts: findings only the
courier raised, findings only the checker of record raised, and the overlap.
Name the clause behind each unique finding — #34 rules on the unique-finding
rate, and a count with no clause attached can't be audited later.

Say which cited clauses were deterministic. Those cross as pre-run output for
the far side to judge, so they agree by construction and are worth nothing as
evidence either way.

A denied or blocked second opinion goes here too, with the reason. An absence
recorded is data; an absence unrecorded reads later as agreement.

This section never reaches the vendor: compose-brief.py extracts only the spec
excerpt and rework diagnosis. -->

---

## Evidence collected locally (verbatim command output from the repo)

== C-8 deterministic check, run verbatim ==
OK: 0 path(s) in scope
exit=0

== task routing / deps as declared ==
T-001.md: executor=worker-standard model=sonnet checker=checker-judgment deps=[]
  clauses=[C-1, C-2, C-3, C-6, C-7, C-8, C-9]
T-002.md: executor=worker-craft model=opus checker=checker-judgment deps=[T-001]
  clauses=[C-4, C-5, C-7, C-8, C-9]

== clause coverage: which task cites each C-N ==
C-1: T-001
C-2: T-001
C-3: T-001
C-4: T-002
C-5: T-002
C-6: T-001
C-7: T-001 T-002
C-8: T-001 T-002
C-9: T-001 T-002

== the suite facts the tasks depend on ==
# One defect per file, so a count is a meaningful assertion and a check that
# starts firing twice shows up as an arithmetic failure rather than a wash. The
# arithmetic is off by one because a contradiction has to point at something
# accepted: the lone record in this scope is link bait, carries no defect, and is
# the reason failures trail the file count.
broken_out="$(run_lint "$fixtures/broken")"
require_line "$broken_out" "v1 files: 0" broken
require_line "$broken_out" "v2 files: 19" broken
require_line "$broken_out" "failures: 18" broken
-- contradiction-fields pin at :521:
require_text "$contracts" "contradiction-fields"
-- journal-migrated assertion at :708:
require_line "$jrn_lint" "failures: 0" journal-migrated

== three suites at HEAD ==
inbox-to-memory-smoke.sh exit=0
file-issue-smoke.sh exit=0
handoff-smoke.sh exit=0
