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

## Later tasks

### T2 Count unresolved threads

- Files: work-issue/scripts/run-state.py
- Add a field for the count.

### T3 Rename the `unresolved` flag

- Files: work-issue/scripts/run-state.py
- Keep the old name as an alias.

This settles the open question of retries, but the open question of caching remains.

## Open items

- [x] Does the cache key include the branch?
  - Yes, decided in review.
- Whether retries need jitter.
  - Probably, but nobody has measured it.
- ~~Whether the lock file needs a version.~~
  - No, the rebase test settled it.

Nothing below this paragraph is settled.

  - Whether the cache survives a restart.

## Task 4: parse the open questions section

- Files: work-issue/scripts/check-plan.py
- Read each list item under the heading.
