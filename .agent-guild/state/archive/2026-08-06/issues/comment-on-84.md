More evidence from a second Claude-host run, the `kendrick/skills#16` job. Same lane, same improvisation, and the ledger came out wrong in new ways — which is worth recording because it shows the failure isn't one bad courier, it's the absence of a shared writer.

Six crossings, `vendor-calls.jsonl`:

```
CON-audit   66352 ms  exit 0    23179 in /  3403 out
DEC-audit   43142 ms  exit 0    30544 in /  1838 out
DEC-audit  152088 ms  exit 0    13425 in /   849 out
T-001        8000 ms  exit 0    20370 in /   543 out
T-002      120000 ms  exit 143
T-003       60000 ms  exit 0    27854 in /  2049 out
```

Three problems on top of the ones already in this issue:

**Durations are invented.** T-001's `8000` was reported by the courier as an estimate rather than measured wall time — it said so in its own return. T-003's `60000` is round against a crossing whose artifact took roughly 275s to appear, and its `started_at` (`16:59:00Z`) *precedes* the dispatch that produced it. A separate line carried local time labelled `Z` while earlier lines in the same file used real UTC. Every one of these is a courier deciding for itself what to write into a field the ledger treats as measured.

**Duplicate lines with no way to tell which crossing is which.** Ten lines for six crossings — DEC-audit twice, T-002 three times — because re-runs append rather than supersede, and nothing in a line distinguishes "the crossing that produced the verdict on disk" from "an earlier attempt that was overwritten." Reconstructing what actually happened needed `dispatches.log` alongside it.

**The timeout pattern is not about brief size.** Three of six crossings died at the 120s wall. But the 54KB DEC-audit brief finished in 43s while a 30KB brief timed out twice in a row. What the timed-out briefs had in common was the *question*: they asked the vendor to judge whether a test assertion would still pass under a deliberately broken implementation. That's the most expensive reasoning to ask for and, on this run, the most valuable — the in-family checker found two real blockers that way, and both were assertions that passed against a mutant. So raising the ceiling isn't obviously wrong here; trimming the payload wouldn't have helped, because the payload wasn't the problem.

For #34's purposes: treat `duration_ms` and `started_at` on this run as unusable, and the line count as an upper bound rather than a crossing count. `tokens_in`/`tokens_out` are the vendor's own numbers and are the part worth keeping.

Two related defects filed separately since they're not about the missing script: #106 (a malformed vendor response persisted to the verdict stem unvalidated) and #107 (audits can't be crossed through the courier path at all, so both crossings against the orchestrator's own work were run by hand).
