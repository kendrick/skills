# file-issue Evals

Scenario suite for the skill. Method follows `skill-creator`: for each scenario, run the same prompt twice in one turn — once with the skill loaded, once without — and grade the delta. The no-skill baseline is the step that tells you whether the skill taught anything.

Run everything with `--dry-run`. Nothing gets posted during evaluation.

## Fixtures

Two scratch repos, both throwaway:

- **`fixture-bare`** — git repo, no `.github/`, no CI, one contributor, a `package.json` with a `test` script.
- **`fixture-forms`** — `.github/ISSUE_TEMPLATE/bug.yml` with four fields (two `required`), `.github/ISSUE_TEMPLATE/config.yml` with `blank_issues_enabled: false`, a `CODEOWNERS`, a workflow, and 10 closed issues carrying a `type:` label prefix convention.

## Scenarios

### 1. Trivial — depth floor

**Prompt:** "file an issue to fix the typo in the CONTRIBUTING link on the readme"
**Repo:** `fixture-bare`

| Expect | Pass condition |
| --- | --- |
| Depth | 0, announced |
| Questions | Zero |
| Type | task |
| Rubric | Minimum viable floor only — title, what-and-why, one criterion |
| Output | Rendered draft, nothing posted |

Fails if the skill asks anything at all, or if it inflates a one-line fix into a feature-shaped issue.

### 2. Bug with no reproduction offered

**Prompt:** "auth is flaky, file a bug"
**Repo:** `fixture-bare`

| Expect | Pass condition |
| --- | --- |
| Depth | 1 |
| First question | Steps to reproduce — not environment, not severity |
| Questions | ≤5, one at a time, each naming its slot |
| Rubric | Gate 2 blocks while the repro is prose; passes once it is runnable |
| Output | Observed and expected as separate statements |

The ordering matters more than the count here. Front-loading reproduction is the evidence-backed behavior; asking for the OS version first is the failure.

### 3. Ambiguous feature ask

**Prompt:** "we should probably let people export their data somehow"
**Repo:** `fixture-bare`

| Expect | Pass condition |
| --- | --- |
| Depth | 1 |
| Draft | Problem section states the user need before any solution appears |
| Rubric | ≥1 falsifiable criterion, gated; non-goals surfaced as an unmet default, not blocked |
| Escape hatch | Does **not** fire — one component, few criteria |

Fails if the draft opens with a proposed implementation, or if non-goals get treated as a gate.

### 4. Repo with issue forms

**Prompt:** "file a bug: the export button does nothing on Safari"
**Repo:** `fixture-forms`

| Expect | Pass condition |
| --- | --- |
| Template source | Named as `.github/ISSUE_TEMPLATE/bug.yml`, not `assets/` |
| Structure | Exactly the form's declared fields, in order |
| Required fields | Both filled |
| Labels | Match the observed `type:` prefix convention; no invented labels |
| Invention | No section the form does not declare |

The high-value failure to watch for: filling the form *and then* appending the skill's own sections underneath.

### 5. Agent-targeted bug

**Prompt:** "file a bug for the session timeout race, I'm going to assign it to Copilot"
**Repo:** `fixture-forms`

| Expect | Pass condition |
| --- | --- |
| Depth | 2 (agent-targeted trigger) |
| Code probe | Runs; issue carries real file paths |
| Rubric | Gate 6 enforced — all seven agent-readiness elements |
| Verification command | Taken from the manifest during harvest, **not** asked as a question |
| Label | Ready-for-agent-style label applied only after gate 6 passes |

Asking the user for the test command is the failure mode this scenario exists to catch.

### 6. Spec-sized ask

**Prompt:** "file an issue to rebuild billing — new plans, proration, invoice PDFs, dunning emails, and a self-serve upgrade flow"
**Repo:** `fixture-forms`

| Expect | Pass condition |
| --- | --- |
| Depth | 2 |
| Escape hatch | Fires — ≥7 criteria or ≥4 components |
| Output | Stops, says why, recommends the spec path |
| Posted | Nothing |
| Interview output | Handed over, not discarded |

Two ways to fail: producing one enormous issue anyway, or starting to decompose it here.

### 7. Prose pass — technical-writing installed

**Prompt:** "file a bug: saving a draft clears the labels field"
**Repo:** `fixture-bare`, with the `technical-writing` skill installed

| Expect | Pass condition |
| --- | --- |
| Depth | 1, announced |
| Dispatch | `technical-writing` invoked via the Skill tool, visible in the transcript — not merely narrated as done |
| Ordering | The pass runs after the Step 6 gates and before the duplicate search |
| No reach-past | file-issue invokes no prose auditor directly |
| Facts preserved | Commands, paths, and error output byte-identical before and after the pass |
| Criteria intact | Acceptance criteria may be reworded, but every symbol and condition inside them survives and each stays falsifiable |
| Pre-pass copy | The body as it entered Step 7 was kept, so the two rows above are checkable rather than asserted |
| Depth 0 control | Rerun with `--fast` on a readme-typo task — no Skill dispatch at all |

Fails if the pass runs before the gates, if file-issue reaches past technical-writing to an auditor, or if the pass rewrites a command or drops a symbol from a criterion.

**Run of 2026-08-20, `--dry-run`, against a real defect in this repo.** Depth 1 announced; `technical-writing` invoked via the Skill tool rather than narrated; ordering correct, with the pass after all six gates and before the duplicate search; no reach-past, and `humanizer` fired once from inside `technical-writing` where that skill claims the invocation. Commands, paths, and line numbers came through byte-identical. The Depth 0 control skipped Step 7 with no dispatch.

Three defects in the step's wording surfaced and are fixed: it said the skill returns a revised body when a skill only loads instructions into the same context, which had the runner reinterpreting "apply what comes back" before it could act; the protected list omitted acceptance criteria, so a reword slipped through against a row that demanded byte-identity; and nothing required keeping the pre-pass body, which is what makes the preservation rows checkable at all. The rationale paragraph also moved to the end of the step after the runner reported reading it twice looking for an instruction.

Two findings left open, both older than this change. Step 2's Depth 2 trigger "the issue is destined for a coding agent" and its ceiling "a solo repo with no CI and no templates caps at Depth 1" both fire in this repo and nothing says which wins — here the choice decided whether Step 7 ran at all. And Step 1 sources the verification command from manifest scripts only, so in a repo whose tests live in a bare `tests/` directory the row resolves to `absent` and the command gets synthesized, even though a prior issue in this repo uses `bash tests/file-issue-smoke.sh` for exactly that purpose.

### 8. Prose pass — technical-writing absent

**Prompt:** "file a bug: saving a draft clears the labels field"
**Repo:** `fixture-bare`, with no `technical-writing` skill installed

| Expect | Pass condition |
| --- | --- |
| Completion | Run reaches the write guard — no error, no stall |
| Absence framing | The missing skill is named as absent, not narrated as an audit that ran |
| Body | Identical to what Step 6 passed |
| Output | Rendered draft, nothing posted |

Fails if the missing skill blocks the run, or if the transcript claims a prose pass happened.

*Runner note: technical-writing is installed on the author's machine, so producing the "absent" environment for this scenario needs a scratch skills directory or the installed skill temporarily renamed.*

## Grading

Per scenario, record `passed` plus verbatim `evidence` for each row. The rows are deliberately binary — anything that needs a judgment call is a badly specified expectation, not a hard grading problem.

Watch the with-skill versus without-skill delta on scenarios 2, 4, and 5. Those are the three where a capable model without the skill produces something that looks fine and misses the point: prose reproduction steps, a form ignored in favor of a prettier structure, and an agent-targeted issue with no verification command.
