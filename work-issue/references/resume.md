# Resume

Read this at Step 0, item 2, before anything else in the run spends a token.

**The world outranks RUN_DIR, and RUN_DIR outranks memory.** git, gh, and herdr are asked first. RUN_DIR answers only what they cannot see — which reports came back, what the reproducer decided, which triage rows were written. Memory answers nothing: the conversation's account of where the run got to is the one source that was not there when the run actually stopped, and a crashed session's last confident sentence is exactly the sentence to distrust.

Every field below is present in the probe JSON, `null` where the probe could not answer. A missing field exits 3 rather than defaulting, because a field silently defaulting to `false` reads as "no branch yet" and sends a run that is three steps in back to Step 0.

## Probes

| Field | Probe |
|---|---|
| `herdr_agent_state` | HERDR: `herdr agent list --json`, reading the `issue-<N>` entry's state — `working`, `blocked`, `idle`, or `done`; no such entry is `absent`. Without herdr: `absent`. |
| `branch_local` | `git show-ref --verify --quiet refs/heads/issue-<N>` |
| `branch_remote` | `git ls-remote --exit-code --heads origin issue-<N>` |
| `run_dir` | `test -d <COMMON>/work-issue/issue-<N>` |
| `pr_state` | `gh pr list --head issue-<N> --state all --json state --jq '.[0].state'`; no pull request is `null` |
| `review_state` | `work-issue/scripts/run-state.py review <PR> --since <SINCE> --author <login>`, first stdout line; no pull request is `null` |
| `has_waves` | `grep -q '^## Waves' <RUN_DIR>/plan.md` |
| `wave_tasks` | rows in that table: `grep -cE '^\| [0-9]+ \|' <RUN_DIR>/plan.md` |
| `wave_reports` | `find <RUN_DIR>/reports -name '[0-9]*-*.json' \| wc -l` — the `<wave>-<task>.json` files only, which is why `build-final.json` and `repair-<k>.json` do not match the glob |
| `self_reviews` | `find <RUN_DIR>/review -name 'self-*.md' \| wc -l` |
| `build_final` | `test -f <RUN_DIR>/reports/build-final.json` |
| `redteam_rounds` | `find <RUN_DIR>/redteam -name 'round-*.json' \| wc -l` |
| `redteam_last_failed` | `grep -q NOT_REPRODUCED "$(ls -t <RUN_DIR>/redteam/round-*.json \| head -1)"` — the newest round only; an earlier round's failures were the reason a later round exists |
| `trigger_fired` | `grep -qi fired <RUN_DIR>/redteam/trigger.txt` |
| `ar_run_dir` | `ls -d <TREE>/.adversarial-review/runs/*-"$(git -C <TREE> rev-parse --short "$(cat <RUN_DIR>/base_sha)")"` — adversarial-review stamps its run directory with the merge-base short SHA, so this matches its run against *this* fixed point rather than any run that ever happened in the tree |
| `conflict` | `test -f <RUN_DIR>/conflict.txt` |
| `rebase_in_progress` | `test -d "$(git -C <TREE> rev-parse --git-path rebase-merge)" \|\| test -d "$(git -C <TREE> rev-parse --git-path rebase-apply)"` — resolved through `--git-path` because in a linked worktree the hardcoded spelling under `.git/` does not exist |
| `ahead_of_origin` | `git rev-list --count origin/issue-<N>..issue-<N>` greater than 0; where `branch_remote` is false and the branch carries commits past BASE_SHA, `true` |
| `triage_rounds` | `find <RUN_DIR>/triage -name 'round-*.md' \| wc -l` |
| `triage_newer_than_since` | the newest `triage/round-*.md` is newer than SINCE: compare its mtime against `<RUN_DIR>/pushed_at`. Older means the rows describe review on a push that has since been replaced. |
| `triage_inscope_rows` | rows marked in scope in the newest `triage/round-*.md` |
| `repair_reports` | `find <RUN_DIR>/reports -name 'repair-*.json' \| wc -l` |
| `triage_rows_unanswered` | triage rows carrying no reply URL, across every round newer than SINCE |

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
| 7 | `## Waves` present; `reports/` lacks a report for some task | Step 2 at that wave (re-record WAVE_BASE; revert a half-written wave with no report) |
| 8 | all wave reports; no `review/self-*.md` | Step 3 at the `code-review` invocation |
| 9 | `review/self-*` present; no `reports/build-final.json` | Step 3 at the fix dispatch |
| 10 | `build-final.json`; no `redteam/round-*.json`, or newest round has NOT_REPRODUCED and no later repair report | Step 4 |
| 11 | red-team clean; `trigger.txt` says fired; no adversarial-review run dir in the tree | Step 4 at the adversarial-review invocation |
| 12 | `conflict.txt` exists, or a rebase in progress | Step 5 item 1 |
| 13 | red-team clean; no PR, or local HEAD ahead of `origin/issue-N` | Step 5 |
| 14 | PR open; review `pending` | Step 6 poll |
| 15 | PR open; `findings`; no `triage/round-<k>.md` newer than SINCE | Step 6 triage |
| 16 | triage round with in-scope rows; no matching `reports/repair-<k>.json` | Step 7 |
| 17 | repair report, or a triage round with no in-scope rows; local ahead of origin, or a triage row without a reply URL | Step 8 |
| 18 | PR open; `cleared` | done: final report |

Row order is the mechanism, not a convenience. Rows 1 through 3 read the world and outrank every RUN_DIR row below them: a pull request somebody closed while the session was away ends the run no matter how much unfinished state is on disk, and an agent still `working` is waited on rather than duplicated by a second dispatch into the same tree.

Rows 4 and 5 are the two shapes of "nothing to resume", and they differ in what they leave behind. No branch and no RUN_DIR is a fresh issue. A RUN_DIR with no branch anywhere is the wreckage of a run whose branch was deleted — it moves to `closed/` first, because leaving it in place makes the next invocation resume into a tree that no longer has the commits its reports describe.

Row 7 reverts before it re-dispatches. A wave that wrote files and returned no report left work nobody gated, and handing that to a second worker gives it the first one's leftovers to debug on the plan's budget.

Rows 15 and 17 both turn on SINCE. Review signal older than the last push describes code that is no longer there, and triage rows written against it are answers to a question nobody is still asking.
