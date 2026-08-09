---
schema: 2
id: kQ2MiN7kOA
memory_type: Context
title: 'Harrow takes no writes between 01:00 and 04:00'
status: accepted
date: 2026-03-10
last_confirmed: 2026-05-19
source_refs: [0NvNhqo-ic]
applies_to: [integration, work-orders]
owners: [Deshawn Pryor]
tags: [tanager, harrow]
related: []
---

# Harrow takes no writes between 01:00 and 04:00

## Context Scope

Anything writing into Harrow on a schedule, and anything downstream that assumes a job closed in the field is closed in the back office.

## Fact Statement

Harrow shuts to writes at 01:00 and reopens at 04:00 while the overnight run rebuilds the day. A push arriving inside that window is not rejected — it queues, and it lands at 04:00. The window has been in place since Harrow went in, and network operations schedules the meter-read import inside it.

## Provenance

Deshawn Pryor walked the integration surface at the 2026-03-10 mobilisation session and read the window off Harrow's own job calendar. It is documented nowhere Quillon can see, which is why it came as news to them.

## Why This Matters

A leak job closed at 01:20 is in Harrow at 04:00, not at 01:20. Any report reading completion off Harrow before four in the morning is reading yesterday, and the crews notice first, because they can see the job closed on the handset and closed nowhere else.
