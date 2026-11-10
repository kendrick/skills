# Migration

Bringing a scope written before the v2 contract onto it, without editing anyone's notes.

The constraint that shapes everything here: a note is a record of what someone knew on a particular day. Frontmatter is metadata about that record and can be rewritten freely. The body is the record itself, and rewriting it destroys the only thing the note was ever good for. So migration rewrites frontmatter and copies bodies byte for byte, which produces files that are v2 above the fence and v1 below it.

[scripts/migrate-scope.sh](../scripts/migrate-scope.sh) does the work. It runs on one opted-in scope at a time, skips anything already carrying `schema: 2`, and writes nothing unless you pass `--apply`.

## Why Migrate at All

V1 files are legal forever, and the lint's one check on them—whether their wiki links resolve—is one they pass as readily as a v2 file does, so nothing forces this. What migration buys is the queries. `grep -L 'open_questions: 0'` finds every note with unfinished business, and a v1 note is invisible to it: absent is not zero, it's unknown. The same goes for `last_confirmed` on records and for every relationship grep that expects a compound string.

A scope with a long v1 tail answers every one of those questions with half the truth and no indication that it did.

## The Two Tiers

**Tier 1 is mechanical.** Every transformation has exactly one correct answer, derivable from the file itself. That is what makes it safe to approve as a single batch instead of file by file.

**Tier 2 is generative** (summary and entities, which most v1 notes never had). It is gated separately, because a generated summary is the skill's reading of a note rather than a fact about it. It reaches files through a sidecar: the migrator emits what an agent is allowed to read, the agent fills in a proposals file, and the apply writes back only the parts the script can source.

## What Tier 1 Does

| Change | From | To |
| ------ | ---- | -- |
| Version keys | absent | `schema: 2`, `body_schema: 1` |
| Lists | block style | inline arrays |
| Key order | whatever it was | contract order |
| Relationships | `- note_id: X` / `relation: Y` | `[Y::X]` |
| Journal sources | `- scope:` / `path:` / `note_id:` | `[<path>::<note-id>]` |
| Derived counts | absent | counted from body tokens |
| `last_confirmed` | absent on records | the record's own `date` |

Two of those deserve their reasoning written down.

**Counts are counted, never guessed.** A v1 note with no tokens in it gets four zeros, and those zeros are true: the note has no open questions because it has none, not because nobody looked. The migrator runs the same body extraction the lint does, so the numbers it writes are the numbers the lint recomputes. Any drift between them fails the verification run rather than sitting in a file.

**`last_confirmed` initializes to the record's own date.** A record nobody has re-confirmed was last confirmed the day it was written. Any later date would assert a review the migrator has no evidence of, and this field exists precisely so stale records are visible.

Process mode supplies that evidence later. When an inbox input restates a claim an `accepted` record already makes, [scripts/stamp-confirmed.sh](../scripts/stamp-confirmed.sh) stamps the input's date onto the record without stopping to ask. It refuses to move the date backwards, which is the same argument read the other way: draining a folder of old transcripts must not age a record somebody confirmed last week.

## What It Refuses to Do

The migrator reports and leaves alone, rather than guessing, whenever the answer isn't in the file:

- **A `related` entry with an id but no relation.** The relation is the half that carries the meaning. Inventing one produces a link that reads as though someone decided it.
- **Frontmatter `yq` can't parse.** Something is wrong that a rewrite would only bury.
- **A rewrite that would overrun the 20-line budget.** The budget is what makes a header read as a contract, so a file that can't fit needs a human deciding what to drop.
- **Sub-fields the compound form has no room for.** They get named in the report before they stop existing.

Everything it refuses appears under "needs a human" at the end of the run. That list is the output; the diff is just how you check it.

## The Tier 2 Sidecar

Generation stays with the model, enforcement stays in the script. That is why Tier 2 runs as two passes with a file in between rather than as one invocation that does both.

The first pass writes the sidecar and touches nothing else:

```bash
bash inbox-to-memory/scripts/migrate-scope.sh <scope-root> --tier2-extract <dir>
```

For every note it would migrate, that writes `<dir>/<note-id>.extract.md`: the note's sections down to `## Raw Content`, HTML comments dropped, produced by the same extraction the derived counts already use rather than a second copy of the rule. It also appends the note to `<dir>/proposals.yaml`:

```yaml
notes:
  3iMu15QJ_x:
    file: <scope-root>/notes/2025-11-04-atlas-scoping-call-3iMu15QJ_x.md
    summary: ''
    entities: []
```

Records never appear there. A record has no extracted sections of its own, so Tier 2 has nothing to read for one.

Fill those two fields in from the extract and from nothing else. Raw content is the unreviewed layer: transcript, OCR, whatever the input dropped in. A summary that reaches down into it asserts something nobody has checked. Each summary is one line that says nothing the extract doesn't support: no date, name, decision, or outcome that isn't already in the sections. Each entity is a canonical name that appears in the extract verbatim.

The second pass merges the filled-in file into the Tier 1 rewrite:

```bash
bash inbox-to-memory/scripts/migrate-scope.sh <scope-root> --tier2 <dir>/proposals.yaml          # dry run
bash inbox-to-memory/scripts/migrate-scope.sh <scope-root> --tier2 <dir>/proposals.yaml --apply  # writes
```

Before writing a note, the script checks each proposed entity against that note's own extract. One it can't find there gets `tier2-entity-unsourced` and the note is left byte-identical rather than written halfway, because an entity absent from the extract came from raw content or from the model's own memory, and the skill later greps that key as fact. A summary spanning more than one line gets `tier2-summary-multiline` and the same treatment: it would fail `frontmatter-single-line` the moment the lint ran, and catching it afterward means catching it inside a file someone already considers migrated. Both join the "needs a human" list.

The two passes never collapse into one run. `--tier2-extract` rejects `--apply`, and it won't run alongside `--tier2` either. An extract has to exist, and be readable, before anything claims to be sourced from it.

### Gating

`--apply` on its own is Tier 1 and writes no `summary` or `entities` key anywhere, so approving the mechanical batch can't ship a generated summary as a side effect.

Tier 2's own approval is per file or as one batch. The dry run prints each proposal inside the diff block for the file it belongs to rather than in a list at the end, so a reviewer reads a proposed summary against the note that would get it and can rewrite one without disturbing the others.

Rejecting a proposal is an absence, not a rollback. A note the proposals file never names still migrates, since Tier 1 doesn't wait on Tier 2, and it comes out byte-identical to what a Tier-1-only apply would have written. Nothing is undone because nothing was written.

Tier 2 rides along with the Tier 1 apply rather than following it. A note already carrying `schema: 2` is skipped whole, which is what keeps a second run from re-proposing summaries over the first. It also means a scope migrated Tier-1-only stays that way: adding the two keys later is a repair pass over already-migrated files, and the migrator's pen stops at the v1 tail.

## Safety Properties

Each of these is asserted in [tests/inbox-to-memory-smoke.sh](../../tests/inbox-to-memory-smoke.sh) against the `old-only` fixture:

- Filenames and nanoids are unchanged. Nothing is renamed, so every existing wiki link still resolves.
- Body bytes are identical before and after.
- `git status` shows modifications only. No renames, no deletions.
- A second run is a no-op.
- Migrated files pass the lint, and their v1 body shape is not flagged.
- A dry run writes nothing, `--tier2` dry runs included.
- A note the Tier 2 proposals file omits is byte-identical to the same note migrated Tier 1 only.

The clean-tree requirement backs all of them. `--apply` refuses to start when the working tree has uncommitted changes under the scope, because every one of these properties is checked by reading `git diff` afterward, and a dirty tree makes a mistake indistinguishable from work already in progress. `--allow-dirty` overrides it for scopes that aren't under version control.

## Running It

```bash
# see what would change
bash inbox-to-memory/scripts/migrate-scope.sh <scope-root>

# write Tier 1 alone
bash inbox-to-memory/scripts/migrate-scope.sh <scope-root> --apply

# or write both tiers: extract, fill in proposals.yaml, read the dry run, then apply
bash inbox-to-memory/scripts/migrate-scope.sh <scope-root> --tier2-extract <dir>
bash inbox-to-memory/scripts/migrate-scope.sh <scope-root> --tier2 <dir>/proposals.yaml
bash inbox-to-memory/scripts/migrate-scope.sh <scope-root> --tier2 <dir>/proposals.yaml --apply

# confirm
bash inbox-to-memory/scripts/verify-migration.sh <scope-root> --since <pre-migration-ref>
git diff --stat
```

Migrate one scope, read the diff, then move to the next. A vault-wide run offers nothing a per-scope run doesn't, and it makes the diff too large to actually read, which is the only real check on any of this.

## Reflowing Raw Zones

A separate migration for a separate defect. `collapse-vtt.sh` once separated speaker turns with a single newline, and markdown renders consecutive non-blank lines as one paragraph, so every transcript groomed before the fix shows its whole raw zone as a single wall of text. `scripts/reflow-raw.sh` repairs those notes in place:

```bash
# see what would change
bash inbox-to-memory/scripts/reflow-raw.sh <scope-root>

# write it
bash inbox-to-memory/scripts/reflow-raw.sh <scope-root> --apply
```

It inserts a blank line between turns and touches nothing else about the transcript: the same words in the same order, only the whitespace differs. Because the reflow moves every line number below the fence, it then rewrites each `(raw: "..." L<n>)` anchor above the fence by finding the snippet in the reflowed zone, never by adding an offset—snippet-anchored relocation survives a turn that was merged or split, and arithmetic does not. A snippet it cannot place on exactly one zone line, and any bare `(raw: L<n>)` with no snippet to anchor to, is reported under "needs a human" and left byte-identical.

The generation rules are the same as Tier 1's, applied to the body instead of the frontmatter: a note with no `schema` key, or carrying `body_schema: 1`, has a v1 body and is skipped and counted. A raw zone that is not wall-to-wall speaker turns was never collapsed VTT—pasted decks and documents carry their own paragraph breaks—and is left alone. Rerunning on a migrated scope changes nothing, so an interrupted run is safe to repeat.

Anything outside the note that resolves these line numbers — a `<blob-url>#L<n>` source link, most commonly — resolves against the file's real line count, so generate those links after the reflow has run, not before.

## Splitting Raw Zones Into Sidecars

Process mode writes a note's raw text to a `notes/raw/<id>.md` sidecar, and `scripts/split-raw.sh` moves a v2 note groomed before that change onto the same shape. The contract is "The Raw Sidecar" in [machine-contracts.md](machine-contracts.md). Run `reflow-raw.sh` first: reflow skips and counts a split note, because its raw zone is now one pointer line and the transcript reflow would repair sits in the sidecar.

```bash
# list each note it would split, and the sidecar path
bash inbox-to-memory/scripts/split-raw.sh --dry-run <scope-root>

# write it
bash inbox-to-memory/scripts/split-raw.sh --apply <scope-root>
```

For each note in `notes/*.md`, the sidecar gets every byte after the `## Raw Content` heading line, copied rather than rebuilt. The note keeps the heading, a blank line, and the pointer line, and gains `raw_file` in key order. Each `L<n>` in that note's anchors drops by the heading's line number. The text moved verbatim, so that arithmetic is exact, and the snippet stays as written. An `L<n>` that never pointed below the heading is reported under "needs a human" and left as written.

It skips and counts three kinds of note: a v1 body (no `schema` key, or `body_schema: 1`), a note already carrying `raw_file`, and a note with nothing under the heading or no heading at all. A v1 body stays whole, so its transcript stays in the note. It refuses three more, names each under "needs a human", and leaves it byte-identical: a note whose sidecar already exists, a note with no `id` to name the sidecar after, and a note whose raw zone already links into `raw/` with no `raw_file`, which is the lint's `raw-file` failure and may mean the raw text is gone. Any refusal exits 1, on `--dry-run` as well, so the dry run predicts the apply's exit. Exit 3 is usage or an unreadable scope. A second `--apply` splits nothing.

It runs no git check of its own, so commit or stash first if you mean to read the split as a diff. Then run `lint-scope.sh`: a `raw_file` that resolves nowhere fails as `raw-file`.

## Migrating Records to ltm

`--to-ltm` moves a scope's `schema: 2` records onto long-term-memory-kit's format, `schema: 1`, so `ltm validate` and `ltm doctor` can read the scope as a bank. Notes and journal entries keep `schema: 2` and are never touched. The record format is in [memory-bank-schema.md](memory-bank-schema.md), and the facet shape is under Facets in [machine-contracts.md](machine-contracts.md).

For each `schema: 2` record under `_memory/*/`, the pass:

- sets `schema: 1`;
- rewrites `memory_type: Rule` to `PolicyRule`, leaving the file in `_memory/rules/`;
- in `applies_to` and `owners`, rewrites `<prefix>::<value>` to `<prefix>:<value>`, keeps a `<prefix>:<value>` entry, and maps a bare value through the facet map;
- rewrites a scalar `supersedes: <id>` to `supersedes: ['<id>']`;
- drops `effective_from`, `effective_to`, `supersedes`, and `superseded_by` where the value is `null` or empty;
- writes the keys in long-term-memory-kit's order, and refuses a record holding a key outside it (`themes`, for one), because the lint would fail the record on its next run, and refuses a record holding the same key twice, because the reorder keeps one line per key and would silently drop a value.

Bodies are copied byte for byte. A `schema: 1` record is skipped and counted under `already ltm:`, so a second `--apply` changes nothing.

Where the scope root has no `memory-bank.yaml`, the pass writes one: `schema: 1`, a `name` from the scope directory's basename lowercased to `a-z0-9-`, `facet_prefixes` as the sorted union of every prefix the migrated records use plus the map's `prefixes`, and `folders: {PolicyRule: _memory/rules}` where `_memory/rules/` exists. Where the file already exists, the pass leaves it alone and refuses any prefix it doesn't declare. On a scope with `_memory/rules/`, it also refuses a bank whose `folders` maps no `PolicyRule` to `_memory/rules`, since the kit would then look for rules in `_memory/policy-rules/` and never find the migrated ones. Add `folders: {PolicyRule: _memory/rules}` to `memory-bank.yaml` by hand, commit it, and rerun.

The facet map is a YAML file the scope's owner writes. The pass never infers a prefix, because a bare `billing` could be a system, a topic, or a team, and the file is the only place that answer exists:

```yaml
prefixes: [topic]   # extra prefixes to declare; a scope with no facets needs one
applies_to:
  billing: topic    # bare `billing` in applies_to becomes `topic:billing`
owners:
  ops: team         # bare `ops` in owners becomes `team:ops`
```

**The pass is all or nothing.** It checks every record before it writes any, and refuses the whole apply on any record it can't rewrite mechanically. Each refusal is a `needs a human:` line with the record path and the reason, and the dry run prints the same lines, so its output is the complete list for a scope. The common causes:

- a bare value the map doesn't cover, which the dry run also lists under `unmapped:`;
- a v1 record, reason `v1 record; run the Tier 1 migration first`;
- a record with CRLF line endings, reason `CRLF line endings; convert the record to LF and commit it first` (`perl -pi -e 's/\r$//' <record>` converts it);
- a `related` entry that fails the kit's `^[a-z_]+::[A-Za-z0-9_-]{10}$`;
- a record whose rewritten block would overrun the 20-line budget;
- an empty prefix union, which names the map's `prefixes` key;
- an existing `memory-bank.yaml` with `_memory/rules/` beside it and no `folders` entry mapping `PolicyRule` there.

A refusal exits 1 and writes nothing, and the dry run exits 1 on the same input, so it predicts the apply. A scope is never left half in each format. Exit 2 is usage or a precondition: a dirty tree without `--allow-dirty`, or `--to-ltm` beside `--tier2` or `--tier2-extract`.

Run the nine steps in order, one scope at a time, from the root of this skill's checkout:

1. Install `ltm` from the Install section of long-term-memory-kit's README, and confirm it is on `PATH`.
2. Commit the scope, and keep the commit as the ref verification reads.
3. If the scope still holds v1 records, run the Tier 1 migration, verify it, and commit it. On a scope with none, Tier 1 writes nothing.
4. Dry-run `--to-ltm`. It writes nothing.
5. Write the facet map from the dry run's `unmapped:` lines, one entry per bare value under the key it appeared in. Keep the map outside the scope root, such as `../<scope>.facets.yaml` beside it, because an uncommitted map inside the scope dirties the tree and the apply exits 2. Then dry-run again with `--facet-map` until it exits 0.
6. Apply.
7. Run `verify-migration.sh`. It gives the same answer before or after the migration commit: an uncommitted `memory-bank.yaml` is untracked, so the rename sweep never sees it, and a committed one is the single added file the sweep accepts.
8. Run `ltm validate`. Exit 0 means every record parses, so `ltm doctor` skips none as malformed.
9. If either check fails, undo, fix the map or the records, and start again at step 4. Otherwise commit.

```bash
# 1. install ltm
ltm --version

# 2. commit, and keep the ref
git add <scope-root> && git commit -m 'pre-ltm checkpoint'
ref="$(git rev-parse HEAD)"

# 3. Tier 1 first, on a scope with v1 records (verify and commit it, then take the ref again)
bash inbox-to-memory/scripts/migrate-scope.sh <scope-root> --apply

# 4. dry run: lists every bare value under unmapped:
bash inbox-to-memory/scripts/migrate-scope.sh <scope-root> --to-ltm

# 5. write <facet-map> outside the scope from the unmapped: lines, then dry-run with it
bash inbox-to-memory/scripts/migrate-scope.sh <scope-root> --to-ltm --facet-map <facet-map>

# 6. apply
bash inbox-to-memory/scripts/migrate-scope.sh <scope-root> --to-ltm --facet-map <facet-map> --apply

# 7. verify (before or after committing the migration)
bash inbox-to-memory/scripts/verify-migration.sh <scope-root> --since "$ref"

# 8. validate
ltm validate <scope-root>

# 9. undo: before committing the migration
git restore -- <scope-root> && git clean -f -- <scope-root>/memory-bank.yaml
# or after committing it (resets the whole repository)
git reset --hard "$ref"
```

`git restore` alone leaves the new `memory-bank.yaml` behind, since it was never tracked. `git clean` removes only that untracked file, so a `memory-bank.yaml` the scope committed before the pass survives.

Verification is complete only with `ltm` installed. Without it, `verify-migration.sh` prints `ltm: not installed; skipped` and passes on the lint alone, and the lint doesn't run the kit's schema.

## Verification

```bash
bash inbox-to-memory/scripts/verify-migration.sh <scope-root> --since <pre-migration-ref>
```

Its own script rather than a flag on the migrator, and it reads git history instead of the working tree. That is what lets it run against a migration someone applied and committed last week: by then `git status` reports a clean tree and has nothing left to say about what the migration did.

Three sweeps run over the scope, and a fourth runs where the scope root holds `memory-bank.yaml`.

- `lint-scope.sh` runs across every file in it, resolved as a sibling of `verify-migration.sh` so a copied `scripts/` directory runs its own copy. Verification reads the lint's exit status rather than its output, because a lint that aborts on bad input never reaches its summary line and a check grepping for one would read that abort as a clean sweep.
- Every wiki-link target the scope carried at `--since` has to still resolve, by filename first and then by the trailing ten-character id. A target that resolved by name before and by id now counts as a pass, and the report says how many took that fallback. Targets come from the `--since` tree rather than the migrated one, so a link that vanished during the migration is still checked instead of dropping out of the count.
- File statuses come from `git diff --name-status -M <ref>`. Anything other than `M` fails, with renames and deletions named separately. The one exception is an `A` for `memory-bank.yaml` at the scope root, the file `--to-ltm` writes; an added file anywhere else fails.
- Beside `memory-bank.yaml`, `ltm validate` runs when `ltm` is on `PATH`, given the bank file and each `schema: 1` record under `_memory/` by path. `schema: 2` and v1 records are left out: they stay legal until `--to-ltm` runs, and a scope can hold the bank before then. Without `ltm`, the summary prints `ltm: not installed; skipped` and the sweep passes.

Every failure names a diagnostic. `verify-lint` is the lint's own failure line passed through, or a note that the lint aborted with some exit status and no summary. `verify-link` means a target resolves neither by name nor by the nanoid in its last ten characters, so either the file is gone or its id changed, and migration is allowed to do neither. `verify-rename` covers a file that was renamed, deleted, added anywhere but the scope root's `memory-bank.yaml`, or came back with a status the sweep didn't expect; migration rewrites frontmatter in place and adds only that one file, so any other status is evidence that something besides the migrator touched the scope. `verify-ltm` is one `ltm validate` error line passed through, or `ltm validate exited <n> without a finding` when it failed silently. An ltm warning prints as an `info` line and never fails the run, matching ltm, which exits 0 on warnings.

**Verification reports and never repairs.** It prints every failure it found rather than stopping at the first, leaves the scope byte-identical, and exits nonzero. A sweep that rewrote the file it just flagged would stop being the check on the migration and become a second, unreviewed one.

A passing run ends by printing one paragraph carrying the scope, the date, and that run's counts, ready to paste into the scope's patterns journal. It goes to stdout and nowhere else: nothing writes it to a file, and `patterns-journal/` is never touched. A failing run prints no paragraph, because a migration that did not verify has nothing paste-ready to say.
