---
task: DEC-audit
checker: auditor
vendor: anthropic
model: claude-opus-5
verdict: PASS
checked_at: 2026-08-06T22:34:11Z
---

Round 3 audit of the decomposition at `.agent-guild/state/tasks/` (T-001 through T-004) against
`.agent-guild/state/spec.md` and `.agent-guild/state/constitution.md`. Prior rounds: `DEC-audit-r0.md`
(FAIL, blocker on T-002's C-3), `DEC-audit-r1.md` (FAIL, two majors on T-004), `DEC-audit-r2.md`
(FAIL, one major on T-001's unverified name handoff).

The r2 major is closed, and closed on both sides rather than one. All three reported changes were
read out of the task files rather than taken on faith, and this round re-derives the whole
decomposition — coverage, every `check_method` against its clause's full text, routing, and the DAG —
not just the delta. Every file path, line anchor, and script result below was re-run against the
working tree at `eac74fe`.

Two advisories, neither failing a task. The suite-comment question raised in change 3 is ruled on
under Settled below, so a later round has something to point at instead of re-opening it.

## Per-task results

| task | result | severity | description | evidence |
| ---- | ------ | -------- | ----------- | -------- |
| T-001 | **PASS** | — | The r2 major is fixed at the substance. The `check_method` now continues past the fixture into the handoff: it confirms `## Seam planted` names the note the diff actually shows edited, that the recorded name appears byte-for-byte in that note's Raw Content and nowhere above the heading, and it states outright that a mismatch fails the task because T-002 builds two blocker-clause assertions from that string. The byte-for-byte requirement is what makes the fix load-bearing rather than decorative — a truncation like `Meridian` for `Meridian Systems` still satisfies it, and a truncation that satisfies it is still a live falsifier for both C-1 and C-2, so the check admits exactly the variants that stay non-vacuous. Absence of the section fails too: you cannot confirm a section names the note if it isn't there. C-12 and C-13 fragments unchanged and still verbatim against the constitution's checks. | `T-001.md:15-20` (the handoff verification), `:21-24` (C-12, C-13), `:48` (the closing instruction it now verifies); both candidate fixtures present, each carrying `## Raw Content` plus the one-line placeholder at `:45-47` and `:41-43` respectively; C-13 and C-15 scripts both exit 0 at `eac74fe` |
| T-002 | **PASS** | — | The consumer side of the r2 fix landed. The C-1 fragment now has the checker resolve the raw-content-only name from the fixture itself — "read the seam note and take the name that appears below `## Raw Content` and nowhere above it" — explicitly rather than trusting T-001's self-report, and states that an assertion written against an absent string passes vacuously and fails the clause. That restores the checker's standing contract at the one place the decomposition invited the opposite, and it is belt-and-braces with T-001's own new check. The excerpt still points the *worker* at `## Seam planted` (`:67`), which is the right division: the worker may use the handoff, the checker re-derives. All ten cited clauses appear in the `check_method`; the r0 C-3 fix and change 2's C-16 fragment are unchanged and still sound. | `T-002.md:10-17` (C-1 re-derivation), `:20-27` (C-3 judgment plus mechanical halves), `:27-31` (C-4 covering per-file and batched), `:36-44` (C-12/13/15/16); `extract_body` confirmed at `migrate-scope.sh:123`; `NOTE_KEY_ORDER` holds 17 names, so C-15's `17+2 ≤ 20` exits 0; suite anchors `:532` and `:566-575` confirmed |
| T-003 | **PASS** | — | Unchanged since r2 and still sound on a fresh read. C-6 through C-10 are each a restatement or a superset of the constitution's check, including the two seams the clauses turn on: the stub-lint abort run from a copied `scripts/` dir, and the rename **committed** since the `--since` ref that an implementation reading `git status --porcelain` must fail. C-8's fragment adds the committed-deletion case, which the clause's text requires ("naming renames and deletions separately") and its check text does not — a superset, not a drift. The C-16 fragment's carve-out sentence still separates this task's report strings from T-004's record template. | `T-003.md:10-18` (C-6, both cases plus sibling resolution and preflight), `:21-24` (C-8), `:32-37` (C-16 and the carve-out); `verify-migration.sh` still absent from `inbox-to-memory/scripts/` (only `collapse-vtt.sh`, `lint-scope.sh`, `migrate-scope.sh`); `yq` preflights confirmed at `lint-scope.sh:63` and `migrate-scope.sh:76`; `BASH_SOURCE` resolution at `tests/inbox-to-memory-smoke.sh:8` |
| T-004 | **PASS** | — | Change 2 landed: the C-16 fragment's enumeration now closes on "any comment or string this task revised in a script or in `tests/inbox-to-memory-smoke.sh`," which discharges r2's advisory 1 — item 3 has this task editing the record template inside `verify-migration.sh`, and an adjacent comment it revises is no longer read by nobody. C-14's fragment still covers every element of the clause and the string it falsifies against is still in the tree. The commit-message path is still outside C-13's reach. One wording residue at the seam between "added" and "revised", advisory only: see Advisory 1. | `T-004.md:15-22` (C-16 fragment), `:23-25` (C-12, C-13), `:43` (commit draft to `.agent-guild/state/commit-message.md`), `:45` (script comments deferred to T-002/T-003); `references/migration.md:19` still reads "Tier 2 is tracked in its own ticket and is not implemented here."; SKILL.md Migrate Mode spans `:342-368` as cited (`:369` is the rule); existing SKILL.md pins at `tests/inbox-to-memory-smoke.sh:257`, `:551-555`; `.gitignore:2` is `.agent-guild/state/`, and C-13's `--exclude-standard` honors it |

## Coverage

Every spec acceptance criterion maps to at least one task, and every clause C-1 through C-16 is
cited by at least one. No uncovered spec requirement, no orphan clause. The table is unchanged from
r2 — nothing moved between owners this round.

| spec acceptance criterion | clause | task |
| ------------------------- | ------ | ---- |
| Generated summary and entities derive only from extracted sections | C-1, C-2, C-3 | T-001 (seam), T-002 |
| Tier 2 approval separate from Tier 1, per-file or batched | C-4 | T-002 |
| Rejecting a Tier 2 proposal leaves that note's Tier 1 changes intact | C-5 | T-002 |
| Verification runs the full lint over every migrated file | C-6 | T-003 |
| Every link resolving before migration resolves after | C-7 | T-003 |
| Rename count asserted at zero via git | C-8 | T-003 |
| Verification failures reported, never auto-repaired | C-9 | T-003 |
| The migration paragraph is emitted, never written | C-10 | T-003 (behavior), T-004 (prose) |
| — (constitution-only) second-run no-op, Tier 2 included | C-11 | T-002 |
| — (constitution-only) no assertion deleted or weakened | C-12 | all four |
| — (constitution-only) the diff stays in scope | C-13 | all four |
| — (constitution-only) docs describe what ships | C-14 | T-004 |
| — (constitution-only) Tier 2 cannot reach the budget | C-15 | T-002 |
| — (constitution-only) the prose reads like a person wrote it | C-16 | T-002, T-003, T-004 |

The spec's prose body adds nothing the criteria omit: the sidecar shape and separate gating are
C-1 through C-5 on T-002, the closing sweep is C-6 through C-10 on T-003, and "Blocked by #15" is
already satisfied on this branch at `1f17478`.

### The seam handoff, end to end

The r2 major was a transcription hop with no verifier. The chain now closes at both ends, and it is
worth writing down which end catches what, because the two checks are not redundant:

1. T-001's worker plants the name in one old-only note's Raw Content and records it under
   `## Seam planted`.
2. T-001's checker reads the diff, confirms the recorded note is the edited one, and confirms the
   recorded name appears byte-for-byte below the fence and nowhere above it. A copy slip fails here.
3. T-002's worker reads `## Seam planted` and writes its C-1 and C-2 assertions against that string.
4. T-002's checker **re-derives** the name from the fixture and confirms the suite's assertions name
   *that* name, with the vacuous-pass failure mode called out by name.

Step 2 catches a bad record. Step 4 catches assertions built against a string the fixture doesn't
carry, whatever the record says. Either alone would close r2's example; both together also close the
case where the record is right and the suite still keys off something else.

## Routing

Conformant against the table in `CLAUDE.md`.

- T-001 → `worker-bulk`/haiku with `checker-judgment`. The executor tier follows the work, which is a
  mechanical fixture edit plus a two-field record; the checker tier follows the clauses, and every
  clause here but C-13 is rubric-checked. No script can decide "this worker-chosen name appears
  nowhere above the fence," and the new handoff verification is the same kind of read.
- T-002, T-003 → `worker-standard`/sonnet with `checker-judgment`. Clear-spec bash judged on
  correctness. Carrying C-16 does not convert them to taste tasks — comments accompanying an
  implementation are that implementation's ordinary output — and `checker-judgment` is what C-16
  requires on the checking side regardless.
- T-004 → `worker-craft`/opus with `checker-judgment`. Docs, the record paragraph, and the commit
  message are user-facing craft; this is the only pairing the table permits for them.
- All four mix deterministic clauses (C-13, and C-15 on T-002) with judgment ones under a single
  judgment checker. A task names one checker; judgment can run a script, deterministic cannot apply a
  rubric, so the mixed case resolves to judgment. Both deterministic checks were run here at
  `eac74fe` and exit 0, so every checker inherits a clean baseline and any nonzero result is the
  worker's.
- Each `executor_model` matches its executor's tier, so no dispatch trips `dispatch-guard` on a
  model mismatch.

## Dependencies

DAG intact: T-001 → T-002 → T-003, with T-004 depending on both T-002 and T-003. Every referenced id
resolves to a file. No cycles, no dangling references, no task depending on itself.

The T-001 → T-002 edge is a genuine data dependency, not just serialization — T-002's worker reads a
section T-001's worker writes. The T-002 → T-003 edge remains coordination over the shared suite
file, as recorded in r0: if T-002 exhausts its ladder, T-003 can be re-parented to T-001 without
losing anything, since T-003 migrates with the Tier 1 `--apply` that already shipped at `1f17478`.

## Settled

**Suite comments are out of C-16's scope for every task, and this is not to be re-opened.** Change 3
asked for a ruling rather than a fix, and the ruling is that the orchestrator's reading is right.

C-16's text opens on a broad preamble ("Every human-facing string this job adds") and then names
five kinds: the migrate-mode section of `SKILL.md`, `references/migration.md`, the record
paragraph's template, script header comments, and the commit message. Comments in
`tests/inbox-to-memory-smoke.sh` are none of those. r1 and r2 both read the enumeration as
operative, this round reads it the same way, and consistency across rounds is itself worth something
here — a clause that means one thing in r2 and another in r3 is not a standard.

The cost side confirms it. Amending C-16 invalidates the CON-audit PASS and restarts Phase 0, and
`dispatch-guard` blocks every worker until a fresh PASS lands. What that buys is polish on comments
in a test suite. C-16 is severity `major`, not blocker; an unpolished suite comment ships no wrong
behavior, corrupts no data, and makes no check vacuous — nothing downstream reads it. That is not a
trade worth a phase restart. Note also that the exposure is already partial rather than total:
T-004's fragment now reaches the suite comments it revises.

One consequence to hold onto rather than mistake for a defect later. T-004's C-16 fragment now
covers strings the five-kind enumeration does not, while T-002's and T-003's do not. That asymmetry
is real, and it is inside the clause: C-16's preamble and its check text ("read the added prose")
both support the wider reading, so T-004's fragment is a permitted superset rather than a drift.
Over-coverage cannot manufacture a vacuous pass; the worst it can do is cost T-004 a retry over a
comment, which has an ordinary rework path and a dispute route behind it.

## Advisories

Neither fails a task. Fold them in only if the decomposition is being touched for another reason —
neither is worth a revision cycle on its own.

1. **T-004's C-16 fragment says "revised" where "added or revised" would close it.** The fragment
   reads "any comment or string this task revised in a script or in
   `tests/inbox-to-memory-smoke.sh`" (`T-004.md:18-20`). Excerpt item 3 has this task polishing the
   record template inside `verify-migration.sh`, and a *newly added* comment there — explaining a
   substitution variable, say — is not a revised one, while T-003's checker read that file before
   the edit existed. Two things keep this advisory-grade rather than a finding. The fragment's own
   preamble is "read every added human-facing string," which the closing item narrows but does not
   override, and a checker reads the clause text alongside the fragment. And the exposure is a
   single comment inside a template polish, not a file. This is r2's advisory 1 taken and landing one
   word short, not a new gap.

2. **T-004's House constraints line contradicts its own excerpt item 5.** `:49` says "Only
   `inbox-to-memory/` and `tests/` may change (C-13)" while `:43` instructs the worker to write
   `.agent-guild/state/commit-message.md` and list it under `artifacts`. C-13's clause text allows
   `.agent-guild/` explicitly, and its check script excludes that path, so nothing actually fails —
   but the two lines read as a contradiction to a worker encountering them in order, and the
   resolution is only visible by going back to the constitution. Adding "plus the commit draft under
   `.agent-guild/state/`" to the constraints line removes the snag.

## Verdict

PASS. The r2 major is closed on both sides: T-001's checker now verifies the handoff record against
the fixture it describes, and T-002's checker re-derives the name rather than inheriting it, so a
mis-transcribed string can no longer leave two blocker clauses with assertions that cannot fail.
Change 2's addition to T-004 landed and discharges r2's advisory 1. The suite-comment question is
ruled settled in the orchestrator's favor and recorded above so it does not come back.

Coverage is complete against both the spec's acceptance criteria and all sixteen clauses; every
`check_method` is a restatement or a superset of its clause's check, never a narrowing; routing
follows the table on both the executor and the checker axis; and the dependency graph is an acyclic
chain with one join at T-004. The decomposition is dispatchable as written. The two advisories are
wording, not structure — neither justifies another round.
