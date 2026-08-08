OK: rendered ./verdict.md
hecker-courier
vendor: openai
model: gpt-5.6-terra
verdict: FAIL
checked_at: 2026-08-08T18:51:06Z
duration_ms: None
cost_usd: None
---

<!-- GENERATED FILE—do not hand-edit. Rendered by render-verdict.py
from the verdict JSON, the record of record. Edit the JSON and
re-render instead. -->

## Per-clause results

| clause | severity | description | evidence |
| ------ | -------- | ------------ | -------- |
| C-10 | major | Passage 7 has no newly added rule-only sentence and no prohibited header or spaced em dash, but “The walk takes in v1 files as well, checking their wiki links and nothing else: a link resolves against every file in scope, and that resolution never reads the file's own frontmatter.” restates implementation mechanics in a denser register without distinctly explaining why the “nothing else” side of the split is right. | User-supplied Passage 7, After, lines 3-5. |
| C-10 | major | Passage 8 has no prohibited header or spaced em dash, but “It caches v1 bodies too, for a narrower reason.” states the caching rule while only promising, rather than supplying, its reason in that sentence. | User-supplied Passage 8, After, line 3. |
| C-10 | major | Passage 7’s scope-wide/no-frontmatter rationale is substantively duplicative of the unchanged explanation below rather than a different reason, Passage 8’s four-sentence implementation detour crowds out the original pass-one rule, and neither addition fully matches the surrounding prose’s direct policy-level voice, so C-10 does not hold. | User-supplied Passage 7 unchanged context and Passage 8 After. |

## Diagnosis

- **C-10** (major): Passage 7 has no newly added rule-only sentence and no prohibited header or spaced em dash, but “The walk takes in v1 files as well, checking their wiki links and nothing else: a link resolves against every file in scope, and that resolution never reads the file's own frontmatter.” restates implementation mechanics in a denser register without distinctly explaining why the “nothing else” side of the split is right.
  evidence: User-supplied Passage 7, After, lines 3-5.
- **C-10** (major): Passage 8 has no prohibited header or spaced em dash, but “It caches v1 bodies too, for a narrower reason.” states the caching rule while only promising, rather than supplying, its reason in that sentence.
  evidence: User-supplied Passage 8, After, line 3.
- **C-10** (major): Passage 7’s scope-wide/no-frontmatter rationale is substantively duplicative of the unchanged explanation below rather than a different reason, Passage 8’s four-sentence implementation detour crowds out the original pass-one rule, and neither addition fully matches the surrounding prose’s direct policy-level voice, so C-10 does not hold.
  evidence: User-supplied Passage 7 unchanged context and Passage 8 After.
