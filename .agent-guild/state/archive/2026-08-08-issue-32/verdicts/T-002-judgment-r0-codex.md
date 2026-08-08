# Verdict: T-002 (codex lane, second opinion)

**Task:** T-002 — Pin the v1 link behavior in the smoke suite
**Checker:** checker-courier (second opinion via codex lane)
**Vendor:** openai
**Model:** gpt-5.6-terra
**Verdict:** PASS

## Findings

### Finding 1: C-7
**Severity:** info

Line references are ordinal added (`+`) lines in the supplied diff, which has no source-line hunk numbers. Case 1 is pinned at added lines 31–32: `require_failure` requires `FAIL $v1_broken_note: link-broken: `this-target-does-not-exist-AAAAAAAAAA` resolves neither by name nor by id `AAAAAAAAAA`` and `require_line` requires `failures: 1`. This specifically proves that the injected, in-body v1 link is checked and reported; removing or weakening the former would allow a v1-wide skip to appear successful.

**Evidence:**

Supplied diff added lines 23–32: v1_broken_scope fixture copy, inject_above_fence call, require_failure, and require_line.

### Finding 2: C-7
**Severity:** info

Case 2 is pinned at added lines 53–54: the passing scope requires `failures: 0` and refutes `link-broken: `one-vendor-per-region-G2k65qG3Nc``. The refutation names the filename-resolving target, so it would fail if that specific resolution path began producing a broken-link result.

**Evidence:**

Supplied diff added lines 42–54: the passing v1 note injects `[[one-vendor-per-region-G2k65qG3Nc]]`; added line 54 refutes its exact link-broken fragment.

### Finding 3: C-7
**Severity:** info

Case 3 is pinned at added lines 53 and 55: the passing scope requires `failures: 0` and refutes `link-broken: `was-renamed-away-G2k65qG3Nc``. The injected target is deliberately not the fixture filename but retains its trailing ten-character id, so this assertion specifically covers id-only resolution.

**Evidence:**

Supplied diff added line 42 injects `[[was-renamed-away-G2k65qG3Nc]]`; added line 55 refutes its exact link-broken fragment.

### Finding 4: C-7
**Severity:** info

Case 4 is pinned at added lines 43–50 and 53–61. The v1 body contains the six specified malformed or unregistered forms, requires `failures: 0`, and separately refutes `token-grammar`, `open-question-fields`, `tension-fields`, `contradiction-fields`, `decision-fields`, and `anchor-form`. The individual refutations ensure each body-grammar category remains silent rather than one passing result standing in for all six.

**Evidence:**

Supplied diff added lines 44–50 inject the token, unopened resolution slug, tension, contradiction, decision, and raw anchor; added lines 56–61 refute the six corresponding failure classes.

### Finding 5: C-7
**Severity:** info

The first added EXIT trap is at added line 24. It retains all 16 baseline paths in the stated order and appends only `$v1_broken_scope`; no accumulator defect is present.

**Evidence:**

Supplied diff added line 24 contains `$not_a_scope` through `$v_lintdefect` in baseline order, followed by `$v1_broken_scope`.

### Finding 6: C-7
**Severity:** info

The second added EXIT trap is at added line 39. It retains the same 16 baseline paths in order, carries forward `$v1_broken_scope`, and appends `$v1_pass_scope`; no accumulator defect is present.

**Evidence:**

Supplied diff added line 39 contains every path from the line-24 trap followed by `$v1_pass_scope`.

### Finding 7: C-7
**Severity:** info

A `failures: 0` assertion alone would not distinguish a working v1-link implementation from one that skips v1 notes. The broken-link case supplies the needed distinction by requiring the exact v1 `link-broken` failure. All four cases are pinned despite using two scopes: the passing scope has target-specific filename and id-only refutations plus all six grammar refutations, while the broken scope requires the positive failure. Both added traps preserve the accumulator convention.

**Evidence:**

Supplied diff added lines 31, 53–61 and both EXIT traps at added lines 24 and 39.

## Analysis

This second opinion from the OpenAI vendor via the codex lane confirms the in-family checker's findings. All four required cases are pinned with specific assertions:

- **Case 1 (broken link):** requires exact `link-broken` failure, proving v1 links are checked
- **Case 2 (filename resolution):** refutes filename-specific broken-link string
- **Case 3 (id-only resolution):** refutes id-specific broken-link string
- **Case 4 (body-grammar checks off):** refutes all six grammar categories individually

Both added EXIT traps preserve the accumulator convention, carrying all 16 baseline paths in order and accumulating new scopes correctly.
