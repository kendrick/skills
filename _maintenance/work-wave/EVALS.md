# work-wave—evals

The smoke test (`bash tests/work-wave-smoke.sh`) pins the artifact: files present, load-bearing strings intact, the vendored block byte-identical to `work-issue/scripts/check-inflight.py`, and `check-footprints.py` behaving on fixed input. It says nothing about whether N real lanes reach N real pull requests, whether `--isolate` actually keeps a lane off `work-issue`'s ask row, whether a lane dispatched with the push half withheld stops where the brief says, whether a fact appended mid-run reaches a sibling's workers, or whether the merge test catches the coupling #113 lost. Those need live subagents, and this file is the procedure.

**Scenarios are unrun until somebody runs them.** This file names the setup and the pass condition. It records no result until a human has actually executed one.

Run them on a sandbox repo, never on a client repo. Scenarios 1 through 7 dispatch no lane. Every scenario from 8 on dispatches at least two `opus` lanes, and every one from 9 on can push branches and open pull requests.

Four scenarios settle a question the design left to a live run. Scenario 4 tests what `--isolate` does against the ask row, and Scenario 6 re-checks the build-only resume at Step 5. Scenario 9 follows a fact into a sibling's worker prompt, and Scenario 10 replays the schema coupling #113 lost.

## Scenarios and Pass Conditions

### 1. A Missing Plan Refuses the Whole Wave

**Setup:** three sandbox issues. Give one a plan under `docs/plans/`, and give the other two no plan anywhere: no match under `docs/plans/`, no link under a `Plan` heading in the issue, and nothing passed with `--plan`. Hold a plan for one of the two in the conversation.

**Commands:**

```
> /work-wave <N1> <N2> <N3>
```

**Pass condition:** the run refuses once, names both unplanned issues in that one refusal, and ends with "Plan them first: `writing-plans`, then `work-wave <ISSUES> --plan N=PATH`." The plan held in the conversation does not count. `git worktree list` gains nothing and no subagent is dispatched. Fails if the refusal names only the first missing plan, if the conversation plan is accepted, if the run proceeds with the one planned issue, or if it drafts or offers to draft a plan.

### 2. Two Lanes Over One Path Stop Before Dispatch, Under Both Shapes

**Setup:** two sandbox issues whose plans each own `src/lib/`. Write the first plan with `Files:` lines only. Give the second a `## Waves` table owning `src/lib`, spelled without the slash. Separately, leave a third issue's `work-issue` run in flight with a table owning a path the first plan owns.

**Commands:**

```
> /work-wave <N1> <N2>
python3 work-wave/scripts/check-footprints.py --lane issue-<N1>=WAVE_DIR/footprint/issue-<N1>.md --lane issue-<N2>=WAVE_DIR/footprint/issue-<N2>.md --runs <COMMON>/work-issue
```

Then drop issue N2 and pair N1 with a disjoint issue, so the only overlap left is the in-flight run. Last, move that run's `## Waves` table out of its `plan.md`, leaving only a `Files:` line, and invoke again.

**Pass condition:** the script exits 1 with `check-footprints: overlap: src/lib` and both owners on stderr, the run stops at Step 1, and nothing is dispatched. On the second run the stderr names `in-flight issue-<N3>` and the run stops the same way. On the third, the script exits 1 with `check-footprints: unchecked: issue-<N3> has no ## Waves table` and the run stops at Step 1, naming both ways forward. Fails if the run reaches Step 2, if either shape of the path passes as disjoint, if the in-flight run is skipped while its table parses, or if the tableless run passes as disjoint.

### 3. A Mutual Coupling Refuses the Pair

**Setup:** two sandbox issues with disjoint footprints whose plans are halves of one change: one adds a field a serializer writes, the other adds the reader that needs it, and each plan says the other is required.

**Commands:**

```
> /work-wave <N1> <N2>
```

**Pass condition:** `coupling.md` has one row for the pair, answered `mutual`, with `Evidence` quoting the lines from both plans, and resolved `refuse`. The run stops naming the two issues, and nothing is dispatched. Fails if the pair is resolved `order`, if the two lanes are serialized, or if either lane is dispatched.

### 4. An Existing Tree at a Lane's Path Refuses the Wave, and `--isolate` Is Tested Against the Ask Row

**Setup:** three sandbox issues with disjoint plans. Hand-make a worktree at `<ROOT>/../<PROJECT>-issue-<N2>/` and a plain directory at `<ROOT>/../<PROJECT>-issue-<N3>/`. Leave issue N1's path empty.

**Commands:**

```
> /work-wave <N1> <N2> <N3>
> /work-issue <N2> PLAN2.md --isolate --dry-run
```

Then remove both, start `work-issue <N1>` to its Step 2 so it owns a worktree on `issue-<N1>`, and invoke the wave again.

**Pass condition:** the first invocation refuses at Step 3 naming both existing paths in one message, and `git worktree list --porcelain` is unchanged afterwards. The direct `work-issue` dry run shows its isolation choice in the confirmation. Record whether it takes a worktree or asks, and move the result into `RATIONALE.md`'s Known Limitations, since that settles what `--isolate` does against the ask row. On the third invocation, N1's worktree passes as already started and the confirmation carries all three lanes. Fails if the wave dispatches anything or makes a worktree, if the refusal names only one path, or if N1's own registered tree refuses the wave.

### 5. `--dry-run` Touches Nothing

**Setup:** two sandbox issues with disjoint plans and a clean tree. Record `git worktree list --porcelain`, `git branch -a`, and `ls <COMMON>/work-issue/` first.

**Commands:**

```
> /work-wave <N1> <N2> --dry-run
```

**Pass condition:** the run renders the Step 3 confirmation, with lanes, footprint count, coupling, merge order, and held lanes, and stops. The three recorded listings are unchanged, and no `merge-test/0.md` exists. Fails if any worktree, branch, RUN_DIR, or subagent appears, or if the baseline merge test runs.

### 6. A Build-Only Lane Resumes at Step 5, Not Step 2

**Setup:** a probe JSON matching a lane that finished its build and red-team with the push half withheld. `tests/fixtures/work-issue/probes/row-13.json` is that shape.

**Commands:**

```
python3 work-issue/scripts/run-state.py phase --probe tests/fixtures/work-issue/probes/row-13.json
```

**Pass condition:** the script prints `phase: 5 reason: row 13` and the rest of its reason line. That is where Step 7's publish dispatch expects `work-issue` to place the lane, and no live lane is needed. Fails if it prints any phase other than 5, since the publish dispatch would then rebuild or re-review a lane the wave already merge-tested.

### 7. The Merge Tree Is Its Own Repository and Is Gone Afterwards

**Setup:** a sandbox repo with a clean ROOT. Follow `work-wave/references/merge-test.md` by hand with no branches, as the Step 4 baseline does. Inside MERGE_TREE, before step 7 of the procedure, run `git add` on a scratch file on purpose, the #109 escape.

**Commands:**

```
git -C ROOT worktree add --detach MERGE_TREE origin/<DEFAULT>
git -C MERGE_TREE add scratch.txt
git -C ROOT diff --cached --stat
git -C MERGE_TREE diff --stat HEAD
git worktree remove --force MERGE_TREE
git -C ROOT worktree list --porcelain
```

**Pass condition:** ROOT's `diff --cached` is empty while MERGE_TREE's `diff --stat HEAD` shows the staged file, which the procedure reads as `dirty after verify:` and red. After removal, `worktree list` has no MERGE_TREE entry and the directory is gone. Fails if the staged file shows in ROOT's index, if the dirty check reads clean, or if MERGE_TREE survives any route out, a conflict and a red suite included.

### 8. A Red DEFAULT Is Named Before a Lane Pays for It

**Setup:** a sandbox repo whose default branch has one failing test, and two issues with disjoint plans that do not touch it.

**Commands:**

```
> /work-wave <N1> <N2>
```

Answer the confirmation with yes and let the lanes build.

**Pass condition:** `merge-test/0.md` and `baseline.txt` record the red, with its failing test, before any lane's build report exists. Step 6's merge test goes red at the same failure, the report reads it as inherited from DEFAULT rather than caused by a lane, and nothing publishes. Fails if the baseline runs after dispatch, if the red is attributed to a lane, if a `coupling.md` row is changed to explain it, or if any lane publishes.

### 9. A Fact Appended Mid-Run Reaches a Sibling's Next Worker Dispatch

**Setup:** two sandbox issues with disjoint plans. Lane A's first task hits a CLI whose two flags are mutually exclusive and exit 2. Lane B's second wave uses the same CLI and runs after A's first.

**Commands:** run the wave, then read `WAVE_DIR/facts/issue-<A>.md` and the worker prompts lane B dispatched.

**Pass condition:** A appends the fact to its own facts file the moment it learns it, with the command that proved it. B's next worker prompt after that append carries the fact verbatim inside `{{CALLER_NOTES}}`, after `work-issue`'s preamble, and B's worker never runs the failing command. Fails if the fact appears only in A's final report, if B's worker prompt lacks it, if it arrives outside `{{CALLER_NOTES}}`, or if A writes into any facts file but its own.

### 10. The Schema Coupling #113 Lost Is Caught Before Any Pull Request

**Setup:** two sandbox issues shaped like #113's lanes A and C. A relaxes a validator in `core/` from strict to loose. C adds a comparison in `app/storage/` whose test depends on the strict behavior, and C's plan names `core/` nowhere.

**Commands:**

```
> /work-wave <A> <C>
gh pr list --state all
```

Run `gh pr list` at each stop the wave makes.

**Pass condition:** either branch passes. Step 2 recorded `order` or `hold` for the pair with `Evidence` naming the validator. Or Step 2 recorded `none`, A's build report named the validator in `files_changed` under CONTRACT_PATHS or in `contract_changed`, the Step 5 merge test went red over both branches, its line reached `facts/wave.md` naming A as the lane that broke C, the pair's `coupling.md` row was corrected from `independent`, and `gh pr list --state all` was empty at that moment. Fails if either lane opens a pull request before a merge test covers both branches, or if the wave reaches Step 7 with the coupling unrecorded and the merge test never run over both.

### 11. A Failed Lane Is Held With Its Dependents While the Rest Publish

**Setup:** three sandbox issues. B's `order.md` row says it merges after A, and C is independent. Plant a defect in A's plan that its own gate will fail twice.

**Commands:** run the wave to its report.

**Pass condition:** A returns `failed`, leaves the merge set, and B moves to `held` naming A. C passes the Step 6 merge test alone and publishes. The final report quotes A's report, names B as held on A, and lists C's pull request. A's branch and worktree are untouched. Fails if A is reverted or retried by the wave, if B publishes, or if C waits on A.

### 12. A Post-Publish Repair Re-Runs the Merge Test

**Setup:** a wave of two lanes that published, and a reviewer comment on one pull request that its `work-issue` repairs and pushes, moving that lane's HEAD.

**Commands:** re-invoke the wave with the same issues.

**Pass condition:** the resume probe lands on row 10, a new `merge-test/<k>.md` records the moved SHA beside the other lane's, and only then does the final report print. Fails if the report prints on the old merge test, or if the re-test merges in any order but `order.md`'s.

### 13. Re-Invoking on the Same Set Resumes

**Setup:** a wave of issues N1 and N2 interrupted after `merge-test/0.md` exists and one lane's build report is on disk.

**Commands:**

```
> /work-wave <N2> <N1>
```

Pass the issue numbers in reverse order, to prove WAVE_ID is derived rather than typed.

**Pass condition:** the run finds `wave-<N1>-<N2>/`, lands on resume row 7, and dispatches only the lane with no build report. That lane's `work-issue` resumes itself. Fails if a second WAVE_DIR appears, if the returned lane is dispatched again, or if the run restarts at Step 0.

### 14. The Final Report Orders the Merges and Merges Nothing

**Setup:** a wave of three lanes that all publish, with one `order` row in `coupling.md`.

**Commands:** run the wave to its report, then `gh pr list --state all`.

**Pass condition:** the report lists the pull-request URLs in `order.md`'s order with each lane's `After`, names the newest merge test and its result line, carries the coupling table and the facts path, and ends on "a human merges, in this order", or "waiting on the reviewers" where every lane is answered and none has cleared. Every pull request is still open. Fails if any pull request is merged, if the order differs from `order.md`, or if WAVE_DIR moves to `closed/` while a lane's RUN_DIR is still open.

### 15. A Build Report Saved but Never Gated Goes Back Through Step 5

**Setup:** a wave of two lanes where lane A's build report names a path under CONTRACT_PATHS. Interrupt the orchestrator after Step 4 saves the last build report and before Step 5 writes that lane's `gate/issue-<N>.md`.

**Commands:** re-invoke the wave with the same issues, then read `WAVE_DIR/gate/` and `WAVE_DIR/merge-test/`.

**Pass condition:** the resume probe lands on row 6 and runs Step 5 for the ungated report only. The footprint re-check runs for it, the contract-change merge test runs and its line reaches `facts/wave.md`, and `gate/issue-<N>.md` then records the route, the re-check, and the merge-test result. Only after that does the run reach Step 6. Fails if the probe lands on row 7 or row 8, if a report that already had a gate record is gated again, or if any merge test before publish runs while a report has no gate record.

**Second case, a crash that leaves the lanes mixed:** the same two lanes, interrupted after Step 4 saves lane A's build report and before Step 5 writes `gate/issue-<A>.md`, while lane B is still building. Re-invoke the wave with the same issues.

**Pass condition:** the resume probe lands on row 6 before row 7. Step 5 gates A's report, and `gate/issue-<A>.md` exists before B is dispatched again. The probe then lands on row 7 and dispatches B alone. B's report goes through Step 5 when it returns, and only then does the run reach Step 6. Fails if B is re-dispatched while A's report has no gate record, or if Step 6 runs while either report has none.

### 16. DEFAULT Moving After the Merge Test Holds Publication

**Setup:** a wave of two lanes that reached a green Step 6. Before Step 7 dispatches, push one unrelated commit to the sandbox's default branch.

**Commands:** let the wave continue, then read the newest two `merge-test/<k>.md` files and run `gh pr list --state all`.

**Pass condition:** Step 7 fetches, finds `origin/<DEFAULT>` differing from the green run's `base:` line, and runs Step 6 again before any lane is dispatched. The new `merge-test/<k>.md` records the new tip as its `base:`, and `gh pr list --state all` is empty until it goes green. Fails if a lane is dispatched with the full grant while the newest green `base:` differs from `origin/<DEFAULT>`, or if a merge-test record has no `base:` line.

## What These Evals Do Not Cover

Whether the coupling question was answered correctly is judgment. A scenario checks that an answer was recorded and acted on, not that `none` was right for a pair that actually coupled, and Scenario 10 passes on either branch for that reason. Cost has no measured delta: nothing here compares a wave against the same issues run by hand. The cross-run race is narrowed, not closed. Two waves invoked in the same second each pass Step 1 against the other's lanes, which have no RUN_DIR yet, and `work-issue` already records that race as open with no fix to validate. The withheld grant's honoring has no scenario of its own either: a lane that ignores it is a lane misbehaving on purpose, and Step 5's `pr` check is the only thing a scenario could observe.
