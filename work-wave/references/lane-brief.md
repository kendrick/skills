# Lane brief

Read at Steps 4 and 7 to instantiate each lane's dispatch, and at Steps 5 and 7 to read what a lane hands back.

A lane is not a `divvy-up` worker. A worker writes files into a shared tree and leaves every git write to the orchestrator; a lane is a whole `work-issue` run, and it takes a worktree, commits, and, once granted, pushes and opens a pull request. So this brief says almost nothing about how to do the issue — `work-issue` already says that. What it carries is what the wave knows and the lane cannot: who else is running, which coupling rows name this lane, what the wave has learned so far, where to hand results back, and which half of `work-issue`'s own confirmation the wave has already answered on the lane's behalf.

## The brief

Instantiate this once per lane, substituting the thirteen placeholders below. Everything else, fence included, goes across verbatim — this is the whole prompt a lane receives, so a paraphrase here is a paraphrase the lane never sees corrected.

```
You are one lane in a wave of parallel work-issue runs. {{SIBLINGS}}

Your issue: {{ISSUE}}
Your plan, by absolute path: {{PLAN}}

Invoke the `work-issue` skill by name, exactly as:

    work-issue {{N}} {{PLAN}} --isolate

and follow it as written. `--isolate` is not optional: your siblings are
taking worktrees at this same moment, and the flag is what makes your
isolation decision take a worktree without asking a question nobody is here
to answer. Your worktree will be {{WORKTREE}} and your run directory
{{RUN_DIR}}; work-issue makes both. Do not make either yourself.

Phase: {{PHASE}}.

work-issue's Step 0 confirmation has been put to the user by work-wave and
answered. Do not ask it again. The answer, for this invocation:

{{GRANT}}

Name every path you run a command in or report by its absolute form. Your
shell's working directory resets between calls, so a relative path addresses
whatever tree the session started in, and a worktree-relative path in your
report is one the orchestrator cannot open.

The wave's hand-back directory is {{WAVE_DIR}}. It is under the git common
dir, so it is visible from your worktree and from every sibling's.

Facts other lanes have learned about this repository, each with the command
or path that proved it. Read them before your first command, and read the
directory {{WAVE_DIR}}/facts/ again before every worker dispatch and every
repair dispatch you make, because siblings append while you run:

{{FACTS}}

Record what you learn the same way. Append one line per fact to
{{FACTS_PATH}}—that file is yours alone, and you write to no other file
under facts/—the moment you learn it, not at the end, in this form:

    - [issue-{{N}}] <the fact> — <the command you ran, or the path you read>

A fact is something a sibling would otherwise pay to relearn: a CLI whose
two flags are mutually exclusive and exits 2, a test that needs a service
running, an install step the manifest does not mention, a path that moved.
A fact you cannot say how you know is not one; write the command.

Carry the facts to your workers. work-issue puts its preamble into
divvy-up's {{CALLER_NOTES}} placeholder; append the current contents of
{{WAVE_DIR}}/facts/ after that preamble, verbatim, on every dispatch you
make, so the agents doing the work meet the facts before they meet the task.

Coupling rows that name your lane, from the wave's pairwise reading of the
plans. Where a row says a sibling's change alters what you build against,
that sibling is ahead of you in the merge order, and the wave's merge test
will run your branch behind theirs:

{{COUPLING}}

Your place in the merge order: {{ORDER}}

Everything work-issue says about the plan being possibly wrong, proving the
mutation before reading the result, and never the default branch holds
unchanged. Your branch is issue-{{N}} and nothing else.

Your final message is exactly one fenced json block and nothing else—no
preamble, no summary paragraph. This shape:

{
  "lane": "issue-{{N}}",
  "phase": "{{PHASE}}",
  "status": "done",
  "head": "the SHA of issue-{{N}} at the moment you report, from git -C <worktree> rev-parse HEAD",
  "worktree": "absolute path",
  "run_dir": "absolute path",
  "files_changed": ["repo-relative paths, the union across every wave you ran"],
  "contract_changed": ["the subset of files_changed that a wave-0 task of your ## Waves table owned"],
  "facts": ["every line you appended to your facts file, verbatim"],
  "pr": null,
  "detail": "work-issue's own final report or stop message, verbatim",
  "question": ""
}

`status` is `done` (work-issue reached the Done-when of the last step this
phase's grant allows), `stopped` (work-issue stopped for want of an answer,
or a worker did—put the question in `question`), `failed` (a gate failed
twice, a merge test inside work-issue went red, or a report would not
parse—put what failed in `question`), or `refused` (work-issue's Step 0
refused the plan or the cross-run check—put its stderr in `question`).
`pr` is the pull-request URL once one exists and null before. Leave
`question` empty except for `stopped`, `failed`, or `refused`.
```

## Placeholders

Thirteen substitutions. Twelve stand for a single value; `{{GRANT}}` stands for one of two whole paragraphs.

- `{{SIBLINGS}}` — one line naming the wave's other lanes: the rest of ISSUES and their titles, read off `lanes.md`. It puts the other issues in front of a lane before its first command, the way `{{ISSUE}}` puts its own.
- `{{ISSUE}}` — `issue-<N>`, its title, and its URL, from the `gh issue view` call at Step 0.
- `{{PLAN}}` — PLAN[N], the absolute path Step 0 resolved for this issue.
- `{{N}}` — the lane's bare issue number. It stands alone in the invocation line and the facts-file line, and joins `issue-` everywhere else the brief names the branch.
- `{{WORKTREE}}` — LANE[N]'s WORKTREE, absolute: `<ROOT>/../<PROJECT>-issue-<N>/`.
- `{{RUN_DIR}}` — LANE[N]'s RUN_DIR, absolute: `<COMMON>/work-issue/issue-<N>/`.
- `{{PHASE}}` — `build` at Step 4, `publish` at Step 7.
- `{{GRANT}}` — the build half at Step 4, verbatim: *"Yes to executing every wave and committing each passing one in your worktree, on issue-{{N}}. The push and pull-request half is withheld for this invocation: treat it as a no for Steps 5 through 8, stop once Step 4's Done-when holds, and report. The wave runs a merge test across every lane before any of them publishes, and you will be invoked again with the other half."* The full grant at Step 7, verbatim: *"Yes to all of it: rebase, push issue-{{N}} to origin as issue-{{N}}, open a pull request against {{DEFAULT}}, triage, repair, and answer every thread, without asking again. Never {{DEFAULT}}. The wave's merge test is green at your current HEAD."* `{{DEFAULT}}` inside that second text is work-wave's own DEFAULT, already resolved before the grant reaches this brief; nothing about it is a lane-brief placeholder.
- `{{WAVE_DIR}}` — WAVE_DIR, absolute, under COMMON.
- `{{FACTS}}` — the concatenated contents of every `facts/*.md` under WAVE_DIR at dispatch time, or the literal `none yet` where nothing has been learned yet, so the brief goes across unchanged rather than growing a conditional paragraph.
- `{{FACTS_PATH}}` — this lane's own fact file, `{{WAVE_DIR}}/facts/issue-{{N}}.md`. Every lane reads the whole facts directory; only this lane writes to this file.
- `{{COUPLING}}` — the `coupling.md` rows that name this lane, quoted.
- `{{ORDER}}` — this lane's own row in `order.md`: its place in the merge order, or `held`, and what it waits on.

## The report contract

The lane's final message is the fenced block inside the brief above, reproduced here as the twelve fields Steps 5 and 7 read:

```json
{
  "lane": "issue-{{N}}",
  "phase": "{{PHASE}}",
  "status": "done",
  "head": "the SHA of issue-{{N}} at the moment you report, from git -C <worktree> rev-parse HEAD",
  "worktree": "absolute path",
  "run_dir": "absolute path",
  "files_changed": ["repo-relative paths, the union across every wave you ran"],
  "contract_changed": ["the subset of files_changed that a wave-0 task of your ## Waves table owned"],
  "facts": ["every line you appended to your facts file, verbatim"],
  "pr": null,
  "detail": "work-issue's own final report or stop message, verbatim",
  "question": ""
}
```

`status` is one of four: `done` (work-issue reached the Done-when of the last step this phase's grant allows), `stopped` (work-issue stopped for want of an answer, or a worker did — the question is in `question`), `failed` (a gate failed twice, a merge test inside work-issue went red, or a report would not parse — what failed is in `question`), or `refused` (work-issue's Step 0 refused the plan or the cross-run check — its stderr is in `question`).

Each field answers a step that reads it:

- `lane`, `phase` — which lane and which dispatch this report answers.
- `status` — Step 5's route table.
- `head` — checked against the newest merge test's SHAs at Step 8 to decide whether a repair round moved a lane past its last-tested commit.
- `worktree`, `run_dir` — absolute paths the orchestrator reads directly and hands to a resumed `work-issue`.
- `files_changed` — re-run through `check-footprints.py` at Step 5, in place of the lane's pre-dispatch footprint file, to prove the lane's derived table stayed disjoint.
- `contract_changed` — decides whether Step 5 runs a merge test now, ahead of every other lane finishing.
- `facts` — checked against `{{WAVE_DIR}}/facts/issue-{{N}}.md`; where the two differ, the file the lane wrote as it went is the one that wins.
- `pr` — null on a build report, which is the withheld grant's own evidence that it held; the pull-request URL once a publish report opens one.
- `detail` — quoted verbatim in the wave's final report for any lane that stops, fails, or is refused.
- `question` — held for the user with the wave's next message; empty on `done`.
