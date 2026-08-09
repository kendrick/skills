# Retrospective: inbox-to-memory — `last_confirmed` write-through (#27)

24 verdicts. 11 PASS, 10 FAIL, 3 blocked, 0 ERROR, 0 disputes. Seven tasks, no retries, no escalations.

**Every FAIL in this job was against my own work.** Eight from the auditor, seven on the constitution and one on the decomposition, plus two from the courier that I ruled did not change the outcome. Not one worker was sent back. That number is the whole retrospective, and it reads two ways.

The generous reading is that the constitution absorbed eight rounds of audit precisely so the workers would not have to absorb any, and it worked. Two independent auditors each built a conforming implementation of `stamp-confirmed.sh` from the script contract alone, in one pass, before any worker saw it. That is about as direct a measurement of spec quality as exists. The sonnet worker then did the same and passed every harness first time.

The suspicious reading is that seven of seven tasks passing first time may mean the checks were tuned to the artifacts rather than to the clauses. The evidence against it is C-13's saboteur, the one check in the job designed to fail a passing artifact. Installed against the shipped suite, it turned the suite red at the right line: the shasum comparison, not an output-shape wobble. So the load-bearing check has teeth. I would not defend the rest as strongly.

## Catches

Ten FAILs, and none of them stopped a defective deliverable, because all ten landed before a deliverable existed. What they stopped was a defective standard.

**Seven CON-audit rounds.** The recurring defect had one shape, and it is the most useful thing this job produced:

> A check that prints its pass string for a reason other than the property it names.

Six occurrences. Four were in check code I wrote specifically to catch that failure mode. The worst two were the same Python bug in two different clauses:

```python
open(p, "w").write(re.sub(..., open(p).read(), ...))
```

Python evaluates `open(p, "w")` before the argument, truncating the file to zero bytes before reading it. The mutated fixture came out empty, empty files classify as v1, v1 records get skipped, and every downstream assertion printed its pass string against a run that had done nothing. That included `order-independent`, the string the whole clause existed to produce. C-4 had the correct read-then-write form the entire time. Two later clauses were written without copying it.

The others, in order:

| Round | The check | Why it passed wrongly |
| --- | --- | --- |
| r1 | C-6's budget half | Passed a nonexistent `--note`, so the run died on a usage error and printed `held` before reaching the budget path |
| r1 | C-13's restore step | `git diff` on an untracked file is always empty, and the stamper is untracked, so the step meant to prove the saboteur was reverted could not fail |
| r4 | C-18's count | `^stamped: ` also matches the closing summary line, so no implementation could satisfy the asserted count |
| r5 | C-13's placement | Searched for literal script paths, but this suite invokes everything through a bound variable, so the "every invocation" set held one assignment and zero invocations |
| r6 | C-13's placement, again | Pinning the variable name narrowed it without closing it. The binding line alone still satisfied both bounds, so a section with no invocations passed |

Execution matters more than reading here. Rounds r2 through r7 were caught by an auditor that built a working stamper and ran the harnesses for real. The reading-only rounds caught structural problems and missed every one of these. **Any future constitution whose clauses carry executable harnesses should be audited by someone who runs them against a reference implementation.** That is the highest-value process change available.

**One DEC-audit round**, three majors, all real. T-002 edited prose the smoke suite pins verbatim without citing the consumer suite, so a reworded sentence would have reddened the suite in a later task's lap with no attribution. T-003 and T-005 both owned `_maintenance/inbox-to-memory/EVALS.md` with no dep between them, and T-005's new scenario flips the answer to C-11's second question for a passage T-003 has to judge, so the two would have reached opposite verdicts depending on dispatch order. T-006's check asked a checker to confirm the repo-wide diff touched one file, which is unsatisfiable once five tasks have landed, because git carries no per-task attribution.

I caught the same two-owners hazard for `SKILL.md` and missed it one file over. That is a habit worth naming: after decomposing, build the file-to-task ownership map explicitly instead of reasoning from task titles.

## What the Checkers Caught That the Workers Missed

Three things, none of which reached a FAIL, all three worth more than the FAILs.

**T-002's overstated sentence.** The new prose claimed a per-input loop would produce "a different record and a different report depending on which file got read first." The report half is right. The record half is false, because the monotonic guard converges the stored date on the maximum whichever order the inputs arrive in. The in-family checker filed it as a non-blocking observation and passed. The courier independently found the same sentence and failed C-17 over it. Both read the artifact identically and split on whether a structurally complete rubric can be satisfied by a false justification.

I let the verdict of record stand, then handed the correction to T-003 as an explicitly scoped addition traceable to the crossing rather than to C-11. That keeps the courier from having acted as a gate while still not shipping a sentence two readers agreed was false. T-003's checker then settled it properly by running the loop both ways against the shipped stamper: two `stamped:` lines oldest-first, one `stamped:` and one `skipped:` newest-first, same final date either way.

**T-003's census floor was under-counted by its own predicate.** C-11 cited twelve candidate locations and warned that the sweep's vocabulary was a predicate rather than a boundary. The checker re-derived the census from scratch, 71 hits, and found `assets/claude-md/journal.template.md:23`, which the clause's own sweep returns and the clause's list omits. Not a category miss; a counting miss inside the category.

**T-005's fixture calibration.** The eval's negative case had to sit close enough to the transcript that a model stamping everything it read would plausibly stamp it. The checker traced the actual bait: the record that gets stamped and the record that must not both turn on the same overnight job, so a model has "the overnight run" in working memory when it opens the second one. That is a stronger reading of the fixture than the task file asked for, and it is what a checker who reads primary sources produces.

## Strain

None, by the usual measures. Zero retries, zero escalations, zero disputes, no `STALLED.md`, no livelock. Every task's first worker at its first tier produced a passing artifact.

Where the job actually strained was Phase 0, and none of the counters show it. Eight audit rounds is not free, and by r5 the auditor twice told me the document was one revision out and was wrong both times. A constitution carrying executable check code is a software artifact and should be budgeted like one. The last three rounds were debugging a single clause's check, not refining a standard.

## Disputes

None filed. Two courier disagreements, both ruled by reading the verdicts directly:

- **T-001**, courier FAIL against PASS. Four findings, none naming a defect in the artifact. Two were real observations about the adequacy of the checks: C-5's order comparison cannot distinguish path-sorted from grouped-by-outcome output, and C-2's shasum establishes content identity rather than an untouched file. One was a scoping observation answered by another clause. One was wrong on the facts. Verdict of record stood.
- **T-002**, courier FAIL against PASS, described above. Verdict of record stood, and the finding was actioned through T-003.

Neither went through the dispute file, which is correct. The regime treats a courier disagreement as dispute-grade input, not as a dispute.

## Check-Infra Debt

Zero ERROR verdicts, but three blocked crossings and one broken render.

**`CON-audit-r7.md` rendered without its frontmatter block.** The JSON was valid and said `pass`, but `dispatch-guard` reads the markdown frontmatter, so the gate could not see the PASS and blocked the first worker dispatch. Re-running `render-verdict.py` fixed it. This is a live trap: the JSON is the record of record, the markdown is generated, and the gate trusts only the generated file. Every checker dispatch after that point carried an explicit instruction to confirm the rendered file opens with `verdict:`. That instruction belongs in the checker agent definitions rather than in my prompts.

## The Courier Lane

The #34 dual-check regime ran on all seven tasks. This is the run's primary evidence and it is mixed in a specific, reportable way.

| Task | Clause types | Outcome | Agreement | Vendor calls |
| --- | --- | --- | --- | --- |
| T-001 | deterministic | fail | disagree | 3 |
| T-002 | judgment | fail | disagree | 3 |
| T-003 | judgment | pass | agree | 3 |
| T-004 | mixed | pass | agree | 3 |
| T-005 | judgment | blocked | n/a | 2 |
| T-006 | deterministic | blocked | n/a | 2 |
| T-007 | deterministic | blocked | n/a | 1 |

Seventeen vendor calls, roughly 797k tokens in, 45k out, 40k of brief.

**Zero defects found across every crossing that landed.** Not one finding named a real problem with a shipped artifact. What the lane produced instead, categorized:

- `inference` ×5, bounding or strengthening the checker's reasoning without changing the artifact. T-004's three are the model case. Asked whether one red saboteur assertion proves all five cases carry real assertions, the lane correctly answered no, then read the source and cleared it anyway.
- `evidence_quality` ×2, both on T-001, both real. C-5's order-independence check genuinely could not distinguish a path-sorted implementation from one grouping by outcome.
- `coverage` ×2, including the best thing the lane produced all job. Asked what a census built on a third predicate would find, and deliberately not shown the two the in-family checker had already surfaced, it named a category nobody had looked in: immutability and mutation vocabulary. Passages claiming a record stays fixed, or that a field is set once at creation, describe the write surface completely while using none of the words C-11's sweep greps for. That is exactly the move the prior job's four-to-eight enumeration failure needed and never made.
- `overlap` ×1, T-002's false sentence, found independently by both sides.

Framing mattered, and this run has evidence for it. Every crossing used `attack`. On T-003 the lane was asked to argue that two specific edits should have gone the other way, and it declined both with reasons. An attack that fails to land is stronger evidence the calls were right than any `confirm` framing could produce. What this job cannot do is compare framings, because it never varied one. The next job should.

**Reliability is the finding the ledger cannot show.** Three of seven crossings failed, in two unrelated modes.

T-005's vendor answered with substantive findings but stamped them `checker: checker-second-opinion` and `model: gpt-5` instead of the pinned `checker-courier` and `gpt-5.6-terra`, twice. The courier correctly refused both, because a verdict whose author cannot be established is not comparison data. This was the crossing most likely to be worth something: a pure judgment rubric on eval calibration, exactly where the lane has previously outperformed an in-family opus checker. Two paid calls, 109k tokens, nothing admissible. Already open as agent-guild#113.

T-006 and T-007 never responded at all, at 120s and 300s. Both timeouts landed on the two cheapest briefs in the job, 3.2k and 2.1k tokens against a run whose largest was 11.7k. Whatever is failing is not brief size, so trimming the brief will not help. Sub-case of agent-guild#84.

Cost per usable opinion is therefore roughly 75% above raw token spend, and `vendor-calls.jsonl` cannot show it, because a blocked crossing records identically to a productive one. That is agent-guild#116, whose acceptance criteria already ask for the fix.

One correction to #116 belongs in the record. It assumes a crossing writes one ledger line regardless of retries, and tells retrofitters to record `vendor_calls: unknown` in the absence of extra lines. **This lane wrote three lines for several single crossings.** The assumption does not hold here, and the retrofit guidance is backwards for it.

## What the Constitution Missed

The most valuable section, and next job's Phase 0 input.

**It could not stop its own checks from lying.** Six occurrences of the pass-string failure mode, four of them in code written to prevent it, and the constitution has no clause governing its own check quality. What actually worked was adding an explicit fixture-integrity guard to each mutating harness, so `fixture intact` or `fixture is v2, nonempty, and has no last_confirmed` announces a wrecked precondition instead of passing silently. That pattern should be a standing rule: any check that mutates its input asserts the mutation landed before it asserts anything else.

Twice, the document pinned a placement it could not justify. C-17 claimed the phase-4 boundary was forced by the batch design, and it is not, since the close of phase 3 satisfies every constraint the script imposes. Two audit rounds went into establishing that. The fix was to name it a convention and forbid the worker from inventing a reason. Generalizing: when a constitution pins an arbitrary choice for convergence, it should say the choice is arbitrary. A clause that dresses a convention as a derivation forces every downstream artifact to repeat the false claim.

It also let semantics drift between two clauses. C-3 and C-5 disagreed about a record named by two groups whose dates straddle its current value, and neither check reached the case, so both stayed green while the texts contradicted each other. The fix was stating resolution once, as an explicit two-stage rule with a six-row branch table, and making both clauses describe the same rule from different sides. **A rule governing more than two clauses belongs in one place, and it needs its own harness.** C-18 exists for that, and it earns its length: it catches a state-leaking implementation that passes C-1 through C-7 individually.

And it grew past the point anyone reads it whole, 600 lines by the end. The auditor's structural finding was blunt and correct: a haiku `checker-deterministic` holds a task file and a code block, not a constitution. A reading index and an instruction to read the script contract plus your own clauses helped. The deeper lesson is that a constitution carrying executable harnesses will keep growing, and those harnesses probably belong in `.agent-guild/scripts/` as named check scripts rather than inline in clause bodies. That would make them testable in their own right, and it would have caught the truncation bug the first time anyone ran them.

One thing the constitution got right is worth repeating. Pre-ruling boundary cases inside a judgment clause: C-11 named two passages and said outright which one passes and which fails, with reasons. Both the worker and the checker landed on those two exactly as ruled, and neither spent any effort re-litigating them. A judgment rubric that pre-decides its own hardest edge cases converges. One that leaves them to the reader does not.

## Follow-Ups

- `assets/claude-md/journal.template.md:23` is missing from C-11's twelve-location floor, under the clause's own predicate. Not fixed, because the clause's obligation did not reach it.
- `inbox-to-memory/scripts/migrate-scope.sh:348-349` now disagrees in wording with `migration.md:37`, which T-003 narrowed. The script is a frozen non-goal for this job, so it was surfaced rather than fixed.
- `tests/fixtures/inbox-to-memory/README.md:3` says "Three scopes" above four bullets. Pre-existing, declared a non-goal at Phase 0, still true.
- The rendered-verdict frontmatter check should move from my dispatch prompts into the checker agent definitions.
- The lane evidence goes to agent-guild#34 as a comment. The mechanisms are already open at #113, #84, and #116.
