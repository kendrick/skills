The dual-check regime in `.agent-guild/CLAUDE.md` is written for tasks: once a task's checker of record returns, dispatch `checker-courier` on the same Task-ID. Audits get no equivalent, and `dispatch-guard` actively prevents improvising one.

That leaves the two verdicts nobody can cross — the ones on the orchestrator's own work.

## Steps to Reproduce

1. Reach a CON-audit or DEC-audit PASS in a guild job.
2. Try to dispatch the second opinion the same way you would for a task:

   ```
   Agent(subagent_type: 'agent-guild:checker-courier', prompt: 'Audit-ID: CON-audit\n…')
   ```

3. Try again with a Task-ID form instead: `Task-ID: CON-audit`.

## Observed vs. Expected

**Observed:** the first form is denied — `Dispatch to checker-courier has no id line. Put 'Task-ID: T-NNN' in the prompt so the return gate can identify this subagent's work when it finishes.` `_lib.TASK_ID_RE` only matches `T-\d+`, so `CON-audit` never parses as a task id. The second form fails the same way, and even if it parsed, `dispatch-guard.py` requires `.agent-guild/state/tasks/<id>.md` to exist and its status to be `checking` — neither is true of an audit, which has no task file by design.

**Expected:** an audit verdict can carry a second opinion through the same lane a task's can, landing at an audit-shaped suffixed stem.

## What this cost in practice

Both audits in this run still got crossed, because the orchestrator ran the `codex exec` lane command inline by hand — composing the brief, collecting evidence locally, validating the response, writing the verdict, and appending the ledger line itself. That works, and it is exactly the improvisation #84 is about: no shared timeout policy, no shared exit-code contract, no shared ledger writer, and this time no agent boundary either. The orchestrator ended up executing a check it had also commissioned.

It also skews #34. The evaluation rules on unique-finding rate across crossings, and the two crossings against the orchestrator's *own* work are the ones most likely to catch something an in-family reviewer would not — the auditor and the orchestrator share a model family and a prompt lineage. Those are the crossings currently reachable only by hand.

For what it is worth, the CON-audit crossing returned 6 findings against the auditor's 0, four of which were folded into task acceptance criteria and changed what got built. That is the highest-yield crossing in the run, and the lane cannot produce it without an operator driving the CLI directly.

Related but distinct: #100 is about task-level second opinions not being *enforced*. This is about audit-level ones not being *possible*.

## Acceptance Criteria

- [ ] `dispatch-guard` accepts `checker-courier` on an `Audit-ID` (`CON-audit` / `DEC-audit`) without requiring a task file or a `checking` status.
- [ ] The audit courier's verdict lands at a documented audit-shaped stem, e.g. `verdicts/<Audit-ID>-r<N>-<lane>.json`, and never at the auditor's own stem.
- [ ] `subagent-return` validates that verdict the way it validates a task's, including that its `task_id` names the audit.
- [ ] `.agent-guild/CLAUDE.md`'s dual-check section says whether an audit crossing is mandatory or optional, so its absence reads as a decision rather than an oversight.
- [ ] A test covers the denial-before and the acceptance-after.

## For a Coding Agent

- **Verify with:** `python3 hooks/test_hooks.py`
- **Setup:** stdlib only.
- **Start here:** `hooks/dispatch-guard.py` — the auditor path at the `if agent == "auditor"` branch shows the shape an audit-aware courier branch needs, and the checker path just below it is where the task-file and `checking`-status requirements are enforced. `hooks/_lib.py` holds `TASK_ID_RE`, `AUDIT_ID_RE`, and `bare_id()`. `agents/checker-courier.md` documents the stem convention that needs an audit variant.
- **Done when:** a courier dispatched on `Audit-ID: CON-audit` runs and its verdict lands at the audit stem, with the existing task-path behaviour unchanged.
- **Out of scope:** whether audit crossings become mandatory — this issue only makes them possible.
