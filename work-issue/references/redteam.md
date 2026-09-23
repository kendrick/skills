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

### Drive the nearest production caller

The seam reproduction stays and the caller reproduction comes last: run the claim's command at the seam first, then find the change's production callers at HEAD and drive the nearest one. The caller's result is the deciding one. A fixture built by hand shares the assumptions of whoever built it, worker and reproducer alike, and the caller shares none of them—it builds the seam's input out of whatever production hands it.

Find callers with the symbol the change-exists grep already named:

```
git -C TREE grep -n -w <symbol> HEAD -- . ':!*test*' ':!*spec*' ':!*fixture*'
```

The claim's own file stays in range. A seam and the production caller above it share a file often enough that excluding the claim path drops both, and the search then reports a called seam as a seam nothing calls—the exact false negative this subsection exists to catch, arriving through the search itself.

A **production caller** is a non-test path that reaches the changed symbol. Reaching is the test, and the search is wide on purpose: the symbol's own definition line comes back among the hits, and so do the ledgers, agent docs, and changelogs that spell the symbol out and run nothing. Read the hits and take one that runs it. **Nearest** is the one that calls it directly; where several do, take the one whose own input comes from furthest outside the seam. For a script or a CLI, the caller is the command line production runs it with, driven the way production drives it.

**The caller builds the seam's input.** Whatever the reproducer supplies goes in at the caller's boundary, and the caller constructs what reaches the seam.

Three runs record `reproduced_at: seam`, and each is an answer rather than a failure:

- **No production caller among the hits.** `caller.path` is null, `caller.search` carries the grep and `caller.output` what it returned—nothing, or the hits that named the symbol and ran it nowhere—and `reproduced_at` is `seam`. The verdict is whatever the seam said, and the run continues—an unexercised seam is worth knowing about, and it reaches the pull-request body as seam only.
- **A caller found and not drivable**, because it needs a live service, credentials, or hardware. `caller.path` is set, `caller.command` is null, and `caller.output` is the reason. `reproduced_at` is `seam` and the verdict is whatever the seam said.
- **The seam's argument built by hand.** A run that hands the seam an argument the reproducer constructed has built the same fixture again, whatever it drove on the way there. `caller.search` carries the grep, `caller.path` and `caller.command` whatever was driven, `reproduced_at` is `seam`, and the verdict is whatever the seam said.

A seam-level `NOT_REPRODUCED` stops there with `reproduced_at: seam`; there is nothing left to drive. A caller-level failure is `NOT_REPRODUCED` with `reproduced_at: caller`, and the caller's command and output are the repair evidence.

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

Once the claim's command has run at the seam, find the change's production
callers at HEAD: `git -C TREE grep -n -w <symbol> HEAD -- . ':!*test*'
':!*spec*' ':!*fixture*'`. The claim's own file stays in range, because a
caller often sits in the same file as the seam it calls. The search is wide
and returns prose that only names the symbol, so pick a hit that runs it.
Drive the nearest one, and let the caller build the seam's input out of
whatever you supply at its boundary, rather than handing the seam an argument
you built yourself. Where a command ran, report `reproduced_at` as `caller`
or `seam`, and a `caller` object carrying that search, the caller's path and
the command that drove it, and its real output.

Three runs report `reproduced_at: seam`, and each puts its reason in
`caller.output`. Where no hit runs the symbol, give the search and whatever it
returned, empty or prose. Where the caller needs a live service, credentials
or hardware you do not have, give that reason instead. Where you reached the
seam with an argument you built yourself, say so: that run rebuilt the fixture
however many hops it took to get there.

`reproduced_at` is null wherever no command ran, and two claims reach that: one
that arrived with no command to run, which is `UNVERIFIABLE`, and one whose
change-exists grep came back empty, which is `NOT_REPRODUCED` on that grep.
Nothing ran, so there is no reproduction site to name and no caller to go
looking for.

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
  "verdicts": [{
    "claim": "", "command": "", "output": "", "verdict": "REPRODUCED",
    "reproduced_at": "caller",
    "caller": {"search": "", "path": "", "command": "", "output": ""}
  }],
  "left_checks": [{"what": "", "holds": true, "evidence": ""}]
}
```

`verdict` is `REPRODUCED`, `NOT_REPRODUCED`, or `UNVERIFIABLE`. The three route differently and the difference matters: `NOT_REPRODUCED` is a repair dispatch carrying the run that failed, `caller.command` and `caller.output` where `reproduced_at` is `caller` and the top-level pair otherwise; `UNVERIFIABLE` is a pull-request section naming what nobody could check; `REPRODUCED` is the only one that lets the claim stand.

`reproduced_at` says where the last reproduction ran: `caller` where a production caller drove it, `seam` where the claim's own command was the end of it, and `null` wherever no command ran. Two claims reach null: one that arrived with no command, which is `UNVERIFIABLE`, and one the change-exists grep refuted before its command ran, which is `NOT_REPRODUCED` on that grep. Null is the truthful answer in both, and a site invented to fill the field reaches the pull request as a reproduction a reader can go and repeat. Nothing was searched for on either, so `caller` is null throughout. It sits beside `verdict`, which stays those same three values. `caller` carries the search that looked for callers, the caller driven and the command that drove it, and that command's real output—or, where nothing was driven, the reason in `caller.output` with `path` or `command` null.

`REPRODUCED` with `reproduced_at: seam` is the weaker of the two: the seam held against an input the reproducer built, and no production caller built that input for it. Step 5's verification section marks that claim seam only and names which of the cases above it was.

`holds` is the reproducer's read of a `left` entry's stated reason against the code. `false` with evidence is a finding, and it routes like a `NOT_REPRODUCED` claim.

Saved verbatim to `RUN_DIR/redteam/round-<k>.json`. A verdict file you tidied is a verdict file you partly authored.

## The adversarial-review trigger

`adversarial-review` is the last line of defense here rather than the default red-team. A full parallel fan-out with finders, verifiers, and a failing test before every fix is expensive, and the diffs that earn it are the ones where a quiet wrong answer costs real money, leaks real data, or corrupts real rows.

**The trigger fires where the hunks of `git diff BASE_SHA..HEAD` match the diff signals of rows 1 (money), 2 (authz), or 4 (schema) of `adversarial-review/references/trigger-table.md`, or where `--deep` was passed.**

Two rules on the match:

- **Re-derive the grep from the table at run time.** Read the three rows, pull their signal lists, build the grep. Never copy the signals into this file: the table is upstream, it gains rows and signals, and a copy here becomes a quietly narrower trigger that still looks like the real one.
- **Match whole words and identifiers, case-insensitively — never bare substrings.** `grep -Ei '\b<signal>\b'` over the hunks. The table gives the reason: `index` inside `page_index` files a paging helper as a schema change, and `rate` inside `generate` makes every function a money change. A trigger that fires on everything is a trigger nobody keeps.

Record the outcome in `RUN_DIR/redteam/trigger.txt`. The first line is exactly `fired: yes` or `fired: no`; the lines after it name the rows that matched and the grep that decided it. The resume probe reads the first line and nothing else, so a run interrupted between the trigger and the invocation picks up at the invocation rather than re-deriving the answer, and a note such as `not fired: docs-only diff` cannot read as fired.

Once `adversarial-review` has run and its report has been read, copy the `blocking (REPRODUCED): … UNVERIFIED: …` line from its `ledger.py state` into `RUN_DIR/redteam/ar-state.txt`, with its run directory on the line above. The resume probe reads that file for whether the review finished; the run directory alone exists from preflight onward and says nothing.

Where it fired, invoke `adversarial-review` by name with FIXED_POINT = BASE_SHA, in the work tree. Where `RUN_DIR/redteam/mode.txt` names `adversarial-review`, the Step 0 yes carries into its Step 2 as that question's answer, and the review fans out without asking again, but only while the depth `adversarial-review` derives at its Step 2 is at or below the depth forecast in `mode.txt`. A deeper derived depth answers nothing: the user said yes to the forecast, not to a costlier run. A missing file answers nothing, and the review asks its own question. Read its report and its `escalation.md`, and nothing else from its run directory. Its `--fast` flag pins its own depth and roster size; it has no bearing on whether this trigger fired.
