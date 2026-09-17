# Worker prompt

Read this at Step 2, and again at Step 7. It holds two things: the **preamble** every dispatch carries, and the **report contract** the later steps read.

The preamble reaches a wave worker through `divvy-up`'s `{{CALLER_NOTES}}` placeholder, which is the seam a wrapping skill is given for exactly this — it goes across ahead of everything else, so a worker meets the issue before it meets its task. Under herdr there is no template to fold into, and the preamble heads the whole prompt instead.

`divvy-up`'s own placeholders (`{{TASK}}`, `{{OWNS}}`, `{{CONTRACT}}`, `{{DONE_WHEN}}`, `{{CONSTRAINTS}}`, `{{VERIFY_CMD}}`, `{{PRIOR}}`) pass through untouched; `divvy-up` substitutes them. Substitute only the five below.

## The preamble

```
You are working one GitHub issue: {{ISSUE}}.

Acceptance criteria, verbatim from the issue. These are the bar the whole
change is judged against, not a summary of it:

{{CRITERIA}}

Work in {{TREE}}. Name it by absolute path in every command you run — your
shell's working directory resets between calls, so a relative path addresses
whatever tree the session started in.

The plan may be wrong. It was written before anyone read the code you are
about to read, and where it contradicts what is actually there, the plan is
the thing that is out of date. Flag rather than route around: put what the
plan said, what you found, and what you did into `plan_concerns`. A
workaround invented to keep a wrong plan true is the most expensive kind of
correct, because it looks finished and nobody can see what it cost.

Report what you left and why. A finding you judged out of scope, a refactor
you decided against, a test you could not write: each goes into `left` with
its reason. An omission with a reason attached is a decision somebody can
check; a silent one is a hole nobody finds until review.

Prove the mutation, then read the result. Every edit is
proved before anything reads a result that depends on it: after writing,
show the changed bytes (`git diff -- <path>` non-empty, or a grep for the
inserted text with its line number), and only then run the command whose
outcome depends on the edit. A `sed` address the local build rejects, a
regex that missed the real symbol, a guard clause that matched nothing: each
leaves the file exactly as it was and the suite exactly as green as it
already was, and that green is what you will report if you never look at the
bytes.

Every entry in `claims` is reproduced later by an agent that never saw your
reasoning and works only from the command you wrote down. So write the
command you actually ran against the tree as it now stands, and paste its
real output — not a tidied version, and not the command you meant to run.

Leave every git write to the orchestrator. Write files, and run no command
that stages, commits, stashes, rebases, pushes, or moves HEAD. This holds
even where you have a whole shell to yourself and this repo's own agent docs
tell you to commit your work: those docs were written for an agent working
alone. The orchestrator commits each passing wave and owns every push.

Write the same JSON report to {{REPORT_PATH}}.

Review findings to repair, each quoted with its source URL:

{{FINDINGS}}
```

## The report contract

`divvy-up`'s six fields, unchanged, plus three this skill's Steps 4, 5, and 6 read:

```json
{
  "task": "{{TASK}}",
  "status": "done",
  "files_changed": ["repo-relative paths"],
  "summary": "one line on what changed",
  "verify_output": "the verification command and the tail of its real output",
  "question": "",
  "claims": [{"claim": "what is now true", "command": "what proves it", "output": "what that command really printed"}],
  "left": [{"what": "what was not done", "why": "the reason it was not"}],
  "plan_concerns": [{"plan_said": "the plan's words", "found": "what the code showed", "did": "what was built instead"}]
}
```

- `claims` is the red-team's whole input. A claim with no command is unreproducible and comes back `UNVERIFIABLE`, which reaches the pull request as a section saying so. An empty `claims` on the final build report fails Step 3 rather than passing Step 4 by having nothing to check.
- `left` is checked entry by entry against the code by the same reproducer. A reason that does not hold is a finding.
- `plan_concerns` reaches the pull-request body and the deferred queue. It is the only channel a worker has for "the plan asked for something the code cannot support", and a worker that stays silent here hands the next reader a diff that disagrees with its own plan for no visible reason.

## Placeholders

- `{{ISSUE}}` — `issue-<N>`, the issue title, and its URL. A worker that knows only its task builds the task; a worker that knows the issue notices when the task no longer serves it.
- `{{CRITERIA}}` — the CRITERIA lines out of `RUN_DIR/issue.md`, verbatim, checkboxes included. Copied rather than paraphrased: a criterion reworded in the dispatch is a criterion the gate and the worker now disagree about.
- `{{TREE}}` — the absolute path of the tree this run works in: WORKTREE where Step 1 took one, ROOT where it skipped.
- `{{REPORT_PATH}}` — herdr only: the absolute path `RUN_DIR/reports/<task>.json`. On a plain subagent dispatch the whole line comes out along with the placeholder, because the returned JSON is already the record. Under herdr it is the only copy that survives, since an agent drawing on the alternate screen leaves nothing in scrollback.
- `{{FINDINGS}}` — at Step 7, one block per in-scope triage row: the finding quoted, its thread or comment URL, and what makes it in scope. At Step 2 it substitutes the literal `none`, so the preamble goes across unchanged rather than growing a conditional paragraph somebody has to decide about.

## Why the output is only JSON

The orchestrator reads these fields straight into its next step: `files_changed` into `divvy-up`'s ownership check, `verify_output` against the pass bar, `status` into the go/no-go, `claims` into the reproducer's dispatch, `left` and `plan_concerns` into the pull-request body and the queue. None of that involves reading prose. A summary paragraph beside the JSON reopens the gap the block closes: two accounts of what happened, and no rule for which one wins where they differ. The reproducer is the sharpest case — it is built to receive the claims and nothing else, and a prose summary riding along is exactly the worker's reasoning it was designed never to see.
