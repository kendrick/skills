# Plan: settled fixture — implements #101

### T1 `only-task`

Narrow the gate so a closed question stops reading as an open one.

Files: work-issue/scripts/check-plan.py

The four that settle an open question: whether A, B, C or D.

## Risks and uncertainties

- The API may rate-limit us; we back off.
