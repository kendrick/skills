# Machine Contracts

The retrieval funnel assumes it can read a file's frontmatter cheaply and grep its body predictably. Left unenforced, both assumptions degrade quietly: a query comes back empty and nothing distinguishes an answer from a miss.

This document is those assumptions written as rules, and [scripts/lint-scope.sh](../scripts/lint-scope.sh) is what enforces them.

Everything here applies to files carrying a `schema` key, with one exception. Files without a `schema` key are v1, they are legal forever, and the only thing the lint checks on them is whether their wiki links resolve, since a link resolving to no file is broken whichever generation wrote it. The frontmatter contract, the token grammar, the anchor rule, and the four derived counts all stop at the generation line. A scope holding several generations is a normal state, not a half-finished migration.

## Generations, and the File That Is Both

Migration rewrites frontmatter and leaves the body alone, so a migrated file is v2 above the fence and v1 below it. `body_schema: 1` is how it says so, and it splits the contract in two:

| Carries                          | Frontmatter contract | Body grammar | Links   |
| -------------------------------- | -------------------- | ------------ | ------- |
| no `schema` key                  | not checked          | not checked  | checked |
| `schema: 2`                      | checked              | checked      | checked |
| `schema: 2` and `body_schema: 1` | checked              | not checked  | checked |
| `schema: 1` (records only)       | checked, plus the four record checks | checked, or not where `body_schema: 1` | checked |

Only records carry `schema: 1`. It marks a record in long-term-memory-kit's format, the one `ltm validate` reads (see [memory-bank-schema.md](memory-bank-schema.md)). Notes and journal entries stay at `schema: 2`, because the kit reads only the type folders under `_memory/` and has no Journal type.

A record's generation is read from its `schema` value: no key is v1, `schema: 2` is a v2 record awaiting `migrate-scope.sh --to-ltm`, and `schema: 1` is an `ltm` record. A note's generation is read from the key's presence alone. A v2 record stays legal, as a v1 file does, and the record checks in [What the Lint Checks](#what-the-lint-checks) skip it; only `ltm` rejects it.

Without the third row the first migration run would turn every bare line anchor written in 2025 into a lint failure, and the only way to clear them would be editing notes whose entire value is being an accurate record of that day. A body-shape check therefore keys off `body_schema`, never off `schema: 2`.

Links are the one column that runs the whole way down, because a link resolving nowhere is broken in any generation. The lint tries three resolutions in order and stops at the first hit. First it reads the target as a path from the linking note's directory, which is how a cross-scope link resolves. Next, where the target holds no `/`, it looks for a file of that name anywhere in the scope. Last, where the target's basename ends in a hyphen and a ten-character id, it looks for a file in the scope carrying that id. A trailing `.md` on the target is optional. A link that resolves none of these ways fails as `link-broken`. That is not a rule invented for the lint: [scripts/verify-migration.sh](../scripts/verify-migration.sh) collects wiki targets from every markdown file in the scope's git tree and checks each one too, and the word `schema` appears nowhere in it. It resolves differently from the lint, though. It tries the filename and then the target's last ten characters, with no path step and no hyphen anchor, so a path-bearing or cross-scope link the lint passes can still fail its sweep. The derived counts are part of the frontmatter contract rather than a fourth column of their own. The migrator computes those four keys when it rewrites a file rather than guessing them, so they can be checked on any note whose frontmatter contract is checked, and a file carrying no `schema` key carries nothing for them to be compared against.

## The Frontmatter Contract

**Single-line values only.** Every line in the block is either a comment or a `key: value` pair starting at column zero. Lists are inline arrays (`tags: [runbook, cutover]`); block style is a failure. Nested mappings are a failure. A value that wraps onto a second line is a failure.

The reason is grep, not taste. `grep '^tags:'` returns the whole value or it returns nothing, and a diff of a changed tag is one line rather than a moved block.

**The block fits in the first 20 lines of the file.** This is the number that makes a header read a contract: an agent reading 20 lines is guaranteed to have the entire frontmatter, so stage three of the funnel can stop there without ever wondering whether it truncated something. The note order's 18 keys close on exactly line 20, with no margin: one commented-out key puts a full note over. The `schema: 2` record order lists 19 names, and `tags` and `themes` are mutually exclusive, so a record carries at most 18 and also closes on line 20. The `schema: 1` order lists 23 names, and no record can carry them all inside 20 lines, so `frontmatter-budget` is what bounds a `schema: 1` record.

**Fixed key order.** Omit any key you don't need; the order is fixed among the keys that are present. Three orders, picked by the file's own keys: no `memory_type` is a note; `memory_type` with `schema: 1` is a record in long-term-memory-kit's order; `memory_type` otherwise (`schema: 2` records and journal entries) takes the second order below.

Notes:

```
schema, body_schema, id, date, type, summary, attendees, tags, topics, entities, source_file, raw_file, transcript_corrections, open_questions, resolved_questions, deferred_tensions, unpromoted_candidates, related
```

`schema: 2` records, including journal entries:

```
schema, body_schema, id, memory_type, title, status, date, effective_from, effective_to, last_confirmed, source_refs, applies_to, owners, tags, themes, related, exception_to, supersedes, superseded_by
```

`themes` belongs to journal entries and `tags` to everything else; `exception_to` only to Exception records in canonical mode.

`schema: 1` records, in the order `ltm fmt` and every `ltm` writer rewrite a file into (the kit owns it: the property order of `schema/record.schema.json`, which `src/core/canonical.ts` writes in):

```
schema, id, memory_type, title, status, date, effective_from, effective_to, last_confirmed, review_by, summary, superseded_by, supersedes, promoted_from, promoted_to, subject, applies_to, owners, tags, source_refs, related, body_schema, exception_to
```

`body_schema` and `exception_to` trail `related` because `ltm` writes the keys its schema defines first, then appends any it lacks in the order the file had them. Keep a `schema: 1` record in this order and `ltm fmt` changes at most its quoting; any other order draws `frontmatter-key-order` on the next lint. A `schema: 1` record written before this order, from the earlier templates or the earlier `--to-ltm`, draws it too; `ltm fmt`, run from the scope root, rewrites it. `themes` is not in it, since journal entries stay `schema: 2`. The frontmatter holds no `#` comment line, since `ltm` drops every one on its next write.

A `schema: 1` record follows the kit's types and shapes on top of the record order:

- `memory_type` is one of `Decision`, `PolicyRule`, `Exception`, or `Context`. `Rule` is the v2 spelling, and both memory modes write `PolicyRule`.
- The record sits in the folder the scope's `memory-bank.yaml` names for its type under `folders`, or in the kit's default where `folders` names none: `_memory/decisions/`, `_memory/policy-rules/`, `_memory/exceptions/`, `_memory/context/`. A lightweight scope maps `PolicyRule` to `_memory/rules`.
- `supersedes` is an inline list, `supersedes: [<id>]`, even with one id. `superseded_by` is one id.
- An optional key with no value is omitted. The kit's date and id patterns reject a literal `null`.
- The scope root holds `memory-bank.yaml` with `schema: 1`, a `name`, and at least one `facet_prefixes` entry.

**`last_confirmed` is written for you, and only ever forward.** [Migration](migration.md) initializes it to the record's own `date`, since a record nobody has re-confirmed was last confirmed the day it was written. After that, [scripts/stamp-confirmed.sh](../scripts/stamp-confirmed.sh) advances it whenever an inbox input restates a claim an `accepted` record already makes, to that input's date, with no sign-off prompt in front of the write. It refuses any candidate not later than what the record already holds. A file carrying no `schema` key gains the key by neither route, which is the first row of the table above rather than a rule of its own: v1 frontmatter sits outside this contract, so nothing here fits a v2 key onto it.

**Compound references.** A relationship is one greppable string of the form `<relation>::<id>`, never a nested mapping:

```yaml
related: [extends::JJuYgImRWn, confirms::ZGulgExW0q]
```

The relation vocabulary is `confirms`, `contradicts`, `extends`, and `introduces`.

A journal entry's `source_refs` use the same shape, `<scope-path>::<note-id>`, in place of a `scope` / `path` / `note_id` mapping:

```yaml
source_refs: [11 Clients/northwind/pursuits/atlas::JJuYgImRWn]
```

The scope path is relative to the vault root. It is there for a human skimming where a pattern came from; the id is what resolves the file, which is why a moved note doesn't break the reference. Finding every entry sourced from one note is then `grep -F '::JJuYgImRWn'` rather than a YAML parse.

### Facets

`applies_to` and `owners` entries are facets, naming the dimension a value belongs to. On a `schema: 1` record every entry is `<prefix>:<value>`, with one colon, and its prefix is one the scope's `memory-bank.yaml` lists under `facet_prefixes`:

```yaml
applies_to: [regions:emea, systems:billing, topics:invoice-disputes]
owners: [team:ops]
```

The prefix is required. The kit's record schema rejects a bare value, and an undeclared prefix fails `ltm validate`. The kit's prefix check reads only the text before the first colon, though, so `regions::emea` passes `ltm` as prefix `regions` with value `:emea`. The lint's `record-facet` check, which requires the character after the colon to be something other than a colon, is what catches the doubled colon.

The prefixes belong to the scope rather than to this contract, and `memory-bank.yaml` is where a scope declares them. The scaffold declares `topic`; a scope adds its own before the first record that uses one.

A facet keeps one dimension apart at any size. `billing` names a system and also turns up in topics, so a flat `grep billing` returns both: at fifty records a reader separates them by eye, and at several thousand the same search returns hundreds of candidates and nothing reports a problem. `grep 'systems:billing'` pins one dimension, still on one line and still without a YAML parse.

A `schema: 2` record carries the older shape, `<facet>::<value>`, beside bare values, and neither is required there:

```yaml
applies_to: [regions::emea, systems::billing, topics::invoice-disputes]
```

`migrate-scope.sh --to-ltm` rewrites each `<facet>::<value>` to `<facet>:<value>` and maps a bare value through a facet map the scope's owner writes. It never infers a prefix for a bare value. [migration.md](migration.md) covers the pass.

## The Token Grammar

Every inline token the skill emits is registered here with the grep that finds it. A token shape absent from this table is a lint failure on a v2 file. New extraction ideas get a row here first; inventing syntax at the point of use produces something nothing can retrieve later.

| Token                     | Form                                                            | Grep                                                 |
| ------------------------- | --------------------------------------------------------------- | ---------------------------------------------------- |
| Memory candidate, project | `[memory candidate: project] <claim>`                            | `grep -F '[memory candidate: project]'`               |
| Memory candidate, client  | `[memory candidate: client] <claim>`                             | `grep -F '[memory candidate: client]'`                |
| Memory candidate, amend   | `[memory candidate: update existing [[<file>\|<label>]]] <claim>` | `grep -F '[memory candidate: update existing'`; open ones drop lines holding `\| dismissed:` |
| Journal candidate         | `[journal candidate: <generalized pattern>]`                     | `grep -F '[journal candidate:'`                       |
| Working-state candidate   | `[working-state candidate] <claim>`                              | `grep -F '[working-state candidate]'`; open ones drop lines holding `\| landed:` |
| Contradiction             | `[contradicts accepted: [[<file>\|<label>]]] <statement>`         | `grep -F '[contradicts accepted:'`                    |
| Open question             | `[open question: <slug>] <question>`                             | `grep -F '[open question:'`                           |
| Open question, resolved   | `[open question resolved: <slug>] <question>`                    | `grep -F '[open question resolved:'`                  |
| Tension                   | `[tension: resolved\|deferred\|unacknowledged] <description>`     | `grep -F '[tension:'`                                 |
| Decision                  | `[decision: one-way\|two-way] <what was decided>`                 | `grep -F '[decision:'`                                |

The two open-question greps are disjoint: `[open question resolved:` does not contain `[open question:`, so counting one never picks up the other.

### Token Fields

Fields are pipe-delimited and named. Order is not enforced; presence is.

```
- [open question: <slug>] <answerable question>? | resolver: @<name or unknown> | blocks: <decision, or informational> | default: <what happens if nobody answers>
- [open question resolved: <slug>] <question>? | resolved: <the answer, and who gave it>
- [tension: deferred] <description> | stakes: <one clause> | open question: <slug>
- [tension: resolved] <description> | stakes: <one clause> | resolved: <how it landed>
- [tension: unacknowledged] <description> | stakes: <one clause>
- [decision: one-way|two-way] <what was decided> | committed: @<name> | discarded: <alternatives, with the reason given at the time>
- [contradicts accepted: [[<record>|<label>]]] <what the new input says> | claims: <what the record says>
- [contradicts accepted: [[<record>|<label>]]] <statement> | claims: <what the record says> | dismissed: <reason, and who decided>
- [memory candidate: update existing [[<file>|<label>]]] <claim> | dismissed: <reason, and who decided>
- [working-state candidate] <claim> | landed: working-state
```

The discarded alternatives are a decision's payload. What got decided is usually recoverable from the transcript; what got ruled out, and the reason someone gave for ruling it out, is the part with a six-month shelf life, and it is the only part that tells you later whether the reason still holds.

Reversibility rides in the token because it changes how hard a decision is worth reopening. A two-way door reopened is a conversation; a one-way door reopened is a migration.

A slug is lowercase kebab, two to five words, and identical across every note asking the same question. That stability is what lets the skill count how long something has gone unanswered.

A missing field is reported and never filled in. A fabricated resolver does more damage than an admitted gap, because it sends someone to chase a person who was never going to answer.

A contradiction is the only token asserting something about a file other than the one it sits in, so it carries both halves of the disagreement. `claims:` is what the record says, quoted closely enough to settle the conflict without opening it, and closely enough to expose the cases where the two never actually disagreed.

Dismissal is a resolution that leaves the flag in place. A dismissed contradiction is the record that someone looked and decided it was nothing, which is what keeps the next four notes from re-flagging the same non-conflict.

Every deferred tension names an open question in the same note, one to one. Deferring something should open a thread rather than close one, and the pairing is arithmetic, which is why the lint can check it.

## Anchors

A v2 anchor quotes four to six verbatim words, optionally followed by a line number:

```
1. "Finance gave us a date." — Marcus Dell (raw: "Finance gave us a date" L19)
```

The snippet is authoritative and the line number is a convenience. A bare `(raw: L19)` is a lint failure on a v2 note, because line numbers move the first time raw content is reflowed and a reference that silently points at the wrong line is worse than one that points nowhere.

V1 notes keep their bare line refs and are never rewritten.

In a note carrying `raw_file`, `L<n>` counts lines in the sidecar rather than the note. The split moves text verbatim, so the sidecar number is the note's old number minus the line number of its `## Raw Content` heading. The snippet stays as written.

## The Raw Sidecar

`raw_file: raw/<id>.md` says a note's raw text lives in a sidecar at `notes/raw/<id>.md`, where `<id>` is the note's own `id`. It mirrors `source_file: attachments/<filename>`: the path resolves from the note's directory, and the key is optional. A note without it keeps its raw text inline under `## Raw Content`.

A note carries `raw_file` exactly when its raw text lives in the sidecar. The sidecar holds every line after the note's `## Raw Content` heading line, exactly as the note held them, and it has no frontmatter, so the note and its sidecar together reproduce the original raw text byte for byte. The note keeps the heading, a blank line, and one pointer line:

```
## Raw Content

In [raw/<id>.md](raw/<id>.md). Open it only to verify a quote.
```

The sidecar exists so an embedding index can exclude `notes/raw/`. Left inline, a two-hour transcript becomes dozens of chunks competing with the three or four reviewed ones above it.

A v1-body note, meaning one with no `schema` key or one carrying `body_schema: 1`, keeps its raw text inline, because `split-raw.sh` skips it.

Nothing reads a sidecar as a note. The lint walks `notes/*.md` and `notes/reports/*.md`, where memory-consolidate writes its reports, and the migrator walks `notes/*.md` only, since a report is born `schema: 2` with no `## Raw Content` and has nothing to migrate. Neither walk recurses, and three walks that recurse prune `notes/raw/`: the lint's link resolution and the link sweep in [scripts/verify-migration.sh](../scripts/verify-migration.sh) prune every `notes/raw/` at any depth, so a client scope's walk skips its project scopes' sidecars too, and note discovery in [scripts/bench-fixture.sh](../scripts/bench-fixture.sh) prunes the one under `notes/`. Without the prune, a sidecar named `<id>.md` would satisfy the name and id tries for a link to a note that no longer exists, and a sidecar whose raw Markdown opens with its own frontmatter `id` would give the bench a second note for that id.

The lint enforces the rule on v2-body notes as `raw-file`, whose three cases are in the table below. All three mean the raw text may be gone: a pointer that resolves nowhere or to an empty file is no evidence the text survived, and a pointer section with no key names no file to check. An empty sidecar never comes from a split, since `split-raw.sh` skips a note whose raw zone is empty.

## Derived Counts

Four keys on every v2 note, counted from body tokens and never estimated:

| Key                      | Counts                                                             |
| ------------------------ | ------------------------------------------------------------------ |
| `open_questions`         | `[open question:` tokens                                            |
| `resolved_questions`     | `[open question resolved:` tokens                                   |
| `deferred_tensions`      | `[tension: deferred]` tokens                                        |
| `unpromoted_candidates`  | candidate tokens still carrying their prefix rather than a wiki link, minus update-existing lines carrying `dismissed:` and working-state candidates carrying `landed:`, plus contradiction flags carrying no `dismissed:` |

A contradiction or an update-existing candidate counts as unpromoted until it is settled, and it settles two ways. Approving it rewrites the line to a wiki link, like any other candidate. Dismissing it leaves the prefix where it is and adds `dismissed:`, so the count has to read the field rather than the prefix. The open amends in a note are `grep -F '[memory candidate: update existing' <note> | grep -Fvc '| dismissed:'`. A declined new-record candidate takes no `dismissed:` and stays counted, since its prefix already reads as considered, not crystallized. A working-state candidate settles when the user moves its claim into `working-state.md`: the line keeps its token as provenance and takes `| landed: working-state`, conventionally last, as the dismissed suffix is. The count reads the presence of `| landed:`, not its position, and only on a working-state line, so the same suffix on any other token leaves that token counted. The skill never writes `working-state.md` itself, so the suffix goes on only after the user confirms the claim is there. Counting dismissals or landed lines forever would make "every note with unfinished business" a query that never comes back empty, which is the one thing these keys exist to answer.

These four are an explicit exception to omit-if-empty: a v2 note carries all four even when the value is zero. Without the exception a legitimate zero and a missing key look identical, which defeats the query the counts exist to serve. Finding every note with unfinished business is `grep -L 'open_questions: 0'`, and that only works if the key is always there.

**Absent is not zero.** A note with no counts is v1 and its unresolved state is unknown. Nothing infers zero from silence, and a query filtering on these keys has to say which generation it covers.

## What the Lint Checks

Each failure names the file and the check that caught it, so a defect whose cause changes gets a different message rather than the same generic one.

| Check                       | Fails when                                                          |
| --------------------------- | ------------------------------------------------------------------- |
| `frontmatter-fences`        | The file doesn't open with `---` or the block is never closed.       |
| `frontmatter-parses`        | `yq` can't parse the block.                                          |
| `frontmatter-budget`        | The closing `---` lands past line 20.                                |
| `frontmatter-single-line`   | A line is neither a comment nor a `key: value` pair at column zero.  |
| `frontmatter-known-keys`    | A key appears that neither order lists.                              |
| `frontmatter-key-order`     | Present keys are not in contract order.                              |
| `frontmatter-key-domain`    | The block carries both `tags` and `themes`.                          |
| `token-grammar`             | A bracketed token in the body is absent from the grammar table.      |
| `contradiction-fields`      | A contradiction names no record, or never states what that record claims. |
| `raw-file`                  | A v2-body note's `raw_file` doesn't resolve or resolves to an empty file, or its `## Raw Content` links into `raw/` with no `raw_file`. |
| `record-facet`              | A `schema: 1` record's `applies_to` or `owners` entry fails `^[a-z][a-z0-9-]*:[^:]`, or uses a prefix the scope's `memory-bank.yaml` doesn't list under `facet_prefixes`. |
| `record-type`               | A `schema: 1` record's `memory_type` is not one of the kit's four types, or the record sits outside the folder `memory-bank.yaml`'s `folders` names for that type, or the kit default where it names none. |
| `record-supersedes`         | A `schema: 1` record carries `supersedes` as anything other than an inline list. |
| `bank-config`               | A scope holding a `schema: 1` record has no `memory-bank.yaml`, or one missing `schema: 1`, a `name`, or a `facet_prefixes` entry. |

The four `record-` and `bank-config` checks run only where a record carries `schema: 1`. A `schema: 2` record and a note get none of them, which is what keeps a scope that hasn't migrated passing.

`frontmatter-key-domain` is checked ahead of the budget on purpose. A record carrying both keys plus most of the order runs past line 20, and the budget failure would report that overrun without ever naming the mixup underneath it.

Token scanning stops at `## Raw Content`. Raw content is a verbatim capture of someone else's writing, and whatever brackets it happens to contain are not this skill's tokens.
