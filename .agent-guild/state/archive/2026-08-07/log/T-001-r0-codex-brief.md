# Second-opinion brief: T-001 (kendrick/skills#28)

You are `checker-courier` relaying a task check for a second opinion. Judge ONLY the material inlined below. You cannot read any repository or run any command. Judge script-based checks against the "Evidence collected locally" section — every command has already been run and its real output is inlined.

## What was built

A markdown-notes linter enforces a 20-line budget on YAML frontmatter. Two key orders exist: a file carrying `memory_type` is checked against the record order, everything else against the note order. Journal entries carry `memory_type: Journal`, which is why one order holds both `tags` and `themes`.

The bug: a record carrying BOTH `tags` and `themes` is 21 lines, so it failed the budget check — and that check `return`s early, so the real defect was never named and was unreachable. Someone reading `frontmatter-budget` would delete a comment to get under the limit and never learn the file confused a journal entry with a record.

This task adds a `frontmatter-key-domain` check that fires on co-presence of both keys, sited ahead of the budget guard so it is reachable on the 21-line files the bug is about.

## Clauses to judge

- **C-1**: a file carrying both keys fails `frontmatter-key-domain`, the message names the file and both keys, and `frontmatter-budget` is NOT reported for that file.
- **C-2**: the check is reachable on a block that overruns the budget and takes precedence there. This is the clause that separates a real fix from a check that ships correct but unreachable.
- **C-3**: a journal entry with `themes` and no `tags` still lints clean, and a record with `tags` and no `themes` still lints clean. Neither assertion may rest on a v1 file (no `schema` key), which the linter skips entirely and which therefore proves nothing.
- **C-6**: the new `broken/` fixture carries the mixup and no other defect, matching that directory's one-defect-per-file convention. Note the trap: the new check `return`s before the key-order check runs, so a fixture with a second problem still reports exactly one failure and looks clean.
- **C-7**: no `require_*`/`refute_*` assertion removed or loosened. The suite is this job's own deliverable, so a green suite proves nothing on its own — the assertion-set comparison in the evidence is the real check. Note two lines appear "lost": judge whether an updated count literal at the same call site is a removal or an update.
- **C-8**: the diff touches only `inbox-to-memory/` and `tests/`.
- **C-9**: the failure message and any added or rewritten comment read as though a person wrote them. Title-case headings and unspaced em dashes are fine; spaced em dashes, rule-of-three padding, promotional framing, and comments restating the next line are findings.

## Verdict you must produce

Emit ONLY a JSON object with exactly these nine fields:
- "task_id": "T-001"
- "checker": "checker-courier"
- "vendor": "openai"
- "model": "gpt-5.6-terra"
- "verdict": "pass" | "fail" | "blocked"
- "summary": one paragraph
- "findings": array of {"clause_id", "severity", "description", "evidence"} — REQUIRED non-empty if verdict is "fail"; each finding's evidence must cite the inlined material. May be empty on "pass".
- "duration_ms": null
- "cost_usd": null

---

## The diff under check (git diff d4ce6d2, plus the new untracked fixture)

```diff
diff --git a/inbox-to-memory/scripts/lint-scope.sh b/inbox-to-memory/scripts/lint-scope.sh
index c7a3ed2..a2dda0e 100755
--- a/inbox-to-memory/scripts/lint-scope.sh
+++ b/inbox-to-memory/scripts/lint-scope.sh
@@ -153,14 +153,25 @@ check_frontmatter() {
     return
   fi
 
+  local block
+  block="$(sed -n "2,$((end - 1))p" "$file")"
+
+  # Ahead of the budget guard on purpose: every file this check exists for is
+  # 21 lines and hits that guard's `return` first if the check runs after it,
+  # which is exactly the bug this check exists to fix.
+  local tags_lines themes_lines
+  tags_lines="$(printf '%s\n' "$block" | grep -cE '^tags:' || true)"
+  themes_lines="$(printf '%s\n' "$block" | grep -cE '^themes:' || true)"
+  if [[ "$tags_lines" -gt 0 && "$themes_lines" -gt 0 ]]; then
+    fail frontmatter-key-domain "carries both \`tags\` and \`themes\`, a record's key and a journal entry's"
+    return
+  fi
+
   if [[ "$end" -gt "$FRONTMATTER_LINE_BUDGET" ]]; then
     fail frontmatter-budget "closing --- on line $end, past the $FRONTMATTER_LINE_BUDGET-line budget"
     return
   fi
 
-  local block
-  block="$(sed -n "2,$((end - 1))p" "$file")"
-
   if ! printf '%s\n' "$block" | yq '.' >/dev/null 2>&1; then
     fail frontmatter-parses "yq could not parse the block"
     return
diff --git a/tests/inbox-to-memory-smoke.sh b/tests/inbox-to-memory-smoke.sh
index 892c957..e7aa6f9 100755
--- a/tests/inbox-to-memory-smoke.sh
+++ b/tests/inbox-to-memory-smoke.sh
@@ -150,13 +150,14 @@ done
 
 # One defect per file, so a count is a meaningful assertion and a check that
 # starts firing twice shows up as an arithmetic failure rather than a wash. The
-# arithmetic is off by one because a contradiction has to point at something
-# accepted: the lone record in this scope is link bait, carries no defect, and is
-# the reason failures trail the file count.
+# arithmetic still lands one short of the file count: vendor-lock-window is
+# link bait for the contradiction check and stays clean; every other v2 file
+# here, including the new tags/themes record, carries exactly one planted
+# defect.
 broken_out="$(run_lint "$fixtures/broken")"
 require_line "$broken_out" "v1 files: 0" broken
-require_line "$broken_out" "v2 files: 19" broken
-require_line "$broken_out" "failures: 18" broken
+require_line "$broken_out" "v2 files: 20" broken
+require_line "$broken_out" "failures: 19" broken
 
 if bash "$lint" "$fixtures/broken" >/dev/null 2>&1; then
   echo "lint exited zero on the broken fixture" >&2
@@ -180,11 +181,53 @@ require_failure "$broken_out" "FAIL $fixtures/broken/notes/2026-03-14-bare-line-
 require_failure "$broken_out" "FAIL $fixtures/broken/notes/2026-03-15-multiline-summary-gcnwRBmRy_.md: frontmatter-single-line:"
 require_failure "$broken_out" "FAIL $fixtures/broken/notes/2026-03-16-decision-bad-reversibility-w-6dqoA-ky.md: decision-fields:"
 require_failure "$broken_out" "FAIL $fixtures/broken/notes/2026-03-18-contradiction-no-claims-19UymDD7Rt.md: contradiction-fields:"
+require_failure "$broken_out" "FAIL $fixtures/broken/_memory/decisions/tags-themes-mixup-9YpQ2xLmZk.md: frontmatter-key-domain:"
 
 # The record the flag points at is clean. Asserting that here is what keeps the
-# link bait from quietly becoming an eighteenth defect nobody planted.
+# link bait from quietly becoming a twentieth defect nobody planted.
 refute_failure "$broken_out" "vendor-lock-window-WJicoHVdFw.md"
 
+# The file that motivated this check: every RECORD_KEY_ORDER key populated,
+# tags and themes both included, with the block closing on line 21, one line
+# past the budget. check_frontmatter returns at the first fail() it hits, so
+# the mixup has to win that race, or the 21-line record this check exists for
+# keeps reporting frontmatter-budget instead.
+overrun_scope="$(mktemp -d "${TMPDIR:-/tmp}/i2m-overrun.XXXXXX")"
+trap 'rm -rf "$overrun_scope"' EXIT
+mkdir -p "$overrun_scope/_inbox" "$overrun_scope/_memory/decisions"
+overrun_file="$overrun_scope/_memory/decisions/tags-and-themes-both-populated-Kx3fQ7pRtN.md"
+cat >"$overrun_file" <<'EOF'
+---
+schema: 2
+body_schema: 1
+id: Kx3fQ7pRtN
+memory_type: Decision
+title: 'A record with every RECORD_KEY_ORDER key populated'
+status: accepted
+date: 2026-02-22
+effective_from: 2026-02-22
+effective_to: null
+last_confirmed: 2026-02-22
+source_refs: [oKZJNnBgR5]
+applies_to: [vendor-selection]
+owners: [Marcus Dell]
+tags: [vendor]
+themes: [vendor-strategy]
+related: []
+exception_to: null
+supersedes: null
+superseded_by: null
+---
+
+Body content is irrelevant here; this file's frontmatter is the reproduction from the issue.
+EOF
+
+overrun_out="$(run_lint "$overrun_scope")"
+require_line "$overrun_out" "v2 files: 1" overrun-record
+require_line "$overrun_out" "failures: 1" overrun-record
+require_failure "$overrun_out" "FAIL $overrun_file: frontmatter-key-domain: carries both \`tags\` and \`themes\`"
+refute_failure "$overrun_out" "frontmatter-budget"
+
 # V1 notes anchor to bare line numbers everywhere, and that has to stay legal. The
 # check keys off the schema, never off the shape of the reference.
 refute_failure "$old_only_out" "anchor-form"
```

## The new fixture (untracked, so absent from the diff above)

```markdown
---
schema: 2
id: 9YpQ2xLmZk
memory_type: Decision
title: 'Planted defect: a record carrying both tags and themes'
status: accepted
date: 2026-02-21
last_confirmed: 2026-02-21
tags: [vendor]
themes: [vendor-strategy]
---

# Planted defect: a record carrying both tags and themes

## Decision

This fixture exists to trip frontmatter-key-domain. Nothing below the fence is load-bearing.

## Alternatives Discarded

None; this file plants one defect and nothing else.
```

---

## Evidence collected locally (verbatim command output)

== C-8 deterministic check, verbatim ==
OK: 3 path(s) in scope
exit=0

== C-7: assertion-set comparison vs d4ce6d2 ==
inbox-to-memory-smoke.sh: lost=2 base=201 now=206
file-issue-smoke.sh: lost=0 base=41 now=41
handoff-smoke.sh: lost=0 base=28 now=28
-- the two 'lost' lines in the migration suite (updated in place, not deleted):
require_line "$broken_out" "failures: 18" broken
require_line "$broken_out" "v2 files: 19" broken

== three suites ==
inbox-to-memory-smoke.sh exit=0
file-issue-smoke.sh exit=0
handoff-smoke.sh exit=0

== C-1: the issue's reproduction against the shipped lint ==
/var/folders/2b/m3q305ss1tb55qfhrv6v0n3m0000gn/T/tmp.mLW37NdzKT/_inbox
/var/folders/2b/m3q305ss1tb55qfhrv6v0n3m0000gn/T/tmp.mLW37NdzKT/_memory
/var/folders/2b/m3q305ss1tb55qfhrv6v0n3m0000gn/T/tmp.mLW37NdzKT/_memory/decisions
FAIL /var/folders/2b/m3q305ss1tb55qfhrv6v0n3m0000gn/T/tmp.mLW37NdzKT/_memory/decisions/r.md: frontmatter-key-domain: carries both `tags` and `themes`, a record's key and a journal entry's
failures: 1

== the shipped check ==
  local block
  block="$(sed -n "2,$((end - 1))p" "$file")"

  # Ahead of the budget guard on purpose: every file this check exists for is
  # 21 lines and hits that guard's `return` first if the check runs after it,
  # which is exactly the bug this check exists to fix.
  local tags_lines themes_lines
  tags_lines="$(printf '%s\n' "$block" | grep -cE '^tags:' || true)"
  themes_lines="$(printf '%s\n' "$block" | grep -cE '^themes:' || true)"
  if [[ "$tags_lines" -gt 0 && "$themes_lines" -gt 0 ]]; then
    fail frontmatter-key-domain "carries both \`tags\` and \`themes\`, a record's key and a journal entry's"
    return
  fi

  if [[ "$end" -gt "$FRONTMATTER_LINE_BUDGET" ]]; then

== the new fixture ==
---
schema: 2
id: 9YpQ2xLmZk
memory_type: Decision
title: 'Planted defect: a record carrying both tags and themes'
status: accepted
date: 2026-02-21
last_confirmed: 2026-02-21
tags: [vendor]
themes: [vendor-strategy]
---

# Planted defect: a record carrying both tags and themes

## Decision

This fixture exists to trip frontmatter-key-domain. Nothing below the fence is load-bearing.

## Alternatives Discarded

None; this file plants one defect and nothing else.

== broken-scope counts + rewritten comment ==
  refute_failure "$mixed_out" "$legacy"
done

# One defect per file, so a count is a meaningful assertion and a check that
# starts firing twice shows up as an arithmetic failure rather than a wash. The
# arithmetic still lands one short of the file count: vendor-lock-window is
# link bait for the contradiction check and stays clean; every other v2 file
# here, including the new tags/themes record, carries exactly one planted
# defect.
broken_out="$(run_lint "$fixtures/broken")"
require_line "$broken_out" "v1 files: 0" broken
require_line "$broken_out" "v2 files: 20" broken
require_line "$broken_out" "failures: 19" broken
