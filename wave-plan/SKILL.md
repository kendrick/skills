---
name: wave-plan
description: "Run an approved implementation plan as waves of parallel subagents, where the tasks in a wave own disjoint files and each one is routed to the cheapest model that can do it correctly."
argument-hint: '[plan path] [--max N] [--commit]'
disable-model-invocation: true
---

# wave-plan

An implementation plan is a dependency graph, not a list. Read as a list it executes in the order somebody typed the bullets, one task at a time, on whatever model the session happens to be running. Read as a graph it has width: most tasks wait on one or two others and on nothing else, so they can run at the same moment.

Width is only safe under one condition—no two concurrent tasks write the same path—and that condition gets **proved by a script before anything is dispatched**, rather than asserted in a "watch out for conflicts" note attached to the workers. Two agents editing one file in one working tree lose a write and neither of them reports it, so a check that runs after the fan-out is a check that runs too late.

Cost falls for a second reason. Each task runs on the cheapest rung of the ladder that can do it correctly, and the savings hold only because **review stays on the session model**. Delegation that also delegates the judgment of whether the work came back right does not save money; it moves the mistake somewhere nobody is looking.

Three skills cover three shapes of the same job. Reach for `agent-guild` when the work needs a written constitution and an independent checker per task. Reach for `wave-plan` when a plan is already approved and its tasks can be carved into disjoint file ownership. Reach for `subagent-driven-development` when they cannot be, and the tasks have to run one at a time.

This skill is user-invoked (`disable-model-invocation: true`) because a misfire during ordinary planning spends a whole fan-out, while a missed trigger costs the user one word.

Where a step names a shell command, treat it as the intent and use your native shell or file tools.

Resolve once per invocation:

- **PLAN** — the plan path from the arguments; failing that, the plan file this session wrote; failing that, the approved plan held in the conversation.
- **MAX** — the cap on tasks per wave from `--max N`, else unbounded.
- **COMMIT** — set by `--commit`, else asked at Step 4.
- **START_SHA** — `git rev-parse HEAD`, taken before any task runs. Step 7 reads the whole run against it.
- **GUILD** — whether `.agent-guild/` exists.

## Step 1 — Derive tasks

Read PLAN end to end. One task per unit of work that names files. Shared contracts—types, interfaces, schemas, migrations—become wave-0 tasks, each alone, ahead of everything that consumes them: a consumer that starts before its contract exists writes against a guess.

Batch small same-shape edits into ONE task. The same one-line fix or field addition repeated across eight files is one dispatch and one review surface, not eight of each; splitting it multiplies the gate work without buying any parallelism.

Every task carries three things: an `owns` list of exact paths or directory prefixes ending in `/`, a model, and a done-when somebody could fail it against. Where PLAN leaves a task ambiguous, write it up with the open question attached and carry the question to Step 4 rather than guessing an answer that six parallel agents will then build on.

**Done when:** every unit of work in PLAN is a task with owns, model, and a checkable done-when, and every ambiguity is written down as a question instead of a guess.

## Step 2 — Route

| Rung | Work it takes |
|---|---|
| `haiku` | File and symbol discovery, grep-and-report, mechanical renames, test scaffolding, docs and changelogs, formatting, dependency-free boilerplate against a spec the user already approved. |
| `sonnet` | Feature implementation inside a single module, tests written to stated behavior, straightforward refactors. |
| `opus` | Anything touching auth, payments, migrations, deletes, infra, or public API surface; any task whose spec is ambiguous. |
| `fable` | Explicit assignment only, and the rung above `opus` when an `opus` task fails. |

Orchestrator work is not a dispatch. Deriving the plan, gating a wave, and reading the merged diff all run on the session model, whatever it is. That is where the delegation savings survive contact: cheap rungs produce the work, the session model judges it. When a task sits between two rungs, escalate—a wrong guess downward costs a revert, a retry, and the gate that caught it.

**Done when:** every task names one of `haiku`, `sonnet`, `opus`, `fable`, and every task the ladder's `opus` row describes sits at `opus` or above.

## Step 3 — Wave

A task goes in the lowest wave where it shares no owned path with a peer already in that wave, and every task it depends on sits in an earlier wave. Apply MAX as a cap on wave size.

Write the result into PLAN under a `## Waves` heading, as a pipe table with the header `Wave | Task | Files owned | Model | Done when` (print it instead when the plan lives only in the conversation). Then:

```
wave-plan/scripts/check-waves.py validate <PLAN>
```

A non-zero exit is a hard stop, not a warning. Overlapping owners inside one wave remove the single property the whole design rests on, and a fan-out on top of that overlap produces a diff nobody can attribute. Its `serialized:` lines are the healthy case: two tasks that touch one tree, held in different waves.

Announce the shape in one line before anything spends a token—`4 waves, 9 tasks; wave 0 is 1 contract task on opus.` That line is the user's correction point.

**Done when:** `validate` exits 0, and the shape line has been printed.

## Step 4 — Confirm

When GUILD, stop here. Print `Run /agent-guild:job <PLAN>` and say plainly that the guild re-derives its own tasks, so the ownership and model columns just written become advisory prose for the guild to read rather than instructions anything will execute.

When PLAN is still being shaped—plan mode, or the user has not approved it—stop after the table. Waves computed over a moving plan expire the moment it moves.

Otherwise ask once, in one question: execute wave 0, and commit after each passing wave. Drop the commit half when `--commit` already answered it.

**Done when:** the user has approved executing wave 0 and COMMIT is settled, or the run stopped at the guild handoff or the unapproved plan.

## Step 5 — Dispatch a wave

Read `references/worker-prompt.md` and instantiate it once per task in the wave. Dispatch every one of them in a SINGLE message so they run concurrently—one dispatch per message is exactly the serialization the wave exists to remove, and it looks identical in the transcript.

Name each dispatch's model explicitly. An omitted model inherits the session's, which is usually the most expensive one available, and the routing silently evaporates while the run still looks correct.

Save every returned JSON report verbatim. Step 6 reads these as evidence of what happened, and a summarized report is evidence of what the orchestrator thought happened.

Before the dispatch goes out, record **WAVE_BASE**: `git rev-parse HEAD` when COMMIT is set, otherwise a snapshot of `git status --porcelain --untracked-files=all`. Step 6 attributes writes against it, and without it a later wave inherits every earlier wave's paths.

**Done when:** WAVE_BASE is recorded, every task in the wave was dispatched in one message at its routed model, and every report is saved verbatim.

## Step 6 — Gate

Three checks, then a route.

1. **Ownership.** Work out what this wave wrote, then pipe those paths through the plan:

   ```
   wave-plan/scripts/check-waves.py owners <PLAN> --wave N
   ```

   Derive the paths against WAVE_BASE, not against the working tree as a whole. With COMMIT set, that is `git diff --name-only <WAVE_BASE>` together with `git ls-files --others --exclude-standard`, since a diff alone never mentions a file a subagent created. With COMMIT unset, earlier waves are still sitting uncommitted, so take the paths a fresh `git status --porcelain --untracked-files=all` reports that the snapshot did not—reading the whole dirty tree instead fails wave 2 for every path wave 1 legitimately owned.

   A path written outside its task's `owns` fails that task. An agent that wrote outside its territory may have clobbered a peer in the same wave, and that damage is invisible in a passing test suite.

2. **Verification.** Find the repo's own command on disk rather than asking for it: manifest scripts first (`package.json`, `Makefile`, `pyproject.toml`, `Cargo.toml`), then runnable scripts under `tests/` or `scripts/`, then whatever `.github/workflows/` runs.

3. **Reports.** Read each one against its task's done-when, not against whether it sounds finished.

Then route each task:

| Result | Route |
|---|---|
| Passing | Move to the next wave, committing first when COMMIT is set. |
| `stopped` | Collect the question and put it to the user once the rest of the wave lands. |
| `failed`, or failed the gate | Revert that task's owned paths, then re-dispatch it alone one rung up with the failure attached. |
| Failed twice | Stop the run and report. |

Revert before the retry. A re-dispatch onto a half-written tree hands the second agent the first one's leftovers to debug, and it will spend its budget there instead of on the task.

**Done when:** every task in the wave is passing, or has been reverted and retried one rung up, or the run stopped after a second failure; and the wave is committed when COMMIT is set.

## Step 7 — Review

After the last wave, read `git diff <START_SHA>` in-session against PLAN as a whole. The gates checked tasks one at a time; nothing before this point has looked at whether the assembled change does what the plan set out to do.

Report waves run, tasks per model, escalations, questions asked, and what is left uncommitted.

**Done when:** the full diff has been read against PLAN, and the report names waves run, per-model task counts, escalations, open questions, and uncommitted work.

## Further Reading

- [references/worker-prompt.md](references/worker-prompt.md) — read at Step 5 to instantiate each dispatch
- [scripts/check-waves.py](scripts/check-waves.py) — run at Step 3 to prove the waves, and at Step 6 to attribute what a wave wrote
