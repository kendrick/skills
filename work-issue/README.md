# work-issue

Advances one GitHub issue from its approved plan to a pull request whose review threads are answered.

## Why This Exists

`divvy-up` stops at a green verify and an assembled diff. Everything after that is the tail nobody writes down: reproducing the worker's claims with something that did not author them, rebasing, pushing, opening the pull request, reading what an external reviewer said, repairing what is in scope, queueing what is not, and answering every thread.

Held in one session's memory, that tail gets re-derived from scratch each time, and it loses the same things in the same order. The session this skill came out of lost five separate edits to silent mutation failures—BSD `sed` refusing a `0,/re/` address, a regex that missed the real symbol, a `perl` guard that matched nothing—and each one produced a passing suite, because the suite ran against a file nothing had changed. And a second issue worked at the same moment surfaces as a rebase conflict four steps later, rather than as a refusal at the gate.

So the loop is written down instead. One invocation advances one issue to its next gate and stops. The run's state lives on disk rather than in the conversation, so a session that dies mid-run resumes by typing the same command again, and a concurrent run is refused at the gate.

## How It Works

Nothing runs until the plan survives a gate with two halves. `check-plan.py` is the mechanical half, and it greps for the shapes a script can see: a plan that never cites the issue, a task that names no files, an open `TODO` marker, an acceptance criterion whose identifier appears nowhere. The judgment half derives the tasks the way `divvy-up` derives them, reading the plan against the issue's acceptance criteria, and a plan thin enough to raise a question is refused with the questions listed rather than asked. A question asked there would be the second confirmation this design forbids. An issue with no plan at all gets the refusal that names `writing-plans`, and the skill plans nothing itself.

Then `check-inflight.py` compares the plan's owned paths against every other run in flight, and an overlap is a hard stop. Two worktrees rewriting one file produce a rebase conflict later on, and a run the user has walked away from cannot resolve it.

You get one question, in one message. It carries `divvy-up`'s shape line quoted as-is, where the work will be isolated, which red-team mode the diff forecast earns, at what depth when that mode includes `adversarial-review`, and the grant to push the issue's branch and open a pull request without asking again. `--dry-run` renders that message and stops.

After yes, the run is unattended unless the real diff trips an `adversarial-review` the confirmation didn't forecast, or forecast at a lower depth. That review then asks its own question, and the run waits for your answer. Contention decides the isolation. A dirty tree or another run in flight takes a worktree beside the repo; a clean tree on the default branch gets the branch in place. It installs, runs the repo's own verification command, and saves the output as a baseline, so a suite that goes red later can be pinned on this run or on the tree it inherited. Then `divvy-up` continues at its dispatch step, with every worker carrying this skill's preamble through `divvy-up`'s `{{CALLER_NOTES}}` seam. A single-task wave can run on a herdr agent; every other shape goes to plain subagents, because a herdr agent takes one prompt at a time and a wave dispatched through it is a wave serialized.

`divvy-up`'s wave gate runs per wave, and the orchestrator commits each wave that passes. Then it invokes `code-review` once over the assembled diff, with the merge-base SHA as the fixed point and the issue as the spec. That read stays in session on the session model, since a worker reviewing its own change is the shape this skill was written against. A Spec finding or a hard Standards violation goes back to the worker that wrote the code, with the finding quoted and that worker's earlier report attached.

The red-team phase turns the worker's report back on itself. Borrowing the rule from `adversarial-review`—a finding is a hypothesis until something that did not author it reproduces it—a claim gets the same treatment. A fresh subagent receives the claims, the two SHAs, the tree path, and the baseline, and nothing else: no reasoning, no summary, no proposed fixes. Its stance is refutation. Before it runs a claim's command it proves at HEAD that the change the claim rests on exists, and it refutes a claim whose change it cannot find, with that grep as the evidence. Once a claim's command holds at the seam, the reproducer searches HEAD for the change's production callers and drives the nearest one, since the caller builds the seam's input by a route no hand-made fixture takes. The verdict names where the last reproduction ran, at the caller or at the seam, and names neither where no command ran at all. A claim that stood up at the seam alone is the weaker verdict, because the seam held against an input the reproducer built itself and no production caller built that input for it. The pull-request body marks such a claim seam only and gives the reason the reproduction went no further. A refuted claim goes back for repair and gets one more round. A claim nobody could verify either way becomes its own section of the pull-request body, so a reader can see what the review never covered. `adversarial-review` itself fires only on the diffs that earn it.

Publishing rebases on the default branch first, and a conflict stops the run with the conflicted paths recorded, because resolving somebody else's change is a judgment call. Verification runs again at the rebased SHA. Every push names its refspec in full. The body goes through `technical-writing`, carries `Closes #N`, and reports the reproducer's commands and output rather than the worker's.

Then it reads what came back. `run-state.py review` polls the pull request and scores every signal against the last push. An approval or a `+1` older than that push cleared an earlier version of the branch and says nothing about this one. A finding is in scope when it points at a line inside the diff, names an acceptance criterion, or names a plan task. The in-scope ones go out as one repair dispatch, gated the way the build was gated. The rest go to a queue carrying the reason each is outside and a recommendation, and the queue lands as one comment on the pull request rather than as filed tickets.

Every thread then gets a reply saying what changed and at which commit, and nothing gets resolved. Marking a thread resolved is the reviewer's act, and taking it from them destroys the only signal they have that anyone read the finding. The final report ends "a human merges" once the review clears — or "waiting on the reviewer" once every finding is answered and the queue published but nothing has cleared the round yet.

An invocation can stop anywhere because the next one works out where it is from scratch. The world outranks the run directory, and the run directory outranks memory. It asks git, `gh`, and herdr first, since a run's own notes are exactly what the crash that stranded it leaves stale. The run directory holds phase outputs—reports, verdicts, triage rows—and never a note saying which phase the run believes it reached, because that note outlives the crash that invalidates it. `run-state.py phase` reads a probe of the world and prints where to pick up.

## Install

```bash
npx skills add kendrick/skills --skill work-issue
```

Or by hand:

```bash
git clone git@github.com:kendrick/skills.git
cp -R skills/work-issue ~/.claude/skills/work-issue
```

Needs a git repo and Python 3 for the three bundled scripts, which are stdlib-only. Needs `gh` authenticated too, since the opening gate cannot read the issue without it and would invent the acceptance criteria. It invokes `divvy-up`, `code-review`, `adversarial-review`, and `technical-writing` by name, and the step that needs a missing one stops and says which. `herdr` is optional; without it the run falls back to `git worktree` and plain subagents.

## Use

Type its name, or let a wave reach it one lane at a time—see the Gotchas for what it does before it spends anything.

```
> /work-issue 42
> /work-issue 42 docs/plans/issue-42.md
> /work-issue 42 --dry-run
> /work-issue 42 --isolate --deep
> /work-issue https://github.com/you/repo/issues/42 --no-isolate
```

Type the same invocation again to resume, plan path included if you passed one. The run probes the world, works out where it stopped, and picks up there. Without a plan path it looks under `docs/plans/` in this repo, then for a path linked from the issue, then for the approved plan in the conversation. It finds a plan you keep anywhere else only if you pass the path or the issue links it, so a resume that drops the path can reach the plan gate with nothing to satisfy it. `--isolate` and `--no-isolate` pin the isolation decision, `--deep` forces `adversarial-review`, and `--dry-run` runs every gate and every derivation while dispatching nothing and pushing nothing.

## What's Here

```
work-issue/
├── SKILL.md                  # the skill — gate, isolate, dispatch, build, red-team, publish, triage, repair, close
├── references/
│   ├── resume.md               # the probe fields and the phase table that places a half-finished run
│   ├── worker-prompt.md        # the preamble every dispatch carries, and the report contract
│   ├── redteam.md              # the reproducer's instructions and the adversarial-review trigger
│   └── triage.md               # scoring review signal, queueing what's out of scope, answering threads
└── scripts/
    ├── check-plan.py           # the mechanical half of the plan gate
    ├── check-inflight.py       # proves no run in flight owns a path this plan owns
    └── run-state.py            # places a run on the phase table; scores a pull request's review
```

## Gotchas

- **It can fire on its own now, and it still stops to ask.** A skill running a wave of issues reaches one lane through it, so the description has to stay where an agent can see it. Nothing dispatches until Step 0 puts the shape in front of you, and the half of that grant covering the push and the pull request is answerable on its own.
- **One confirmation, then it doesn't ask again, with one exception.** The shape, the isolation, the red-team mode, and the push grant are one question. Everything after yes—dispatching, committing, pushing, opening the pull request, pushing repair commits—happens unattended. Only `adversarial-review` can ask again, when the real diff trips a review the confirmation didn't forecast or forecast at a lower depth, and the run waits until you answer. Use `--dry-run` to see the question without answering it.
- **Never the default branch.** Every push names its refspec in full, after checking that the branch isn't the default one. A force push is `--force-with-lease`, and only after the rebase. `gh pr create` always states its base and head. The skill never merges. A human does that, and the run stops one step short of it.
- **`adversarial-review` fires only when the diff earns it.** It matches the committed diff against the money, authz, and schema rows of `adversarial-review`'s own trigger table, re-derived from that table at run time so the rows stay current, and `--deep` fires it outright. A docs-and-types diff gets the lightweight reproducer and nothing heavier. The trigger needs that sibling installed to derive from, and without it the step stops rather than guessing at a signal list.
- **A `+1` clears the run only if it landed after the last push.** It scores every approval and reaction against that push, so an approval of the branch as it stood before your repair commits leaves the run in `findings` or `pending`. It strips `[bot]` before comparing logins, because REST and GraphQL disagree on whether the suffix is there and an unstripped comparison reads one reviewer as two.
- **The queue is never filed.** An out-of-scope finding gets a row, the reason it's outside, and a `file-issue` line for you to run. A walk-away run that files tickets turns one reviewer's aside into backlog nobody triaged, so the deferred-findings comment on the pull request is where that triage happens instead.
- **A plan outside the repo needs the path or an issue link.** The search covers `docs/plans/` in the working tree and nothing else, so a plan you keep in `~/.claude/plans/` or a scratch directory is found only through the path you pass or a link in the issue itself. Miss both and the run falls back to the copy held in the conversation—quietly, and that copy dies with the session, so a resume can reach the plan gate with nothing left to satisfy it. Pass the path on the command line and the next invocation finds it the same way this one did.
- **Resume reads the world, not its own notes.** Nothing on disk records which phase the run thinks it reached, so it probes git, `gh`, and herdr and infers the phase from what exists. It reverts a half-written wave that left no report rather than trusting it.

## Maintainers

The decision ledger and eval suite live in [`_maintenance/work-issue/`](../_maintenance/work-issue/). Every contested choice has a row in [RATIONALE.md](../_maintenance/work-issue/RATIONALE.md), including where each borrowed mechanism came from and everything deliberately cut. Smoke test: `bash tests/work-issue-smoke.sh` from the repo root, which pins the documents and runs the three scripts against fixtures. [EVALS.md](../_maintenance/work-issue/EVALS.md) carries the live end-to-end scenarios, unrun until somebody runs one.

## License

MIT, per the [collection license](../LICENSE). This skill is part of the [skills collection](..).
