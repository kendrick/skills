# Second-opinion audit brief: DEC-audit r3

You are acting as `checker-courier` relaying a decomposition audit for a second opinion. Judge ONLY the material inlined below. You cannot read any repository, run any command, or see anything outside this prompt. Do not assume any command was or could be run on your side; where a check is a script, judge it against the "Evidence collected locally" section.

## What to judge

The documents under audit are four guild task files (T-001 through T-004): the decomposition of a build job into dispatchable work. The job (GitHub issue kendrick/skills#16) adds, to an existing repo: a Tier 2 migration flow (sidecar proposals file; the model fills in `summary` and `entities`; `--tier2 <file> --apply` writes them mechanically) and a standalone `verify-migration.sh`. Neither exists yet. Tier 1 of the migration already shipped at commit `1f17478`. The constitution the tasks cite is inlined below, as is the spec.

Apply this rubric to the decomposition as a whole and to each task:

1. Coverage: every spec requirement and acceptance criterion maps to at least one task, and every constitution clause C-1 through C-16 is cited by at least one task whose check_method actually enforces it. An uncovered requirement or an orphan clause fails.
2. Check-method fidelity: each task's check_method restates the cited clause's own check faithfully — neither narrower (part of the clause goes unverified) nor substituted (a different, weaker check stands in). A check_method that cites a clause and then checks part of it fails.
3. Routing: each task's executor and checker conform to the routing table inlined below — judged on the work the task actually contains, and on the check type its clauses need (a rubric-checked clause needs a judgment checker).
4. Dependencies: the dependency graph is acyclic, every referenced task id exists, and no task depends on an artifact no earlier task produces.
5. Ownership: no two tasks both claim to verify the same clause fragment on the same artifact (double-read), and no fragment of any cited clause is left with no owner.

## Verdict you must produce

Emit ONLY a JSON object with exactly these nine fields:
- "task_id": "DEC-audit"
- "checker": "checker-courier"
- "vendor": "openai"
- "model": "gpt-5.6-terra"
- "verdict": "pass" | "fail" | "blocked"
- "summary": one paragraph
- "findings": array of {"clause_id", "severity", "description", "evidence"} — REQUIRED non-empty if verdict is "fail"; each finding's evidence must be non-empty and cite the inlined material. May be empty on "pass". Advisory notes that do not fail a task belong in "summary", not "findings". For a decomposition finding, put the task id in "evidence" and the governing clause in "clause_id".
- "duration_ms": null
- "cost_usd": null

---

## Routing table (from the orchestrator contract, verbatim)

| Tier | Agent(s) | Use for |
| ---- | -------- | ------- |
| haiku | worker-bulk, checker-deterministic | Mechanical, zero-judgment work; and all deterministic checks (they only run scripts). |
| sonnet | worker-standard | Clear-spec implementation judged on correctness. |
| opus | worker-craft, checker-judgment, auditor | User-facing/taste work; judgment checks; auditing your own work. |
| fable | (override only) | The final escalation rung, and genuinely hard, ambiguous problems. Reserved. |

Route a task by the work, not the default: a mechanical task goes to worker-bulk even inside a taste-heavy job. A clause checked by a script routes to checker-deterministic; a clause checked by a rubric routes to checker-judgment.

---

## Evidence collected locally (pre-run, at eac74fe)

```
C-13 scope check (constitution check field, verbatim): exit 0
C-15 key-order check (constitution check field, verbatim): exit 0 — NOTE_KEY_ORDER holds 17 names, 17+2=19 <= 20
bash tests/inbox-to-memory-smoke.sh: exit 0
bash tests/file-issue-smoke.sh: exit 0
bash tests/handoff-smoke.sh: exit 0
```

Also true of the tree: `inbox-to-memory/scripts/` contains only `collapse-vtt.sh`, `lint-scope.sh`, `migrate-scope.sh` (no `verify-migration.sh` yet); both old-only fixture notes carry a `## Raw Content` heading with a one-line placeholder below it.

---

## Spec (verbatim)

---
source: github-issue
ref: kendrick/skills#16
issue: 16
title: 'inbox-to-memory v2: migration Tier 2, verification, and the journal record'
fetched_at: 2026-08-06T21:33:47Z
---

# inbox-to-memory v2: migration Tier 2, verification, and the journal record

## Parent

#4

## What to build

Tier 2 and the closing verification. Summary and entities are generated per note from extracted sections and never from raw content, presented in the dry-run report for per-file edit or batch approval, gated separately from Tier 1.

After applying, a verification sweep runs the full lint over every migrated file, confirms every pre-existing wiki link still resolves with the id fallback, and asserts that zero files were renamed. Failures get reported loudly and nothing is fixed silently. The run ends by emitting a one-paragraph migration record the user can drop into the scope's patterns journal.

### Acceptance criteria

- [ ] Generated summary and entities derive only from extracted sections
- [ ] Tier 2 approval is separate from Tier 1 and works per-file or batched
- [ ] Rejecting a Tier 2 proposal leaves that note's Tier 1 changes intact
- [ ] Verification runs the full lint over every migrated file
- [ ] Every link resolving before migration resolves after
- [ ] Rename count is asserted at zero via git
- [ ] Verification failures are reported and never auto-repaired
- [ ] The migration paragraph is emitted, and never written anywhere automatically

## Blocked by

- #15 (migration Tier 1)


---

## Constitution (verbatim)

# Constitution: inbox-to-memory v2 — migration Tier 2, verification, and the journal record

Source: `kendrick/skills#16`, spec at `.agent-guild/state/spec.md`. Tier 1 (#15) is already on this branch at `1f17478`; everything below builds on it and must leave it working.

Two shapes were settled with the user before drafting, and every clause assumes them:

- **Tier 2 reaches files through a sidecar.** The migrator emits a per-note extract (sections only) plus a proposals file; the agent fills in `summary` and `entities`; `--tier2 <file> --apply` writes them mechanically. Generation stays with the model, enforcement stays in the script.
- **Verification is its own script.** `inbox-to-memory/scripts/verify-migration.sh <scope> --since <ref>` runs the sweep and prints the record paragraph. It can be run after the fact, against a migration someone applied yesterday.

A note on check methods. `tests/inbox-to-memory-smoke.sh` is this job's own deliverable, so "the suite exits 0" proves only that the worker passed whatever the worker chose to write. Every clause whose failing example lives in the suite therefore routes to `checker-judgment` and names the assertion that must exist, not just the command that must succeed. Only checks that run against something the worker does not author stay deterministic.

## The testability fixture

C-1 and C-2 both need a note whose Raw Content names something its extracted sections never do — old-only has no such note today, since both fixtures carry a one-line placeholder below the fence and every name in them appears in `attendees`. The job adds that seam: an old-only note gains Raw Content naming at least one person or vendor absent from every section above `## Raw Content`. That name is what the two clauses below falsify against, and adding it changes no assertion the Tier 1 suite already makes.

## Clauses

### C-1: Tier 2 input stops at Raw Content
- **text**: The text the migrator hands to Tier 2 generation is produced by the same `extract_body` rule Tier 1's counts already use — it stops at `## Raw Content` and drops HTML comments. No Tier 2 path reads below that fence.
- **check**: checker-judgment: run `bash tests/inbox-to-memory-smoke.sh` (must exit 0), then confirm the suite asserts the Tier 2 extract for the fixture note above omits the raw-content-only name, and that the extract comes from the same `extract_body` awk as the counts rather than a second copy of the rule.
- **severity**: blocker
- **failing example**: the Tier 2 extract for the fixture note contains the raw-content-only name, because the Tier 2 path re-reads the file with a fresh `sed` instead of reusing `extract_body`. The generated summary then quotes a transcript line nobody reviewed.

### C-2: Every written entity is sourced from the extract
- **text**: `--tier2 --apply` refuses any `entities` value that does not appear verbatim in that note's own Tier 2 extract. The refusal names the file and the entity, carries the diagnostic `tier2-entity-unsourced`, and leaves the note unmodified rather than partially written.
- **check**: checker-judgment: confirm `migrate-scope.sh` emits `tier2-entity-unsourced` for an unsourced entity and leaves the note byte-identical when it fires, and that the suite asserts both against a proposals row naming the raw-content-only name from the fixture above.
- **severity**: blocker
- **failing example**: a proposals row lists the raw-content-only name under `entities`, the apply writes it, and `grep '^entities:'` now returns someone the reviewed layer never mentioned.

### C-3: The summary is a reading of the sections and nothing more
- **text**: Each generated `summary` is one line, single-line per the frontmatter contract, and asserts nothing its note's Tier 2 extract does not support. It introduces no dates, names, decisions, or outcomes absent from the extracted sections.
- **check**: checker-judgment: for each migrated note in the run, read the note's Tier 2 extract beside its written `summary` and confirm every claim traces to the extract. Any unsupported claim fails the clause.
- **severity**: blocker
- **failing example**: a note whose sections record only a scoping conversation gets `summary: 'Cutover approved for March.'` — plausible, unsourced, and now indexed as fact.

### C-4: Tier 2 is gated separately from Tier 1
- **text**: `--apply` without `--tier2` completes Tier 1 and writes no `summary` or `entities` key anywhere. Tier 2 approval is granted per file or as one batch, and the dry-run report presents each proposal alongside the note it belongs to so a reviewer can edit one without touching the rest.
- **check**: checker-judgment: run the suite (must exit 0) and confirm it asserts that a Tier-1-only apply against the old-only copy leaves no `summary:` or `entities:` line in any migrated file, and that the dry-run report groups each Tier 2 proposal under its own file.
- **severity**: blocker
- **failing example**: `--apply` writes a summary generated during the dry run, so approving the mechanical tier silently ships the generative one.

### C-5: Rejecting Tier 2 leaves Tier 1 intact
- **text**: Omitting a note from the proposals file, or declining its proposal, leaves that note's applied Tier 1 frontmatter byte-identical to what a Tier-1-only apply produces. A rejected Tier 2 is an absence, never a rollback.
- **check**: checker-judgment: confirm the suite compares a note migrated Tier-1-only against the same note after a `--tier2` apply whose proposals file omits it, and asserts the two are identical.
- **severity**: blocker
- **failing example**: a partial proposals file makes the migrator re-render frontmatter for every note in the scope, and a declined note loses the `last_confirmed` Tier 1 gave it.

### C-6: Verification lints every migrated file
- **text**: `verify-migration.sh` runs `lint-scope.sh` over the scope, reports its failure count, and exits nonzero when the lint finds anything. It reads the lint's exit status rather than grepping its output for a summary line that an aborted run never prints. It reaches the lint as a sibling of itself, resolved from `$(dirname "${BASH_SOURCE[0]}")` the way `tests/inbox-to-memory-smoke.sh:8` resolves the repo root, so a copy of `scripts/` runs that copy's lint. That is not decoration—it is the only seam the abort case below can be tested through.
- **check**: checker-judgment: run the suite (must exit 0) and confirm it asserts both cases. First, a scope with a planted lint defect makes `verify-migration.sh` exit nonzero and name the failure. Second, an *aborting* lint also makes verification exit nonzero **and** report something other than a clean lint: run `verify-migration.sh` from a copy of `inbox-to-memory/scripts/` whose `lint-scope.sh` is a stub that writes one line to stderr and exits 2 with no summary, and confirm the report attributes the failure to the lint's status. The first case alone does not distinguish a correct implementation from a grep-based one: `lint-scope.sh` on the broken fixture prints `failures: 18` **and** exits 1, so both read it the same way. Only the abort case separates them. Two triggers that look like they would work and don't, both because verification refuses the input before the lint is ever reached: removing `yq` from `PATH` fires `verify-migration.sh`'s own preflight, which it carries because both neighbors do (`lint-scope.sh:63`, `migrate-scope.sh:76`); and a not-opted-in directory is rejected by the scope check.
- **severity**: blocker
- **failing example**: verification greps the lint's output for `FAIL` lines, the lint aborts with exit 2 and prints none, the grep comes back empty, and verification reports a clean sweep over a scope it never checked.

### C-7: Every link that resolved before resolves after
- **text**: Verification collects every wiki-link target present in the scope at `--since <ref>` and confirms each still resolves after migration, by filename first and by the trailing ten-character id second. A target that resolved by name before and by id after is a pass; the report says how many took the fallback. Failures carry the diagnostic `verify-link`.
- **check**: checker-judgment: confirm the suite asserts the sweep counts targets from the pre-migration ref rather than the post-migration tree, reports the fallback count, and fails with `verify-link` when a target resolves neither way.
- **severity**: blocker
- **failing example**: the sweep reads links from the migrated tree, so a link deleted during migration is never checked and the run reports every link intact.

### C-8: Renames are asserted at zero
- **text**: Verification reads file statuses from `git diff --name-status -M <since-ref>` and fails on any status other than `M`, naming renames and deletions separately. Failures carry the diagnostic `verify-rename`. The statuses come from the `--since` ref, not from `git status --porcelain`: the script's whole reason to exist standalone is verifying a migration someone already committed, and porcelain reports a clean tree for exactly that case.
- **check**: checker-judgment: run the suite (must exit 0) and confirm it asserts `verify-migration.sh` fails with `verify-rename` for a rename that has been **committed** since the `--since` ref, not merely a rename sitting in the working tree. An implementation reading `git status --porcelain` must fail that assertion.
- **severity**: blocker
- **failing example**: a scope is migrated, the migration is committed, and `verify-migration.sh <scope> --since <pre-migration-ref>` reports `renames: 0` — because porcelain shows zero lines for a clean tree, while `git diff --name-status -M` against the same ref shows `R100` for every renamed note. Verified against a throwaway repo built from the old-only fixture: a committed `git mv` yields 0 porcelain lines and one `R100` line.

### C-9: Verification reports and never repairs
- **text**: A failing verification changes nothing on disk. It prints every failure it found — not the first — and exits nonzero. No path in the script edits, deletes, restores, or re-runs a migration to clear a failure.
- **check**: checker-judgment: confirm the suite asserts a scope with a planted defect is byte-identical before and after a failing `verify-migration.sh` run, and that a run with two planted defects reports both.
- **severity**: blocker
- **failing example**: verification finds a count mismatch and helpfully rewrites the frontmatter key, so the sweep meant to certify the migration becomes an unreviewed second migration.

### C-10: The record is emitted on success, never written
- **text**: A verification that passes ends by printing one paragraph to stdout, carrying the scope, the date, and the run's real counts, for the user to paste into the scope's patterns journal. A verification that fails prints no record — a migration that did not verify has nothing paste-ready to say. Nothing writes the paragraph to a file, and the scope's `patterns-journal/` is never touched.
- **check**: checker-judgment: confirm the suite asserts the paragraph appears in stdout on a passing run with counts matching that run, that no file under the scope contains it afterward, and that a failing run emits no record.
- **severity**: blocker
- **failing example**: a sweep that found a broken link still prints a confident migration record, and the user pastes into the patterns journal a paragraph certifying a migration that failed.

### C-11: A second run stays a no-op, Tier 2 included
- **text**: Re-running the migrator over an already-migrated scope reports everything as already v2 and writes nothing, and a note already carrying `summary` and `entities` is not re-proposed for Tier 2.
- **check**: checker-judgment: confirm the suite extends the existing second-run assertion to a Tier-2-applied scope, asserting both `migrated: 0` and an empty Tier 2 proposal set.
- **severity**: major
- **failing example**: the second run re-proposes summaries for every note because Tier 2 keys off the absence of a proposals file rather than the presence of the keys, and a reviewer approves a second generation over the first.

### C-12: No existing assertion is deleted or weakened
- **text**: The suites may gain assertions and may not lose them. Every `require_*` / `refute_*` call present at `1f17478` still runs and still asserts the same thing; a Tier 1 assertion whose meaning the Tier 2 rework changed gets updated in place, never dropped.
- **check**: checker-judgment: run `git diff 1f17478 -- tests/` and confirm no assertion line was removed or loosened, then run `bash tests/inbox-to-memory-smoke.sh && bash tests/file-issue-smoke.sh && bash tests/handoff-smoke.sh` (all must exit 0).
- **severity**: blocker
- **failing example**: `require_output "$apply_out" "left alone: 0"` is deleted because Tier 2 changed the counter's meaning. All three suites still exit 0, and the migrator's refusal path stops being tested by anything.

### C-13: The diff stays in scope
- **text**: The deliverable touches only the `inbox-to-memory/` skill and `tests/`. No edits to other skills. `.agent-guild/`, `CLAUDE.md`, and `.gitignore` are allowed because the guild install and this job's own state live there — they are the harness, not the deliverable.
- **check**: `test -z "$( { git diff --name-only $(git merge-base main HEAD) -- ':(exclude)inbox-to-memory/' ':(exclude)tests/' ':(exclude).agent-guild/' ':(exclude)CLAUDE.md' ':(exclude).gitignore'; git ls-files --others --exclude-standard -- ':(exclude)inbox-to-memory/' ':(exclude)tests/' ':(exclude).agent-guild/' ':(exclude)CLAUDE.md' ':(exclude).gitignore'; } )"`
- **severity**: blocker
- **failing example**: a convenience helper lands in `handoff/scripts/` because it was useful there too, and a job scoped to one skill has quietly changed another. (Two traps this check is shaped around: reading only the working tree would miss the violation the moment the work is committed, which is why it diffs from the branch point; and `grep -q` reports unreliably in this environment — `grep -cv` counts 41 out-of-scope paths on input where `grep -qv` exits 1 — which is why exclusion happens in the git pathspec and the assertion is on empty output.)

### C-14: The docs describe what ships
- **text**: `SKILL.md`'s Migrate Mode section and `references/migration.md` document `--tier2`, the proposals file, and `verify-migration.sh`, and no longer assert that Tier 2 is unimplemented. The suite pins the new surface the way it already pins the mode's routing row.
- **check**: checker-judgment: confirm `references/migration.md` no longer says Tier 2 "is not implemented here", that both docs describe the sidecar flow and the verification sweep as they actually behave, and that the suite asserts the presence of `--tier2` and `verify-migration.sh` in `SKILL.md` alongside the existing routing-row assertions.
- **severity**: blocker
- **failing example**: both scripts ship and `migration.md` still reads "Tier 2 is tracked in its own ticket and is not implemented here," so the only doc a user reads before running a migration describes a tool that no longer matches it.

### C-15: Tier 2 cannot reach the budget, structurally
- **text**: Tier 2 needs no budget refusal, and this clause is the tripwire keeping that true. The argument has two legs. For the frontmatter Tier 2 itself writes: the note key order holds 17 names, `render_frontmatter` emits one line per key with no comments or blanks, and `summary` and `entities` are already among the 17 — so a rendered note closes on line 19 at worst. For everything else: a note can lint clean at the full 20 lines, since `check_frontmatter` admits comments and blank lines (`lint-scope.sh:174`), but any such note already carries `schema: 2`, and `has_schema_key`'s skip plus the backfill non-goal keep Tier 2's pen off it entirely. Records reach 21 and genuinely can overrun, but they carry neither key, so Tier 2 never touches them and Tier 1's existing refusal still covers them. If a later change grows the note order past 18 names, this clause fails and a real `tier2-budget` refusal becomes a requirement rather than an argument.
- **check**: `test $(( $(sed -n 's/^NOTE_KEY_ORDER="\(.*\)"$/\1/p' inbox-to-memory/scripts/migrate-scope.sh | wc -w) + 2 )) -le 20`
- **severity**: major
- **failing example**: someone adds `reviewed_by` and `review_date` to `NOTE_KEY_ORDER` for an unrelated feature, a full note's frontmatter now closes on line 21, and Tier 2 writes notes past the budget that makes a header read a contract. (Verified both ways: the check exits 0 today and exits 1 against a copy of the migrator with two keys appended.)

### C-16: The prose reads like a person wrote it
- **text**: Every human-facing string this job adds — the migrate-mode section of `SKILL.md`, `references/migration.md`, the record paragraph's template, script header comments, and the commit message — goes through the `humanizer` skill's audit-and-revise loop and carries the house voice: a technical writer in a hurry, comments explaining why rather than what.
- **check**: checker-judgment: read the added prose against the `humanizer` skill's pattern list and against the surrounding files' voice; flag rule-of-three padding, promotional framing, bolded inline headers, and comments that restate the code. Title-case headings and occasional unspaced em dashes are correct here, not findings.
- **severity**: major
- **failing example**: the new migration.md section opens with "This powerful verification sweep ensures a seamless, robust migration experience" and every comment explains what the next line does.

## Protected content

Nothing in this job ships verbatim author words, so there is no passages manifest. The byte-identity guarantee that matters here is the note bodies, and Tier 1 already asserts it in `tests/inbox-to-memory-smoke.sh`.

## Non-goals

- Changing v1 legality. Files with no `schema` key stay legal forever and the lint keeps ignoring them.
- Editing note bodies. Tier 2 writes frontmatter only, same as Tier 1. The one test-side exception is scaffolding rather than migration behavior: the fixture edit above adds Raw Content to an old-only note.
- A `tier2-budget` refusal. C-15 shows Tier 2's own output cannot reach the budget, so the refusal would be dead code. Not because a 20-line note is impossible—one padded with comments lints clean—but because Tier 2 never writes to those, and a note pushed past 20 by keys outside the note order fails `frontmatter-known-keys` (`lint-scope.sh:133`) first, under a diagnostic that names the actual defect. The clause fails if that stops being true.
- Writing to the patterns journal, or anywhere else outside the migrated files.
- Multi-scope or vault-wide runs. One scope per run stays the rule.
- New lint checks unrelated to migration, and any change to the frontmatter contract or token grammar.
- Backfilling `summary` and `entities` on files already carrying `schema: 2`. Tier 2 is part of migration, not a repair pass.
- Retrofitting the Tier 1 refusal list. A `related` entry with a bare id stays a bare id.


---

## Task file T-001.md (verbatim)

---
id: T-001
title: Add the raw-content seam to the old-only fixture
spec: .agent-guild/state/spec.md#what-to-build
clauses: [C-1, C-2, C-12, C-13]
executor: worker-bulk
executor_model: haiku
checker: checker-judgment
check_method: >-
  C-1/C-2 (seam only, the clauses themselves land in T-002): checker-judgment:
  both old-only notes already carry a `## Raw Content` heading, so check the
  content below it, not the heading's presence. Confirm exactly one old-only
  note's Raw Content body now names at least one person or vendor, and that
  name appears nowhere above the `## Raw Content` heading in that note — not in
  attendees, not in any section body. Then verify the handoff record T-002 reads
  from: confirm `## Seam planted` names the note the diff actually shows edited,
  and that the name it records appears BYTE-FOR-BYTE in that note's Raw Content
  and nowhere above the heading. A recorded name that doesn't match the planted
  one fails this task — T-002 builds two blocker-clause assertions from that
  string, and a mistranscribed one makes them pass vacuously.
  C-12: run `git diff 1f17478 -- tests/` and confirm no require_*/refute_*
  line was removed or loosened, then `bash tests/inbox-to-memory-smoke.sh &&
  bash tests/file-issue-smoke.sh && bash tests/handoff-smoke.sh` (all exit 0).
  C-13: run the constitution C-13 script check verbatim (exit 0).
status: pending
retries: 0
max_retries: 2
deps: []
escalations: []
artifacts: []
---

## Spec excerpt

The constitution's "testability fixture" section requires a seam that C-1 and C-2 (built later, in T-002) will falsify against: an old-only fixture note whose Raw Content names something its extracted sections never do.

Do exactly this, nothing more:

1. Pick ONE of the two notes in `tests/fixtures/inbox-to-memory/old-only/notes/` (`2025-11-18-atlas-working-session-P5spzLt4Bz.md` or `2025-11-04-atlas-scoping-call-3iMu15QJ_x.md`). Both already have a `## Raw Content` heading with a one-line placeholder below it — you are replacing that placeholder's content, not adding the section.
2. Replace that placeholder with 2–4 lines of plausible raw transcript content that names at least one person or vendor — a name that appears NOWHERE else in the note: not in `attendees`, not in any section above `## Raw Content`. Invent a distinctive name unlikely to collide (e.g. a vendor like "Meridian Systems" or a person not in attendees).
3. Change nothing else: no frontmatter edits, no section edits above Raw Content, no other fixture files, no test assertions. Every name already in the note stays where it is.

Constraints that make this pass its check:

- The note must remain a valid v1 fixture: the Tier 1 suite (`bash tests/inbox-to-memory-smoke.sh`) must still exit 0 with zero assertion changes. The Tier 1 migrator counts and body-identity assertions must be unaffected — Raw Content sits below the extraction fence (`extract_body` stops at `## Raw Content`), so added lines there change no extract-derived count. If a suite assertion pins this note's byte content or line count, pick the other note or update nothing — report the conflict instead of weakening an assertion (C-12 forbids deleting or loosening any `require_*`/`refute_*`).
- Only files under `tests/fixtures/inbox-to-memory/old-only/` may change (C-13 confines the job's diff; your slice of it is this fixture directory).

When done: set this task's `status` to `needs-check`, list the changed file under `artifacts`, and add a `## Seam planted` section to this task file recording two things T-002 depends on — the note path you edited, and the exact raw-content-only name you planted. Write the name verbatim; T-002's suite asserts against that string.

## Rework diagnosis

<!-- ORCHESTRATOR appends here on each FAIL, copied verbatim from the checker's
verdict Diagnosis. Newest at the bottom, headed with the attempt it addresses
(e.g. "### sonnet r1"). Empty until the first failure. -->

## Courier comparison

<!-- ORCHESTRATOR writes this once the second opinion lands, while #34 is still
open. Read both verdicts directly and record three counts: findings only the
courier raised, findings only the checker of record raised, and the overlap.
Name the clause behind each unique finding — #34 rules on the unique-finding
rate, and a count with no clause attached can't be audited later.

Say which cited clauses were deterministic. Those cross as pre-run output for
the far side to judge, so they agree by construction and are worth nothing as
evidence either way.

A denied or blocked second opinion goes here too, with the reason. An absence
recorded is data; an absence unrecorded reads later as agreement.

This section never reaches the vendor: compose-brief.py extracts only the spec
excerpt and rework diagnosis. -->


---

## Task file T-002.md (verbatim)

---
id: T-002
title: Tier 2 sidecar in migrate-scope.sh, with suite assertions
spec: .agent-guild/state/spec.md#what-to-build
clauses: [C-1, C-2, C-3, C-4, C-5, C-11, C-12, C-13, C-15, C-16]
executor: worker-standard
executor_model: sonnet
checker: checker-judgment
check_method: >-
  C-1: checker-judgment: resolve the raw-content-only name yourself from the
  fixture — read the seam note and take the name that appears below
  `## Raw Content` and nowhere above it — rather than trusting T-001's
  `## Seam planted` self-report. Then run the suite (exit 0) and confirm it
  asserts the Tier 2 extract for that note omits THAT name, and that the extract
  comes from the same extract_body awk as the counts, not a second copy of the
  rule. An assertion written against a string absent from the note passes
  vacuously and fails this clause. C-2: checker-judgment: confirm migrate-scope.sh
  emits tier2-entity-unsourced for an unsourced entity and leaves the note
  byte-identical when it fires, and that the suite asserts both against a
  proposals row naming the raw-content-only name. C-3: checker-judgment: apply
  the clause's own check — for every note the suite's Tier 2 runs migrate, read
  that note's emitted extract beside its written summary and confirm every
  claim traces to the extract; any unsupported claim fails the clause, and the
  suite's own fixture summaries are in scope for this read. Then confirm the
  two mechanical halves: the apply refuses a multi-line summary value with a
  named diagnostic and leaves the note unmodified, and the suite asserts
  lint-scope.sh exits 0 over a Tier-2-applied scope. C-4: checker-judgment: confirm the suite
  asserts a Tier-1-only apply leaves no summary:/entities: line anywhere, that
  the dry-run report groups each proposal under its own file, and that approval
  works both per-file (a proposals file covering a subset applies only that
  subset) and batched (a full proposals file applies everything). C-5:
  checker-judgment: confirm the suite compares a note migrated Tier-1-only
  against the same note after a --tier2 apply whose proposals file omits it, and
  asserts byte identity. C-11: checker-judgment: confirm the suite asserts a
  second run over a Tier-2-applied scope reports migrated: 0 and an empty
  proposal set. C-12: run `git diff 1f17478 -- tests/` (no assertion removed or
  loosened) and all three suites (exit 0). C-13: run the constitution C-13
  script check verbatim (exit 0). C-15: run the constitution C-15 script check
  verbatim (exit 0) and confirm NOTE_KEY_ORDER was not grown. C-16:
  checker-judgment: read every comment and user-facing string this task added to
  migrate-scope.sh — including the Tier 2 diagnostics' wording and any new
  header comments — against the humanizer skill's pattern list and the file's
  existing voice; flag comments that restate what the next line does rather than
  why it's there, rule-of-three padding, and promotional framing.
status: pending
retries: 0
max_retries: 2
deps: [T-001]
escalations: []
artifacts: []
---

## Spec excerpt

Build migration Tier 2 in `inbox-to-memory/scripts/migrate-scope.sh` (365 lines today; Tier 1 shipped at `1f17478`), plus the smoke-suite assertions that pin it. Two design shapes are settled premises, not open questions:

**The sidecar shape.** Tier 2 reaches files through a sidecar, in two runs:

1. **Extract run**: the migrator emits, per v1 note, a Tier 2 extract (the note's sections only) plus one proposals file for the scope. The extract MUST be produced by the same `extract_body` awk rule Tier 1's counts already use (it stops at `## Raw Content` and drops HTML comments — see `extract_body` at `migrate-scope.sh:123`). No Tier 2 path reads below that fence, and no second copy of the extraction rule may exist.
2. **Apply run**: the agent (not this script) fills `summary` and `entities` into the proposals file; `--tier2 <file> --apply` then writes them mechanically. Generation stays with the model; enforcement stays in the script.

**Separate gating.** `--apply` without `--tier2` completes Tier 1 and writes no `summary` or `entities` key anywhere. The dry-run report presents each Tier 2 proposal grouped under the note it belongs to, so a reviewer can edit one without touching the rest. Approval works per-file (a proposals file covering a subset of notes applies only that subset) or as one batch (a full proposals file).

Behavior the suite must pin (each of these is a constitution clause — the checker will look for the assertion, not just a green suite):

- **Sourced entities (C-2)**: `--tier2 --apply` refuses any `entities` value not appearing verbatim in that note's own Tier 2 extract. The refusal names the file and the entity, carries diagnostic `tier2-entity-unsourced`, and leaves the note unmodified — never partially written. The suite must assert this against a proposals row naming the raw-content-only name T-001 planted in the old-only fixture (that name is in the note but BELOW the fence, so it must be refused).
- **Extract stops at the fence (C-1)**: the suite must assert the emitted extract for the seam note omits the raw-content-only name. Read which note that is — and the exact name — from the `## Seam planted` section of `.agent-guild/state/tasks/T-001.md`, which records both. T-001 could have seeded either old-only note, so do not assume.
- **Summaries trace to the extract (C-3)**: this clause has a judgment half and a mechanical half, and the judgment half is the substance.

  *Judgment half*: every `summary` written in a Tier 2 run asserts nothing that note's own extract does not support — no dates, names, decisions, or outcomes the extracted sections don't carry. The clause's failing example is a note whose sections record only a scoping conversation getting `summary: 'Cutover approved for March.'` — one line, lint-clean, and false. That is the shape to avoid. This applies to the summaries YOU author in the suite's proposals fixtures: the checker will read each one beside its note's emitted extract and fail the clause on any claim that doesn't trace. Write fixture summaries that are demonstrably readings of their sections, and keep the extract for each fixture note recoverable so that read is possible.

  *Mechanical half*: `summary` is one line. Enforce it — `--tier2 --apply` refuses a proposals row whose summary value spans multiple lines (or embeds a newline), with a named diagnostic in the house `tier2-*` style, leaving the note unmodified the same way `tier2-entity-unsourced` does. Assert the refusal in the suite, and assert `lint-scope.sh` exits 0 over a Tier-2-applied scope.

  Do not try to make the script validate traceability — a script cannot decide whether a claim is supported, which is why C-3 routes to a judgment checker.
- **Rejection is absence (C-5)**: a note omitted from the proposals file keeps applied Tier 1 frontmatter byte-identical to a Tier-1-only apply. Never re-render other notes because the proposals file is partial.
- **Idempotence (C-11)**: re-running over a Tier-2-applied scope reports `migrated: 0` and proposes nothing — key off the presence of `summary`/`entities` keys, not the absence of a proposals file.
- **No budget refusal (C-15)**: do NOT add a `tier2-budget` refusal and do NOT grow `NOTE_KEY_ORDER` (17 names; `summary` and `entities` are already among them). A rendered note closes on line 19 at worst.

House constraints:

- Only `inbox-to-memory/` and `tests/` may change (C-13).
- The suites may gain assertions and may not lose them (C-12): every `require_*`/`refute_*` present at `1f17478` still runs and asserts the same thing. Baseline: all three suites (`tests/inbox-to-memory-smoke.sh`, `tests/file-issue-smoke.sh`, `tests/handoff-smoke.sh`) exit 0 before and after.
- Match the existing script's idiom: `yq` preflight, `fail`-style diagnostics, work under a temp dir, refusal counters. Comments explain why, not what.
- The suite's migration section starts at `tests/inbox-to-memory-smoke.sh:532`; the throwaway-repo harness at :566-575 is the pattern for building a scope to migrate.
- Do not touch `SKILL.md` or `references/` — docs are T-004.
- Environment gotcha: `grep -q` is unreliable here (an RTK hook rewrites commands; `grep -cv` and `grep -qv` have disagreed on identical input). In suite assertions, prefer capturing output and testing with `test -z`/`test -n` or comparing counts, the way the existing suite does.

When done: set this task's `status` to `needs-check` and list changed files under `artifacts`.

## Rework diagnosis

<!-- ORCHESTRATOR appends here on each FAIL, copied verbatim from the checker's
verdict Diagnosis. Newest at the bottom, headed with the attempt it addresses
(e.g. "### sonnet r1"). Empty until the first failure. -->

## Courier comparison

<!-- ORCHESTRATOR writes this once the second opinion lands, while #34 is still
open. Read both verdicts directly and record three counts: findings only the
courier raised, findings only the checker of record raised, and the overlap.
Name the clause behind each unique finding — #34 rules on the unique-finding
rate, and a count with no clause attached can't be audited later.

Say which cited clauses were deterministic. Those cross as pre-run output for
the far side to judge, so they agree by construction and are worth nothing as
evidence either way.

A denied or blocked second opinion goes here too, with the reason. An absence
recorded is data; an absence unrecorded reads later as agreement.

This section never reaches the vendor: compose-brief.py extracts only the spec
excerpt and rework diagnosis. -->


---

## Task file T-003.md (verbatim)

---
id: T-003
title: verify-migration.sh, with suite assertions
spec: .agent-guild/state/spec.md#what-to-build
clauses: [C-6, C-7, C-8, C-9, C-10, C-12, C-13, C-16]
executor: worker-standard
executor_model: sonnet
checker: checker-judgment
check_method: >-
  C-6: checker-judgment: run the suite (exit 0) and confirm both cases are
  asserted: a planted lint defect makes verify-migration.sh exit nonzero,
  report the lint's failure count, and name the failure; and an aborting lint —
  the suite runs verify-migration.sh from a copy of inbox-to-memory/scripts/
  whose lint-scope.sh is a stub writing one stderr line and exiting 2 with no
  summary — also makes verification exit nonzero with a report attributing the
  failure to the lint's exit status. Confirm the script reads the lint's exit
  status, resolves the lint as a sibling via dirname "${BASH_SOURCE[0]}", and
  carries its own yq preflight. C-7: checker-judgment: confirm the suite asserts
  the link sweep counts targets from the pre-migration --since ref, reports the
  id-fallback count, and fails with verify-link when a target resolves neither
  way. C-8: checker-judgment: confirm the suite asserts verify-migration.sh
  fails with verify-rename for a rename COMMITTED since the --since ref (an
  implementation reading git status --porcelain must fail this), and for a
  committed deletion, with renames and deletions named separately. C-9:
  checker-judgment: confirm the suite asserts a scope with a planted defect is
  byte-identical before and after a failing run, and a run with two planted
  defects reports both. C-10: checker-judgment: confirm the suite asserts the
  record paragraph appears on stdout on a passing run with that run's real
  counts, that no file under the scope contains it afterward, and that a
  failing run emits no record. C-12: run `git diff 1f17478 -- tests/` (no
  assertion removed or loosened) and all three suites (exit 0). C-13: run the
  constitution C-13 script check verbatim (exit 0). C-16: checker-judgment: read
  verify-migration.sh's header comment, its inline comments, and its failure and
  report strings against the humanizer skill's pattern list and the voice of
  lint-scope.sh and migrate-scope.sh; flag comments that restate what the next
  line does rather than why it's there, rule-of-three padding, and promotional
  framing. The record paragraph's final prose is T-004's, not this task's.
status: pending
retries: 0
max_retries: 2
deps: [T-002]
escalations: []
artifacts: []
---

## Spec excerpt

Create `inbox-to-memory/scripts/verify-migration.sh` — it does not exist — plus the smoke-suite assertions that pin it. It is a standalone verification sweep: `verify-migration.sh <scope> --since <ref>`, runnable after the fact against a migration someone applied and committed yesterday. That standalone-ness dictates several shapes below.

What a run does:

1. **Refuse bad input first**: not-a-directory and not-an-opted-in-scope (needs `_inbox/` plus `_memory/` or `entries/`) exit 2 with one stderr line, same idiom as the neighbors. Carry your own `yq` preflight exactly like `lint-scope.sh:63` and `migrate-scope.sh:76` do — verification must fail on its own terms when the tool is missing, not inside the lint.
2. **Lint sweep (C-6)**: run `lint-scope.sh` over the scope and read its EXIT STATUS — never grep its output for a summary line an aborted run never prints. Report the lint's failure count when it ran, or attribute the failure to the lint's exit status when it aborted (exit 2 before any summary). Resolve the lint as a sibling of this script — `"$(dirname "${BASH_SOURCE[0]}")/lint-scope.sh"`, the way `tests/inbox-to-memory-smoke.sh:8` resolves the repo root — so a copy of `scripts/` runs that copy's lint. The suite tests the abort case through exactly that seam: a copied `scripts/` dir whose `lint-scope.sh` is a stub exiting 2.
3. **Link sweep (C-7)**: collect every wiki-link target present in the scope at `--since <ref>` (from git history, NOT the migrated tree — a link deleted during migration must still be checked) and confirm each still resolves after: by filename first, by the trailing ten-character id second. Resolving by id where it used to resolve by name is a pass; report how many took the fallback. Unresolvable targets fail with diagnostic `verify-link`.
4. **Rename sweep (C-8)**: read file statuses from `git diff --name-status -M <since-ref>` and fail on any status other than `M`, naming renames and deletions separately, diagnostic `verify-rename`. Never `git status --porcelain` — it reports a clean tree for exactly the committed-migration case this script exists for.
5. **Report, never repair (C-9)**: a failing run prints EVERY failure it found, changes nothing on disk, and exits nonzero. No path edits, deletes, restores, or re-runs anything.
6. **The record (C-10)**: a passing run ends by printing one paragraph to stdout — scope, date, the run's real counts — for the user to paste into the scope's patterns journal. A failing run prints no record. Nothing writes the paragraph to any file; `patterns-journal/` is never touched. (T-004 will own the paragraph's prose; write it plainly here and expect T-004 to polish the template.)

Suite assertions the checker will look for (build scopes with the throwaway-repo harness at `tests/inbox-to-memory-smoke.sh:566-575`; migrate with the existing Tier 1 `--apply`):

- Planted lint defect → nonzero exit, failure count reported, failure named (C-6 first case).
- Stub-lint abort → nonzero exit, report attributes the failure to the lint's status (C-6 second case).
- Link deleted during migration → `verify-link` failure; fallback count reported (C-7).
- COMMITTED rename since `--since` → `verify-rename`; committed deletion → named separately (C-8). Commit the rename in the throwaway repo — a working-tree rename doesn't discriminate porcelain from diff.
- Failing run leaves the scope byte-identical; two planted defects both reported (C-9).
- Passing run: record paragraph on stdout with matching counts; no file under the scope contains it; failing run emits none (C-10).

House constraints:

- Only `inbox-to-memory/` and `tests/` may change (C-13). Do not touch `SKILL.md` or `references/` — docs are T-004.
- Suites gain assertions, never lose them (C-12); all three suites exit 0 before and after.
- Match the house idiom: bash, `set -euo pipefail` semantics as the neighbors have them, `fail`-style diagnostics, comments explain why.
- Environment gotcha: `grep -q` is unreliable here (an RTK hook rewrites commands). Prefer capturing output and testing with `test -z`/`test -n` or counting, in both the script and the suite.

When done: set this task's `status` to `needs-check` and list changed files under `artifacts`.

## Rework diagnosis

<!-- ORCHESTRATOR appends here on each FAIL, copied verbatim from the checker's
verdict Diagnosis. Newest at the bottom, headed with the attempt it addresses
(e.g. "### sonnet r1"). Empty until the first failure. -->

## Courier comparison

<!-- ORCHESTRATOR writes this once the second opinion lands, while #34 is still
open. Read both verdicts directly and record three counts: findings only the
courier raised, findings only the checker of record raised, and the overlap.
Name the clause behind each unique finding — #34 rules on the unique-finding
rate, and a count with no clause attached can't be audited later.

Say which cited clauses were deterministic. Those cross as pre-run output for
the far side to judge, so they agree by construction and are worth nothing as
evidence either way.

A denied or blocked second opinion goes here too, with the reason. An absence
recorded is data; an absence unrecorded reads later as agreement.

This section never reaches the vendor: compose-brief.py extracts only the spec
excerpt and rework diagnosis. -->


---

## Task file T-004.md (verbatim)

---
id: T-004
title: Docs and the migration record paragraph
spec: .agent-guild/state/spec.md#what-to-build
clauses: [C-14, C-16, C-12, C-13]
executor: worker-craft
executor_model: opus
checker: checker-judgment
check_method: >-
  C-14: checker-judgment: confirm references/migration.md no longer says Tier 2
  "is not implemented here", that both docs describe the sidecar flow (extract
  run, proposals file, --tier2 apply) and the verification sweep as the shipped
  scripts actually behave, and that the suite asserts the presence of --tier2
  and verify-migration.sh in SKILL.md alongside the existing routing-row
  assertions. C-16: checker-judgment: read every added human-facing string —
  SKILL.md migrate-mode prose, references/migration.md, the record paragraph
  template, the drafted commit message at .agent-guild/state/commit-message.md,
  and any comment or string this task added or revised in a script or in
  tests/inbox-to-memory-smoke.sh — against the humanizer skill's pattern
  list and the surrounding files' voice; flag rule-of-three padding,
  promotional framing, bolded inline headers, comments restating code.
  Title-case headings and occasional unspaced em dashes are correct here, not
  findings. C-12: run `git diff 1f17478 -- tests/` (no assertion removed or
  loosened) and all three suites (exit 0). C-13: run the constitution C-13
  script check verbatim (exit 0).
status: pending
retries: 0
max_retries: 2
deps: [T-002, T-003]
escalations: []
artifacts: []
---

## Spec excerpt

Update the docs to describe what T-002 and T-003 shipped, and give the migration record paragraph its final prose. Read the shipped scripts first — the docs must describe actual behavior, not the plan.

1. **`inbox-to-memory/SKILL.md`, Migrate Mode section (:342-368 today)**: it documents only the Tier 1 dry-run/`--apply` pair. Extend it to cover the Tier 2 sidecar flow (extract run → agent fills `summary`/`entities` in the proposals file → `--tier2 <file> --apply` writes mechanically), the separate gating (per-file or batch approval; rejecting a proposal is an absence, not a rollback), and `verify-migration.sh <scope> --since <ref>` as the closing sweep. Include the generation instruction the flow depends on: summary and entities are generated ONLY from the emitted extract, never from raw content, and each summary is one line asserting nothing the extract doesn't support.
2. **`inbox-to-memory/references/migration.md`**: line 19 still says Tier 2 "is tracked in its own ticket and is not implemented here" — that must go. Document the sidecar flow and the verification sweep as they behave, including what each verification failure diagnostic (`verify-link`, `verify-rename`) means and that verification reports and never repairs.
3. **The record paragraph template** in `verify-migration.sh`: T-003 wrote it plainly; polish the template so the emitted paragraph reads like a person's journal entry — scope, date, real counts, one paragraph, no boilerplate enthusiasm. Keep the script's substitution variables intact and keep the suite's C-10 assertions passing unchanged.
4. **Suite**: add the assertions C-14 names — `SKILL.md` mentions `--tier2` and `verify-migration.sh`, the way the suite already pins the mode's routing row (see the existing `require_text inbox-to-memory/SKILL.md` assertions at `tests/inbox-to-memory-smoke.sh:257` and :553).

5. **The commit message**: C-16 covers it, and by the time you run, every artifact it describes exists. Draft the job's commit message to `.agent-guild/state/commit-message.md` — NOT under `.agent-guild/state/notes/`, which the orchestrator is barred from reading, and this file has to be readable at ship time. List it under `artifacts` so it gets checked like any other prose. Focus on WHY as much as WHAT; just long enough to cover what's essential. No `Co-Authored-By` or other coauthored attribution, and no hard-wrapped lines — let git's pager wrap at display time. The orchestrator commits at ship time; you write the words.

Voice and process (C-16): run every added human-facing string through the `humanizer` skill's audit-and-revise loop before finishing — SKILL.md prose, migration.md, the record template, the commit message, any script comments you touch here. (The comments T-002 and T-003 wrote into `migrate-scope.sh` and `verify-migration.sh` are C-16-checked in those tasks, not this one.) House voice: a technical writer in a hurry; comments explain why, not what. Title-case headings are correct. Em dashes stay unspaced and occasional. Avoid lists of exactly three items when a fourth fits naturally or one can drop without loss — but never pad or trim just to dodge the pattern.

House constraints:

- In the deliverable, only `inbox-to-memory/` and `tests/` may change (C-13). Item 5's `.agent-guild/state/commit-message.md` is not an exception to that — C-13 exempts `.agent-guild/` as job harness, and its check script excludes the path outright.
- Suites gain assertions, never lose them (C-12); all three suites exit 0 before and after.

When done: set this task's `status` to `needs-check` and list changed files under `artifacts`.

## Rework diagnosis

<!-- ORCHESTRATOR appends here on each FAIL, copied verbatim from the checker's
verdict Diagnosis. Newest at the bottom, headed with the attempt it addresses
(e.g. "### sonnet r1"). Empty until the first failure. -->

## Courier comparison

<!-- ORCHESTRATOR writes this once the second opinion lands, while #34 is still
open. Read both verdicts directly and record three counts: findings only the
courier raised, findings only the checker of record raised, and the overlap.
Name the clause behind each unique finding — #34 rules on the unique-finding
rate, and a count with no clause attached can't be audited later.

Say which cited clauses were deterministic. Those cross as pre-run output for
the far side to judge, so they agree by construction and are worth nothing as
evidence either way.

A denied or blocked second opinion goes here too, with the reason. An absence
recorded is data; an absence unrecorded reads later as agreement.

This section never reaches the vendor: compose-brief.py extracts only the spec
excerpt and rework diagnosis. -->


---
