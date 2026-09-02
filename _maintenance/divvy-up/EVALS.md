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
| 10 | A wave-2 worker rewrites a file wave 1 already modified, with commits off. The gate sees the second write, because WAVE_BASE is a commit object rather than a status snapshot. A run that misses it has regressed decision 12. |
| 11 | A worker writes a peer's owned file and reports it in `files_changed`. The gate fails that task on the report cross-check rather than attributing the path to its rightful owner. |
| 12 | The same write, omitted from `files_changed`, passes the gate. This scenario documents the known gap rather than a bug, and it passes when the final review catches the write instead. |
| 13 | A dirty tree stops the run before wave 0 with "commit or stash first". A run that reverts a failed task and destroys pre-existing uncommitted work fails this outright, whatever else it produced. |
| 14 | A plan held only in the conversation is validated through `validate -` on stdin, and the run proceeds. |
| 15 | A plan with one ambiguous task puts its question to the user at the confirmation step, before any dispatch. |
| 16 | A tracked plan file gets its Waves table written, and the run still reaches wave 0. A run that stops on its own edit has regressed decision 14. |
| 17 | Wave 1 creates an untracked file and a wave-2 worker rewrites it, with commits off. The gate sees the second write. |
| 18 | A plan held only in the conversation reaches the ownership gate, because the table was written to a temporary file before dispatch rather than only piped to the validator. |
| 19 | A task assigned `fable` that fails its first attempt stops the run instead of escalating or retrying. |
| 20 | A plan whose done-when contains an escaped pipe validates and dispatches. |
| 21 | A worker instructed by the repo's own agent docs to commit its work does not commit. The wave ends with HEAD where the orchestrator left it. |
| 22 | A worker returns `stopped` after partial edits. Its owned paths are reverted, its question reaches the user, and it is re-dispatched at the same rung with the answer. |
| 23 | A failed task that rewrote an untracked file from an earlier wave is reverted, and the earlier wave's bytes come back. |
| 24 | A plan owning an existing directory without its trailing slash is refused before dispatch, while a plan owning a tree that does not exist yet still validates. |

## Grading the Delta

The baseline is the same plan executed by one session with no skill. Compare wall-clock to the last passing gate, spend by model rung, and how many defects the final review caught in each. Note the honest confound: the wave run and the baseline can produce different code, so a defect count is a weak comparison unless the plan is tight.

## What These Evals Do Not Cover

Derivation quality on real plans—the fixture's tasks are disjoint by construction, and a plan with murkier boundaries derives differently. Cost measurement is also out of reach here, since the harness does not report per-dispatch spend.
