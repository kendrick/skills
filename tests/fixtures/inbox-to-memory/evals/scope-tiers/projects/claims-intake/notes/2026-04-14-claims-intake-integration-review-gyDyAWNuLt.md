---
schema: 2
id: gyDyAWNuLt
date: 2026-04-14
type: working-session
summary: 'Integration review for Fieldnote. Policy header comes off the overnight extract and the notice-taker sees how old it is; the counter path is formally out of phase 1.'
attendees: [Bridget Lomax, Tomas Kral, Colm Deasy, Yvette Mbeki]
tags: [claims-intake, kestrel]
topics: [integration, staleness, member-data]
entities: [Fieldnote, Kestrel, Colm Deasy, Yvette Mbeki, Hal Brenner, Nadia Okonjo]
open_questions: 1
resolved_questions: 1
deferred_tensions: 0
unpromoted_candidates: 0
related: [extends::9wCOavZA2T]
---

## Notable Quotes

1. "A day old is fine. A day old and not saying so is the thing that gets us a complaint." — Yvette Mbeki (raw: "not saying so is the thing" L26)
2. "We asked Hal for a live path in week two. I would rather not spend week fourteen asking again." — Tomas Kral (raw: "rather not spend week fourteen" L33)
3. "Nobody has masked anything here before. There is no house pattern to copy." — Colm Deasy (raw: "no house pattern to copy" L49)

## Decisions

- [decision: two-way] Fieldnote reads policy header from the overnight Kestrel extract and shows the notice-taker the extract timestamp on the header panel. | committed: @Colm Deasy | discarded: a synchronous read against Kestrel, ruled out because Hal Brenner has told two prior programmes the same thing and the answer has not moved; and a same-day delta feed, which nobody at Calderwood has built and which would have made a two-week integration into a platform change

## Stated Assumptions

- A policy header that is up to 28 hours old is acceptable at first notice, because nothing the notice-taker does at that moment depends on a same-day change.

## Unstated Assumptions

- The staleness marker was designed as a UI element. Nobody has asked whether it needs to be on the claim record too, which is where a complaint would go looking.

## Open Questions

- [open question: preprod-data-masking] What has to happen to a member record before it can sit in the Fieldnote pre-prod environment? | resolver: @Nadia Okonjo | blocks: end-to-end testing against anything other than synthetic data | default: we test on synthetic data only and meet the real shape of the data in UAT
- [open question resolved: counter-intake-in-scope] Does the branch counter intake path come into scope for phase 1? | resolved: out, confirmed by Dermot Sayer on 2026-03-11 and reflected in the phase 1 scope — the counter goes to the phase 2 gate with the device estate attached to it

## Action Items / Memory Candidates

- [ ] @Tomas (priority: medium) — confirm the second-batch completion time against three weeks of actuals rather than the documented window (raw: "against actuals not the doc" L41)
- [ ] @Bridget (priority: high) — put the masking question in front of the data-sharing review board, whatever that turns out to involve (raw: "whatever that turns out to involve" L57)
- [[fieldnote-reads-policy-from-extract-yvOXPdadL8|memory]] Fieldnote takes policy header from the overnight extract and surfaces the extract timestamp at first notice.

## Raw Content

Verbatim transcript omitted from the fixture. Snippet anchors above are illustrative.
