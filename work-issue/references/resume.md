# Resume

Read this at Step 0, item 1, before anything else in the run spends a token or writes under RUN_DIR. Row 5 reads a run dir with no branch as a dead run, so a probe taken after `issue.md` is written would archive the issue it just read.

**The world outranks RUN_DIR, and RUN_DIR outranks memory.** git, gh, and herdr are asked first. RUN_DIR answers only what they cannot see — which reports came back, what the reproducer decided, which triage rows were written. Memory answers nothing: the conversation's account of where the run got to is the one source that was not there when the run actually stopped, and a crashed session's last confident sentence is exactly the sentence to distrust.

Every field below is present in the probe JSON, `null` where the probe could not answer. A missing field exits 3 rather than defaulting, because a field silently defaulting to `false` reads as "no branch yet" and sends a run that is three steps in back to Step 0. A `null` is treated the same way for every field but `pr_state` and `review_state`, where null means no pull request yet: the script answers `stop` naming the field, because a null read as "no" is the same wrong answer arriving through the front door. Row 1 is checked first, since a merged or closed pull request ends the run whatever else the probe could not see.

## Probes

| Field | Probe |
|---|---|
| `herdr_agent_state` | HERDR: `herdr agent list --json`, reading the `issue-<N>` entry's state — `working`, `blocked`, `idle`, or `done`; no such entry is `absent`. Without herdr: `absent`. |
| `branch_local` | `git show-ref --verify --quiet refs/heads/issue-<N>` |
| `branch_remote` | `git ls-remote --exit-code --heads origin issue-<N>` |
| `run_dir` | `test -d <COMMON>/work-issue/issue-<N>` |
| `base_sha` | `test -f <RUN_DIR>/base_sha`. Step 1's last writes, with `baseline`; row 7 sends a run missing either back to Step 1 rather than dispatching workers against no fixed point |
| `baseline` | `test -f <RUN_DIR>/baseline.txt` |
| `pr_state` | `gh pr list --head issue-<N> --state all --json state --jq '.[0].state'`; no pull request is `null` |
| `review_state` | `work-issue/scripts/run-state.py review <PR> --since <SINCE> --author <login>`, first stdout line; no pull request is `null` |
| `has_waves` | `grep -q '^## Waves' <RUN_DIR>/plan.md` |
| `wave_tasks` | rows in that table and no other: `awk '/^## Waves/{f=1;next} f&&/^[[:space:]]*\|/{t=1;print;next} f&&t{exit}' <RUN_DIR>/plan.md \| grep -cE '^\s*\|\s*[0-9]+\s*\|'`. The table ends at the first non-table line after it starts, which is where the vendored parser ends it; a cut that ran to the next `## ` heading still counted a numbered row under a `### ` heading inside the section. Whitespace-tolerant inside the row because the parser accepts a compact row such as `|0|one|a.py|sonnet|done||`, and ahead of it because the parser strips leading whitespace, so an indented table is a valid table |
| `wave_reports` | `find <RUN_DIR>/reports -name '[0-9]*-*.json' \| wc -l` — the `<wave>-<task>.json` files only, which is why `build-final.json` and `repair-<k>.json` do not match the glob |
| `self_reviews` | `find <RUN_DIR>/review -name 'self-*.md' \| wc -l` |
| `build_final` | `test -f <RUN_DIR>/reports/build-final.json` |
| `redteam_rounds` | `find <RUN_DIR>/redteam -name 'round-*.json' \| wc -l` |
| `redteam_failed_twice` | the two newest `round-*.json` both match the `redteam_last_failed` grep: `ls -t <RUN_DIR>/redteam/round-*.json \| head -2 \| xargs -I{} grep -lE 'NOT_REPRODUCED\|"holds": *false' {} \| wc -l` is 2. Step 4 stops after two failed rounds, and row 10 has to honor that stop rather than start a third cycle |
| `repair_after_last_round` | the newest `reports/repair-*.json` is newer than the newest `redteam/round-*.json`: `case "$(ls -t <RUN_DIR>/reports/repair-*.json <RUN_DIR>/redteam/round-*.json 2>/dev/null \| head -1)" in */reports/repair-*) echo true;; *) echo false;; esac`. Order, not count: a repair report older than the failed round is the code that round refuted, and re-running the round over it re-tests unchanged code |
| `redteam_last_failed` | `grep -qE 'NOT_REPRODUCED\|"holds": *false' "$(ls -t <RUN_DIR>/redteam/round-*.json \| head -1)"` — the newest round only; an earlier round's failures were the reason a later round exists. A `left_checks` entry with `holds` false routes like a `NOT_REPRODUCED` claim (see `references/redteam.md`), so the probe reads both |
| `trigger_fired` | `yes`, `no`, or `absent`: `case "$(head -1 <RUN_DIR>/redteam/trigger.txt 2>/dev/null)" in 'fired: yes') echo yes;; 'fired: no') echo no;; *) echo absent;; esac`. Three values, because a missing file is not a `no`: a run that stopped between its clean round file and the trigger has not evaluated the trigger at all, and row 13 must not publish it |
| `ar_complete` | `grep -q 'UNVERIFIED: 0' <RUN_DIR>/redteam/ar-state.txt`. Step 4 writes that file from `ledger.py state` after it has read the report, so it exists only for a review that finished. The run directory under `<TREE>/.adversarial-review/runs/` is not the signal: it exists from adversarial-review's preflight onward, and a review interrupted after preflight leaves one behind with nothing in it |
| `conflict` | `test -f <RUN_DIR>/conflict.txt`. Step 5 item 2 removes the file once the rebase is proven, so a marker with no rebase in progress is a run that stopped between items 1 and 2, and row 12 sends it back to item 1, where the rebase is a no-op and item 2 clears it |
| `rebase_in_progress` | `test -d "$(git -C <TREE> rev-parse --git-path rebase-merge)" \|\| test -d "$(git -C <TREE> rev-parse --git-path rebase-apply)"` — resolved through `--git-path` because in a linked worktree the hardcoded spelling under `.git/` does not exist |
| `ahead_of_origin` | `git rev-list --count origin/issue-<N>..issue-<N>` greater than 0; where `branch_remote` is false and the branch carries commits past BASE_SHA, `true` |
| `triage_rounds` | `find <RUN_DIR>/triage -name 'round-*.md' \| wc -l` |
| `triage_newer_than_since` | the newest `triage/round-*.md` is newer than SINCE: compare its mtime against `<RUN_DIR>/pushed_at`. Older means the rows describe review on a push that has since been replaced. |
| `triage_inscope_rows` | rows marked in scope in the newest `triage/round-*.md` |
| `repair_reports` | `find <RUN_DIR>/reports -name 'repair-*.json' \| wc -l` |
| `newest_repair_report` | `test -f <RUN_DIR>/reports/repair-<k>.json` for the newest `triage/round-<k>.md`. Row 16 reads this rather than comparing counts, because an all-queued round writes no repair report and the counts drift apart |
| `triage_rows_unanswered` | triage rows carrying no reply URL, across every round. Not cut off at SINCE: Step 8 pushes before it replies, so the rows it owes are always older than the push that answered them |

Write them to a JSON file and map them:

```
work-issue/scripts/run-state.py phase --probe PROBE.json
```

It prints `phase: <0-8|done|wait|stop> reason: <one line>` and exits 0, or exits 3 on a malformed probe.

## The phase table

The same eighteen rows the script implements, written out so a reader can fail one against the other. Where they disagree, the script is what ran and this table is what somebody believed — check the diff that moved them apart. First match wins.

| # | Probe | Resume at |
|---|---|---|
| 1 | PR state MERGED or CLOSED | done; offer cleanup (worktree remove, RUN_DIR → `closed/`), ask before removing |
| 2 | HERDR and agent `working` | wait, re-probe |
| 3 | HERDR and agent `blocked` | show the blocked UI, stop |
| 4 | no `issue-N` branch locally or on origin, no RUN_DIR | Step 0 |
| 5 | RUN_DIR exists, no branch anywhere | RUN_DIR → `closed/`, Step 0 |
| 6 | branch exists; `plan.md` has no `## Waves` | Step 0 at the plan gate |
| 7 | `## Waves` present; no `base_sha` or no `baseline.txt`, or `reports/` lacks a report for some task | Step 1 at the missing artifact; else Step 2 at that wave (re-record WAVE_BASE; revert a half-written wave with no report) |
| 8 | all wave reports; no `review/self-*.md` | Step 3 at the `code-review` invocation |
| 9 | `review/self-*` present; no `reports/build-final.json` | Step 3 at the fix dispatch |
| 10 | `build-final.json`; no `redteam/round-*.json`, or newest round has NOT_REPRODUCED | Step 4: the repair dispatch, or round k+1 where a repair report followed the failed round; two failed rounds in a row stop with the evidence |
| 11 | red-team clean; `trigger.txt` absent, or its first line `fired: yes` with no `redteam/ar-state.txt` showing `UNVERIFIED: 0` | Step 4 at the trigger, or at the adversarial-review invocation |
| 12 | `conflict.txt` exists, or a rebase in progress | Step 5 item 1 |
| 13 | red-team clean; trigger recorded; no triage round yet; no PR, or local HEAD ahead of `origin/issue-N` | Step 5 |
| 14 | PR open; review `pending`; no triage row without a reply URL | Step 6 poll |
| 15 | PR open; `findings`; no `triage/round-<k>.md` newer than SINCE | Step 6 triage |
| 16 | newest triage round has in-scope rows; no `reports/repair-<k>.json` for that round | Step 7 |
| 17 | PR open; repair report, or a triage round with no in-scope rows; local ahead of origin, or a triage row without a reply URL | Step 8 |
| 18 | PR open; `cleared` | done: final report |

Row order is the mechanism, not a convenience. Rows 1 through 3 read the world and outrank every RUN_DIR row below them: a pull request somebody closed while the session was away ends the run no matter how much unfinished state is on disk, and an agent still `working` is waited on rather than duplicated by a second dispatch into the same tree.

Rows 4 and 5 are the two shapes of "nothing to resume", and they differ in what they leave behind. No branch and no RUN_DIR is a fresh issue. A RUN_DIR with no branch anywhere is the wreckage of a run whose branch was deleted — it moves to `closed/` first, because leaving it in place makes the next invocation resume into a tree that no longer has the commits its reports describe.

Row 7 reverts before it re-dispatches. A wave that wrote files and returned no report left work nobody gated, and handing that to a second worker gives it the first one's leftovers to debug on the plan's budget.

Row 15 turns on SINCE: review signal older than the last push describes code that is no longer there, and a triage round written against it is an answer to a question nobody is still asking. Row 17's unanswered leg deliberately does not. Step 8 pushes and writes `pushed_at` before it replies, so a stop between the two leaves rows older than SINCE that still owe a reply, and a cutoff there would hand them to row 14's poll for good. Row 14 carries the matching guard.
