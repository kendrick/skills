---
task: T-006
checker: checker-deterministic
vendor: anthropic
model: claude-haiku-4-5-20251001
verdict: PASS
checked_at: 2026-08-08T00:00:00Z
duration_ms: None
cost_usd: None
---

<!-- GENERATED FILE—do not hand-edit. Rendered by render-verdict.py
from the verdict JSON, the record of record. Edit the JSON and
re-render instead. -->

## Per-clause results

| clause | severity | description | evidence |
| ------ | -------- | ------------ | -------- |
| C-15 | minor | Line-number citation successfully rewritten to stable form using comment text; grep sweep found zero matches and new citation resolves correctly. | Grep result: /usr/bin/grep -rnoE 'inbox-to-memory\\.sh:[0-9]+' _maintenance/ inbox-to-memory/ tests/ returned exit code 1 (zero hits). New citation in eval-scope.sh:6-7 references comment text 'The checked-in fixtures are never migrated or stamped in place.' which appears exactly once at tests/inbox-to-memory-smoke.sh:1421. |
