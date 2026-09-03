---
name: divvy-up
description: "Run an approved implementation plan as waves of parallel subagents, where the tasks in a wave own disjoint files and each one is routed to the cheapest model that can do it correctly."
argument-hint: '[plan path] [--max N] [--commit]'
disable-model-invocation: true
---

# divvy-up

An implementation plan is a dependency graph, not a list. Read as a list it executes in the order somebody typed the bullets, one task at a time, on whatever model the session happens to be running. Read as a graph it has width: most tasks wait on one or two others and on nothing else, so they can run at the same moment.

Width is only safe under one condition—no two concurrent tasks write the same path—and that condition gets **proved by a script before anything is dispatched**, rather than asserted in a "watch out for conflicts" note attached to the workers. Two agents editing one file in one working tree lose a write and neither of them reports it, so a check that runs after the fan-out is a check that runs too late.

Cost falls for a second reason. Each task runs on the cheapest rung of the ladder that can do it correctly, and the savings hold only because **review stays on the session model**. Delegation that also delegates the judgment of whether the work came back right does not save money; it moves the mistake somewhere nobody is looking.

Three skills cover three shapes of the same job. Reach for `agent-guild` when the work needs a written constitution and an independent checker per task. Reach for `divvy-up` when a plan is already approved and its tasks can be carved into disjoint file ownership. Reach for `subagent-driven-development` when they cannot be, and the tasks have to run one at a time.

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

Then take each pair of tasks whose files are disjoint and ask whether one's change would alter what the other builds against, even where PLAN names no dependency between them. Disjoint paths prove two tasks cannot lose each other's writes; they do not prove the two tasks are about different things. Three shapes turn up: both change behavior some third module reads, one fix may make the other unnecessary, or both touch a runtime agreement that is neither a type nor a schema and so never became a wave-0 task. A coupling found this way lands in a mechanism this skill already has. Directional—A's result shapes B's work—is a dependency, which Step 3's rule already resolves by putting B in a later wave. Mutual, or either may make the other moot, is a merge into one task, the same way the batching rule merges same-shape edits. Suspected but unclear is an ambiguity: write it up as a question for Step 4 rather than settling it here.

Every task carries four things: an `owns` list of exact paths or directory prefixes ending in `/`, a model, a done-when somebody could fail it against, and a constraint naming the shortcut that would satisfy that done-when without doing the work. A done-when states what passing looks like, and a cheap rung told "these tests pass" can get there by weakening the test—the gate then sees green. So where the done-when has an obvious cheap wrong path—a test that could be loosened, a timeout that could be raised, production code a test-only task could edit—write that shortcut down. Most tasks have no such path, and their constraint cell stays empty rather than holding something invented to fill it. Where PLAN leaves a task ambiguous, write it up with the open question attached and carry the question to Step 4 rather than guessing an answer that six parallel agents will then build on.

**Done when:** every unit of work in PLAN is a task with owns, model, a checkable done-when, and a constraint cell that is either filled or deliberately empty; every disjoint-file pair has been asked the coupling question, and each coupling found has landed as a dependency, a merge, or a recorded question; and every ambiguity is written down as a question instead of a guess.

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

Check `git status --porcelain` before writing anything. A dirty tree stops the run with "commit or stash first": Step 6 recovers a failed task by reverting the paths it owns, and against pre-existing uncommitted work that revert destroys something this run never wrote. Where the user overrides deliberately, name the exposed paths. The check runs here, ahead of the table, because writing the table into a tracked plan file is itself a modification—checking after that edit would stop every ordinary run on the skill's own change.

A task goes in the lowest wave where it shares no owned path with a peer already in that wave, and every task it depends on sits in an earlier wave. Apply MAX as a cap on wave size.

Write the result into PLAN under a `## Waves` heading, as a pipe table with the header `Wave | Task | Files owned | Model | Done when | Constraints`. Then:

```
divvy-up/scripts/check-waves.py validate <PLAN>
```

A plan that lives only in the conversation still needs a pathname, because Step 6's `owners` takes its changed paths on stdin and refuses `-`. Write the table to a temporary file, use that path for the rest of the run, and print the table for the user as well. Validating through `validate -` and dispatching anyway strands the run: workers modify the tree, and the mandatory ownership check then has no plan to read.

A non-zero exit is a hard stop, not a warning. Overlapping owners inside one wave remove the single property the whole design rests on, and a fan-out on top of that overlap produces a diff nobody can attribute. Its `serialized:` lines are the healthy case: two tasks that touch one tree, held in different waves.

Announce the shape in one line before anything spends a token—`4 waves, 9 tasks; wave 0 is 1 contract task on opus.` That line is the user's correction point.

**Done when:** `validate` exits 0, and the shape line has been printed.

## Step 4 — Confirm

When GUILD, stop here. Print `Run /agent-guild:job <PLAN>` and say plainly that the guild re-derives its own tasks, so the ownership and model columns just written become advisory prose for the guild to read rather than instructions anything will execute.

When PLAN is still being shaped—plan mode, or the user has not approved it—stop after the table. Waves computed over a moving plan expire the moment it moves.

Put every question Step 1 recorded to the user before asking anything else, and settle each one. An ambiguous task that reaches a dispatch spends a rung and comes back `stopped`, by which time its peers have already written the tree it was guessing about.

Ask once, in one question: execute wave 0, and commit after each passing wave. Drop the commit half when `--commit` already answered it.

**Done when:** every recorded question is answered, and the user has approved executing wave 0 with COMMIT settled—or the run stopped at the guild handoff or the unapproved plan.

## Step 5 — Dispatch a wave

Read `references/worker-prompt.md` and instantiate it once per task in the wave. Dispatch every one of them in a SINGLE message so they run concurrently—one dispatch per message is exactly the serialization the wave exists to remove, and it looks identical in the transcript.

Every git write belongs to you, not to a worker. Workers write files; you stage, commit, and branch. A worker that commits stages its peers' half-written changes along with its own and moves HEAD out from under Step 6's revert, so a failed task survives its own rollback. Say so in the dispatch: a repo's own agent docs are usually written for an agent working alone, and this one is not.

Name each dispatch's model explicitly. An omitted model inherits the session's, which is usually the most expensive one available, and the routing silently evaporates while the run still looks correct.

Save every returned JSON report verbatim. Step 6 reads these as evidence of what happened, and a summarized report is evidence of what the orchestrator thought happened.

Before the dispatch goes out, record **WAVE_BASE** as a commit object: `git stash create`, falling back to `git rev-parse HEAD` when that prints nothing because the tree is clean. `git stash create` writes a commit of the current tree without touching the working tree or the index, which is what makes it safe to run mid-run.

Record the wave's untracked files beside it as content, not as names: each path from `git ls-files --others --exclude-standard` with its `git hash-object -w`. `git stash create` ignores untracked files even under `--include-untracked`, so nothing else covers them, and a name-only list repeats the defect below in the untracked half—wave 1 creates a file, a wave-2 worker rewrites it, both lists hold the same path, and the clobber is invisible.

`-w` is what makes the manifest more than a detector. Without it `git hash-object` prints a hash and stores nothing, so once a worker overwrites the file the bytes are gone and Step 6 has a name for what it cannot restore. `-w` writes the blob into the object database, where `git cat-file -p` can still reach it.

A commit object rather than a status snapshot, because status text cannot see a second write. When wave 1 leaves a file at ` M path` and a wave-2 worker rewrites that same file, both snapshots hold the identical line, the difference between them is empty, and the clobber the gate exists to catch passes it silently.

**Done when:** WAVE_BASE is recorded, every task in the wave was dispatched in one message at its routed model, and every report is saved verbatim.

## Step 6 — Gate

Three checks, then a route.

1. **Ownership.** Work out what this wave wrote, then pipe those paths through the plan:

   ```
   divvy-up/scripts/check-waves.py owners <PLAN> --wave N
   ```

   Derive the paths against WAVE_BASE, not against the working tree as a whole, and the same way whether or not COMMIT is set: `git diff --name-only <WAVE_BASE>` for tracked content, plus every untracked path whose `git hash-object` differs from the wave's manifest, is missing from it, or has since disappeared. Reading the whole dirty tree instead fails wave 2 for every path wave 1 legitimately owned.

   A path no task in the wave owns fails the run. That is a write into territory nobody claimed, and it is invisible in a passing test suite.

   Then check each report's `files_changed` against that task's own `owns`, and fail any task claiming a path it does not own. `owners` answers which task owns a path, never which agent wrote it, so a worker that writes a peer's owned file leaves a path the gate happily attributes to its rightful owner. The report cross-check is what catches that case, and it rests on the worker's own account of what it touched—see Known Limitations for what stays uncovered.

2. **Verification.** Find the repo's own command on disk rather than asking for it: manifest scripts first (`package.json`, `Makefile`, `pyproject.toml`, `Cargo.toml`), then runnable scripts under `tests/` or `scripts/`, then whatever `.github/workflows/` runs.

3. **Reports.** Read each one against its task's done-when and its constraints, not against whether it sounds finished.

Then route each task:

| Result | Route |
|---|---|
| Passing | Move to the next wave, committing first when COMMIT is set. |
| `stopped` | Revert that task's owned paths, then hold its question. Put every held question to the user once the rest of the wave lands, then re-dispatch the task alone at the same rung with the answer attached. Same rung, because it stopped for want of an answer rather than for want of a better model. Reverting first matters as much as it does for a failure: partial work built toward a guess the worker declined to make is worse than an empty tree. |
| `failed`, or failed the gate | Revert that task's owned paths, then re-dispatch it alone one rung up with the failure attached. Work that reached its done-when by the shortcut its constraint named has failed the gate: a worker that took that route lacked the judgment the task needed, and the rung above is what supplies it. |
| Failed on `fable` | Revert its owned paths and stop the run. `fable` is the top rung, so nothing is left to escalate to, and a retry at the same rung spends the budget to learn the same thing. |
| Failed twice | Stop the run and report. |

Revert before the retry. A re-dispatch onto a half-written tree hands the second agent the first one's leftovers to debug, and it will spend its budget there instead of on the task. The revert is bounded by the clean tree Step 3 required and by WAVE_BASE, so it only ever discards writes this run made.

Reverting a task means, for each path it owns: a tracked path goes back with `git checkout <WAVE_BASE> -- <path>`; an untracked path the wave created is deleted; an untracked path in the wave's manifest is restored with `git cat-file -p <its blob> > <path>`, whether the task rewrote it or removed it.

**Done when:** every report has been read against its task's done-when and its constraints, and every task in the wave is passing; or was reverted and retried one rung up; or was reverted, answered, and re-dispatched at its own rung; or the run stopped after a second failure or on a `fable` task. The wave is committed when COMMIT is set, and no worker has committed anything.

## Step 7 — Review

After the last wave, read `git diff <START_SHA>` in-session against PLAN as a whole. The gates checked tasks one at a time; nothing before this point has looked at whether the assembled change does what the plan set out to do.

Report waves run, tasks per model, escalations, questions asked, and what is left uncommitted.

**Done when:** the full diff has been read against PLAN, and the report names waves run, per-model task counts, escalations, open questions, and uncommitted work.

## Further Reading

- [references/worker-prompt.md](references/worker-prompt.md) — read at Step 5 to instantiate each dispatch
- [scripts/check-waves.py](scripts/check-waves.py) — run at Step 3 to prove the waves, and at Step 6 to attribute what a wave wrote
