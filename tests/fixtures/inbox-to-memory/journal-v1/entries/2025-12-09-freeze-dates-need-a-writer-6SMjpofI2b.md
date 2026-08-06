---
id: 6SMjpofI2b
memory_type: Journal
title: 'A freeze date nobody will put in writing is not a date'
status: current
date: 2025-12-09
themes:
  - governance
  - delivery-risk
applies_to:
  - cutover-planning
source_refs:
  - scope: client
    path: 11 Clients/northwind/pursuits/atlas
    note_id: ZGulgExW0q
related: []
---

# A freeze date nobody will put in writing is not a date

Across two clients now, a freeze window has been treated as settled while the only artifact backing it was somebody's recollection of a meeting. Both times the date moved, and both times the delivery team found out from a calendar invite rather than from the people who moved it.

The tell is the phrasing. "Finance said end of Q1" is a recollection. "Finance sent the end date on the 4th" is a date. The first one costs nothing to say and nothing to change.

This fixture exists to exercise the migrator against a journal entry's nested source reference, which is the one compound form that carries a scope path rather than a relation.
