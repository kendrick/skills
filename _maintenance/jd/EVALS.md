# JD skills — evaluation scenarios

This repo has no eval harness and no CI, so these run manually and deliberately: someone sits down, runs the prompt, and reads the transcript. Method follows `skill-creator` — run each prompt twice, once with the skill available and once without, and grade the delta.

Client names in the prompts are fictional, matching the ones in `tests/fixtures/jd-audit/`. Swap in real ones when running these against a live vault — the phrasing is what the scenario tests, not the name.

The prompts are written the way the user actually types: lowercase, mid-thought, naming a real thing rather than a category of thing. A prompt that says "use the Johnny Decimal skill to file this" tests nothing, because the hard part of triggering is the phrasing that never mentions the system.

## Fixtures

These run against the live vault, so every scenario is read-only until the user approves an action. Scenario 3 is the exception and is scoped to a dry run.

One deliberate **precision control** is included: scenario 4 must produce no filing action at all. A skill that files it anyway is over-triggering, and over-triggering is harder to notice than under-triggering because the output still looks like work.

## Scenarios

### 1. A real filing question, no system vocabulary

**Prompt:** `got the renewal paperwork for the truck insurance, where does this go`

**Tests:** triggering on plain phrasing; the confidence gate; the confirm-first tier on a new ID; substrate selection with only one substrate in scope.

| Expect | Pass condition |
|---|---|
| Triggers `jd-file` | The skill is consulted without the user naming it or saying "Johnny Decimal" |
| Orients before deciding | Register, constitution, and conventions are read; category 32 is snapshotted across substrates |
| Lands in category 32 | Proposes an ID under `32 Property & Records`, not a new category |
| Stops to confirm | Minting a new ID is proposed and **not** executed before the user answers |
| Names the ID's purpose | The proposed register line says what the number is for, not what file arrived |
| Picks vault only | Does not propose an office or code folder for a 30-39 ID |

### 2. The ambiguous item that should hit the gate

**Prompt:** `where should i put the notes from the thornbridge leadership coaching thing`

**Tests:** the low-confidence path. This is genuinely ambiguous in the real vault — one client holds `11.06` as a delivery engagement and `15.03` as a pursuit, and the coaching stream lives under `11.06`. A skill that answers confidently has guessed.

| Expect | Pass condition |
|---|---|
| Surfaces the ambiguity | Both `11.06` and `15.03` are named, with the difference between them stated |
| Does not silently pick | Either asks, or recommends one and names the runner-up |
| Asks specifically | The question names candidate IDs, never "where should this go?" |
| Respects the groomed scope | Does not propose moving or renaming anything already inside `11.06`, which `inbox-to-memory` owns |

### 3. The vague audit request

**Prompt:** `something feels off with my vault numbering, can you check`

**Tests:** triggering `jd-audit` rather than `jd-file`; running the script instead of eyeballing the tree; reporting without repairing.

| Expect | Pass condition |
|---|---|
| Triggers `jd-audit` | Not `jd-file`, despite both concerning numbers |
| Runs the validator | `validate.py` is executed; findings are not produced by reading folders by hand |
| Finds the known drift | Reports the `11.03` name mismatch, the `15.01`/`15.02` collision, the `Protogen` split, and the fourth-tier numbering |
| Adds nothing of its own | No finding appears that the script did not emit |
| Repairs nothing | No rename, deletion, or folder creation occurs; reconciliation is offered as choices |
| Distinguishes clean from skipped | The report says which checks ran and found nothing, separately from any that did not run |

### 4. Precision control — must NOT trigger a filing action

**Prompt:** `can you summarize what's in 11.09 riverton`

**Tests:** that naming an ID is not the same as asking to file something. This mentions a JD number, a client, and the vault, and a skill keyed on those tokens will fire when it should not.

| Expect | Pass condition |
|---|---|
| No filing | Nothing is created, moved, renamed, or added to the register |
| No audit run | The validator is not invoked; nothing was asked about consistency |
| Answers the question | Responds with a summary of the ID's contents |

A run that consults `jd-file`, decides no action is needed, and answers the question has passed. Consulting a skill is cheap; acting on it unbidden is the failure.

## Recording results

Note for each scenario whether the skill triggered, whether the pass conditions held, and where the with-skill and without-skill runs diverged. A scenario where both runs produce the same answer is not evidence the skill works — it is evidence that scenario cannot discriminate, and it should be replaced.
