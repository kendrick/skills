---
name: work-issue
description: "Advance one GitHub issue from its approved plan to a pull request whose review threads are answered, resuming from wherever a previous invocation left it. Use ONLY when the user explicitly invokes work-issue. It never plans an issue and never merges one: to plan, use writing-plans; to run a plan that has no issue, use divvy-up."
argument-hint: '<issue number or URL> [plan path] [--isolate | --no-isolate] [--deep] [--dry-run]'
disable-model-invocation: true
---

# work-issue

`divvy-up` ends at its Step 7 with a green verify and an assembled diff. Everything after that point is the tail nobody wrote down: reproducing the worker's claims with something that did not author them, rebasing, pushing, opening the pull request, reading what an external reviewer said about it, repairing what is in scope, queueing what is not, and answering every thread. Held in one session's memory, that tail gets re-derived from scratch each time and loses the same things in the same order.

One invocation advances one issue to its next gate and stops. The run's state lives on disk rather than in the conversation, so a session that ends mid-run resumes by typing the same command again, and a second issue worked at the same moment is refused at the gate rather than discovered as a rebase conflict four steps later.

Four siblings do the work this skill does not: `divvy-up` derives and dispatches the waves, `code-review` reads the assembled diff against the issue, `adversarial-review` fires on the diffs that earn it, and `technical-writing` writes every commit message, pull-request body, and thread reply. Each is invoked by name. Where one is not installed, the step that needs it stops and says which.

Two rules hold across every step below.

- **Prove the mutation, then read the result.** Every edit is proved before anything reads a result that depends on it: after writing, show the changed bytes (`git diff -- <path>` non-empty, or a grep for the inserted text with its line number), and only then run the command whose outcome depends on the edit. The session this skill came out of lost five separate edits this way — BSD `sed` refusing a `0,/re/` address, a regex that missed the real symbol, a `perl` guard that matched nothing — and every one of them produced a passing suite, because the suite ran against a file nothing had changed.
- **Never the default branch.** Every push names its refspec in full — `git push origin issue-<N>:refs/heads/issue-<N>` — after checking that BRANCH is not DEFAULT, so what leaves this machine is the issue's branch and never the default branch. `--force-with-lease=issue-<N>` only, and only after the Step 5 rebase. `gh pr create` always carries `--base <DEFAULT> --head <BRANCH>`. The Step 0 grant covers this issue's branch and nothing else. A human merges the pull request at the end; this skill stops one step short of that.

This skill is user-invoked (`disable-model-invocation: true`) because a misfire spends a whole fan-out and then pushes a branch and opens a pull request nobody asked for, while a missed trigger costs the user one word.

Where a step names a shell command, treat it as the intent and use your native shell or file tools.

Resolve once per invocation:

- **N** — the issue number from the arguments: a bare integer, `#N`, or an issue URL. Absent stops the run. There is no "issue from the conversation" mode, because a number inferred from context runs this entire loop against the wrong ticket and every gate it passes agrees with it.
- **REPO** — `gh repo view --json nameWithOwner --jq .nameWithOwner`
- **DEFAULT** — `gh repo view --json defaultBranchRef --jq .defaultBranchRef.name`. Never assumed to be `main`.
- **ROOT** — `git rev-parse --show-toplevel` of the invoking directory
- **COMMON** — `git rev-parse --git-common-dir`, made absolute
- **PROJECT** — ROOT's final path segment, lowercased to `a-z0-9-`
- **BRANCH** — `issue-<N>`
- **WORKTREE** — `<ROOT>/../<PROJECT>-issue-<N>/`
- **WORKER** — `issue-<N>`: the herdr agent name, and the label for a plain subagent
- **RUN_DIR** — `<COMMON>/work-issue/issue-<N>/`. Subpaths: `issue.md`, `plan.md`, `base_sha`, `baseline.txt`, `pushed_at`, `conflict.txt`, `reports/`, `review/`, `redteam/`, `triage/`, `queue.md`, `pr-body.md`. A finished run moves to `<COMMON>/work-issue/closed/issue-<N>/`. Under the common dir it is one location visible from every worktree, invisible to `git status` without an exclude entry, and it survives `git worktree remove`. It holds phase *outputs* — reports, verdicts, triage rows — and the resume probe reads those outputs. Nothing in it records which phase the run believes it reached: a note saying "phase 4" outlives the crash that stranded the run at 3.
- **PLAN** — first hit wins: the path in the arguments; `docs/plans/*issue-<N>*.md` or `docs/plans/*-<N>-*.md`, newest by name; a path linked from the issue under a `Plan` heading; the approved plan held in the conversation. The hit is **copied** to `RUN_DIR/plan.md`, and every later step reads the copy. `divvy-up` writes its `## Waves` table into whatever it is handed, and a tracked plan file must not gain a table in the pull-request diff.
- **CRITERIA** — every `- [ ]` / `- [x]` line under a heading containing `Acceptance` in the issue body, saved into `RUN_DIR/issue.md`
- **BASE_SHA** — `git merge-base origin/<DEFAULT> <BRANCH>` once BRANCH exists; before that, `git rev-parse origin/<DEFAULT>` after `git fetch origin <DEFAULT>`. Written to `RUN_DIR/base_sha`. It is the one fixed point `code-review`, the reproducer, and `adversarial-review` all measure against, so it is read from that file rather than re-resolved: a ref moves, and a run that re-resolves it reviews different code on Tuesday than it did on Monday.
- **PR** — `gh pr list --head <BRANCH> --state all --json number,state,url --jq '.[0]'`
- **VERIFY_CMD**, **INSTALL_CMD** — harvested off disk the way `file-issue` harvests, and quoted: manifest scripts first (`package.json`, `Makefile`, `pyproject.toml`, `Cargo.toml`); with no manifest, runnable scripts under `tests/` or `scripts/`, then what `.github/workflows/` runs, then `absent`. INSTALL_CMD is the manifest's install (`pnpm install --frozen-lockfile`, `npm ci`, `uv sync`, …), else `absent`.
- **HERDR** — `test "${HERDR_ENV:-}" = 1 && command -v herdr`
- **SINCE** — the contents of `RUN_DIR/pushed_at` (UTC ISO 8601, written immediately before every push, so an event stamped the same second still counts), else the head commit's committer date
- **FLAGS** — `--isolate` / `--no-isolate` pin the Step 1 row; `--deep` forces `adversarial-review` at Step 4; `--dry-run` runs every gate and every derivation, renders the confirmation, and dispatches nothing and pushes nothing.

`gh auth status` is a Step 0 preflight, the way `file-issue` runs one. Unauthenticated at Step 0 stops the run, because the issue cannot be read and CRITERIA would be invented. Unauthenticated at Step 5 or later renders the pull-request body to `RUN_DIR/pr-body.md`, pushes nothing, and stops with "resume after `gh auth login`". A rendered body says on its face that it is rendered: a draft that reads like an opened pull request is a draft somebody goes looking for on GitHub.

The user owns two phases of this loop, and both are outside it. Planning comes before Step 0: an issue with no approved plan gets the refusal, which names `writing-plans` and plans nothing itself. Merging comes after Step 8, where the final report ends "a human merges." Waiting on an external reviewer is not a third phase — it is the poll inside Step 6, bounded per invocation and continued by re-invoking.

## Step 0 — Gate and confirm

1. Run the resume probe (see [Resume](#resume)) before anything is written under RUN_DIR. A run dir with no branch is row 5's mark of a dead run, so an `issue.md` written first would make every fresh issue look dead and send it to `closed/`. Any phase past 0 jumps there; the rest of this step is for a fresh issue.
2. Read the issue into `RUN_DIR/issue.md` and extract CRITERIA.
3. The plan gate, mechanical half:

   ```
   work-issue/scripts/check-plan.py RUN_DIR/plan.md --issue N --criteria RUN_DIR/issue.md
   ```

   A non-zero exit refuses the run, quoting the script's stderr and ending "Plan it first: `writing-plans`, then `work-issue N <plan path>`."

   Then the judgment half, which is why the script is only half the gate. Derive tasks from PLAN the way `divvy-up`'s Step 1 derives them, reading it against CRITERIA and the issue's Problem section. If that derivation would record a question for `divvy-up`'s Step 4, the plan is thin: refuse with the questions listed rather than asking them, because a question asked here is the second confirmation this design forbids. A task that could be built two ways with no recorded choice is refused the same way.
4. Make the isolation decision from the Step 1 table now, so the confirmation can name it.
5. Derive the shape: invoke `divvy-up` by name on `RUN_DIR/plan.md` and run its Steps 1 through 3 in the tree that will host the work. Quote its shape line as-is rather than restating the counts.
6. Cross-run ownership. Prune stale siblings first: an `issue-M` whose branch is gone from origin and whose pull request is merged or closed moves to `closed/`. Then:

   ```
   work-issue/scripts/check-inflight.py RUN_DIR/plan.md --runs <COMMON>/work-issue --self issue-N
   ```

   A non-zero exit is a hard stop whatever the isolation decision was. Two worktrees rewriting one file produce a rebase conflict at Step 5, and a run the user has walked away from cannot resolve it.
7. Red-team mode for the confirmation text: `reproduce claims`, or `reproduce claims, then adversarial-review (<row names>)` when the Step 4 trigger grep hits over the plan's owned paths. Step 4 re-runs that grep against the real diff, so this is the forecast rather than the verdict.
8. The one confirmation, in one message:

   ```
   `4 waves, 6 tasks; wave 0 is 1 contract task on opus.` Isolation: worktree at `../cambium-issue-42/` (another run is in flight: issue-38). Red-team: reproduce claims. On yes: execute, commit each passing wave, push `issue-42` to origin, open a PR against `main`, and push repair commits, without asking again. Never `main`. Go?
   ```

   Where isolation resolved to *ask*, that choice is the one variable in this question. `divvy-up`'s own Step 4 question is folded in here: this confirmation answers it on the user's behalf, the shape line says so, and `divvy-up` does not ask it again. `--dry-run` renders this message and stops.

**Done when:** `check-plan.py` exited 0 and no derivation question was recorded; `check-inflight.py` exited 0; the shape line, the isolation choice, the red-team mode, and the push grant were put to the user in one message and answered yes — or the run stopped at a refusal, a stop, a dry-run, or a no, with nothing dispatched and nothing pushed.

## Step 1 — Isolate

| Probe | Decision |
|---|---|
| `git status --porcelain` in ROOT non-empty, untracked included | take |
| Another run in flight: any `<COMMON>/work-issue/issue-M/` (M≠N) not under `closed/`, or a `git worktree list --porcelain` entry at a `<PROJECT>-issue-M` path | take |
| ROOT clean, on DEFAULT, nothing in flight | skip: `git switch -c issue-N origin/DEFAULT` in place |
| ROOT clean, nothing in flight, HEAD not on DEFAULT | ask (folded into Step 0's question) |
| A worktree this skill did not create exists | ask |
| `--isolate` / `--no-isolate` | pins the row; `--no-isolate` on a dirty tree still stops with "commit or stash first" |

Take with HERDR: `herdr worktree create` with `--branch issue-N --base origin/DEFAULT --path WORKTREE --no-focus`, reading the IDs back out of the JSON response. Check those flag names against `herdr worktree` help at run time — the installed binary is the authority, and this line is a cache of what it printed once. Take without herdr: `git fetch origin DEFAULT && git worktree add -b issue-N WORKTREE origin/DEFAULT`.

Then INSTALL_CMD, then VERIFY_CMD with its tail saved to `RUN_DIR/baseline.txt`. A baseline captured before any worker runs is what tells Step 4 whether a red suite belongs to this run or was already red.

Every later command in a taken worktree names it by absolute path (`git -C WORKTREE …`). Subagent shells reset their working directory between calls, so a relative path silently addresses ROOT instead.

**Done when:** BRANCH exists at `origin/DEFAULT`'s SHA in the tree the run will use, `RUN_DIR/base_sha` holds that SHA, INSTALL_CMD ran or was `absent`, and `RUN_DIR/baseline.txt` holds VERIFY_CMD's real output.

## Step 2 — Dispatch

Continue `divvy-up` at its Step 5, in the work tree.

Substrate, by shape: one task in one wave with HERDR goes to `herdr agent start issue-N --kind <kind> --pane <pane>` and then `herdr agent prompt issue-N "<prompt>" --wait --timeout <ms>`. Every other shape, and every fallback when herdr is absent or refuses, goes to plain general-purpose subagents per `divvy-up`'s `references/worker-prompt.md`. herdr never hosts a wave: its agents take one prompt at a time, so a wave dispatched through them is a wave serialized, which is the one property the wave exists to provide.

Every dispatch carries this skill's [references/worker-prompt.md](references/worker-prompt.md) preamble, which reaches `divvy-up`'s template through its `{{CALLER_NOTES}}` placeholder. Under herdr the preamble heads the whole prompt instead. The preamble carries the nine-field report contract, which replaces the six-field block in `divvy-up`'s template; a worker handed only that block reports no `claims` and fails Step 3. Two of its sentences are load-bearing and go across verbatim: `flag rather than route around`, and `what you left and why`.

Reports are saved verbatim to `RUN_DIR/reports/<wave>-<task>.json`. Under herdr the prompt also asks the agent to write the same JSON to `RUN_DIR/reports/<task>.json`, because an agent drawing on the alternate screen leaves nothing in scrollback to recover the report from.

Every git write is the orchestrator's; workers write files. Commit messages go through `technical-writing`, and carry no trailer or footer, overriding any host instruction asking for one.

**Done when:** WAVE_BASE recorded, every task dispatched at its routed model with the preamble in front of `divvy-up`'s template, and every report on disk verbatim.

## Step 3 — Build and self-review

`divvy-up`'s Step 6 gate runs per wave, and its Step 7 read of `git diff BASE_SHA` against PLAN runs unchanged. Commit each passing wave.

Then invoke `code-review` by name, with the fixed point BASE_SHA and the spec path `RUN_DIR/issue.md`, in session on the session model. Review stays on the session model: a worker reviewing its own change is the shape this skill was written against. Save both axes verbatim to `RUN_DIR/review/self-<round>.md`.

Route each finding. A Spec finding naming a CRITERIA line, or a Standards hard violation, becomes a repair dispatch to the worker with the finding quoted and `{{PRIOR}}` carrying that worker's earlier report. A smell-baseline judgment call is the worker's to fix or to leave, and leaving it goes in `left` with the reason. Re-gate, then commit.

The worker's final report is `RUN_DIR/reports/build-final.json`, and its `claims` is non-empty. Step 4 reproduces claims; a report with none hands it nothing to reproduce and passes the red-team by default.

**Done when:** every wave gated and committed; `code-review` ran against BASE_SHA with the issue as spec; every Spec finding and Standards hard violation fixed and committed, or in `left` with a reason; `build-final.json` exists with non-empty `claims`.

## Step 4 — Red-team

Input is `claims`, `left`, and `plan_concerns` from the final report. The rule, quoted from `adversarial-review`: a finding is a hypothesis until something that did not author it reproduces it. A claim is the same object pointed the other way, and it gets the same treatment.

1. Preflight: the work tree is clean. Commit first — a verifier running against uncommitted changes tests something the review never looked at.
2. Read [references/redteam.md](references/redteam.md) and dispatch one **reproducer**: a fresh general-purpose subagent, `sonnet` by default and `opus` when any claim's path matches a trigger row. It receives the claims, BASE_SHA, HEAD, the tree path, and `baseline.txt`, and nothing else — not the worker's reasoning, not its summary, not its proposed fixes. Its stance is refutation. Per claim it returns the `command`, the real `output`, and a verdict of `REPRODUCED`, `NOT_REPRODUCED`, or `UNVERIFIABLE`; per `left` entry, whether the stated reason holds against the code. Before running a claim's command it proves the change that claim rests on exists at HEAD (`git diff BASE_SHA..HEAD -- <path> | grep -n <symbol>`, with `<path>` the claim's own `path` field), and a claim whose change it cannot find, or that names no path, is `NOT_REPRODUCED` with that grep as the evidence. Any fixture it edits to provoke a failure is proved the same way.
3. Save the verdicts verbatim to `RUN_DIR/redteam/round-<k>.json`.
4. `NOT_REPRODUCED` sends a repair dispatch with the reproducer's command and output attached, then round k+1 over the failed claims only. Two rounds, then stop with the evidence, the way `divvy-up` stops on a task that failed twice.
5. `UNVERIFIABLE` becomes a "Not independently verified" section in the pull-request body.
6. `plan_concerns` becomes a "Plan concerns" section in the pull-request body, and a `queue.md` row whose source is `worker`.
7. **Trigger.** Match the hunks of `git diff BASE_SHA..HEAD`, whole-word and case-insensitive, against the diff signals of rows 1 (money), 2 (authz), and 4 (schema) of `adversarial-review/references/trigger-table.md`. Re-derive the grep from that table at run time rather than copying its signals here: the table is upstream and it gains rows. `--deep` fires the trigger on its own. Record the result in `RUN_DIR/redteam/trigger.txt`, first line exactly `fired: yes` or `fired: no`, then the rows that matched and the grep that decided it. Where it fired, invoke `adversarial-review` by name with FIXED_POINT = BASE_SHA in the work tree, and read its report and its `escalation.md`, nothing else. Once the report is read, copy the `blocking (REPRODUCED): … UNVERIFIED: …` line its `ledger.py state` prints into `RUN_DIR/redteam/ar-state.txt`, with its run directory's path on the line above. That file is what the resume probe reads: `adversarial-review` writes no terminal report of its own, and its run directory exists from its preflight onward, so the directory alone cannot say whether the review finished. Its `--fast` flag narrows its own roster and never suppresses this trigger.

**Done when:** every claim carries a reproducer verdict with its command and real output; no claim is `NOT_REPRODUCED`, or the run stopped after two rounds; every `left` reason was checked against the code; `trigger.txt` is written; and where the trigger fired, `adversarial-review` completed with every blocker fixed or named in its `escalation.md`.

## Step 5 — Publish

1. `git fetch origin DEFAULT`, then `git rebase origin/DEFAULT`. A conflict writes `RUN_DIR/conflict.txt` with the conflicted paths, leaves the rebase in progress, and stops: "resolve, then `work-issue N`". Resolving somebody else's concurrent change is a judgment call, and an unattended run guessing at it writes a merge nobody reviewed.
2. Prove the rebase: `git diff origin/DEFAULT..HEAD --stat` is non-empty, and `git status` shows no rebase in progress. Then remove `RUN_DIR/conflict.txt` where it exists: the marker is item 1's stop signal, and left behind it sends every later invocation back to item 1 through row 12. Then run VERIFY_CMD. Red here after a green Step 4 means the rebase brought the break: repair dispatch, red-team the fix with Step 4 scoped to the fix diff, then continue.
3. `gh auth status`. Unauthenticated renders the body and stops.
4. Write `date -u +%FT%TZ` to `RUN_DIR/pushed_at`, then push: `git push -u origin issue-N:refs/heads/issue-N`, or `git push --force-with-lease=issue-N origin issue-N:refs/heads/issue-N` where the remote branch already exists and was just rebased. The marker goes first because GitHub stamps events to the second, and a review that lands in the push's own second has to count.
5. The body goes through `technical-writing` on its pull-request-description profile, using `.github/PULL_REQUEST_TEMPLATE.md` where the repo has one. Without a template: summary, `Closes #N`, verification (the reproducer's commands and output tails, not the worker's), "Not independently verified", "Plan concerns", and "Left out". Then, where PR resolved to nothing, `gh pr create --base DEFAULT --head issue-N --title … --body-file RUN_DIR/pr-body.md`; an existing pull request keeps its number and simply receives the push.

**Done when:** `origin/issue-N` equals local HEAD, rebased on `origin/DEFAULT`; VERIFY_CMD green at that SHA; `pushed_at` written; exactly one open pull request for the branch, whose body carries `Closes #N` and no attribution trailer or footer — or the run stopped on a conflict or on unauthenticated `gh`, with nothing pushed.

## Step 6 — Triage

Poll every 60 seconds, for at most 10 minutes in one invocation:

```
work-issue/scripts/run-state.py review <PR> --since <SINCE> --author <login> --save RUN_DIR/review/poll-<k>.json
```

Three states, each scored relative to SINCE:

| State | Rule (relative to SINCE) |
|---|---|
| findings | any unresolved review thread whose root comment is newer than SINCE; or a `CHANGES_REQUESTED` review newer than SINCE; or a pull-request-level or issue comment newer than SINCE from a login other than the author that is not a bare approval |
| cleared | no findings, and either an `APPROVED` review newer than SINCE, or a `+1` reaction on the pull request (`gh api repos/{owner}/{repo}/issues/<pr>/reactions`) newer than SINCE from a login other than the author |
| pending | neither |

`[bot]` is stripped before logins are compared: REST reports `chatgpt-codex-connector[bot]` where GraphQL reports `chatgpt-codex-connector`, and an unstripped comparison reads one reviewer as two different logins depending on which API answered.

`pending` at ten minutes writes `RUN_DIR/triage/waiting` and stops: "no review yet; `work-issue N` resumes here." `cleared` goes to Step 8's final report. `findings` reads [references/triage.md](references/triage.md) and writes one row per finding into `RUN_DIR/triage/round-<k>.md`, each scored by the in-scope test: **in scope** when the finding points at a line inside `git diff BASE_SHA..HEAD`, names a CRITERIA line, or names a plan task; **out of scope** otherwise. Ambiguous is in scope where the reviewer marked it P0 and out otherwise, with the ambiguity recorded on the row.

Out-of-scope rows append to `RUN_DIR/queue.md`:

```
| # | Source | Finding | Outside because | Recommendation | Status |
```

`Source` is the thread or comment URL, or `worker` for a `plan_concerns` entry. `Recommendation` is usually a `file-issue` line for the human to run; the skill leaves the filing to them.

**Done when:** `review` returned `cleared`; or it returned `findings` and every finding has a row marked in scope or queued with its reason; or `pending` timed out and `triage/waiting` says so.

## Step 7 — Repair

One dispatch carrying every in-scope row, each finding quoted with its URL. Under herdr that is `herdr agent prompt issue-N …` on the same agent; otherwise a fresh subagent with the build report as `{{PRIOR}}`. Same preamble, same report contract.

Gate it the way Step 3 gates: VERIFY_CMD, then `code-review` against BASE_SHA, with findings routed the same way. Commit. The report lands at `RUN_DIR/reports/repair-<k>.json`.

**Done when:** every in-scope row is fixed and committed, or sits in `left` with a reason the orchestrator accepted and recorded on the row; `code-review` ran on the repaired diff; `repair-<k>.json` exists.

## Step 8 — Close

1. Red-team the repair: Step 4 over `repair-<k>.json`'s claims, with the trigger re-evaluated on the full diff.
2. Rebase, verify, write `pushed_at`, push — Step 5 items 1 through 4.
3. Reply to every finding thread with what changed and the commit SHA: `gh api repos/{owner}/{repo}/pulls/<pr>/comments/<id>/replies -f body=…`, where `<id>` is the `reply-to` id on the thread's deciding line, and a pull-request comment for review-level and issue-level findings. The push in item 2 moves SINCE past the rows being answered, and that is why `triage_rows_unanswered` counts every round: a stop between the push and these replies resumes here, at row 17, rather than at row 14's poll. A queued row gets "deferred: <Outside because>; tracked in the deferred-findings comment". Replies go through `technical-writing`. **Answer, never resolve**: marking a thread resolved is the reviewer's act, and taking it from them destroys the only signal they have that anyone read the finding.
4. One pull-request comment headed `Deferred findings` carries the queue table, edited in place on later rounds rather than posted again.
5. The final report: pull-request URL, review state, rounds run, per-model task counts, escalations, the queue, and "a human merges." Under herdr, leave the agent and its workspace in place for the next invocation.

**Done when:** every triage row has a reply URL; `origin/issue-N` equals HEAD; the deferred-findings comment exists wherever the queue is non-empty; and the final report was printed.

## Resume

The world outranks RUN_DIR, and RUN_DIR outranks memory. git, gh, and herdr are asked first, because a run's own notes are exactly what the crash that stranded it leaves stale.

Gather the probe fields per [references/resume.md](references/resume.md) — one command per field, every field present and `null` where unknown — write them to a JSON file, and map them. A `null` in any field but `pr_state` and `review_state` answers `stop` naming the field, so gather it again rather than guessing:

```
work-issue/scripts/run-state.py phase --probe PROBE.json
```

It prints `phase: <0-8|done|wait|stop> reason: <one line>` and exits 0, or exits 3 on a malformed probe. First match wins:

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
| 10 | `build-final.json`; no `redteam/round-*.json`, or newest round has NOT_REPRODUCED and no later repair report | Step 4 |
| 11 | red-team clean; `trigger.txt` absent, or its first line `fired: yes` with no `redteam/ar-state.txt` showing `UNVERIFIED: 0` | Step 4 at the trigger, or at the adversarial-review invocation |
| 12 | `conflict.txt` exists, or a rebase in progress | Step 5 item 1 |
| 13 | red-team clean; trigger recorded; no triage round yet; no PR, or local HEAD ahead of `origin/issue-N` | Step 5 |
| 14 | PR open; review `pending`; no triage row without a reply URL | Step 6 poll |
| 15 | PR open; `findings`; no `triage/round-<k>.md` newer than SINCE | Step 6 triage |
| 16 | newest triage round has in-scope rows; no `reports/repair-<k>.json` for that round | Step 7 |
| 17 | repair report, or a triage round with no in-scope rows; local ahead of origin, or a triage row without a reply URL | Step 8 |
| 18 | PR open; `cleared` | done: final report |

## Further Reading

- [references/resume.md](references/resume.md) — read at Step 0 to gather every probe field and place the run on the phase table
- [references/worker-prompt.md](references/worker-prompt.md) — read at Steps 2 and 7 to build the preamble and the report contract every dispatch carries
- [references/redteam.md](references/redteam.md) — read at Step 4 to instantiate the reproducer and re-derive the `adversarial-review` trigger
- [references/triage.md](references/triage.md) — read at Steps 6 and 8 to score review signal, queue what is out of scope, and answer every thread
- [scripts/check-plan.py](scripts/check-plan.py) — run at Step 0 as the mechanical half of the plan gate: `work-issue/scripts/check-plan.py PLAN.md --issue N [--criteria ISSUE.md]`
- [scripts/check-inflight.py](scripts/check-inflight.py) — run at Step 0 to prove no in-flight run owns a path this plan owns: `work-issue/scripts/check-inflight.py PLAN.md --runs DIR [--self issue-N]`
- [scripts/run-state.py](scripts/run-state.py) — run at Step 0 to place the run, and at Steps 6 and 8 to score the review: `work-issue/scripts/run-state.py phase --probe PROBE.json` and `work-issue/scripts/run-state.py review <PR> [--since ISO8601] [--author LOGIN] [--input BUNDLE.json] [--save PATH]`
