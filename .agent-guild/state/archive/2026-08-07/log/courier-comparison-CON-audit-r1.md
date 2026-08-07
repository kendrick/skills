# Courier comparison: CON-audit r1 (job #28)

Audits have no task file, so the comparison the #34 standing instruction wants lives here. Crossing run inline by the orchestrator: `dispatch-guard` refuses `checker-courier` on an `Audit-ID` and requires a `T-NNN` task in `checking` status, which an audit never has. That gap is filed as kendrick/agent-guild#107. Ran per the standing instruction's own steps: empty scratch dir (`x28/`), self-contained 21.6 KB brief, all script evidence collected locally and inlined, ledger line appended by hand.

Brief: `log/CON-audit-r1-codex-brief.md`. Ledger: `log/vendor-calls.jsonl` line 1. 67.2s, exit 0, no quota event.

## Verdicts

- Of record: auditor (anthropic/opus), `CON-audit-r1.md` — **PASS**, after an r0 FAIL on the C-1/C-2 contradiction and C-5's sibling miscount.
- Second opinion: codex lane (openai/gpt-5.6-terra), `CON-audit-r1-codex.json` — **FAIL**, one finding, `major` on C-9. Validated clean on the first attempt.

## Unique to courier: 0. Unique to checker of record: 0. Overlap: 1.

**This is the first crossing across two jobs where both sides raised the same finding, and it changed the artifact.**

Both flagged C-9's process-versus-artifact gap. The clause's text promised the prose "goes through the `humanizer` skill's audit-and-revise loop"; its check reads the finished prose against a pattern list. Nothing observable decides whether the loop ran, so a worker could satisfy the check without the process or run the process and fail the check.

The difference was in what each side did about it. The auditor raised it twice, at r0 and again at r1, as a known limitation and passed the clause anyway. The codex lane failed it. Neither is wrong on the facts, and the disagreement is entirely about whether an unfalsifiable half of a conjunction is a defect or a wart.

Two independent flags was enough to act on. C-9 now reads that the prose "reads as though a person wrote it, judged against the `humanizer` skill's pattern list," with the check unchanged. Re-audited at r2, which confirmed the rewrite closes the gap rather than relocating it: the `check:` field was already artifact-only in r0 and r1 and was not edited, so the set of artifacts that fail C-9 today is exactly the set that failed before. The rewrite removed a promise the check never covered; it did not weaken a check.

## Deterministic clauses

C-8 alone (`check-diff-scope.py`). It crossed as pre-run output, exit 0, so agreement on it is by construction and worth nothing as evidence. The finding above came from a judgment-rubric clause, which is the sample #34 actually wants.

## For the #34 ledger

One crossing, one unique finding, zero overlap by count but a genuine convergence in substance: the courier's sole finding matched an observation the checker of record had already made and declined to fail on. Score it as agreement on the defect and disagreement on its severity, not as a unique catch.

Worth noting against the previous job's pattern, where three of six crossings timed out at 120s: this brief was 21.6 KB and returned in 67s with valid JSON on the first attempt. The briefs that died on job #16 were the ones asking the vendor to judge mutation-discrimination. This one asked for clause falsifiability, which is cheaper. That distinction is probably the useful predictor, not brief size.

## What it cost

22,794 input tokens, 3,336 output. For one finding that changed a clause, on a run where the in-family auditor had already seen the same thing and passed. The honest read is that the lane's value here was not discovery but escalation: it turned a known wart into a fixed clause by disagreeing about severity.
