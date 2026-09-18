# Plan: work-issue plan gates (fixture)

Implements `work-issue/scripts/check-plan.py` and `check-inflight.py` for
issue #101.

### T1 `check-plan-script`

Build the plan gate.

Files: work-issue/scripts/check-plan.py

### T2 `check-inflight-script`

Build the cross-run gate.

Files: work-issue/scripts/check-inflight.py, work-issue/scripts/run-state.py

### T3 `fixtures`

Build the fixtures both scripts read in their tests.

Files: tests/fixtures/work-issue/plans/

## OpenAPI changes

- [ ] Regenerate the client once the endpoint lands.

## Waves

| Wave | Task | Files owned | Model | Done when | Constraints |
|---|---|---|---|---|---|
| 0 | check-plan-script | work-issue/scripts/check-plan.py | sonnet | check-plan.py exists | |
| 0 | check-inflight-script | work-issue/scripts/check-inflight.py, work-issue/scripts/run-state.py | sonnet | check-inflight.py exists | |
| 0 | fixtures | tests/fixtures/work-issue/plans/ | sonnet | fixtures exist | |
