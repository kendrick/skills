# Memory: agent conventions

> **Audience:** Claude working in this directory.
>
> **Inherits from:** the scope's root `CLAUDE.md`.

## Record types ({{MEMORY_MODE}} mode)

{{MEMORY_TYPE_LIST}}

## Required frontmatter

```yaml
---
id: <nanoid>
memory_type: {{MEMORY_TYPE_ENUM}}
title: "..."
status: proposed | accepted | superseded | deprecated | rejected
date: YYYY-MM-DD
source_refs: [<note-or-record-id>]
---
```

Optional: `related`, `applies_to`, `owners`, `effective_from`, `effective_to`, `tags`, `supersedes`, `superseded_by`.

## Filename

`<slug>-<nanoid>.md` inside the type subfolder. The folder implies `memory_type`; still set the field in frontmatter for safety. Type folders in this scope: {{MEMORY_TYPE_FOLDERS}}.

## Querying memory token-efficiently

Default to a four-stage funnel, cheapest first. Don't skip stages unless you already have the specific record id.

**Stage 1: glob on filenames.** Filenames carry type (via subfolder), slug, and nanoid. Zero file content loaded.

```
Glob _memory/decisions/*.md                    # all decisions
Glob _memory/decisions/*coaching*.md           # decisions with "coaching" in the slug
Glob _memory/**/*V1StGXR8Z5*                   # resolve a specific nanoid ref
```

**Stage 2: grep on frontmatter.** When filenames aren't enough, grep structured fields. Frontmatter sits at the top of each file, so matching lines come back cheap.

```
Grep "^status: accepted" _memory/decisions/
Grep "tags:.*compliance" _memory/
Grep "applies_to:.*commerce" _memory/context/
```

**Stage 3: frontmatter-only read.** Use `Read` with `limit: 15` to pull just the YAML header (~300 tokens per record). Only on candidates that survived stages 1 and 2.

**Stage 4: full body read.** Only for the three-to-five records that actually matter for the question at hand.

Anti-pattern: reading every record in full to find matches. If you catch yourself doing this, stop and go back to stage 1.

## How records get created

Memory records are agent-proposed, never user-dropped. The workflow is two-pass:

1. **Flag candidates in the groomed note.** During inbox processing, surface memory-worthy content inline (`[memory candidate: <scope>] <claim>`). Do **not** create record files at this stage.
2. **Wait for user sign-off.** Only create record files in `_memory/` after the user reviews the groomed note and explicitly approves which candidates to crystallize.
3. **Link promoted candidates.** When a record is created, rewrite the candidate line in the groomed note: replace the `[memory candidate]` prefix with a wiki link — `[[<filename>|memory]]`. Unpromoted candidates keep the prefix, signaling "considered, not crystallized."

When creating the record:

1. Generate an id: `nanoid -s 10` (globally-installed CLI; never random-generate).
2. Place in the canonical type subfolder with `status: proposed`.
3. Populate `source_refs` with the note id(s) that produced the record.
4. Write a concise body: context, the crystallized fact, rationale where relevant. Type-specific body sections live in [`~/.claude/skills/inbox-to-memory/references/memory-bank-schema.md`](~/.claude/skills/inbox-to-memory/references/memory-bank-schema.md).
5. Do not auto-commit. Summarize what was proposed and let the user review.

## When records graduate

The user edits `status: proposed` → `status: accepted` after review. If a record is later replaced, mark the old one `status: superseded` and set `supersedes:` on the replacement to the old record's id. No automated supersession enforcement in this version; discipline only.

## What never goes here

- Auto-committed proposed records.
- Records without `source_refs`. If you can't trace a record to a source, flag it and ask.
- A `MEMORY.md` or `INDEX.md` summary file. Filenames carry slug + id, subfolders carry type — an index duplicates information that globbing already surfaces, drifts the moment a record is renamed or superseded, and teaches a retrieval path that doesn't transfer to Copilot Spaces or MCP queries.
- Notes or journal entries. Notes are raw input; journal entries are cross-client candidates; memory records are crystallized engagement state.
- Reading full file bodies when frontmatter would answer the question.
