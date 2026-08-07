# Verdict: T-002-sonnet-r0-codex

**Task:** T-002 — Tier 2 sidecar in migrate-scope.sh, with suite assertions
**Checker:** checker-courier (codex lane, OpenAI gpt-5.6-terra)
**Verdict:** PASS

## Clauses Evaluated

### C-1: Tier 2 input stops at Raw Content
- **Result:** PASS
- **Analysis:** Line 731 in smoke suite asserts via `refute_text` that "Cascade Analytics" (the raw-content-only name) is absent from the seam extract. Lines 176-184 in migrate-scope.sh define the same `extract_body` awk rule used for both Tier 1 counts and Tier 2 extraction at line 369. No second copy of the extraction rule exists.

### C-2: Every written entity is sourced from the extract
- **Result:** PASS
- **Analysis:** Lines 393-410 in migrate-scope.sh implement entity sourcing check: grep for entity in extract, refuse with diagnostic `tier2-entity-unsourced` if absent, continue without writing. Suite line 857 asserts the diagnostic in output. Line 858 checks via shasum that the note remains byte-identical after refusal.

### C-3: The summary is a reading of the sections and nothing more
- **Result:** PASS
- **Analysis:** seam_summary traces to extract (Tensions + Open Questions + quotes support all claims). other_summary traces to extract (Tensions support all claims). No unsupported claims in either fixture summary.

### C-4: Tier 2 is gated separately from Tier 1
- **Result:** PASS
- **Analysis:** Lines 760-774 show subset apply writes entities to seam_note, not to other_note (gating). Lines 807-821 show batched dry-run extracts proposals under their own file headers (grouping).

### C-5: Rejecting Tier 2 leaves Tier 1 intact
- **Result:** PASS
- **Analysis:** Lines 777-782 assert via shasum equality that a note omitted from proposals is byte-identical to Tier-1-only apply.

### C-11: A second run stays a no-op, Tier 2 included
- **Result:** PASS
- **Analysis:** Lines 903-908 assert `migrated: 0` and that proposals.yaml does not exist on second --tier2-extract over Tier-2-applied scope.

### C-12: No existing assertion is deleted or weakened
- **Result:** PASS
- **Analysis:** Pre-run evidence: git diff shows only fixture prose removed, no assertions removed. All three suites exit 0.

### C-13: The diff stays in scope
- **Result:** PASS
- **Analysis:** Pre-run evidence: git diff command exits 0, nothing out-of-scope changed.

### C-15: Tier 2 cannot reach the budget
- **Result:** PASS
- **Analysis:** Pre-run evidence: NOTE_KEY_ORDER holds 17 names (unchanged), frontmatter renders at line 19 at worst.

### C-16: The prose reads like a person wrote it
- **Result:** PASS
- **Analysis:** migrate-scope.sh comments explain WHY (boundary drift, judgment separation, extract review requirement, write point safety, sourcing principle), not WHAT. No promotional framing, no rule-of-three padding. House voice: technical, concise, constraint-focused.

## Summary

All 10 clauses PASS. Zero findings. The Tier 2 implementation in migrate-scope.sh adheres to its constitution in full, and the smoke suite's assertions are comprehensive and well-targeted.

---
Generated: 2026-08-06T23:36:45Z  
Lane: codex  
Model: gpt-5.6-terra
