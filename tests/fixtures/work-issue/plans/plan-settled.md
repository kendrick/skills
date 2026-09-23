# Plan: settled fixture — implements #101

### T1 `only-task`

Narrow the gate so a closed question stops reading as an open one.

Files: work-issue/scripts/check-plan.py

The four that settle an open question: whether A, B, C or D.

## Risks and uncertainties

- The API may rate-limit us; we back off.

## Counting unresolved threads

- Tally each thread the review left without a reply.

## The `open questions` parser

- Reads the list a plan files under that heading.

## Open questions

- [x] Does the cache key include the branch?
  - Yes, decided in review.
- ~~Does the lock file need a version?~~
  - No, the rebase test settled it.

This settles the open question of retries and answers the open question of caching.

## `gh api` unresolved thread counts

- Use the GraphQL endpoint for the count.

## Open decisions

10. ~~Whether retries back off.~~ They do.
    - With a ceiling of one minute.
