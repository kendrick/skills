---
task: DEC-audit
checker: auditor
vendor: anthropic
model: claude-opus-5
verdict: FAIL
checked_at: 2026-08-06T22:28:30Z
---

Round 2 audit of the decomposition at `.agent-guild/state/tasks/` (T-001 through T-004) against
`.agent-guild/state/spec.md` and `.agent-guild/state/constitution.md`. Prior rounds:
`DEC-audit-r0.md` (FAIL, blocker on T-002's C-3) and `DEC-audit-r1.md` (FAIL, two majors on
T-004).

All three reported changes were verified against the task files rather than taken on faith. Both
r1 majors are fixed, and fixed at the substance. The C-16 ruling in change 2 is sound and I am
recording it as upheld rather than re-litigating it — the reasoning that a worker who writes a
comment should be told the standard and checked against it is correct, and it leaves no C-16
fragment double-checked.

This round fails on `T-001`, at major severity, on a defect that change 3 introduced. Making the
name handoff explicit was the right move; it created a worker-authored string that two blocker
clauses' assertions key off, and nothing in the decomposition checks that string against the
fixture it claims to describe. Every line-number, file-existence, and arithmetic claim below was
re-derived from the working tree at `eac74fe`.

## Per-task results

| task | result | severity | description | evidence |
| ---- | ------ | -------- | ----------- | -------- |
| T-001 | **FAIL** | major | Change 3's cosmetic half landed cleanly: excerpt step 1 now points at `tests/fixtures/inbox-to-memory/old-only/notes/` and names both candidate files, and both exist. The handoff half landed as instruction without verification. The closing instruction requires a `## Seam planted` section recording the note path and the verbatim planted name; the `check_method` never mentions that section, so no checker compares what T-001 wrote down against what T-001 planted. T-002's C-1 and C-2 assertions are built from the recorded string, and a mis-transcribed name makes both of them pass vacuously. Detail in Diagnosis. | `T-001.md:9-18` (`check_method`, no mention of the section), `:33` (both candidates named), `:42` (the `## Seam planted` instruction); both fixture files present in `old-only/notes/`; `T-002.md:63` reads note and name from that section |
| T-002 | PASS | — | The r0 C-3 fix still stands. Change 2's addition landed: C-16 is in `clauses` and the `check_method` fragment reads "every comment and user-facing string this task added to migrate-scope.sh — including the Tier 2 diagnostics' wording and any new header comments," judged against the humanizer pattern list and the file's existing voice, with the three flags named. That is the whole of what this task adds to that file, so the fragment is co-extensive with the work. Change 3's consumer side landed at the C-1 bullet, which is why the T-001 defect lands where it does rather than here. All ten cited clauses appear in the `check_method`; the nine non-C-16 fragments are unchanged and still consistent with their clauses. | `T-002.md:5` (`clauses` gains C-16), `:35-40` (C-16 fragment), `:63` (reads `## Seam planted`); `extract_body` at `migrate-scope.sh:123` as cited; `NOTE_KEY_ORDER` holds 17 names, C-15 script exits 0 (17+2=19 ≤ 20); suite anchors `:532`, `:566-575` confirmed |
| T-003 | PASS | — | Change 2's addition landed with a boundary rather than a blur: C-16 in `clauses`, and the fragment scopes to `verify-migration.sh`'s header comment, inline comments, and failure and report strings against the voice of `lint-scope.sh` and `migrate-scope.sh`, closing with "The record paragraph's final prose is T-004's, not this task's." That sentence is what keeps this fragment from colliding with T-004's. C-6 through C-10 unchanged and still each a restatement or superset of the constitution's check, including the stub-lint abort seam and the committed-rename case. All cited anchors re-verified. | `T-003.md:5`, `:32-37` (C-16 fragment and carve-out); `verify-migration.sh` still absent from `inbox-to-memory/scripts/` (only `collapse-vtt.sh`, `lint-scope.sh`, `migrate-scope.sh`); `lint-scope.sh:63` and `migrate-scope.sh:76` are the `yq` preflight; `tests/inbox-to-memory-smoke.sh:8` is the `BASH_SOURCE` resolution |
| T-004 | PASS | — | Both r1 majors are closed. **(a)** The draft moved to `.agent-guild/state/commit-message.md`; excerpt item 5 names the path, says why it is not under `notes/`, and still lists it under `artifacts`, and the C-16 `check_method` names the same path. The orchestrator may read that path — the state map puts only `notes/` off-limits — and `.gitignore:2` untracks all of `.agent-guild/state/`, so C-13 is unaffected. **(b)** The narrowing that left T-002's and T-003's comments unverified is gone, replaced by an explicit pointer at the tasks that now own them. C-14's fragment is still the constitution's verbatim and the string it falsifies against is still in the tree. One residue, advisory only: the enumerated scope does not name comments this task itself revises. See Advisory 1. | `T-004.md:15-21` (C-16 fragment naming the new path), `:42` (excerpt item 5 with the reason), `:44` (parenthetical deferring script comments to T-002/T-003); `.gitignore:2` is `.agent-guild/state/`; `references/migration.md:19` still reads "Tier 2 is tracked in its own ticket and is not implemented here."; SKILL.md Migrate Mode at `:342-368`; existing SKILL.md pins at `tests/inbox-to-memory-smoke.sh:257`, `:551-555` |

## Coverage

Every spec acceptance criterion maps to at least one task, and every clause C-1 through C-16 is
cited. No uncovered spec requirement, no orphan clause. The C-16 row is the only one that moved
this round, and it moved from one owner to three with disjoint scopes.

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
| — (constitution-only) prose reads like a person wrote it | C-16 | T-002 (migrate-scope.sh), T-003 (verify-migration.sh), T-004 (docs, record template, commit message) |

### The C-16 partition, checked fragment by fragment

The ruling in change 2 was to distribute C-16 rather than widen T-004, and the audit question is
whether the partition covers the clause and whether any fragment is now read twice. Taking C-16's
five named kinds of prose in order:

| C-16 fragment | owner | double-checked? |
| ------------- | ----- | --------------- |
| Migrate-mode section of `SKILL.md` | T-004 | no other task may touch `SKILL.md` (T-002 `:81`, T-003 `:70`) |
| `references/migration.md` | T-004 | same |
| The record paragraph's template | T-004 | T-003 writes it plainly and its fragment carves it out by name |
| Script header comments | T-002 (`migrate-scope.sh`), T-003 (`verify-migration.sh`) | disjoint by file; T-004's fragment names neither and its excerpt says so in parentheses |
| The commit message | T-004 | sole author, sole reader |

No fragment is unowned, and no string is read by two checkers, so the decomposition cannot produce
two verdicts on one piece of prose. The ruling is upheld. It is also the better call on its merits:
the alternative made T-004's checker judge prose T-004 never wrote, on a task that would then fail
for a sonnet worker's comment with no path to rework it except through a second worker's file.

Two boundary notes, neither a finding. T-003's "failure and report strings" and T-004's "record
paragraph template" abut, and the carve-out sentence is what separates them — it is doing real
work, so it should survive any future rewording of that fragment. And T-002's and T-003's C-16
fragments omit the house carve-outs that C-16's own check text carries (title case and unspaced em
dashes are correct, not findings). That is tolerable because the checker reads the clause text
itself, which carries them, and because neither carve-out has much purchase inside a bash comment.

## Routing

Conformant, including the one place change 2 makes it look otherwise.

- T-001 → `worker-bulk`/haiku for a mechanical fixture edit, with `checker-judgment` because every
  clause it cites but C-13 is rubric-checked and no script can decide "this worker-chosen name
  appears nowhere above the fence." Recording the seam it planted is still mechanical work; the
  tier is right.
- T-002, T-003 → `worker-standard`/sonnet. Adding C-16 does not make these taste tasks. The routing
  table says to route by the work, and the work is clear-spec bash judged on correctness; comments
  accompanying an implementation are that implementation's normal output, not user-facing craft.
  Both already carry `checker-judgment`, which is what C-16 requires on the checking side, and a
  C-16 FAIL on either has an ordinary rework path with an escalation rung above it.
- T-004 → `worker-craft`/opus with `checker-judgment`. Correct, and the only pairing the table
  permits for the docs and the commit message.
- All four carry the two deterministic clauses (C-13, C-15) under a judgment checker. A task names
  one checker; judgment can run a script, deterministic cannot apply a rubric, so the mixed case
  resolves to judgment. Both deterministic checks were run here at `eac74fe` and exit 0, so each
  checker inherits a clean baseline.

## Dependencies

DAG intact: T-001 → T-002 → T-003, with T-004 depending on T-002 and T-003. Every referenced id
exists as a file. No cycles, no dangling references.

Change 3 strengthened the T-001 → T-002 edge from coordination to a genuine data dependency: T-002
now reads a section T-001 writes, so the edge carries content and not just serialization. The
T-002 → T-003 edge remains coordination over the shared test file, as recorded in r0 — if T-002
exhausts its ladder, T-003 can still be re-parented to T-001.

## Diagnosis

- **T-001 / C-1, C-2** (major): the seam record is a worker self-report that gates two blocker
  clauses, and no `check_method` reads it.

  The closing instruction (`T-001.md:42`) requires the worker to "add a `## Seam planted` section
  to this task file recording two things T-002 depends on — the note path you edited, and the exact
  raw-content-only name you planted. Write the name verbatim; T-002's suite asserts against that
  string." T-002 does exactly that: "Read which note that is — and the exact name — from the
  `## Seam planted` section of `.agent-guild/state/tasks/T-001.md`, which records both"
  (`T-002.md:63`).

  T-001's `check_method` covers the fixture and not the record. It asks the checker to confirm one
  old-only note's Raw Content names a person or vendor and that the name appears nowhere above the
  fence. Both are the right things to check about the *note*. Neither compares the note against the
  section T-002 will read. T-002's C-1 fragment says "the raw-content-only name" without saying
  where its checker should resolve that phrase, so a checker can resolve it from the same
  self-report the worker used.

  The failing example is concrete and needs no misconduct, only a copy slip from a haiku worker.
  T-001 plants `Meridian Systems` in the note's Raw Content and records `Meridian Systems Inc.`
  under `## Seam planted`. T-001's checker reads the fixture, finds a raw-content-only vendor name,
  and passes — correctly, against the check it was given. T-002 builds its suite from the recorded
  string: it asserts the Tier 2 extract omits `Meridian Systems Inc.`, which is vacuously true even
  of an implementation that reads the whole file below the fence, and it asserts a proposals row
  naming `Meridian Systems Inc.` is refused as `tier2-entity-unsourced`, which is vacuously true of
  a string absent from the note entirely. The suite exits 0. Every `check_method` in the
  decomposition passes. C-1 and C-2, both blockers, ship with assertions that cannot fail, and the
  constitution's "testability fixture" section — whose whole purpose is "that name is what the two
  clauses below falsify against" — has been satisfied on paper only.

  This is the r0 blocker's species at lower severity: a check that cannot fail. It is also new this
  round. Before change 3, T-002's worker had to identify the name from the fixture itself, which is
  self-correcting; the explicit handoff is better in every way except that it added a transcription
  hop with no verifier. Do not revert it.

  Fix, one sentence in T-001's `check_method`: confirm the `## Seam planted` section names the note
  the diff actually shows edited, and that the name it records appears byte-for-byte in that note's
  Raw Content body and nowhere above the `## Raw Content` heading. Worth one clause in T-002's C-1
  fragment as well — that the checker resolves the raw-content-only name from the fixture rather
  than from T-001's record — since re-deriving rather than trusting a self-report is the checker's
  standing contract and this is the one place the decomposition invites the opposite.

## Advisories

Neither fails a task. Fold them into the same revision if convenient.

1. **T-004's C-16 scope omits comments T-004 itself revises.** The excerpt's voice paragraph
   (`:44`) tells the worker to run "any script comments you touch here" through the humanizer loop,
   but the `check_method`'s enumerated list is docs, record template, and commit message. Item 3
   has the worker editing the record template inside `verify-migration.sh`, so an adjacent comment
   is a plausible thing for it to touch — and T-003's checker read that file before the edit
   existed. The exposure is much smaller than r1's version of this (one task's edits to comments a
   checker has already seen once, rather than two whole files), which is why it is an advisory.
   Adding "and any script comment this task adds or revises" to the fragment closes it.

2. **New comments in `tests/inbox-to-memory-smoke.sh` fall between C-16's preamble and its list.**
   The clause opens on "Every human-facing string this job adds" and then enumerates five kinds,
   none of them suite comments. All three implementing tasks add substantial commentary to that
   file — the existing suite is heavily commented in house voice, e.g. `:565-567` — and the C-16
   fragments scope to `migrate-scope.sh`, `verify-migration.sh`, and the docs. I read the
   enumeration as operative, which is why this is not a finding, and it is the same reading r1 used
   to fail T-004. If the intent is the broader preamble, the cheapest fix is a clause in T-002's
   and T-003's C-16 fragments covering the suite comments each one adds.

## Verdict

FAIL. Both r1 majors on T-004 are closed, the C-16 ruling in change 2 is upheld after checking the
partition fragment by fragment, and T-002, T-003, and T-004 are sound and dispatchable as written.
T-001 carries one major: change 3 made the seam handoff explicit without making it checkable, so a
mis-transcribed name would leave two blocker clauses with assertions that cannot fail and every
check in the decomposition green. The fix is one sentence in T-001's `check_method` and, optionally,
one clause in T-002's. Coverage, routing, and the dependency graph need no movement. Revise T-001
and re-submit for `DEC-audit-r3`.
