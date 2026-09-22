# Plan: open-section fixture — implements #101

### T1 `only-task`

Share the plan cache between runs.

Files: work-issue/scripts/check-plan.py

It is still an open question whether the cache is shared.

## Open uncertainties

1. Whether the threshold is right. Unresolved; settled by a live run.
2. ~~Whether the cache key includes the branch.~~ Settled: it does.
