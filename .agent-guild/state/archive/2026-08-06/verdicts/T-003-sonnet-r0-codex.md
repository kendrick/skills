# T-003 — Courier Verdict (codex lane)

**Verdict:** FAIL

**Checker:** checker-courier (OpenAI gpt-5.6-terra)  
**Task:** T-003 — verify-migration.sh, with suite assertions  
**Timestamp:** 2026-08-06T17:00:00Z

---

## Findings

### C-6: Verification lints every migrated file
**Status:** SATISFIED

The script records the sibling lint command's exit status, distinguishes an abort without a summary, and the inlined suite asserts both the planted-defect and stub-abort cases.

**Evidence:** Inlined script lint-sweep block and inlined verification-suite sections "An aborting lint still fails verification" and "One planted lint defect."

---

### C-7: Every link that resolved before resolves after
**Status:** FAILS (blocker)

Although the script reads targets from the pre-migration ref, the suite has no scenario where the link source exists only at that ref, so a post-migration-tree mutation would still pass its asserted link count and diagnostics.

**Evidence:** Inlined script function since_tree_targets uses git ls-tree and git show at since_ref; the inlined suite's only asserted count is "links checked: 1 (id fallback: 1)" while its link source note remains present post-migration.

---

### C-8: Renames are asserted at zero
**Status:** SATISFIED

Rename and deletion detection uses the diff from the supplied ref, and the suite commits both changes before asserting verify-rename diagnostics.

**Evidence:** Inlined script rename-sweep block uses git diff --name-status -M "$since_ref"; the inlined combo scenario commits git mv and git rm, asserts a clean porcelain state, then requires both rename diagnostics.

---

### C-9: Verification reports and never repairs
**Status:** SATISFIED

Verification only reports failures, and the suite checks byte-identical scopes after failing runs and requires all three simultaneous combo failures.

**Evidence:** Inlined script contains no write or migration command; the inlined suite compares hash_scope before and after both combo and lint-defect failures and requires the link, rename, and deletion findings.

---

### C-10: The record is emitted on success, never written
**Status:** FAILS (blocker)

The suite asserts the record's prefix and suffix and separately asserts summary counts, but never asserts that the record paragraph itself carries this run's real counts, so hardcoded record counts would pass.

**Evidence:** Inlined passing-run assertions require "Verified … against …" and "Paste this paragraph …", while the count assertions target the separately printed summary; the prior diagnosis describes the zero-count record mutation passing.

---

### C-12: No existing assertion is deleted or weakened
**Status:** SATISFIED (deterministic)

The supplied deterministic evidence shows no removed require_* or refute_* assertion and reports all three smoke suites exiting zero.

**Evidence:** Inlined Locally Collected Evidence reports the sole removed line is fixture prose and lists exit 0 for inbox-to-memory, file-issue, and handoff smoke suites.

---

### C-13: The diff stays in scope
**Status:** SATISFIED (deterministic)

The supplied deterministic scope-check command exited zero and the only identified new file is within the permitted inbox-to-memory area.

**Evidence:** Inlined Locally Collected Evidence gives the exact scope-check command with exit 0 and identifies the new verification script as in scope.

---

### C-16: The prose reads like a person wrote it
**Status:** SATISFIED

The added human-facing script prose is concise, technical, and explains rationale without promotional framing, rule-of-three padding, or code-restating comments.

**Evidence:** Inlined script header and sweep comments explain committed-migration behavior, sibling resolution, abort handling, history-based link collection, and stdout-only records.

---

## Summary

Two blocker clauses FAIL—the same two identified in the first attempt's diagnosis:

- **C-7**: Script is correct, but the suite lacks an assertion that would discriminate a tree-based read from the correct history-based read.
- **C-10**: Script is correct, but the suite doesn't pin the record paragraph's counts to the run's actual values.

Six clauses SATISFIED, including both deterministic checks (C-12, C-13) confirmed by pre-run evidence.
