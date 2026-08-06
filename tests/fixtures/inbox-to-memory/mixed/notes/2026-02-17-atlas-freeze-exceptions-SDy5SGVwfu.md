---
schema: 2
id: SDy5SGVwfu
date: 2026-02-17
type: working-session
summary: 'Freeze-exception routing came up against two accepted records: one amended, one dismissed, one still open.'
attendees: [Priya Raghavan, Marcus Dell]
tags: [runbook, cutover]
topics: [freeze-window, regional-rollout]
entities: [Atlas, Priya Raghavan, Marcus Dell, Northwind Billing]
open_questions: 0
resolved_questions: 0
deferred_tensions: 0
unpromoted_candidates: 1
related: [extends::j5jLCGc5il]
---

## Notable Quotes

1. "Ops signs it, delivery routes it." — Priya Raghavan (raw: "Ops signs it, delivery routes it" L31)

## Tensions

- [contradicts accepted: [[freeze-window-owned-by-ops-ocPwdpeY0a|freeze window ownership]]] Priya described freeze exceptions as the delivery lead's call. | claims: freeze exceptions are Ops' call and always have been | dismissed: they route through delivery and are signed by Ops, so both are true — Marcus, in the room
- [contradicts accepted: [[atlas-region-topology-mPmy8XBe5H|region topology]]] Marcus said EMEA is one deployment region now that the second cluster was retired. | claims: EMEA is one billing region and two deployment regions

## Decisions

- [decision: two-way] Freeze exceptions keep routing through the delivery lead for logging, with the Ops sign-off unchanged. | committed: @Marcus Dell | discarded: moving sign-off to delivery, which nobody could name a reason for beyond it being faster

## Stated Assumptions

- The retired EMEA cluster is not coming back before cutover.

## Unstated Assumptions

- Everyone reading "region" in the runbook means the billing boundary.

## Open Questions

## Action Items / Memory Candidates

- [ ] @Marcus (priority: medium) — confirm the EMEA cluster retirement with the platform team (raw: "second cluster was retired" L44)
- [[atlas-region-topology-mPmy8XBe5H|memory — updated]] Billing region and deployment region are not the same boundary, and the EMEA deployment count is now in flux.

## Raw Content

Verbatim transcript omitted from the fixture. Snippet anchors above are illustrative.
