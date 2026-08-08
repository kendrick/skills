# Retrospective: link-check v1 notes (#32)

Four tasks, seventeen verdicts, no disputes, no retries, no escalations. The fix shipped: `check_links` now runs on v1 notes, the smoke suite pins it four ways, and eight prose passages across four files stopped contradicting the code.

## The Catches, and Where They Landed

Seven FAIL verdicts. Five came from the auditor, every one against my own work. The other two came from courier crossings, which have no authority to fail anything.

| Phase | Verdict | What it caught |
| --- | --- | --- |
| CON r0 | fail | C-7 was unsatisfiable: it demanded trap completeness no worker could reach without editing code the non-goals forbid. C-8 checked whether a sentence could be *tied* to a line rather than whether the line made it *true*. C-9 contradicted itself and C-1. |
| CON r1 | fail | My repair to C-7 opened the reverse gap: checking only the last added trap lets a mid-chain leak hide behind a complete final one. Also: my `grep` instability finding had the right conclusion and the wrong mechanism. |
| DEC r0 | fail | A fifth false sentence existed and the constitution forbade fixing it. T-002 and T-003 could not run concurrently: their edits are disjoint, but their checks are not. |
| DEC r1 | fail | A sixth false sentence, and the best one: it was already false before this job started. |
| DEC r2 | fail | C-8's rubric was sentence-shaped and structurally could not reach the table in location six, so a checker could pass it without opening the artifact the clause calls load-bearing. |
| T-003 courier | fail | C-10 read strictly: one sentence states a rule with no reason, beside a clause that carries one. Comparison data only; the checker of record passed the task. |
| T-004 courier | fail | C-10 again, on the same sentence-versus-passage split, plus a real overlap between passage seven's reason and the block five lines below it. Comparison data only. |

Zero task checkers returned FAIL. Four workers, four first-attempt passes.

That distribution repeats #17's and has the same cause. By the time a worker saw a task, two rounds of constitution audit and three of decomposition audit had removed the clauses it could not have satisfied. Phase 2 was quiet because Phases 0 and 1 were not.

## The Defect That Kept Recurring

The #17 run's recurring defect was a clause whose check was stated one notch off from its text. That happened here too, and I caught myself committing it: T-002's `check_method` said "confirm **each** new case would fail against the pre-fix lint" in its preamble and "its failure must name **one** of the new cases" in the recipe below. Only the second is satisfiable. Both the worker and the checker noticed independently, and the executable half governed, so it cost nothing—but it held by luck, not design. Three constitution rounds went into eliminating that defect from clauses, and nobody was auditing my task files to the same standard.

The defect that actually shaped this run is different, and the auditor named it better than I did. I asked whether four rounds of findings against T-003 meant the task was still wrong or whether prose is simply fuzzy. It rejected both:

> T-003 is the only task in the cut whose correctness depends on **completeness** rather than on **accuracy**, and completeness defects fail open.

T-001's correctness rests on the internals of one file it owns. T-002's on one file plus an idiom. T-003's rests on a census of the whole repository. An incomplete list is indistinguishable from a complete one by inspection—nothing in the artifact signals the omission. A wrong line number fails closed: the worker opens `:414`, sees a `for` loop where a quoted block should be, and notices. Every one of T-003's four defects was found by running an instrument, none by reading carefully, and none was a matter of taste. The task was not fuzzy. It was wide.

The rule that falls out, for decomposition rather than for restructuring: **when a task's brief asserts an enumeration over territory the task does not own, re-derive that enumeration before dispatch, by a method that would fail differently from the one that produced it.** It would have caught three of the four.

## What the Constitution Missed

**The enumeration, twice, and it is still not closed.** The issue named four prose locations. I built C-8 on that list and then audited hard *inside* it for three rounds, asking whether each clause was right and never whether the list was complete. The fifth was found by grepping the claim's phrasing. The sixth could not have been—it makes the same claim inverted, "links are checked in all three rows" rather than "the lint never flags them"—and surfaced only when the auditor read every sentence containing "lint" across the skill.

The sixth was the most valuable finding of the job. `machine-contracts.md:21` was **already false before this job started**, in exactly the way the issue is titled after, sitting in the document the offending comment points at. And it contradicted `:7` in the same file. Repairing `:7` alone would have shipped a document disagreeing with itself.

Then T-003's checker, reading past its clause list, found a seventh and eighth: `lint-scope.sh:2-3` still said the script checks "every v2 note and record," and `:414-415` still said pass one caches "each v2 body." Both were false as of T-001, and T-004 repaired them.

The auditor's third sweep was rigorous, structural, and correctly bounded, and it searched for *passages describing what a file carrying no `schema` key receives*, a predicate lifted from C-8's own framing. These two sentences describe what the **script** does. An exhaustive search under a predicate inherited from the artifact being audited returns a confident, bounded, incomplete answer. Re-deriving an enumeration is not enough if you never question the category it enumerates over.

**A clause that substituted a constraint for a specification, and put the constraint in the wrong file.** For location six I deliberately left the form open—a Links column, a footnote, whatever the opus worker judged best—and wrote a reader test in place of a specification. But I wrote it only into T-003's excerpt, which the checker has no reason to read closely, while C-8's check kept the sentence-shaped rubric that structurally cannot reach a table. The worker was bound by a constraint its checker had no instruction to apply. **Latitude is only sound when the thing standing in for a specification is itself checkable, and the check is where it belongs.**

**Two counts inherited rather than derived.** The non-goals said "the four body-grammar checks behind `has_v1_body`"; the gate wraps six. T-003's caution said the smoke suite pins "15 literal strings"; it is 14 call sites and 22 strings. Both came from copying the issue's framing instead of running `grep -c`.

## Check-infra Debt

**The vendor-call ledger has merged two jobs.** `vendor-calls.jsonl` holds the #17 run's seven rows and this job's four. Both runs number tasks from T-001, the ledger carries no job identifier, and the artifact paths are byte-identical because live state is wiped between runs. Two rows are keyed `T-001` and only their timestamps separate them. The cause is a missed archive step: the three older archives each carry their own `log/vendor-calls.jsonl`, and the #17 archive has no `log/` directory at all. #34 is a cost ruling and this is the evidence it rules on.

A courier stamped local time as UTC. T-002's crossing was recorded at `13:15:46Z` for what was `18:15:46Z`, which sorted it before a crossing that happened earlier. Corrected by hand. That courier also appended its own ledger row, which standing rule 5 reserves to the orchestrator.

No courier measured its own call either. All four durations were reconstructed from artifact mtimes, and the one self-reported figure disagreed with the artifacts by better than 2x. One courier reported a duration of `null` outright.

**`brief_tokens` still does not measure what reaches the model.** It read 1,494 against 19,326 billed on T-001, a 13× gap. That is agent-guild#84 reproducing for a second run.

**The stop gate wrote two false `STALLED.md` files**, both while a commissioned agent was mid-flight: once during a DEC-audit, once during T-003's courier crossing. It cannot distinguish slow from stuck. Already agent-guild#111. It also blocked the turn repeatedly on tasks whose `deps` were unmet, which is a state the gate treats as actionable and is not.

## The #34 Dual-check Evaluation

Four crossings: 138,524 in, 14,312 out, 273 seconds. Four unique courier findings, five unique checker-of-record findings, two disagreements, no blocks.

The crossings were sampled to test one hypothesis rather than to maximize coverage: that the lane's value tracks whether a question can be answered from a self-contained brief, and not clause severity or task importance. The result confirms it from both directions inside a single job.

T-001 and T-002 sampled clauses whose decisive half required an experiment against the repository. Both produced zero unique courier findings, while the checker of record produced three—every one obtained by planting a defect and observing the result. It refused to accept that refuting `link-broken` on an id-fallback target proved the fallback worked, since blanket silence would refute it equally, so it planted a link that should *not* resolve and confirmed only that one was reported. On T-001 the courier reached the same verdict on the `index` variable but wrote that the evidence "identifies no subsequent use, so no later check is *shown* to be affected"—correctly hedged, because it had the diff and could not confirm the absence of a later read.

T-003 and T-004 sampled C-10, the one clause needing no repository access. On both, the courier found something the opus checker of record missed, from identical evidence.

So the lane is not weaker than an in-family checker. It is blind in a specific place. Pointed at reasoning over inlined evidence it catches what opus misses; pointed at facts about the repository it cannot participate at all. **The routing rule is to choose the crossing's clause by whether a brief can carry the whole question, and to stop reading a zero unique-finding rate as evidence about the lane when the sampled clause was one the lane could never have answered.** #17 reached the first half of this by accident; this run reached both halves on purpose, for a fifth of the tokens.

T-004 then crossed C-10 a second time on purpose, to find out whether that disagreement was a one-off. It was not. The courier failed C-10 again, on the same sentence-versus-passage split, plus one finding that is not scope ambiguity at all: passage seven's stated reason overlaps the unchanged block five lines below it, which the worker had explicitly claimed it avoided. Reading both, the overlap is real. So the lane produced a genuine unique finding on each of the two crossings where it could see the whole question, and none on the two where it could not.

That crossing also cost 79,664 input tokens against roughly 19,000 for each of the others, because its brief inlined neighbouring context so the far side could judge duplication. `brief_tokens` read 2,605, a 30x gap against what was billed, where T-001's was 13x. Spend tracks brief size rather than task size, and nothing in the ledger predicts it.

One note on the disagreements themselves, and it is the clearest clause-level lesson of the job. The courier is right on a strict reading and the checker is right on a holistic one, because C-10 is ambiguous about its own scope—"each rewritten comment and doc **sentence**" invites the sentence-level reading the courier took, while "read each rewritten passage against the paragraphs around it" invites the checker's. The clause is the defect, not either agent.

## What Ships

Five files, uncommitted:

- `inbox-to-memory/scripts/lint-scope.sh`, 19 lines routing v1 files to `check_links` and nothing else, plus two rewritten comments.
- `tests/inbox-to-memory-smoke.sh`, 70 lines, four cases, two scratch scopes, both traps preserving the accumulator convention.
- `inbox-to-memory/references/machine-contracts.md`, the opening claim, and the generation table with a fourth column.
- `inbox-to-memory/references/migration.md` and `inbox-to-memory/SKILL.md`, one sentence each.

All three suites exit 0. Nothing is committed and nothing is pushed.

**Open, and the user's call:** `lint-scope.sh:2-3` and `:414-415` are the seventh and eighth stale sentences. Fixing them means a T-004 and a C-8 amendment; shipping without them means filing an issue that is honest about leaving two known-false comments in the file the job just repaired.
