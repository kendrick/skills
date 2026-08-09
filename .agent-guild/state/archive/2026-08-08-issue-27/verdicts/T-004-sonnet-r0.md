---
task: T-004
checker: checker-judgment
vendor: anthropic
model: claude-opus-5[1m]
verdict: PASS
checked_at: 2026-08-08T00:00:00Z
duration_ms: None
cost_usd: None
---

<!-- GENERATED FILE—do not hand-edit. Rendered by render-verdict.py
from the verdict JSON, the record of record. Edit the JSON and
re-render instead. -->

## Per-clause results

| clause | severity | description | evidence |
| ------ | -------- | ------------ | -------- |
| C-13 | blocker | Part 1 of C-13's check: the suite exits 0 on the shipped tree, both before and after the saboteur run. | $ bash tests/inbox-to-memory-smoke.sh inbox-to-memory smoke: ok suite exit=0 (re-run after saboteur restore: "inbox-to-memory smoke: ok", post-restore suite exit=0) |
| C-13 | blocker | Part 2, the placement block run verbatim: the banner, the stamper binding, and all five invocations sit between the guard's snapshot and its comparison, and none of $ban, $bind, or $first is empty. | $ <C-13 placement block, verbatim> snap=587 banner=1298 bind=1307 first-use=1320 last-use=1408 cmp=1425 inside the guard --- use count: 5 All three variables non-empty; the invocation set holds 5 lines (1320, 1345, 1360, 1384, 1408), not just the binding. The suite is 1435 lines, so the section is not appended past the comparison at :1425. |
| C-13 | blocker | Part 3, judgment on the section: every assertion runs against a real `bash "$stamper"` invocation rather than a require_text against SKILL.md, each of the five cases builds its own scope under mktemp -d and registers it in the cumulative EXIT trap, and the five minimum cases the clause names are all present and asserted. | tests/inbox-to-memory-smoke.sh:1297-1428. Five cases, each `mktemp -d` + `trap 'rm -rf ...' EXIT` + `cp -R "$fixtures/mixed/."`: headline :1314-1334, backward/equal :1339-1351, cross-group dedupe :1357-1369, status gate :1373-1389, key insertion :1394-1419. Headline asserts the v1 hold by bytes, not output text — :1319 `wt_v1_before="$(shasum "$wt_v1" \| cut -d' ' -f1)"` and :1324 `[[ "$wt_v1_before" == "$(shasum "$wt_v1" \| cut -d' ' -f1)" ]] \|\| { echo "the v1 record was written by a run that also stamped a v2 record" >&2; exit 1; }`. Backward/equal loops both notes at :1344-1347 and shasum-compares at :1348. Dedupe asserts one output line at :1363 (`grep -c 'atlas-region-topology'` == 1) plus `stamped: 1 skipped: 0`. Status gate mutates to `status: proposed` at :1377-1382 (reads then writes, no truncation) and shasum-compares at :1386. Key insertion strips the key at :1398-1403, runs the stamper at :1408, then pins contract position at :1413 (`lc == date+1 && lc == source_refs-1`) and `require_line "$wt_keyins_lint" "failures: 0"` at :1419. `grep -n 'stamp-confirmed\\\|\\$stamper'` over the whole suite returns the C-17 wiring `require_text` at :301 (outside the section, deliberately) and nothing else outside 1297-1428. The guard comment is reworded: :1421-1424 reads "Every migration or write-through test works on a copy" and the failure message at :1426 is "a migration or stamping test wrote to a checked-in fixture". |
| C-13 | blocker | Part 4, the saboteur run verbatim: the suite goes red, and it goes red on the v1 byte assertion specifically; the stamper is restored (shasum-verified against two independent backups) and tests/fixtures/ carries no damage. | $ <C-13 saboteur block, verbatim> sabotaged exit=1 restored ?? tests/fixtures/inbox-to-memory/evals/confirmation-writethrough/ fixture damage above, if any === sabotaged output tail === the v1 record was written by a run that also stamped a v2 record The red came from tests/inbox-to-memory-smoke.sh:1325, the headline's shasum comparison, not from an output-format wobble. Restore confirmed two ways: the clause's own shasum compare printed `restored`, and an independent pre-run copy diffs clean — `diff scratchpad/stamper.backup.sh inbox-to-memory/scripts/stamp-confirmed.sh` -> "Files are identical", shasum add540132db4f4af61c449689669969f4930b48e both before and after. The single `??` line is the untracked eval fixture directory from a sibling task; I recorded `git status --porcelain tests/fixtures/` before installing the saboteur and it was already the only entry, so the sabotaged run added no modified or new paths under tests/fixtures/. |
