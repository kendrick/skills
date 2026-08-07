---
task: DEC-audit
checker: auditor
vendor: anthropic
model: claude-opus-5
verdict: PASS
checked_at: 2026-08-06T00:00:00Z
---

## Per-task results

| task | result | severity | description | evidence |
| ---- | ------ | -------- | ----------- | -------- |
| T-001 | PASS | — | the r1 major is closed: the falsified comment is now named at the point the counts change, with the reason stated and a rewrite required; C-9 widened to "adds or rewrites" and C-6 dropped the directory rule for a `memory_type` rule that matches the live routing | `T-001.md:98`, `:46-51`, `:32-40`; `tests/inbox-to-memory-smoke.sh:151-159`; `lint-scope.sh:182-186` |
| T-002 | PASS | — | the attribution paragraph resolves the r1 minor by asserting prior coverage rather than by inferring a boundary, and its factual premise checks out | `T-002.md:34-39`; `tests/inbox-to-memory-smoke.sh:521` |

## Audit dimensions

| dimension | result | note |
| --------- | ------ | ---- |
| r1 major (falsified suite comment) | PASS | all three counts and the comment text reproduce; the rewrite is now required where the worker is already editing |
| item 2: C-9 verb | PASS | "ADDS OR REWRITES", names `:151-155`, cites `constitution.md:69` as the matched wording |
| item 3: C-6 directory rule | PASS | judges by `memory_type`, which is what `lint-scope.sh:182` actually routes on; no longer fails an artifact C-6 permits |
| item 4: T-002 attribution | PASS | premise verified: one `require_text` is T-002's whole required suite change |
| item 5: `#for-a-coding-agent` | PASS | resolves to `spec.md:82` in both task files |
| new problems from the fixes | PASS | two minors below, neither reachable by a worker following its brief |
| spec coverage | PASS | six Done-when criteria plus the Verify-with line, all mapped |
| clause citation | PASS | union of both `clauses` lists is C-1..C-9; every id appears in its own task's `check_method` |
| check consistency | PASS with one minor | C-6's fragment stretches "arithmetic" to cover the comment explaining it |
| routing conformance | PASS | unchanged and still correct |
| deps DAG | PASS | `T-001.deps: []`, `T-002.deps: [T-001]`; one edge, acyclic, referent exists |

## The r1 major: closed

Every number and quote in the new paragraph at `T-001.md:98` reproduces against the tree.

`tests/inbox-to-memory-smoke.sh:158-159` reads `v2 files: 19` and `failures: 18`, and linting the fixture scope directly returns the same pair. The comment at `:151-155` carries the sentence the task quotes, verbatim through "is the reason failures trail the file count." The scope holds 18 notes and one record, and that record is refuted as a failure at `:186`, so the gap of one is exactly what the comment says it is.

Adding a failing record under `_memory/decisions/` moves the pair to 20 and 19. The gap stays one, so the comment's *mechanism* survives; what dies is "the lone record in this scope," which stops naming anything once a second record lands. The task states this precisely rather than approximately, and "Update both rather than deleting either" closes the C-7 escape hatch of solving the arithmetic by deleting the assertion.

Two things make the fix stick where the r1 version leaked. It sits inside the fixture bullet, so the worker meets it while editing the counts rather than in a separate instruction it might satisfy independently. And C-6's `check_method` at `T-001.md:37-40` now carries the checker-side twin, which matters because `compose-brief.py` passes the worker the spec excerpt and never the `check_method` — the two halves have to exist separately or one audience misses it.

## Ruling on the r0/r1 standing correction: `v2 files: 19`

Covered, and I am closing it.

`T-001.md:98` now names `v2 files: 19` explicitly, with its new value, alongside `failures: 18` → 19. That was the whole ask: the worker previously had only `failures: N` to go on and could have left `:158` stale.

The checker-side fragment at `T-001.md:28` still says "the broken scope's failures: N arithmetic was updated rather than left stale," naming one count. I am not holding the round open for it. A stale `v2 files: 19` turns `require_line` red at `:158`, which fails C-7's "all three suites exit 0" before any judgment is applied — this is the one count in the pair that cannot ship wrong. The worker-side risk was the real risk, and it is closed.

## Item 3: the C-6 rule now matches the code

`lint-scope.sh:182` routes on `grep -qx 'memory_type'` against the frontmatter keys, with no reference to the file's path. So "judge by the `memory_type` key, not by the directory" is a restatement of the implementation, not a policy choice, and the r1 defect — a `check_method` that could fail an artifact its clause permits — is gone.

The replacement rule is also correct in the direction it does fail. `NOTE_KEY_ORDER` (`:20`) holds 17 names and `themes` is not among them; `RECORD_KEY_ORDER` (`:21`) holds 19 and does. A fixture with no `memory_type` carrying both keys therefore trips `frontmatter-known-keys` as well as the new check, and once the key-domain check sits ahead of the budget guard per C-2 it returns first and hides the second defect. Failing such a fixture is what C-6's binding text ("carrying that one defect and no other") requires.

## Item 4: the attribution premise holds

`T-002.md:34-39` resolves the r1 minor the opposite way I suggested — it licenses a vacuous fragment instead of telling the checker to over-read — and the resolution is sound, because it does not rest on attribution at all. It rests on prior coverage: T-001's checker runs before T-002's worker exists (`deps: [T-001]`), and T-001's C-9 fragment grades everything added or rewritten in the suite at that point. Anything the T-002 checker cannot attribute has already been graded.

The factual premise checks out. `tests/inbox-to-memory-smoke.sh:521` is a single `require_text "$contracts" "contradiction-fields"`, and T-002's brief item 3 asks for that one assertion and nothing else. So "if T-002 added no comment, this fragment is vacuous" describes the expected case, not a loophole.

## Minors, not failures

- **C-6's fragment stretches its clause by one word.** C-6's text requires "the suite's existing `failures:` arithmetic ... updated to match rather than left stale." The fragment extends that to the comment explaining the arithmetic. I read this as consistent: the comment is part of what goes stale, and it is the only clause that can compel the rewrite (C-9 is vacuous when a comment is left untouched, which is the exact gap r1 found). Recording it because a worker could, in principle, dispute a C-6 FAIL by arguing the numbers were updated. The brief tells the worker to rewrite it, so no artifact built to instruction reaches that edge.
- **T-002's own C-9 scope says "adds," not "adds or rewrites."** `T-002.md:30-31` covers "any comment THIS task adds"; its fence at `:34` correctly uses "added or rewrote." If T-002 rewrote an existing suite comment, T-001's fence would exclude it and T-002's scope would not reach it. This is the same shape as the r1 major, but it is not the same severity: T-001 was *required* to touch a comment that its brief made false, whereas nothing directs T-002 at any existing comment. One word if it is ever revised.
- **`T-001.md:100` still frames the record/note distinction by directory** ("a file under `broken/notes/` carrying both keys is *already* defective today"), which is true of note-shaped files and over-general as stated, now that the `check_method` frames it by `memory_type`. It is worker-facing prose rather than a grading rule, so it cannot produce a dispute, and its next sentence supplies the operative rule: give the fixture a `memory_type` and keep every key inside `RECORD_KEY_ORDER`.

## Carried forward deliberately

**C-6's failing example at `constitution.md:54` is still known-stale**, on the same reasoning r1 recorded: it names `frontmatter-key-order` where the live hazard is `frontmatter-known-keys`, and "fails two checks at once" stops being possible once C-2's precedence lands. The condition r1 attached still holds — the masking correction lives in `T-001.md:29-36` and has gotten stronger this round, not weaker, since the `memory_type` rewrite spells out the second diagnostic by name. If that passage is ever trimmed, the example becomes load-bearing and a CON round is owed.

## Re-verified rather than carried forward

- **C-2's scratch-copy mutation** survives all five edits. `T-001.md:13-20` still runs the full sequence: assert against a file closing past line 20, mutate a scratch copy so the check sits after the budget guard, re-run, confirm it now fails, restore or copy before returning, with the reason attached. The worker-side twin moved to `:112` as the file grew and is intact, which is the redundancy that matters.
- **The C-6/C-2 fixture separation** is undisturbed. `T-001.md:94` still opens "Two separate cases, and they cannot share a file," and item 1's paragraph landed inside the first bullet at `:98` without touching the second at `:101`.
- **Line references.** `lint-scope.sh:20-21` key orders, budget guard and `return` at `:156-159`, routing at `:182-186`, `check_key_order` at `:117`, `check_frontmatter` at `:146`; `tests/inbox-to-memory-smoke.sh:521` and `:708`; `constitution.md:69` reads "adds or rewrites"; `spec.md:82` is `## For a Coding Agent`. All reproduce.
- **Baseline.** `git diff d4ce6d2 -- inbox-to-memory/ tests/` is empty. All three suites exit 0. `check-diff-scope.py inbox-to-memory/ tests/ --ignore .agent-guild/` returns `OK: 0 path(s) in scope`.
- **Spec coverage.** `spec.md:88` → T-001 (C-1, C-2); `:89` → T-001 (C-3); `:90` → T-002 (C-5); `:91` → T-002 (C-4); `:92` → T-001 (C-6); `:93` → both (C-7); the Verify-with line at `:84` → C-7. The out-of-scope note at `:94` maps to the constitution's non-goals and is echoed at `T-001.md:68`. Nothing unmapped, and neither task claims scope the spec does not grant.
- **Routing.** T-001 is clear-spec implementation judged on correctness → worker-standard/sonnet. T-002 is prose and taste → worker-craft/opus. Both check with checker-judgment, which every cited clause but C-8 names in its own check text, and which `constitution.md:15` requires for anything evidenced by the suite. C-8's script rides along with the judgment checker because a task carries one `checker` field.
- **deps.** The shared write to `tests/inbox-to-memory-smoke.sh`, C-7's `comm -23` comparison, C-5's data dependency on the shipped check, and the by-author C-9 fences each force the single edge independently.
