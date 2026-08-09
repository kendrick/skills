---
id: Ld9pW3nZq6
memory_type: Context
title: 'Schema work stops during the quarterly close window'
status: accepted
date: 2025-12-02
source_refs:
  - Kt7vR2mQx4
applies_to:
  - reporting
owners:
  - Dana Whitfield
tags:
  - scheduling
---

# Schema work stops during the quarterly close window

## Context Scope

Anything that alters a schema the reporting pipeline reads.

## Fact Statement

The last two weeks of each quarter are closed to schema changes. The window is set by Finance and applies whether or not the change is believed to be safe.

## Provenance

Stated by Dana Whitfield in the 2025-12-02 kickoff.

## Why This Matters

A migration planned without checking the calendar can lose two weeks with no warning, and the constraint is not visible anywhere in the codebase.
