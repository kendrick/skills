---
id: Qj2vTy_2pZ
memory_type: Context
title: 'A refund cannot be started without the printed receipt barcode'
status: superseded
date: 2026-02-24
source_refs: [vC8nfl6HWd]
applies_to: [refunds]
owners: [Ellie Kwan]
tags: [pos-rollout]
related: []
---

# A refund cannot be started without the printed receipt barcode

## Context Scope

Refund handling in the Rowan pilot build, at the register and at the service desk.

## Fact Statement

The refund flow opens from a scanned receipt barcode and from nothing else. A customer who has lost the receipt is sent to the district office with the card statement.

## Provenance

Stated by Ellie Kwan at the February controls workshop as the constraint the approval-code prompt would hang off.

## Why This Matters

Superseded on 2026-03-31, when card lookup shipped with the pilot build and a clerk could pull a purchase from the card the customer paid with. Nothing replaced this record; the constraint went away rather than changing, and the approval-code threshold is unaffected either way.
