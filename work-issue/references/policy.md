# Ruling policy

Read this when the invocation carries `--auto-budget`, `--repair-class`, or `--defer-after`. Each flag lets `work-issue/scripts/policy.py` rule one kind of stop before the run asks the user, so a wave lane nobody watches keeps moving where the conductor would answer the same way every time. Every ruling is a line of `policy.py` output, and the run acts on that line.

A run with no policy flag asks at every one of these stops, as it did before these flags existed: `budget` prints `ask`, a red-team `sort` prints `ask` for every finding, and a triage `sort` prints `keep` for every row, which routes it as today.

## The flags

- `--auto-budget <ratio>`: a finite number above 0. At a budget stop, raise the ratio to it once, and past it defer at Step 7.
- `--repair-class <class>`: `unowned-write`, the one class. A finding sorted into it is repaired rather than asked about or deferred, except in a capped round, where the review round cap rules first.
- `--defer-after <k>`: a positive integer. From triage round k on, an in-scope row outside the repair class is deferred rather than repaired.

Step 0 runs `work-issue/scripts/policy.py flags [--auto-budget R] [--repair-class C] [--defer-after K]` before anything is written under RUN_DIR. Exit 0 prints the flags normalized. Exit 3 prints one `policy: --<flag>: <value>` line per bad value: refuse the run quoting them. The flags bind the invocation that carries them and are never written to RUN_DIR, so a resume without them asks at every stop.

## The budget stop

Wherever the Timing paragraph's `budget` check, or a resume probe's `stop` reason, reads over budget, run this before asking:

```
work-issue/scripts/policy.py budget --timing RUN_DIR/timing.log --now "$(date -u +%FT%TZ)" --at <step> --run-dir RUN_DIR [--auto-budget R]
```

`<step>` is the step the stop sits in: 4 for a Step 4 check and resume rows 10, 11, and 20; 7 for a Step 7 check and row 16; 8 for a Step 8 check and row 17. Act on the line it prints:

- `under`: the threshold already stands raised. Continue.
- `raise R`: the script appended `budget-raised R` to `timing.log`, so the raise happens once, and the run reads under at R. Continue without a question. A run already over at R at this stop gets the raise appended and recorded too, and the same call prints `defer` or `ask` instead.
- `defer`: over at R or more at step 7. Write every in-scope row of the newest triage round not yet queued as `in scope; queued: policy: --auto-budget R spent` in its Scope cell and append it to `queue.md` with that reason as Outside-because, as Step 6's review round cap paragraph writes a deferral. Then re-probe: row 17's all-queued leg takes the run to Step 8, which posts the deferred-findings comment and ends at item 5's final report.
- `ask`: the budget stop as today. Past the raised ratio at steps 4 and 8 there is no unqueued row to defer, and skipping a red-team round or a re-fired review would ship claims nobody reproduced.

## The red-team stop

Where two red-team rounds fail in a row, at Step 4 or at Step 8 item 1's red-team, run this on the second failed round k before stopping:

```
work-issue/scripts/policy.py sort --kind redteam --round-file RUN_DIR/redteam/round-<k>.json --round k --plan RUN_DIR/plan.md --run-dir RUN_DIR --root WORKTREE [--repair-class C]
```

It prints one `<id> <ruling>` line per finding: each `NOT_REPRODUCED` verdict, id its `n` or its 1-based position, and each `holds: false` left check as `left-<n>`.

- Every line reads `ask`: stop with the evidence, as today. That's every run without `--repair-class`, a run with no plan, and round k once `policy.log` records a red-team ruling for round k-1, because each failing streak gets one granted round. A ruling for an older round belongs to an earlier streak, so a grant spent at Step 4 leaves Step 8's red-team stops their own.
- `repair`: dispatch the repair for those findings as Step 4 item 4 does, then run round k+1 over them.
- `defer`: append the finding to `queue.md` with Source `red-team`, Finding the claim quoted with its command, Outside because `policy: --repair-class C`, a `file-issue` Recommendation, and Status `queued`, and name it in the pull-request body's "Left out" section with its command. Where every line reads `defer` at Step 4, the run goes on to Step 5. Where every line reads `defer` at Step 8 item 1, the run goes back to Step 8's own flow: item 2 under its ahead-of-origin guard, so nothing pushes when origin already holds HEAD, then items 3 and 4. Step 8 pushed the repair before item 1 red-teamed it, so Step 5 would push again and skip the round's replies.

## Triage from round k

Where the invocation carries `--defer-after K` and Step 6 writes triage round k with k at or above K, run this once the round's rows are written and before the review round cap reads them:

```
work-issue/scripts/policy.py sort --kind triage --round-file RUN_DIR/triage/round-<k>.md --round k --plan RUN_DIR/plan.md --run-dir RUN_DIR --root WORKTREE [--repair-class C] [--defer-after K]
```

It prints one line per in-scope row not yet queued, id the row's `#`.

- `keep`: the row routes as today, the review round cap included.
- `repair`: the row stays `in scope`. Step 7 repairs it in a round below the cap, or with `RUN_DIR/review_loop` present, since then no round is capped. In a capped round the review round cap rules first and the `repair` ruling changes nothing: a `P0` or `blocking` row stops the run for a human, and any other is queued with `review round cap reached (N)`. The `repair` line in `policy.log` then records the ruling, not a repair.
- `defer`: write `in scope; queued: policy: --defer-after K` in its Scope cell and append it to `queue.md` with that reason as Outside-because. Step 8 answers it like any other queued row.

A run with no plan, which an adopted run is, has no `owns` to sort against: every row is `keep` with `--repair-class` set, and `defer` without it.

## The sort

A finding is in the `unowned-write` class when it names a path outside `owns`. It names a path when a token of its text ends in a file extension, or contains `/` and is backticked, starts with `/`, `~`, or `./`, ends in `/`, or holds a dot, so `and/or` and abbreviations such as `e.g.` read as prose. A red-team finding's text is its `claim`, `output`, and `caller.output`. Pasted output names paths no task writes, so the sort strips WORKTREE, given as `--root` and the current directory by default, from an absolute path under it, then drops a Python traceback's `File "..."` path, a path under macOS's `/var/folders/`, and a path with a default `mktemp` component (`tmp.` and six or more letters or digits). A path is outside `owns` when no `Files owned` entry of the plan's `## Waves` table equals it or, for an entry ending in `/`, prefixes it: `scoped-cmd`'s match, no globs.

| Finding | Triage, from round K | Red-team, with `--repair-class` |
| --- | --- | --- |
| names a path outside `owns` | `repair` under `--repair-class`, else `defer` | `repair` |
| cites "Writes outside a task's files" and names no path | `keep` | `ask`, and the whole round asks |
| anything else, a `P0` naming no path or a mode change on an owned file included | `defer` | `defer` |

A citation that names no path is the one finding the script can't sort, since only a reader can tell whether it describes lost data. It never resolves to `defer`: triage rules it `keep`, so it routes as any in-scope row does, the review round cap included, and the red-team stop asks.

The path test is a heuristic, in the sense of the **Heuristic scripts.** rule, and it misreads both ways: a bare repo-relative directory with no dot and no backticks, such as src/lib, reads as prose and can sort a real unowned write `defer`, a one-letter name with a one-letter extension such as a.c reads as an abbreviation, and a path holding a space reads as two tokens. Every `defer` still reaches the deferred-findings comment, where a human rules on it. A finding against the sort built on a constructed token is P1.

## `policy.log`

Every `raise`, `defer`, and `repair` appends one line to `RUN_DIR/policy.log`:

```
- [wave] policy: <run> <stop>: <ruling> (<flag> <value>) — <evidence>
```

`<run>` is RUN_DIR's basename. `<stop>` is `budget at step <n>`, `red-team round <k>`, or `triage round <k>`. `<evidence>` is the `budget` line, or the finding ids with each one's named paths. A line already in the log isn't appended again, so a resumed ruling leaves one line. `ask` and `keep` record nothing, since the user or today's routing decides them. The run never writes under a wave's `facts/`: `work-wave` copies these lines into `facts/wave.md` as each lane reports.

Exit 3 from `budget` or `sort` means an unreadable or malformed timing log, round file, or plan, a bad flag value, or an unwritable log: stop and quote its stderr.
