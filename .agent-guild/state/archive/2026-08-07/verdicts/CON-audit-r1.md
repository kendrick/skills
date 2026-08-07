---
task: CON-audit
checker: auditor
vendor: anthropic
model: claude-opus-5
verdict: PASS
checked_at: 2026-08-06T00:00:00Z
---

## Per-clause results

| clause | result | severity | description | evidence |
| ------ | ------ | -------- | ----------- | -------- |
| C-1 | PASS | blocker | check names a concrete reproduction and a falsifiable output condition; no longer contradicts C-2 | constitution.md:20-23; spec.md:88 |
| C-2 | PASS | blocker | precedence now aligned with C-1 and the spec; prong 2 is a behavioral mutation test that binds to reachability, not to file location | constitution.md:26-29; lint-scope.sh:156-159 |
| C-3 | PASS | blocker | failing example now points at an assertion that can actually break; vacuity trap named and correctly excluded | tests/inbox-to-memory-smoke.sh:708; migration run reproduced |
| C-4 | PASS | blocker | arithmetic re-derived independently: note order 17 keys closing line 19, record order 19 closing line 21, 18 closing exactly on 20 | lint-scope.sh:20-21; machine-contracts.md:29 |
| C-5 | PASS | blocker | sibling count corrected to six and independently recounted; failing example no longer rests on a completeness the table lacks | machine-contracts.md:146-151; lint-scope.sh:133,142,152,157,165,176 |
| C-6 | PASS | major | one-defect convention and the `failures:` arithmetic both real; `note:` field resolves the C-2 tension without over-constraining the implementer | tests/fixtures/inbox-to-memory/broken/notes (18 files); tests/inbox-to-memory-smoke.sh:159 |
| C-7 | PASS | blocker | `comm -23` method runnable; base commit and all three suite paths exist; C-2's new precedence rule breaks no existing fixture | git d4ce6d2; tests/*.sh; no fixture carries both keys |
| C-8 | PASS | blocker | invocation parses and runs clean against the working tree | `check-diff-scope.py inbox-to-memory/ tests/ --ignore .agent-guild/` → `OK: 0 path(s) in scope`, exit 0 |
| C-9 | PASS | major | rubric applicable, tells named, house carve-outs explicit | ~/.claude/skills/humanizer |

## Corrections required, not clause failures

The document is sound as it stands. These are operational sharp edges in illustrative or procedural material, not defects in normative text or in what a check tests. Fix them when convenient; none blocks dispatch.

- **C-2**, mutation hygiene: the check method instructs the checker to "move the key-domain check to sit after the existing budget guard, re-run the suite." That is the right test, but it has the checker editing the deliverable, and the clause never says to work on a scratch copy or restore the file afterward. A checker that mutates `lint-scope.sh` in place and returns without reverting leaves a dirty tree that the next checker — including C-8's diff-scope run — will attribute to the worker. One clause: "on a scratch copy of the tree, or restore the file before returning."

- **C-6**, the `note:` field: acceptable, and better here than in `text:`. `compose-brief.py` extracts a clause block by regex from its `### C-N:` heading to the next heading (`compose-brief.py:97-108`), so the note travels verbatim into the worker brief rather than being dropped — the mechanical concern doesn't apply. Keeping it out of `text:` is the right call substantively too: promoted to normative text it would forbid an equally valid implementation that puts the >20-line case in its own fixture directory outside `broken/`. One wording nit: "C-2's case belongs in an inline scope" reads imperative for a non-normative field. A checker must not fail an implementation that sites the C-2 case elsewhere, since no clause requires it. "The suite's existing inline-scope pattern is the natural home" would carry the guidance without the pull toward enforcement.

- **C-9**, unverifiable half (carried from r0, unchanged): the text still requires prose that "goes through the `humanizer` skill's audit-and-revise loop." Nothing in the artifact records whether a skill was invoked, so that half remains unobservable. The check method judges output only, which is why the clause passes. Trimming the text to match what the check can see would close the gap.

## Verified without finding

Every factual and arithmetic claim below was re-derived against the working tree rather than accepted from the constitution or from r0.

**The six corrections claimed in the dispatch, each confirmed landed:**

1. **C-1/C-2 contradiction resolved toward C-1.** C-2 now reads "reports `frontmatter-key-domain` and does not report `frontmatter-budget`, per C-1" (constitution.md:26). The "implementer's call" grant is gone. This matches the spec's done-when, "fails a named key-domain check **instead of** `frontmatter-budget`" (spec.md:88). The two clauses now give the same answer for the same file.
2. **C-2's second prong rebound to behavior.** It no longer presumes the check lives inside `check_frontmatter`. I traced the mutation both ways: an implementation placed before the budget guard with an early return survives normal execution and dies under the mutation; an implementation in its own function called ahead of `check_frontmatter` also survives normally, and the instruction "move it to sit after the existing budget guard" is still well-defined against it. The clause is also *satisfiable* — suppressing `frontmatter-budget` for a co-presence file is achievable in bash by ordering plus `return`, matching the house pattern where every `fail` in `check_frontmatter` returns.
3. **Six siblings, recounted independently.** Six `frontmatter-*` rows in the table (machine-contracts.md:146-151: fences, parses, budget, single-line, known-keys, key-order) and six `fail frontmatter-*` sites in the script (lint-scope.sh:133, 142, 152, 157, 165, 176). `frontmatter-key-domain` is the seventh, alongside six. Corrected in both C-5 and the preamble at :8.
4. **C-3's failing example now points at a live assertion.** `tests/inbox-to-memory-smoke.sh:708` is exactly `require_line "$jrn_lint" "failures: 0" journal-migrated`. I ran the migrator over `journal-v1` and linted the result: the entry gains `schema: 2`, carries `themes` and `memory_type: Journal` with no `tags`, and lints `failures: 0`. So the assertion is non-vacuous and a `memory_type`-based check would break it. The unmigrated fixture does carry no `schema` key, so the clause's stated reason for excluding it holds.
5. **C-5's failing example** no longer claims the table lists every diagnostic; it rests on the reader's path after a failure instead.
6. **The `:156-159` citation** is correct in both places (constitution.md:13 and :29). Counted from the file: the budget guard opens at 156, fails at 157, returns at 158, closes at 159; line 160 is blank. No `157-160` remains anywhere in the document.

**No new problem introduced by any of the above.** Specifically checked:

- **C-2's precedence rule vs. C-7.** The only existing budget fixture is `broken/notes/2026-03-02-frontmatter-budget-kFtFA-Xh5P.md`, which carries `tags` and no `themes`. No fixture anywhere under `tests/fixtures/inbox-to-memory/` carries both keys (`grep -l '^tags:' | xargs grep -l '^themes:'` returns nothing). Suppressing `frontmatter-budget` when key-domain fires therefore cannot silence an existing assertion.
- **C-2's precedence vs. C-5's "description matching its behavior."** The `frontmatter-budget` row still reads "The closing `---` lands past line 20," which after this change is a trigger condition rather than a guarantee. That is not a new inaccuracy: `check_frontmatter` has always returned early on fences, so the table has always described triggers rather than precedence among diagnostics. No clause needs to change.
- **C-6 vs. C-7.** C-6 requires the broken scope's `failures:` arithmetic be updated; C-7 forbids deletion but its own failing example distinguishes "deleted rather than updated." Consistent.
- **C-8 vs. C-4/C-5/C-6.** All paths those clauses touch (`inbox-to-memory/references/`, `tests/fixtures/`) fall inside the allowed scope.

**Spec coverage — all six done-when criteria map to a clause:**

| spec.md done-when | clause |
| ----------------- | ------ |
| :88 named key-domain check instead of budget, message names both keys | C-1, with C-2 covering reachability on the file that motivated it |
| :89 journal with `themes` only, and record with `tags` only, still pass | C-3 |
| :90 new check registered in the "What the Lint Checks" table | C-5 |
| :91 `machine-contracts.md:29` states real headroom, drops the comments claim | C-4 |
| :92 suite gains a one-defect fixture asserting the named failure | C-6 |
| :93 all three suites exit 0 | C-7 (its check runs all three) |

The spec's out-of-scope paragraph (:94) is reproduced in the constitution's non-goals, with two additions the user settled before drafting (domain assignment declined; record order not reconciled to 18).

**Re-derived from the tree, not carried from r0:**

- `NOTE_KEY_ORDER` holds 17 names, `RECORD_KEY_ORDER` holds 19 (lint-scope.sh:20-21). 17 keys plus opening and closing fences closes on line 19; 19 keys closes on 21; dropping `themes` leaves 18, closing on exactly 20. C-4's numbers are correct.
- machine-contracts.md:29 is the sentence carrying both false claims C-4 names, verbatim: "fit inside the budget with room left over" and "almost always accumulated commented-out keys rather than real content."
- tests/inbox-to-memory-smoke.sh:521 is `require_text "$contracts" "contradiction-fields"` — a real precedent for pinning a table row.
- tests/inbox-to-memory-smoke.sh:159 is `require_line "$broken_out" "failures: 18" broken`, and `broken/notes/` holds 18 fixtures.
- Commit d4ce6d2 exists (`git cat-file -t` → commit) and all three suite paths named in C-7 exist.
- C-8's invocation runs clean: `OK: 0 path(s) in scope`, exit 0.
- No protected-content manifest is claimed, and none is needed — nothing in this job ships verbatim author words.
