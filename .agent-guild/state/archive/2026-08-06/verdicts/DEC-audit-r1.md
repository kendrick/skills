---
task: DEC-audit
checker: auditor
vendor: anthropic
model: claude-opus-5
verdict: FAIL
checked_at: 2026-08-06T22:21:56Z
---

Round 1 audit of the decomposition at `.agent-guild/state/tasks/` (T-001 through T-004)
against `.agent-guild/state/spec.md` and `.agent-guild/state/constitution.md`. Prior round:
`DEC-audit-r0.md` (FAIL, one blocker plus three advisories).

The four reported changes were verified against the task files rather than taken on faith,
and all four landed as described. The r0 blocker is genuinely fixed. This round fails on
`T-004`, at major severity, on two defects in how C-16 is wired — one of them introduced by
change 4 itself. Every line-number and file-existence claim below was re-derived from the
working tree at `eac74fe`.

## Per-task results

| task | result | severity | description | evidence |
| ---- | ------ | -------- | ----------- | -------- |
| T-001 | PASS | — | Cites C-1, C-2 (seam only, honestly labeled), C-12, C-13. Change 2 landed in both places: the `check_method` now reads "both old-only notes already carry a `## Raw Content` heading, so check the content below it, not the heading's presence," and excerpt step 1 says the worker is "replacing that placeholder's content, not adding the section." The premise is true. No new problem. | both fixtures carry the heading: `old-only/notes/2025-11-18-…-P5spzLt4Bz.md:41`, `old-only/notes/2025-11-04-…-3iMu15QJ_x.md:45` |
| T-002 | PASS | — | The r0 blocker is fixed. C-3's `check_method` now leads with the clause's own check — read each note's emitted extract beside its written `summary`, any unsupported claim fails — and puts the suite's fixture summaries explicitly in scope, which is the one place summaries exist at check time. The mechanical conjuncts follow rather than replace it. Excerpt bullet rewritten to match, splitting judgment from mechanical, quoting C-3's failing example as the shape to avoid, and forbidding a script-side traceability check. Change 3 landed at the C-1 bullet. The other eight check_methods are unchanged and still consistent with their clauses. | `T-002.md:16-23` (C-3 check_method), `:59-65` (excerpt bullet); `extract_body` confirmed at `migrate-scope.sh:123` as cited; `NOTE_KEY_ORDER` holds 17 names, C-15 script exits 0 (17+2=19 ≤ 20) |
| T-003 | PASS | — | Unchanged from r0 and still sound. Cites C-6 through C-10 plus C-12, C-13; each check_method restates the constitution's check and keeps the two folded findings (reported failure count, committed-deletion case) and the stub-lint abort seam. All cited anchors re-verified. | `verify-migration.sh` still absent from `inbox-to-memory/scripts/` (only `collapse-vtt.sh`, `lint-scope.sh`, `migrate-scope.sh`); throwaway-repo harness confirmed at `tests/inbox-to-memory-smoke.sh:566-575` |
| T-004 | **FAIL** | major | Change 4 landed — excerpt item 5 has the worker draft the message and list it under `artifacts`, and the C-16 `check_method` names the file — so the commit-message fragment now crosses a checker. Two defects remain, both C-16 plumbing. **(a)** The draft is written to `.agent-guild/state/notes/`, a directory the orchestrator is contractually forbidden to read, while the task hands the message to the orchestrator to commit. **(b)** C-16's `check_method` narrows the clause's "script header comments" fragment to comments "touched here," leaving every comment T-002 and T-003 add with no C-16 verifier anywhere in the decomposition. Detail in Diagnosis. | `T-004.md:15-21` (C-16 check_method), `:42` (excerpt item 5), `:44` (voice paragraph); `.agent-guild/CLAUDE.md` state map: "Workers write notes; you never read them"; T-002 `clauses:` and T-003 `clauses:` contain no C-16 |

## Coverage

Every spec section and acceptance criterion still maps to at least one task, and every clause
C-1 through C-16 is cited. No uncovered spec requirement, no orphan clause. Unchanged from r0
except the C-16 row, which change 4 moved from a carve-out to an owned artifact.

| spec acceptance criterion | clause | task |
| ------------------------- | ------ | ---- |
| Summary and entities derive only from extracted sections | C-1, C-2, C-3 | T-001 (seam), T-002 |
| Tier 2 approval separate from Tier 1, per-file or batched | C-4 | T-002 |
| Rejecting a Tier 2 proposal leaves Tier 1 intact | C-5 | T-002 |
| Verification runs the full lint over every migrated file | C-6 | T-003 |
| Every link resolving before resolves after | C-7 | T-003 |
| Rename count asserted at zero via git | C-8 | T-003 |
| Failures reported, never auto-repaired | C-9 | T-003 |
| The record paragraph is emitted, never written | C-10 | T-003 (behavior), T-004 (prose) |
| — (constitution-only) second-run no-op incl. Tier 2 | C-11 | T-002 |
| — (constitution-only) assertions never lost | C-12 | all four |
| — (constitution-only) diff stays in scope | C-13 | all four |
| — (constitution-only) docs describe what ships | C-14 | T-004 |
| — (constitution-only) Tier 2 cannot reach the budget | C-15 | T-002 |
| — (constitution-only) prose reads like a person wrote it | C-16 | T-004 — commit message now covered, script comments partially uncovered (Diagnosis b) |

## Routing

Unchanged from r0 and still conformant.

- T-001 → `worker-bulk`/haiku for a mechanical fixture edit, with `checker-judgment` because
  every clause it cites but C-13 is rubric-checked, and no fixed script can decide "this
  worker-chosen name appears nowhere above the fence." The routing table's operative rule is
  the clause's check type, and it points at judgment here.
- T-002, T-003 → `worker-standard`/sonnet, clear-spec bash judged on correctness. Correct.
- T-004 → `worker-craft`/opus with `checker-judgment`. Correct, and the only pairing the
  table permits for C-16.
- All four carry the two deterministic clauses (C-13, C-15) under a judgment checker. A task
  names one checker; judgment can run a script, deterministic cannot apply a rubric, so the
  mixed case resolves to judgment. Both deterministic checks were run here at `eac74fe` and
  exit 0, so a checker inherits a clean baseline.

## Dependencies

DAG intact: T-001 → T-002 → T-003, with T-004 depending on T-002 and T-003. Every referenced
id exists as a file. No cycles, no dangling references. The T-002 → T-003 edge remains
coordination over a shared test file rather than a functional dependency, as recorded in r0.

## Diagnosis

- **T-004 / C-16(a)** (major): the drafted commit message lands where the agent who commits
  may not read it.

  Excerpt item 5 sends the draft to `.agent-guild/state/notes/T-004-commit-message.txt` and
  closes with "The orchestrator commits at ship time; you write the words." The guild's own
  state map makes that handoff illegal: "`.agent-guild/state/notes/` — the message bus.
  Workers write notes; you never read them (they're the worker's self-report, off-limits to
  keep verification honest)." The rule is categorical about the directory, not about the kind
  of file in it.

  So the fix closes the verification half of r0's Advisory 1 and leaves the delivery half
  broken. At ship time the orchestrator has two moves, and both cost something the audit was
  meant to prevent: read `notes/` and breach the contract that keeps its verification honest,
  or write its own message and ship un-humanized prose in violation of C-16, having paid a
  worker and a checker for a draft nobody used. A clause fragment that ends in a verdict file
  but never reaches its consumer is checked, not satisfied.

  Fix: move the draft out of `notes/`. Any other path under `.agent-guild/state/` works —
  `.agent-guild/state/T-004-commit-message.txt` is the obvious one — since the state map puts
  only `notes/` off-limits to the orchestrator and `.gitignore:2` keeps all of
  `.agent-guild/state/` untracked, so C-13 is unaffected either way. Update three places
  together: excerpt item 5, the `artifacts` instruction, and the path named in the C-16
  `check_method`. Checkers reading `notes/` is fine; nothing forbids that. It is the
  orchestrator's read that the contract blocks.

- **T-004 / C-16(b)** (major): the `check_method` is narrower than the clause on the
  script-comments fragment, and no other task covers the remainder.

  C-16 names five kinds of added prose: the migrate-mode section of `SKILL.md`,
  `references/migration.md`, the record paragraph's template, **script header comments**, and
  the commit message. T-004's `check_method` renders the fourth as "script header comments
  touched here," and the excerpt's voice paragraph repeats the narrowing as "any script header
  comments you touch." T-002 writes the entire Tier 2 path into `migrate-scope.sh`; T-003
  writes `verify-migration.sh` from nothing. Neither cites C-16, and neither `check_method`
  mentions voice, so every comment and diagnostic string in the two scripts this job actually
  ships is read by no checker against C-16.

  This is the r0 blocker's species at lower severity: a `check_method` that cites a clause and
  then checks part of it. Its failing example is concrete — `verify-migration.sh` ships with a
  header comment reading "This function runs the lint over each file in the scope and returns
  its status," pure what-not-why against a clause that exists to forbid exactly that, and
  every check in the decomposition passes.

  Fix, either way: (a) drop "touched here" and have T-004's C-16 read cover all comments and
  human-facing strings this job added to `inbox-to-memory/scripts/`, with the excerpt telling
  the worker it may revise comments in `migrate-scope.sh` and `verify-migration.sh` for voice
  — T-004 depends on both tasks, so both files exist by then, and C-13 already permits the
  edits; or (b) add C-16 to T-002's and T-003's `clauses` with a comments-and-diagnostics
  rubric in each `check_method`. Option (a) is the smaller change and keeps prose judgment in
  the one task routed to `worker-craft`.

## Advisories

Neither fails a task. Fold them into the same revision if convenient.

1. **T-002's C-1 bullet asks the `artifacts` list for something it does not carry.** The
   bullet says to read "which note that is — and which name — from T-001's `artifacts` list."
   T-001's closing instruction lists changed files, so the list yields the note and not the
   name. The name is still recoverable — it is the one in the note's Raw Content body that
   appears nowhere above the fence, and `git diff 1f17478 -- tests/fixtures/` shows the added
   lines directly — so a worker can resolve this. Saying so in the bullet would remove the
   only step it leaves to inference.

2. **T-001's excerpt points one directory up from the notes.** Step 1 says "Pick ONE note in
   `tests/fixtures/inbox-to-memory/old-only/`"; both candidates live in that directory's
   `notes/` subdirectory, alongside `_inbox/`, `_memory/context/`, and `_memory/decisions/`.
   The C-1/C-2 framing makes the intent unambiguous, and the constraint that only files under
   `old-only/` may change is correct as written. Cosmetic.

## Verdict

FAIL. T-001, T-002, and T-003 are sound and dispatchable as written — the r0 blocker on
T-002's C-3 is fixed, and fixed at the substance rather than around it. T-004 carries two
major C-16 defects: a drafted commit message written where the orchestrator may not read it,
and a check that covers the clause's script-comment fragment only for files T-004 itself
touches. Both fixes are confined to T-004's `check_method` and spec excerpt; nothing about
coverage, routing, or the dependency graph needs to move. Revise T-004 and re-submit for
`DEC-audit-r2`.
