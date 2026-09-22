# mutation-testing—evals

The smoke test (`bash tests/mutation-testing-smoke.sh`) pins the documents: that the skill ships its four artifacts, that the description triggers on what a diff adds rather than on a kind of file, that both questions and all three rules survive with the failures that taught them, and that every cut in Deliberately Not Built stays cut. It proves the skill still says what it was built to say.

It says nothing about whether the skill works. Whether a mutation is caught cannot be pinned by grep: it needs a real guard, a real suite, and a real runner printing a real summary line. Whether the plausible mutation is the one a person would write is a judgment the skill makes at run time against code the test has never seen. And the restore check only earns its place if it actually stops a run, which needs a run to stop. Those are the scenarios below.

**Scenarios are unrun until somebody runs them.** This file names the setup and the pass condition; it records no result until a human has actually executed one.

Run them against the fixture repo described below, never against a project you care about. Every scenario deliberately breaks working code and relies on the restore step to put it back.

## The Fixture Repo

A throwaway git repo, created fresh per scenario run, holding one guard and a small pytest suite:

- `app/storage.py` — a `save(record, conn)` that reads the record's current version inside the transaction that writes it, and rejects the write when the version moved. That read-inside-the-transaction is the guard, and hoisting it above the transaction is the plausible mutation the skill should reach for.
- `app/report.py` — a `formatted_count()` that returns the number of rows the formatter itself reports having touched, and a guard asserting it equals the number of rows handed in. The guard watches a proxy, which is what makes it the adversarial case: a write that touches rows outside the batch leaves the proxy correct and the invariant broken.
- `tests/test_storage.py` — one test pinning the rejection, plus enough unrelated passing tests that a count like "fails 1, leaves 12 green" is a real measurement rather than an arithmetic accident.
- `tests/test_report.py` — a test asserting `formatted_count()` matches the batch size, and nothing asserting anything about rows outside it.

**Commit a guardless base first.** The fixture above describes the repo *after* the work; the scenarios need the state before it. So commit a version of `app/storage.py` and `app/report.py` with their guards removed, and the tests that pin those guards absent, and check the suite is green on that base.

**Each scenario's uncommitted work is the guard *and* its pinning test, together.** That pairing is not optional, and leaving it out makes every scenario vacuous in a way that looks like a pass: Step 1 finds a guard with no test, reports it as such, and Step 2 runs no mutation for it at all, so nothing any scenario measures ever happens. Scenario 7 needs a pinning test for `lib/storage.py` as well as for `app/storage.py`, since it runs two guards.

That uncommitted pair is the diff the skill is invoked on.

Committing the fixture as described instead — guards and all — leaves no diff adding a guard, so Step 1 finds nothing and every scenario passes vacuously while testing none of the behaviour it names.

Take the base as a fresh clone or a `git worktree` per scenario, so one scenario's mutations cannot reach the next.

## Scenarios and Pass Conditions

### 1. The Plausible Mutation Fails Exactly the Pinning Test

**Setup:** the guardless base, clean and green. Uncommitted work adding the `save()` guard **and** the test in `tests/test_storage.py` that pins it, presented as work about to be called done.

**Commands:**

```
> add the version guard to save() and let me know when it's done
```

**Pass condition:** the skill fires on its own, without being named. It identifies the guard, names the quantity it watches as the record's version read inside the transaction, and writes a plausible mutation that hoists the read above the transaction. The suite run reports exactly one failure, the test that pins the rejection, named. The report quotes pytest's own summary line verbatim—`1 failed, 12 passed in 0.14s` or whatever the run actually prints—rather than a count assembled by hand. Fails if the mutation is an arbitrary break that produces a wide failure count, if the skill has to be invoked by name, or if the report gives a number with no runner line behind it.

### 2. The Adversarial Mutation Slips, and Is Reported First

**Setup:** the guardless base, with uncommitted work adding the `formatted_count()` guard and the test in `tests/test_report.py` that pins it.

**Commands:**

```
> add the count guard to report.py and let me know when it's done
```

**Pass condition:** the skill writes an adversarial mutation that makes rows outside the batch change while leaving the formatter's self-reported count correct, and the suite stays green. The verdict is `slipped`, it appears ahead of every plausible-mutation row in the report, and it names the quantity the guard should have been watching instead—the rows actually touched, rather than the count the formatter prints about itself. Fails if the guard is reported as adequately covered, if the slipped row is buried below the measurements, or if only a plausible mutation was attempted.

### 3. Restore Leaves the Tree Identical

**Setup:** the guardless base with scenario 1's or scenario 2's uncommitted work applied, and that run in progress.

**Commands:**

```
git status --porcelain -uall > /tmp/before-status.txt
git diff > /tmp/before-diff.txt
# ... run the skill ...
git status --porcelain -uall | diff /tmp/before-status.txt -
git diff | diff /tmp/before-diff.txt -
```

**Pass condition:** both comparisons are empty — status and `git diff` each match what they printed before the run — every mutated path matches the backup taken outside the repo in contents and in mode, and the skill restored each path by copying its backup back. `git diff` is compared against what it printed before the run, never against empty. Under the guardless base every scenario's tree is dirty by construction — the guard and its test are the uncommitted work the skill was invoked on — so an empty `git diff` afterwards is the signature of the destructive restore, not of a clean one: it means the work being measured is gone. Run it a second time with a further uncommitted edit that is not part of the guard — an unrelated change to `app/report.py`, say, standing in for work the user had in flight — and confirm both that the edit survives untouched and that the contents check is what would catch a failed restore of it, since status reads ` M app/report.py` either way and cannot. Fails on any leftover mutation, any missing file, and on a restore performed with `git checkout` in any form, by directory or by name, even where the tree happens to come back clean. The directory form is the one that produced the near miss; the by-name form is the one that deletes the user's uncommitted guard, so a run that restored with `git checkout -- app/storage.py` fails this scenario outright.

### 4. A Directory Restore Is Caught by the Snapshot Check

**Setup:** a scratch copy of the fixture repo above, unchanged — `app/storage.py`, `app/report.py`, `tests/test_storage.py`, `tests/test_report.py`. Add the new test as an **uncommitted edit to the tracked `tests/test_storage.py`**, mutate `app/storage.py`, and then perform the restore deliberately wrong, as `git checkout -- .` from the repo root.

Every part of that is load-bearing, and getting any of it wrong makes the scenario unable to fail. The restore has to reach both the mutation and the collateral, which is why it runs from the root rather than against `app/` alone. The collateral has to be an edit to a **tracked** file: `git checkout -- <dir>` restores tracked files from the index and leaves untracked ones alone, so a brand-new unstaged file survives the restore and the scenario proves nothing. And the collateral has to sit under the restored path, since a file outside it is never reached at all.

Run the skill's Step 3 by hand to that point.

**Commands:**

```
git status --porcelain -uall > /tmp/before.txt
# apply the mutation to app/storage.py, run the suite, then restore with the
# directory form, which reverts the tracked test file's uncommitted edit along
# with it
git checkout -- .
git status --porcelain -uall | diff /tmp/before.txt -
```

**Pass condition:** the diff is non-empty — the ` M tests/test_storage.py` line is present before the restore and gone after — the skill stops and names the path that differs, and it does so before the suite result is read as a measurement. Confirm the new test function is actually gone from the file, rather than trusting the status line alone. Fails if the run reports a clean restore, and fails if it notices only because the test count looked wrong—the snapshot comparison has to be what catches it.

### 5. A Test Added Mid-Run Forces a Re-Measure

**Setup:** a scenario-1 run, interrupted after its first measurement. Add a test to `tests/test_storage.py` that exercises the same return value the guard protects, so the plausible mutation's failure count moves.

**Commands:**

```
> here's another test for that path, can you add it — then give me the numbers for the PR
```

**Pass condition:** the skill re-runs the mutation against the grown suite before quoting any count, and the number in its report is the post-growth one. Fails if it quotes the pre-growth count, and fails if it re-measures only because the user asked—Step 4 is triggered by a number leaving the run, not by a request.

### 6. A Guard With No Test Is Reported Before Any Mutation Runs

**Setup:** the guardless base with uncommitted work adding a third guard to `app/storage.py` and, deliberately, no test for it. This is the one scenario where the guard arrives unpaired, which is the condition it exists to check.

**Pass condition:** the untested guard is named in the report, the report says there is nothing to measure there, and that row appears before the first mutation's results. Fails if the skill writes a test to make the guard measurable—that is the work under review, not this skill's job.

### 7. Two Guards Sharing a Basename Keep Separate Backups

**Setup:** extend the guardless base with `lib/storage.py` alongside `app/storage.py`, each carrying its own uncommitted guard and its own uncommitted pinning test, and a diff that adds all four. The basenames collide; the paths do not.

**Commands:**

```
# after the run, for each path:
cmp app/storage.py <its backup>
cmp lib/storage.py <its backup>
grep -c 'APP' app/storage.py ; grep -c 'LIB' lib/storage.py
```

**Pass condition:** each path has its own backup at a destination mirroring its full repo path, and each file comes back holding its own guard. Fails if one backup overwrote the other, which is the case worth constructing deliberately: with a flat scratch directory both `cmp` checks pass and `git status --porcelain` is unchanged, while `app/storage.py` holds `lib`'s contents and nothing in git has a copy of what was lost. Check the file contents, never the checks' verdicts, since the verdicts are what the defect corrupts.

**Also check mode.** Give one fixture file mode 755, run under `umask 077`, and confirm the backup's mode matches the source rather than the umask, and that the restored file's mode matches the backup rather than the mutated file's.

## What These Evals Do Not Cover

They run on pytest. A runner whose summary line has a different shape is exactly the case decision 6 in the ledger was written for, and nothing here exercises one—a `go test` or `vitest` fixture would be the next one worth building.

They run on a suite that finishes in under a second, so the Known Limitation about suite runtime bounding the mutation count goes untested. The failure mode there is a run that quietly measures fewer guards than it named in Step 1, which no scenario here would notice.

And nothing here exercises an equivalent mutant. Producing one on purpose means writing a mutation no test could distinguish, and then checking the report says it is waiting on a human ruling rather than calling it a gap.
