# Second-opinion audit brief: CON-audit r1 (kendrick/skills#28)

You are `checker-courier` relaying a constitution audit for a second opinion. Judge ONLY the material inlined below. You cannot read any repository, run any command, or see anything outside this prompt. Do not assume any command was or could be run on your side; judge script-based checks against the "Evidence collected locally" section.

## What you are judging

A guild "constitution": the falsifiable standard a build job is measured against. The job fixes two defects in a markdown-notes skill's frontmatter linter. Apply this rubric to every clause C-1 through C-9:

1. It names a concrete check method: a script invocation with arguments, or a judgment rubric a checker could actually apply. A clause whose check is vague or absent fails.
2. It is falsifiable: you can state a specific artifact that would violate it. If you cannot describe a failing example, the clause is unfalsifiable and fails.
3. No two clauses contradict each other.
4. Coverage: does any requirement in the spec's "Done when" list lack a governing clause?

Two premises settled with the user before drafting. Do NOT fail a clause for either:
- The check is mutual exclusion only. A file carrying BOTH `tags` and `themes` fails. A record with only `tags`, or a journal entry with only `themes`, passes. The stricter rule (rejecting `themes` on a non-Journal) was deliberately declined and is listed as a non-goal.
- The diagnostic is named `frontmatter-key-domain`.

Background you need: the linter enforces a 20-line budget on a file's YAML frontmatter. Two key orders exist; a file carrying `memory_type` is checked against the record order, everything else against the note order. Journal entries carry `memory_type: Journal`, which is why one order legitimately holds both `tags` and `themes`. The reported bug is that a record carrying both keys is 21 lines, so it fails the budget check, and the budget check returns early — meaning the real defect is never named and is currently unreachable.

## Verdict you must produce

Emit ONLY a JSON object with exactly these nine fields:
- "task_id": "CON-audit"
- "checker": "checker-courier"
- "vendor": "openai"
- "model": "gpt-5.6-terra"
- "verdict": "pass" | "fail" | "blocked"
- "summary": one paragraph
- "findings": array of {"clause_id", "severity", "description", "evidence"} — REQUIRED non-empty if verdict is "fail"; each finding's evidence must cite the inlined material. May be empty on "pass". Advisory notes that do not fail a clause belong in "summary", not "findings".
- "duration_ms": null
- "cost_usd": null

---

## The constitution under audit (verbatim)

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
- **text**: Every human-facing string this job adds or rewrites — the `machine-contracts.md` headroom sentence, the new table row, the failure message itself, any new comment in `lint-scope.sh`, and the commit message — goes through the `humanizer` skill's audit-and-revise loop and carries the house voice: a technical writer in a hurry, comments explaining why rather than what.
- **check**: checker-judgment: read the added prose against the `humanizer` skill's pattern list and the surrounding files' voice; flag rule-of-three padding, promotional framing, bolded inline headers, and comments that restate the code. Title-case headings and occasional unspaced em dashes are correct here, not findings. Spaced em dashes are a finding.
- **severity**: major
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

## The spec it must cover (verbatim)

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

## Evidence collected locally (verbatim command output from the repo)

== C-8 deterministic check, run verbatim ==
OK: 0 path(s) in scope
exit=0

== key order arithmetic (recounted from the script) ==
NOTE_KEY_ORDER=17 names -> closes line 19  (budget 20, so 1 spare)
RECORD_KEY_ORDER=19 names -> closes line 21  (past budget by 1)
record minus one of tags/themes = 18 names -> closes line 20

== the false claim, machine-contracts.md:29 ==
**The block fits in the first 20 lines of the file.** This is the number that makes a header read a contract: an agent reading 20 lines is guaranteed to have the entire frontmatter, so stage three of the funnel can stop there without ever wondering whether it truncated something. Both key orders below fit inside the budget with room left over, which means overrunning it is almost always accumulated commented-out keys rather than real content.

== the six frontmatter-* siblings ==
fail frontmatter-budget
fail frontmatter-fences
fail frontmatter-key-order
fail frontmatter-known-keys
fail frontmatter-parses
fail frontmatter-single-line

== the early return that makes the bug ==
  if [[ "$end" -gt "$FRONTMATTER_LINE_BUDGET" ]]; then
    fail frontmatter-budget "closing --- on line $end, past the $FRONTMATTER_LINE_BUDGET-line budget"
    return
  fi

== bug reproduced: both keys present ==
/var/folders/2b/m3q305ss1tb55qfhrv6v0n3m0000gn/T/tmp.1JsxO5ERAr/_inbox
/var/folders/2b/m3q305ss1tb55qfhrv6v0n3m0000gn/T/tmp.1JsxO5ERAr/_memory
/var/folders/2b/m3q305ss1tb55qfhrv6v0n3m0000gn/T/tmp.1JsxO5ERAr/_memory/decisions
FAIL /var/folders/2b/m3q305ss1tb55qfhrv6v0n3m0000gn/T/tmp.1JsxO5ERAr/_memory/decisions/full-record-AbCdEfGhIj.md: frontmatter-budget: closing --- on line 21, past the 20-line budget
failures: 1
-- themes removed:
failures: 0

== no existing fixture carries both keys (so C-2's suppression breaks nothing) ==
(no BOTH lines = none)

== three suites at HEAD ==
inbox-to-memory-smoke.sh exit=0
file-issue-smoke.sh exit=0
handoff-smoke.sh exit=0
