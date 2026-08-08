---
schema: 2
id: oVYv2RYrA0
date: 2026-04-28
type: working-session
summary: 'Field-level walkthrough of the case extract with Hal Brenner in the room for the first time. Three of the six mapped columns turned out to mean something other than their names.'
attendees: [Adaeze Nwoye, Tomas Kral, Ruaridh Cale, Hal Brenner]
tags: [underwriting-assist, kestrel]
topics: [field-mapping, data-quality, member-data]
entities: [Lantern, Kestrel, Hal Brenner, Ruaridh Cale, Nadia Okonjo]
open_questions: 1
resolved_questions: 1
deferred_tensions: 0
unpromoted_candidates: 0
related: [extends::DibesvlEcG]
---

## Notable Quotes

1. "That column has not meant referral reason since about 2014. It means whatever the last screen wrote into it." — Hal Brenner (raw: "whatever the last screen wrote" L21)
2. "We had this mapping reviewed. It came back approved." — Tomas Kral (raw: "it came back approved" L26)
3. "Approved by me reading a document. You are asking me now what is in the field, which is a different question." — Hal Brenner (raw: "what is in the field" L30)
4. "Three of six. If we had built on that we would have found out in September." — Adaeze Nwoye (raw: "we would have found out in September" L48)

## Tensions

- [tension: resolved] The mapping had been signed off in writing three weeks earlier and was wrong in half its columns, which left the team unsure whether the sign-off had been worth anything. | stakes: a review step everyone trusts and nobody has tested is worse than no review step | resolved: the mapping was redone live in the session with Hal reading the actual values, and the corrected version is what the pilot design now rests on

## Stated Assumptions

- The reason-code column is unreliable back to 2014 and reliable before it, which is the opposite of what anyone would have guessed.
- The corrected mapping holds for the referred and declined book. Nobody has checked it against the accepted book, and nobody needs to.

## Unstated Assumptions

- The sign-off was read as verification. It was one person confirming that a document was internally consistent, which is not the same claim.

## Open Questions

- [open question: referral-reason-code-truth] Is there any field that reliably carries why a case was referred after 2014, or does that reason only exist in free text? | resolver: @Hal Brenner | blocks: whether the pilot can group referrals by reason or only score them individually | default: we treat referral reason as unavailable and lose the grouping the underwriters asked for
- [open question resolved: declined-book-outcome-source] Where does an outcome for a declined case actually come from, given nothing was underwritten? | resolved: there is no outcome — Ruaridh Cale confirmed the pilot scores agreement with the underwriter of record and nothing else, and the proposal has to say so in those words

## Action Items / Memory Candidates

- [ ] @Tomas (priority: high) — redo the sample extract against the corrected mapping before anything else is built on it (raw: "before anything else is built" L54)
- [ ] @Adaeze (priority: medium) — the case-level extract still has not been in front of the data-sharing review board and the proposal date depends on it (raw: "still has not been in front of" L61)
- [[lantern-scores-declined-book-yZCQWC3yhR|memory]] The pilot scores the referred and declined book only, against the underwriter of record rather than against an outcome.

## Raw Content

Verbatim transcript omitted from the fixture. Snippet anchors above are illustrative.
