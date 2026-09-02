# AGENTS.md

A collection of agent skills, each installed on its own with `npx skills add kendrick/skills --skill <name>`. The `README.md` says what each one does; this file says how the repo works and what a change to it has to satisfy.

One fact drives most of the rules below: **a skill lands alone**. A user installs `jd-file` and gets that directory and nothing else, so a skill may never import from a sibling. Shared code is vendored, and shared behavior is described in prose that names the other skill without depending on it.

## What a skill ships

Four artifacts. The first two are universal; the last two are the bar a new skill meets, and several early skills predate them:

- `<skill>/SKILL.md` — the agent's document. Frontmatter, then the steps or reference the agent runs.
- `<skill>/README.md` — the human's document. Why the skill exists, the mechanism, install.
- `_maintenance/<skill>/RATIONALE.md` — the decision ledger. Every contested choice gets a row saying why, tiered `[E]` measured, `[P]` reasoned from prior art, `[C]` convention. Sections: Where This Came From, Decision Ledger, Deliberately Not Built, Known Limitations.
- `tests/<skill>-smoke.sh` — the pin. Runs standalone from the repo root.

`SKILL.md` and `README.md` are the only files at a skill's top level. Everything else goes in `references/`, `scripts/`, or `assets/`.

`_maintenance/<skill>/EVALS.md` joins them where a skill needs live subagents to prove it works, since a smoke test cannot. `PROVENANCE.md` joins them where a skill is derived from an upstream project, as `handoff` and `technical-writing` are.

Four skills predate the bar. `databricks-api`, `eli5`, `inbox-to-memory`, and `technical-writing` carry no `RATIONALE.md`, and `databricks-api` and `eli5` have no smoke test. Hold new work to the full bar; leave those alone until someone is changing them anyway.

## Invocation

`disable-model-invocation: true` makes a skill user-invoked, which strips its description from the agent's reach and costs zero context. Choose by the asymmetry: when a misfire is expensive and a miss costs the user one word, take user-invoked. `adversarial-review`, `handoff`, `eli5`, and `divvy-up` are user-invoked for that reason, and each says so in its own body. Everything else carries a trigger-bearing description.

A description that summarizes the workflow becomes a shortcut the model takes instead of reading the body. Write triggers, and let the steps live in the file.

## Vendoring

Shared code is copied byte-identically with a provenance comment naming the source, the date, and the rule that upstream is authoritative: fix the bug there, then re-copy. `scaffold_digest.py` lives in three skills this way, and `paths_overlap` runs in both `adversarial-review` and `divvy-up`.

Copy the docstrings with the code. They record the incidents that set each rule, and a reader who trims them re-introduces the bug they describe.

## Scripts

Standard library only, Python 3, so a skill stays copy-in portable.

A script exists where a job wants a diff tool rather than a fresh act of judgment every run. Where judgment is the job, leave it in the prose.

A script that gates a run, rather than producing an artifact, follows the validator convention `check-territories.py` set and `check-waves.py` follows: exit 0 pass, 1 semantic failure with one line per problem on stderr, 3 usage or unreadable input. The Johnny.Decimal scripts predate it and use their own codes.

## Smoke tests

Two kinds of assertion, and the second is the one people forget. `require_text` pins a load-bearing string. `refute_text` pins a mechanism that was deliberately cut, because every cut in this repo is a reasonable-sounding idea and a well-meaning edit is exactly how it comes back. Each refute should correspond to a row in that skill's Deliberately Not Built table.

**There is no CI.** Tests run by hand from the repo root:

```bash
bash tests/divvy-up-smoke.sh
```

Run every suite a change could touch, not only the one named for the skill. A vendored-predicate edit reaches two suites.

## Prose

Route by artifact, and invoke the skill rather than applying it from memory:

- `SKILL.md`, `AGENTS.md`, anything an agent consumes → the `writing-for-agents` skill. It governs alone; a prose-audit pass on top would sand off the precision it asks for.
- `README.md`, commit messages, PR descriptions, code comments → the `technical-writing` skill, which dispatches to a per-artifact profile and ends in its own audit.

Comment the WHY. A comment that restates well-named code costs a reader attention and buys nothing; a comment naming the constraint that forced this shape earns its line.

## Commits and branches

Conventional Commits, scope is the skill name: `feat(divvy-up):`, `fix(jd-file):`, `docs(inbox-to-memory):`. Lowercase after the colon, no trailing period, imperative mood. Bodies and PR descriptions are never hard-wrapped, and carry no attribution trailer or generated-by footer.

Branch before committing when on `main`. Push when the user asks.

---

## Code Review Rules

For an agent reviewing a pull request against this repo. You are reviewing the diff, not the repo, so a pre-existing problem the diff did not touch belongs in a comment at most.

### Scope

Review what the diff changes, plus anything the diff makes wrong. That second half is where the real findings are here, because this repo's documents cross-reference each other: a step in a `SKILL.md` naming a script flag, a `README.md` describing a mechanism, a smoke test pinning a string, a ledger row justifying a choice. A change to one leaves the other three describing something that no longer exists, and every one of those is a live defect rather than a style note.

Out of scope: the choice of what to build, taste disagreements with a decision that has a ledger row, vendored code that matches its upstream, and prose style that follows the house rules above.

### Severity

**P0 — blocks merge.** The change makes an agent do the wrong thing at runtime. A script that fails on valid input or passes on invalid input. A step that contradicts another document in the same skill. A smoke test that passes while the behavior it names is gone. A `SKILL.md` claiming something its script does not implement. A vendored copy that has drifted from its upstream. Anything that would make a skill destructive or lossy on a user's files.

**P1 — fix before merge, or record why not.** The repo's own discipline is broken, though nothing misbehaves yet. A contested choice with no ledger row. A cut feature with no refute pinning it. A new skill missing one of its four artifacts. A load-bearing string no test pins. A script reaching outside the standard library. Prose that skipped the skill that owns it.

**P2 — non-blocking.** Consistency and craft. Wording that drifts from sibling skills, a heading shape that doesn't match, a comment explaining what rather than why, a test assertion that would pass on unrelated prose.

Codex surfaces P0 and P1 on a pull request and holds P2 back, so the third band is for a reviewer running somewhere that shows everything.

Rank findings most severe first. No quota: zero findings is a real answer, and a manufactured P2 spends the author's attention for nothing.

### Evidence

Every finding names the file and line, quotes the text it is about, and states what breaks. A claim about a comment, a docstring, or a commit message is a claim about the code, so verify it against the code.

Where a finding can be checked by running something, run it and paste the real output. A suite you did not run is a suite nobody ran. At minimum:

```bash
bash tests/<skill>-smoke.sh
```

A finding you cannot reproduce is reported as unverified, with what you tried, rather than dropped or promoted.

### What to check, by artifact

**A new or changed `SKILL.md`.** Frontmatter matches the invocation the body describes. Steps end on completion criteria a reader could fail the agent against. The description carries triggers rather than a summary of the steps. Every file, flag, and command it names exists at this commit.

**A script.** Standard library only. A vendored block is byte-identical to its source and keeps its provenance header. A gating script exits 0/1/3. Feed it a malformed input and confirm it fails rather than passing quietly.

**A smoke test.** Each refute corresponds to a real cut in Deliberately Not Built. Each assertion string is distinctive enough that it cannot pass on unrelated prose. The suite exits non-zero when the thing it pins is removed, which you can check by removing it in a scratch copy.

**A `README.md` or the root `README.md`.** Every claim is true of the `SKILL.md` as it actually stands. Counts and lists are correct against the directory tree.

**A ledger.** Every contested choice in the diff has a row. A row's tier matches its evidence: `[E]` means something was measured, so a row claiming `[E]` for reasoning is itself a finding.

### What not to flag

- Vendored code that matches its upstream. Divergence is the bug; duplication is the design.
- Em dashes chained flush against the text, title-case headings, and lists that keep their bullets. These are house style.
- A decision you would have made differently that carries a ledger row explaining it. Argue with the row if you must, as a P2.
- Missing tests or ledgers on the skills named above as predating the bar, unless the diff is already changing that skill.
- The absence of CI.

### Output

Group findings by severity, most severe first. For each: the file and line, one sentence saying what is wrong, the quoted evidence, and the command that shows it where one exists. Close with what you ran and what you could not check.

State plainly when the diff is clean. A review that found nothing and says so is more useful than one that padded itself to look thorough.
