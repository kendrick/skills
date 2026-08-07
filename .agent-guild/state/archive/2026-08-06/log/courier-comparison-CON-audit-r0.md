# Courier comparison: CON-audit r0

No task file exists for an audit, so the comparison the #34 standing instruction wants in the task file lives here instead.

Crossing ran retroactively (the standing instruction arrived after the audit dispatch), by the orchestrator directly: `dispatch-guard` correctly refuses a checker-courier dispatch carrying an Audit-ID, and no `T-NNN` task exists yet, so the lane command was run per the standing instruction's own steps (empty scratch dir, self-contained brief, evidence collected locally, ledger line appended). Brief: `log/CON-audit-r0-codex-brief.md`. Ledger: `log/vendor-calls.jsonl` line 1.

## Verdicts

- Of record: auditor (anthropic/opus), `CON-audit-r0.md` — **PASS**, 0 findings. One precondition (yq absent on this machine; 12 clauses `blocked` until installed), four advisories.
- Second opinion: codex lane (openai/gpt-5.6-terra), `CON-audit-r0-codex.json` — **FAIL**, 6 findings: C-3 (major), C-4 (blocker), C-6 (major), C-8 (major), C-15 (major), C-16 (major).

The verdict of record decides; the constitution stays PASSED. The disagreement is recorded below as dispute-grade input for #34, not routed through the dispute flow.

## Findings only the courier raised

All six, and they share one shape: each says a clause's *check* under-tests its *text*. None disputes a factual claim, a line number, or the arithmetic — the locally-collected evidence was accepted wholesale.

- **C-3**: check traces summary claims to the extract but never verifies the one-line requirement.
- **C-4**: check covers Tier-1-only apply and report grouping, but not that approval actually works per-file *and* as a batch.
- **C-6**: check requires nonzero exit and attribution, but not the reported failure *count* the text promises.
- **C-8**: check pins the committed-rename case only; deletions and separate naming go untested.
- **C-15**: the word-count tripwire doesn't guard the premises the argument rests on (summary/entities membership in the order, comment-free rendering, the `has_schema_key` skip).
- **C-16**: "went through the humanizer loop" is process, not falsifiable from the artifact; the pattern list and surrounding voice weren't in the brief.

## Findings only the checker of record raised

- The yq environment precondition (courier couldn't see it as a finding — it was handed to it as evidence).
- Advisory: C-6's rationale assumes a yq preflight in verify-migration.sh that no clause text requires — put it in task acceptance.
- Advisory: C-2's "leaves the note unmodified" is unambiguous only under the settled two-run shape — the task should state the shape.

## Overlap

One partial: both flag C-6's check as under-specified relative to its text (auditor as advisory, courier as a major finding). Nothing else overlaps.

## Deterministic clauses

C-13 and C-15 carry deterministic checks, run locally and inlined in the brief. Agreement on their *results* is by construction and worth nothing as evidence. The courier's C-15 finding is not about the result — it's a judgment-level critique of the check's coverage — so it does count as a unique finding.

## Orchestrator reading

The courier grades check-method completeness stricter than the house rubric, which asks whether a checker *could* apply the check, not whether the check exhausts the clause. On that rubric the PASS holds. But four courier findings are cheap to honor at decomposition time and I will fold them into task acceptance criteria: the one-line summary assertion (C-3), an approval-path test per file and batch (C-4), asserting the reported failure count (C-6), and a committed-deletion case beside the rename (C-8). The C-16 finding is inherent to process clauses and the check already judges the artifact instead; C-15's tripwire is a tripwire, not a proof-checker — its premises are documented in the clause text and checked by the suite the clauses above require.
