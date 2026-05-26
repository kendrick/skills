# Cross-client Journal

Reflective pattern capture spanning every client engagement. Note and memory processing here uses the same [`inbox-to-memory`](~/.claude/skills/inbox-to-memory/SKILL.md) skill, in journal scope.

## What lives here

Journal entries are personal pattern-capture — methodology insights, consulting craft, RFP defense patterns, hypercare risk patterns, anything that generalizes past the specific client that triggered it.

Entries are flat under `entries/`. No subdivision by theme; themes are tracked in frontmatter and queried via grep when needed.

Most entries are _promoted_ from `[journal candidate: ...]` flags in client notes — the skill handles that flow. Direct drops into `_inbox/` are rare but supported (e.g., a standalone reflection that didn't emerge from a client conversation).

## Entry shape

```yaml
---
id: <nanoid>
memory_type: Journal
title: '...'
status: current | superseded | archived
date: YYYY-MM-DD
themes: []
applies_to: [] # generalized patterns ("rfp-defense", "client-onboarding")
source_refs: # cross-scope refs; each entry is qualified
  - scope: pursuit | project | client
    path: 11.04 NextEra/pursuits/atlas/notes/<file>.md
    note_id: <nanoid>
related: [] # other journal entry ids
---
# <title>

Free-form prose. One section. Optional `## Source moment` quoting the triggering passage with a back-link.
```

## Conventions inherited from the skill

- One entry per pattern; don't combine. If two source moments triggered the same pattern, append both to `source_refs`.
- Promotion from a client note rewrites the candidate line in the source note to a wiki-link pointing here.
- Journal entries can cite each other via `related`. A pattern that's been refined over multiple entries supersedes earlier entries via `status: superseded` and a `supersedes:` field.

## Filename convention

`YYYY-MM-DD-<slug>-<nanoid>.md` inside `entries/`. Slug should be 3-6 words, lowercase, kebab-case, descriptive of the pattern (not the source client).
