# Migration

Bringing a scope written before the v2 contract onto it, without editing anyone's notes.

The constraint that shapes everything here: a note is a record of what someone knew on a particular day. Frontmatter is metadata about that record and can be rewritten freely. The body is the record itself, and rewriting it destroys the only thing the note was ever good for. So migration rewrites frontmatter and copies bodies byte for byte, which produces files that are v2 above the fence and v1 below it.

[scripts/migrate-scope.sh](../scripts/migrate-scope.sh) does the work. It runs on one opted-in scope at a time, skips anything already carrying `schema: 2`, and writes nothing unless you pass `--apply`.

## Why Migrate at All

V1 files are legal forever and the lint never flags them, so nothing forces this. What migration buys is the queries. `grep -L 'open_questions: 0'` finds every note with unfinished business, and a v1 note is invisible to it: absent is not zero, it's unknown. The same goes for `last_confirmed` on records and for every relationship grep that expects a compound string.

A scope with a long v1 tail answers every one of those questions with half the truth and no indication that it did.

## The Two Tiers

**Tier 1 is mechanical.** Every transformation has exactly one correct answer, derivable from the file itself. That is what makes it safe to approve as a single batch instead of file by file.

**Tier 2 is generative** (summary and entities, which most v1 notes never had). It is gated separately, because a generated summary is the skill's reading of a note rather than a fact about it. Tier 2 is tracked in its own ticket and is not implemented here.

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

**`last_confirmed` initializes to the record's own date.** A record nobody has re-confirmed was last confirmed the day it was written. Any later date would assert a review that never happened, and this field exists precisely so stale records are visible.

## What It Refuses to Do

The migrator reports and leaves alone, rather than guessing, whenever the answer isn't in the file:

- **A `related` entry with an id but no relation.** The relation is the half that carries the meaning. Inventing one produces a link that reads as though someone decided it.
- **Frontmatter `yq` can't parse.** Something is wrong that a rewrite would only bury.
- **A rewrite that would overrun the 20-line budget.** The budget is what makes a header read as a contract, so a file that can't fit needs a human deciding what to drop.
- **Sub-fields the compound form has no room for.** They get named in the report before they stop existing.

Everything it refuses appears under "needs a human" at the end of the run. That list is the output; the diff is just how you check it.

## Safety Properties

Each of these is asserted in [tests/inbox-to-memory-smoke.sh](../../tests/inbox-to-memory-smoke.sh) against the `old-only` fixture:

- Filenames and nanoids are unchanged. Nothing is renamed, so every existing wiki link still resolves.
- Body bytes are identical before and after.
- `git status` shows modifications only. No renames, no deletions.
- A second run is a no-op.
- Migrated files pass the lint, and their v1 body shape is not flagged.
- A dry run writes nothing.

The clean-tree requirement backs all of them. `--apply` refuses to start when the working tree has uncommitted changes under the scope, because every one of these properties is checked by reading `git diff` afterward, and a dirty tree makes a mistake indistinguishable from work already in progress. `--allow-dirty` overrides it for scopes that aren't under version control.

## Running It

```bash
# see what would change
bash inbox-to-memory/scripts/migrate-scope.sh <scope-root>

# write it
bash inbox-to-memory/scripts/migrate-scope.sh <scope-root> --apply

# confirm
bash inbox-to-memory/scripts/lint-scope.sh <scope-root>
git diff --stat
```

Migrate one scope, read the diff, then move to the next. A vault-wide run offers nothing a per-scope run doesn't, and it makes the diff too large to actually read, which is the only real check on any of this.
