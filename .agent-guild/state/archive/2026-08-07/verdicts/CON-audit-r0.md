---
task: CON-audit
checker: auditor
vendor: anthropic
model: claude-opus-5
verdict: FAIL
checked_at: 2026-08-06T00:00:00Z
---

## Per-clause results

| clause | result | severity | description | evidence |
| ------ | ------ | -------- | ----------- | -------- |
| C-1 | FAIL | blocker | check forbids `frontmatter-budget` on the issue's 21-line reproduction; C-2 permits it on the same file | constitution.md:21 vs :26 |
| C-2 | FAIL | blocker | grants latitude C-1 revokes; check prong 2 also presumes the new check lives inside `check_frontmatter` | constitution.md:26-27 |
| C-3 | PASS | blocker | check method names the vacuity trap and is applicable; failing example points at a fixture the lint skips (see notes) | tests/fixtures/inbox-to-memory/journal-v1/entries/2025-12-09-freeze-dates-need-a-writer-6SMjpofI2b.md |
| C-4 | PASS | blocker | arithmetic reproduced: note order 17 keys closing on 19, record order 19 keys closing on 21, 18 keys closing on 20 | lint-scope.sh:20-21; reproduction run |
| C-5 | FAIL | blocker | clause text asserts five `frontmatter-*` siblings; six exist | machine-contracts.md:146-151; lint-scope.sh:133,142,152,157,165,176 |
| C-6 | PASS | major | fixture convention and the `failures:` assertion both exist and are locatable | tests/inbox-to-memory-smoke.sh:159 |
| C-7 | PASS | blocker | `comm -23` method is runnable; base commit and all three suite paths exist | git d4ce6d2; tests/*.sh |
| C-8 | PASS | blocker | invocation parses and runs clean against the working tree | `check-diff-scope.py inbox-to-memory/ tests/ --ignore .agent-guild/` → `OK: 0 path(s) in scope` |
| C-9 | PASS | major | rubric is applicable with named tells and explicit house carve-outs; skill is installed | ~/.claude/skills/humanizer |

## Diagnosis

- **C-1 / C-2** (blocker): the two clauses give opposite answers about the same artifact. C-1's check requires that on the issue's reproduction the lint "does not report `frontmatter-budget` for that file" (constitution.md:21). That reproduction is a record whose block closes on line 21 — I ran it and confirmed today's output is exactly one `frontmatter-budget` failure at line 21. C-2 covers the identical file and says "whether it also reports `frontmatter-budget` is the implementer's call" (constitution.md:26). An implementation that reports both diagnostics satisfies C-2 and fails C-1, and both are blockers, so a worker cannot read the constitution and know what to build. The spec breaks the tie in C-1's favor — its done-when reads "fails a named key-domain check **instead of** `frontmatter-budget`" (spec.md:88) — so the drifted text is C-2's grant of latitude. Fix in one place: either drop C-2's "implementer's call" sentence and require the budget failure be suppressed when key-domain fires, or drop C-1's "and does not report `frontmatter-budget` for that file" and let both surface. One edit clears both rows.

- **C-2** (blocker): second, separable defect in the check method. Prong 2 reads "read `check_frontmatter` to confirm no early `return` on the budget path can skip the key checks." That presumes the new check ships inside `check_frontmatter`, which the clause text never requires. An implementation that puts key-domain in its own function called from the per-file loop, before `check_frontmatter` runs, is correct and reachable, yet prong 2 has no subject in that file — a checker can read it as vacuously satisfied, or fail a good implementation for the check's absence there. Prong 1 ("confirm the suite asserts `frontmatter-key-domain` against a file whose block closes past line 20") is the load-bearing half and is sound: it is behavioral, and an implementation placed after the budget `return` cannot make that assertion green. Reword prong 2 to bind to behavior rather than location, e.g. "run the issue's reproduction against the shipped lint and confirm `frontmatter-key-domain` appears; then read the control path the check actually sits on and confirm nothing returns before it on the budget-overrun path." Reachability itself is confirmed as a real hazard: `check_frontmatter` does `return` immediately after `fail frontmatter-budget` (lint-scope.sh:156-159), so a 21-line file never reaches the key checks today. Nit while you are in there: the preamble cites that guard as `lint-scope.sh:157-160`; the guard runs 156-159 and line 160 is blank.

- **C-5** (blocker): the clause text says the new row lands "alongside its five `frontmatter-*` siblings." There are six. The "What the Lint Checks" table carries `frontmatter-fences`, `frontmatter-parses`, `frontmatter-budget`, `frontmatter-single-line`, `frontmatter-known-keys`, and `frontmatter-key-order` (machine-contracts.md:146-151), and `lint-scope.sh` has six matching `fail frontmatter-*` call sites (:133, :142, :152, :157, :165, :176). The same miscount appears in the preamble at constitution.md:8. This does not change what C-5 requires, but a checker under instruction to re-derive every claim will hit it, and the constitution is the document that teaches the standard. Change both to six.

### Corrections required, not clause failures

These are errors in illustrative material rather than in the normative text or the check method, so the clauses stand. Fix them in the same revision.

- **C-3**, failing example: it predicts that "the existing journal fixture with `themes` and no `tags` starts failing." That fixture is `tests/fixtures/inbox-to-memory/journal-v1/entries/2025-12-09-freeze-dates-need-a-writer-6SMjpofI2b.md`, and it carries no `schema` key, so it is v1 and the lint skips it entirely — it is the exact vacuity trap the clause's own check method warns about, and it cannot start failing under any implementation. The assertion a `memory_type`-based check would actually break is `require_line "$jrn_lint" "failures: 0" journal-migrated` at tests/inbox-to-memory-smoke.sh:708, which lints the migrated copy. Point the example there so the checker looks where the breakage lands. The mechanism the example describes is right; only its locator is wrong.

- **C-5**, failing example: it calls the table "the one document listing every diagnostic." It isn't. The lint emits seventeen distinct diagnostics; the table documents eight. Absent from it: `anchor-form`, `decision-fields`, `derived-counts`, `link-broken`, `open-question-fields`, `open-question-resolution`, `open-question-slug`, `tension-deferred-pairing`, `tension-fields`. The requirement to register the new row still holds — `frontmatter-*` checks are all present there, so a missing sixth-plus-one row would be a conspicuous gap — but rest the rationale on that rather than on a completeness the table does not have.

- **C-6 / C-2**, unflagged tension: C-6 requires the new `broken/` fixture carry one defect and no other, while C-2 requires a suite assertion against a block closing past line 20. A file that overruns the budget and carries both keys has two defects by construction, so those two clauses cannot be satisfied by the same file under `broken/`. Resolvable as written — the >20-line case can be an inline temp scope, which is how the suite already handles similar cases at :207 and :1075 — but saying so in C-2 or C-6 would stop a worker from discovering the conflict the expensive way.

- **C-9**, unverifiable half: the clause text requires prose that "goes through the `humanizer` skill's audit-and-revise loop." Nothing in the artifact records whether a skill was invoked, so that half is not checkable. The check method sensibly judges the output instead, which is why the clause passes. Consider trimming the text to match what the check can actually see.

## Verified without finding

Reproduced against the working tree rather than accepted from the preamble:

- `NOTE_KEY_ORDER` holds 17 names, `RECORD_KEY_ORDER` holds 19 (lint-scope.sh:20-21). Built the spec's heredoc and ran the lint: the 19-key record reports `frontmatter-budget: closing --- on line 21` and nothing about `tags` or `themes`, matching spec.md:70 exactly. Deleting `themes` leaves 18 keys, closes the fence on line 20, and reports `failures: 0`. So C-4's "one spare line for notes, none for records, realistic maximum of 18 keys landing on exactly line 20" is correct.
- Order selection routes on `memory_type` (lint-scope.sh:182-186), as the preamble states.
- machine-contracts.md:29 is the sentence carrying both false claims C-4 names.
- tests/inbox-to-memory-smoke.sh:521 is `require_text "$contracts" "contradiction-fields"`, and that string occurs exactly once in machine-contracts.md — line 153, the table row — so C-5's cited precedent does pin a row.
- tests/inbox-to-memory-smoke.sh:159 is `require_line "$broken_out" "failures: 18" broken`, and `broken/notes/` holds 18 fixtures. C-6's "existing `failures:` arithmetic" is real and locatable.
- Commit d4ce6d2 exists on this branch, and all three suite paths C-7 names exist.
- C-8's invocation runs: `OK: 0 path(s) in scope`, exit 0.
- No protected-content manifest is claimed, and none is needed — nothing here ships verbatim author words.
