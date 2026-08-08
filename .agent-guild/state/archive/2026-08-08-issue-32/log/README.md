# Why this log is a slice

`dispatches.log` and `vendor-calls.jsonl` accumulate across jobs in live state, so neither file belongs to one run. What sits here is this run's portion, extracted by timestamp: dispatch lines 32 through 45 of the live file, and the four ledger rows started at or after `2026-08-08T17:00:00Z`.

The live files were deliberately left whole rather than split. Seven ledger rows from the #17 run are still sitting in `state/log/vendor-calls.jsonl` with no job identity, which is exactly the defect [agent-guild#117](https://github.com/kendrick/agent-guild/issues/117) describes and reproduces. Moving them out would make that issue's premise stale before anyone reads it. They get backfilled where they are, as that issue's acceptance criteria require.

So these four rows exist in two places for now: here, and in the live ledger. Once #117 lands and the rows carry a job, the live copy can be trimmed to whatever the next run needs.

The #17 archive next door has no `log/` at all. That omission is what let its rows reach this run in the first place, and it is the second half of #117.
