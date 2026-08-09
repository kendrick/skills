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

## Verification

```bash
bash inbox-to-memory/scripts/verify-migration.sh <scope-root> --since <pre-migration-ref>
```

Its own script rather than a flag on the migrator, and it reads git history instead of the working tree. That is what lets it run against a migration someone applied and committed last week: by then `git status` reports a clean tree and has nothing left to say about what the migration did.

Three sweeps run over the scope.

- `lint-scope.sh` runs across every file in it, resolved as a sibling of `verify-migration.sh` so a copied `scripts/` directory runs its own copy. Verification reads the lint's exit status rather than its output, because a lint that aborts on bad input never reaches its summary line and a check grepping for one would read that abort as a clean sweep.
- Every wiki-link target the scope carried at `--since` has to still resolve, by filename first and then by the trailing ten-character id. A target that resolved by name before and by id now counts as a pass, and the report says how many took that fallback. Targets come from the `--since` tree rather than the migrated one, so a link that vanished during the migration is still checked instead of dropping out of the count.
- File statuses come from `git diff --name-status -M <ref>`. Anything other than `M` fails, with renames and deletions named separately.

Every failure names a diagnostic. `verify-lint` is the lint's own failure line passed through, or a note that the lint aborted with some exit status and no summary. `verify-link` means a target resolves neither by name nor by the nanoid in its last ten characters, so either the file is gone or its id changed, and migration is allowed to do neither. `verify-rename` covers a file that was renamed, deleted, or came back with a status the sweep didn't expect; migration rewrites frontmatter in place, so any other status is evidence that something besides the migrator touched the scope.

**Verification reports and never repairs.** It prints every failure it found rather than stopping at the first, leaves the scope byte-identical, and exits nonzero. A sweep that rewrote the file it just flagged would stop being the check on the migration and become a second, unreviewed one.

A passing run ends by printing one paragraph carrying the scope, the date, and that run's counts, ready to paste into the scope's patterns journal. It goes to stdout and nowhere else: nothing writes it to a file, and `patterns-journal/` is never touched. A failing run prints no paragraph, because a migration that did not verify has nothing paste-ready to say.
