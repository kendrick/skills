---
id: i59pVI65GO
date: 2025-09-08
type: working-session
attendees:
  - Elena Vasquez
  - Tomasz Krol
tags:
  - migration
  - kestrel
topics:
  - cutover-plan
  - index-rebuild
---

## Notable Quotes

1. "We are not cutting over on a Friday again." — Elena Vasquez (raw: L9)
2. "The index rebuild took six hours last time and nobody budgeted for it." — Tomasz Krol (raw: L22)

## Tensions

- Elena wants a Tuesday cutover window; Tomasz says the index rebuild needs a Thursday-to-Sunday buffer to finish safely. — Elena Vasquez, Tomasz Krol (raw: L30)

## Stated Assumptions

- The staging environment mirrors production index sizes.

## Unstated Assumptions

- Everyone assumed the vendor's migration window from the old contract still applies.

## Open Questions

- Who owns sign-off on the final cutover date?
- Does the index rebuild block the cutover, or can it run in parallel?

## Action Items / Memory Candidates

- [ ] @Tomasz (priority: high) — benchmark the index rebuild against a production-sized copy (raw: L45)
- [memory candidate: project] Cutover windows need a minimum 48-hour rebuild buffer, based on the six-hour rebuild that ran long last time.
- [memory candidate: client] The vendor's migration window from the prior contract does not automatically carry over and needs reconfirming per engagement.

## Raw Content

Tomas Krohl said the staging rebuild finished in four hours this run, better than last time but still tight against a weekend window.
After some back and forth, the team locked the cutover for November 14th.
Elena said she'd send the change notice once the date was locked.
