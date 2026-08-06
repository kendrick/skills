---
schema: 2
id: mPmy8XBe5H
memory_type: Context
title: 'Billing region and deployment region are not the same boundary'
status: accepted
date: 2026-01-13
last_confirmed: 2026-02-10
source_refs: [JJuYgImRWn, j5jLCGc5il]
applies_to: [billing, regional-rollout]
owners: [Marcus Dell]
tags: [topology]
related: [clarifies::G2k65qG3Nc]
---

# Billing region and deployment region are not the same boundary

## Context Scope

Any conversation that uses the word "region" about Atlas.

## Fact Statement

Atlas has two independent region concepts. Billing regions follow the Northwind contract boundaries; deployment regions follow the cloud provider's. EMEA is one billing region and two deployment regions, which is why the same rollout can be both compliant and double-vendored depending on which map you are reading.

## Provenance

Surfaced in the 2026-01-13 readiness session, where three people used "region" to mean two different things without noticing, and confirmed again in the 2026-02-10 runbook review.

## Why This Matters

The one-vendor-per-region decision is written against billing regions. Reading it against deployment regions produces the opposite conclusion, which is a mistake that survives review because both readings sound correct.
