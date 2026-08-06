---
schema: 2
id: o7fhuG__gc
date: 2026-01-27
type: stakeholder-call
summary: 'Finance check-in opened three questions and answered none of them.'
attendees: [Marcus Dell, Kendrick Arnett]
tags: [billing, cutover]
topics: [freeze-window, rollback]
entities: [Atlas, Marcus Dell, Northwind Billing]
open_questions: 3
resolved_questions: 0
deferred_tensions: 0
unpromoted_candidates: 0
---

## Notable Quotes

1. "I can ask Finance. I can't promise what they say." — Marcus Dell (raw: "I can ask Finance" L11)

## Tensions

## Stated Assumptions

- Finance will answer a direct written request within a week.

## Unstated Assumptions

- Asking Finance and getting a date are treated as the same step.

## Open Questions

- [open question: billing-freeze-scope] Does the billing freeze lift before the cutover date? | resolver: @Marcus Dell | blocks: cutover date | default: cutover plans against a date nobody confirmed
- [open question: rollback-execution-owner] Who executes the rollback if cutover fails overnight? | resolver: @unknown | blocks: cutover go/no-go | default: the on-call engineer improvises
- [open question: dry-run-date] When does the cutover dry run actually happen? | resolver: @unknown | blocks: rollback rehearsal | default: the first rollback anyone attempts is the real one

## Action Items / Memory Candidates

- [ ] @Marcus (priority: high) — send Finance a written request for the freeze end date (raw: "send Finance a written" L14)

## Raw Content

Verbatim transcript omitted from the fixture. Snippet anchors above are illustrative.
