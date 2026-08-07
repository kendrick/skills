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
| T-001 | FAIL | major | both r0 findings landed and both are factually correct; but siting the fixture in `broken/_memory/decisions/` falsifies the comment that explains the broken scope's arithmetic, and no clause, `check_method`, or worker instruction reaches it | `tests/inbox-to-memory-smoke.sh:151-155`; `T-001.md:90-92`, `:41-49`; reproductions below |
| T-002 | PASS | — | the C-9 widening landed cleanly; coverage, clause citation, check consistency, routing, and deps all still hold | `T-002.md:25-34`, `:67` |

## Audit dimensions

| dimension | result | note |
| --------- | ------ | ---- |
| r0 finding 1 landed | PASS | placement named, the record-not-note reasoning is correct as written, and the `check_method` gained a masking guard |
| r0 finding 2 landed | PASS | seven C-9 fragments, each owned exactly once; the fences now partition by author rather than by file |
| new problems from the fixes | **FAIL** | finding 1's fix puts a second record in a scope whose comment asserts there is only one, and asserts it carries no defect |
| spec coverage | PASS | all six Done-when criteria and the Verify-with line still map to a task |
| clause citation | PASS | union of both `clauses` lists is C-1..C-9; every id appears in its task's `check_method` |
| check consistency | PASS with one minor | one sentence of T-001's C-6 fragment is stricter than C-6's text (below) |
| routing conformance | PASS | unchanged from r0 and still correct |
| deps DAG | PASS | `T-001.deps: []`, `T-002.deps: [T-001]`; one edge, acyclic, referent exists |

## Diagnosis

- **T-001** (major, C-6/C-9): moving the fixture into `broken/_memory/decisions/` makes the suite's own explanation of the broken scope false, and nothing in the decomposition catches it.

  `tests/inbox-to-memory-smoke.sh:151-155` is the comment sitting directly above the three count assertions T-001 must edit:

  ```
  # One defect per file, so a count is a meaningful assertion and a check that
  # starts firing twice shows up as an arithmetic failure rather than a wash. The
  # arithmetic is off by one because a contradiction has to point at something
  # accepted: the lone record in this scope is link bait, carries no defect, and is
  # the reason failures trail the file count.
  ```

  Today that is exactly true: `broken/` holds 19 v2 files, one of which is the record `_memory/decisions/vendor-lock-window-WJicoHVdFw.md`, refuted as a failure at `:186`. T-001 now instructs the worker to add a *second* record to that same directory, and that record fails. After the change the scope holds 20 v2 files and 19 failures, and "the lone record in this scope is link bait, carries no defect" no longer identifies anything. A reader tracing why 19 trails 20 goes to `_memory/decisions/`, finds two files, and one of them is asserted to fail. The uniqueness the sentence asserts is gone and the referent is ambiguous.

  This is new this round, and it is a direct consequence of the fix I asked for. Under the r0 wording the fixture would most likely have landed in `broken/notes/` (18 files there against 1), where the comment stays true — it was wrong for the reason r0 gave, but it did not disturb this sentence. Pinning the fixture to `_memory/decisions/` is still the right call; the comment now has to move with it.

  Nothing in the pipeline is positioned to catch it. Walking the concrete failing artifact — worker adds `broken/_memory/decisions/2026-03-19-tags-themes-mixup-XXXXXXXXXX.md`, updates `:158` to `v2 files: 20` and `:159` to `failures: 19`, leaves `:151-155` alone:

  - C-6's `check_method` asks only that "the broken scope's `failures: N` arithmetic was updated rather than left stale." The counts are updated. Passes.
  - C-7 passes: no assertion lost, all three suites green. Comments do not execute.
  - C-9's clause text at `constitution.md:69` covers strings the job "adds or rewrites," but T-001's C-9 fragment at `:41-43` covers "any comment this task adds to `tests/inbox-to-memory-smoke.sh`." A comment left untouched is neither added nor rewritten by the fragment's wording. Passes.
  - C-8 passes; the path is in scope.

  So the job whose reason for existing is a doc sentence that lied about frontmatter arithmetic (C-4) would ship a test-suite comment that lies about fixture arithmetic, and every check would go green.

  Fix, both halves needed:
  1. In the fixture bullet at `T-001.md:90`, name `tests/inbox-to-memory-smoke.sh:151-155` alongside the counts: the comment explains the off-by-one by pointing at a lone clean record, a second record in that directory falsifies it, and it must be rewritten with the counts rather than after them.
  2. Change T-001's C-9 fragment from "any comment this task adds to `tests/inbox-to-memory-smoke.sh`" to "adds **or rewrites**," matching C-9's own verb at `constitution.md:69`, so the rewritten comment is graded rather than falling between "added" and "existing." T-002's fence should track the same verb.

## Finding 1: did it land, and does the reasoning hold?

Landed, and every factual claim in the new paragraph reproduces.

`T-001.md:90` now names `tests/fixtures/inbox-to-memory/broken/_memory/decisions/` explicitly, and `:92` carries the reason. I reproduced both branches against the tree rather than taking them:

- **A note carrying both keys is already defective.** Built at `notes/` with `schema: 2` and both keys:

  ```
  FAIL .../notes/2026-03-01-mixup-AbCdEfGhIj.md: frontmatter-known-keys: `themes` is in neither key order
  failures: 1
  ```

  `NOTE_KEY_ORDER` (`lint-scope.sh:20`) holds 17 names and `themes` is not among them; `RECORD_KEY_ORDER` (`:21`) holds 19 and does. So the task's claim is right, and so is the masking mechanism: `check_key_order` is reached only at `:187`, after the routing at `:182-186`, and every earlier check in `check_frontmatter` uses the `fail X; return` idiom. A key-domain check sited ahead of the budget guard per C-2 follows that idiom and returns first.

- **A record carrying both keys is clean today.** A `memory_type: Decision` record with 17 keys including both `tags` and `themes`, closing on line 19:

  ```
  scope: /var/folders/.../tmp.Atyin3piDM
  v2 files: 1
  failures: 0
  ```

  Zero failures at baseline is the strongest available evidence that such a fixture carries exactly one defect once the check ships, and it is a check a checker can run in one command. Worth naming in the `check_method` as the cheap version of "no masked second defect," though the existing wording is already sufficient.

The `check_method` addition at `T-001.md:29-35` is the right shape. "Check for a MASKED second defect rather than trusting the single failure line" is the operative instruction and it is general; the sentences after it are elaboration. It names `check_key_order`, which carries both the known-keys branch (`:133`) and the key-order branch (`:143`), so both masked diagnostics are covered, and "every key in it appears in that order" reads as membership plus sequence. Adequate.

## The constitution's stale failing example: does the judgment hold?

It holds. C-6's failing example at `constitution.md:54` — "the fixture also carries a bad key order, so it fails two checks at once" — is inaccurate in two ways, not one: it points at `frontmatter-key-order` where the live hazard is `frontmatter-known-keys`, and "fails two checks at once" describes an outcome that stops being possible the moment C-2's precedence lands, since the second failure is masked rather than printed.

I am not forcing a CON round for it, for three reasons that have to hold together:

1. `failing example` is the clause's illustrative field. C-6's binding text is "carrying that one defect and no other," which is exact, and which the r0 fix satisfies.
2. The only agent who acts on the example is C-6's checker, and that checker reads `T-001.md:29-35` alongside it. That passage now contradicts the example's implication head-on, in the checker's own field: "a fixture with a second problem still reports exactly one failure." The trap the stale example sets is disarmed at the point of use, by the more specific document.
3. The cost of a CON round is not just the round. `constitution.md` is the input to both tasks' checkers; amending it after DEC work has begun means re-auditing the constitution and then re-reading every `check_method` against the amended text.

That reasoning depends on the `check_method` staying as written. If T-001's C-6 fragment is ever narrowed back — if "check for a MASKED second defect" is trimmed — the example becomes load-bearing again and the CON round is owed. Recording it here so a future round finds it: **C-6's failing example is known-stale and is carried deliberately, with the masking correction living in `T-001.md:29-35` instead.**

## Finding 2: did the C-9 partition close?

Closed. Re-derived fragment by fragment against `constitution.md:69`, with the r0 table extended for the by-author split:

| C-9 fragment | owner | fenced out of |
| ------------ | ----- | ------------- |
| `machine-contracts.md` headroom sentence | T-002 (`:25`) | T-001 (`:48`) |
| the new table row | T-002 (`:25-26`) | T-001 (`:48`) |
| the commit message | T-002 (`:26-27`) | T-001 (`:48`) |
| the failure message itself | T-001 (`:41`) | T-002 (`:33-34`) |
| new comments in `lint-scope.sh` | T-001 (`:42`) | T-002 (`:33-34`) |
| suite comments T-001 adds | T-001 (`:42-44`) | T-002 (`:33-34`) |
| suite comments T-002 adds | T-002 (`:30-31`) | T-001 (`:48-49`) |

Seven fragments, seven owners, no double-ownership and no gap. The fences now cut by author rather than by file, which is what the smoke suite needed: it is the one artifact both tasks write to. The retrospective's lesson at `state/archive/2026-08-06/retrospective.md:12` is now applied rather than repeated.

T-001's humanizer instruction was also fixed at the root rather than patched. `:101` now leads with a governing quantifier — "every string a person will read that you added or changed" — and uses the enumeration as illustration, mirroring C-9's own structure. That shape survives a worker adding a string nobody anticipated, which the bare enumeration did not. The parenthetical ruling out from-memory application survives the rewrite, and "including the ones introducing your new inline scope" closes the specific hole. T-002's `:67` gained "and any comment you add to the suite" in the same list, and its `**Voice (C-9).**` heading still makes it unmissable.

Placement is still bullet four of five under House constraints in T-001. Same call as r0: not a failure, since the sentence is unambiguous and says why it matters.

## Minor, not failures

- **T-001's C-6 fragment is stricter than C-6 in one sentence.** `:33-35` says "A fixture placed under `broken/notes/` fails this clause." Routing is by the `memory_type` key, not by directory (`lint-scope.sh:182-186`). I built a `memory_type: Decision` file under `notes/` carrying both keys and it lints clean at baseline — `failures: 0` — so it would carry exactly one defect and satisfy C-6's text ("under `tests/fixtures/inbox-to-memory/broken/`"), while the `check_method` says to fail it. The reason the fragment gives is sound; only the blanket is over-general. Since the brief directs the worker to `_memory/decisions/` anyway, no reachable artifact hits this, but a `check_method` that can fail an artifact its clause permits is a dispute the orchestrator would have to rule against its own checker. One qualifier fixes it: "a fixture under `broken/notes/` *carrying no `memory_type`*."
- **T-002's checker has to attribute suite comments it cannot see attributed.** `T-002.md:33-34` fences out "the suite comments T-001 added." Nothing is committed between the two tasks — T-002 drafts the commit message and the orchestrator commits at ship time — so the working diff against `d4ce6d2` holds both tasks' hunks with no boundary in it. Over-reading costs a redundant read of a string T-001's checker already passed; under-reading drops a T-002 comment nobody grades. The asymmetry is cheap to resolve in wording: tell the T-002 checker that when authorship is unclear it reads the comment anyway.

## Corrections still outstanding from r0

Both were raised at r0 as corrections rather than failures, and both are still open. Neither changes the verdict; both are one phrase each and cheaper to fix in the same pass as the diagnosis above.

- **`v2 files:` is still unnamed.** `T-001.md:90` and C-6's `check_method` both say only `failures: N`. Adding the fixture also moves `v2 files: 19` at `tests/inbox-to-memory-smoke.sh:158`, and this round's placement decision does not change that — a record under `_memory/decisions/` counts in `v2` exactly as a note under `notes/` would (`lint-scope.sh` pass one globs `"$scope"/_memory/*/*.md`). Self-catching: a stale count turns the suite red and C-7 requires green. Still a wasted round if the worker misses it.
- **`spec: .agent-guild/state/spec.md#done-when` is a dangling anchor** in both task files. The criteria live at `spec.md:87` as a `- **Done when:**` bullet inside `## For a Coding Agent`; `#for-a-coding-agent` resolves.

## Re-verified, since a change to one task can disturb the other

Confirmed still holding, re-derived rather than carried forward from r0 where the fixes bear on them:

- **C-2's scratch-copy mutation** survives both edits intact. `T-001.md:13-20` still carries the full sequence: assert against a file closing past line 20, mutate on a scratch copy to sit the check after the budget guard, re-run, confirm it now fails, and restore or copy before returning with the reason attached ("a dirty `lint-scope.sh` is attributed to the worker by C-8's diff-scope run"). The worker-side twin at `:104` is also intact, which is the redundancy that matters, since `compose-brief.py` never passes `check_method` to a worker.
- **The C-6/C-2 fixture separation** is undisturbed and improved. `T-001.md:88` still opens "Two separate cases, and they cannot share a file," and the new paragraph at `:92` sits inside the first bullet without weakening the second at `:93` ("the over-budget case, which by construction has a second thing wrong with it and so does not belong in `broken/`"). This remains the strongest passage in the decomposition: it states the constraint, the discriminating property of each file, and why the two cannot be merged.
- **Baseline.** `git diff d4ce6d2 -- inbox-to-memory/ tests/` is empty; the working tree is the baseline on every deliverable path. `inbox-to-memory-smoke` exit 0, `file-issue-smoke` exit 0, `handoff-smoke` exit 0. `check-diff-scope.py inbox-to-memory/ tests/ --ignore .agent-guild/` → `OK: 0 path(s) in scope`, exit 0.
- **Spec coverage.** Unchanged from r0's table: `spec.md:88` → T-001 (C-1, C-2); `:89` → T-001 (C-3); `:90` → T-002 (C-5); `:91` → T-002 (C-4); `:92` → T-001 (C-6); `:93` → both (C-7). No spec requirement is unmapped and neither task claims scope the spec does not grant.
- **Routing.** T-001 is clear-spec implementation judged on correctness → worker-standard/sonnet, checked by checker-judgment. T-002 is prose and taste → worker-craft/opus, checker-judgment. C-8's script is absorbed into each task's judgment checker because a task carries one `checker` field and only that direction works. Unchanged and correct.
- **deps.** The write conflict on `tests/inbox-to-memory-smoke.sh`, C-7's `comm -23` comparison, and C-5's genuine data dependency on the shipped check each independently force the edge. The comment-staleness finding adds a fourth reason: both tasks now have a stake in the same file's prose, and serializing them is what lets the by-author C-9 fences mean anything.
