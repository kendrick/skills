---
source: github-issue
ref: kendrick/skills#17
issue: 17
title: "inbox-to-memory v2: eval suite for judgment-dependent behavior"
fetched_at: 2026-08-07T19:53:23Z
---
# inbox-to-memory v2: eval suite for judgment-dependent behavior

## Parent

#4

## What to build

A scenario suite for the behavior no lint can check, following the pattern already established for file-issue: fixtures, each scenario run with and without the skill loaded, graded on the delta. The no-skill baseline is the step that tells you whether the skill taught anything.

Scenarios cover whether contradiction detection finds a real conflict against an accepted record and round-trips through sign-off into an amendment, whether generated summaries and entities are any good, whether scope proposals land at the right tier, and whether an unacknowledged tension gets spotted at all.

### Acceptance criteria

- [ ] Every scenario names its fixture, its prompt, and its pass condition
- [ ] Each runs with and without the skill, and the delta is what gets graded
- [ ] The contradiction round-trip is covered end to end
- [ ] Unacknowledged-tension detection has its own scenario
- [ ] Scope-proposal accuracy is covered across all three tiers
- [ ] Nothing is written to a real scope during evaluation
- [ ] The doc lives beside the other maintainer evals

## Blocked by

- #14 (contradiction detection)
