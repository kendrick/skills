---
schema: 2
id: 9wCOavZA2T
date: 2026-02-19
type: scoping-call
summary: 'Opening discovery for Fieldnote. Scope of phase 1 is the phone and web intake path; the counter path and the pre-prod data question both came out unresolved.'
attendees: [Bridget Lomax, Tomas Kral, Dermot Sayer, Colm Deasy, Yvette Mbeki]
tags: [claims-intake, calderwood]
topics: [scope, intake-channels, member-data]
entities: [Fieldnote, Kestrel, Dermot Sayer, Colm Deasy, Yvette Mbeki, Nadia Okonjo]
open_questions: 2
resolved_questions: 0
deferred_tensions: 0
unpromoted_candidates: 1
---

## Notable Quotes

1. "The screen has not changed since I joined and I joined in 2009." — Yvette Mbeki (raw: "not changed since I joined" L14)
2. "Eleven minutes a call and nine of them are finding the policy." — Yvette Mbeki (raw: "nine of them are finding the policy" L19)
3. "I can tell you what the counter does. I cannot tell you whether it is yours." — Colm Deasy (raw: "whether it is yours" L38)
4. "Nadia Okonjo will not look at it as a project. She looks at the request." — Colm Deasy (raw: "she looks at the request" L61)

## Tensions

- [tension: resolved] Yvette sizes the intake problem in call minutes and Colm sizes it in device estate, so the two of them scoped different projects for twenty minutes before anyone noticed. | stakes: a phase 1 estimated on call handling and delivered as a hardware refresh misses both numbers | resolved: Bridget restated the scope in both units and the room agreed the estimate is a call-handling one

## Stated Assumptions

- The pilot dataset of first notices pulled for discovery is representative of a normal quarter. It covers 2025-12-01 to 2026-02-28, which includes a storm week.
- Fieldnote reads the policy master through the interface Kestrel already exposes and does not need a new extract of its own.

## Unstated Assumptions

- Everyone in the room treated the data-sharing review board as a step at the end rather than a gate at the front, and nobody in the room had ever taken a request to it.

## Open Questions

- [open question: counter-intake-in-scope] Does the branch counter intake path come into scope for phase 1? | resolver: @Dermot Sayer | blocks: the phase 1 device and training estimate | default: it stays out and the counter staff hear about it from someone else
- [open question: member-data-approval-route] What does Fieldnote need in front of Nadia Okonjo and the data-sharing review board before it can hold member data in pre-prod? | resolver: @Nadia Okonjo | blocks: the start of end-to-end testing | default: we build against synthetic data and discover the shape of the real thing in UAT

## Action Items / Memory Candidates

- [ ] @Tomas (priority: high) — pull the first notice sample and get the channel split out of it (raw: "get me the split by channel" L27)
- [ ] @Colm (priority: medium) — find out who has actually taken a request to the data-sharing review board and how long it took them (raw: "who has actually done it" L64)
- [memory candidate: project] Phase 1 of Fieldnote covers the phone and web intake paths only. The branch counter path is deferred to the phase 2 gate on device-estate grounds.

## Raw Content

Verbatim transcript omitted from the fixture. Snippet anchors above are illustrative.
