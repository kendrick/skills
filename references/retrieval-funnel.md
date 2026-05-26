# Retrieval funnel

How to query memory records at scale without loading every file into context. Adapted from memory-bank's retrieval pattern.

The funnel has four stages, narrowing from cheap to expensive. Apply them in order; stop as soon as you have enough to answer.

## Stage 1 — Glob

Use the directory layout and filenames to filter without reading content.

- `pursuits/atlas/_memory/decisions/*.md` — all Decision records for Atlas.
- `_memory/**/*.md` — all records in the current scope.
- `**/nee-*.md` — records whose slug starts with "nee-" (a manual tagging convention worth using sparingly).

This stage is free. Token cost is zero until you read.

## Stage 2 — Grep frontmatter

When glob isn't selective enough, grep for frontmatter fields. Common queries:

```bash
# Records owned by a specific person
grep -l "owners:.*Andrew" _memory/**/*.md

# Records tagged 'hypercare'
grep -l "tags:.*hypercare" _memory/**/*.md

# Records that are still 'proposed' (need user attention)
grep -l "^status: proposed" _memory/**/*.md

# Records that reference a specific note
grep -l "source_refs:.*bStpwliejr" _memory/**/*.md
```

Still cheap. Returns a list of filenames; nothing loaded yet.

## Stage 3 — Read YAML headers only

For each candidate file from stage 2, read just the frontmatter block. The Read tool with `limit: 25` or so usually catches the full YAML for a memory record.

Inspect:

- Does `status: accepted` (vs proposed/superseded/deprecated)?
- Does `effective_to` indicate this is still current?
- Do `related` or `supersedes` fields point you to a newer version you should read instead?

If you can answer the user's question from the YAML headers alone, stop. Don't load the body.

## Stage 4 — Read full body

Reserved for the 3-5 candidate records that survived stages 1-3. Read the type-specific body fields (decision outcome, fact statement, rule statement) to answer the question.

## Cost discipline

The funnel keeps token cost roughly constant as the memory bank grows. A bank with 500 records can answer a query by globbing to 30 candidates, grepping to 8, reading YAML for 5, and loading 2 full bodies. Without the funnel, that's 500 file reads.

Apply the funnel even when the bank is small. It's a habit, not an optimization.

## When the funnel doesn't apply

Some queries genuinely need broad context:

- "What's been decided in the last month?" — read every Decision record with `date` in the window.
- "Are there any contradictions between Atlas and Marketplace records?" — read all records in both, look for contradictory claims.

For these, accept the token cost or dispatch a subagent to do the broad pass and return a summary.
