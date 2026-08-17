# adversarial-review — evals

The smoke test (`bash tests/adversarial-review-smoke.sh`) pins the artifact: files present, load-bearing strings intact, both scripts behaving. It says nothing about whether the review works, because that needs live subagents. This file is the procedure for that.

Method follows `skill-creator`: run each scenario with the skill and without it, then grade the delta. These runs are manual—they dispatch real subagents and cost real time, so they belong in a deliberate session rather than in CI.

## The planted-bug fixture

Build a throwaway repo with a base commit and one feature commit. The feature commit plants five things, and the fifth is the one most eval suites forget.

1. **A money bug** — `total += round(line.amount * qty, 2)` inside the loop, so rounding happens per line and drifts on accumulation. Reproducible: sum a basket whose exact total ends in a half cent.
2. **An authz bug** — a query whose docstring says results are scoped to the caller's tenant, with no tenant predicate in the SQL. Reproducible: query as tenant A and see tenant B's row.
3. **A state bug** — a `locked` flag with a set path and no clear path, so the entity latches. Reproducible: run the transition twice.
4. **A red herring** — a deliberate rename covered by the out-of-scope list. Should never reach the ledger.
5. **A false-looking-but-correct passage** — code that reads like an off-by-one but is guarded upstream, e.g. `items[n]` where the caller has already bounded `n`. This is the verifier's test, not the finder's: a finder reporting it is behaving correctly, and the run passes only if it ends `NOT_REPRODUCED` with counter-evidence naming the guard. Build this one carefully: the first run's version carried a docstring that was independently false, so the finder reported that instead and reproduced it, which grades nothing. Everything a finder could say about this passage has to be wrong, or the probe does not probe.

Also make a **docs-only sibling diff** (README and comment changes alone) to exercise the depth governor.

## Scenarios and pass criteria

| # | Scenario | Passes when |
|---|---|---|
| 1 | Preflight, bad ref | `/adversarial-review no-such-ref` stops with an unresolvable-ref message and dispatches nothing. |
| 2 | Preflight, empty diff | Fixed point equal to HEAD stops before fan-out. |
| 3 | Preflight, dirty tree | An uncommitted edit stops the run with "commit or stash first"; the override records `dirty_tree_accepted: true`. |
| 4 | Determinism | Two runs on the unchanged fixture diff produce identical territory names, membership, and derivation records. |
| 5 | Detection | At least two of the three planted bugs end `REPRODUCED`, each with a real command and its actual output in the ledger. |
| 6 | Out-of-scope discipline | The red herring appears in no findings file and no ledger row. |
| 7 | Verifier independence | The false-looking passage, if reported, ends `NOT_REPRODUCED` with counter-evidence naming the upstream guard. A run where it ends `REPRODUCED` is a failure of the gate, not of the finder. |
| 8 | Test-before-fix | Every `REPRODUCED` blocking finding has a `TEST_WRITTEN` event whose artifact exists and fails when run against the unfixed code. |
| 9 | Round loop | Apply a fix that deliberately introduces a new bug in the same territory. Round 2 fans out to only the intersected territory, and catches it. |
| 10 | Scope amendment | Apply a fix that touches a path no territory owns. `intersect` exits 1, and the run records an `amendments` entry and re-validates before fanning out. |
| 11 | Termination | A round producing zero `REPRODUCED` findings in its intersected territories ends the loop without asking anyone. |
| 12 | Escalation | `--max-rounds 1` against an unfixed blocker writes `escalation.md` naming the finding id, and stops. |
| 13 | Depth governor | The docs-only diff runs Depth 0 with no opus finder. A run that spends an opus fan-out on comment changes fails this, whatever else it found. |
| 14 | Calibration signal | A territory seeded with untestable hunt items reports a `calibration:` line and does **not** re-fan-out. |

## First run, 2026-08-17

Run against the fixture above at Depth 2: four territories (money, authz, state, general), opus finders on the first three, verifiers batched per territory rather than per finding to hold the cost down.

Round 1 produced 12 findings, 6 of them blocking. All 12 reproduced. All three planted bugs were caught, each by the territory that should have caught it, and the red herring never reached the ledger. Six failing tests were written from the repro commands and confirmed red before any fix.

Round 2 is the result worth keeping. The fix commit deliberately introduced a new function, `apply_tax`, carrying the same per-line rounding defect round 1 had just blocked. Round 2 fanned out to the money territory alone and caught it as blocking. It also caught something nobody planted: the fix chose to raise on an out-of-range discount while the failing test written in round 1 asserted a clamped return, so the branch was shipping a red test and the fix disagreed with its own reproduction. That is the loop finding a defect in the review's own artifact, which is the strongest evidence so far that re-reviewing fixes is worth the round.

The run ended on escalation rather than a clean round: with `--max-rounds 2` spent and reproduced blockers still landing, it wrote `escalation.md` naming six unresolved blockers and stopped. Final ledger: 18 findings, 40 events, 58 append-only lines, every finding reproduced and every finding carrying a terminal outcome.

Scenarios 4, 5, 6, 8, 9, 10, and 12 passed. Scenario 7 landed differently than written: the finder declined to report the guarded off-by-one and said so in its `works` line, then reported a genuine docstring falsehood in the same function, which reproduced. The passage needs rebuilding so the only claim available about it is false, or scenario 7 keeps grading a finder that behaved correctly.

Two defects in the skill itself surfaced and were fixed before the run finished: signals were matching as substrings, and preflight's exclusions were never applied to the round loop's fix diff. Both have rows in the RATIONALE ledger.

Still unexercised: scenarios 3, 11, 13, and 14. Scenarios 1 and 2 were confirmed by hand against the fixture rather than through a full run. Termination by the zero-reproduced rule never got tested, because no round of this run was clean; that needs a fixture whose fixes hold.

## Grading the delta

The baseline for a with/without comparison is an ordinary review of the same diff and no skill. What to compare:

- **Blocking findings that survive verification.** The baseline has no verification step, so grade its findings by hand against the same bar. The interesting number is not how many findings each produced but how many survived.
- **False positives reaching the user.** The red herring and the false-looking passage are the two probes. A baseline run typically surfaces at least one.
- **Whether fix-introduced bugs get caught at all.** The baseline has no round loop, so scenario 9 is where the delta should be largest.

## What these evals do not cover

Territory derivation on real-world diffs—the fixture's signals are clean by construction, and a repo whose money code never says `amount` or `price` derives differently. Worth a second fixture drawn from a real diff once the trigger table has taken a few rounds of extension.
