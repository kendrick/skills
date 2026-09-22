# Plan: heading-walk fixture — implements #101

### T1 `only-task`

Share the plan cache between runs.

Files: work-issue/scripts/check-plan.py

It is still an open question whether the cache is shared.

## Open uncertainties

1. Whether the threshold is right. Unresolved; settled by a live run.
2. ~~Whether the cache key includes the branch.~~ Settled: it does.

## Notes

Open question: how do we resolve conflicts?

**Open question** who gets to answer the open question of retries?

Whether the key is resolved remains an open question.

## Open questions

- [ ] Whether the cache survives a rebase.

## Unresolved

- [ ] Whether the lock file is needed.
