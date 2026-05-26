# memory-bank schema (vendored summary)

This skill aligns with the schema published at [`kendrick-at-slalom/memory-bank`](https://github.com/kendrick-at-slalom/memory-bank). Inspired by, not bound to — if that repo evolves, this document goes stale and gets updated manually.

## Record types

Four types live in client and project scope:

| Type       | Purpose                                                                                                                |
| ---------- | ---------------------------------------------------------------------------------------------------------------------- |
| Decision   | Captures _why_ something was decided this way. Has a decision question, an outcome, alternatives considered, approver. |
| PolicyRule | Standing guidance ("never X", "always Y"). Has a rule statement and an enforcement level.                              |
| Exception  | Sanctioned deviation from a PolicyRule. Has the rule it's an exception to, a justification, an approver.               |
| Context    | Environmental fact. Stakeholder, system, constraint. Has a context scope and a fact statement.                         |

A fifth type — `Journal` — is local to this skill's three-tier model. It lives only in cross-client journal scope and has a different frontmatter shape (qualified `source_refs`, themes, no enforcement model).

## Frontmatter — fields shared across record types

```yaml
id: <nanoid> # required, nanoid -s 10
memory_type: Decision | PolicyRule | Exception | Context # required
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

**PolicyRule:**

- Rule statement
- Enforcement (`required | recommended | advisory`)
- Rationale
- (optional) Known exceptions

**Exception:**

- Exception scope
- Justification
- Approved by
- Expires (date or condition)
- frontmatter: `exception_to: [[<rule-id>|<rule-short-name>]]`

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
