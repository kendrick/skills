# Machine Contracts

The retrieval funnel assumes it can read a file's frontmatter cheaply and grep its body predictably. Left unenforced, both assumptions degrade quietly: a query comes back empty and nothing distinguishes an answer from a miss.

This document is those assumptions written as rules, and [scripts/lint-scope.sh](../scripts/lint-scope.sh) is what enforces them.

Everything here applies to files carrying `schema: 2` and to nothing else. Files without a `schema` key are v1, they are legal forever, and the lint never flags them. A scope holding both generations is a normal state, not a half-finished migration.

## The Frontmatter Contract

**Single-line values only.** Every line in the block is either a comment or a `key: value` pair starting at column zero. Lists are inline arrays (`tags: [runbook, cutover]`); block style is a failure. Nested mappings are a failure. A value that wraps onto a second line is a failure.

The reason is grep, not taste. `grep '^tags:'` returns the whole value or it returns nothing, and a diff of a changed tag is one line rather than a moved block.

**The block fits in the first 20 lines of the file.** This is the number that makes a header read a contract: an agent reading 20 lines is guaranteed to have the entire frontmatter, so stage three of the funnel can stop there without ever wondering whether it truncated something. Both key orders below fit inside the budget with room left over, which means overrunning it is almost always accumulated commented-out keys rather than real content.

**Fixed key order.** Omit any key you don't need; the order is fixed among the keys that are present. Two orders, one for notes and one for records.

Notes:

```
schema, id, date, type, summary, attendees, tags, topics, entities, source_file, transcript_corrections, open_questions, resolved_questions, deferred_tensions, unpromoted_candidates, related
```

Records, including journal entries:

```
schema, id, memory_type, title, status, date, effective_from, effective_to, last_confirmed, source_refs, applies_to, owners, tags, themes, related, exception_to, supersedes, superseded_by
```

A file is a record when it has `memory_type` and a note otherwise. `themes` belongs to journal entries and `tags` to everything else; `exception_to` only to Exception records in canonical mode.

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

## The Token Grammar

Every inline token the skill emits is registered here with the grep that finds it. A token shape absent from this table is a lint failure on a v2 file. New extraction ideas get a row here first; inventing syntax at the point of use produces something nothing can retrieve later.

| Token                     | Form                                                            | Grep                                                 |
| ------------------------- | --------------------------------------------------------------- | ---------------------------------------------------- |
| Memory candidate, project | `[memory candidate: project] <claim>`                            | `grep -F '[memory candidate: project]'`               |
| Memory candidate, client  | `[memory candidate: client] <claim>`                             | `grep -F '[memory candidate: client]'`                |
| Memory candidate, amend   | `[memory candidate: update existing [[<file>\|<label>]]] <claim>` | `grep -F '[memory candidate: update existing'`        |
| Journal candidate         | `[journal candidate: <generalized pattern>]`                     | `grep -F '[journal candidate:'`                       |
| Working-state candidate   | `[working-state candidate] <claim>`                              | `grep -F '[working-state candidate]'`                 |
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
```

The discarded alternatives are a decision's payload. What got decided is usually recoverable from the transcript; what got ruled out, and the reason someone gave for ruling it out, is the part with a six-month shelf life, and it is the only part that tells you later whether the reason still holds.

Reversibility rides in the token because it changes how hard a decision is worth reopening. A two-way door reopened is a conversation; a one-way door reopened is a migration.

A slug is lowercase kebab, two to five words, and identical across every note asking the same question. That stability is what lets the skill count how long something has gone unanswered.

A missing field is reported and never filled in. A fabricated resolver does more damage than an admitted gap, because it sends someone to chase a person who was never going to answer.

Every deferred tension names an open question in the same note, one to one. Deferring something should open a thread rather than close one, and the pairing is arithmetic, which is why the lint can check it.

## Anchors

A v2 anchor quotes four to six verbatim words, optionally followed by a line number:

```
1. "Finance gave us a date." — Marcus Dell (raw: "Finance gave us a date" L19)
```

The snippet is authoritative and the line number is a convenience. A bare `(raw: L19)` is a lint failure on a v2 note, because line numbers move the first time raw content is reflowed and a reference that silently points at the wrong line is worse than one that points nowhere.

V1 notes keep their bare line refs and are never rewritten.

## Derived Counts

Four keys on every v2 note, counted from body tokens and never estimated:

| Key                      | Counts                                                             |
| ------------------------ | ------------------------------------------------------------------ |
| `open_questions`         | `[open question:` tokens                                            |
| `resolved_questions`     | `[open question resolved:` tokens                                   |
| `deferred_tensions`      | `[tension: deferred]` tokens                                        |
| `unpromoted_candidates`  | candidate tokens still carrying their prefix rather than a wiki link |

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
| `token-grammar`             | A bracketed token in the body is absent from the grammar table.      |

Token scanning stops at `## Raw Content`. Raw content is a verbatim capture of someone else's writing, and whatever brackets it happens to contain are not this skill's tokens.
