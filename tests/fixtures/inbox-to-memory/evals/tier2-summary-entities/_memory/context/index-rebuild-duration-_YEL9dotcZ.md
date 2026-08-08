---
id: _YEL9dotcZ
memory_type: Context
title: 'Index rebuild runs four to six hours under load'
status: accepted
date: 2025-09-08
source_refs:
  - i59pVI65GO
applies_to:
  - kestrel
owners:
  - Tomasz Krol
tags:
  - migration
related:
  - 8taS8NdrXK
---

# Index rebuild runs four to six hours under load

## Context Scope

The Kestrel index rebuild step, wherever it runs ahead of a cutover.

## Fact Statement

The rebuild has taken as long as six hours on a full production-sized index, and four hours on a lighter staging run. Any cutover plan has to budget for the slower end.

## Provenance

Stated by Tomasz Krol in the 2025-09-08 cutover planning session.

## Why This Matters

A cutover window sized to the faster run leaves no slack if the rebuild runs long again, which is exactly what happened the first time.
