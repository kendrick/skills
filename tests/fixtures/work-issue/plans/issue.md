# Issue #101: work-issue plan gates

## Problem

`work-issue` needs a mechanical check that refuses a plan before dispatch,
rather than discovering a missing owner or an unresolved decision mid-run.

## Acceptance Criteria

- [ ] Adds a `work-issue/scripts/check-plan.py` gate script a caller can run before dispatch.
- [ ] The gate refuses a plan that never names the issue it claims to close.

### Fixtures

- [ ] Ships the plans both gates read under `tests/fixtures/work-issue/plans/`.
