# Courier comparison: DEC-audit r3

No task file exists for an audit, so the comparison the #34 standing instruction wants in the task file lives here instead, matching the CON-audit r0 precedent.

Crossing run by the orchestrator directly: `dispatch-guard` refuses a checker-courier dispatch on an audit (tried with both `Audit-ID:` and `Task-ID: DEC-audit`; the gate requires a `T-NNN` task in `checking` status), so the lane command ran per the standing instruction's own steps — empty scratch dir, self-contained brief, evidence collected locally and inlined, ledger line appended. Brief: `log/DEC-audit-r3-codex-brief.md`. Ledger: `log/vendor-calls.jsonl` line 2. Duration 152s, exit 0, no quota event. Note: `dispatches.log` carries one `checker-courier | DEC-audit` line from before the gate refused the Agent-tool route; that dispatch never ran, and this inline crossing is what replaced it.

## Verdicts

- Of record: auditor (anthropic/opus), `DEC-audit-r3.md` — **PASS**, 0 findings, two wording advisories, one question ruled Settled.
- Second opinion: codex lane (openai/gpt-5.6-terra), `DEC-audit-r3-codex.json` — **FAIL**, 6 findings: C-1 (blocker), C-2 (blocker), C-12 (blocker), C-13 (blocker), C-15 (major), C-10 (blocker).

The verdict of record decides; the decomposition stays PASSED and dispatchable. The disagreement is recorded below as dispute-grade input for #34, not routed through the dispute flow.

## Deterministic clauses crossed as pre-run output

C-13's scope check and C-15's key-order check crossed as locally-collected exit codes (both 0), as did the three suite exit codes. Any agreement on those results is by construction and worth nothing as evidence. Neither side disputed them: the courier's C-13/C-15 findings below are about checker *routing*, not check results.

## Findings only the courier raised

All six, in three families:

- **Fragment citation read as full ownership — C-1, C-2 (both blocker).** T-001 cites C-1/C-2 while its check method covers only the fixture seam, with the clauses' own checks landing in T-002. The courier reads a partial-fragment citation as a blocker; the auditor read the same split in r1 and r3 as sound because it is honestly labeled ("seam only, the clauses themselves land in T-002") and the coverage table assigns the clauses' operative checks to T-002. Interpretation difference, not a factual dispute.
- **Single-checker resolution of mixed tasks — C-12, C-13 (blocker), C-15 (major).** The courier holds that script-checked clauses must route to checker-deterministic and that four tasks each running the same global C-12/C-13 guards is a prohibited double-read. The auditor's Routing section settles both on grounds the brief under-carried: a task names exactly one checker, judgment can run a script while deterministic cannot apply a rubric, so mixed tasks resolve to judgment; and C-12/C-13 are deliberate global guards, not fragment ownership claims. Partly a brief artifact — the ownership rubric in the brief prohibited double-reads without carrying the single-checker-per-task rule or the global-guard convention. Discount accordingly for #34.
- **Post-check template edit — C-10 (blocker).** T-004 polishes the record template inside `verify-migration.sh` after T-003's C-10 check has run, without citing C-10 itself. This is the one unique finding with a real kernel: T-004's C-12 fragment diffs `tests/` against `1f17478`, so an assertion T-003 *added* and T-004 then deleted would be invisible to that baseline diff. Three things blunt it short of overturning the PASS: T-004's excerpt item 3 pins "keep the suite's C-10 assertions passing unchanged"; C-12's other half re-runs all three suites at T-004's check; and the `1f17478` anchor is C-12's own clause text — a constitution-level choice already through CON-audit, so the decomposition restates it faithfully rather than introducing it. If the anchor ever gets revisited, this finding is the reason.

## Findings only the checker of record raised

None as findings (PASS), but two advisories and one ruling the courier did not surface:

- Advisory: T-004's C-16 fragment says "revised" where "added or revised" would close a one-comment gap in `verify-migration.sh`.
- Advisory: T-004's House-constraints line contradicts its own excerpt item 5 on where the commit draft lives (resolved only by going back to the constitution).
- Settled ruling: suite comments are outside C-16's five-kind enumeration for every task; re-opening this costs a Phase 0 restart for polish on strings nothing downstream reads.

## Overlap

Zero. No finding, advisory, or ruling appears on both sides. The courier accepted all locally-collected evidence wholesale and disputed no fact, line anchor, or arithmetic — every disagreement is about what the audit rubric requires, not about what is in the tree.

## For the #34 counts

Unique-to-courier: 6 (5 discountable as rubric-interpretation or brief artifacts; 1 with a real kernel, C-10/C-12 baseline anchoring). Unique-to-record: 3 (2 advisories, 1 ruling). Overlap: 0. All counted findings are judgment-rubric; the deterministic clauses crossed as pre-run output and contribute nothing.
