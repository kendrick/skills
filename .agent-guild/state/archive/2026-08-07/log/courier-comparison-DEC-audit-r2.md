# Courier comparison: DEC-audit r2 (job #28)

Audits have no task file, so the comparison lives here. Crossing run inline by the orchestrator, same reason as the CON-audit one: `dispatch-guard` refuses `checker-courier` on an `Audit-ID`, filed as kendrick/agent-guild#107. Empty scratch dir, self-contained 39.6 KB brief, script evidence collected locally and inlined, ledger line appended by hand.

Brief: `log/DEC-audit-r2-codex-brief.md`. Ledger: `log/vendor-calls.jsonl` line 2. 27.2s, exit 0, valid JSON first attempt, no quota event.

## Verdicts

- Of record: auditor (anthropic/opus), `DEC-audit-r2.md` — **PASS**, after r0 FAILed on two majors and r1 FAILed on one.
- Second opinion: codex lane (openai/gpt-5.6-terra), `DEC-audit-r2-codex.json` — **PASS**, 0 findings.

**Unique to courier: 0. Unique to checker of record: 0. Overlap: 0 findings, both PASS.**

## What that agreement is and isn't worth

The two sides agree, but they agree on a document the in-family auditor had already reshaped across three rounds. Everything the lane might have caught, the auditor caught first and the orchestrator fixed before this crossing ran:

- **r0**: the `broken/` fixture's placement was unspecified, and the likely branch planted two defects rather than one, with the second masked by the new check's own precedence.
- **r0**: C-9's suite prose was owned by neither task, both fences excluding the file both tasks write to.
- **r1**: pinning the fixture to `_memory/decisions/` falsified an existing suite comment at `:151-155` that explains the scope's off-by-one arithmetic. Nothing in the decomposition caught it, and a job that exists because a doc sentence lied about arithmetic would have shipped a suite comment lying about arithmetic.

A PASS from the lane on the fourth version of a document is not evidence the lane would have found those. It is evidence the document is now clean enough that two providers agree, which is a weaker claim.

## Deterministic clauses

C-8 alone (`check-diff-scope.py`), crossed as pre-run output, exit 0. Agreement on it is by construction and worth nothing. Everything else in this decomposition is judgment-rubric, so the zero-finding result is measured over the sample #34 actually wants — it just happens to be a sample with nothing left in it.

## For the #34 ledger

Two crossings on this job so far. The CON-audit crossing produced one finding that changed a clause; this one produced none. Combined with job #16's record, the pattern that keeps repeating is that the lane's value shows up against **early drafts**, and drops to zero once the in-family auditor has done two or three rounds. Worth testing directly before #34 closes: cross the *first* draft rather than the passing one, and measure whether the lane's findings anticipate the auditor's.

Cost this crossing: 27,219 input tokens, 1,113 output, for zero findings.
