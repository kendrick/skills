---
schema: 2
id: yvOXPdadL8
memory_type: Decision
title: 'Fieldnote takes policy header from the overnight extract and shows the notice-taker how old it is'
status: accepted
date: 2026-04-14
last_confirmed: 2026-04-14
source_refs: [gyDyAWNuLt]
applies_to: [integration, intake-ui]
owners: [Colm Deasy]
tags: [claims-intake, kestrel]
related: [extends::rWFFzufjXj]
---

# Fieldnote takes policy header from the overnight extract and shows the notice-taker how old it is

## Decision Question

Where does Fieldnote get policy header data at first notice, and what does it tell the person taking the call about how current that data is?

## Decision Outcome

Policy header comes off the second batch of the overnight Kestrel extract. The header panel carries the extract timestamp in plain text next to the policy details, and the same timestamp is written onto the claim record at the moment of notice, so a later complaint can be answered with what the notice-taker was actually looking at.

## Alternatives Considered

- A synchronous read against Kestrel. Ruled out on Hal Brenner's account that no such path exists outside the business day and none at all during day-close, which is the same answer two prior programmes got.
- A same-day delta feed. Ruled out on scale: nobody at Calderwood has built one, and adding it would have turned a two-week integration into a platform change with its own approvals.

## Approved By

Colm Deasy, at the 2026-04-14 integration review, with Yvette Mbeki confirming that day-old header is workable at first notice as long as it says so on the screen.

## Context

Reversible. Nothing in the design assumes the extract is the permanent source; if a live path ever appears, the header panel changes and the timestamp field goes null. The timestamp on the claim record is the part worth keeping either way — it was Yvette's point that a stale value nobody flagged is what generates the complaint, not the staleness itself.
