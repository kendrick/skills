# wave-plan—rationale

Evidence tiers: **[E]** measured or observed in a real run, **[P]** practitioner reasoning from prior art, **[C]** convention inherited from this repo or its neighbors.

## Where This Came From

Three sources, one keeper mechanism each:

- **agent-guild** (a plugin at `~/.claude/plugins/cache/kendrick/agent-guild/`)—the `owns` field, the wave computation in `ready-set.py`, and the `paths_overlap` predicate. It stops short by requiring a per-project install, a constitution every task must cite a clause of, and an independent checker per task. Its only outside intake is a spec document, and it re-derives its own tasks from that, so a wave table handed to it becomes prose.
- **The forked `subagent-driven-development` skill** (user-level, at `~/.agents/skills/`)—the model-routing rubric and the batching rule for small same-shape edits. It stops short at "Never dispatch multiple implementation subagents in parallel (conflicts)"—correct for a skill with no ownership mechanism, and exactly what declared ownership plus a validating script is there to lift.
- **This repo's own `adversarial-review`**—disjoint territories with exactly one owner each, proved by a script, a hard stop on overlap, and the announce-before-you-spend line.

## Decision Ledger

| # | Decision | Why | Tier |
|---|---|---|---|
| 1 | User-invoked only (`disable-model-invocation: true`) | A misfire during ordinary planning costs a whole fan-out; a missed trigger costs the user one word. Same call as `adversarial-review` and `handoff`. | [P] |
| 2 | Literal paths, never globs; `paths_overlap` and `owns_entry_problem` vendored byte-identically rather than rewritten | Two globs can overlap without either matching a file that exists yet, and the upstream predicate rejects glob characters outright because "an entry is a literal path, and a pattern here would own nothing." Vendoring across skills has precedent in this repo. | [C] |
| 3 | Any plan source: a plan-mode file, a `writing-plans` output, any markdown path, or the approved plan held in the conversation | Derivation reads prose either way; a `writing-plans` file with a `Files:` block per task is the best case, not a requirement. | [P] |
| 4 | A standalone skill rather than a mode inside `subagent-driven-development` | The gap nobody owns is parallel execution of an existing plan without guild ceremony. | [P] |
| 5 | Four literal model rungs (haiku, sonnet, opus, fable) rather than role tiers like "cheap / standard / most capable" | Literal names make the Model column an enum a script can check and make escalation mechanical. The cost is that the ladder is Claude-only. | [P] |
| 6 | Orchestrator work runs on the session model and is never a dispatch | A fable session should not spend fable on every sensitive task by default, and review is where the delegation savings hold up. | [P] |
| 7 | The wave gate is the repo's own verification command plus a session-model read of each report against its done-when | Per-task reviewer subagents would duplicate `subagent-driven-development`; no gate at all lets a wave-0 contract defect reach every consumer before anyone looks. | [P] |
| 8 | Ambiguity stops the task and reaches the user; failure re-dispatches alone one rung up, once, then stops | Guild's escalation ladder without its per-tier retry counters. | [P] |
| 9 | No run directory and no ledger. The plan file's `## Waves` table is the only artifact | Run-state tracking is what makes the guild the guild, and disjoint ownership already gives the recovery story: a failed task rolls back by reverting the paths it owns. | [C] |
| 10 | A failed task's owned paths are reverted before the retry | A re-dispatch onto a half-written tree makes the second agent debug the first one's leftovers instead of doing the task. | [P] |

## Deliberately Not Built

| Cut | Why |
|---|---|
| A run directory and append-only ledger | The `## Waves` table already names every task, its owner, and its model; a parallel ledger would just restate it until the two drift. |
| Per-task reviewer subagents | The wave gate already reads each report against its done-when on the session model. A reviewer subagent per task would double the dispatch count for a check the gate already covers. |
| Glob ownership | A glob can claim territory no file yet occupies, which is exactly the overlap `paths_overlap` exists to catch. Literal paths keep its answer meaningful. |
| Per-tier retry counters | The retry rule is fixed: one re-dispatch, one rung up, then stop. A counter per model tier is guild machinery for a skill with no run state to hold it. |
| Automatic commits without the user's consent | A task's owned paths are the recovery mechanism for a failed retry. Committing on the skill's own authority would remove the user's chance to look before that revert happens. |
| Sub-file ownership (two tasks each owning a different region of one file) | `paths_overlap` proves disjointness at the file level. Two tasks racing inside one file is a merge problem no path-level check can see coming. |

## Known Limitations

- Task derivation from a prose plan is judgment, so two runs on one plan can differ.
- The model ladder names Claude models and does not port to other hosts.
- Sub-file ownership is out of scope, so a plan needing it must split the file or serialize the tasks.
- The gate trusts that the repo's verification command actually exercises the change.
- No scenario in EVALS.md has been run live yet, so every row there is [P] until it is not.
