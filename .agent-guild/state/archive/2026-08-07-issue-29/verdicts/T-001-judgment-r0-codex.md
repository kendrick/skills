# Verdict: T-001 (codex lane)

**Status:** PASS

**Checker:** checker-courier  
**Vendor:** openai  
**Model:** gpt-5.6-terra  
**Task ID:** T-001

## Findings

### C-1 — PASS

The observed count-one record says `1 link checked`, while the provided printf derives `0 links checked` and `2 links checked` at zero and two.

**Evidence:** Observed C-1 stdout and supplied `links_noun=links` / `if [[ "$links_checked" -eq 1 ]]` record construction.

### C-2 — PASS

The isolated one-line record contains no directive to paste it and ends with the factual link-resolution sentence.

**Evidence:** C-2 record-isolation evidence shows neither paste phrase nor `patterns journal` in the `Verified ...` line.

### C-3 — PASS

The instruction is stdout-only, precedes a blank line and the final record, refers forward to the paragraph below, and is absent together with the record on the failing run.

**Evidence:** C-3 split-stream capture has empty stderr; the supplied failing combo output contains neither `Paste the paragraph below` nor `Verified`.

### C-4 — PASS

The removed count, instruction, and leak assertions have equally specific or stronger replacements, and the record-related assertion set grows.

**Evidence:** C-4 diff replaces the count literal precisely, uses whole-line `require_line` plus extracted-record rejection for the instruction, and adds both new instruction-leak and combo-absence checks.

### C-11 — PASS

The suite structurally extracts the record and rejects a directive within it, pins the instruction as a whole line, and rejects the instruction on the failing combo run.

**Evidence:** C-11 diff includes `pass_record`/`record_directive`, `require_line "$pass_out" "Paste the paragraph below into the scope's patterns journal."`, and `combo_instruction` rejection.

### C-11 — MINOR

The required placement-mutant verification was not attempted in this read-only courier review, so only the three assertions' structural presence is independently confirmed here.

**Evidence:** The inlined routing note directs read-only couriers to judge the structural half and state that they did not run the mutation.

## Summary

All sampled clauses (C-1, C-2, C-3, C-4, C-11) pass. The courier's structural judgment of C-11 is complete; load-bearing verification via C-6's placement mutant was not run (read-only context).

---
Generated: 2026-08-07T13:59:15.629463
