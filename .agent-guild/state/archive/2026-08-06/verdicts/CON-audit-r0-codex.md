---
task: CON-audit
checker: checker-courier
vendor: openai
model: gpt-5.6-terra
verdict: FAIL
checked_at: 2026-08-06T00:00:00Z
duration_ms: None
cost_usd: None
---

<!-- GENERATED FILE—do not hand-edit. Rendered by render-verdict.py
from the verdict JSON, the record of record. Edit the JSON and
re-render instead. -->

## Per-clause results

| clause | severity | description | evidence |
| ------ | -------- | ------------ | -------- |
| C-3 | major | The stated check never verifies the required one-line frontmatter form of each summary, so a multiline but fully extract-supported summary would pass the check while violating the clause. | C-3 text requires "Each generated `summary` is one line," but its check only directs the checker to trace claims to the Tier 2 extract. |
| C-4 | blocker | The check does not establish that Tier 2 approval can be applied per file and as a batch, because grouping proposals in a dry-run report is not a test of either approval path. | C-4 text requires "Tier 2 approval is granted per file or as one batch," while its check verifies a Tier-1-only apply and that the dry-run report groups proposals by file. |
| C-6 | major | The check omits the clause's requirement that verification report the lint failure count, so an implementation that merely reports a generic lint failure would satisfy both prescribed cases. | C-6 text says verification "reports its failure count," but the first prescribed check only requires nonzero exit and that it "name the failure," while the abort case requires only attribution to lint status. |
| C-8 | major | The sole prescribed test covers a committed rename and does not test deletion or separate reporting of renames and deletions, despite the clause requiring failure for every non-`M` status. | C-8 text requires failure "on any status other than `M`, naming renames and deletions separately," but its check requires only a committed rename to produce `verify-rename`. |
| C-15 | major | The key-count tripwire does not test the structural premises on which the no-budget-refusal claim depends, so it can pass even if `summary` or `entities` are no longer in `NOTE_KEY_ORDER` or rendering/skip behavior changes. | C-15 check only counts words in `NOTE_KEY_ORDER`; C-15 text additionally relies on `summary` and `entities` being among those keys, one-line rendering without blanks/comments, and the `has_schema_key` skip. The local evidence likewise reports only "NOTE_KEY_ORDER words=17." |
| C-16 | major | The required humanizer audit-and-revise process is not falsifiable from the resulting prose, and the proposed judgment depends on a pattern list and surrounding-file voice that are not included in the audit material. | C-16 requires every string to "goes through the `humanizer` skill's audit-and-revise loop," while its check says to compare against the humanizer pattern list and surrounding files; neither the pattern list nor surrounding prose is inlined. |

## Diagnosis

- **C-3** (major): The stated check never verifies the required one-line frontmatter form of each summary, so a multiline but fully extract-supported summary would pass the check while violating the clause.
  evidence: C-3 text requires "Each generated `summary` is one line," but its check only directs the checker to trace claims to the Tier 2 extract.
- **C-4** (blocker): The check does not establish that Tier 2 approval can be applied per file and as a batch, because grouping proposals in a dry-run report is not a test of either approval path.
  evidence: C-4 text requires "Tier 2 approval is granted per file or as one batch," while its check verifies a Tier-1-only apply and that the dry-run report groups proposals by file.
- **C-6** (major): The check omits the clause's requirement that verification report the lint failure count, so an implementation that merely reports a generic lint failure would satisfy both prescribed cases.
  evidence: C-6 text says verification "reports its failure count," but the first prescribed check only requires nonzero exit and that it "name the failure," while the abort case requires only attribution to lint status.
- **C-8** (major): The sole prescribed test covers a committed rename and does not test deletion or separate reporting of renames and deletions, despite the clause requiring failure for every non-`M` status.
  evidence: C-8 text requires failure "on any status other than `M`, naming renames and deletions separately," but its check requires only a committed rename to produce `verify-rename`.
- **C-15** (major): The key-count tripwire does not test the structural premises on which the no-budget-refusal claim depends, so it can pass even if `summary` or `entities` are no longer in `NOTE_KEY_ORDER` or rendering/skip behavior changes.
  evidence: C-15 check only counts words in `NOTE_KEY_ORDER`; C-15 text additionally relies on `summary` and `entities` being among those keys, one-line rendering without blanks/comments, and the `has_schema_key` skip. The local evidence likewise reports only "NOTE_KEY_ORDER words=17."
- **C-16** (major): The required humanizer audit-and-revise process is not falsifiable from the resulting prose, and the proposed judgment depends on a pattern list and surrounding-file voice that are not included in the audit material.
  evidence: C-16 requires every string to "goes through the `humanizer` skill's audit-and-revise loop," while its check says to compare against the humanizer pattern list and surrounding files; neither the pattern list nor surrounding prose is inlined.
