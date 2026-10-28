# memory-index

## Why This Exists

[qmd](https://github.com/tobi/qmd) gives a memory scope local BM25, vector, and reranked search, and serves it to agents over a read-only MCP server. It has no file watcher, though, and it knows nothing about how an `inbox-to-memory` scope is laid out. Somebody has to register each record folder as a collection, write the `context` string qmd hands back with each result, and reindex after an agent writes a record. Left to `SKILL.md` prose, every scope would do that a little differently. This skill makes it one script with two subcommands.

## How It Works

`register <scope-root>` registers one qmd collection for each folder under `_memory/`, named `<scope>-<type>`, so `qmd query -c acme-pursuit-decisions` searches decisions and nothing else. The folder decides the collection. The script never opens a record, so editing a record's `memory_type` frontmatter leaves its collection where it was, and moving the file to another folder moves it.

One more collection, `<scope>-notes`, covers the groomed notes with the mask `*.md`. That mask matches files directly in `notes/` and nothing below it, so the raw transcripts in `notes/raw/` stay out of the index and can't outnumber the reviewed text. qmd's `ignore` list would do the same job, but only qmd's own YAML config can set it, and this skill leaves that file alone.

Each collection's context string comes from the scope's own files: the "in One Paragraph" section of its `CLAUDE.md`, plus the type's one-line description from `_memory/CLAUDE.md`. The skill runs `register --dry-run` first and shows you every qmd command before anything changes. A real run ends by printing the `mcpServers` entry to add to your client.

`refresh` runs `qmd update`, then `qmd embed`. Call it by hand, or from a hook you wire up yourself. The skill gives you the command and never writes the hook.

## Install

```bash
npx skills add kendrick/skills --skill memory-index
```

To install by hand, clone the collection and copy this directory in:

```bash
git clone git@github.com:kendrick/skills.git
cp -R skills/memory-index ~/.claude/skills/memory-index
```

It needs Python 3 and [qmd](https://github.com/tobi/qmd) on your `PATH`. The script uses only the standard library.

## Use

```
> register this scope with qmd
> index my memory
> refresh the memory index
```

## Known Limitations

- Registering a scope twice fails at the first collection, because qmd refuses a duplicate name. Remove the scope's collections with `qmd collection remove` before you register it again.
- A note in the older v1 body format keeps its transcript inline, so the `notes/` mask can't keep that text out of the index. `register` doesn't detect v1 notes.
- `[journal candidate:]` markers live in `notes/raw/`, which the index skips. To find them, grep `notes/` recursively.
- `notes/CLAUDE.md` and `notes/README.md` sit directly in `notes/`, so the mask indexes them along with the notes.

The decision ledger behind these choices is [`_maintenance/memory-index/RATIONALE.md`](../_maintenance/memory-index/RATIONALE.md).
