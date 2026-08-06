---
id: Hq3U2Su1gy
memory_type: Context
title: 'Billing schema is frozen until Q1'
status: accepted
date: 2025-11-04
source_refs:
  - 3iMu15QJ_x
applies_to:
  - billing
owners:
  - Marcus Dell
tags:
  - billing
related:
  - G2k65qG3Nc
---

# Billing schema is frozen until Q1

## Context Scope

The legacy billing service and anything that writes to its schema.

## Fact Statement

Schema changes to legacy billing are frozen until Q1. The freeze is enforced by Finance, not by engineering, and lifting it requires Finance sign-off rather than a code review.

## Provenance

Stated by Marcus Dell in the 2025-11-04 scoping call.

## Why This Matters

Any design that needs a new billing column has to either wait for Q1 or route around the schema entirely. Discovering this late is what turns a two-week integration into a quarter.
