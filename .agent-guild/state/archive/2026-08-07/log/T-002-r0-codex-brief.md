# Second-opinion brief: T-002 (kendrick/skills#28)

You are `checker-courier` relaying a task check for a second opinion. Judge ONLY the material inlined below. You cannot read any repository or run any command; every command has already been run and its real output is in the evidence section.

## What was built

A markdown-notes linter enforces a 20-line frontmatter budget. A record carrying both `tags` and `themes` runs to 21 lines, so it used to fail `frontmatter-budget` — naming the symptom, not the cause. A companion task added a `frontmatter-key-domain` check that fires on co-presence and sits ahead of the budget guard.

THIS task is the documentation half: make the contract stop lying about the budget's headroom, register the new check, and write the commit message.

## Clauses to judge

- **C-4**: `machine-contracts.md:29` must no longer claim both key orders "fit inside the budget with room left over," nor that an overrun "is almost always accumulated commented-out keys rather than real content." Both were false. The replacement must state the real headroom, and its numbers must match what the key orders actually produce. A sentence that reads well and states a wrong number FAILS — a wrong number in that sentence is the entire bug being fixed. The evidence section gives you the recount.
- **C-5**: the new table row's "Fails when" description must match what the shipped check does. Note the worker moved the check's precedence fact out of the table cell to a sentence below the table, because 150 characters in a 69-character column broke the row's shape and every sibling cell states a single trigger condition. Judge whether the row still satisfies the clause.
- **C-7**: no assertion removed or loosened. Two lines DO appear "lost" in the comparison — the broken-scope count literals, updated in place from 18→19 and 19→20 because a companion task added a fixture. Judge whether an updated count literal at the same call site is a removal or an update. Note the clause's own failing example names the opposite case ("deleted rather than updated when the new fixture changes the count") as the defect.
- **C-8**: the diff touches only `inbox-to-memory/` and `tests/`.
- **C-9**: the rewritten sentence, the table row, and the commit message read as though a person wrote them. Judge against common AI-writing tells: rule-of-three padding, promotional framing, bolded inline headers with colons, vague significance claims, prose restating what the numbers already say. House overrides you must respect: title-case headings are CORRECT here and are not findings; unspaced em dashes are CORRECT and are not findings; SPACED em dashes are a finding.

## Verdict you must produce

Emit ONLY a JSON object with exactly these nine fields:
- "task_id": "T-002"
- "checker": "checker-courier"
- "vendor": "openai"
- "model": "gpt-5.6-terra"
- "verdict": "pass" | "fail" | "blocked"
- "summary": one paragraph
- "findings": array of {"clause_id", "severity", "description", "evidence"} — REQUIRED non-empty if verdict is "fail"; evidence must cite the inlined material. May be empty on "pass".
- "duration_ms": null
- "cost_usd": null

---

## The diff under check

```diff
diff --git a/inbox-to-memory/references/machine-contracts.md b/inbox-to-memory/references/machine-contracts.md
index 687912f..e9edb7e 100644
--- a/inbox-to-memory/references/machine-contracts.md
+++ b/inbox-to-memory/references/machine-contracts.md
@@ -26,7 +26,7 @@ Links and derived counts are checked in all three of the rows the lint touches.
 
 The reason is grep, not taste. `grep '^tags:'` returns the whole value or it returns nothing, and a diff of a changed tag is one line rather than a moved block.
 
-**The block fits in the first 20 lines of the file.** This is the number that makes a header read a contract: an agent reading 20 lines is guaranteed to have the entire frontmatter, so stage three of the funnel can stop there without ever wondering whether it truncated something. Both key orders below fit inside the budget with room left over, which means overrunning it is almost always accumulated commented-out keys rather than real content.
+**The block fits in the first 20 lines of the file.** This is the number that makes a header read a contract: an agent reading 20 lines is guaranteed to have the entire frontmatter, so stage three of the funnel can stop there without ever wondering whether it truncated something. The note order's 17 keys close on line 19, one line to spare. The record order lists 19 names and would close on line 21, but `tags` and `themes` are mutually exclusive, so a record carries at most 18 and closes on exactly line 20, with no margin at all. One commented-out key puts a full record over. Adding a name to the record order means dropping one.
 
 **Fixed key order.** Omit any key you don't need; the order is fixed among the keys that are present. Two orders, one for notes and one for records.
 
@@ -149,7 +149,10 @@ Each failure names the file and the check that caught it, so a defect whose caus
 | `frontmatter-single-line`   | A line is neither a comment nor a `key: value` pair at column zero.  |
 | `frontmatter-known-keys`    | A key appears that neither order lists.                              |
 | `frontmatter-key-order`     | Present keys are not in contract order.                              |
+| `frontmatter-key-domain`    | The block carries both `tags` and `themes`.                          |
 | `token-grammar`             | A bracketed token in the body is absent from the grammar table.      |
 | `contradiction-fields`      | A contradiction names no record, or never states what that record claims. |
 
+`frontmatter-key-domain` is checked ahead of the budget on purpose. A record carrying both keys plus most of the order runs past line 20, and the budget failure would report that overrun without ever naming the mixup underneath it.
+
 Token scanning stops at `## Raw Content`. Raw content is a verbatim capture of someone else's writing, and whatever brackets it happens to contain are not this skill's tokens.
```

---

## Evidence collected locally (verbatim command output)

== C-8 verbatim ==
OK: 4 path(s) in scope
exit=0

== C-7 assertion sets vs d4ce6d2 ==
inbox-to-memory-smoke.sh: lost=2 gained=8
file-issue-smoke.sh: lost=0 gained=0
handoff-smoke.sh: lost=0 gained=0
-- the two lost lines and their in-place successors:
require_line "$broken_out" "failures: 18" broken
require_line "$broken_out" "v2 files: 19" broken
159:require_line "$broken_out" "v2 files: 20" broken
160:require_line "$broken_out" "failures: 19" broken

== three suites ==
inbox-to-memory-smoke.sh exit=0
file-issue-smoke.sh exit=0
handoff-smoke.sh exit=0

== C-4: key orders recounted at check time ==
NOTE=17 -> closes 19; RECORD=19 -> closes 21; record at 18 keys -> closes 20
-- the false claims, gone?
0
0
(0 and 0 expected)

== the rewritten headroom passage ==
**The block fits in the first 20 lines of the file.** This is the number that makes a header read a contract: an agent reading 20 lines is guaranteed to have the entire frontmatter, so stage three of the funnel can stop there without ever wondering whether it truncated something. The note order's 17 keys close on line 19, one line to spare. The record order lists 19 names and would close on line 21, but `tags` and `themes` are mutually exclusive, so a record carries at most 18 and closes on exactly line 20, with no margin at all. One commented-out key puts a full record over. Adding a name to the record order means dropping one.

== the new table row and the precedence sentence ==
| --------------------------- | ------------------------------------------------------------------- |
| `frontmatter-fences`        | The file doesn't open with `---` or the block is never closed.       |
| `frontmatter-parses`        | `yq` can't parse the block.                                          |
| `frontmatter-budget`        | The closing `---` lands past line 20.                                |
| `frontmatter-single-line`   | A line is neither a comment nor a `key: value` pair at column zero.  |
| `frontmatter-known-keys`    | A key appears that neither order lists.                              |
| `frontmatter-key-order`     | Present keys are not in contract order.                              |
| `frontmatter-key-domain`    | The block carries both `tags` and `themes`.                          |
| `token-grammar`             | A bracketed token in the body is absent from the grammar table.      |
| `contradiction-fields`      | A contradiction names no record, or never states what that record claims. |

`frontmatter-key-domain` is checked ahead of the budget on purpose. A record carrying both keys plus most of the order runs past line 20, and the budget failure would report that overrun without ever naming the mixup underneath it.


== the suite pin ==
require_text "$contracts" "frontmatter-key-domain"

== the drafted commit message ==
Name the tags/themes mixup instead of its symptom

A record carrying every key in its order, `tags` and `themes` included, closes its frontmatter on line 21. The lint reported `frontmatter-budget`, so whoever read it went looking for a key to delete. The overrun is the symptom; the cause is a journal entry's key sitting on a record, and nothing in the output said so.

`frontmatter-key-domain` fires on the co-presence of both keys and names both in the message. It sits ahead of the budget guard because `check_frontmatter` returns at the first failure it hits, and every file this check exists for is 21 lines—behind the guard it would never run at all.

The contract fed the confusion. It claimed both key orders fit the budget with room to spare, so an overrun read as accumulated commented-out keys rather than real content. The note order does have a spare line. The record order has none: with `tags` and `themes` mutually exclusive it tops out at 18 keys and closes on exactly line 20.

The check fires on co-presence only. A record carrying `tags` alone and a journal entry carrying `themes` alone both stay legal, since rejecting `themes` on a non-journal record goes past what the issue asked for.

Closes #28
