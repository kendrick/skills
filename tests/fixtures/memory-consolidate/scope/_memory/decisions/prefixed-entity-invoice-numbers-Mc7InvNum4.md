---
schema: 1
id: Mc7InvNum4
memory_type: Decision
title: Prefixed entity invoice numbers
status: accepted
date: 2026-08-01
last_confirmed: 2026-09-10
applies_to: [topic:billing]
supersedes: [Mc6InvNum3]
---

## Context

Support kept confusing invoices from two entities that shared a number, so each number now starts with the entity code.

## Decision

Adopt the summary above.

## Consequences

Billing's invoice tooling follows this until a later Decision supersedes it.
