# Retrieval Funnel

How to query memory records at scale without loading every file into context. Adapted from memory-bank's retrieval pattern.

The funnel has four stages, narrowing from cheap to expensive. Apply them in order; stop as soon as you have enough to answer.

Every grep below is marked for which file generation it matches. A scope can hold v1 and v2 files indefinitely, so a query that only matches one generation returns half an answer and looks like a whole one.

## Stage 1 — Glob

Use the directory layout and filenames to filter without reading content.

- `pursuits/atlas/_memory/decisions/*.md` — all Decision records for Atlas.
- `_memory/**/*.md` — all records in the current scope.
- `**/nee-*.md` — records whose slug starts with "nee-" (a manual tagging convention worth using sparingly).

This stage is free. Token cost is zero until you read. It is also generation-blind, which is why it stays the first move.

## Stage 2 — Grep Frontmatter

When glob isn't selective enough, grep for frontmatter fields.

```bash
# Records owned by a specific person — both generations
grep -l "owners:.*Andrew" _memory/**/*.md

# Records tagged 'hypercare' — both generations
grep -l "tags:.*hypercare" _memory/**/*.md

# Records still 'proposed' and needing attention — both generations
grep -l "^status: proposed" _memory/**/*.md

# Records citing a specific note — both generations
grep -l "source_refs:.*bStpwliejr" _memory/**/*.md

# Notes with unfinished business — v2 only
grep -L "^open_questions: 0" notes/*.md

# Records not confirmed since a given date — v2 only, and v1 records have no
# last_confirmed at all, so they are absent from this result rather than stale
grep -l "^last_confirmed: 2025" _memory/**/*.md
```

Relationships need both forms until a scope is fully migrated. V2 flattens them to compound strings; v1 nests them:

```bash
# What extends this note — v2
grep -rl "extends::JJuYgImRWn" notes/

# The same question — v1
grep -rl -A1 "note_id: JJuYgImRWn" notes/ | grep -l "relation: extends"
```

Still cheap. Returns a list of filenames; nothing loaded yet.

## Stage 3 — Read YAML Headers Only

Read the first 20 lines of each candidate. On a v2 file that is a contract rather than a guess: the frontmatter contract caps the block at 20 lines precisely so a header read is guaranteed to catch all of it. See [machine-contracts.md](machine-contracts.md).

V1 files have no such guarantee. If line 20 lands mid-block on one, read further rather than assuming the rest is empty.

Inspect:

- Is `status: accepted`, as opposed to proposed, superseded, or deprecated?
- Does `effective_to` say this is still current?
- Do `related` or `supersedes` point at a newer version you should read instead?
- On a v2 note, do the derived counts say there is unfinished business worth opening the file for?

**Absent is not zero.** A note with no counts is v1, and its unresolved state is unknown rather than empty.

If the headers answer the question, stop. Don't load the body.

## Stage 4 — Read Full Body

Reserved for the three to five candidates that survived stages 1 through 3.

**Stop at `## Raw Content`.** Everything above it is the extracted, reviewed layer, and it is what the sections exist to give you. Raw content is there for a human reading back, and for verifying a quote you have specific reason to doubt. Reading it by default pulls an entire transcript into context to answer a question the extracted sections already answered, which is the exact cost the whole funnel exists to avoid.

## Materializing an Index

There is no index file in the memory bank, in any form, under any name. An index duplicates what globbing already surfaces, drifts the moment a record is superseded, and teaches a retrieval path that doesn't exist in Copilot Spaces or in an MCP query.

When you want the shape of the bank, generate it and throw it away:

```bash
awk -v OFS='\t' '
  function val(s) { sub(/^[a-z_]+:[ \t]*/, "", s); return s }
  FNR == 1 { if (seen) print id, mtype, status, date, confirmed, title, tags
             id = mtype = status = date = confirmed = title = tags = ""; seen = 1; fm = 1; next }
  fm && /^---$/          { fm = 0 }
  fm && /^id:/           { id = val($0) }
  fm && /^memory_type:/  { mtype = val($0) }
  fm && /^status:/       { status = val($0) }
  fm && /^date:/         { date = val($0) }
  fm && /^last_confirmed:/ { confirmed = val($0) }
  fm && /^title:/        { title = val($0) }
  fm && /^tags:/         { tags = val($0) }
  END { if (seen) print id, mtype, status, date, confirmed, title, tags }
' _memory/*/*.md
```

One row per record, tab separated. Nothing beyond awk. V1 records emit an empty cell where they lack a key, which is how you spot the ones with no `last_confirmed` to reason about.

## Links Resolve by ID

Files are never renamed after creation, and ids never regenerate. When a wiki link's literal filename target is missing, resolve it by id before calling it broken: the last ten characters of the target are the nanoid, and `ls **/*<id>*.md` finds the file wherever it went. Report a link broken only after that fallback fails too.

## Cost Discipline

The funnel keeps token cost roughly constant as the bank grows. A bank with 500 records can answer a query by globbing to 30 candidates, grepping to 8, reading headers for 5, and loading 2 bodies. Without the funnel, that's 500 file reads.

Apply it even when the bank is small. It's a habit, not an optimization.

## When the Funnel Doesn't Apply

Some queries genuinely need broad context:

- "What's been decided in the last month?" — read every Decision record with `date` in the window.
- "Are there contradictions between the Atlas and Marketplace records?" — read all records in both and look for conflicting claims.

For these, accept the token cost or dispatch a subagent to do the broad pass and return a summary.
