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
