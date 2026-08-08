# T-006 Codex Lane Second Opinion — Blind Scope-Tier Classification

**Task:** T-006 — Scope-signal eval fixture  
**Checker:** checker-courier  
**Vendor:** openai  
**Model:** gpt-5.6-terra  
**Verdict:** PASS  
**Timestamp:** 2026-08-07

## Summary

The codex lane independently classified the four fixture inputs in blind mode (without knowing intended tier assignments or order). The vendor's assignments matched the fixture's built-for tiers exactly:

- Input A (governance sync) → **client** ✓
- Input B (notice without policy) → **project** ✓
- Input C (data discovery retro) → **journal** ✓
- Input D (cutover date decision) → **project** (two-tier conflict, narrowest scope) ✓

## Key Findings

The vendor correctly identified Input D as the tiebreak case carrying signals at two tiers (project and client), and applied the Conflict Resolution principle correctly—Project is the floor. The note's reporting-line signals (client tier) and its core decision-making process signals (client tier) were balanced against its primary substance (a project-specific cutover date), resulting in the narrower assignment.

All four inputs' tier assignments align with what `references/scope-decisions.md` suggests for their content signals. No classification errors; no overreach into journal for project-bound content.

## Implications for the Fixture

The independent reproduction of the four-way split (project, client, journal, tiebreak→project) constitutes strong evidence that the fixture routes as built. The vendor's reasoning would need to be examined in detail to assess depth of signal reasoning, but the core tier assignments passed blind classification without deviation.
