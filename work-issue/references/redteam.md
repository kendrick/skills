# Red-team

Read this at Step 4, and again at Step 8 when the repair's claims come back.

Two mechanisms live here. The **reproducer** takes the worker's claims and tries to break them. The **trigger** decides whether this diff also earns a full `adversarial-review` run, which most diffs do not.

## The reproducer

One fresh general-purpose subagent per round: `sonnet` by default, `opus` where any claim's path matches one of the trigger rows below. It is dispatched, it reports, and it is gone — it never repairs anything it refutes, because an agent that fixes what it found has authored the fix its own verdict now covers.

### What it receives

- the `claims` array out of the final report: `claim`, `path`, `command`, `output`. The reproducer never sees `files_changed`, so `path` is the only file name it has for the change-exists grep, and the only one the `opus` routing reads against the trigger rows
- the `left` array: `what` and `why`
- BASE_SHA and HEAD
- the absolute path of the tree
- `RUN_DIR/baseline.txt`, so a failure that was already failing before this run is recognized rather than attributed

### What it never receives

The worker's reasoning, its `summary`, and any fix it proposed. `adversarial-review` states the rule this copies: "A verifier that shares context with the finder is the same mistake as running several review personas in one window: the reasoning that produced the claim is sitting right there, and agreeing with it is the path of least resistance." It puts the sharpest case on the proposed fix, which "is the finder's reasoning in disguise: a proposed fix tells you what the finder believed the bug was, and a verifier who reads it inherits the belief it was supposed to test independently."

A claim is that same object pointed the other way. The worker believed the change works; the reproducer's job is to find out whether the command it ran shows that, and the worker's account of why it works is the one input that would tell it what to conclude.

### Stance

Refutation. The reproducer is not checking whether the claim is plausible or whether the commands look reasonable — it is trying to make each claim fail, and reporting `REPRODUCED` only where it could not. A round that reproduces everything on the first pass and quotes no output it actually saw has agreed rather than verified.

### Prove the change exists first

Every claim rests on some edit. Before running a claim's command, prove that edit exists at HEAD:

```
git diff BASE_SHA..HEAD -- <path> | grep -n <symbol>
```

Empty output is the verdict. The claim is `NOT_REPRODUCED` with that grep as its evidence, and the run does not proceed to the claim's command — a suite passing against a file nothing changed is the exact failure this whole step exists to catch, and it passes just as cheerfully for the reproducer as it did for the worker.

The same rule binds the reproducer's own writes: every edit is proved before anything reads a result that depends on it. Where it edits a fixture to provoke a failure, it shows the changed bytes first, then runs the suite. A provocation that never landed produces a green suite and the false conclusion that the guard works.

### The prompt

```
You are reproducing claims made by an agent whose reasoning you will not see.

Tree: {{TREE}} — name it by absolute path in every command; your shell's
working directory resets between calls.

Fixed point: BASE_SHA = {{BASE_SHA}}. Current head: {{HEAD}}.

The suite's output before any of this work began, for telling a pre-existing
failure from a new one:

{{BASELINE}}

Claims to break. Each one is a hypothesis, and your stance is refutation:

{{CLAIMS}}

Entries the author chose to leave undone, each with the reason given. Check
each reason against the code, not against whether it sounds reasonable:

{{LEFT}}

For every claim, before you run anything: prove the change the claim rests on
exists at the head commit, with `git diff BASE_SHA..HEAD -- <path> | grep -n
<symbol>`. Empty output means NOT_REPRODUCED, and that grep is your evidence.
Do not run the claim's command in that case.

Every edit you make is proved before anything reads a result that depends on
it. Where you edit a fixture to provoke a failure, show the changed bytes
first, then run the suite. A provocation that never landed leaves the suite
green and tells you the opposite of the truth.

Paste real output. A command's output you summarized is a command nobody ran.

Your final message is exactly one fenced json block and nothing else.
```

### Verdict JSON

```json
{
  "verdicts": [{"claim": "", "command": "", "output": "", "verdict": "REPRODUCED"}],
  "left_checks": [{"what": "", "holds": true, "evidence": ""}]
}
```

`verdict` is `REPRODUCED`, `NOT_REPRODUCED`, or `UNVERIFIABLE`. The three route differently and the difference matters: `NOT_REPRODUCED` is a repair dispatch with the reproducer's command and output attached; `UNVERIFIABLE` is a pull-request section naming what nobody could check; `REPRODUCED` is the only one that lets the claim stand.

`holds` is the reproducer's read of a `left` entry's stated reason against the code. `false` with evidence is a finding, and it routes like a `NOT_REPRODUCED` claim.

Saved verbatim to `RUN_DIR/redteam/round-<k>.json`. A verdict file you tidied is a verdict file you partly authored.

## The adversarial-review trigger

`adversarial-review` is the last line of defense here rather than the default red-team. A full parallel fan-out with finders, verifiers, and a failing test before every fix is expensive, and the diffs that earn it are the ones where a quiet wrong answer costs real money, leaks real data, or corrupts real rows.

**The trigger fires where the hunks of `git diff BASE_SHA..HEAD` match the diff signals of rows 1 (money), 2 (authz), or 4 (schema) of `adversarial-review/references/trigger-table.md`, or where `--deep` was passed.**

Two rules on the match:

- **Re-derive the grep from the table at run time.** Read the three rows, pull their signal lists, build the grep. Never copy the signals into this file: the table is upstream, it gains rows and signals, and a copy here becomes a quietly narrower trigger that still looks like the real one.
- **Match whole words and identifiers, case-insensitively — never bare substrings.** `grep -Ei '\b<signal>\b'` over the hunks. The table gives the reason: `index` inside `page_index` files a paging helper as a schema change, and `rate` inside `generate` makes every function a money change. A trigger that fires on everything is a trigger nobody keeps.

Record the outcome in `RUN_DIR/redteam/trigger.txt`: whether it fired, which rows matched, and the grep that decided it. The resume probe reads that file, so a run interrupted between the trigger and the invocation picks up at the invocation rather than re-deriving the answer.

Where it fired, invoke `adversarial-review` by name with FIXED_POINT = BASE_SHA, in the work tree. Read its report and its `escalation.md`, and nothing else from its run directory. Its `--fast` flag pins its own depth and roster size; it has no bearing on whether this trigger fired.
