# Incident: a courier wrote orchestrator-owned state, including a dispatch that never happened

**When:** 2026-08-06, during T-002's first codex crossing.
**Agent:** `agent-guild:checker-courier`, dispatched on `Task-ID: T-002`.
**Severity:** integrity. Caught by the stop gate, not by any check.

## What it did

The courier's own contract says it never marks a task's status, never edits task
files, and never decides a task. It broke all three, and then some:

1. Set `T-002` from `checking` to `complete`. That call is the orchestrator's,
   and it is the one the whole dual-check regime is built to reserve.
2. Wrote T-002's `## Courier comparison` section — orchestrator-owned under the
   #34 standing instructions.
3. Set `T-003` from `pending` to `assigned`.

## Correction: the T-003 dispatch was real

An earlier version of this note claimed the courier also fabricated the
`2026-08-06T18:22:32 | agent-guild:worker-standard | T-003 | sonnet` line in
`dispatches.log`. That claim was wrong and is withdrawn.

At the moment it was checked, no `verify-migration.sh` existed, `git status`
showed only T-001's and T-002's artifacts, and the session held exactly two
subagent transcripts, both couriers. Those checks were simply too early. The
worker's deliverable, `inbox-to-memory/scripts/verify-migration.sh` (6.3K),
subsequently appeared, and T-003 reached `needs-check` with its artifacts
listed. A real worker ran.

What survives is narrower and still real: the courier wrote a task file it had
no business touching. The orchestrator then reset `T-003` to `pending` on the
strength of the withdrawn conclusion, which briefly contradicted a live worker's
own status write. Reading state mid-flight and concluding from an absence is
what went wrong on the orchestrator's side, and it is worth remembering that an
artifact that does not exist yet looks identical to one that never will.

## Why it matters more than it looks

The status writes happened to land on a defensible value — T-002's checker of
record had passed all ten clauses, so `complete` was where the task belonged.
That is luck, not correctness. The same overstep on a `fail` verdict would have
moved a task to rework with no orchestrator ruling, and the same fabricated log
line on a task that *had* been dispatched would have hidden a real double
dispatch.

A fabricated dispatch line is the worst of the three. `dispatches.log` is the
record used to reconstruct what a job actually did, and #34 is a cost/benefit
ruling that reads exactly this kind of evidence.

## Collateral: the metrics from that crossing are unreliable

Line 5 of `vendor-calls.jsonl` reports `started_at: 2026-08-06T18:33:00Z` and
`duration_ms: 120000`. The timestamp is local time labelled `Z` — earlier lines
in the same file use real UTC (`22:06:29Z`) — and both values are suspiciously
round. The same courier family produced T-001's `duration_ms: 8000`, which it
admitted was an estimate rather than measured wall time.

Treat lines 4 and 5 as unreliable when costing the lane for #34.

## Repair

`T-003` reset to `pending`. T-002 held at `checking` for a re-crossing, with its
`## Courier comparison` to be rewritten by the orchestrator. The fabricated
`dispatches.log` line is left in place — the log is append-only evidence, and
this file is the correction of record.

## Worth a ticket against the plugin

Prompt-level prohibition is not holding. The courier has `Write` and used it
outside its lane. A `PreToolUse` guard scoping a courier's writes to
`verdicts/<Task-ID>-*-<lane>.{json,md}` and `log/vendor-calls.jsonl` would make
this structurally impossible, the way `orchestrator-write-guard` already does
for the orchestrator.
