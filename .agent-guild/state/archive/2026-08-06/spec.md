---
source: github-issue
ref: kendrick/skills#16
issue: 16
title: 'inbox-to-memory v2: migration Tier 2, verification, and the journal record'
fetched_at: 2026-08-06T21:33:47Z
---

# inbox-to-memory v2: migration Tier 2, verification, and the journal record

## Parent

#4

## What to build

Tier 2 and the closing verification. Summary and entities are generated per note from extracted sections and never from raw content, presented in the dry-run report for per-file edit or batch approval, gated separately from Tier 1.

After applying, a verification sweep runs the full lint over every migrated file, confirms every pre-existing wiki link still resolves with the id fallback, and asserts that zero files were renamed. Failures get reported loudly and nothing is fixed silently. The run ends by emitting a one-paragraph migration record the user can drop into the scope's patterns journal.

### Acceptance criteria

- [ ] Generated summary and entities derive only from extracted sections
- [ ] Tier 2 approval is separate from Tier 1 and works per-file or batched
- [ ] Rejecting a Tier 2 proposal leaves that note's Tier 1 changes intact
- [ ] Verification runs the full lint over every migrated file
- [ ] Every link resolving before migration resolves after
- [ ] Rename count is asserted at zero via git
- [ ] Verification failures are reported and never auto-repaired
- [ ] The migration paragraph is emitted, and never written anywhere automatically

## Blocked by

- #15 (migration Tier 1)
