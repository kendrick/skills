---
task: T-001
checker: checker-courier
vendor: openai
model: gpt-5.6-terra
verdict: FAIL
checked_at: 2026-08-09T01:23:06Z
duration_ms: None
cost_usd: None
---

<!-- GENERATED FILE—do not hand-edit. Rendered by render-verdict.py
from the verdict JSON, the record of record. Edit the JSON and
re-render instead. -->

## Per-clause results

| clause | severity | description | evidence |
| ------ | -------- | ------------ | -------- |
| C-18 | major | The four-line transcript does not demonstrate real-path deduplication, because an implementation that deduplicates only literal path strings—or does not deduplicate when this fixture has no differently spelled aliases—can emit the same two stamped and two skipped lines and totals. | C-18 output names four display paths but supplies neither the input references/groups nor their resolved real paths; no absolute-versus-relative (or other alias) collision is shown. |
| C-5 | major | Although the arguments necessarily arrive in opposite orders and the test rules out direct per-argument printing, it does not establish general path-sorted output: an implementation that emits stamped results before skipped results while preserving input order within each bucket produces this exact transcript. | Both C-5 runs contain one stamped atlas record and one skipped v1 record, with stamped output preceding skipped output; no reversed pair within the same outcome branch is tested. |
| C-6 | major | The budget wording and unchanged file do not establish that the budget branch was reached; an implementation that refuses every insertion, or has faulty precondition or line-count logic, can print the same message and leave this file held. | C-6 contains only the rejection fixture and its asserted reason; it has no paired accepted v2 record with a missing key that fits within budget and is demonstrably inserted. |
| C-2 | minor | Matching SHA-1 digests establish only matching final content with overwhelming practical confidence, not that the v1 branch performed no write or other file mutation: a script can rewrite identical bytes, change metadata, or mutate and restore the file before hashing. | C-2 records only matching before/after SHA-1 values and does not compare inode, mtime, permissions, write activity, or intermediate state. |

## Diagnosis

- **C-18** (major): The four-line transcript does not demonstrate real-path deduplication, because an implementation that deduplicates only literal path strings—or does not deduplicate when this fixture has no differently spelled aliases—can emit the same two stamped and two skipped lines and totals.
  evidence: C-18 output names four display paths but supplies neither the input references/groups nor their resolved real paths; no absolute-versus-relative (or other alias) collision is shown.
- **C-5** (major): Although the arguments necessarily arrive in opposite orders and the test rules out direct per-argument printing, it does not establish general path-sorted output: an implementation that emits stamped results before skipped results while preserving input order within each bucket produces this exact transcript.
  evidence: Both C-5 runs contain one stamped atlas record and one skipped v1 record, with stamped output preceding skipped output; no reversed pair within the same outcome branch is tested.
- **C-6** (major): The budget wording and unchanged file do not establish that the budget branch was reached; an implementation that refuses every insertion, or has faulty precondition or line-count logic, can print the same message and leave this file held.
  evidence: C-6 contains only the rejection fixture and its asserted reason; it has no paired accepted v2 record with a missing key that fits within budget and is demonstrably inserted.
- **C-2** (minor): Matching SHA-1 digests establish only matching final content with overwhelming practical confidence, not that the v1 branch performed no write or other file mutation: a script can rewrite identical bytes, change metadata, or mutate and restore the file before hashing.
  evidence: C-2 records only matching before/after SHA-1 values and does not compare inode, mtime, permissions, write activity, or intermediate state.
