---
skill: jira-refine
schema: 1
source: refinement-2026-08-30.vtt
source_path: /Users/example/transcripts/refinement-2026-08-30.vtt
session: 2026-08-30
label: refined-2026-08-30
config: /Users/example/jira-refine.toml
projects: [PROJ, PLAT]
generated: 2026-08-30T16:40:05
---

## PROJ-412

status: approved
segment: 00:12:04 - 00:19:40
duration: 7m36s
words: 1140
revisited: 0
mentions: [PROJ-398]

### Context
The nightly export times out for the largest customers whenever a report crosses fifty thousand rows.

### Acceptance criteria
- [ ] Export completes for a 50k-row report without a timeout (raw: "fifty thousand rows without timing out" 00:13:10)

### Out of scope

### Dependencies
- PROJ-398 (raw: "can't start until three ninety eight lands" 00:14:02)

### Goal

### Open questions
- not discussed: out of scope
- not discussed: goal

### Provenance
- source: refinement-2026-08-30.vtt
- session: 2026-08-30
- segment: 00:12:04 - 00:19:40

### Source excerpt
```text
[00:12:04] Dan: Okay, PROJ dash four twelve. So the export thing.
[00:13:10] Priya: Right, fifty thousand rows without timing out is the bar support keeps citing.
[00:14:02] Dan: And this can't start until three ninety eight lands, that's a hard blocker.
```

## PROJ-413

status: approved
segment: 00:20:00 - 00:24:15
duration: 4m15s
words: 620
revisited: 0
mentions: []

### Context
The SSO redirect drops query params when a client runs its own identity provider.

### Acceptance criteria
- [ ] A redirect preserves the query string exactly (raw: "preserves the query string" 00:21:40)

### Out of scope
- Fixing the legacy OAuth1 integration is a separate ticket

### Dependencies

### Goal

### Open questions
- not discussed: dependencies
- not discussed: goal

### Provenance
- source: refinement-2026-08-30.vtt
- session: 2026-08-30
- segment: 00:20:00 - 00:24:15

### Source excerpt
```text
[00:20:00] Priya: Next, PROJ 413. The login flow ticket, SSO redirect drops query params.
[00:21:40] Dan: The fix preserves the query string byte for byte, that's the bar.
[00:22:10] Priya: Also, fixing the legacy OAuth1 integration is a separate ticket, not this one.
```

## PROJ-398

status: approved
segment: 00:25:00 - 00:27:30
duration: 2m30s
words: 310
revisited: 0
mentions: []

### Context
The identity data migration that several other tickets are waiting on.

### Acceptance criteria
- [ ] All legacy identity records are migrated with no duplicate emails (raw: "no duplicate emails across the migrated set" 00:26:05)

### Out of scope

### Dependencies

### Goal
Consolidate identity data onto the new schema before Q4 (raw: "consolidate identity data onto the new schema" 00:25:40)

### Open questions
- not discussed: out of scope
- not discussed: dependencies

### Provenance
- source: refinement-2026-08-30.vtt
- session: 2026-08-30
- segment: 00:25:00 - 00:27:30

### Source excerpt
```text
[00:25:00] Dan: PROJ three ninety eight, the identity migration everyone is blocked on.
[00:25:40] Priya: The goal is we consolidate identity data onto the new schema before Q4.
[00:26:05] Dan: And there should be no duplicate emails across the migrated set when we're done.
```

## PLAT-77

status: staged
segment: 00:28:00 - 00:29:30
duration: 1m30s
words: 145
revisited: 1
mentions: []

### Context

### Acceptance criteria

### Out of scope

### Dependencies

### Goal

### Open questions
- not discussed: context
- not discussed: acceptance criteria
- not discussed: out of scope
- not discussed: dependencies
- not discussed: goal

### Provenance
- source: refinement-2026-08-30.vtt
- session: 2026-08-30
- segment: 00:28:00 - 00:29:30

### Source excerpt
```text
[00:28:00] Dan: Okay, platform seventy seven, the auth-service migration cutover.
[00:29:00] Priya: We still need to lock the cutover date down.
```

## PLAT-14

status: skipped
segment: 00:30:00 - 00:31:10
duration: 1m10s
words: 98
revisited: 0
mentions: []

### Context
A proposal to add dark mode to the admin console, raised in passing.

### Acceptance criteria

### Out of scope
- Not this quarter, the team already has a full roadmap

### Dependencies

### Goal

### Open questions
- not discussed: acceptance criteria
- not discussed: dependencies
- not discussed: goal

### Provenance
- source: refinement-2026-08-30.vtt
- session: 2026-08-30
- segment: 00:30:00 - 00:31:10

### Source excerpt
```text
[00:30:00] Priya: Someone mentioned PLAT fourteen, dark mode for the admin console.
[00:30:40] Dan: Not this quarter, we already have a full roadmap, let's skip it for now.
```

## Summary

### Spike candidates
- PLAT-77: revisited 1x

### Mentioned in passing
- PROJ-501 (mentioned only, 1x)

### Gaps to file
- retry-backoff work on the nightly export job has no ticket yet

### Apply log
