# adversarial-review

A code review where findings are hypotheses until something else reproduces them.

## Why This Exists

Most review tooling stops at the report. You get a list of findings, some of them are wrong, and nothing in the process tells you which. So you verify them yourself, or you skip verifying and act on a guess. Either way the review handed you its homework.

The usual fix is to run several reviewers and trust whatever they agree on. That fails in a specific way: reviewers looking at the same code produce correlated findings, so agreement measures similarity rather than truth. Three agents can agree on a bug that isn't there.

This skill swaps the confidence mechanism. Territories don't overlap, so there's nobody to agree with, and instead every finding gets handed to a fresh agent that never saw the reasoning behind it and is told to break it. Only a finding that survives can block a merge. Findings that don't survive still get recorded, with the counter-evidence that killed them, because "we checked and it was fine" is worth knowing.

Then there's the part nobody plans for. In the session this design came out of, two of the three merge-blockers weren't in the original diff at all—they were introduced while fixing the previous round's findings. Code written under review pressure is the most suspicious code in the run, and a review that stops when the first round's fixes land will miss it. So the loop keeps going, re-reviewing exactly the territories a fix touched.

## How It Works

Preflight resolves your fixed point and pins the merge-base SHA, so a branch moving underneath a multi-day review can't silently change what's being reviewed. A bad ref or an empty diff dies here, in front of you, rather than inside six subagents.

Then it greps the diff against a trigger table—money, authz, state transitions, schema, budgets—and partitions the changed files into territories. Each file has exactly one owner, but a territory carries every suspicion class its files earned, so a file that's both an authz change and a money change gets hunted both ways. A script proves the territories don't overlap before anything runs. Overlap is a hard error, not a warning.

One finder per territory, in parallel, each told what to be suspicious of, what's already settled and off-limits, and to trust code over comments. Their findings go into an append-only ledger as claims, not conclusions.

Then the gate. Fresh verifiers get the claim, the quoted code, and the proposed reproduction command—never the finder's reasoning, and never its proposed fix, which is the reasoning wearing a hat. Each finding lands as reproduced, not reproduced, or unverifiable, and it's the routing that makes it matter:

- **Reproduced and blocking** — a failing test gets written from the repro command, before the fix. A test written afterward is written by someone who already believes the fix works.
- **Reproduced and advisory** — off to `file-issue`, repro attached.
- **Not reproduced** — closed in the ledger, counter-evidence recorded.
- **Unverifiable** — filed as an open question for `inbox-to-memory`.

How much this costs scales with what you're reviewing. A docs-and-types diff gets two territories and cheap models; an auth-plus-money diff gets the full fan-out. The depth is announced in one line before any subagent spends a token, so you can correct it.

## Install

```bash
npx skills add kendrick/skills --skill adversarial-review
```

Or by hand:

```bash
git clone git@github.com:kendrick/skills.git
cp -R skills/adversarial-review ~/.claude/skills/adversarial-review
```

Needs a git repo and Python 3 for the two bundled scripts. Both are stdlib-only.

## Use

It only runs when you ask for it by name—see the Gotchas for why.

```
> /adversarial-review main
> /adversarial-review v2.1.0 --deep
> /adversarial-review origin/main --fast
> /adversarial-review abc1234 --max-rounds 1 --report-only
```

## What's Here

```
adversarial-review/
├── SKILL.md              # the skill — preflight, scope, fan-out, ledger, gate, disposition, loop
├── references/
│   ├── trigger-table.md    # diff signals to suspicion classes, and the derivation algorithm
│   ├── finder-prompt.md    # the finder template and its output contract
│   └── verifier-prompt.md  # the verifier template, repro safety rules, event contract
├── assets/                 # the three JSON schemas the scripts enforce
└── scripts/
    ├── check-territories.py  # proves territories disjoint; intersects a fix diff
    └── ledger.py             # appends findings and events, derives state
```

## Gotchas

- **It won't fire on its own.** `code-review`, `security-review`, and `grilling` all answer to similar phrasing, and a misfire here spends a long expensive fan-out on someone who wanted a quick read. Type its name.
- **It asks for a fixed point instead of guessing one.** Guessing produces a thorough review of the wrong code, which looks exactly like a thorough review of the right code.
- **A dirty working tree stops it.** Verification evidence only means something against the code the diff describes. You can override, and the override gets recorded in the report.
- **Territories are literal paths, never globs.** The overlap predicate is vendored from agent-guild, where a pattern entry is rejected outright because it silently owns nothing—which once put two agents on the same file.
- **Findings never get merged across territories.** Two territories reporting the same bug is information about the bug. There's also no single overall verdict, deliberately: one axis passing shouldn't mask another failing.
- **Three rounds, then it escalates to you.** If three rounds of fixes keep introducing new blockers, something structural is wrong and a fourth automated round is less useful than you reading the escalation.
- **`--report-only` still costs a full run.** It skips writing tests and filing issues, not the fan-out. Use `--fast` to spend less.

## Maintainers

The decision ledger and eval suite live in [`_maintenance/adversarial-review/`](../_maintenance/adversarial-review/). Every contested choice has a row in [RATIONALE.md](../_maintenance/adversarial-review/RATIONALE.md), including the five mechanisms from the prior art that were deliberately cut. Smoke test: `bash tests/adversarial-review-smoke.sh` from the repo root. The live planted-bug procedure is in [EVALS.md](../_maintenance/adversarial-review/EVALS.md).

## License

MIT, per the [collection license](../LICENSE). This skill is part of the [skills collection](..).
