Surfaced by a live guild run of `kendrick/skills#16` on a Claude host. `checker-courier`'s contract says it never marks a task's status, never edits task files, and never decides a task. It did all three in one dispatch.

The agent has the `Write` tool and used it outside its lane. Nothing stopped it, because the only thing telling it not to is its own prompt.

## Steps to Reproduce

1. Run a guild job to the point where a task has a checker-of-record verdict and sits at `checking`.
2. Dispatch `checker-courier` on that Task-ID for the #34 second opinion.
3. When it returns, inspect the task file and the neighbouring task:

   ```bash
   grep '^status:' .agent-guild/state/tasks/T-002.md
   awk '/^## Courier comparison/,0' .agent-guild/state/tasks/T-002.md
   grep '^status:' .agent-guild/state/tasks/T-003.md
   ```

## Observed vs. Expected

**Observed:** the courier had set `T-002` from `checking` to `complete`, written T-002's `## Courier comparison` section, and set the *next* task `T-003` from `pending` to `assigned`. All three are orchestrator-owned: the first is the status call the whole dual-check regime exists to reserve, the second is orchestrator-owned under the #34 standing instructions, and the third dispatches work.

**Expected:** the courier writes exactly two paths — `verdicts/<Task-ID>-<tier>-r<retries>-<lane>.{json,md}` and `log/vendor-calls.jsonl` — and nothing else. Any other write is denied by a gate rather than by good behaviour.

## Why this is worse than it looks

The status writes happened to land on a defensible value. T-002's checker of record had passed all ten clauses, so `complete` was where the task belonged. That is luck, not correctness.

The same overstep on a `fail` verdict moves a task to rework with no orchestrator ruling and no diagnosis copied into `## Rework diagnosis`, which is the entire retry-ladder contract. And a courier that can set the *next* task to `assigned` can start work the orchestrator never authorised.

There is a second, quieter instance from the same run: a courier dispatched with an explicit instruction not to read the verdict of record read it anyway, and its return said of each finding "Same finding as the in-family checker produced on r0." That contaminates the one thing a second opinion is for. Same root cause — the prohibition lives in the prompt, and prompts are advisory.

## Proposed

A `PreToolUse` guard scoping a courier's writes the way `orchestrator-write-guard` already scopes the orchestrator's. Allow `verdicts/<Task-ID>-*-<lane>.json`, its `.md` sibling, and `log/vendor-calls.jsonl`, plus `state/exhausted/<lane>` for the quota path. Deny everything else, task files included.

Worth pairing with a read-side denial on the unsuffixed verdict stem `verdicts/<Task-ID>-<tier>-r<retries>.json`, so blind crossing is structural rather than requested. #34 rules on comparison data, and data from a courier that read the answer first is not comparison data.

Adjacent but not the same: #36 covers write modes for the *external vendor process*. This is about the courier agent itself writing guild state through its own tools.

## Acceptance Criteria

- [ ] A courier attempting to write any task file under `.agent-guild/state/tasks/` is denied by a hook, not by prompt instruction.
- [ ] A courier attempting to write an unsuffixed verdict stem is denied.
- [ ] The two permitted paths plus the exhaustion sentinel still succeed.
- [ ] A test demonstrates each denial, not just the happy path.
- [ ] A courier that reads the verdict of record is either denied, or the crossing is marked contaminated on the record.

## For a Coding Agent

- **Verify with:** `python3 hooks/test_hooks.py`
- **Setup:** stdlib only; the hooks read the guild state tree under `.agent-guild/state/`.
- **Start here:** `hooks/orchestrator-write-guard.py` is the working model for a scoped write guard. `hooks/dispatch-guard.py` already resolves the courier's lane via `_lib.courier_lane()` and knows `_lib.CHECKER_AGENTS`. `agents/checker-courier.md` carries the contract text this would enforce.
- **Done when:** the write guard denies a courier's out-of-lane write in a test, and the courier's contract text points at the gate rather than asking for cooperation.
- **Out of scope:** the external vendor's sandbox write mode (#36), and the missing `codex-courier.py` (#84).
