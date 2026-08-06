---
schema: 2
id: kFtFA-Xh5P
date: 2026-03-02
type: working-session
summary: 'Planted defect: commented-out optional keys push the closing fence past line 20.'
attendees: [Priya Raghavan, Marcus Dell]
tags: [runbook]
topics: [rollback]
entities: [Atlas]
# source_file: attachments/steerco-deck.pptx
# transcript_corrections: [Saatchi -> Shachi]
# effective_from: 2026-03-02
# effective_to: null
# supersedes:
# superseded_by:
# owners: [Marcus Dell]
# applies_to: [billing]
open_questions: 0
resolved_questions: 0
deferred_tensions: 0
unpromoted_candidates: 0
---

## Notable Quotes

1. "Every key is in order and single-line. The block just got long." — Marcus Dell (raw: "the block just got long" L6)

## Raw Content

Fixture body. The defect is above. Commented-out optional keys are the realistic way a
block overruns the budget, which is why the defect is planted as comments rather than
as content nobody would actually write.
