---
task: DEC-audit
checker: checker-courier
vendor: openai
model: gpt-5.6-terra
verdict: FAIL
checked_at: 2026-08-06T22:41:35Z
duration_ms: 152088
cost_usd: None
---

<!-- GENERATED FILE—do not hand-edit. Rendered by render-verdict.py
from the verdict JSON, the record of record. Edit the JSON and
re-render instead. -->

## Per-clause results

| clause | severity | description | evidence |
| ------ | -------- | ------------ | -------- |
| C-1 | blocker | T-001 cites C-1 but its check method explicitly checks only the fixture seam, not C-1’s required suite assertion that the Tier 2 extract omits the raw-only name and reuses extract_body. | T-001 check_method says “C-1/C-2 (seam only, the clauses themselves land in T-002)” and only asks to inspect Raw Content plus the seam record; Constitution C-1 requires a checker-judgment review of the suite’s Tier 2 extract assertion and extract_body reuse. |
| C-2 | blocker | T-001 cites C-2 but does not perform C-2’s prescribed check of the apply refusal, diagnostic, byte-identical note, and corresponding suite assertion. | T-001 check_method labels C-1/C-2 “seam only”; Constitution C-2 requires confirming migrate-scope.sh emits tier2-entity-unsourced, leaves the note byte-identical, and that the suite asserts both using the raw-content-only name. |
| C-12 | blocker | C-12’s whole-test-diff check has four owners, creating prohibited double reads of the same clause fragment and artifacts. | T-001, T-002, T-003, and T-004 each cite C-12 and each runs `git diff 1f17478 -- tests/` plus all three suites. The ownership rubric prohibits two tasks claiming verification of the same clause fragment on the same artifact. |
| C-13 | blocker | C-13 is both multiply owned and routed incorrectly: every task assigns its verbatim shell check to checker-judgment rather than checker-deterministic. | T-001 through T-004 each cite C-13, set `checker: checker-judgment`, and say to run the Constitution C-13 script check verbatim. The routing table states that a clause checked by a script routes to checker-deterministic. |
| C-15 | major | T-002 assigns C-15’s standalone deterministic script check to checker-judgment, violating the required routing for script-checked clauses. | T-002 sets `checker: checker-judgment` while its C-15 method is “run the constitution C-15 script check verbatim”; the Constitution defines C-15’s check solely as a `test ...` shell command, and the routing table requires checker-deterministic for script checks. |
| C-10 | blocker | No task applies C-10’s dedicated check to the final record template after T-004 edits it, leaving the final emitted record behavior without a final owner. | T-003 owns C-10 but says “The record paragraph’s final prose is T-004’s, not this task’s.” T-004 changes the template in verify-migration.sh but does not cite C-10 or restate its check; its C-12 baseline comparison only protects assertions present at `1f17478`, not C-10 assertions added by T-003. |

## Diagnosis

- **C-1** (blocker): T-001 cites C-1 but its check method explicitly checks only the fixture seam, not C-1’s required suite assertion that the Tier 2 extract omits the raw-only name and reuses extract_body.
  evidence: T-001 check_method says “C-1/C-2 (seam only, the clauses themselves land in T-002)” and only asks to inspect Raw Content plus the seam record; Constitution C-1 requires a checker-judgment review of the suite’s Tier 2 extract assertion and extract_body reuse.
- **C-2** (blocker): T-001 cites C-2 but does not perform C-2’s prescribed check of the apply refusal, diagnostic, byte-identical note, and corresponding suite assertion.
  evidence: T-001 check_method labels C-1/C-2 “seam only”; Constitution C-2 requires confirming migrate-scope.sh emits tier2-entity-unsourced, leaves the note byte-identical, and that the suite asserts both using the raw-content-only name.
- **C-12** (blocker): C-12’s whole-test-diff check has four owners, creating prohibited double reads of the same clause fragment and artifacts.
  evidence: T-001, T-002, T-003, and T-004 each cite C-12 and each runs `git diff 1f17478 -- tests/` plus all three suites. The ownership rubric prohibits two tasks claiming verification of the same clause fragment on the same artifact.
- **C-13** (blocker): C-13 is both multiply owned and routed incorrectly: every task assigns its verbatim shell check to checker-judgment rather than checker-deterministic.
  evidence: T-001 through T-004 each cite C-13, set `checker: checker-judgment`, and say to run the Constitution C-13 script check verbatim. The routing table states that a clause checked by a script routes to checker-deterministic.
- **C-15** (major): T-002 assigns C-15’s standalone deterministic script check to checker-judgment, violating the required routing for script-checked clauses.
  evidence: T-002 sets `checker: checker-judgment` while its C-15 method is “run the constitution C-15 script check verbatim”; the Constitution defines C-15’s check solely as a `test ...` shell command, and the routing table requires checker-deterministic for script checks.
- **C-10** (blocker): No task applies C-10’s dedicated check to the final record template after T-004 edits it, leaving the final emitted record behavior without a final owner.
  evidence: T-003 owns C-10 but says “The record paragraph’s final prose is T-004’s, not this task’s.” T-004 changes the template in verify-migration.sh but does not cite C-10 or restate its check; its C-12 baseline comparison only protects assertions present at `1f17478`, not C-10 assertions added by T-003.
