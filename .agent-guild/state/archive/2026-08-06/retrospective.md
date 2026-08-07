# Retrospective: inbox-to-memory v2, Migration Tier 2 and Verification

Job: `kendrick/skills#16`. Four tasks, 17 verdicts, 6 FAILs, 0 disputes, 0 escalations. Every task landed at its originally routed tier.

## Catches

Six FAILs, and they split cleanly by what they caught.

**Three were the auditor turning back the orchestrator's own work**, all on the decomposition and none on the constitution. DEC-audit needed four rounds:

- **r0.** T-002's C-3 check had dropped the traceability half of the clause, keeping only the single-line requirement. The clause's own failing example (`summary: 'Cutover approved for March.'`) would have passed every check in the decomposition. A blocker clause whose failing example passes its own task's check is not being checked.
- **r1.** Two majors on T-004. The commit-message draft was routed to `state/notes/`, which the orchestrator is barred from reading, so it would have been written, checked, and then unreadable at ship time. And C-16's script-comment fragment was scoped to files T-004 touched, leaving the `migrate-scope.sh` and `verify-migration.sh` comments unchecked by anyone.
- **r2.** Making the T-001 to T-002 name handoff explicit had introduced an unverified transcription hop. A copy slip (`Meridian Systems` recorded as `Meridian Systems Inc.`) would have left two blocker-clause assertions passing vacuously against a string absent from the note.

**Two were the codex lane**, on the constitution. CON-audit's crossing returned 6 findings against the auditor's 0. Four became task acceptance criteria and changed what got built: the single-line summary assertion (C-3), per-file-and-batch approval (C-4), the reported failure count (C-6), and a committed-deletion case beside the rename (C-8). Highest-yield crossing of the run.

**One was checker-judgment on real code**, and it is the catch that earned the apparatus. T-003 r0 FAILed on C-7 and C-10, not because the script was wrong but because no assertion pinned the correct behavior. The checker proved it by mutation: it swapped in a tree-reading link sweep and the whole suite still exited 0. Same story for hard-coding the record paragraph's counts to zeros. Two assertions would have shipped asserting nothing under a green suite, and only a checker willing to break the implementation on purpose would have noticed.

## Strain

One strained task: T-003 at retries=1, and it stayed at sonnet. No tier was ever exhausted and `escalations.log` is empty.

The strain wasn't difficulty. The worker's script was correct on the first attempt, both times the checker failed it. What the task file demanded clearly was "write the script." What it needed was "write assertions that would fail if the script were wrong"—a different skill, and never asked for. The rework prompt worked because it named the second one directly: prove each new assertion discriminates by planting the mutant and watching the suite fail. The worker did exactly that and passed.

Routing was right throughout. T-001 mechanical to worker-bulk, T-002 and T-003 clear-spec to worker-standard, T-004 prose to worker-craft. All four to checker-judgment, because every task mixed judgment clauses with the two deterministic script checks, and a judgment checker can run a script while a deterministic one cannot apply a rubric.

## Disputes

None. No worker contested a verdict.

The absence isn't neutral, though. Every FAIL was accepted and reworked without argument, and each rework passed on the next attempt, which says the diagnoses were specific enough to act on. That is what the retry ladder asks of a FAIL, and it held.

## Check-Infra Debt

Zero ERROR verdicts, but the courier lane accumulated real debt anyway. Four defects, three filed today:

- **#105**, the courier writes outside its lane. It set a task to `complete`, wrote a task file's `## Courier comparison`, and set the next task to `assigned`. It landed on defensible values, which is luck rather than correctness. It also read the verdict of record after being told not to, contaminating the independence a crossing exists to measure.
- **#106**, a malformed vendor response persisted to the verdict stem unvalidated. `T-003-sonnet-r0-codex.json` still fails `validate-verdict.py`. Left unrepaired, because repairing a verdict you also commissioned makes you the author of your own check.
- **#107**, audits cannot be crossed at all. `dispatch-guard` requires a `T-NNN` task in `checking` status, so both audit crossings ran by hand, with the orchestrator executing a check it had also commissioned. Given that CON-audit's crossing was the highest-yield of the run, this is the costliest gap of the four.
- **#84**, commented rather than duplicated: ledger timing is fabricated across the run.

The ledger does not reconcile. Eleven lines against ten courier dispatches. Timing is unusable: `8000ms` self-reported as an estimate, `60000ms` with a `started_at` preceding its own dispatch, `150000ms` annotated "measured from timeout boundary" after an explicit instruction to measure real wall time, and one line at `1905466ms` (32 minutes) that no dispatch accounts for. Four lines carry null tokens. For #34, treat `tokens_in` and `tokens_out` as the only trustworthy fields and the line count as an upper bound.

The stall fired correctly. Two sessions were driving this job concurrently: T-003 shows three worker and three checker dispatches where the lifecycle calls for two of each, and a `T-002: complete` write was reverted underneath the orchestrator. `STALLED.md` caught what no check did. Resolved by the user assigning ownership to one session.

## What the Constitution Missed

It held up well. Sixteen clauses, CON-audit PASS on the first round after the rebuild, zero disputes, and no clause proved unfalsifiable in practice. The two revisions made before the audit, C-6's abort trigger and C-15's argument, were both cases of a clause reasoning about the environment instead of measuring it, and both were caught by the previous run's audit rounds rather than shipping.

Three genuine gaps:

**C-12 anchors to `1f17478`, which cannot see intra-job deletions.** The clause forbids removing or loosening an assertion, measured by diffing `tests/` against the pre-job commit. But an assertion T-003 added and T-004 then deleted is invisible to that baseline, because it never existed at `1f17478`. The codex lane raised exactly this on DEC-audit and it was not upheld, correctly, since three other things blunt it. It's still the one real hole in the clause. A next-job version should anchor to the previous task's completion rather than the job's start.

**C-16 does not reach test-suite comments.** Its broad preamble arguably covers them; its five-item enumeration does not list them. The enumeration was ruled operative and recorded as Settled, because amending would have restarted Phase 0 for polish on strings nothing downstream reads. Defensible, but it means the suite—the largest single artifact this job produced—had its prose unchecked.

**C-10 pins the record paragraph's exact strings, which froze two defects into the deliverable.** T-004's checker found that the shipped paragraph reads `1 links checked`, ungrammatical at count 1, and closes with `Paste this paragraph into the scope's patterns journal.`, an instruction that gets pasted into the journal along with the record. Both strings are pinned verbatim by T-003's C-10 assertions, and C-12 protects those assertions, so fixing either meant editing a protected assertion. The checker escalated instead of quietly resolving, which was right, and it needs a follow-up ticket.

All three are the same trade. A clause that pins an exact string or an exact baseline gets precision and pays in rigidity. For the next Phase 0: pin the property, and pin a literal string only where the string itself is the thing you care about.

## What to Carry Forward

Every defect this job caught in real code had one shape: the implementation was right and the test was vacuous. C-7, C-10, and the C-1/C-2 seam handoff were all assertions that would pass against a broken implementation. None would have been caught by running the suite, because the suite is this job's own deliverable. The constitution said so out loud in its check-methods preamble, and that turned out to be the sentence the whole job leaned on.

Mutation testing found all of them. The next constitution should ask for it by name.
