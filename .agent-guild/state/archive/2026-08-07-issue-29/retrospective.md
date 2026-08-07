# Retrospective: kendrick/skills#29

One task, seven dispatches, one catch. The worker passed on its first attempt and
never went back, so every correction in this job landed on the orchestrator's own
work. That is now the second job running with that shape, which is the part worth
carrying forward.

| | |
| --- | --- |
| tasks | 1, complete, 0 retries, 0 escalations, 0 disputes |
| verdicts | 5: CON-audit r0 FAIL, CON-audit r1 PASS, DEC-audit PASS, T-001 PASS, courier PASS |
| catches | 1, all by the auditor |
| dispatches | 7 (3 auditor, 1 worker, 1 checker of record, 2 courier) |
| vendor crossings | 2 on the codex lane, one blocked at 120s and one clean at 43s |

## The Catch

`CON-audit-r0` failed the constitution, and it failed it on the one property the
job existed to establish. I had written eleven clauses about the record's prose and
the assertions pinning it. The auditor traced the cheapest passing worker through
all of them and found the whole set could go green while the suite stayed blind to
the exact defect #29 was filed about: every assertion over the record is a substring
search across the whole captured output, and a substring search cannot tell an
instruction sitting on its own line from one welded onto the record's tail. C-4,
C-5, and C-6 gestured at the vacuity problem. On that property they did not close
it. That became C-11.

Two more findings in the same verdict were nearly as valuable.

The first: my mutation check would have destroyed the deliverable it was checking.
C-6 told the checker to revert with `git checkout -- <path>`. Workers here do not
commit, so the fix is unstaged, and that command restores from the index. It would
have wiped the worker's edit, run the suite against the original script plus the
new assertions, gone red, and reported that the worker had failed C-6, producing a
FAIL the check itself caused. The auditor reproduced it in a throwaway repo instead
of reasoning about it.

The second: a load-bearing factual claim of mine was false. C-10 asserted that
`migration.md:148` was the only doc sentence describing the record. `SKILL.md:406`
says the same thing, and it was not in C-9's allowlist, so a worker who broke it
would have had no legal way to fix it. A false doc was the constitution's only
permitted outcome.

## Where the Work Strained

Nowhere in the build. It strained entirely in Phase 0, which is where it should.

The retry ladder was never touched. No task climbed a tier, no dispute was filed,
and the single worker dispatch produced an artifact that passed eleven clauses on
first inspection, including both mutants, four negative-check falsifications, and a
derivation through logic the worker had just written. Routing it to `worker-craft`
on opus looks right in hindsight: the deliverable was two sentences a person reads
plus three assertions in prescribed shapes, and neither half tolerates a cheap pass.

The real cost was dispatch count rather than tiers. Three auditor runs and two
courier crossings for one task is a heavy ratio, and it bought exactly one catch.
That catch was the difference between shipping a fix and shipping a fix that nothing
would have caught regressing.

## What the Constitution Missed

Nothing shipped broken, so this is about the first draft rather than the final one.

**A clause that pins strings is not a clause that pins structure.** Every
anti-vacuity clause I wrote first constrained the assertions' content: assertions
may not be deleted, needles must be emittable, the suite must survive a
zeroed-counts mutant. None constrained their shape, and the defect lived in the
shape, in whole-capture substring searches. Job #16's retrospective said every
defect it found was "implementation right, test vacuous." This job's near miss
refines that. The test was not vacuous about what it searched for, only about where
it searched. The next Phase 0 on a test-editing job should ask, for each assertion,
what output would still satisfy it, rather than only whether its needle is real.

**Mutation checks need a named non-destructive method, written down up front.**
"Apply the mutant and revert" reads as complete and is not. It has to say where the
mutation happens, and the answer is always a scratch copy. That belongs in a
standing clause template rather than being rediscovered per job.

The `DEC-audit` pass added six amendments, two of them live traps. C-7's text forbade
changing a counter while its check confined every hunk to the record block, so a
worker who computed a plural-noun variable six lines too high would have eaten a
blocker FAIL for a correct fix. And the task excerpt's "Where" section read as the
complete edit list while C-11 required assertions that did not exist yet. Both were
cheap to fix, and neither reached the worker.

## Check-Infra Debt

- **`--ignore` on `check-diff-scope.py` is inert.** It matches by exact string equality, so `--ignore .agent-guild/` never fired. The script already hardcodes `.agent-guild/state/` as in scope at `:111`. Harmless here, but it read as protection that was not there, and it had been riding along in the check command for two jobs. Dropped from C-9.
- **The courier's default timeout sits below the lane's known hang.** The first crossing killed the vendor at 120 seconds. This lane's documented hangs run past 400s, and the retry, same 4910-token brief with a 600s ceiling, completed in 43 seconds. A 120s kill cannot distinguish a hung lane from a thinking one, and it cost a full extra crossing. Worth a ticket against agent-guild.
- **The checker of record died twice on API errors mid-run**, both times as it went to write its verdict after completing every check. Resuming it from its own transcript recovered the derivation instead of paying for a re-run, and it wrote an honest verdict. But a checker that finishes its work and loses it at the write is a real failure mode. Verdicts should be written incrementally, per clause, rather than as one terminal artifact.
- **The stop gate wrote `STALLED.md` during the checker's long run.** Nothing was stuck; the gate blocked four times while a slow checker worked. Removed by hand. A gate that cannot tell "slow" from "stuck" will keep firing on opus-tier judgment checks.

## Disputes

None.

## The Courier, for #34

Five judgment clauses crossed, with the deterministic ones deliberately excluded so
the unique-finding rate would not be driven to zero by method. The far side concurred
on all five and raised zero substantive unique findings. Its one unique entry was a
declaration that it could not attempt the placement-mutant verification in a read-only
context, which is an admission of shorter reach rather than a finding.

That asymmetry is the part worth recording. The checker of record covered eleven
clauses to the courier's five, and the six it did not cross include every one that
required executing something: both mutants, the four falsifications, and the
byte-identity check. On this job the second opinion confirmed judgment the first
checker had already made, and it could not touch the evidence that carried the most
weight. Two crossings bought one usable opinion that told us nothing we did not
already have.

Full comparison, including the blocked crossing and a correction to the retry
courier's own account of it, is in `## Courier comparison` in `tasks/T-001.md`.
