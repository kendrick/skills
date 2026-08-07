# Retrospective: inbox-to-memory, Honest Budget Headroom and a Named tags/themes Check

Job: `kendrick/skills#28`. Two tasks, 12 verdicts, 4 FAILs, 0 disputes, 0 escalations, 0 retries. Both tasks passed their checker on the first attempt.

## Catches

Four FAILs, and all four landed on the orchestrator's own work rather than on a worker's. Every defect this job caught was in the specification, not the implementation.

**Three by the auditor, all on the decomposition.** DEC-audit took three rounds:

- **r0.** The `broken/` fixture's placement was unspecified. The likely branch put it under `notes/`, where `themes` is absent from the key order, so the file would have carried two defects rather than one. Worse, the second would have been invisible: the new check `return`s before the key-order check runs, so a checker applying the "no unrelated failure" rubric sees one failure and passes.
- **r0.** C-9's suite prose was owned by neither task. Both fences excluded `tests/inbox-to-memory-smoke.sh`, the one file both tasks write to.
- **r1.** Pinning the fixture to `_memory/decisions/` falsified an existing suite comment at `:151-155`, which explained the broken scope's off-by-one by calling its lone record defect-free. Nothing in the decomposition caught it. A job that exists because a doc sentence lied about arithmetic would have shipped a test comment lying about arithmetic.

**One by the codex lane, on the constitution.** C-9 promised the prose "goes through the `humanizer` skill's audit-and-revise loop" while its check read only the finished artifact. No observable evidence decides whether the loop ran. The auditor had flagged the same gap twice, at r0 and r1, and passed the clause anyway as a known wart. The lane failed it. Two independent flags was enough to act on: C-9 now grades the artifact, and CON-audit r2 confirmed the rewrite closes the gap rather than relocating it, since the `check:` field was already artifact-only and was not edited.

That is the first time in two jobs the lane changed an artifact.

## Strain

None. Zero retries, zero escalations, both workers passing first time.

The load moved upstream instead. Phase 0 and Phase 1 needed five audit rounds between them against two build tasks that needed none. The pattern from job #16 repeats and sharpens: when the spec is precise, workers do not fail, and the expensive part is making the spec precise.

Worth noting what that precision cost and bought. T-001's brief carried the reachability trap, the fixture's record-vs-note requirement with the masking mechanism spelled out, and the three-things-move-together warning about the suite comment. All three came from audit rounds. The worker hit all three on the first attempt.

## Disputes

None. Two rulings were surfaced by workers in their returns rather than filed as disputes, and both were upheld by their checkers reasoning independently:

- T-001's worker predicted a `comm -23` assertion diff would show two count literals as "lost," and argued they were C-6-mandated updates at the same call site rather than deletions.
- T-002's worker reached the same conclusion about the same two lines, and separately argued that moving the check's precedence fact out of a 69-character table cell into a sentence below the table still satisfies C-5.

Both checkers upheld both. T-002's checker reached the C-7 ruling on its own grounds rather than inheriting T-001's: reading "still asserts the same thing" as "the same literal" would put C-6 and C-7 in direct conflict and forbid adding any fixture at all. It also used a multiset comparison rather than plain `comm -23`, so a duplicate could not hide a deletion.

Workers surfacing a judgment call in their return, instead of either hiding it or escalating it into a formal dispute, is the behavior worth keeping.

## Check-Infra Debt

Zero ERROR verdicts. Two defects found and escalated by checkers, neither covered by any clause, neither held against its worker:

1. **A temp-dir leak.** T-001's new inline scope sets `trap 'rm -rf "$overrun_scope"' EXIT` at `tests/inbox-to-memory-smoke.sh:196`, breaking the file's trap-accumulator idiom. Every prior trap restates all earlier temp dirs; the next one at `:239` drops `$overrun_scope` and nothing picks it back up, so the suite leaks one temp dir per run. No clause reaches it: nothing is asserted away, nothing leaves scope, it is not prose.

2. **A pin weaker than its model.** T-002's `require_text "$contracts" "frontmatter-key-domain"` at `:565` would survive deletion of the table row it exists to pin, because the string now appears twice in `machine-contracts.md`, once in the row and once in the precedence sentence below the table. The `contradiction-fields` pin it was modelled on matches its row uniquely.

The second is the more interesting one. It is the same species as job #16's two blockers, an assertion that survives the thing it exists to catch, but this time it came from the constitution rather than the worker: C-5 set its standard by analogy to a precedent and named no mutant, so an identical construct meets the clause as written. Both are worth a follow-up ticket.

**The courier lane.** Five crossings, one 400s hang with no output and no quota wording, resolved by a retry on a byte-identical brief that finished in 43s. Both are on the ledger, the hang as line 3 with an empty artifact list, because a crossing with no ledger line has an opinion and no price. That is the fourth timeout across two jobs. Total lane cost here: 90,805 input tokens and 6,325 output across five crossings, for one finding that changed an artifact.

Audits still cannot be crossed through the courier path at all (kendrick/agent-guild#107), so both audit crossings were run inline by the orchestrator. Given the CON-audit crossing produced this job's only lane finding, that gap keeps costing the thing it is most likely to catch.

## What the Constitution Missed

Nine clauses, no clause proved unfalsifiable in practice, and the one weakness both providers found was fixed mid-job rather than shipped. Two gaps remain:

**C-5 sets its standard by analogy.** "Pin the row the way the suite already pins `contradiction-fields`" borrows a precedent without stating the property that made the precedent good, which is that the pinned string appears exactly once. The copy is weaker than its model and the clause cannot tell. A clause that says "pin it like that one" inherits whatever the other one happened to get right.

**Nothing in the constitution reaches test hygiene.** The trap leak is real, in code this job authored, and unreachable by every clause. C-7 guards assertions, C-8 guards scope, C-9 guards prose. Nobody guards whether the suite cleans up after itself.

Job #16's retrospective made the matching complaint one level down: a clause that pins an exact string gets precision and pays for it in rigidity. Pinning an analogy has the opposite failure. It costs nothing to write and quietly inherits whatever the exemplar happened to get right, which nobody wrote down. Say what property the check depends on.

## What to Carry Forward

Job #16's defects were all "implementation right, test vacuous," and mutation testing found them. This job's defects sat one level up. The decomposition was wrong in ways that would have produced a vacuous test, and the auditor found them by asking which branch a worker would most likely take, then checking whether that branch satisfied the clause.

That question generalizes, and it is cheaper than mutation testing because it runs before any code exists: **for each instruction, what is the most likely reading, and does that reading satisfy the clause?** The fixture-placement catch came from exactly that. So did the falsified comment.

Mutation testing still earned its place at check time. Both checkers used it, T-001's by relocating the check behind the budget guard in an rsync copy and by neutering the condition to `if false` to hunt for a masked defect. The two want different phases: ask about likely readings while writing the tasks, and mutate once there is something to break.
