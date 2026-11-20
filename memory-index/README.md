# memory-index

## Why This Exists

[qmd](https://github.com/tobi/qmd) gives a memory scope local BM25, vector, and reranked search, and serves it to agents over a read-only MCP server. It has no file watcher, though, and it knows nothing about how an `inbox-to-memory` scope is laid out. Somebody has to register each record folder as a collection, write the `context` string qmd hands back with each result, and reindex after an agent writes a record. Left to `SKILL.md` prose, every scope would do that a little differently. This skill makes it one script with two subcommands.

## How It Works

`register <scope-root>` registers one qmd collection for each folder under `_memory/`, named `<scope>-<type>`, so `qmd query -c acme-pursuit-decisions` searches decisions and nothing else. The folder decides the collection. The script never opens a record, so editing a record's `memory_type` frontmatter leaves its collection where it was, and moving the file to another folder moves it.

One more collection, `<scope>-notes`, covers the groomed notes with the mask `*.md`. That mask matches files directly in `notes/` and nothing below it, so the raw transcripts in `notes/raw/` stay out of the index and can't outnumber the reviewed text. qmd's `ignore` list would do the same job, but only qmd's own YAML config can set it, and this skill leaves that file alone.

Each collection's context string comes from the scope's own files: the "in One Paragraph" section of its `CLAUDE.md`, plus the type's one-line description from `_memory/CLAUDE.md`. The skill runs `register --dry-run` first and shows you every qmd command before anything changes. A real run ends by printing the `mcpServers` entry to add to your client.

`refresh` runs `qmd update`, then `qmd embed`, and records its start time and every qmd collection it saw in a state file outside the scope. `refresh --if-changed` is the hook mode. It checks each recorded collection for a file newer than that start time, or for a file added, renamed, moved, or deleted since then, and starts a detached `refresh` only when it finds one, so a turn that changed nothing costs no qmd call. Call `refresh` by hand, or let a hook do it: after `register`, whenever you ask to keep the index current, and when `inbox-to-memory` reports `vec stale:`, the skill offers once to add a hook that runs `refresh --if-changed` on Stop and SessionStart. If a hook that runs `refresh` already exists, it says so and asks nothing. It hands the write to your harness's settings tool, recommends user-level settings, and never writes the hook itself.

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
- A `[journal candidate:]` marker that appears only in the raw source text lives in `notes/raw/`, which the index skips. Markers that `inbox-to-memory` flags inside the extracted sections stay in the top-level note, so the index does see them. To find the raw-only ones, grep `notes/` recursively.
- `notes/CLAUDE.md` and `notes/README.md` sit directly in `notes/`, so the mask indexes them along with the notes.
- `--if-changed` doesn't watch a collection registered after the last refresh. The state file lists only the collections that refresh saw, so the new one joins at the next refresh.
- A collection's files can be older than the last refresh when `register` adds it, so `--if-changed` doesn't count them as changed and they stay unembedded. Run `refresh` once after `register`.
- Plain `refresh` takes no lock, so it can overlap a refresh that a hook started. Both run the same qmd commands, so the overlap only wastes time.
- When nothing changed, `--if-changed` checks every file in every qmd collection, including ones another tool registered. One large collection, such as `~/code` with `**/*.md`, can push the hook past one second.

The decision ledger behind these choices is [`_maintenance/memory-index/RATIONALE.md`](../_maintenance/memory-index/RATIONALE.md).
