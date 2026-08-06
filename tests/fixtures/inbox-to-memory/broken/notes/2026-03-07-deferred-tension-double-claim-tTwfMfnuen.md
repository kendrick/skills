---
schema: 2
id: tTwfMfnuen
date: 2026-03-07
type: working-session
summary: 'Planted defect: two deferred tensions riding on one open question.'
attendees: [Priya Raghavan]
tags: [runbook]
topics: [rollback]
entities: [Atlas]
open_questions: 1
resolved_questions: 0
deferred_tensions: 2
unpromoted_candidates: 0
---

## Tensions

- [tension: deferred] Rollback execution has no named owner. | stakes: nobody is authorized to pull the trigger overnight | open question: rollback-execution-owner
- [tension: deferred] The runbook has no rollback section at all. | stakes: even a named owner would have nothing to follow | open question: rollback-execution-owner

## Open Questions

- [open question: rollback-execution-owner] Who executes the rollback if cutover fails overnight? | resolver: @unknown | blocks: cutover go/no-go | default: the on-call engineer improvises

## Raw Content

Fixture body. Closing the one question would silently close both tensions.
