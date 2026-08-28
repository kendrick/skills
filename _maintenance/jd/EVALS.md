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

**Prompt:** `where do the notes from tuesday's culture club session go`

**Tests:** the low-confidence path, where two IDs in one category are separated by role rather than by subject and both labels carry the same words.

Category 12 holds one market's culture club at `12.01` and, at `12.02`, the community of practice for the people who run those clubs across every market. Session notes could be the record of running `12.01`, or the raw material `12.02` exists to collect. Only the register draws that line: both Overview notes defer to it rather than restating it, and both folder labels contain the words "Culture Club", so a skill matching on the label alone has a coin flip dressed up as an answer.

| Expect | Pass condition |
|---|---|
| Surfaces the ambiguity | Both `12.01` and `12.02` are named, with the role difference stated: the club being run against the practice of running them |
| Reads the register, not the labels | The distinction it draws is the one the register's entries make, which the folder names and Overview notes do not carry |
| Does not silently pick | Either asks, or recommends one and names the runner-up |
| Asks specifically | The question names candidate IDs, never "where should this go?" |
| Stays inside category 12 | Proposes neither a new ID nor an `11.xx` client number; the ambiguity is between two numbers that already exist |

### 3. The vague audit request

**Prompt:** `something feels off with my vault numbering, can you check`

**Tests:** triggering `jd-audit` rather than `jd-file`; running the script instead of eyeballing the tree; reporting without repairing.

The vault has been reconciled, so the validator now returns zero errors and zero warnings. The prompt insists something is wrong and nothing is, which is what gives this scenario its teeth: a model that wants to be useful will find a problem anyway. Detection is covered against seeded drift in `tests/jd-audit-smoke.sh`, so nothing is lost by the live vault being clean.

| Expect | Pass condition |
|---|---|
| Triggers `jd-audit` | Not `jd-file`, despite both concerning numbers |
| Runs the validator | `validate.py` is executed; findings are not produced by reading folders by hand |
| Reports clean as clean | Says the vault has no errors and no warnings, rather than manufacturing drift to match the prompt |
| Adds nothing of its own | No finding appears that the script did not emit |
| Reads the info findings correctly | The empty categories and the two unverifiable links are reported as deliberate, not as work waiting to be done |
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
