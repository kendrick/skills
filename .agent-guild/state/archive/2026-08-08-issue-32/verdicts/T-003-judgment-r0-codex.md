---
task: T-003
checker: checker-courier
vendor: openai
model: gpt-5.6-terra
verdict: FAIL
checked_at: 2026-08-08T18:31:20Z
duration_ms: None
cost_usd: None
---

<!-- GENERATED FILE—do not hand-edit. Rendered by render-verdict.py
from the verdict JSON, the record of record. Edit the JSON and
re-render instead. -->

## Per-clause results

| clause | severity | description | evidence |
| ------ | -------- | ------------ | -------- |
| C-10 | note | Passage 1 passes all four prose checks. | Passage 1 rewritten lint-scope.sh header comment. |
| C-10 | note | Passage 2 passes all four prose checks. | Passage 2 rewritten pass-two gate comment. |
| C-10 | minor | Issue 1: this rule states which v2-only checks stop at the generation line without supplying the reason that those requirements do not apply to v1 notes. | Passage 3: "The frontmatter contract, the token grammar, the anchor rule, and the four derived counts all stop at the generation line." |
| C-10 | note | Passage 4 passes all four prose checks. | Passage 4 rewritten skill-document paragraph. |
| C-10 | note | Passage 5 passes all four prose checks; its em dash is correctly unspaced. | Passage 5 rewritten migration-guide opening. |
| C-10 | note | Passage 6 passes all four prose checks. | Passage 6 rewritten table explanation. |

## Diagnosis

- **C-10** (note): Passage 1 passes all four prose checks.
  evidence: Passage 1 rewritten lint-scope.sh header comment.
- **C-10** (note): Passage 2 passes all four prose checks.
  evidence: Passage 2 rewritten pass-two gate comment.
- **C-10** (minor): Issue 1: this rule states which v2-only checks stop at the generation line without supplying the reason that those requirements do not apply to v1 notes.
  evidence: Passage 3: "The frontmatter contract, the token grammar, the anchor rule, and the four derived counts all stop at the generation line."
- **C-10** (note): Passage 4 passes all four prose checks.
  evidence: Passage 4 rewritten skill-document paragraph.
- **C-10** (note): Passage 5 passes all four prose checks; its em dash is correctly unspaced.
  evidence: Passage 5 rewritten migration-guide opening.
- **C-10** (note): Passage 6 passes all four prose checks.
  evidence: Passage 6 rewritten table explanation.
