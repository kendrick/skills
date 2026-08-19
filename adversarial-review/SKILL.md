---
name: adversarial-review
description: "Adversarial review of a git diff, where a finding has to be reproduced by something that did not author it before it can block. Parallel finders hunt disjoint territories, a fresh verifier tries to break each claim, and reproduced blockers get a failing test before any fix. Use ONLY when the user explicitly invokes adversarial-review. For a general single-pass review use code-review, for a repo-wide vulnerability scan use security-review, and for stress-testing a plan use grilling."
argument-hint: '[fixed point, e.g. main or a SHA | --fast | --deep | --max-rounds N | --report-only]'
disable-model-invocation: true
---

# adversarial-review

A review that ends at a report has produced opinions. Some of them are wrong, and nothing in the process can tell you which—so the reader does the verification work the review skipped, or skips it too. Findings here are treated as hypotheses until something that did not author them reproduces them, and **only a reproduced finding can block a merge**.

Two structural choices follow from that. Territories are disjoint, so no two finders review the same file: with verification carrying the confidence, agreement between reviewers is not needed, and reviewers who might agree mostly produce correlated noise. And the loop keeps going after fixes land, because in the session this design came from, two of three merge-blockers were defects introduced while fixing the previous round's finding. Code written under review pressure is the highest-suspicion code in the run.

Where a step names a shell command, treat it as the intent and use your native shell or file tools.

Resolve once per invocation:

- **FIXED_POINT** — the ref or SHA the diff is measured against, from the arguments. When it is absent, ask. Guessing produces a review of the wrong code that looks exactly like a review of the right code.
- **Flags**: `--fast` pins Depth 0, `--deep` pins Depth 2, `--max-rounds N` overrides the default of 3, `--report-only` runs the full review and emits the report without writing tests, filing issues, or filing questions.
- **RUN_DIR** — `.adversarial-review/runs/<UTC-stamp>-<merge-base-short-sha>/`, created in Step 1.

## Step 1 — Preflight

Everything here fails in front of the user. A bad ref discovered inside six parallel subagents costs six times as much and reports itself six different ways.

1. `git rev-parse --verify <FIXED_POINT>` — unresolvable, stop and say so.
2. `git merge-base <FIXED_POINT> HEAD` — record the result as `merge_base_sha`. Every diff for the rest of the run uses this SHA, never the ref. A branch moves; a multi-day round loop that re-resolves `main` each round would review different code in round 3 than it did in round 1, silently.
3. `DIFF_CMD` is `git diff <merge_base_sha>..HEAD`. Capture it once into the scope contract, and hand that same string to every finder.
4. `git diff <merge_base_sha>..HEAD --name-only` — empty means there is nothing to review. Stop.
5. `git status --porcelain` — a dirty tree stops the run with "commit or stash first." Verification evidence is only meaningful against the code the diff describes, and a verifier running commands against uncommitted changes is testing something the review never looked at. When the user overrides deliberately, record `dirty_tree_accepted: true` in the scope contract so the report can say the evidence was gathered under that condition.
6. Identify generated and vendored trees from the changed-file list (`dist/`, `build/`, `__pycache__/`, compiled artifacts like `*.pyc`, lockfiles, `*.generated.*`, vendored dependency directories) and hold them out as `excluded`. These exclusions hold for the whole run, not just this step — Step 7 filters the fix diff through the same list, because a build artifact reappearing every round would send each round to the scope-amendment branch for nothing.
7. Create RUN_DIR, and in the same breath append `.adversarial-review/` to `.git/info/exclude` if it is not already there. Use `info/exclude` rather than `.gitignore`: `.gitignore` is a tracked file, so editing it would add a change to the very diff under review and pollute the next round's fix intersection.

**Done when:** RUN_DIR exists and `scope.json` holds `fixed_point`, `merge_base_sha`, `diff_cmd`, `changed_files`, and `excluded`; the tree is clean or the override is recorded. Any check above failed and stopped the run before a single subagent was dispatched.

## Step 2 — Scope Contract

The contract is written to disk before anything fans out. It is what makes two runs on the same diff produce the same territories, and what a reader consults later to see what nobody was asked to look at.

Read [references/trigger-table.md](references/trigger-table.md) and follow its derivation algorithm. In outline: grep each changed file's hunks against the table's rows, assign each file to a territory named for its first matching row, and give each territory the union of its files' suspicion classes. Disjoint ownership, layered lenses—a file that is both money and authz keeps both hunts, and exactly one owner.

Collect the **out-of-scope list** from the user and the conversation: settled decisions, deliberate renames, prose-only changes. Ask for it if the conversation has not supplied it. This list goes to every finder verbatim, and reporting an item on it is a false positive by definition.

Assign **depth**, which governs what the run costs:

| Depth | Fires when | Shape |
|---|---|---|
| 0 | `--fast`, or no row above 6 matched anywhere in the diff | ≤2 territories, sonnet finders, one batched verifier |
| 1 | the default | ≤4 territories, tiers per the trigger table, opus verifier |
| 2 | `--deep`, or three or more distinct high-stakes rows matched, or the diff exceeds ~40 files | ≤6 territories, opus on money/authz/state, one verifier per finding |

Write `scope.json` (shape: [assets/scope.schema.json](assets/scope.schema.json)), including the `derivation` record for every file, then run:

```
adversarial-review/scripts/check-territories.py validate RUN_DIR/scope.json
```

A non-zero exit is a hard stop, not a warning. Overlapping territories remove the property the whole design rests on: verification replaces cross-reviewer agreement precisely because no two finders were looking at the same code.

Announce the result in one line, then continue: `Depth 1: 3 territories (money, authz, general), opus verifier.` That line is the user's correction point, and it comes before any subagent spends a token.

**Done when:** `validate` exits 0, and the derivation records name a matched row and an owning territory for every changed file.

## Step 3 — Fan-Out

Read [references/finder-prompt.md](references/finder-prompt.md) and instantiate one prompt per territory. Dispatch them in a single turn so they run in parallel, on stake-neutral general-purpose subagents at each territory's model tier.

Save each finder's returned JSON verbatim to `RUN_DIR/findings/round-<N>-<territory>.json`. Verbatim matters—an output you tidied is an output you partly authored.

**Done when:** every territory has a findings file that parses against the finder contract. A territory that failed twice is marked failed rather than repaired by hand: it reports as UNREVIEWED in Step 8, and where `escalation.md` gets written it appears there too, as a territory that never reported.

## Step 4 — Ledger

Append every finding, in the order its finder ranked it:

```
adversarial-review/scripts/ledger.py append-finding --ledger RUN_DIR/ledger.jsonl \
    --id F-r<round>-<territory>-<NN> --round <N> --territory <name> ...
```

This step is transcription. Two territories reporting the same underlying bug is information about the bug, not duplication to clean up; re-ranking across territories reintroduces the single ordering the per-territory verdicts exist to avoid. Dedupe, re-rank, and synthesis all belong after verification, if anywhere.

Findings carry no disposition field. A finding's state is derived from the events appended after it, which is what keeps the ledger append-only in fact rather than only in intent, and preserves when each state landed and who landed it.

**Done when:** `ledger.py validate` exits 0, the finding count matches the findings files, and `ledger.py state` shows every finding UNVERIFIED.

## Step 5 — Verification Gate

Read [references/verifier-prompt.md](references/verifier-prompt.md). Dispatch fresh verifier subagents that receive only `id`, `file`, `quoted_evidence`, `claim`, and `proposed_repro`—never the finder's reasoning, and never `proposed_fix`, which carries that reasoning in another form. Their stance is refutation: the claim is what they are trying to break.

Record each returned event with `ledger.py append-event`, with `--actor verifier-r<round>-<territory>`. The script enforces the evidence rules, so a REPRODUCED event without its command and actual output is refused at the append.

Only REPRODUCED can block. A finding nobody could reproduce is not a small finding—it is an unproven one, and it routes accordingly in Step 6.

**Done when:** `ledger.py state` reports zero UNVERIFIED. Every finding is REPRODUCED with a command and its real output, NOT_REPRODUCED with counter-evidence, or UNVERIFIABLE with a reason.

## Step 6 — Disposition

Routing is mechanical. Nothing here is a judgment call, which is the point: a gate that can be argued with is a gate that gets argued with at the end of a long review. Blocking and advisory are the finding's `claimed_severity`, exactly as the finder recorded it—set before verification ran, and not reopened here. A severity fixed before anyone had a stake in the routing is what lets the table stay mechanical.

| State | Route |
|---|---|
| REPRODUCED + blocking | Write a failing test from the repro command **before** writing the fix. Record `TEST_WRITTEN` with the test's path. |
| REPRODUCED + advisory | Hand to the `file-issue` skill with the repro command attached, one invocation per finding — it files exactly one issue per run. Record `ISSUE_FILED` with the URL. |
| NOT_REPRODUCED | Record `CLOSED`, with the verifier's counter-evidence already in the ledger. |
| UNVERIFIABLE | Emit an open question for `inbox-to-memory`. Record `QUESTION_FILED`. |

The failing test comes first because that is what makes the finding survive its own fix. A test written afterward is written by someone who already believes the fix works, and it passes for reasons nobody checked.

For an open question, use `inbox-to-memory`'s own detection rule: a directory holding `_memory/` or `entries/`, with a queue at `_inbox/` at that level or under `notes/`. Write a dated markdown file there carrying the claim, the quoted evidence, and why verification could not settle it. Where no opted-in scope exists, keep the question in the report and record the reason instead—inventing a queue somewhere is worse than reporting.

`--report-only` skips every action in this table and reports what would have happened.

**Done when:** every finding id carries a terminal outcome event, and every test written for a blocking finding exists and fails.

## Step 7 — Round Loop

Record each round's `head_sha` in the scope contract as that round fans out. Fixes must be committed before this step runs: `intersect` compares commits, so an uncommitted fix is invisible to it—the loop prints nothing, exits clean, and the highest-suspicion code in the run was never reviewed. Re-run the preflight cleanliness check (`git status --porcelain`) before every fan-out, with the same stop and the same recorded override as Step 1. Once fixes are committed:

```
git diff <prev_round_head_sha>..HEAD --name-only \
    | grep -vFf RUN_DIR/excluded.txt \
    | adversarial-review/scripts/check-territories.py intersect RUN_DIR/scope.json
```

Filter the fix diff through the scope contract's `excluded` list first. Skipping that sends every round to the amendment branch over `__pycache__` and build output, and an amendment that gets rubber-stamped each round stops being a signal.

Re-run Steps 3 through 6 for the printed territories only, at `--round N+1`, with each finder prompt carrying what previous rounds found here and which fixes introduced new blockers. That last part is the whole reason for the loop—a finder who knows a fix landed hunts the fix rather than re-hunting the original.

A non-zero exit from `intersect` means the fix touched a path no territory owns. Amend the scope contract—add the path to the nearest territory with a recorded `amendments` entry, re-run `validate`—and then fan out. A blind spot that appears mid-run is exactly what should stop and get written down.

The loop ends when `intersect` prints nothing, or when a round produces zero REPRODUCED findings in the territories it re-reviewed. At `--max-rounds` with blockers still landing, write `RUN_DIR/escalation.md` naming the unresolved finding ids and what each still needs, record `ESCALATED` for each, and stop. Any failed territory gets its own section there: a territory that never reported is a different kind of unknown than a blocker that will not die, and the reader should know which they are looking at. Three rounds of new blockers means something structural is wrong with the change, and a fourth automated round is less use than a human reading the escalation.

**Done when:** the loop exited by the rule above, or `escalation.md` exists and every unresolved finding is named in it.

## Step 8 — Report

Report per territory. There is deliberately no single cross-territory verdict: one axis passing must never mask another failing, and a combined verdict is exactly the artifact that lets it.

For each territory give its verdict, its findings with terminal dispositions, and the one line its finder wrote about what works. A territory whose finder failed carries the verdict UNREVIEWED—nobody managed to look, which must never read like somebody looked and found nothing. Then the run-level facts: rounds taken, what each round's fixes introduced, tests written, issues filed, questions filed.

Surface any `calibration:` line `ledger.py state` produced. A territory whose findings were mostly UNVERIFIABLE is telling you its hunt items generate untestable claims—worth fixing in the trigger table before the next run, and deliberately not a trigger for re-fanning-out, since termination has to stay mechanical.

**Done when:** every territory and every finding id appears with its terminal disposition, and every blocking finding is either fixed behind a failing test or named in the escalation.

## Further Reading

- [references/trigger-table.md](references/trigger-table.md) — read at Step 2 to derive territories, and before adding a suspicion class
- [references/finder-prompt.md](references/finder-prompt.md) — read at Step 3 to instantiate finders
- [references/verifier-prompt.md](references/verifier-prompt.md) — read at Step 5 to instantiate verifiers
- [assets/](assets/) — the three schemas the scripts enforce; read only when changing the shape of the contract or the ledger
