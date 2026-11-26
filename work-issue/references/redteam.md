# Red-team

Read this at Step 4, and again at Step 8 when the repair's claims come back.

Two mechanisms live here. The **reproducer** takes the worker's claims and tries to break them. The **trigger** decides whether this diff also earns a full `adversarial-review` run, which most diffs do not.

## The reproducer

With `WORK_ISSUE_REPRODUCER` unset or empty, one fresh general-purpose subagent per round: `sonnet` by default, `opus` where any claim's path matches one of the trigger rows below. With it set, the reproducer runs on the executor it names, as [Running on an external executor](#running-on-an-external-executor) describes, and that subagent covers whatever the executor leaves uncovered. The subagent is dispatched, it reports, and it is gone — it never repairs anything it refutes, because an agent that fixes what it found has authored the fix its own verdict now covers.

### What it receives

- the `claims` array out of the final report: `claim`, `path`, `command`, `output`. The reproducer never sees `files_changed`, so `path` is the only file name it has for the change-exists grep, and the only one the `opus` routing reads against the trigger rows
- the `left` array: `what` and `why`
- BASE_SHA and HEAD
- REPAIR_BASE, in a repair round only: the SHA HEAD stood at before the repair whose report this round checks. A build round has none
- the absolute path of the tree
- `RUN_DIR/baseline.txt`, so a failure that was already failing before this run is recognized rather than attributed. A file reading `absent` means the repo has no verification command, so nothing ran before this run and nothing was already failing
- `RUN_DIR/plan.md` as `cat -n RUN_DIR/plan.md` prints it, or `none` where the run has no plan, as on an adopted run. A worker may cite a `plan.md` line in a `left` reason, and the numbered copy is what that citation is checked against. It goes in inline, never as a path: a path names RUN_DIR, and `RUN_DIR/reports/` holds the worker's `summary`

### What it never receives

The worker's reasoning, its `summary`, and any fix it proposed. `adversarial-review` states the rule this copies: "A verifier that shares context with the finder is the same mistake as running several review personas in one window: the reasoning that produced the claim is sitting right there, and agreeing with it is the path of least resistance." It puts the sharpest case on the proposed fix, which "is the finder's reasoning in disguise: a proposed fix tells you what the finder believed the bug was, and a verifier who reads it inherits the belief it was supposed to test independently." The plan is none of these: it is the spec the worker built against, not its reasoning.

A claim is that same object pointed the other way. The worker believed the change works; the reproducer's job is to find out whether the command it ran shows that, and the worker's account of why it works is the one input that would tell it what to conclude.

### Stance

Refutation. The reproducer is not checking whether the claim is plausible or whether the commands look reasonable — it is trying to make each claim fail, and reporting `REPRODUCED` only where it could not. A round that reproduces everything on the first pass and quotes no output it actually saw has agreed rather than verified.

### Prove the change exists first

Every claim rests on some edit. Before running a claim's command, prove that edit shows in the range's per-commit history:

```
git log -p BASE_SHA..HEAD -- <path> | grep -n <symbol>
```

Empty output is the verdict. The claim is `NOT_REPRODUCED` with that grep as its evidence, and the run does not proceed to the claim's command — a suite passing against a file nothing changed is the exact failure this whole step exists to catch, and it passes just as cheerfully for the reproducer as it did for the worker.

Grep the history, because two kinds of true claim cancel out of the net diff, and PR #245 lost one of each to it: a line one commit added and a later commit removed, and an absence claim, whose text no commit adds to the file it is about. A hit proves only that a commit in range touched the symbol, and the claim's command decides whether it survived. An absence claim's `path` is the file whose diff enforces or creates the absence, such as the test that refutes the text or the file a removed line came out of. A claim pathed at the file the text is absent from comes back empty, and `NOT_REPRODUCED` is the right verdict for it.

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
Repair base: REPAIR_BASE = {{REPAIR_BASE}} (`none` in a build round). In a repair round,
judge a `left` reason about the change or the repair, and a claim about the repair
itself, against `git diff REPAIR_BASE..HEAD`. With `none`, judge against
`git diff BASE_SHA..HEAD`. A `left` reason that cites text you were not given,
such as a dispatch's Done-when, is `holds: false` with that as the evidence.

The suite's output before any of this work began, for telling a pre-existing
failure from a new one:

{{BASELINE}}

The run's plan, numbered as `cat -n` prints it, or `none` where the run has
no plan:

{{PLAN}}

A `left` reason that cites a `plan.md` line holds only where that line exists
in the numbered plan and says what the reason claims. A line number past the
end, or a line that says something else, is `holds: false`, and the evidence
quotes what the plan holds at that number or says the plan ends before it.

Claims to break. Each one is a hypothesis, and your stance is refutation:

{{CLAIMS}}

Entries the author chose to leave undone, each with the reason given. Check
each reason against the code, not against whether it sounds reasonable:

{{LEFT}}

For every claim, before you run anything: prove the change the claim rests on shows in the range's per-commit history, with `git log -p BASE_SHA..HEAD -- <path> | grep -n <symbol>`. Where REPAIR_BASE is given above and the claim is about the repair itself ("the repair", "only this line changed"), the range is `REPAIR_BASE..HEAD`. That history keeps a line a later commit removed, which the net diff drops, so a hit proves only that a commit touched the symbol, and the claim's command decides whether the change survived. Empty output means NOT_REPRODUCED, and that grep is your evidence. Do not run the claim's command in that case.

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

`holds` is the reproducer's read of a `left` entry's stated reason against the code. A reason about the change is judged against `git diff REPAIR_BASE..HEAD` where REPAIR_BASE was given, and against `git diff BASE_SHA..HEAD` where it wasn't, so a reason true of the repair alone is not read as false of the whole branch. A reason that cites text the reproducer didn't receive, a dispatch's Done-when for one, comes back `holds: false` with that as its evidence. A reason that cites a `plan.md` line holds only where that line exists in the numbered plan and says what the reason claims; a line number past the end, or a line saying something else, is `holds: false` with what the plan holds there as its evidence. `false` with evidence is a finding, and it routes like a `NOT_REPRODUCED` claim.

Saved verbatim to `RUN_DIR/redteam/round-<k>.json`. A verdict file you tidied is a verdict file you partly authored. The codex path below amends what verbatim means there.

### Running on an external executor

Resolve the executor fresh at the start of every reproducer round, Step 8's included, with `printenv WORK_ISSUE_REPRODUCER` in the orchestrator's environment, and keep the value out of RUN_DIR.

- **Unset or empty:** the subagent above, exactly as described. Save its answer verbatim to `round-<k>.json`, skip `merge-verdicts.py`, and leave `executor.log` untouched. A `codex` on PATH with `WORK_ISSUE_REPRODUCER` unset changes nothing.
- **Set:** the value is exactly three non-empty `:`-separated fields, `<executor>:<model>:<effort>`, each matching `[A-Za-z0-9._-]+`, such as `codex:gpt-6-luna:xhigh`. That character class is what keeps the value from injecting into the shell command below, so check it before any field reaches a command. `codex` is the one supported executor. Any other shape falls back with reason `malformed value`, and any other executor with `unsupported executor <name>`.

The `opus` routing above applies to the subagent only, a fallback subagent included. A fallback subagent routes by the paths of the claims in `uncovered-<k>.json`.

**The codex path**, in order:

1. Write `RUN_DIR/redteam/claims-<k>.json` as `{"claims": [...], "left": [...]}`: the claim and `left` objects this round dispatches, copied from the report in report order. Round k+1 after a `NOT_REPRODUCED` holds only the failed claims. Give each object an integer `"n"`, its 1-based position in its own list: `claims` run 1 to their count, and `left` entries run 1 to theirs separately. `merge-verdicts.py` matches a verdict line to its claim by `n` alone, with the text as a cross-check, because two claims can share their text. It exits 3 on a file whose numbering skips or repeats.
2. Fall back without running codex when the value falls back as above, when `command -v codex` fails (`not on PATH`), when the host cannot run a background command and notify on exit (`no background execution`: a 45-minute run cannot outlive a foreground timeout), or when the round already has `round-<k>.part-*.verdicts.jsonl` files and no `round-<k>.json` (`resumed`: an earlier run was interrupted, and item 3 runs over the lines it left). Otherwise write each part's prompt file and run the invocation below, and read each part's `part <p> exit <n>` line when it returns.
3. Run the merge:

   ```
   work-issue/scripts/merge-verdicts.py --claims RUN_DIR/redteam/claims-<k>.json --parts RUN_DIR/redteam --round <k> --uncovered RUN_DIR/redteam/uncovered-<k>.json --out RUN_DIR/redteam/round-<k>.json
   ```

   Exit 0 ends the round: `round-<k>.json` is written.
4. Exit 1 means claims are uncovered. Dispatch the subagent with `uncovered-<k>.json`'s `claims` and `left` filling `{{CLAIMS}}` and `{{LEFT}}`, each object keeping its `n`. After the verdict JSON shape, add one instruction: each element of `verdicts` and `left_checks` copies the `"n"` of the claim or left entry it answers. Save its answer verbatim to `RUN_DIR/redteam/fallback-<k>.txt`. An element without a recognized `verdict`, without a boolean `holds`, or naming an `n` already covered is rejected and covers nothing.
5. Run the merge again with the subagent's answer:

   ```
   work-issue/scripts/merge-verdicts.py --claims RUN_DIR/redteam/claims-<k>.json --parts RUN_DIR/redteam --round <k> --uncovered RUN_DIR/redteam/uncovered-<k>.json --fallback RUN_DIR/redteam/fallback-<k>.txt --out RUN_DIR/redteam/round-<k>.json
   ```

   Exit 0 ends the round. Exit 1 is a subagent that left claims uncovered. Re-run item 3's command, which restores `uncovered-<k>.json` to item 4's set because the part files are unchanged, re-dispatch the subagent once over it, replace `fallback-<k>.txt` with its answer, and run this command again. A second exit 1 stops the run quoting the script's stderr: a round nobody can fill is a round to stop on, never one to fill by guessing.
6. Exit 3 from any merge stops the run quoting its stderr.

Codex runs at most once per round.

**Fallback reasons.** Every round on this path appends one line to `RUN_DIR/redteam/executor.log`, and Step 8's final report prints that file:

```
round <k>: <executor> <model> <effort>, <c> of <n> claims; fallback: <reason>, <m> to <sonnet|opus> subagent
```

`<c>` is the claims the part files covered, `<n>` the claims dispatched, and `<m>` the claims the subagent was given. A round item 3 closed writes `fallback: none`. A field the value did not supply is `-`. The reason is the first that applies, in backticks: `malformed value`, `unsupported executor <name>`, `not on PATH`, `no background execution`, `resumed`, `exit <n>` where `codex exec` exits non-zero, `cap fired` where it exits `142`, and `uncovered` where codex exited 0 and item 3's merge still exited 1, a verdict line that does not parse included, since the script rejects it and leaves its claim uncovered. A fallback never stops the run, and the subagent sees only what `uncovered-<k>.json` names.

**The invocation**, one per part:

```
perl -e 'alarm shift; exec @ARGV' 2700 codex exec -m <model> -c 'model_reasoning_effort="<effort>"' -s workspace-write -C <tree> --add-dir RUN_DIR/redteam - < RUN_DIR/redteam/round-<k>.part-<p>.prompt.md > RUN_DIR/redteam/round-<k>.part-<p>.log 2>&1; echo "part <p> exit $?"
```

All parts run in one background command, as `( … ) & ( … ) & wait`, the way Step 6's poll uses the host's background execution. Each piece has its reason:

- `- <` feeds the prompt file on stdin. With stdin left open, `codex exec` blocks forever reading it.
- `-s workspace-write`, because `-s read-only` blocks the smoke suites and still produces a report that looks real.
- `--add-dir RUN_DIR/redteam`, because RUN_DIR sits under the git common dir, outside `<tree>`, and the verdicts file has to be writable.
- The 2700-second cap, because a `codex exec` whose stream drops can sit for hours. The cap firing shows as exit `142`.

**The split.** A round with more than 8 claims runs as two parts. Part 1 takes the first ceil(n/2) claims in report order and every `left` entry. Part 2 takes the rest, with `{{LEFT}}` filled as `none`. A round with 8 or fewer claims has only part 1. Each part's verdicts file is `RUN_DIR/redteam/round-<k>.part-<p>.verdicts.jsonl`.

**The prompt file**, `RUN_DIR/redteam/round-<k>.part-<p>.prompt.md`, holds what a subagent dispatch carries for that part: the prompt above filled in from `claims-<k>.json`, so each claim and `left` object keeps its `n`, and REPAIR_BASE filled in or `none`, and `{{PLAN}}` filled in or `none`, then the verdict JSON shape. After both comes the codex addendum below, with `{{VERDICTS_FILE}}` filled as the part's verdicts file by absolute path. The prompt files sit beside the round they fill, under `redteam/`, because the reproducer prompt never passes through `render-prompt.py` and `prompts/` is that script's.

**Saved verbatim, on this path**, means `round-<k>.json` is what `merge-verdicts.py` assembled, every element field-for-field from a verdict line or from the fallback's block. The script exists so that no one, the orchestrator included, edits those elements by hand.

The names this path adds (`claims-<k>.json`, `uncovered-<k>.json`, `fallback-<k>.txt`, `executor.log`, and the part files) never match `round-*.json`, which the resume probe counts. Only the assembled `round-<k>.json` does, and the script writes it last in one write, so a crash anywhere before it resumes as a round not yet run.

### The codex addendum

```
Record each result in a file as you reach it, as well as in your final answer. When a claim is settled, append it to {{VERDICTS_FILE}} as one line of JSON: the same object the verdicts array holds for that claim, with its "claim" text copied exactly as you were given it and its "n" number copied too. Do the same for each left entry: append the same object the left_checks array holds for it, with its "what" text and its "n" copied exactly. Write each line the moment that claim is settled, never in a batch at the end: a run cut off by its time limit keeps every line already written, and a claim with no line is handed to someone else to redo. Append with >>; never rewrite the file. One object per line, with no line break inside it.

Your final fenced json block is still due once every claim is settled.
```

## The adversarial-review trigger

`adversarial-review` is the last line of defense here rather than the default red-team. A full parallel fan-out with finders, verifiers, and a failing test before every fix is expensive, and the diffs that earn it are the ones where a quiet wrong answer costs real money, leaks real data, or corrupts real rows.

**The trigger fires where a changed line of `git diff BASE_SHA..HEAD` matching the diff signals of rows 1 (money), 2 (authz), or 4 (schema) of `adversarial-review/references/trigger-table.md` implements the hazard its row names, as the reading below decides, or where `--deep` was passed.**

Run the match with the script `adversarial-review` ships for it:

```
git diff BASE_SHA..HEAD | adversarial-review/scripts/match-triggers.py rows --only 1,2,4
```

It prints one `<n> <name>` line per matched row. Any output line makes the diff a candidate, and a candidate fires the trigger only where a reading confirms it. Two reasons the match is that script and nothing hand-built:

- **The script reads the table at run time.** No signal is copied into this file: the table is upstream, it gains rows and signals, and a copy here becomes a quietly narrower trigger that still looks like the real one.
- **The script owns the table's matching rules.** Whole words and identifiers, case-insensitively, a trailing `_` as a prefix, a unit only after a digit, and only added or removed lines, never context. The table gives the reason for whole words: `index` inside `page_index` files a paging helper as a schema change, and `rate` inside `generate` makes every function a money change. A trigger that fires on everything is a trigger nobody keeps. Until #157 the table closed on a worked grep recipe, and that recipe, filled in as `grep -Ei '\bround(\b'`, exited 2 on `total = round(amount, 2)` instead of matching it (#114): a grep rebuilt from the prose failed on exactly the money signal this trigger exists for, which is why the script replaced it.

The match is lexical, so it nominates more diffs than earn the review: the English "where" hits authz as SQL `WHERE`, and "default" hits schema as `DEFAULT`. Every lane from #157 through #171 fired that way on a docs or tooling diff, and the user ruled each one a false positive by hand. The reading does that ruling and records it. For a candidate, print each matched changed line:

```
git diff BASE_SHA..HEAD | adversarial-review/scripts/match-triggers.py lines --only 1,2,4
```

Each output line is `<n> <name>`, the path, the signal, and the changed line with its `+` or `-`, tab-separated. Read each printed line in its hunk (`git diff BASE_SHA..HEAD -- <path>`) and give it one verdict. `implements`: the line computes or converts a money or quantity value; adds, removes, or changes a predicate or check deciding which rows or actions a caller can reach; or changes a schema, migration, or constraint. That holds in code, in SQL a program runs (a query string passed to an execute call counts), and in an instruction an agent executes, such as a SKILL.md step. `mentions`: the signal is a word in prose, a heading, a comment or docstring, a ledger row, a test expectation, fixture data, or an example prompt or sample session that names the hazard without changing what anything does. A removed line counts as the change its removal makes. A line the reading cannot settle reads `implements`. The trigger fires on the first `implements` line, and the lines after it need no verdict. `--deep` fires the trigger on its own, with no reading.

A non-zero exit decides nothing, from `rows` or `lines` alike: stop and quote its stderr, since an empty output from a failed run reads as `fired: no`.

Record the outcome in `RUN_DIR/redteam/trigger.txt`. The first line is exactly `fired: yes` or `fired: no`; the lines after it hold the `rows` command and its output lines, verbatim. Where the reading ran, the `lines` command follows, then one line per line read: `implements` or `mentions`, a tab, the `lines` output line verbatim, a tab, and the reason in a few words. Where `--deep` fired it, the line after the `rows` output is `reading: skipped, --deep`. Nothing mechanical checks a verdict, so the per-line record is what a reader audits. The resume probe reads the first line and nothing else, so a run interrupted between the trigger and the invocation picks up at the invocation rather than re-deriving the answer, and a note such as `not fired: docs-only diff` cannot read as fired.

Once `adversarial-review` has run and its report has been read, persist its outcomes first. Delete `RUN_DIR/redteam/ar-state.txt` where an earlier review left one, as the build review's sits on disk when Step 5 item 2 red-teams a fix, so a stop before this review's persist resumes through row 11 rather than past it. Then write the report it printed, verbatim, to `RUN_DIR/redteam/ar-report.md`, replacing any earlier copy, and copy its run directory's `escalation.md` to `RUN_DIR/redteam/escalation.md` where this review wrote one, and delete `RUN_DIR/redteam/escalation.md` where this review wrote none. Step 5 carries the pull-request body's escalated, `UNVERIFIABLE`, and `UNREVIEWED` entries from those two files, and the resume probe treats `ar-state.txt` as the review finished, so both land before it. Then copy the `blocking (REPRODUCED): … UNVERIFIED: …` line from its `ledger.py state` into `RUN_DIR/redteam/ar-state.txt`, with its run directory on the line above. The resume probe reads that file for whether the review finished; the run directory alone exists from preflight onward and says nothing.


Where it fired, invoke `adversarial-review` by name with FIXED_POINT = BASE_SHA, in the work tree. Pass `--deep` on to it where this run carries `--deep`, so the review pins the Depth 2 that Step 0 forecast for a `--deep` run. Where `mode.txt` names `adversarial-review`, hand the review that file's line, verbatim, in the same invocation, as the wrapping skill's confirmation its Step 2 checks the derived depth against: a resumed run has no conversation holding the yes. Put the line last, after the fixed point and any flags, wrapped in double quotes, so the review can tell where it starts and read it as the quoted text its Wrapper confirmation rule names. Where `RUN_DIR/redteam/mode.txt` names `adversarial-review`, the Step 0 yes carries into its Step 2 as that question's answer, and the review fans out without asking again, but only while the depth `adversarial-review` derives at its Step 2 is at or below the depth forecast in `mode.txt`. A deeper derived depth answers nothing: the user said yes to the forecast, not to a costlier run. A missing file answers nothing, and the review asks its own question. Read its report and its `escalation.md`, and nothing else from its run directory. Its `--fast` flag pins its own depth and roster size; it has no bearing on whether this trigger fired.

**After a repair, the trigger re-fires on either of two conditions: the repair's own diff has a line on row 1, 2, or 4 that the reading confirms, or the triage round that repair answered held a row whose Severity is `P0`, `P1`, or `blocking` and the full diff fires the trigger.** The repair's diff is `RUN_DIR/redteam/repair-diff-<k>.patch`, which Step 8 saves before item 2's push, from the SHA in `RUN_DIR/redteam/repair-base-<k>` that Step 7 records before its dispatch to the HEAD the repair left. Item 1 reads that patch after the push, so a rebase that orphans the base leaves the diff it reads unchanged. It never reads the whole branch, which fired the trigger once already at Step 4. The first condition exists because a reviewer can label a real money, authz, or schema bug `P2`. Step 8 item 1 always runs the reproducer over the repair's claims and checks both conditions once it comes back clean. The repair diff's reading runs as above, on the `lines` output of that same patch, in its hunks. A repair whose round held no such row and whose own diff prints no row ends at the reproducer and writes neither file. Otherwise the files are the repair's own: `RUN_DIR/redteam/trigger-repair-<k>.txt` and `RUN_DIR/redteam/ar-state-repair-<k>.txt`, with `k` the triage round. `ar-state-repair-<k>.txt` takes the format above. `trigger-repair-<k>.txt` takes it with one line inserted second, `condition: repair-diff`, `condition: severity`, `condition: both`, or `condition: none`, naming which condition fired, so its first line is still the `fired:` line the resume probe reads. The `condition:` line names the conditions that held after the reading, so a repair whose candidate lines all read `mentions`, in a round with no such row, writes `fired: no` and `condition: none`. `trigger.txt` and `ar-state.txt` stay the build's record. Row 11 reads those two files, and row 17 reads the repair's. Each fix is new code, and new code draws an advisory a notch smaller than the last, so a review that re-fired after every repair almost never came back empty. On cambium #23 and #26 that took 7 repair cycles per lane and about 5 h of review against about 50 min of build, for 1 blocker among about 30 reproduced findings.

**A Step 4 red-team repair re-fires on its own diff alone.** Step 4 runs the build's trigger and any `adversarial-review` while round 1's reproducer runs, so that review covers the HEAD before any red-team repair the reproducer's verdicts send. Once round k+1 over that repair comes back clean, Step 4 item 4 runs `git diff` from the SHA in `RUN_DIR/redteam/redteam-repair-base-<k>` to HEAD as its own command, checks its exit, and reads the output as Step 8 item 1 reads a triage repair's saved patch, and re-fires when a line on row 1, 2, or 4 reads `implements`, whether or not the build review fired. Step 8's severity condition has no counterpart, since a red-team round carries no triage Severity. Its files are `RUN_DIR/redteam/trigger-redteam-repair-<k>.txt`, `RUN_DIR/redteam/ar-report-redteam-repair-<k>.md`, `RUN_DIR/redteam/escalation-redteam-repair-<k>.md`, and `RUN_DIR/redteam/ar-state-redteam-repair-<k>.txt`, with `k` the red-team round the repair answers, in the formats of `trigger.txt`, `ar-report.md`, `escalation.md`, and `ar-state.txt`. The escalation file exists only where that review wrote an `escalation.md`. Step 5 item 5 carries the report and the escalation file into the pull-request body as it carries `ar-report.md` and `escalation.md`. They stay apart from Step 8's `trigger-repair-<k>.txt` family, which is numbered by triage round, so a red-team repair never reads as a triage repair.
