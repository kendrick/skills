---
task: DEC-audit
checker: auditor
vendor: anthropic
model: claude-opus-5
verdict: FAIL
checked_at: 2026-08-06T22:15:29Z
---

Audit of the decomposition at `.agent-guild/state/tasks/` (T-001 through T-004) against
`.agent-guild/state/spec.md` and `.agent-guild/state/constitution.md`. Round 0; the only
prior verdict on this job is `CON-audit-r0.md` (PASS), whose Note 4 is load-bearing below.
Every line-number, file-existence, and arithmetic claim the tasks make was re-derived from
the working tree at `eac74fe` rather than taken from the task text.

## Per-task results

| task | result | severity | description | evidence |
| ---- | ------ | -------- | ----------- | -------- |
| T-001 | PASS | — | Cites C-1, C-2 (as seam precondition, honestly labeled "the clauses themselves land in T-002"), C-12, C-13. The check_method is falsifiable and mechanically resolvable: a named fixture note, a name that must appear nowhere above `## Raw Content`, plus the C-12 diff read and the C-13 script verbatim. Routing sound (see Routing). Feasibility confirmed: no suite assertion pins either candidate note's byte content or line count, so the edit cannot break the Tier 1 suite the way the task's own escape hatch worries about. | both old-only notes carry the one-line placeholder (`2025-11-04-…-3iMu15QJ_x.md:45`, `2025-11-18-…-P5spzLt4Bz.md:41`); the suite's only content pins on those notes are `require_text` on frontmatter keys and one `(raw: L12)` line ref (`tests/inbox-to-memory-smoke.sh:651-662`), none of which the Raw Content body affects |
| T-002 | **FAIL** | blocker | Cites C-1, C-2, C-3, C-4, C-5, C-11, C-12, C-13, C-15. Eight of nine check_methods are consistent with or a strict superset of the constitution's own check. **C-3 is not.** The clause's check is claim-by-claim traceability from each written `summary` back to that note's Tier 2 extract; T-002 substitutes "summary is a single line" plus "lint-scope.sh exits 0 over a Tier-2-applied scope" and drops traceability entirely. Neither substitute can fail on C-3's own failing example. Detail in Diagnosis. | constitution `C-3` check text vs. `T-002.md:16-18` (`check_method`) and `T-002.md:54` (spec excerpt bullet) |
| T-003 | PASS | — | Cites C-6, C-7, C-8, C-9, C-10, C-12, C-13. Every check_method restates the constitution's check and adds the two folded findings: the lint's reported failure count and the committed-deletion case, plus the sibling resolution and the script's own `yq` preflight from CON-audit Note 1. The stub-lint abort seam is specified precisely enough for a checker to reproduce it. All cited anchors exist. | `verify-migration.sh` genuinely absent from `inbox-to-memory/scripts/` (only `collapse-vtt.sh`, `lint-scope.sh`, `migrate-scope.sh`); `lint-scope.sh:63` and `migrate-scope.sh:76` are both the `command -v yq` preflight; `tests/inbox-to-memory-smoke.sh:8` is the `dirname "${BASH_SOURCE[0]}"` resolution; throwaway-repo harness at `:566-575` matches |
| T-004 | PASS | — | Cites C-14, C-16, C-12, C-13. C-14's check_method is the constitution's verbatim, and the string its falsifiability depends on is still in the tree. C-16's rubric carries both house carve-outs (title case, unspaced em dashes) so a checker cannot flag them as findings. The commit-message carve-out is acceptable but under-recorded — see Advisory 1. | `references/migration.md:19` still reads "Tier 2 is tracked in its own ticket and is not implemented here."; SKILL.md Migrate Mode confirmed at `:342-368`; existing routing-row pins at `tests/inbox-to-memory-smoke.sh:257`, `:551-555` |

## Coverage

Every spec section and every acceptance criterion maps to at least one task, and every
constitution clause C-1 through C-16 is cited by at least one task. No orphan clauses, no
uncovered spec requirements.

| spec acceptance criterion | clause | task |
| ------------------------- | ------ | ---- |
| Summary and entities derive only from extracted sections | C-1, C-2, C-3 | T-001 (seam), T-002 |
| Tier 2 approval separate from Tier 1, per-file or batched | C-4 | T-002 |
| Rejecting a Tier 2 proposal leaves Tier 1 intact | C-5 | T-002 |
| Verification runs the full lint over every migrated file | C-6 | T-003 |
| Every link resolving before resolves after | C-7 | T-003 |
| Rename count asserted at zero via git | C-8 | T-003 |
| Failures reported, never auto-repaired | C-9 | T-003 |
| Record paragraph emitted, never written | C-10 | T-003 (behavior), T-004 (prose) |
| — (constitution-only) second-run no-op incl. Tier 2 | C-11 | T-002 |
| — (constitution-only) assertions never lost | C-12 | all four |
| — (constitution-only) diff stays in scope | C-13 | all four |
| — (constitution-only) docs describe what ships | C-14 | T-004 |
| — (constitution-only) Tier 2 cannot reach the budget | C-15 | T-002 |
| — (constitution-only) prose reads like a person wrote it | C-16 | T-004 (minus the commit message; Advisory 1) |

Coverage is a mapping, not a guarantee of depth: C-3 appears in the table because T-002
cites it, and the Diagnosis is about the fact that citing it is all T-002 does.

## Routing

Assignments follow the routing table, including the two places they appear not to.

- T-001 → `worker-bulk`/haiku is correct for a mechanical fixture edit. Its checker is
  `checker-judgment` rather than the table's default `checker-deterministic` pairing, and
  that is right, not a deviation: the table's operative rule is "a clause checked by a
  script routes to checker-deterministic; a clause checked by a rubric routes to
  checker-judgment," and every clause T-001 cites except C-13 is rubric-checked in the
  constitution. `checker-deterministic` only runs scripts, and no script exists that can
  decide "this name appears nowhere above the fence" or "no assertion was loosened."
- T-002, T-003 → `worker-standard`/sonnet for clear-spec bash implementation judged on
  correctness. Correct.
- T-004 → `worker-craft`/opus with `checker-judgment` for user-facing prose. Correct,
  and the only pairing the table permits for C-16.
- All four → `checker-judgment` despite carrying the two deterministic clauses (C-13,
  C-15). A task names one checker; a judgment checker can run a script, a deterministic
  checker cannot apply a rubric, so the mixed case resolves to judgment. Both deterministic
  checks were executed here and exit 0 at `eac74fe` (C-13: empty output; C-15: 17 + 2 = 19
  ≤ 20), so a checker inheriting them inherits a clean baseline.

## Dependencies

`deps` form a DAG: T-001 → T-002 → T-003, and T-004 depends on both T-002 and T-003. Every
referenced id exists as a file. No cycles, no dangling references.

The T-002 → T-003 edge is coordination, not logic, and it holds on that basis. Both tasks
edit `tests/inbox-to-memory-smoke.sh`, and running them in parallel would put two workers in
one file and hand each of them a C-12 baseline (`git diff 1f17478 -- tests/`) polluted by the
other's half-finished edits — a checker could not attribute a loosened assertion to either
worker. Serializing is the right call. Worth recording that the edge is not a functional one:
T-003's suite scopes migrate with the existing Tier 1 `--apply` and nothing in
`verify-migration.sh` needs Tier 2 to exist, so if T-002 exhausts its ladder or is abandoned,
T-003 can be re-parented to T-001 rather than dying with it.

## Diagnosis

- **T-002 / C-3** (blocker): the `check_method` does not check the clause it cites.

  C-3's text has two conjuncts: each generated `summary` is one line, **and** it "asserts
  nothing its note's Tier 2 extract does not support." The constitution's check is entirely
  about the second: "for each migrated note in the run, read the note's Tier 2 extract beside
  its written `summary` and confirm every claim traces to the extract. Any unsupported claim
  fails the clause."

  T-002's check_method for C-3 reads, in full: "confirm the apply writes summary as a single
  line and the suite asserts lint-scope.sh exits 0 over a Tier-2-applied scope." The spec
  excerpt gives the worker the same narrowed instruction (`T-002.md:54`). Traceability appears
  in no task's check_method anywhere in the decomposition.

  This is not a stylistic gap. Take C-3's own failing example — a note whose sections record
  only a scoping conversation, given `summary: 'Cutover approved for March.'` — and plant it
  in the proposals fixture T-002's suite must author. It is one line. It lints clean. It passes
  T-002's C-3 check_method, it passes every other check_method in the decomposition, and the
  blocker clause written to catch exactly it never fires. A clause whose failing example passes
  its own task's check is not being checked.

  The substitution also runs against the standing advisory. `CON-audit-r0.md` Note 4 passed C-3
  on the condition that the decomposition give it teeth: "unlike C-1, C-2, and C-4 it names no
  assertion that must exist in the suite, so nothing guards it against regression later. If the
  decomposition can pin one (a fixture proposal whose summary asserts something the extract does
  not support, asserted to be caught or flagged), C-3 gets teeth it currently lacks." The
  decomposition instead removed the half of C-3 the note was about. The single-line assertion
  folded in from the codex lane is a fine addition; it was added in place of the clause's
  substance rather than alongside it.

  Fix, either way is acceptable: (a) extend T-002's C-3 check_method to "read every `summary`
  value the suite's proposals fixtures carry beside that note's emitted extract and confirm each
  claim traces to it — a fixture summary introducing a date, name, decision, or outcome absent
  from the extract fails," keeping the single-line and lint assertions as the first conjunct; or
  (b) go further and take Note 4's suggestion, having T-002 plant an unsupported-claim proposal
  and pin the flag. Whichever, the spec excerpt bullet at `T-002.md:54` needs the same text, or
  the worker builds to the narrow reading and the checker fails it for something it was never
  told to do.

## Advisories

These do not fail a task. Both should be resolved in the same revision as the Diagnosis.

1. **C-16's commit-message fragment has an owner but no verifier.** C-16 names "the commit
   message" among the strings that must go through the humanizer loop; T-004 excludes it
   ("the orchestrator handles it at ship time"). The exclusion itself is sound — the message
   cannot exist until every task's artifacts do, so no task could own it without writing about
   work that has not happened. What is missing is the record. Every other clause fragment in
   this job ends in a verdict file; this one ends in a parenthesis inside a task excerpt, and
   the CON and DEC audits both run in Phases 0–1, well before there is a message to read. Pick
   one: add the commit message to C-16's check text as an explicitly orchestrator-verified
   fragment with the humanizer loop named, or make a drafted message a T-004 artifact so it
   crosses a checker. Do not leave it as a carve-out only the task excerpt knows about.

2. **T-001's check_method says "gained a Raw Content section."** Both old-only notes already
   have the section (`:45` and `:41`); what the note gains is content below the existing fence.
   A literal-minded checker could fail a correct edit for not adding a heading. Reword to
   "gained raw-content lines below its existing `## Raw Content` heading."

3. **T-001 leaves the note choice to the worker; T-002 depends on it.** T-002's C-1 and C-2
   assertions both target "the seam note (T-001's fixture)," and T-001 permits either note plus
   a fallback ("pick the other note"). That resolves fine as long as T-001's `artifacts` names
   the file it actually edited, which the task does require — worth stating in T-002's excerpt
   that the note is read from T-001's artifacts rather than assumed.

## Verdict

FAIL. One blocker: T-002's C-3 `check_method` is inconsistent with the clause it cites, in the
specific way `CON-audit-r0.md` Note 4 warned against. Coverage, routing, and the dependency
graph are otherwise sound, and T-001, T-003, and T-004 are ready to dispatch as written. Revise
T-002 (check_method and spec excerpt), fold in the three advisories, and re-submit for
`DEC-audit-r1`.
