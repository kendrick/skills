# Worker prompt

Read this once per wave, then instantiate one prompt per task in that wave.

## Dispatching

Use general-purpose subagents. Dispatch every task in the wave in the same message so they run concurrently against the same working tree—that concurrency is the entire point of a wave, and dispatching them one at a time defeats it while also breaking the disjoint-ownership assumption the plan was built on.

Name the model explicitly on every dispatch, from the wave table's Model column. An omitted model inherits the session's, which is usually the most expensive one available, and that undoes the entire reason for routing tasks to different models in the first place.

If a worker returns something that does not parse as the JSON contract below, re-prompt it once with the contract restated. Still unparseable, mark the task failed rather than hand-editing its output into shape—a report you repaired is a report you partly authored, and the gate that reads it next has no way to tell the difference.

## Template

Substitute the six placeholders. Everything else goes across verbatim.

```
You are one worker in a wave of parallel subagents building one implementation
plan. Other tasks in this wave are running right now, writing into this same
working tree.

Your task: {{TASK}}

Files you own. Write only these, and nothing outside them:

{{OWNS}}

The orchestrator checks this after you finish, attributing every path the
wave wrote against your ownership list. A write outside it fails your task
even if the change itself is correct. A peer subagent is writing into this
same tree at this same moment, and a stray write from you can clobber work
it already did—work you never saw and have no way to reconcile with.

The contract you code against—the shared types, interface, schema, or
migration a prior wave already landed:

{{CONTRACT}}

Treat it as fixed. If your task seems to need it changed, that's the
ambiguity below, not a green light to change it yourself.

Your definition of done, verbatim from the wave table:

{{DONE_WHEN}}

{{PRIOR}}

Before you report, run the repo's verification command and record what it
actually prints:

    {{VERIFY_CMD}}

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
`failed` (verification would not pass and you could not fix it—put what
failed in `question`). Leave `question` empty except for `stopped` or
`failed`.
```

## Placeholders

- `{{TASK}}` — the task's label from the wave table's Task column, verbatim. It appears twice: once in the instructions and once inside the JSON contract, so the returned report identifies itself without the orchestrator having to track which prompt went to which subagent.
- `{{OWNS}}` — the task's Files owned entries from the wave table, one path per line. This is the exact list the orchestrator's script checks the diff against, so it needs to match verbatim rather than as a paraphrase.
- `{{CONTRACT}}` — the shared types, interface, schema, or migration a wave-0 task already landed, quoted inline or named by path. A worker left to infer the contract will guess at something plausible and wrong; quoting or naming the real thing is what lets every task in the wave agree on the same shape without talking to each other.
- `{{DONE_WHEN}}` — the wave table's Done when cell for this task, verbatim. It is the only acceptance bar the worker gets, so copying it exactly matters more than making it read smoothly.
- `{{VERIFY_CMD}}` — the repo's verification command (test suite, linter, build—whatever this repo runs). The worker runs it before reporting, so a task that reports `done` with a broken build is a worker that skipped this line, not a gap in the contract.
- `{{PRIOR}}` — empty on a first dispatch. On a re-dispatch after a failure, it carries the previous attempt's report and what the gate found wrong with it. A worker who knows how the last attempt failed fixes that failure; a worker dispatched cold repeats it, because nothing in a fresh prompt tells it the first path was already tried and turned down.

## Why the output is only JSON

The orchestrator copies these fields straight into its wave gate—`files_changed` against the ownership check, `verify_output` against the pass bar, `status` into the go/no-go decision. None of that involves reading prose. A summary paragraph sitting next to the JSON reintroduces exactly the gap the block exists to close: now there are two descriptions of what happened, and the gate has to decide which one is authoritative when they disagree.
