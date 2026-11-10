# memory-bank Schema (vendored summary)

This skill's record types come from the memory-bank reference architecture: structured project memory that both people and agents can query, descended from the architecture decision record as Nygard framed it and extended past the decision itself into standing rules, sanctioned exceptions, and environmental context.

The upstream for the record format is long-term-memory-kit at `fa45506a64d7d51c5521d038bee8a138980c9605`, whose `schema/record.schema.json` and `schema/memory-bank.schema.json` are authoritative, and whose `src/core/canonical.ts` sets the frontmatter key order. A record carrying `schema: 1` is a record in that format, and a scope holding one is a bank `ltm validate` can check. The skill follows the kit, so where this summary and the kit disagree, the kit wins and this document gets updated by hand.

## Mode Selection

Two modes for client and project scope, picked once at scaffold time and recorded in the scope's `CLAUDE.md`:

- **Lightweight** (default) — 3 types: `Decision`, `Context`, `PolicyRule`. Exception is dropped; edge cases fold into Decision. Files live in `_memory/decisions/`, `_memory/context/`, `_memory/rules/`. Optimized for adoption: smaller surface, less debate about whether something is an Exception or a Decision.
- **Canonical** — 4 types: `Decision`, `PolicyRule`, `Exception`, `Context`. Matches the upstream reference architecture exactly. Files live in `_memory/decisions/`, `_memory/policy-rules/`, `_memory/exceptions/`, `_memory/context/`. Use when the engagement needs strict alignment with the canonical schema or genuinely needs to separate sanctioned deviations from base decisions.

Switch happens at scaffold time. Existing 4-type substrates keep working without migration — process mode reads the chosen mode from the scope's `CLAUDE.md` and flags candidates against whichever type set is in effect.

The Journal type is unaffected by mode selection — it only exists at the cross-client journal tier (always one type, always the same frontmatter).

**Naming note:** both modes write a rule as `memory_type: PolicyRule`, since that is the only rule type the kit accepts. Only the folder differs. Lightweight keeps `_memory/rules/`, and its `memory-bank.yaml` maps `PolicyRule: _memory/rules` under `folders` so `ltm` looks there; canonical uses the kit's default, `_memory/policy-rules/`, and needs no mapping. A lightweight record moves into canonical mode by moving the file to `_memory/policy-rules/` and dropping that `folders` entry.

`memory_type: Rule` is the pre-ltm spelling. It survives only in `schema: 2` records, which `migrate-scope.sh --to-ltm` rewrites to `PolicyRule` (see [migration.md](migration.md)).

## The Bank Config

A scope holding `schema: 1` records carries `memory-bank.yaml` at its root, scaffolded from [`assets/memory-bank.template.yaml`](../assets/memory-bank.template.yaml). The kit requires three keys and rejects any it doesn't define:

```yaml
schema: 1
name: <scope directory basename, lowercased to a-z0-9->
facet_prefixes: [topic]           # every prefix this scope's facets may use; at least one
folders: {PolicyRule: _memory/rules}   # lightweight mode only
```

`facet_prefixes` is the scope's declared facet vocabulary, the list [machine-contracts.md](machine-contracts.md) checks every `applies_to` and `owners` entry against. The scaffold writes `[topic]` because the kit needs at least one prefix and the scaffold interview asks for none; a scope adds its own prefixes here as it adopts them.

## Record Types

Lightweight mode uses three of these; canonical mode uses all four.

| Type                  | Purpose                                                                                                                | Lightweight | Canonical |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------- | ----------- | --------- |
| Decision              | Captures _why_ something was decided this way. Has a decision question, an outcome, alternatives considered, approver. | ✓           | ✓         |
| Context               | Environmental fact. Stakeholder, system, constraint. Has a context scope and a fact statement.                         | ✓           | ✓         |
| PolicyRule            | Standing guidance ("never X", "always Y"). Has a rule statement and an enforcement level.                              | ✓ (in `_memory/rules/`) | ✓ (in `_memory/policy-rules/`) |
| Exception             | Sanctioned deviation from a PolicyRule. Has the rule it's an exception to, a justification, an approver.               | — fold into Decision | ✓ |

A fifth type — `Journal` — is local to this skill's three-tier model. It lives only in cross-client journal scope and has a different frontmatter shape (qualified `source_refs`, themes, no enforcement model). The kit has no Journal type, so journal entries stay at `schema: 2`, as notes do; only the four record types above move to `schema: 1`.

## Frontmatter — Fields Shared Across Record Types

The `memory_type` value reflects the active mode. Lightweight scopes set it to one of `Decision | Context | PolicyRule`; canonical scopes set it to `Decision | PolicyRule | Exception | Context`.

```yaml
schema: 1 # required; the kit's record schema version
id: <nanoid> # required, nanoid -s 10
memory_type: Decision | Context | PolicyRule # lightweight
# or
memory_type: Decision | PolicyRule | Exception | Context # canonical
title: '...' # required
status: proposed | accepted | superseded | deprecated | rejected # required
date: YYYY-MM-DD # required — when the record was first established
last_confirmed: YYYY-MM-DD # required by this skill; the stamper advances it
source_refs: [<note-id>, ...] # required by this skill; ids of groomed notes that contributed
```

This block is the required keys. Every key is one line with no `#` comment in a real record, because `ltm fmt` refuses frontmatter holding one. The full order, which `ltm` owns, with the optional keys in place:

```
schema, id, memory_type, title, status, date, effective_from, effective_to, last_confirmed, review_by, summary, superseded_by, supersedes, promoted_from, promoted_to, subject, applies_to, owners, tags, source_refs, related, body_schema, exception_to
```

Where each optional key goes:

- `effective_from`, `effective_to` (`YYYY-MM-DD`) follow `date`. Set `effective_to` on an Exception when the exception expires.
- `superseded_by: <id>` (one id) and `supersedes: [<id>]` (always a list, even with one id) follow `last_confirmed`, `superseded_by` first.
- `applies_to: [<prefix>:<value>]` (facets where the record applies), `owners: [<prefix>:<value>]` (facets responsible for keeping it current, e.g. `team:ops`), and `tags: []` (free-form keywords) come before `source_refs`.
- `related: [<relation>::<id>]` follows `source_refs`, then `body_schema` and `exception_to` where the record carries them.

Omit an optional key that has no value. The kit's date and id patterns reject a literal `null`, so `effective_to: null` or `superseded_by: null` fails `ltm validate`.

## Type-specific Body Fields

These appear as `## Section` headings in the record body, not as frontmatter keys.

**Decision:**

- Decision question
- Decision outcome
- Alternatives considered
- Approved by
- (optional) Context

**PolicyRule:**

- Rule statement
- Enforcement (`required | recommended | advisory`)
- Rationale
- (optional) Known exceptions — in lightweight mode, list these here rather than crystallizing each as a separate Exception record.

**Exception (canonical mode only):**

- Exception scope
- Justification
- Approved by
- Expires (date or condition)
- frontmatter: `related: ['constrained_by::<rule-id>']` and `exception_to: [[<rule-id>|<rule-short-name>]]`, both naming the same PolicyRule. The `constrained_by` entry is the link `ltm` reads, in doctor, validate, and retrieval; an Exception without it draws `orphan` from `ltm doctor`. `exception_to` is the Obsidian link.

In lightweight mode, the same content gets captured as a Decision record whose decision question is "should we deviate from `<rule>` for `<scope>`?" The crystallized fact is the same; only the record type and its discoverability path differ.

**Context:**

- Context scope
- Fact statement
- Provenance
- Why this matters

## Status Lifecycle

```
proposed
  └─► accepted
        ├─► superseded (replaced by a newer record; both rendered with link)
        ├─► deprecated (no longer applies, but kept for historical reference)
        └─► rejected (decision was reversed before being acted on)
```

Never silently change `accepted` → `superseded` or `accepted` → `deprecated` without the user's explicit decision. Status changes are a kind of edit the user signs off on, same as record creation.

## Retrieval Funnel

See [retrieval-funnel.md](retrieval-funnel.md) for the four-stage querying pattern (glob → grep frontmatter → YAML headers only → full body).

## What This Skill Does NOT Adopt From memory-bank

- The kit's optional record keys `review_by`, `summary`, `promoted_from`, `promoted_to`, and `subject` as keys this skill writes. They sit in the order in [machine-contracts.md](machine-contracts.md) and the lint accepts them on a `schema: 1` record, since `ltm` writes `promoted_*`; the 20-line budget limits how many one record carries.
- The kit's `consumers`, `heading_aliases`, and `doctor` keys in `memory-bank.yaml`. The scaffold writes none of them; a scope that wants one adds it by hand.
- The hydrator agent's scaffold-via-CLI workflow. This skill's process+scaffold modes serve a different ergonomic.

When in doubt, follow this document. If a memory-bank pattern not covered here would obviously improve this skill, raise it with the user before adopting.
