# mutation-testing

Breaks a guard your diff just added, runs the suite, and tells you which tests noticed.

## Why This Exists

A guard nobody has watched fail is not a guard. You can read the rejection in the diff and still have no idea whether a single test would catch its absence, and reading harder does not help: two `code-review` passes across four subagents returned nothing that changed a line on a ticket whose entire content was a new rejection rule.

One mutation run on that same code produced four measurements in minutes. The useful one became the most useful sentence in the pull request: hoisting a read out of its write transaction fails exactly one test and leaves 62 green, so a reasonable-looking refactor reintroduces the original defect with the suite still passing. Nothing in the diff says that, and nothing else in the toolkit asks for it.

So this skill fires on what a diff **adds**—a rejection, a validation, an invariant, a limit, a permission check, a branch that turns input away—rather than on what kind of file it lands in. A formatting change to a file full of guards adds none. One line added to a controller may add one.

## How It Works

It names the guards first, and for each one writes down the quantity it watches. That column does the work later, so it records what the guard actually reads—the value in the variable it compares—rather than the outcome somebody meant it to protect. A guard with no test gets a row saying so, before any mutation runs, because there is nothing to measure and the absence is the finding.

Then two mutations per guard that has a test, because there are two questions and neither mutation answers the other's. An unpinned guard gets no mutation, since zero failures there would read exactly like the real gap this skill is looking for:

- **Would a reasonable refactor slip past this suite?** That takes the **plausible** mutation: the edit a person cleaning up the code would actually make, like hoisting a read above the transaction that writes it. The output is a measurement. An arbitrary break measures nothing, and the run behind this skill proved it: mutating a read into a form that stalls under the test double produced 21 failures and said only that the test double was load-bearing.
- **Is this guard watching the right quantity at all?** That takes the **adversarial** mutation: make the failure the guard exists to catch happen by a route the guard's proxy cannot see. The output is a verdict, caught or slipped. A plausible mutation can never answer this one, because a guard watching the wrong quantity survives every reasonable edit to the right one. In the case that taught it, a guard read the file count a formatter printed about itself and passed cleanly while the tree-wide write it existed to catch had already happened.

Mutations run one at a time, each against a tree the previous one put back. Apply, prove the edit actually landed on disk, run the suite, restore, compare. Proving the edit matters here: an edit that silently failed to apply leaves the suite green, and green reads in this skill as "no test catches this", which is the exact inverse of what happened.

Restore happens **by name**, one path at a time. `git checkout -- app/storage/` once reverted a new test alongside the mutation, and the suite came back green without it, caught on the test count rather than noticed, which makes it a near miss rather than a save. So every restore is checked twice. Each mutated path is compared against the backup taken outside the repo, in contents and in mode, and the whole tree's `git status --porcelain` is compared against a snapshot from before the first mutation. Neither check sees what the other does: status reports codes rather than contents, so a file you had already edited reads ` M path` whether it holds your work or a live mutation, while the contents check is blind to a casualty among the files no mutation touched.

Counts go stale, so the baseline and its snapshot are re-taken and every mutation re-runs against the final suite before any number leaves the run. The re-take happens only from a tree whose restores have just passed, because absorbing a still-applied mutation into the snapshot would retire the restore check for the rest of the run. One mutation moved from 2 failures to 4 once a later test began exercising the same return value, and extrapolating from the earlier run would have put a wrong number in a pull request, where it reads as a measurement.

The report gives one row per mutation: the guard, the question, the mutation in a line, the runner's own summary line quoted verbatim, the failing tests by name, how many passed, and the reading. Nothing parses that summary line. Runners disagree about what they report and how they phrase it, and the line as printed is what you can check against your own run. A slipped verdict that names a real gap goes first, ahead of every measurement, because it is a defect in the guard rather than a fact about the suite. Where the mutation changed nothing a caller could observe, the row is reported unresolved instead, since no test could have caught it and the guard may be sound.

## Install

```bash
npx skills add kendrick/skills --skill mutation-testing
```

Or by hand:

```bash
git clone git@github.com:kendrick/skills.git
cp -R skills/mutation-testing ~/.claude/skills/mutation-testing
```

Needs a git repo and a test suite you can run from one command. No Python, and no script to install. Every step is judgment, your runner, or `git`.

## Use

It fires on its own, which is the one place it differs from `adversarial-review` and `work-issue`; see the Gotchas for why. You will usually meet it as an interruption:

```
> add the tenant check to the list endpoint
```

It runs when that work is about to be called done. You can also name it directly, against work already on the branch:

```
> /mutation-testing
```

It asks for your test command when the project's config does not name one, and it stops before mutating anything if that command is already red. A failure that was there before is indistinguishable from one a mutation caused, and every count after it inherits the ambiguity while still reading like a measurement.

## What's Here

```
mutation-testing/
├── SKILL.md      # the skill: name the guards, write both mutations, run, re-measure, report
└── README.md     # this file
```

There is no `references/` and no `scripts/`, because choosing a mutation is judgment, the suite is your own command, and restoring is a copy-back checked by a `cmp` against the backup and a `git status` comparison against the snapshot.

## Gotchas

- **It fires on its own.** The premise of the whole thing is that nothing else asks for this measurement, so a missed trigger costs a guard its only check while a misfire costs one mutation run and a restore. Its user-invoked neighbors sit under the opposite asymmetry, so they wait to be named.
- **One mutation, one checkout, in sequence.** Restore is already the fragile step at concurrency one, and two mutations sharing a tree restore against the same snapshot and race over the same paths. The only safe fan-out is a worktree per mutation, and this skill builds none.
- **A red suite stops it before it starts.** Fix the baseline first, or every number it hands you is ambiguous.
- **The measurement is of your suite, not your guard.** "Fails 1, leaves 62 green" says one test noticed. Whether one is enough is your call, and the report is deliberately silent on it.
- **An equivalent mutant is reported unresolved, not as a defect.** A mutation that changes nothing a caller could observe could not have been caught by any test, so the guard may be sound. Those rows say they are waiting on a human ruling, and making it is yours. Where the run cannot tell an equivalent mutant from a real gap, the row says that too.
- **Ignored files restore unverified.** `git status --porcelain` says nothing about anything in `.gitignore`, so a mutation that writes into an ignored build directory sits outside the snapshot check.
- **A slow suite bounds the run.** Two mutations per guard, re-run at the end, against a ten-minute suite is a long afternoon. Fewer guards per run beats fewer mutations per guard.
- **It stays inside what the diff added.** It will not wander into surrounding code to find something else worth mutating.

## Maintainers

The decision ledger and eval suite live in [`_maintenance/mutation-testing/`](../_maintenance/mutation-testing/). Every contested choice has a row in [RATIONALE.md](../_maintenance/mutation-testing/RATIONALE.md), including everything deliberately left out and why each cut would come back. [EVALS.md](../_maintenance/mutation-testing/EVALS.md) carries the fixture repo and the six live scenarios, because whether a mutation is caught cannot be pinned by grep.

To verify this skill on its own, from the repository root:

```bash
bash tests/mutation-testing-smoke.sh
```

## License

MIT, per the [collection license](../LICENSE). This skill is part of the [skills collection](..).
