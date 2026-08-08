# Constitution: inbox-to-memory eval suite for judgment-dependent behavior (#17)

The job ships a scenario suite for the inbox-to-memory behavior no lint can reach: contradiction detection, unacknowledged tension, scope-tier proposal, and Tier 2 summary and entities. The precedent it follows is `_maintenance/file-issue/EVALS.md`, and the failure it exists to prevent is an eval doc that reads convincingly and grades nothing.

Three deliverables: the doc, purpose-built fixtures, and a staging script that keeps a run out of the committed fixtures. The suite is a specification. Executing it and recording results is separate work.

## Clauses

### C-1: Deliverables land where they belong, and nowhere else

- **text**: The suite is exactly three things — `_maintenance/inbox-to-memory/EVALS.md`, a fixture-staging script at `_maintenance/inbox-to-memory/eval-scope.sh`, and eval fixtures under `tests/fixtures/inbox-to-memory/evals/`. The working tree's diff touches no other path. Nothing under `inbox-to-memory/` changes, because a user who loads the skill should not pay context for the maintainer's test plan.
- **check**: `.agent-guild/scripts/check-diff-scope.py _maintenance/inbox-to-memory/EVALS.md _maintenance/inbox-to-memory/eval-scope.sh tests/fixtures/inbox-to-memory/evals/`
- **severity**: blocker
- **failing example**: The suite written to `inbox-to-memory/EVALS.md`, inside the skill directory every invocation loads.

### C-2: Every scenario carries its own fixture, prompt, and pass conditions

- **text**: Under `## Scenarios`, each scenario heading is followed — before the next scenario heading — by the fixture it runs against, the prompt verbatim, and a table of pass conditions. All three live inside the scenario's own section. A fixture or prompt stated elsewhere in the document does not satisfy the scenario that omits it.
- **check**: checker-judgment: Enumerate the scenario headings in order and check them by number, one at a time. For scenario N, extract only the text between heading N and the next scenario heading — or, for the last scenario, `## Grading` rather than the end of the file — and confirm that slice carries a named fixture, a quoted prompt, and a pass-condition table. Subheadings inside a scenario do not end its slice. Anything found outside the slice under test does not count toward it. Report the result per scenario number, so a document where one scenario in six is short cannot be summarized as passing.
- **severity**: blocker
- **failing example**: Scenario 4 gives a prompt and a table but names no fixture, leaving the reader to carry scenario 3's forward.

### C-3: Every fixture a scenario names actually exists and is opted in

- **text**: Every fixture named in `EVALS.md` exists as a directory under `tests/fixtures/inbox-to-memory/evals/`, and each one satisfies the skill's own opt-in test: `_inbox/` plus either `_memory/` or `entries/`. A fixture the skill would refuse to operate on cannot grade the skill.
- **check**: checker-judgment: Collect the fixture names cited in `EVALS.md` and the directories present under `tests/fixtures/inbox-to-memory/evals/`, confirm the first set is a subset of the second, and confirm each cited directory contains `_inbox/` alongside `_memory/` or `entries/`.
- **severity**: blocker
- **failing example**: The contradiction scenario names `fixture-conflict` while the fixtures directory holds only `fixture-contradiction`.

### C-4: The no-skill baseline is stated per scenario, not once in the preamble

- **text**: Every scenario names what the without-skill run is expected to produce, specifically enough to grade the delta against it. A scenario whose pass conditions describe only the with-skill run fails, and so does one whose baseline is the same generic sentence repeated across sections. The baseline is the step that says whether the skill taught anything, so a baseline that says nothing about this scenario's input has skipped it.
- **check**: checker-judgment: Per scenario section, confirm the no-skill expectation names a specific wrong output — a token the baseline omits, a section it invents, a tier it picks instead — rather than asserting only that the baseline does worse. A sentence that would stay true if pasted into a different scenario, with or without its fixture name swapped, fails whether or not it is repeated verbatim anywhere.
- **severity**: blocker
- **failing example**: Each scenario closes with "run again without the skill and compare," and nowhere does the doc say what the baseline is expected to get wrong.

### C-5: The contradiction scenario runs the full round trip

- **text**: One scenario carries a contradiction from a phase 2.5 flag against a `status: accepted` record, through phase 5 sign-off, into the amend outcome. Its pass conditions name the artifact each step must produce: the inline `[contradicts accepted: [[...]]] <statement> | claims: <what the record says>` flag with both halves present, the line rewritten to `[[<target>|memory — updated]]`, the source note's `id` appended to the target record's `source_refs`, and the amended passage marked `(added YYYY-MM-DD, <note-id>)`. Detection alone is not the round trip.
- **check**: checker-judgment: Confirm all four artifacts appear as pass conditions within that one scenario, and read the fixture to confirm it holds an `accepted` record that the planted input genuinely contradicts.
- **severity**: blocker
- **failing example**: The scenario ends at "the skill flags the contradiction" and never checks that sign-off produced an amended record.

### C-6: Unacknowledged tension gets its own scenario, with the negative case

- **text**: A scenario is dedicated to `[tension: unacknowledged]`, and it grades both branches of the rule at `SKILL.md:122`: flag a slug open across three or more notes, unless the transcript shows someone naming it out loud. The two halves live in different files. The count is over prior notes under `<scope-root>/notes/`, which is where the skill's recurrence grep reads. The acknowledgement is in the `_inbox/` transcript being groomed, because process mode never edits a prior note. A fixture that puts the acknowledgement in a prior note has planted it where the rule does not look.
- **check**: checker-judgment: Confirm the scenario exists and carries both a positive and a negative row. Then read each row's fixture against `SKILL.md:122` and confirm it makes that row's expected outcome the correct one. Both slugs must reach three or more files under `notes/`, so that the negative case turns on the acknowledgement rather than on the count, and the negative fixture's acknowledgement must sit in the `_inbox/` file under grooming.
- **severity**: blocker
- **failing example**: The negative fixture puts "we still haven't answered the freeze-owner question" in a prior note rather than in the inbox transcript. The skill flags the slug, correctly, and the scenario records a failure.

### C-7: Scope proposal is graded at all three tiers, on inputs that carry the deciding signal

- **text**: Scope-proposal accuracy is covered at project, client, and journal, each with a pass condition naming the expected token. One further case carries signals at two tiers at once and expects the narrower token, exercising the tiebreak at `references/scope-decisions.md:21-25`. Tier is proposed from content signals, not from where the scope root sits, so every one of these inputs has to be one `references/scope-decisions.md` actually routes to the tier the scenario expects. The single signal in that reference that is not purely textual — a subject already referenced across two or more of the client's projects — needs its fixture to hold those references in distinct project directories, or the scenario grades a signal that isn't there.
- **check**: checker-judgment: Confirm `[memory candidate: project]`, `[memory candidate: client]`, and `[journal candidate: ...]` each appear as the expected outcome of a distinct input, and that a fourth case presents two tiers of signal and expects the narrower. Then read each input against `references/scope-decisions.md` as a whole, tiebreak included, and confirm the reference routes it to the tier the scenario expects. Where a scenario rests on cross-project recurrence, open the fixture and confirm a second project directory exists and that its notes actually carry the subject.
- **severity**: blocker
- **failing example**: An input carrying only a stakeholder's reporting line, which the reference routes to client, on a scenario expecting `[memory candidate: project]` — correct behavior graded as a failure.

### C-8: Summary and entities are graded against the extract, never against taste

- **text**: The Tier 2 scenario states its pass conditions against the note's emitted extract, on the rule `SKILL.md` already sets: every proposed entity appears verbatim in that note's extract, and the summary asserts no date, name, decision, or outcome the extract does not carry. Only the entity half is machine-enforced (`tier2-entity-unsourced`); the summary half is exactly the judgment this scenario exists to grade, which is why it needs stating rather than delegating. At least one row covers a plausible-but-unsourced summary that must be rejected. No pass condition in this scenario is phrased as quality, usefulness, or readability.
- **check**: checker-judgment: Run `--tier2-extract` against the fixture first, into a scratch directory. Identify the note the scenario grades and confirm the run emitted that note's `<note-id>.extract.md` — not merely that some extract was written, since a mixed fixture emits for its v1 notes while the graded note carries `schema: 2` and produces nothing. Then decide every row of the scenario against that emitted file on disk, not against any extract quoted inside `EVALS.md`, and confirm none is phrased as a quality judgment and that the unsourced row names the specific fabricated fact the file lacks.
- **severity**: blocker
- **failing example**: A mixed fixture where the graded note is already v2. The extract directory is non-empty, so a check that only counts files passes, while the note under test emitted nothing and every row grades a proposal against a file that was never written.

### C-9: The suite invents no vocabulary

- **text**: Every inline token the doc cites is a shape registered in the grammar table at `references/machine-contracts.md`, which is the skill's own registry and declares a token absent from it a lint failure. All ten rows are in scope, not just the candidate flags: this suite is built on `[tension: ...]` and `[open question: ...]` as much as on `[memory candidate: ...]`. The same fidelity holds for the rest of the skill's vocabulary the doc cites — phase numbers, frontmatter keys, `status` values, `memory_type` values, memory folder names, lint failure codes, and scripts under `inbox-to-memory/scripts/` — each appearing in `SKILL.md` or its references with the same spelling and the same meaning. An eval that grades against a token the skill does not emit is worse than no eval, because it fails work that was correct.
- **check**: checker-judgment: Extract tokens the way the skill's own linter does at `scripts/lint-scope.sh:218-230` — strip `[[...]]` wiki links first, then read the bracketed tokens out of what remains. That order is load-bearing and the linter's comment says why: without it an unlabeled wiki link reads as a token named after its filename, and C-5 mandates `[[<target>|memory — updated]]`, which is a link and not a token. Match each surviving token against the grammar table's ten rows, including the enumerated values inside a row's form (`[tension: resolved|deferred|unacknowledged]` admits three, and nothing else — a tightening on the shipped lint, which checks the prefix only). Then extract the remaining vocabulary above and grep each against `inbox-to-memory/SKILL.md` and `inbox-to-memory/references/`. Report any token with no source, any use that contradicts its definition at the source, and any enumerated value outside its row's set. Three things this job authors are out of scope here and checked elsewhere: `eval-scope.sh` and its behavior (C-10), fixture directory names (C-3), and `_maintenance/inbox-to-memory/EVALS.md` itself (C-1).
- **severity**: blocker
- **failing example**: A pass condition expecting `[memory candidate: journal]` — a token the grammar does not define, because journal candidates take no scope token.

### C-10: No scenario writes into a committed fixture

- **text**: `EVALS.md` carries a run procedure — a named section stating the steps that take a reader from a fixture name to a running scenario. That procedure goes through `eval-scope.sh`, which copies a named fixture into a fresh scratch directory outside the repo and prints that path. It stages once per run, not once per scenario: the with-skill and without-skill runs each need their own copy, because the first one empties `_inbox/` and the second would otherwise grade a baseline against nothing. No scenario, and no step of the procedure, names a path under `tests/fixtures/` as the directory the skill is run against. Process mode deletes from `_inbox/` and writes notes into the scope, so an in-place run destroys the fixture on its first use. `tests/inbox-to-memory-smoke.sh:1226` already holds the migration tests to this same rule and says why.
- **check**: checker-judgment: First confirm a run-procedure section exists and names `eval-scope.sh`; if there is no such section this clause fails outright, with no further checking. Then run `eval-scope.sh` against one named fixture and confirm all three of: it prints the staged path; the staged directory is a faithful copy of that fixture, verified by diffing the two trees rather than by the script's own report; and `git status --porcelain` is unchanged from before the run. A script that prints a path and copies nothing satisfies every negative term, so the copy has to be checked positively. Then confirm neither the procedure nor any scenario names a `tests/fixtures/` path as the run target.
- **severity**: blocker
- **failing example**: `eval-scope.sh` mints a scratch directory, prints it, and never copies the fixture into it. Nothing is written outside scratch and git stays clean, so every negative check passes while each scenario runs against an empty directory the skill would refuse as un-opted-in.

### C-11: The existing suites stay green

- **text**: Adding fixtures and a maintainer script breaks nothing already passing. All three smoke suites exit 0 after the change. Two of their checks walk the whole fixtures tree and so reach new directories: `tests/inbox-to-memory-smoke.sh:515` forbids `MEMORY.md`, `INDEX.md`, or `index.md` anywhere under a `*_memory*` path, and the shasum snapshot at `:586` and `:1229` requires the run to leave every fixture file byte-identical. If a new fixture directory turns the suite red, that is a signal about the fixtures, not an invitation to edit the suite — C-1 puts that path out of scope on purpose.
- **check**: `bash tests/inbox-to-memory-smoke.sh && bash tests/file-issue-smoke.sh && bash tests/handoff-smoke.sh`
- **severity**: blocker
- **failing example**: An eval fixture carrying a convenience `_memory/MEMORY.md` index, which the tree-wide `find` rejects and which turns the suite red for the next job's worker.

### C-12: The doc keeps the shape of its precedent

- **text**: `EVALS.md` carries the same top-level shape as `_maintenance/file-issue/EVALS.md`: three sections — `## Fixtures`, `## Scenarios`, `## Grading` — preceded by a method statement naming the with-skill and without-skill delta, whether or not it carries a heading of its own. The precedent writes it as opening prose. The Grading section ships the empty table a run fills in, and that table has a place to record the without-skill result alongside the with-skill one. The delta is what gets graded, so a results table with nowhere to write the baseline loses the measurement the suite was built for.
- **check**: checker-judgment: Compare section headings against `_maintenance/file-issue/EVALS.md`, confirm all three are present with content, and confirm a method statement naming the delta appears somewhere ahead of `## Fixtures`. Then confirm the Grading section provides an actual results table rather than a description of one, and that the table's columns or rows admit both the with-skill and without-skill results for each scenario.
- **severity**: major
- **failing example**: A one-column results table reading `| Scenario | Passed |`, which records whether the skill did well and keeps no trace of what the baseline did.

### C-13: The prose reads as a person wrote it

- **text**: `EVALS.md` and the comments in `eval-scope.sh` read as maintainer documentation, not as generated filler. No bolded inline headers of the `- **Thing:** description` form, no padding to three items where a fourth fits or one can go, no hedging preambles, no sentence that restates its heading. Prose lines in `EVALS.md` are never hard-wrapped — the rule guards against display-time rewrapping, which is a markdown problem. It does not reach comments in `eval-scope.sh`, where source renders verbatim and the neighbouring scripts in `inbox-to-memory/scripts/` all wrap; there, matching them is correct. Dash spacing and heading case follow the neighbouring `_maintenance/file-issue/EVALS.md` rather than any external style rule; this is a maintainer test plan, and matching its precedent beats matching a house voice it never used.
- **check**: checker-judgment: Audit against the `humanizer` patterns, excluding its em-dash and title-case rules. A hard-wrapped prose paragraph in `EVALS.md` is an automatic fail; a hard-wrapped comment block in `eval-scope.sh` is not, and failing one is itself a misreading of this clause. Dash and heading style are judged only against `_maintenance/file-issue/EVALS.md`, and consistency with it is a pass.
- **severity**: major
- **failing example**: A scenario introduced by "This scenario is designed to test three key things:" — a hedged preamble, a padded triple, and a sentence that says nothing the heading did not.

## Protected content

Nothing in this job ships verbatim author words. No manifest.

## Non-goals

- Changing `inbox-to-memory/` itself. If a scenario exposes a skill defect, the finding is filed as an issue, not fixed here.
- Building a graded runner that executes scenarios and scores them. The with-skill and without-skill delta is a human judgment made per run; automating it is a separate job.
- Executing the suite or recording results. This job ships the specification and the empty results table.
- Scaffold mode. The scenarios cover process mode and migrate mode Tier 2, which is where the judgment lives.
- Refreshing the inventories these deliverables make stale: `README.md`'s `_maintenance/` listing and `tests/fixtures/inbox-to-memory/README.md`. Both are known stale and owned elsewhere. C-1 keeps them out of the diff, and a worker that updates them fails that clause.
- Committing or pushing. Work is staged for the user.
