---
task: DEC-audit
checker: auditor
vendor: anthropic
model: claude-opus-5
verdict: FAIL
checked_at: 2026-08-06T00:00:00Z
---

## Per-task results

| task | result | severity | description | evidence |
| ---- | ------ | -------- | ----------- | -------- |
| T-001 | FAIL | major | two C-9/C-6 gaps the cited checks cannot catch: the `broken/` fixture's note-vs-record placement is unspecified and one branch plants a second defect; and the suite prose T-001 adds is fenced out of both tasks' C-9 fragments | `lint-scope.sh:130-133`, `:182-186`; reproduction below; `T-001.md:34-39`, `:80-81`; `T-002.md:31-32` |
| T-002 | PASS | — | coverage, clause citation, check consistency, routing, and deps all hold; every cited anchor reproduced | `T-002.md:9-32`, `:43-65` |

## Audit dimensions

| dimension | result | note |
| --------- | ------ | ---- |
| spec coverage | PASS | all six Done-when criteria and the Verify-with line map to a task; no orphan requirement |
| clause citation | PASS | every id in `clauses` appears in that task's `check_method`; no clause cited by neither task |
| check consistency | PASS | each fragment tracks its constitution clause, narrowed but never contradicted |
| C-9 fragment ownership | **FAIL** | five enumerated fragments partition cleanly; the clause's governing phrase covers a sixth that neither task owns |
| routing conformance | PASS | matches the table, including the one-checker-per-task compromise on C-8 |
| deps DAG | PASS | two nodes, one edge, acyclic, referenced task exists, ordering necessary |

## Diagnosis

- **T-001** (major, C-6): the `broken/` fixture's placement is unspecified, and the likely branch plants two defects instead of one.

  `T-001.md:80` says only "A fixture under `tests/fixtures/inbox-to-memory/broken/` carrying the mixup and nothing else, under the 20-line budget." That directory holds both `notes/` (18 files) and `_memory/decisions/` (1 file), so "under `broken/`" admits two readings, and the 18:1 split pulls hard toward `notes/`. Only one reading satisfies C-6.

  `check_frontmatter` routes by `memory_type` (`lint-scope.sh:182-186`) and hands `check_key_order` a *single* order; the unknown-key test at `:130-133` runs against that one array, not both. `themes` is in `RECORD_KEY_ORDER` and not in `NOTE_KEY_ORDER`. So a note carrying both keys is already defective today, before the new check exists. Reproduced against the current tree:

  ```
  FAIL .../notes/2026-03-01-mixup-AbCdEfGhIj.md: frontmatter-key-domain is not yet implemented, so today:
  FAIL .../notes/2026-03-01-mixup-AbCdEfGhIj.md: frontmatter-known-keys: `themes` is in neither key order
  ```

  The same scope's record fixture, carrying `tags` and `themes` and `memory_type: Decision`, lints clean. A note fixture therefore carries the mixup *and* an unknown key; a record fixture carries the mixup alone.

  The reason this has to be fixed in the brief rather than left to the checker: C-6's `check_method` at `T-001.md:26-27` asks the checker to confirm "linting it produces `frontmatter-key-domain` and no unrelated failure." Once the key-domain check is sited ahead of the budget guard as C-2 demands, it fires and returns before `check_key_order` is ever reached at `:187`. The second defect is masked by construction, so the checker sees exactly one failure and passes a fixture that violates C-6's text ("carrying that one defect and no other"). C-6's failing example names "a bad key order" as the two-defect hazard, which points the checker at `frontmatter-key-order` rather than `frontmatter-known-keys` — adjacent, and away from the live one.

  Fix: one sentence in the `T-001.md:80` bullet saying the fixture must be a record carrying `memory_type` (so `themes` is legal for its key order and the mixup is the only defect), with `broken/_memory/decisions/vendor-lock-window-WJicoHVdFw.md` named as the existing record fixture to model. A note carrying `themes` fails `frontmatter-known-keys` and is not a one-defect file.

- **T-001** (major, C-9): the suite prose this task adds is owned by neither task.

  C-9's governing phrase is "Every human-facing string this job adds or rewrites," followed by an em-dash enumeration of five artifacts. The two tasks partition those five exactly — T-001 takes the failure message and `lint-scope.sh` comments, T-002 takes the headroom sentence, the table row, and the commit message. Nothing is double-owned. But both `check_method` fields then *fence* their scope: `T-001.md:38-39` ends "The docs prose belongs to T-002, not here," and `T-002.md:31-32` ends "The failure message and lint comments belong to T-001, not here." Between those two fences sits `tests/inbox-to-memory-smoke.sh`, which T-001 must add prose to and no checker is instructed to read.

  This is not hypothetical. `T-001.md:81` requires the worker to "build it as an inline scope in the suite," which is a new block of suite code, and the suite carries 239 top-level comments written in full explanatory sentences (`tests/inbox-to-memory-smoke.sh:520`: "Both halves of the disagreement travel together, and the contract says why."). New suite code in this file gets a why-comment by house convention, and the house prose standard counts code comments as human-facing.

  It is also the exact defect the previous job on this branch shipped and caught late. `state/archive/2026-08-06/retrospective.md:12` records it as an r1 major: "C-16's script-comment fragment was scoped to files T-004 touched, leaving the `migrate-scope.sh` and `verify-migration.sh` comments unchecked by anyone." Same clause shape, same fencing mechanism, one file over.

  Fix: widen T-001's C-9 fragment from "any comment this task adds to `lint-scope.sh`" to the comments this task adds to `lint-scope.sh` **and** `tests/inbox-to-memory-smoke.sh`, and add the suite to the artifacts named in the `T-001.md:89` humanizer instruction. T-002's fence should then read "the failure message and the lint and suite comments belong to T-001."

## The r2 follow-through: does the humanizer instruction actually reach the worker?

It does, in both tasks, and the wording clears the bar I set. Recorded here because I committed at `CON-audit-r2.md:42` to checking it, and a commitment discharged silently is indistinguishable from one forgotten.

- `T-001.md:89`: "Before finishing, run the `humanizer` skill formally (via the Skill tool, not from memory) over the failure message string and any comment you add, then revise in place. C-9 grades the result."
- `T-002.md:65`: "Before finishing, formally invoke the `humanizer` skill via the Skill tool rather than applying it from memory, which reliably misses tells, and revise the headroom sentence, the table row, and the commit message in place against its audit."

Both name the Skill tool explicitly, both rule out applying it from memory, and both name the audit-and-revise return leg rather than stopping at "run it." Both exceed the precedent I cited as the standard — `state/archive/2026-08-06/tasks/T-004.md:50` says only "run every added human-facing string through the `humanizer` skill's audit-and-revise loop," which does not mention the Skill tool at all.

Both survive skimming, though unevenly. T-002's sits under its own bolded `**Voice (C-9).**` heading and is structurally unmissable. T-001's is the fourth of five bullets under "House constraints," wedged between a file-idiom note and a `grep -q` gotcha, which is the weaker placement. I am not failing it: the sentence itself is unambiguous, the parenthetical carries the operative force, and "C-9 grades the result" tells the worker why it matters. Worth promoting if T-001 is revised for the two findings above anyway.

One point of substance the placement does not fix: both instructions enumerate the artifacts to run the skill over, and T-001's enumeration inherits the C-9 gap diagnosed above. A worker following that line to the letter runs the humanizer over the failure message and the lint comment and skips the suite comment. The instruction is strong; its scope is short by one file.

## The C-9 partition against the fragment-ownership lesson

The dispatch asked whether splitting C-9 by artifact leaves a fragment unowned or double-owned. Judged fragment by fragment against `constitution.md:69`:

| C-9 fragment | owner | fenced out of |
| ------------ | ----- | ------------- |
| `machine-contracts.md` headroom sentence | T-002 | T-001 |
| the new table row | T-002 | T-001 |
| the failure message itself | T-001 | T-002 |
| new comments in `lint-scope.sh` | T-001 | T-002 |
| the commit message | T-002 | T-001 |
| *comments added to the smoke suite* | **none** | both |

Five of five enumerated fragments are owned exactly once. The split is the right call and the mutual fences are what make it verifiable — this is the retrospective's lesson applied correctly, not ignored. The sixth row is the miss: it falls under the clause's opening quantifier without appearing in its enumeration, and the fences that keep the five clean are precisely what exclude it. That is the second diagnosis above.

## C-2: does the check_method force reachability to be tested?

Yes, on both sides of the dispatch's question.

**The mutation is compelled, with the hygiene attached.** `T-001.md:13-20` carries the full sequence: assert against a file "whose frontmatter block closes past line 20," then "on a SCRATCH COPY of the tree, move the key-domain check to sit after the existing budget guard, re-run the suite there, and confirm it now fails," then "Mutate a copy or restore the file before returning — a dirty `lint-scope.sh` is attributed to the worker by C-8's diff-scope run." Both halves of `constitution.md:27` survive the transfer, including the r1 correction and the reason behind it. The task drops only the clause's rhetorical sentence ("An assertion that stays green under that mutation is not testing reachability"); every operative instruction is intact.

The worker is held to the same demand independently at `T-001.md:92`, which is the right redundancy: `compose-brief.py` extracts only the Spec excerpt and the Rework diagnosis (`compose-brief.py:145,150`), so a worker never reads `check_method`. A mutation demand that lived only in the checker's field would reach the worker not at all.

**The excerpt does not over-prescribe.** `T-001.md:54-63` quotes the live guard, and I diffed it against the tree rather than trusting it: `lint-scope.sh:156-159` reads exactly as excerpted, modulo two columns of stripped indentation. The excerpt then states the requirement purely as behavior — the 21-line record reports `frontmatter-key-domain` and does not report `frontmatter-budget` — and explicitly declines to pick an implementation at `:65`: "How you site the check is yours to choose — inside `check_frontmatter` ahead of the budget guard, or in its own function called earlier. Both are fine if the behavior above holds." C-2's text constrains precedence and nothing else, and the excerpt constrains precedence and nothing else. Correct.

## C-6 vs C-2: are the two fixtures kept apart?

Yes, and this is the strongest part of the decomposition. `T-001.md:78` opens the section "Two separate cases, and they cannot share a file," then gives each its own bullet with the discriminating property stated: the `broken/` fixture is "under the 20-line budget," and the reachability case is "the over-budget case, which by construction has a second thing wrong with it and so does not belong in `broken/`." A worker cannot read that and try one file. It also explains *why* they can't merge, which is what stops a worker from optimizing the constraint away.

Two smaller notes on the same passage, neither a failure:

- `T-001.md:81` hardens what `constitution.md:53` marked non-normative, turning "the obvious home ... but nothing here requires that siting" into the instruction "Build it as an inline scope in the suite." That is a legitimate orchestrator choice inside a space the clause left open, and no `check_method` tests siting, so a worker who sites it elsewhere cannot be failed for it. C-6's own text still bars the over-budget file from `broken/`, which is the case that actually needed guarding.
- The excerpt's arithmetic checks out. `RECORD_KEY_ORDER` is 19 names (`lint-scope.sh:21`) and `NOTE_KEY_ORDER` is 17 (`:20`), counted at audit time rather than copied; `FRONTMATTER_LINE_BUDGET=20` at `:35`. Nineteen keys put the closing fence on line 21 and eighteen put it on 20, so "dropping either key lands on exactly line 20" (`T-001.md:67`) and T-002's headroom numbers at `:49` are both right.

## deps: necessary, or over-serialized?

Necessary. Three independent reasons, any one sufficient:

1. **Write conflict.** Both tasks modify `tests/inbox-to-memory-smoke.sh` — T-001 for fixture and reachability assertions, T-002 for the table-row pin at item 3. Run in parallel they collide in one file.
2. **C-7 becomes uncheckable.** Both `check_method` fields run `comm -23` of the suite's `require_*`/`refute_*` lines at `d4ce6d2` against the working copy. That comparison is meaningless while another task is concurrently editing the same suite.
3. **C-5 is a genuine data dependency.** `T-002.md:53` requires the row's "Fails when" description to match shipped behavior, and its `check_method` at `:18` says "read the check, not T-001's task file." There is no check to read until T-001 lands.

Only T-002's item 1, the headroom sentence, is arguably independent — it depends on the key orders, which this job may not change (`constitution.md:81`). But even it says "because `tags` and `themes` are now mutually exclusive" (`T-002.md:49`), which is true only once T-001 ships. And a two-node chain is already the minimum decomposition; splitting item 1 into a third task to parallelize one sentence would recreate the fragment-ownership problem the retrospective warned about, for no wall-clock gain. The ordering is right.

## Routing

| task | work | executor | model | checker | verdict |
| ---- | ---- | -------- | ----- | ------- | ------- |
| T-001 | bash implementation in `lint-scope.sh`, a fixture, suite assertions; judged on whether the right diagnostic fires | worker-standard | sonnet | checker-judgment | correct |
| T-002 | doc prose, a table row, the commit message; judged on reading | worker-craft | opus | checker-judgment | correct |

T-001 is clear-spec implementation judged on correctness, which is sonnet's row exactly. It is not mechanical — siting the check against the budget guard is a real design call — so worker-bulk would be wrong. Its C-9 share is one failure-message string plus comments; that is not enough taste work to pull the whole task to worker-craft, and splitting the string into its own task would fragment C-9 again. T-002 is prose and taste end to end, which is worker-craft's row.

Both checkers are `checker-judgment`, and both tasks mix judgment clauses with C-8's script. Taken clause by clause the table would send C-8 to checker-deterministic, but a task carries one `checker` field, so a mixed task must absorb one into the other. Absorbing the script into the judgment checker is the only direction that works — a judgment checker can run `check-diff-scope.py`, a deterministic one cannot apply a rubric — and it matches the constitution's standing decision at `constitution.md:15` that every clause whose evidence lives in the suite routes to checker-judgment. Recorded rather than merely accepted because the absorbed C-8 is worth nothing as courier-comparison evidence, per the note both tasks carry in their Courier comparison sections.

## Spec coverage

| spec requirement | source | task | clause |
| ---------------- | ------ | ---- | ------ |
| both keys fail a named key-domain check, not `frontmatter-budget`; message names both keys | `spec.md:88` | T-001 | C-1, C-2 |
| journal with `themes` only, and record with `tags` only, still pass | `spec.md:89` | T-001 | C-3 |
| new check registered in the "What the Lint Checks" table | `spec.md:90` | T-002 | C-5 |
| `machine-contracts.md:29` states real headroom, drops the commented-out-keys claim | `spec.md:91` | T-002 | C-4 |
| suite gains a fixture asserting the named failure, one defect per file | `spec.md:92` | T-001 | C-6 |
| all three suites exit 0 | `spec.md:93`, `:84` | both | C-7 |

No spec section is unmapped. The reproduction (`spec.md:19-59`) and the Observed/Expected pair (`:61-65`) are inputs to C-1 and C-2 rather than separate deliverables, and both reach the worker: T-001's excerpt reproduces the heredoc's shape and the observed output at `:69-76`. The four Out-of-scope items at `spec.md:94` land as non-goals at `constitution.md:81-86` and are echoed where a worker could trip on them — `T-001.md:52` restates the mutual-exclusion-not-domain-assignment carve-out in the worker's own excerpt, which is where it does some good.

Nothing in either task claims scope the spec does not grant. The commit message (`T-002.md:57`) is house standard rather than a spec requirement, and it is correctly sited at `.agent-guild/state/commit-message.md`, which `check-diff-scope.py --ignore .agent-guild/` excludes outright — the same path and the same reasoning as `state/archive/2026-08-06/tasks/T-004.md:48`, whose r1 finding was that the draft had been routed to `state/notes/` where the orchestrator cannot read it. That lesson landed.

## Verified without finding

Every line-number citation in both task files was reproduced against the tree rather than accepted:

- `lint-scope.sh:156-159` — the budget guard, quoted verbatim in T-001's excerpt.
- `lint-scope.sh:181-186` — `memory_type` routing between the two key orders.
- `lint-scope.sh:20-21` — 17 and 19 names, counted at audit time.
- `machine-contracts.md:29` — the headroom sentence; T-002's block quote at `:47` matches the file's text exactly.
- `machine-contracts.md:140` — the `## What the Lint Checks` heading; the table header follows at `:144`, six `frontmatter-*` rows at `:146-151`.
- `tests/inbox-to-memory-smoke.sh:521` — `require_text "$contracts" "contradiction-fields"`, the pin T-002 is told to model.
- `tests/inbox-to-memory-smoke.sh:708` — `require_line "$jrn_lint" "failures: 0" journal-migrated`, the live assertion C-3 says a `memory_type`-based implementation would break.
- **Baseline.** `git diff d4ce6d2 -- inbox-to-memory/ tests/` is empty, so the working tree is the baseline on every deliverable path. All three suites run green: `inbox-to-memory-smoke` exit 0, `file-issue-smoke` exit 0, `handoff-smoke` exit 0. `check-diff-scope.py inbox-to-memory/ tests/ --ignore .agent-guild/` → `OK: 0 path(s) in scope`, exit 0. T-001's "Baseline: all three suites exit 0 at `d4ce6d2`" is accurate.
- **DAG.** `T-001.deps: []`, `T-002.deps: [T-001]`. One edge, no cycle, no dangling reference.
- **Clause closure.** Union of both `clauses` lists is C-1 through C-9 with none missing and none invented. C-7, C-8, and C-9 are cited by both tasks, which is correct — each constrains each task's own diff independently rather than being a fragment to divide.

## Corrections required, not task failures

- **The `broken` scope has two counts to update, and T-001 names one.** `T-001.md:80` says "Update the broken scope's `failures: N` arithmetic," and C-6's `check_method` likewise says only `failures:`. Adding a fixture also moves `v2 files: 19` at `tests/inbox-to-memory-smoke.sh:158`, alongside `failures: 18` at `:159`. Not a failure, because a stale `v2 files` breaks the suite and C-7 requires all three to exit 0, so it cannot ship. Cheap to say "the broken scope's `v2 files:` and `failures:` counts" and remove the chance of a wasted round.
- **`spec: .agent-guild/state/spec.md#done-when` is a dangling anchor** in both task files. The spec has no `## Done when` heading; the criteria live at `spec.md:87` as a bullet, `- **Done when:**`, inside `## For a Coding Agent`. Cosmetic — `compose-brief.py` never resolves it and workers read the excerpt — but the field is the provenance pointer a human follows, and it currently points nowhere. `#for-a-coding-agent` resolves.
