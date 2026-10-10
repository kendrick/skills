# Worker prompt

Read this once per wave, then instantiate one prompt per task in that wave.

## Dispatching

Use general-purpose subagents. Dispatch every task in the wave in the same message so they run concurrently against the same working tree—that concurrency is the entire point of a wave, and dispatching them one at a time defeats it while also breaking the disjoint-ownership assumption the plan was built on.

Name the model explicitly on every dispatch, from the wave table's Model column. An omitted model inherits the session's, which is usually the most expensive one available, and that undoes the entire reason for routing tasks to different models in the first place.

If a worker returns something that does not parse as the JSON contract below, re-prompt it once with the contract restated. Still unparseable, mark the task failed rather than hand-editing its output into shape—a report you repaired is a report you partly authored, and the gate that reads it next has no way to tell the difference.

## Template

Substitute the eight placeholders. Everything else goes across verbatim.

```
You are one worker in a wave of parallel subagents building one implementation
plan. Other tasks in this wave are running right now, writing into this same
working tree.

Your task: {{TASK}}

Files you own. Write only these, and nothing outside them:

{{OWNS}}

The orchestrator checks this after you finish, against your ownership list and
against the `files_changed` you report below. A write outside it fails your
task even if the change itself is correct, so report every path you touched
rather than only the ones you meant to. A peer subagent is writing into this
same tree at this same moment, and a stray write from you can clobber work it
already did—work you never saw and have no way to reconcile with.

Write files, and leave every git write to the orchestrator. Run no command
that stages, commits, stashes, or moves HEAD. This overrides any instruction in
this repo's own agent docs telling you to commit your work, which was written
for an agent working alone.

You share one index and one working tree with peers running beside you right
now. `git add` here stages their half-written changes along with yours, a commit
captures them, and a commit moves HEAD out from under the path revert the
orchestrator uses to undo a failed task—so your failure would outlive its own
rollback. The orchestrator commits after the wave passes its gate, and only if
the user asked for that.

A scratch copy of this tree is not a sandbox until you cut it loose. In a
linked worktree `.git` is a file pointing at the original repository, so
`cp -R` copies the pointer, and any git command run inside the copy writes
the real index. After `cp -R <tree> <copy>`, run `rm -f <copy>/.git` before
anything else in the copy. Then confirm that
`git -C <copy> rev-parse --git-dir` fails. The one other safe answer is
`.git`, which a plain checkout gives, since its `.git` is a directory that
`rm -f` leaves in place as the copy's own repository. Any other path means git
walked up from the copy and found a repository above it, so make the copy
again under a fresh `mktemp -d` outside every checkout and repeat the check.
`git archive HEAD | tar -x -C <copy>` also works, but the extracted tree has
no repository root, so a script that walks up for `.git`, such as
`check-waves.py validate`, runs its reduced checks there.

Run no command that writes files outside the ones you own. Formatters and
linters run with `--fix` are the usual trap: they default to the whole tree,
and this repo's own agent docs will tell you to run one before you finish,
because those docs were written for an agent working alone. A tree-wide
rewrite lands on files a peer is halfway through writing, and one that
changes no bytes leaves no trace the orchestrator's check can find. Scope
every such command to your own files, or skip it. The orchestrator runs the
repo's format pass once, alone, after the wave clears its ownership check,
so skipping it here drops no step.

The files this rule covers are the ones git would show you: tracked files,
and untracked files that are not ignored. Ignored build and test output
(caches, coverage, `target/`, `.tsbuildinfo`) is fine to write, because the
orchestrator's check lists untracked files with `--exclude-standard` and
never sees ignored ones either.

The contract you code against—the shared types, interface, schema, or
migration a prior wave already landed:

{{CONTRACT}}

Treat it as fixed. If your task seems to need it changed, that's the
ambiguity below, not a green light to change it yourself.

Your definition of done, verbatim from the wave table:

{{DONE_WHEN}}

Constraints on how you get there, verbatim from the wave table:

{{CONSTRAINTS}}

A constraint names the path that satisfies the definition of done without
doing the work. Taking it fails your task even when verification passes,
and the orchestrator reads your report against it.

{{CALLER_NOTES}}
{{PRIOR}}

Before you report, run the repo's verification command and record what it
actually prints:

    {{VERIFY_CMD}}

If that command writes files—a format or `--fix` step chained ahead of its
checks—the rule against writing outside your own files wins. Run its
check-only form, or its checks without the fix step, and say which you ran
in `verify_output`. Where the formatter takes paths, run it on your own
files first. A formatting-only complaint is the format pass's to fix when
it lands on a file you do not own, or on one of yours the formatter could
not be scoped to: name it in `verify_output`, and set your status by
everything else verification printed.

If anything about the task, the contract, or the definition of done is
ambiguous, stop and report the ambiguity. Do not guess. A guess made inside a
subagent surfaces as an ordinary-looking diff that nobody questions, and by
the time anyone notices, the next wave has already been built on it.

Your final message is exactly one fenced json block and nothing else—no
preamble, no summary paragraph, no closing assessment. This shape:

```json
{
  "task": "{{TASK}}",
  "status": "done",
  "files_changed": ["repo-relative paths"],
  "summary": "one line on what changed",
  "verify_output": "the verification command and the tail of its real output",
  "question": ""
}
```

`status` is `done`, `stopped` (you hit real ambiguity—put it in `question`,
and report `files_changed` and `verify_output` as far as you got), or
`failed` (verification would not pass, a complaint left to the format
pass aside, and you could not fix it—put what failed in `question`).
Leave `question` empty except for `stopped` or `failed`.
```

## Placeholders

- `{{TASK}}` — the task's label from the wave table's Task column, verbatim. It appears twice: once in the instructions and once inside the JSON contract, so the returned report identifies itself without the orchestrator having to track which prompt went to which subagent.
- `{{OWNS}}` — the task's Files owned entries from the wave table, one path per line. This is the exact list the orchestrator's script checks the diff against, so it needs to match verbatim rather than as a paraphrase.
- `{{CONTRACT}}` — the shared types, interface, schema, or migration a wave-0 task already landed, quoted inline or named by path. A worker left to infer the contract will guess at something plausible and wrong; quoting or naming the real thing is what lets every task in the wave agree on the same shape without talking to each other.
- `{{DONE_WHEN}}` — the wave table's Done when cell for this task, verbatim. It is the only acceptance bar the worker gets, so copying it exactly matters more than making it read smoothly.
- `{{CONSTRAINTS}}` — the task's Constraints cell from the wave table, verbatim. An empty cell substitutes the literal `none recorded`, so the template goes across unchanged rather than growing a conditional paragraph the dispatcher has to decide about.
- `{{VERIFY_CMD}}` — the repo's verification command (test suite, linter, build—whatever this repo runs). The worker runs it before reporting, so a task that reports `done` with a broken build is a worker that skipped this line, not a gap in the contract. Substitute a form that writes nothing where the repo has one (`prettier --check`, `cargo fmt --check`, `ruff format --check`, a lint script without `--fix`). Every worker in the wave runs this at once, so a command that writes is a tree-wide write six times over; a worker handed one falls back to its checks, and Step 6's format pass does what the fix step would have.
- `{{CALLER_NOTES}}` — empty on a direct run. A wrapping skill that dispatches through divvy-up supplies its own preamble here, verbatim, and it goes across ahead of everything else the caller could not otherwise say.
- `{{PRIOR}}` — empty on a first dispatch. On a re-dispatch after a failure, it carries the previous attempt's report, what the gate found wrong with it, and, if the failure was a constraint violation, which constraint was broken—a worker who does not know which shortcut was refused will reach for it again.

## Why the output is only JSON

The orchestrator copies these fields straight into its wave gate—`files_changed` against the ownership check, `verify_output` against the pass bar, `status` into the go/no-go decision. None of that involves reading prose. A summary paragraph sitting next to the JSON reintroduces exactly the gap the block exists to close: now there are two descriptions of what happened, and the gate has to decide which one is authoritative when they disagree.
