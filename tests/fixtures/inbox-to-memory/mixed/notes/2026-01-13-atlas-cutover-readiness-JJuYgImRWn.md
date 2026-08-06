---
id: JJuYgImRWn
date: 2026-01-13
type: working-session
summary: 'Readiness review found the rollback step unowned and the freeze end date still unwritten.'
attendees: [Priya Raghavan, Marcus Dell, Kendrick Arnett]
tags: [cutover, readiness]
topics: [rollback, freeze-window]
entities: [Atlas, Priya Raghavan, Marcus Dell, Northwind Billing]
related: [confirms::ZGulgExW0q]
---

<!--
Deliberately v2-shaped and deliberately unversioned. Inline arrays, a flattened
relationship reference, a single-line summary, canonical entities: everything a
content sniffer would read as v2. The absent version key is the only thing that
decides, and this file exists to prove nothing else gets a vote.
-->

## Notable Quotes

1. "Readiness has an owner for every step except the one that matters." — Priya Raghavan (raw: L21)

## Tensions

- The rollback step has no named owner, and each person in the room assumed a different one. — Priya Raghavan, Marcus Dell (raw: L44)

## Stated Assumptions

- Rollback is exercised at least once before cutover.

## Unstated Assumptions

- Someone treated "owns the runbook" and "owns executing the rollback" as the same role.

## Open Questions

- Who executes the rollback if cutover fails overnight?
- Does the billing freeze lift before the cutover date?

## Action Items / Memory Candidates

- [ ] @Marcus (priority: high) — name a rollback owner in the runbook (raw: L47)
- [memory candidate: project] Rollback ownership is named in the runbook, not assumed from the on-call rotation.

## Raw Content

Verbatim transcript omitted from the fixture. Line refs above are illustrative.
