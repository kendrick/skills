# Retrospective: inbox-to-memory Eval Suite (#17)

Seven tasks, 24 verdicts, zero disputes, zero escalations. The suite shipped: `_maintenance/inbox-to-memory/EVALS.md`, its staging script, and four purpose-built fixtures.

## The Catches, and Where They All Landed

Eight FAIL verdicts. Every one came from the auditor, and every one was against my own work.

| Phase | Verdict | What it caught |
| --- | --- | --- |
| CON r0 | fail | C-11's check named `.agent-guild/hooks/test_hooks.py`, which does not exist in this repo. Every task citing that clause would have returned `blocked`. |
| CON r1 | fail | C-1, C-9 and C-10 jointly unsatisfiable. C-7 built on the wrong mechanism entirely. C-8's fixture could legally emit nothing to grade. |
| CON r2 | fail | C-7's check failed the tiebreak case its own text mandated. C-9's enumeration stopped short of the two tokens the suite is built on. C-10 verified only negatives, so a script that copied nothing passed. |
| CON r3 | fail | C-6 put the acknowledgement in the file the rule does not read. C-9's extraction was wider than its registry. C-1 pinned a directory where it needed a filename. |
| CON r4 | fail | C-2's check contradicted C-2's text, so the two halves returned opposite verdicts on the same correct document. |
| DEC r0 | fail | T-004's `check_method` told the checker not to paraphrase and then paraphrased, narrowing four clauses to "already checked upstream" when the conjuncts in question were unreachable upstream. |
| DEC r1 | fail | The fixture-lint instrument I had just added was a no-op on v1 files. |
| DEC r2 | fail | My fix for that was a doc-scoped extraction transplanted onto note trees; a checker running it would have failed a correct fixture. |

Zero task checkers returned FAIL. Seven workers, seven first-attempt passes, no retries, no escalations, no disputes.

That distribution is the run's most useful result, and it is not a compliment to the workers. The verification that paid for itself was verification of the orchestrator. By the time a worker saw a task, five rounds of constitution audit and three of decomposition audit had removed the defects that would have made its work fail: clauses that could not be satisfied, checks that contradicted their own text, and instruments that measured nothing. Phase 2 was quiet because Phases 0 and 1 were not.

## The Defect That Kept Recurring

Four clauses failed for the same shape, a clause whose *check* was stated one notch off from its *text*. Not vagueness. Both halves were specific, and they specified different things. C-7 failed for it twice, C-2 three times across rewrites.

It is a nastier failure than an unfalsifiable clause, because it survives a read-through. Each half looks right alone. Only holding them against the same artifact exposes that they disagree, and when they do, the clause fails correct work about as often as it catches bad work.

What fixed it, every time, was the r3 auditor's prescription: where the skill already ships an artifact that decides the question, cite it instead of paraphrasing it. `SKILL.md:122` decides C-6. `lint-scope.sh:218-230` decides C-9. `scope-decisions.md:21-25` decides C-7. Each clause got shorter and correct in the same edit. Paraphrase was the defect, and the citation was the repair.

The next Phase 0 should audit each clause by reading its text and its check against one hypothetical artifact and asking whether the two can disagree. That is the question that eventually caught C-2, C-7, C-9, and C-10, and it took three separate audit rounds to arrive at it one clause at a time.

Being precise about its reach, because the looser version of this claim is the kind of thing this retrospective exists to distrust: the question catches CON r2, CON r4, and DEC r0 outright. It does not catch the other five. CON r0 was a check naming a file that does not exist, which is an unrunnable command rather than a disagreement. DEC r1 was an instrument I asserted without running. DEC r2 was a procedure whose two halves agreed with each other and were both wrong for the artifact they were pointed at. Three of eight is still the best single question available, and the remaining five want their own: does this command run, and have I watched this instrument do the thing I am claiming it does?

## What the Constitution Missed

**A false claim in prose that no clause covered.** `EVALS.md:110` asserted three places the name `Kestrel` appears in its fixture, and two were fabricated. C-9 governs vocabulary fidelity, and this was not a token. C-8 governs whether a row is decidable against the extract, and that row was decidable. No clause reached it. It was caught only because T-004's checker went past its clause list and logged it anyway, then correctly declined to fail the task for it.

The gap is that the constitution constrained what the document may *grade against* and never constrained whether its explanatory prose is *true*. That is an awkward omission in a document whose whole purpose is catching claims unsupported by their source. T-007 repaired the sentence; the clause is next job's business.

A clause worth carrying into the next Phase 0: every factual claim the deliverable makes about a fixture or about the repository is true of it, checked by opening what the claim names.

**An instrument asserted rather than verified.** I wrote `lint-scope.sh` into four `check_method` fields as the guard against invented tokens. It runs its token pass only over `schema: 2` files, so on a v1 fixture it reads nothing and exits 0 on a token that does not exist. Three task files told their workers the opposite as fact. The rule this earns: run an instrument before naming it in a check, and record what it actually covers rather than what its name suggests.

Two workers responded to the corrected instruction by writing their fixtures as `schema: 2` throughout so the lint's token pass would engage rather than skip. Neither was told to. That instinct is worth carrying forward as guidance.

## Check-infra Debt

- `ledger-append.py` recorded a null-priced crossing. T-007's row carries `tokens_in: null`, `tokens_out: null`, `duration_ms: 0`. Six of seven rows are complete; the seventh has an opinion and no price, which is exactly what the #34 ledger exists to prevent.
- `brief_tokens` does not measure what reaches the model. Across all seven crossings it reads 1,849 to 5,774 while `tokens_in` reads 18,672 to 109,422. This independently reproduces the observation already filed on agent-guild#84.
- The stop gate wrote a false `STALLED.md`. It fired on T-007 while that task's courier crossing was still running, because the gate cannot distinguish slow from stuck. Already agent-guild#111, and cleared by hand.
- The courier lane does not supply its own identity. T-001's crossing was rejected twice for returning `checker: checker-judgment` and a mismatched model string. Stating the required values in the brief and asking the vendor to echo them worked on every subsequent crossing, but that is a workaround living in prompt text.

## The #34 Dual-check Evaluation

Seven crossings: 308,519 tokens in, 15,136 out, 269 seconds. One unique courier finding, one unique checker-of-record finding, one blocked, four confirmations.

The two unique findings fall on opposite sides of one line, and that line is what this run has to offer #34.

The courier's unique finding was C-13's hard-wrap ambiguity on T-001, a question about what a *clause* means, which travels into a brief perfectly. The checker of record's was the `Kestrel` provenance error on T-004, a question about what is *in the repository*, which cannot travel at all. Standing rule 2 forbids handing the far side paths, and that rule is exactly what makes the crossing honest and exactly what blinds it. The vendor was given the false sentence verbatim and unflagged, and did not catch it. It could not have.

So the lane's value does not track clause severity or task importance. It tracks whether the question can be answered from a self-contained brief.

The confirmations were also not equal, and counting them as one thing would mislead the ruling. T-002's and T-007's were agreement. T-006's and T-003's were blind derivations: the vendor reproduced a four-way tier classification from unlabelled, reordered inputs and independently flagged the two-tier case, then sorted sourced from unsourced entity and summary candidates having seen only the emitted extract. An in-family checker structurally cannot supply that, because it already knows the intended answer.

The recommendation for #34 is that a unique-finding rate is the wrong sole metric. It scores T-006's blind reproduction identically to T-007's nod, and those are not the same purchase. Measure instead whether the brief was built to make the far side *derive* something rather than *ratify* it, and route crossings toward questions of reasoning and away from questions of fact about the repo.

One cost note for the ruling. T-004's crossing alone was 109k in, 7.2k out, 183 seconds, roughly a third of the run's total spend, and it returned confirmation. T-006's cost 22k and returned the run's strongest evidence. Spend tracked brief size rather than value.

## Filed Elsewhere

Two skill defects surfaced during the job and were kept out of it, per the constitution's non-goals:

- `lint-scope.sh` `continue`s v1 files out of pass one before they reach `check_links`, so a broken wiki link in a v1 note goes unreported while the same link fails in a v2 note. The comment at `:441` states links "stay on either way," so the code and its stated intent disagree. This is the narrow, real defect. The v1 token blind spot next to it is by design and documented at `machine-contracts.md:65`.
- The courier identity-validation rejection described above.

## What Ships

- `_maintenance/inbox-to-memory/EVALS.md`, four scenarios plus a run procedure and a Grading table with a column for the baseline.
- `_maintenance/inbox-to-memory/eval-scope.sh`, which stages a fixture to scratch, once per run.
- `tests/fixtures/inbox-to-memory/evals/`, holding `contradiction-amend`, `unacknowledged-tension`, `scope-tiers`, and `tier2-summary-entities`.

Nothing is committed. The working tree is in scope at 35 paths and all three smoke suites exit 0.
