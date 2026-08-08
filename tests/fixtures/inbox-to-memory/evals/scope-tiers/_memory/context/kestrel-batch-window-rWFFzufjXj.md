---
schema: 2
id: rWFFzufjXj
memory_type: Context
title: 'Kestrel is readable only through the overnight extract, and the usable copy lands after 02:30'
status: accepted
date: 2026-04-16
last_confirmed: 2026-04-16
source_refs: [FUItKUpxH6]
applies_to: [claims-intake, underwriting-assist]
owners: [Hal Brenner]
tags: [calderwood, kestrel, member-data]
related: []
---

# Kestrel is readable only through the overnight extract, and the usable copy lands after 02:30

## Context Scope

Any engagement at Calderwood that needs policy, member, or claim data out of the Kestrel policy administration platform. Both live engagements sit behind this, and Hal Brenner says every engagement before them has too.

## Fact Statement

Kestrel exposes no synchronous read path outside the business day, and none at all during day-close. The supported interface is the overnight extract, which runs in two batches between 22:00 and 02:30. The first batch carries policy header and the second carries transactions and adjustments, so anything that needs a complete picture is reading a file that does not exist until the second batch closes. Hal will add fields to the extract on request; he will not hold a copy on a consuming team's behalf, and each engagement owns the retention of whatever it takes.

## Provenance

Hal Brenner, at the 2026-04-16 platform forum. He described the same conversation happening with every prior programme, each of which asked for a live feed and each of which ended up on the extract.

## Why This Matters

Any plan at this client that assumes same-day data is wrong by a day, and the error shows up as a testing problem rather than as a design problem. Design against yesterday from the start. It also fixes the earliest a nightly job can be scheduled, which is the constraint most likely to be discovered late.
