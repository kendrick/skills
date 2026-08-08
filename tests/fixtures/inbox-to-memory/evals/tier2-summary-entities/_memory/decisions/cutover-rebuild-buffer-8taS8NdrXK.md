---
id: 8taS8NdrXK
memory_type: Decision
title: 'Cutover windows require a 48-hour rebuild buffer'
status: accepted
date: 2025-09-08
source_refs:
  - i59pVI65GO
applies_to:
  - cutover-plan
owners:
  - Elena Vasquez
tags:
  - kestrel
related:
  - _YEL9dotcZ
---

# Cutover windows require a 48-hour rebuild buffer

## Decision Question

How much slack does a cutover window need around the index rebuild?

## Decision Outcome

Every cutover window reserves 48 hours for the rebuild step, regardless of how fast the last run went. The buffer is fixed, not sized to the most recent run.

## Alternatives Considered

- Size the buffer to the average of past runs. Rejected: an average hides the slow run, and the slow run is the one that breaks a tight window.
- Leave the buffer unscheduled and extend on the day if needed. Rejected: extending live is what turned a weekend cutover into a lost weekend the first time.

## Approved By

Elena Vasquez, engagement lead.

## Context

The prior rebuild ran six hours against a four-hour estimate, and the cutover window had no slack to absorb it.
