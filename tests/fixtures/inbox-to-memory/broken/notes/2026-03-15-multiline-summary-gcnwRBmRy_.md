---
schema: 2
id: gcnwRBmRy_
date: 2026-03-15
type: working-session
summary: >
  Planted defect: a summary written as a folded block scalar, which reads fine
  to a human and breaks every grep that expects the value on one line.
attendees: [Priya Raghavan]
tags: [runbook]
topics: [rollback]
entities: [Atlas]
open_questions: 0
resolved_questions: 0
deferred_tensions: 0
unpromoted_candidates: 0
---

## Notable Quotes

1. "The summary is the thing you read instead of opening the file." — Priya Raghavan (raw: "instead of opening the file" L6)

## Raw Content

Fixture body. `grep '^summary:'` returns the marker and none of the sentence.
