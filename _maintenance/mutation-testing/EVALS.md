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

Commit it clean, with the suite green, before each scenario.

## Scenarios and Pass Conditions

### 1. The Plausible Mutation Fails Exactly the Pinning Test

**Setup:** the fixture repo, clean and green. A diff that adds the `save()` guard, presented as work about to be called done.

**Commands:**

```
> add the version guard to save() and let me know when it's done
```

**Pass condition:** the skill fires on its own, without being named. It identifies the guard, names the quantity it watches as the record's version read inside the transaction, and writes a plausible mutation that hoists the read above the transaction. The suite run reports exactly one failure, the test that pins the rejection, named. The report quotes pytest's own summary line verbatim—`1 failed, 12 passed in 0.14s` or whatever the run actually prints—rather than a count assembled by hand. Fails if the mutation is an arbitrary break that produces a wide failure count, if the skill has to be invoked by name, or if the report gives a number with no runner line behind it.

### 2. The Adversarial Mutation Slips, and Is Reported First

**Setup:** the fixture repo, with a diff adding the `formatted_count()` guard.

**Commands:**

```
> add the count guard to report.py and let me know when it's done
```

**Pass condition:** the skill writes an adversarial mutation that makes rows outside the batch change while leaving the formatter's self-reported count correct, and the suite stays green. The verdict is `slipped`, it appears ahead of every plausible-mutation row in the report, and it names the quantity the guard should have been watching instead—the rows actually touched, rather than the count the formatter prints about itself. Fails if the guard is reported as adequately covered, if the slipped row is buried below the measurements, or if only a plausible mutation was attempted.

### 3. Restore Leaves the Tree Identical

**Setup:** the fixture repo, with a scenario-1 or scenario-2 run in progress.

**Commands:**

```
git status --porcelain     # before the run
git status --porcelain     # after the report
git diff
```

**Pass condition:** the two status outputs are identical, `git diff` is empty, and the skill restored each mutated path by name. Fails on any leftover mutation, any missing file, and, most importantly, on a restore performed with a directory argument even where the tree happens to come back clean, since that is the command that produced the near miss.

### 4. A Directory Restore Is Caught by the Snapshot Check

**Setup:** a scratch copy of the fixture repo where the restore step is deliberately performed as `git checkout -- app/` while an uncommitted new test sits in `tests/`. Run the skill's Step 3 by hand to that point.

**Commands:**

```
git status --porcelain > /tmp/before.txt
# apply mutation, run suite, then restore with the directory form
git status --porcelain | diff /tmp/before.txt -
```

**Pass condition:** the diff is non-empty, the skill stops and names the path that differs, and it does so before the suite result is read as a measurement. Fails if the run reports a clean restore, and fails if it notices only because the test count looked wrong—the snapshot comparison has to be what catches it.

### 5. A Test Added Mid-Run Forces a Re-Measure

**Setup:** a scenario-1 run, interrupted after its first measurement. Add a test to `tests/test_storage.py` that exercises the same return value the guard protects, so the plausible mutation's failure count moves.

**Commands:**

```
> here's another test for that path, can you add it — then give me the numbers for the PR
```

**Pass condition:** the skill re-runs the mutation against the grown suite before quoting any count, and the number in its report is the post-growth one. Fails if it quotes the pre-growth count, and fails if it re-measures only because the user asked—Step 4 is triggered by a number leaving the run, not by a request.

### 6. A Guard With No Test Is Reported Before Any Mutation Runs

**Setup:** the fixture repo with a diff that adds a third guard to `app/storage.py` and no test for it.

**Pass condition:** the untested guard is named in the report, the report says there is nothing to measure there, and that row appears before the first mutation's results. Fails if the skill writes a test to make the guard measurable—that is the work under review, not this skill's job.

## What These Evals Do Not Cover

They run on pytest. A runner whose summary line has a different shape is exactly the case decision 6 in the ledger was written for, and nothing here exercises one—a `go test` or `vitest` fixture would be the next one worth building.

They run on a suite that finishes in under a second, so the Known Limitation about suite runtime bounding the mutation count goes untested. The failure mode there is a run that quietly measures fewer guards than it named in Step 1, which no scenario here would notice.

And nothing here exercises an equivalent mutant. Producing one on purpose means writing a mutation no test could distinguish, and then checking the report says it is waiting on a human ruling rather than calling it a gap.
