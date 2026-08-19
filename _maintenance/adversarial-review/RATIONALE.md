# adversarial-review — rationale

Evidence tiers: **[E]** measured or observed in a real run, **[P]** practitioner reasoning from prior art, **[C]** convention inherited from this repo or its neighbors.

## Where This Came From

Four sources, one keeper mechanism each:

- **Pocock's `code-review`** — preflight discipline. Resolve the ref, confirm the diff is non-empty, fail in front of the user rather than inside subagents. Also its refusal to merge findings across axes.
- **`adversarial-reviewer` (alirezarezvani)** — names the self-review trap correctly. Its implementation, personas in one context, does not solve it.
- **A Claude Code Opus session** — genuine subagent isolation, a pre-declared out-of-scope list, escalating context across rounds, hand-verification of every blocker before acting on it.
- **The "MIL method"** — non-overlapping, domain-derived beats. The emotional frame is a confound rather than a mechanism.

All four stop at *report*. Findings arrive as results rather than hypotheses, and nobody reproduces them. That gap is what this skill exists to close.

## Decision Ledger

| # | Decision | Why | Tier |
|---|---|---|---|
| 1 | Verification gate is the confidence mechanism, not multi-agent agreement | Agreement between reviewers who saw the same code is correlation, not corroboration. Reproduction by an agent that never saw the finder's reasoning is independent evidence. This is also what makes disjoint territories coherent: with no overlap there is nothing to agree, so something else has to carry confidence. | [P] |
| 2 | Only REPRODUCED can block | An unreproduced finding is unproven, not merely minor. Letting it block means the reader does the verification the review skipped. | [P] |
| 3 | Territories are literal paths, not globs | The brief specified glob sets. The mechanism this repo actually has (`paths_overlap` / `owns_entry_problem`, agent-guild `check-diff-scope.py`) rejects `*` and `?` outright: "an entry is a literal path, and a pattern here would own nothing." That rejection is load-bearing for upstream issue #162, where a meaningless overlap answer put two agents on one tree. Amending the brief was cheaper than forking the predicate. | [E] |
| 4 | Predicate vendored byte-identical rather than imported | The canonical copy lives in a sibling repo and a version-pinned plugin cache; this skill installs standalone to `~/.claude/skills/`. Vendoring with a provenance comment is the only form that survives installation. Docstrings travel with the code because they record the incidents that set each rule. | [C] |
| 5 | Disjoint ownership, unioned lenses | Strict glob disjointness would make a file that is both authz and money lose one lens. Each file gets exactly one owning territory (so coverage accounting stays exact and overlap stays a hard error), and a territory carries the union of its files' suspicion classes. | [P] |
| 6 | No `disposition` field on a finding | The brief specified `disposition` starting at `UNVERIFIED`, alongside append-only JSONL. Those contradict: a field that later reads `REPRODUCED` is a mutation with extra steps. State is derived from appended events instead, which also preserves when each state landed and who landed it. | [C] |
| 7 | Merge-base SHA pinned in preflight | `git diff main...HEAD` re-resolves `main` on every invocation. Across a multi-day round loop, round 3 would review a different diff than round 1, silently. | [P] |
| 8 | Run dir excluded via `.git/info/exclude`, never `.gitignore` | `.gitignore` is tracked, so editing it adds a change to the diff under review and pollutes the next round's fix intersection. | [P] |
| 9 | Dirty tree stops the run | Verification evidence is only meaningful against the code the diff describes. An override is allowed and recorded as `dirty_tree_accepted`, so the report can say the evidence was gathered under that condition. | [P] |
| 10 | Verifier receives five fields, selected explicitly | `proposed_fix` is the finder's reasoning in another form; a verifier who reads it inherits the belief it was meant to test. Selecting five keys explicitly rather than deleting one means a field added to the schema later cannot leak in by default. | [P] |
| 11 | Unsafe repro commands are UNVERIFIABLE, not run | The verifier executes commands proposed by another agent. Read-only and test-runner commands only; anything that writes, migrates, deploys, or leaves the repo is refused with a recorded reason. | [P] |
| 12 | Failing test before the fix, for blocking findings | A test written after the fix is written by someone who already believes the fix works. Writing it from the repro command first is what makes the finding survive its own fix. | [P] |
| 13 | `file-issue`, looped once per advisory finding | `create-issue` does not exist; the rename to `file-issue` was deliberate (see that skill's ledger). It files exactly one issue per invocation, so N findings means N invocations rather than one call that quietly drops the rest. | [E] |
| 14 | UNVERIFIABLE back-pressure reports, never re-fans-out | A territory that is mostly UNVERIFIABLE is generating untestable claims, which is worth a human's attention and worth fixing in the trigger table. Making it trigger another round would make termination depend on a judgment call, and termination has to stay mechanical. | [P] |
| 15 | Depth governor (0/1/2) | A naive invocation should not cost what a full opus fan-out costs; the source session ran ~31 minutes. Depth is computed from trigger hits and diff size, announced in one line before any subagent spends a token, and overridable with `--fast` / `--deep`. Borrowed wholesale from `file-issue`'s depth ladder, which solves the same problem. | [E] |
| 16 | `disable-model-invocation: true` | Three ambient skills (`code-review`, `security-review`, `grilling`) contend for review vocabulary. The failure modes are asymmetric: a misfire costs a long expensive fan-out on someone who wanted a quick read, a missed trigger costs one sentence naming the skill. Removing this one from ambient arbitration also makes the other three more reliable. Description is therefore human-facing, matching `handoff`. | [P] |
| 17 | Per-run ledger, not per-repo append-only | A per-repo ledger grows without bound and collides finding ids across runs. A run directory is self-contained and survives across sessions, which the round loop and human escalation both need. | [P] |
| 18 | Trigger signals match as whole words, never substrings | Found in the first live eval run. Substring matching filed a paging helper as a schema change because `page_index` contains `index`, and would file every function containing `generate` as a money change because it contains `rate`. A territory built on a false signal hunts the wrong thing with a straight face, and the derivation record makes it look deliberate. | [E] |
| 19 | Row 6 is named `general`, not `tests` | Same eval run. Row 6 owns any file that matched nothing else, and those are rarely test files — a paging helper landing in a territory called "tests" reads as a mistake. Changed test files usually match their subject's row and land with the code they cover, which is the desirable outcome: one finder sees both the change and the test meant to catch it. | [E] |
| 20 | Preflight exclusions apply to the round loop's fix diff, not just round 1 | Found in the first live eval. `__pycache__` artifacts showed up in the fix diff and sent `intersect` to the scope-amendment branch over build output. An amendment rubber-stamped every round stops being a signal, which defeats the point of exiting non-zero on an unowned path. | [E] |
| 21 | Row order in the trigger table is the determinism mechanism | First-match by table order assigns each file its owner. Same diff, same assignment, on any machine and any model. Inserting a row therefore changes derivation for existing diffs, which is why insertion is a deliberate act that belongs in this ledger. | [P] |
| 22 | Fixes are committed before each round, and the cleanliness check re-runs at every fan-out | Step 7's `intersect` compares commits, so an uncommitted fix was invisible to it: the loop printed nothing and exited clean with the fix code never reviewed—a false-clean exit, not just contaminated evidence. The rounds are also exactly when the tree is most likely dirty, yet the porcelain check ran once at preflight. Surfaced by an external review of the skill. | [P] |
| 23 | Disposition routes on `claimed_severity`, bound at finding time | Step 6 routed on "REPRODUCED + blocking" without naming a source for blocking, which left the one gate that claims to be mechanical open to an ad hoc severity call at disposition. `claimed_severity` is the only severity in the system and is fixed before verification, so nobody re-litigates it with a stake in the outcome. The alternative—each trigger-table row declaring what blocks—trades finder miscalibration for class coarseness; it can layer on later as a floor if run data shows finders under-claiming. | [P] |

## Deliberately Not Built

Each of these was in the prior art and was cut. A well-meaning edit is exactly how they come back, so the smoke test refutes the text of each.

| Cut | Why |
|---|---|
| "Each reviewer MUST find ≥1 issue" quota | Unterminatable in a multi-round loop, and it manufactures findings. The verification gate would then spend real time refuting them. |
| Severity promotion on multi-agent agreement | Meaningless once territories are disjoint — there is nobody to agree with. Verification replaces it. |
| Personas as identity (Saboteur, New Hire, Security Auditor) | A persona reviews a money change and an authz change with the same posture. A suspicion class carries the actual question. Their checklists were mined for trigger-table rows; their identities were not kept. |
| A single cross-territory verdict | One axis passing must not mask another failing, and a combined verdict is exactly the artifact that lets it. |
| Emotional or roleplay framing | Not portable to a client repo, and it optimizes for finding volume over calibration. |
| Cross-territory dedupe and re-ranking at ledger time | Two territories reporting one bug is information about the bug. Re-ranking reintroduces the single ordering per-territory verdicts exist to avoid. |

## Known Limitations

- **Territory derivation is grep-driven.** A money bug in a file whose hunks name no money signal lands in whatever territory its first matching row gives it, and gets that territory's lenses. Row 6 (tests) catching every file limits the damage but does not eliminate it.
- **The verifier trusts its own environment.** A repo whose test suite cannot run in the agent's environment produces UNVERIFIABLE across the board. The calibration signal reports this; it cannot fix it.
- **`--report-only` runs the full cost.** It skips the actions in Step 6, not the fan-out or the verification. Use `--fast` to spend less.
- **Three rounds is a guess.** The cap comes from one session where two of three blockers were fix-introduced. It has not been calibrated across repos.
