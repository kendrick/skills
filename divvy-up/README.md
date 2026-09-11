# divvy-up

Runs an approved plan as waves of parallel subagents, where no two agents in a wave can write the same file.

## Why This Exists

An approved implementation plan is a dependency graph that got typed up as a list. Read back as a list, it executes in the order somebody wrote the bullets, one task at a time, on whatever model the session happens to be running. But most tasks in a plan wait on one or two others and on nothing else, which means a lot of them could have run at the same moment.

Running them that way meant choosing among three bad fits. `agent-guild` runs waves safely, but it wants a per-project install, a written constitution every task cites a clause of, and an independent checker per task. `subagent-driven-development` routes each task to a model but forbids parallel implementers outright, which is the right call for a skill with no ownership mechanism. And the generic parallel-dispatch skills fan out with no ownership mechanism at all, then reconcile afterwards, which is too late. Two agents editing one file in one working tree lose a write, and neither of them reports it.

So the bet here is narrow. Declared file ownership, proved disjoint by a script before anything is dispatched, is what makes parallel implementers safe. That is the whole mechanism, and it is what lets this skill lift the never-in-parallel rule its neighbor keeps. That rule exists because nothing was tracking who owned what. Now something is, and it fails the run instead of warning about it.

## How It Works

It reads your plan and carves it into tasks, one per unit of work that names files. Shared contracts—types, interfaces, schemas, migrations—go into wave 0, each one alone, ahead of everything that consumes them, because a consumer that starts before its contract exists writes against a guess. Derivation also checks every pair of tasks whose files don't overlap for a dependency the plan never wrote down. Disjoint paths prove two tasks can't lose each other's writes, not that they're about different things, so it merges or serializes the pair when it finds one. Small same-shape edits go the other direction: the same one-line fix repeated across eight files is one task and one review, not eight of each. Where the plan leaves a task ambiguous, it writes the ambiguity down as a question and brings it to you rather than answering it, since a guess made this early is a guess six parallel agents will build on.

Every task then names one of four rungs, the cheapest that can do the work correctly:

- `haiku` — file and symbol discovery, mechanical renames, test scaffolding, docs and changelogs, formatting, boilerplate against a spec you already approved.
- `sonnet` — feature work inside a single module, tests written to stated behavior, straightforward refactors.
- `opus` — anything touching auth, payments, migrations, deletes, infra, or the public API; anything whose spec is ambiguous.
- `fable` — by explicit assignment, and the rung an `opus` task escalates to after it fails.

A task goes in the lowest wave where it shares no owned path with a peer already there and every task it depends on sits earlier. The resulting table—wave, task, files owned, model, done-when, constraints—lands in your plan file, and `check-waves.py validate` has to exit 0 on it before anything else happens. The constraints cell names the cheap wrong path that would satisfy the done-when without doing the work. A worker on a cheap rung told "these tests pass" is told, in the same breath, not to get there by weakening the test. Overlapping owners inside one wave remove the single property the whole design rests on, and a fan-out on top of that overlap produces a diff nobody can attribute afterwards. You then get the shape in one line, something like `4 waves, 9 tasks; wave 0 is 1 contract task on opus.` That line is your correction point, and nothing has spent a token yet.

Each wave goes out in a single message, so its tasks genuinely run at once. One dispatch per message is exactly the serialization the wave exists to remove, and in the transcript afterwards the two look identical. Every dispatch names its model, since an omitted model inherits the session's, which is usually the most expensive one available.

The gate that follows runs three checks. It works out what the wave actually wrote and pipes those paths back through the ownership table, and a path nobody in the wave claimed fails the run. It runs the repo's own verification command, found on disk rather than asked for. And it reads each returned report against that task's done-when, not against whether the report sounds finished. A task that fails gets the paths it owned reverted and one more try, alone, one rung up, with the failure attached. Failing twice stops the run.

One thing that check cannot do on its own is say who wrote a path. If task A writes task B's file, the path is still owned by B and the ownership pass is content with it. So the gate also holds each worker's own report of what it touched against what it owned, which catches the honest stray. A worker that writes a peer's file and leaves it out of its report gets through, and the Gotchas below say what that costs.

After the last wave, it reads the merged diff in-session against the plan as a whole. The gates looked at one task at a time; nothing before this point has asked whether the assembled change does what the plan set out to do.

That last read is why the routing saves anything. Deriving the tasks, gating a wave, and reviewing the diff are not dispatches. They stay on the session model, whatever it is, so cheap rungs produce the work and an expensive reader judges it. Push the judging down the ladder along with the work and you have not spent less. You have bought a cheaper opinion about whether the cheap work was any good, and a wrong opinion arrives looking exactly like a right one.

## Install

```bash
npx skills add kendrick/skills --skill divvy-up
```

Or by hand:

```bash
git clone git@github.com:kendrick/skills.git
cp -R skills/divvy-up ~/.claude/skills/divvy-up
```

Needs a git repo and Python 3 for the bundled script, which is stdlib-only.

## Use

It only runs when you ask for it by name—see the Gotchas for why.

```
> /divvy-up
> /divvy-up docs/plan.md
> /divvy-up docs/plan.md --max 3
> /divvy-up docs/plan.md --commit
```

Without a path it takes the plan file this session wrote, and failing that the approved plan sitting in the conversation. `--max N` caps how many tasks one wave may hold. `--commit` commits after each passing wave instead of asking you at the confirmation step.

## What's Here

```
divvy-up/
├── SKILL.md                  # the skill — derive, route, wave, confirm, dispatch, gate, review
├── references/
│   └── worker-prompt.md        # the dispatch template and the JSON contract every worker returns
└── scripts/
    └── check-waves.py          # proves the waves disjoint; attributes what a wave wrote
```

## Gotchas

- **It won't fire on its own.** A misfire during ordinary planning spends a whole fan-out on somebody who was still thinking, while a missed trigger costs you one word. Type its name.
- **A plan still being shaped stops it.** Waves computed over a moving plan expire the moment it moves, so it prints the table and waits for you to settle the plan first.
- **It defers to `agent-guild`.** In a repo that already has `.agent-guild/`, it emits its table, names `/agent-guild:job`, and dispatches nothing. The guild re-derives its own tasks from a spec, so the ownership and model columns become prose for the guild to read rather than instructions anything will execute.
- **Ownership is per file, never per region.** Two tasks that need different parts of one file have to split the file or land in different waves. `paths_overlap` proves disjointness at the file level, and two agents racing inside one file is a merge problem no path-level check can see coming.
- **Owned paths are literal, never globs, and never decorated.** The predicate is vendored from `agent-guild`, where a glob entry is rejected outright because it can claim territory no file yet occupies, which is exactly the overlap the check exists to catch. The same gate refuses a backtick or a markdown link around a path for the same reason: a decorated entry matches no file on disk, and it compares as a different string from the bare path a peer task owns, so two spellings of one file read as no overlap and two tasks land on it in the same wave.
- **There's no run directory and no ledger.** The `## Waves` table in your plan file is the only artifact. Ownership is already the recovery story: a failed task rolls back by reverting the paths it owns, and a second record would restate the table until the two drifted apart.
- **Writers are attributed by their own report.** Git records that a file changed, never which of two concurrent agents changed it. The gate cross-checks each worker's reported `files_changed` against its `owns`, so an honest stray is caught, but a worker that clobbers a peer and omits it from its report is not. Per-wave commits keep it recoverable. Closing the gap properly would mean one worktree per worker, which is a different skill.
- **A constraint is read from the same report as everything else.** The gate checks the constraints cell against a worker's own report, the channel that also attributes writes. A shortcut a worker takes and doesn't mention gets through exactly like an unreported stray write.
- **It wants a clean tree before it dispatches.** Recovery works by reverting a failed task's owned paths, and against uncommitted work the run never wrote that revert destroys it. Commit or stash first.
- **There's no reviewer subagent per task.** The wave gate reads each report against its done-when on the session model. A reviewer per task would double the dispatch count for a check the gate already covers.

## Maintainers

The decision ledger and eval suite live in [`_maintenance/divvy-up/`](../_maintenance/divvy-up/). Every contested choice has a row in [RATIONALE.md](../_maintenance/divvy-up/RATIONALE.md), including where each borrowed mechanism came from and everything deliberately left out. [EVALS.md](../_maintenance/divvy-up/EVALS.md) carries the smoke test that pins the artifact and the live procedure for whether the waves actually work.

## License

MIT, per the [collection license](../LICENSE). This skill is part of the [skills collection](..).
