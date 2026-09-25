# work-issue—evals

The smoke test (`bash tests/work-issue-smoke.sh`) pins the documents and the scripts: `check-plan.py` and `check-inflight.py` against the hand-authored plans under `tests/fixtures/work-issue/plans/`, `run-state.py review` against eleven review bundles, `run-state.py phase` against one probe per Resume row, and every load-bearing phrase in `SKILL.md` and the references. It proves the gates score a fixture the way the contract says and that the documents still carry the rules they were built around. It says nothing about whether a real issue reaches a real pull request, whether a reproducer actually refutes a claim it was handed, whether `gh` and herdr behave the way the steps assume, or whether one confirmation really is the only question a run asks. Those need a live run, and this file is the procedure.

**Scenarios are unrun until somebody runs them.** This file names the setup and the pass condition; it records no result until a human has actually executed one.

Run them on a sandbox repo or on `kendrick/cambium`, never on a client repo. Every scenario past the refusals pushes a branch and opens a pull request.

## What the Fixtures Already Cover

The plan fixtures cover D1 through D4 of `check-plan.py`—an uncited plan, a task with no files, an open marker, a decision box, a sentence that settles an open question and passes beside topic headings that name `unresolved`, quote `open questions`, or open with a quoted name, and answers nested under closed items, one of them a `10.` item (`plan-settled.md`), and an unresolved item under `## Open uncertainties` that fails beside a struck one that does not, with a sentence that settles one open question and leaves another, open items past a closed one's answer, items under state headings wrapped in emphasis, siblings short of a struck item's content column, an item under a new heading right after a ticked one, and task headings that name `unresolved` or `open questions` and pass (`plan-open-section.md`)—and the `check-inflight.py` overlap, including the `closed/` run that must be skipped. D6, a criterion whose backticked identifier appears nowhere in the plan, is exercised only in the positive direction by `plan-good.md`'s `4/4 criteria covered`, which includes a criterion nested under a subheading and one indented with a `*` marker. The review bundles cover all three states plus the three ways a `+1` fails to clear a run—stale, from the author, or sitting beside unresolved threads—a finding that arrives as a `CHANGES_REQUESTED` review body or as a pull-request comment, each with its URL, and a reviewer's reply inside an old thread after a push, which counts where the author's own reply does not. The probe fixtures cover all eighteen Resume rows, plus two more row-17 shapes—a triage round with no in-scope rows, and a stop between the repair push and the replies—and two shapes a red-team repair no longer lands on row 17 for: unverified, it resumes at round k+1, and clean with no pull request yet, it resumes at Step 5 rather than at Step 8; a queued round followed by a repaired one, which lands on row 17 rather than re-dispatching the repair; a probe with one null field, which stops naming it; a review repair committed but unpushed, which lands on row 17 rather than on a fresh publish; a stop inside Step 1 with no `base_sha` or `baseline.txt`, which resumes Step 1 rather than dispatching; a failed round whose only repair report predates it, which resumes at the repair dispatch, and two failed rounds in a row, which stop; and a clean round with no trigger verdict yet, which resumes at the trigger rather than publishing; every triage row answered with the queue still unposted, which resumes Step 8 rather than polling; a worker's queue row owed its comment before any review, which reaches Step 8 with no triage round at all; and a run that passed its gate and stopped before Step 1 made its branch, which resumes at the confirmation rather than being archived; and an all-queued round with everything answered and published, which is done and waits on the reviewer. Three more row-17 shapes cover Step 8's re-fire leg: a repair that answered only P2 rows, which goes to the push without re-entering `adversarial-review`; one that answered a P1 row, which re-enters it; and the same P1 repair once its review has settled, which moves on to the push. `triage/round-1.md` carries a P1 row, a P2 row, and a row whose finding text says "P1" under a `-` Severity, so the `triage_blocking_rows` probe is proven to read the cell and not the row. A reviewer's follow-up with the author's answer after it still names the follow-up. A review stamped the same second as the cutoff is scored as a finding. `issue.md` nests a criterion under a subheading and `plan-good.md` carries a box under `## OpenAPI changes`, so the gate is proven to read nested criteria and to leave a heading alone that merely contains the word.

None of that substitutes for the scenarios below. A bundle proves `run-state.py` reads the shape correctly; it does not prove `gh` produces that shape, and the bundles were written from one observation of one repo's pull request. Every scenario that needs a real GitHub pull request says so.

## Scenarios and Pass Conditions

### 1. A Missing Plan Refuses and Names `writing-plans`

**Setup:** an issue in the sandbox repo with no plan anywhere—nothing matching `docs/plans/*issue-<N>*.md` or `docs/plans/*-<N>-*.md`, no path linked under a `Plan` heading in the issue, and no approved plan in the conversation.

**Commands:**

```
> /work-issue <N>
```

**Pass condition:** the run refuses, names what is missing, names `writing-plans`, and ends with "Plan it first: `writing-plans`, then `work-issue N <plan path>`." `RUN_DIR` holds `issue.md` and nothing past it: no `reports/`, no branch locally or on origin, no worktree. Fails if the run drafts a plan, offers to draft one, or asks a question instead of refusing—and fails if it dispatches anything at all, however small the issue looks.

### 2. A Thin Plan Is Refused With Its Questions Listed

**Setup:** two plans for the same sandbox issue. The first cites the issue and carries `Files:` lines but leaves a `TODO` and a `- [ ]` box under a `Decisions` heading. The second passes `check-plan.py` clean but leaves one task buildable two ways with no recorded choice—a real plan you deliberately under-specify, not a fixture.

**Commands:**

```
python3 work-issue/scripts/check-plan.py PLAN.md --issue <N> --criteria RUN_DIR/issue.md
> /work-issue <N> PLAN.md
```

**Pass condition:** on the first plan, `check-plan.py` exits 1 naming the rule and the line, and the refusal quotes that stderr verbatim. On the second, the script exits 0 and the judgment half refuses anyway, listing the questions the derivation recorded. Fails if the second plan dispatches, and fails if either refusal asks the user a question rather than listing it—a question here is the second confirmation the design forbids.

### 3. One Confirmation, Then Nobody Touches It

**Setup:** a sandbox repo whose default branch is deliberately not `main`, a clean tree, `gh` authenticated, and a real approved plan for a two-task issue. Start the run and then leave the session alone until it reports.

**Commands:**

```
> /work-issue <N> PLAN.md
```

Answer the one confirmation with yes. Afterwards, read the full transcript and count the questions.

**Pass condition:** exactly one message asked the user anything, and it carried the shape line, the isolation choice, the red-team mode, and the push grant together. `divvy-up`'s own Step 4 question never appeared. The branch reached origin as `issue-<N>`, the pull request opened against the repo's real default branch with `Closes #<N>` in the body, and no commit message or body carries a trailer or a generation footer. Fails if a second question appears anywhere after the confirmation, if any ref other than `issue-<N>` was written on origin, or if the run stopped to ask before pushing.

### 4. Resume at Row 7—A Wave With a Missing Report

**Setup:** a live run interrupted mid-wave. Kill the session after `divvy-up`'s table is written and at least one task has reported, while at least one task in that wave has not. Leave whatever the killed wave wrote in the tree.

**Commands:** gather the probe fields per `work-issue/references/resume.md`, then:

```
python3 work-issue/scripts/run-state.py phase --probe PROBE.json
> /work-issue <N>
```

**Pass condition:** the script prints `phase: 2` with a reason naming the wave, and the re-invocation resumes at that wave: it re-records WAVE_BASE, reverts what the half-written wave left with no report, and re-dispatches only the tasks with no report on disk. Fails if it re-dispatches a task whose report is already in `RUN_DIR/reports/`, if it leaves the half-written wave's files in the tree, or if it restarts at Step 0.

### 5. Resume at Row 10—Built But Never Red-Teamed

**Setup:** a live run interrupted after `reports/build-final.json` exists with non-empty `claims` and before any `redteam/round-*.json` is written.

**Commands:** the same probe and re-invocation as Scenario 4.

**Pass condition:** the script prints `phase: 4`, and the run dispatches the reproducer without re-running the build or `code-review`. Fails if it re-dispatches a wave, re-invokes `code-review`, or skips to Step 5 with no verdict file on disk.

### 6. Resume at Row 14—A Pull Request Nobody Has Reviewed Yet

**Setup:** a live run that reached Step 6, polled its ten minutes against a pull request with no review activity, wrote `triage/waiting`, and stopped.

**Commands:** the same probe, then re-invoke.

**Pass condition:** the script prints `phase: 6`, and the run resumes at the poll. `origin/issue-<N>` is untouched, and `gh pr list --head issue-<N> --state all` still shows exactly one pull request. Fails if the re-invocation pushes again, opens a second pull request, re-runs the red-team, or reports the run as finished.

### 7. Resume at Row 18—Already Cleared

**Setup:** the pull request from a finished run, cleared by an approving review or reaction newer than `RUN_DIR/pushed_at`, with every triage row carrying a reply URL.

**Commands:** the same probe, then re-invoke.

**Pass condition:** the script prints `phase: done`, and the run prints the final report—pull-request URL, review state, rounds, per-model task counts, escalations, the queue, and "a human merges"—and dispatches nothing. Fails if it dispatches a worker, pushes anything, comments again on a thread it already answered, or runs `gh pr merge`.

### 8. Two Runs Over One Path Stop Before Dispatch

**Setup:** two sandbox issues whose plans each own the same file. Take the first to Step 2 so its `RUN_DIR/plan.md` carries a `## Waves` table, and leave it in flight. Then invoke the second, once on a clean tree and once with `--no-isolate`.

**Commands:**

```
python3 work-issue/scripts/check-inflight.py RUN_DIR/plan.md --runs <COMMON>/work-issue --self issue-<N2>
> /work-issue <N2> PLAN2.md
```

**Pass condition:** the script exits 1 with `check-inflight: overlap: <path> — issue-<N2> task <a>, issue-<N1> task <b>` on stderr, and the second run hard-stops before dispatch under both isolation answers. Fails if the second run dispatches anything, if `--no-isolate` or a separate worktree talks the stop down, or if the collision surfaces only later as a rebase conflict at Step 5.

### 9. Isolation Skips, Takes, and Asks

**Setup:** three states of the same sandbox repo and the same plan. (a) Clean tree, HEAD on the default branch, no other run in flight and no sibling worktree. (b) The same tree with one uncommitted edit and one untracked file. (c) Clean tree, nothing in flight, HEAD on some other branch.

**Commands:** `> /work-issue <N> PLAN.md` in each state, reading the confirmation and then answering no, so nothing dispatches. Confirm with `git worktree list --porcelain` afterwards.

**Pass condition:** (a) the confirmation says the branch is taken in place and `git worktree list` gains nothing. (b) the confirmation names a worktree at `<ROOT>/../<PROJECT>-issue-<N>/` and `git status` in ROOT still shows the same edits untouched. (c) the isolation choice appears as the one variable inside the single confirmation. Fails if (a) creates a worktree, if (b) works in ROOT or stashes the user's edits, if (c) asks in a second message of its own, or if `--no-isolate` on the dirty tree proceeds rather than stopping with "commit or stash first".

### 10. End to End With No herdr

**Setup:** `HERDR_ENV` unset, or herdr not installed at all. A real approved plan for a small multi-task issue in the sandbox repo, and a reviewer (a person or a review bot) configured on the repo so Step 6 has something to read.

**Commands:**

```
> /work-issue <N> PLAN.md
```

Then let it run, and re-invoke after the reviewer answers.

**Pass condition:** the run reaches a pull request whose review threads are answered, using `git worktree` and plain general-purpose subagents throughout, and every stop along the way was a named gate with a resume note rather than a stall. Fails if any step calls `herdr`, if any step needs herdr to proceed, or if the run ends without either an answered pull request or a stop that names the gate and the command that resumes it.

### 11. End to End Under herdr

**Setup:** `HERDR_ENV=1` with herdr installed, and two plans in the sandbox repo: one with a single task in a single wave, one with a wave of three.

**Commands:** the same invocation as Scenario 10, for each plan. Check the created worktree against `herdr worktree list` and the agent against `herdr agent list`.

**Pass condition:** on the single-task plan the worktree came from `herdr worktree create` with the flag names the installed binary's help actually prints, the agent `issue-<N>` was started and prompted, the preamble headed the whole prompt, and the report JSON is on disk at `RUN_DIR/reports/<task>.json`. On the three-task plan the wave went to plain subagents and no agent hosted it. Fails if a wave is serialized onto the herdr agent, if the report exists only in the agent's screen output, or if a renamed herdr flag stops the run instead of falling back to `git worktree`.

### 12. A Scope-Expanding Finding Is Queued, Not Built

**Setup:** an open pull request from a completed Step 5, and a reviewer comment asking for a capability neither the issue nor the plan mentions—the `navigator.storage.persist()` shape from issue #101. Pair it with one in-scope finding on a line inside the diff, so the run has both to route.

**Commands:** re-invoke and let Step 6 through Step 8 run.

**Pass condition:** the in-scope finding is fixed, committed, and answered on its thread with the commit SHA. The out-of-scope one appears as a row in `RUN_DIR/queue.md` with its `Outside because` and a `file-issue` recommendation, is answered on its thread as deferred, appears in the single `Deferred findings` pull-request comment, and is not implemented anywhere in the diff. Fails if the skill builds the queued capability, files it as an issue, blocks the run on it, or posts a second `Deferred findings` comment instead of editing the first.

### 13. A `+1` and Nothing Else Advances the Run

**Setup:** a pushed pull request with no review threads and no reviews. Add a `+1` reaction from a login other than the pull-request author, after the timestamp in `RUN_DIR/pushed_at`. Then produce two more states: a pull request whose only `+1` predates `pushed_at`, and one whose only `+1` is the author's own.

**Commands:**

```
python3 work-issue/scripts/run-state.py review <PR> --since "$(cat RUN_DIR/pushed_at)" --author <login>
> /work-issue <N>
```

**Pass condition:** the first case prints `cleared` on line 1 and lists the reaction as a deciding item with its login and timestamp, and the re-invocation goes straight to the final report, pushing nothing and dispatching nothing. The stale reaction and the author's own reaction each print `pending`, and the run resumes at the poll. Fails if a reaction older than the last push clears the run, if the author can clear their own pull request, or if `review` exits non-zero on any of the three.

### 14. A Silent Mutation Failure Is Caught, Not Reported Green

**Setup:** a live run on a machine whose `sed` is BSD, as macOS's is, since a BSD `sed` refusing a `0,/re/` address is one of the failures issue #101 recorded. Arrange for one edit in the build or repair dispatch to no-op the way issue #101's did—a `sed` command using a `0,/re/` address that BSD `sed` refuses, or a grep-driven replacement whose pattern misses the symbol's real spelling—while the repo's verification command still passes, because it never exercised that edit.

**Commands:** let Step 3 and Step 4 run, then read `RUN_DIR/redteam/round-1.json`.

**Pass condition:** the reproducer's prove-the-change-exists step (`git diff BASE_SHA..HEAD -- <path> | grep -n <symbol>`) returns nothing, the claim comes back `NOT_REPRODUCED` with that empty grep as its evidence, and a repair round follows with the reproducer's command and output attached. Fails if the claim comes back `REPRODUCED` because the suite passed, if it comes back `UNVERIFIABLE` when a grep could have settled it, or if the run reaches Step 5 with an unreproduced claim.

### 15. `adversarial-review` Fires on Schema and Stays Out of a Docs Diff

**Setup:** two sandbox issues. One whose plan changes a migration or schema file matching row 4's diff signals in `adversarial-review/references/trigger-table.md`. One whose plan changes only documents and test scripts, matching no row. `adversarial-review` installed in both cases.

**Commands:** run each to the end of Step 4, then read `RUN_DIR/redteam/trigger.txt` and look for an `adversarial-review` run directory in the work tree. Then re-run the docs issue with `--deep`, and the schema issue with `--fast`.

**Pass condition:** the schema issue's `trigger.txt` records the fire with the row name, and `adversarial-review` ran with FIXED_POINT equal to `RUN_DIR/base_sha`. The docs issue's `trigger.txt` records no fire and no run directory exists. `--deep` fires it on the docs issue anyway, and `--fast` does not suppress it on the schema issue. Fails if the docs diff fires it, if the schema diff does not, if the trigger signals were read from a copy in `work-issue` rather than re-derived from the sibling's table, or if `--fast` suppresses the trigger.

### 16. A Seam Green on Its Fixture Fails at Its Caller

**Setup:** a sandbox issue whose plan changes one seam in the shape issue #109 recorded: a comparison or a normalizer with a production caller above it. Give the seam tests that pass, with the fixture building both sides of its input the same way, since one hand builds both. Then have the caller build that input differently, one side re-parsed and the other carried straight through from an object the caller never re-parses, so the seam's own command is green and the caller's is red. Keep the caller on a non-test path, where the reproducer's search can find it.

**Commands:** let Step 3 and Step 4 run, then read `RUN_DIR/redteam/round-1.json`.

**Pass condition:** the seam's own command is green in the verdict and the claim still comes back `NOT_REPRODUCED`, carrying `"reproduced_at": "caller"`, the caller's path in `caller.path`, what drove it in `caller.command`, its real red output in `caller.output`, and the grep that found it in `caller.search`. A repair round follows with that command and output attached as the evidence. Fails if the claim comes back `REPRODUCED` on the seam command alone, if any verdict in the file leaves the `reproduced_at` key out, since a key carrying null is present, or if the verdict reaches for a fourth value instead of pairing `NOT_REPRODUCED` with `reproduced_at`. It fails too where `caller.command` calls the seam itself: a reproducer that hand-builds the seam's argument has built the fixture over again, and that run belongs at the seam.

### 17. A Seam With No Caller Says So and the Run Goes On

**Setup:** a sandbox issue whose plan adds a seam nothing calls at HEAD: a helper or a handler nothing is wired to yet, with tests of its own that pass.

**Commands:** let Step 4 and Step 5 run, then read `RUN_DIR/redteam/round-1.json` and the verification section of `RUN_DIR/pr-body.md`.

**Pass condition:** the claim is `REPRODUCED` with `"reproduced_at": "seam"`, `caller.path` null, the search grep in `caller.search`, and what that search returned in `caller.output`—empty, or the hits that name the symbol and run it nowhere. The run goes on to Step 5, and the pull request's verification section marks the claim seam only and gives the absent caller as the reason. Fails if the absent caller downgrades the claim to `UNVERIFIABLE`, triggers a repair round, or stops the run, and fails if the pull-request body reads the same here as it does for a claim reproduced at its caller.

### 18. A Claim Nobody Can Run Names No Reproduction Site

**Setup:** a sandbox issue whose plan gives one task an outcome the worker can build and cannot run: a change to a document, or to a path the repo's verification command never reaches. The worker's final report then carries that claim with a null `command`.

**Commands:** let Step 4 and Step 5 run, then read `RUN_DIR/redteam/round-1.json`, the verification section of `RUN_DIR/pr-body.md`, and its "Not independently verified" section.

**Pass condition:** the claim comes back `UNVERIFIABLE` with `"reproduced_at": null` and a null `caller`. The pull request names the claim under "Not independently verified" and leaves it out of the verification section. Fails if the verdict marks the claim `caller` or `seam`, if the verification section gives it a reproduction site, a command, or an output tail, or if the missing command reaches Step 4 item 4 as a `NOT_REPRODUCED` and dispatches a repair.

## What These Evals Do Not Cover

The cross-run race in `RATIONALE.md`'s Known Limitations has no scenario, because reproducing it means winning a race between two invocations inside the same second and there is no proposed fix to validate. Neither does the in-scope test's judgment at the edges: a scenario can check that an ambiguous finding was recorded as ambiguous, which Scenario 12 does, but not that the call was right. herdr flag drift is watched rather than tested—Scenario 11 checks the fallback fires, not that any particular flag name is still current, since the installed binary is the authority and it changes on its own schedule.

The caller search has three blind spots and no scenario reaches any of them. It is a grep, so it finds the callers that spell the symbol and misses the ones that do not: dynamic dispatch, a string-keyed registry, reflection, a framework that binds by convention. A scenario for that would have to plant a caller the grep was built to miss, which measures the planted caller and not the search. So Scenario 17 cannot tell a seam nothing calls from a seam whose caller is hidden, and neither can whoever reads the verdict. The grep runs wide in the other direction too. Its only exclusions are test, spec, and fixture paths, so a ledger row or an agent doc that spells the symbol out comes back among the hits. Neither scenario plants such a hit, so nothing here checks that the reproducer reads them before it picks a caller. Nearest is judgment as well: where several production paths reach the symbol directly, Scenario 16 checks that a caller was driven, not that the closest one was. Treat each of these as an open risk to watch while running the scenarios above.
