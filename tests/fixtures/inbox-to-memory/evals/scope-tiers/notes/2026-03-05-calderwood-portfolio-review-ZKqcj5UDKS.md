---
schema: 2
id: ZKqcj5UDKS
date: 2026-03-05
type: status
summary: 'Quarterly portfolio review across both Calderwood engagements. Claims-intake is on plan, underwriting-assist is waiting on data it has not been able to ask for yet.'
attendees: [Adaeze Nwoye, Dermot Sayer, Fiona Traill, Hal Brenner]
tags: [calderwood, governance]
topics: [portfolio, data-access, sequencing]
entities: [Calderwood Mutual, Kestrel, Dermot Sayer, Fiona Traill, Hal Brenner, Nadia Okonjo]
open_questions: 1
resolved_questions: 0
deferred_tensions: 0
unpromoted_candidates: 0
---

## Notable Quotes

1. "Both of you are queued behind the same door and neither of you knew the other was in the queue." — Hal Brenner (raw: "queued behind the same door" L31)
2. "I have a build plan I believe in and a data plan I am guessing at." — Fiona Traill (raw: "a data plan I am guessing at" L44)
3. "Nothing has gone wrong. It is just slower than the plan says, and the plan was written by us." — Adaeze Nwoye (raw: "the plan was written by us" L58)

## Tensions

## Stated Assumptions

- Claims-intake can reach code-complete without any new extract from Kestrel, because it reads the policy master through the interface Hal already exposes.
- Underwriting-assist cannot start scoring anything until it has a case-level extract, and it has not yet been able to put a request in front of anyone.

## Unstated Assumptions

- Two engagements asking the same governance function for two different things were assumed to be two independent queues.

## Open Questions

- [open question: kestrel-extract-ownership] Who owns the nightly Kestrel extract now that two engagements read from it? | resolver: @Hal Brenner | blocks: whether underwriting-assist can piggyback on the claims-intake feed or has to raise its own | default: each engagement builds its own extract and Hal maintains two

## Action Items / Memory Candidates

- [ ] @Adaeze (priority: high) — get both engagements onto one view of what Nadia Okonjo's function actually needs from us (raw: "one view of what she needs" L66)
- [ ] @Fiona (priority: medium) — write the case-level extract request down even though there is nowhere to send it yet (raw: "write it down anyway" L71)

## Raw Content

Verbatim transcript omitted from the fixture. Snippet anchors above are illustrative.
