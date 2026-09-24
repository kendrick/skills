# work-wave

Runs several GitHub issues at once, each one a `work-issue` lane in its own worktree, and merge-tests the lanes together before any of them opens a pull request.

## Why This Exists

`work-issue` advances one issue and refuses a concurrent sibling at its gate. For one issue, that's the right call. What it doesn't cover is the shape a wave actually takes: three issues, three worktrees, three agents, and one orchestrator holding everything that's true across all of them.

Run by hand, that orchestration loses the same four things every time.

A coupling between two lanes that no diff shows. In one wave, lane A relaxed a schema from strict to loose while lane C's comparison depended on the strictness. Their diffs sat in `core/` and `app/storage/`, so every ownership proof passed, and file-level disjointness was what made the wave feel safe.

The merge test, run last instead of first. Merging each branch into a scratch ref and running the suite took twenty minutes, and the lane that ran it called those the most reassuring twenty minutes of the wave. It happened after everything was pushed, because nothing asked for it sooner.

A fact one lane learned and another paid to relearn. One lane found that a CLI's two flags are mutually exclusive and exit 2. A second lane found the same thing an hour later, then spent another cycle proving what it had actually run.

A file handed back at a path the orchestrator couldn't read. Lanes reported worktree-relative paths, and each one cost a round trip.

So this skill owns the parts that are true across lanes, and hands everything else to `work-issue` unchanged.

## How It Works

It reads every lane's plan, writes each lane's footprint as a list of the paths it will own, and runs `check-footprints.py` over all of them at once, plus every `work-issue` run already in flight. For a lane whose `work-issue` already started, it reads the copy of the plan that run is building from, not the source plan, since an edit to the source after the run started changes nothing that run will build. An overlap stops the wave, because two worktrees rewriting one file produce a rebase conflict after you've walked away. So does an in-flight run that hasn't written its `## Waves` table yet. Its footprint is unknown, so the wave waits for the table, or for you to move a dead run to `closed/`. A run whose table has a path the script refuses to compare, such as one wrapped in backticks, stops the wave too. A backticked path never matches the bare spelling a lane uses, so the whole run counts as unproved until its plan spells the path bare or you move the run to `closed/`. A pass proves the lanes can't lose each other's writes. It doesn't prove they're independent, so for every pair the script lists, the orchestrator reads both plans against each other and asks whether one lane's change alters what the other builds against. Each answer lands as a row in `coupling.md` with the plan lines that decided it, and the answers become a merge order in `order.md`. A pair where one lane only observes the other's change merges after it. A pair where one lane would build against what the other changes is held out of the wave. A pair where each lane carries half of one change is refused. A pair the orchestrator can't call becomes a question for you.

You get one confirmation, in one message. It names the lanes and their worktrees, the footprint result, the coupling answers, the merge order, and any held lanes, so you can correct the shape before anything is dispatched. Before that message, it checks whether any lane's worktree path already exists and refuses the wave if one does, naming every such path. `--dry-run` renders the confirmation and stops. On yes, it runs the merge test once with no branches: a detached worktree on `origin/<default>`, the install, the suite, and the removal. That baseline proves the mechanism works and records what green looks like, so a red merge later lands on a lane and not on the tree the wave inherited.

Then every lane goes out in a single message, each one a subagent told to run `work-issue <N> <plan> --isolate`. The confirmation answers each lane's own `work-issue` confirmation in two halves. The first dispatch carries only the build half: execute every wave and commit, but don't push or open a pull request. When a lane's report shows it changed a contract path, such as a type, an interface, a schema, or a migration, the merge test runs right away over every lane branch with commits. The result lands in the wave's `facts/` directory, where lanes still building can read it and adjust. That helps only when the changing lane returns before them. Once every lane has returned, the merge test runs over the whole merge set in `order.md`'s order, one `git merge --no-ff` at a time. A conflict stops the wave naming every merged branch that touched the conflicted paths, which isn't always the one merged just before. A red suite stops it with the coupled pair named. Only a green merge test sends each lane out a second time with the push-and-pull-request half, and `work-issue` resumes at its own publish step. Right before that dispatch, the orchestrator fetches the default branch. If it moved since the merge test, the merge test runs again on the new tip first, because each lane rebases onto that tip before it opens its pull request.

Each lane appends what it learns to its own file under the wave's `facts/` directory, one line per fact with the command that proved it, and reads the whole directory before every worker dispatch it makes, so a sibling's discovery reaches the agents doing the work mid-run. Everything lives under the git common dir, which every lane's worktree can see. A lane that reports its worktree or run directory as a relative path gets re-prompted for the absolute one. The final report gives the merge order as pull-request URLs, the held and failed lanes, the newest merge test, and the coupling table. It ends on "a human merges, in this order," or on "waiting on the reviewers" when every lane is answered but none has cleared.

## Install

```bash
npx skills add kendrick/skills --skill work-wave
```

Or by hand:

```bash
git clone git@github.com:kendrick/skills.git
cp -R skills/work-wave ~/.claude/skills/work-wave
```

Needs a git repo with an `origin` remote and Python 3 for the bundled script, which is stdlib-only. Needs `gh` authenticated too, since the gate can't read the issues without it. Each lane invokes `work-issue` by name, so install that skill as well.

## Use

Type its name with two or more issues. It never fires on its own.

```
> /work-wave 113 114 115
> /work-wave 113 114 --plan 113=docs/plans/issue-113.md --plan 114=/tmp/plan-114.md
> /work-wave 113 114 115 --lane-model fable
> /work-wave 113 114 115 --dry-run
```

Each issue needs a plan, found the way `work-issue` finds one: the `--plan N=PATH` argument, then `docs/plans/` in this repo, then a path the issue links under a `Plan` heading. `--lane-model fable` runs the lanes on `fable` instead of the default `opus`. `--dry-run` runs every step through the confirmation, then dispatches nothing, makes no worktree, and pushes nothing. To resume, type the same invocation again, plan paths included. The run works out where it stopped from what's on disk, down to which returned lanes it had finished checking.

## What's Here

```
work-wave/
├── SKILL.md                  # the skill — gate, footprint, couple and order, confirm, dispatch, gate a lane, merge test, publish, report
├── references/
│   ├── lane-brief.md           # the prompt each lane receives, and the report contract it returns
│   └── merge-test.md           # the scratch-tree merge test, its four trigger points, and why a linked worktree
└── scripts/
    └── check-footprints.py     # proves every lane's footprint disjoint and lists the pairs to answer for coupling
```

## Gotchas

- **It only runs when you type it.** A misfire during ordinary planning spends a whole fan-out, while a missed trigger costs you one word, so the skill is user-invoked. No sibling skill calls it.
- **Every issue needs a plan, and fewer than two issues isn't a wave.** One missing plan refuses the whole wave, naming every issue that lacks one, since two lanes of three is a different wave from the one you asked for. A plan held only in the conversation doesn't count, because a fresh lane subagent can't see it. One issue gets pointed at `work-issue`.
- **It creates no worktrees for the lanes.** Each lane's `work-issue --isolate` makes its own. A tree already sitting at a lane's worktree path would put that lane on `work-issue`'s isolation question, which an unattended lane can't answer, so the confirmation step refuses the wave when one exists. The exception is a lane `work-issue` already started, whose tree is registered on its own `issue-N` branch.
- **Lanes build first and publish later, on the strength of a withheld grant.** The build dispatch tells each lane the push half is a no, and `work-issue` has no flag that stops it before publishing. That split rests on the lane honoring its brief. The one check is the report: a build report carrying a pull-request URL stops the wave, and whether that pull request stays open is your call.
- **Coupling is the orchestrator's call.** The script proves the footprints disjoint. Whether two lanes are independent comes from the orchestrator reading two plans against each other, and the merge test is what catches a pair it called wrong. When the merge test goes red, the pair's row in `coupling.md` is corrected and the wave stops.
- **A failed lane isn't retried or reverted.** Its writes sit on its own branch in its own worktree, so there's nothing to revert, and `work-issue` already retried inside the lane. It leaves the merge set, lanes ordered after it are held, and every other lane proceeds.
- **A red merge test publishes nothing.** A conflict or a failing suite in the merge test before publishing stops the wave and names the branches involved, and the repair isn't routed back to a lane, because which issue owns it is your call.
- **Lanes run on `opus` or `fable`, never lower.** A lane runs `divvy-up`'s gate, `code-review`, and a red-team on whatever model it was dispatched at, and those are judgment calls.
- **It never merges.** The final report hands you the order. If a repair round moved the HEAD of any lane it's handing you after the last merge test, it runs the merge test again first, so the order you merge in was tested at the commits you'll merge.

## Maintainers

The decision ledger and eval suite live in [`_maintenance/work-wave/`](../_maintenance/work-wave/). Every contested choice has a row in [RATIONALE.md](../_maintenance/work-wave/RATIONALE.md), including everything deliberately left out. Smoke test: `bash tests/work-wave-smoke.sh` from the repo root. [EVALS.md](../_maintenance/work-wave/EVALS.md) carries the live end-to-end scenarios.

## License

MIT, per the [collection license](../LICENSE). This skill is part of the [skills collection](..).
