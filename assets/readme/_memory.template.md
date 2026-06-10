# Memory

Structured records of decisions made, facts observed, and rules in force for this scope.

Lives alongside [`../working-state.md`](../working-state.md) (when present):

- **`working-state.md`** is narrative: where we are, what's in flight, what's next, active hypotheses.
- **`_memory/`** is structured: crystallized decisions, stable facts, and standing rules. Queryable by Claude via Glob and Grep without loading full file contents.

When a decision in working-state settles into something durable, it gets written as a `_memory/decisions/` record. Working-state references it by id.

## Record types ({{MEMORY_MODE}} mode)

{{MEMORY_TYPE_SUMMARY}}

## Finding what's in memory

`_memory/` is on-demand retrieval — there is no always-loaded index. Whether you're asking an agent or browsing by hand, the pattern is **filter on structured fields first, read bodies last.**

### The query funnel

**1. Filenames carry type (via subfolder) + slug + id.** One glob usually narrows the field:

```
Glob _memory/decisions/*.md                  # all decisions
Glob _memory/context/*intake*.md             # context records about intake
Glob _memory/**/*coaching*                   # anything with "coaching" in the slug
```

**2. Frontmatter carries scope, state, and tags.** Grep on structured fields:

```
Grep "^status: accepted" _memory/decisions/
Grep "applies_to:.*commerce" _memory/
Grep "tags:.*architect" _memory/{{RULES_FOLDER}}/
```

**3. Read bodies only for the handful that survive steps 1 and 2.** Bodies are for humans — rationale, context, exceptions. Frontmatter is the retrieval surface.

### Why this pattern

Filtering on frontmatter before reading bodies is dramatically cheaper in tokens than reading every record to find matches. More importantly, the same mental model carries over to the retrieval surfaces production tooling uses:

- **GitHub Copilot Spaces** scopes to selected repos or files; its equivalent of "filter first" is the Space boundary + `copilot-instructions.md` guidance.
- **MCP server queries** expose structured filters directly to IDE agents.

If you can write the right Glob/Grep here, you can write the right Copilot Space or MCP query at the client. The local funnel is a rehearsal for the production retrieval model.

### What's deliberately not here

- **No `MEMORY.md` / `INDEX.md` index file.** Filenames already carry slug + id; subfolders carry type. An index would duplicate information that globbing already surfaces, drift the moment a record is renamed or superseded, and teach a retrieval path that doesn't exist in Copilot Spaces or MCP.
- **No maintained inventory list.** If you need "what's currently in memory," generate it on demand: `Grep "^title:" _memory/`.

---

Agent conventions, including token-efficient querying, are in [CLAUDE.md](CLAUDE.md). The canonical schema reference is at [`~/.claude/skills/inbox-to-memory/references/memory-bank-schema.md`](~/.claude/skills/inbox-to-memory/references/memory-bank-schema.md).
