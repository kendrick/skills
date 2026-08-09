---
source: github-issue
ref: kendrick/skills#27
issue: 27
title: "inbox-to-memory v2: last_confirmed write-through on confirmation"
fetched_at: 2026-08-08T19:28:16Z
---

# inbox-to-memory v2: last_confirmed write-through on confirmation

## Parent

#4

## What to build

When an inbox file confirms a claim an `accepted` memory record already makes, the skill stamps that record's `last_confirmed` date without stopping for approval, and names every record it touched in the verify report.

This is the one sanctioned exception to the skill's rule that nothing in `_memory/` gets written without per-item sign-off. It is metadata rather than content, and gating it would put an obviously-yes prompt in front of every input, which trains rubber-stamping and devalues the gate protecting the writes that need protecting. Because it is the only exception, the operating rules name it as such instead of leaving it implicit.

Records missing the field gain it only if they are v2. V1 records are skipped entirely.

Confirmation is detected by the same pass that detects contradictions, which is why that work gates this.

### Acceptance criteria

- [ ] A confirmation stamps `last_confirmed` on a v2 record
- [ ] V1 records are skipped and never gain the field
- [ ] Every stamped record is named in the verify report
- [ ] No confirmation prompts for per-record approval
- [ ] The operating rules name the write-through as the sole sanctioned exception, with its reasoning
- [ ] A record confirmed twice in one run is stamped once
- [ ] The smoke test asserts that a run over the mixed fixture leaves v1 records untouched

## Blocked by

- #14 (contradiction detection)
