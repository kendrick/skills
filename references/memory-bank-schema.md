# memory-bank schema (vendored summary)

This skill aligns with the schema published at [`kendrick-at-slalom/memory-bank`](https://github.com/kendrick-at-slalom/memory-bank). Inspired by, not bound to — if that repo evolves, this document goes stale and gets updated manually.

## Mode selection

Two modes for client and project scope, picked once at scaffold time and recorded in the scope's `CLAUDE.md`:

- **Lightweight** (default) — 3 types: `Decision`, `Context`, `Rule`. Exception is dropped; edge cases fold into Decision. Files live in `_memory/decisions/`, `_memory/context/`, `_memory/rules/`. Optimized for adoption: smaller surface, less debate about whether something is an Exception or a Decision.
- **Canonical** — 4 types: `Decision`, `PolicyRule`, `Exception`, `Context`. Matches `kendrick-at-slalom/memory-bank` exactly. Files live in `_memory/decisions/`, `_memory/policy-rules/`, `_memory/exceptions/`, `_memory/context/`. Use when the engagement needs strict alignment with the canonical schema or genuinely needs to separate sanctioned deviations from base decisions.

Switch happens at scaffold time. Existing 4-type substrates keep working without migration — process mode reads the chosen mode from the scope's `CLAUDE.md` and flags candidates against whichever type set is in effect.

The Journal type is unaffected by mode selection — it only exists at the cross-client journal tier (always one type, always the same frontmatter).

**Naming note:** lightweight `Rule` and canonical `PolicyRule` describe the same concept (standing guidance, "never X" / "always Y") with the same body fields. The shorter name is the only thing that differs. A record written in one mode can be moved into the other by renaming the file's parent folder and updating `memory_type:` in frontmatter.

## Record types

Lightweight mode uses three of these; canonical mode uses all four.

| Type                  | Purpose                                                                                                                | Lightweight | Canonical |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------- | ----------- | --------- |
| Decision              | Captures _why_ something was decided this way. Has a decision question, an outcome, alternatives considered, approver. | ✓           | ✓         |
| Context               | Environmental fact. Stakeholder, system, constraint. Has a context scope and a fact statement.                         | ✓           | ✓         |
| Rule / PolicyRule     | Standing guidance ("never X", "always Y"). Has a rule statement and an enforcement level.                              | ✓ (`Rule`)  | ✓ (`PolicyRule`) |
| Exception             | Sanctioned deviation from a PolicyRule. Has the rule it's an exception to, a justification, an approver.               | — fold into Decision | ✓ |

A fifth type — `Journal` — is local to this skill's three-tier model. It lives only in cross-client journal scope and has a different frontmatter shape (qualified `source_refs`, themes, no enforcement model).

## Frontmatter — fields shared across record types

The `memory_type` value reflects the active mode. Lightweight scopes set it to one of `Decision | Rule | Context`; canonical scopes set it to `Decision | PolicyRule | Exception | Context`.

```yaml
id: <nanoid> # required, nanoid -s 10
memory_type: Decision | Rule | Context # lightweight
# or
memory_type: Decision | PolicyRule | Exception | Context # canonical
title: '...' # required
status: proposed | accepted | superseded | deprecated | rejected # required
date: YYYY-MM-DD # required — when the record was first established

# Time bounds (optional)
effective_from: YYYY-MM-DD
effective_to: YYYY-MM-DD | null

# Provenance (required)
source_refs: [<note-id>, ...] # ids of groomed notes that contributed to this record

# Scope and discoverability (optional)
applies_to: [] # what this record applies to (free vocab)
owners: [] # names or roles responsible for keeping this current
tags: [] # discoverability

# Relationships (optional)
related: [] # ids of related records
supersedes: <id> | null # id of an older record this replaces
superseded_by: <id> | null # id of a newer record that replaces this one
```

## Type-specific body fields

These appear as `## Section` headings in the record body, not as frontmatter keys.

**Decision:**

- Decision question
- Decision outcome
- Alternatives considered
- Approved by
- (optional) Context

**Rule / PolicyRule:**

- Rule statement
- Enforcement (`required | recommended | advisory`)
- Rationale
- (optional) Known exceptions — in lightweight mode, list these here rather than crystallizing each as a separate Exception record.

**Exception (canonical mode only):**

- Exception scope
- Justification
- Approved by
- Expires (date or condition)
- frontmatter: `exception_to: [[<rule-id>|<rule-short-name>]]`

In lightweight mode, the same content gets captured as a Decision record whose decision question is "should we deviate from `<rule>` for `<scope>`?" The crystallized fact is the same; only the record type and its discoverability path differ.

**Context:**

- Context scope
- Fact statement
- Provenance
- Why this matters

## Status lifecycle

```
proposed
  └─► accepted
        ├─► superseded (replaced by a newer record; both rendered with link)
        ├─► deprecated (no longer applies, but kept for historical reference)
        └─► rejected (decision was reversed before being acted on)
```

Never silently change `accepted` → `superseded` or `accepted` → `deprecated` without the user's explicit decision. Status changes are a kind of edit the user signs off on, same as record creation.

## Retrieval funnel

See [retrieval-funnel.md](retrieval-funnel.md) for the four-stage querying pattern (glob → grep frontmatter → YAML headers only → full body).

## What this skill does NOT adopt from memory-bank

- Sequential namespaced IDs (`<namespace>-ADR-<n>`). This skill uses nanoid because three-scope nesting with sequential IDs creates ordering conflicts.
- The `uuid` field (RFC 4122). Obsidian resolves wiki-links by filename; `uuid` adds no value here.
- `applies_to` taxonomies bound to services and domains. Consulting-note `applies_to` is free vocabulary.
- The hydrator agent's six-phase scaffold-via-CLI workflow. This skill's process+scaffold modes serve a different ergonomic.

When in doubt, follow this document. If a memory-bank pattern not covered here would obviously improve this skill, raise it with the user before adopting.
