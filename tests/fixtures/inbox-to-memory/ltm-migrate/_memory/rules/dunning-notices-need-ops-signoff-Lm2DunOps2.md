---
schema: 2
id: Lm2DunOps2
memory_type: Rule
title: 'Ops signs off every dunning notice before it sends'
status: accepted
date: 2026-06-03
source_refs: [Lm0BilRev0]
applies_to: [regions::emea]
owners: [ops]
tags: [billing]
related: []
---

# Ops signs off every dunning notice before it sends

## Rule Statement

No dunning notice goes to a customer until ops has checked the balance against the ledger.

## Enforcement

required

## Rationale

A stale balance reached a customer in May and triggered a dispute.

## Known Exceptions

None.
