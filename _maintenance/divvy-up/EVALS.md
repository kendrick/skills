# divvy-up—evals

The smoke test (`bash tests/divvy-up-smoke.sh`) pins the artifact: files present, load-bearing strings intact, `check-waves.py` behaving on fixed input. It says nothing about whether the waves actually work, because that needs live subagents. This file is the procedure for that.

## The Fixture

A throwaway repo and a small plan: one shared-types task, and three tasks that each consume those types. One of the three also touches a file a fourth task owns.

## Scenarios and Pass Criteria

| # | Scenario | Passes when |
|---|---|---|
| 1 | Wave computation | Wave 0 holds the shared-types task alone; the three consumers land together in wave 1. |
| 2 | Serialization over overlap | The two tasks sharing a file land in different waves, with no "be careful" note anywhere in the table. |
| 3 | Validation is a hard stop | `validate` exits non-zero on a hand-edited table with a same-wave overlap, and the run stops rather than warning. |
| 4 | Escalation on failure | A haiku task that fails its done-when is re-dispatched alone on sonnet, with the failure text attached, and the paths it owned were reverted first. |
| 5 | Gate catches out-of-territory writes | A subagent that writes outside its owned paths is caught by `owners` at the gate, not by a human reading the diff. |
| 6 | `--max` splits waves without touching ownership | `--max 2` splits a five-task wave into three waves without changing any ownership. |
| 7 | Guild deference | In a repo with `.agent-guild/`, the run emits the table and stops, naming `/agent-guild:job`, and dispatches nothing. |
| 8 | Model always named | Every dispatch names its model explicitly. A run where any dispatch omitted the model fails this, whatever else it produced. |
| 9 | Ambiguity stops the task | A task the plan leaves ambiguous is written up with its question rather than given a model and dispatched. |

## Grading the Delta

The baseline is the same plan executed by one session with no skill. Compare wall-clock to the last passing gate, spend by model rung, and how many defects the final review caught in each. Note the honest confound: the wave run and the baseline can produce different code, so a defect count is a weak comparison unless the plan is tight.

## What These Evals Do Not Cover

Derivation quality on real plans—the fixture's tasks are disjoint by construction, and a plan with murkier boundaries derives differently. Cost measurement is also out of reach here, since the harness does not report per-dispatch spend.
