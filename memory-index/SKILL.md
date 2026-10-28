---
name: memory-index
description: "Register a memory scope's `_memory/<type>/` folders and `notes/` with qmd as collections, and reindex after records land. Use when the user says \"index my memory\", \"set up qmd for this scope\", \"register this scope with qmd\", wants semantic search over memory, or says \"refresh the memory index\", and when a hook or another skill needs the index current after a write. Never writes or edits records: to groom an inbox into notes and records, use inbox-to-memory."
argument-hint: 'register <scope-root> | refresh'
---

# memory-index

qmd searches markdown by collection and has no file watcher, so a memory scope reaches it only by being registered, and stays current only by being refreshed. `scripts/memory-index.py` does both jobs, and this skill decides when to run it and what to show the user.

A file's collection is its folder. A record under `_memory/decisions/` belongs to `<scope>-decisions` whatever its `memory_type` frontmatter says, because the script keys collections on folders and never opens a record. A mismatch between the two is the lint's to report, not this skill's to repair.

Resolve once per invocation:

- **SCRIPT**: `scripts/memory-index.py`, resolved against this skill's own directory. Run it with `python3`.
- **SCOPE_ROOT**: the directory holding the scope's `_memory/`. Take it from the user, or from the working directory when that directory holds `_memory/`. Ask when neither does.

| Exit | Meaning |
|---|---|
| 0 | every qmd command succeeded, or the dry run printed them |
| 1 | a qmd command failed; the script printed `FAILED: <command>` and qmd's first stderr line, and ran nothing after it |
| 3 | `not a memory scope: <path>` (no `_memory/` directory) or `qmd not on PATH` |

On exit 1 or 3, report the script's message verbatim and stop the step.

## Step 1 — Register

Run `register` with `--dry-run` first, show the user every command it prints, and run it for real only on a yes:

```
python3 SCRIPT register SCOPE_ROOT --dry-run
python3 SCRIPT register SCOPE_ROOT
```

The dry run prints one command per line: a `qmd collection add` and a `qmd context add` for each type folder under `_memory/`, then the same pair for `notes/` with `--mask "*.md"` when `notes/` exists. Collections are named `<scope>-<type>` and `<scope>-notes`, where `<scope>` is SCOPE_ROOT's basename lowercased with every other character run turned into `-`. The mask matches files directly in `notes/` only, which keeps `notes/raw/`, `notes/_inbox/`, and `notes/attachments/` out of the index. After the commands, the dry run prints the same `MCP:` line the real run ends with.

Each context string opens with the paragraph under the `## ... in One Paragraph` heading in SCOPE_ROOT's `CLAUDE.md`. When that paragraph is still an unfilled comment, the string opens with `Memory scope <scope>.` instead. Tell the user the scope paragraph is unfilled when the dry run shows that fallback, since every collection's context inherits it.

A second `register` on a scope already registered fails at its first `collection add`, because qmd refuses a duplicate collection name. To re-register, have the user remove the scope's collections with `qmd collection remove <name>` first.

After the real run, relay the script's last line, which starts `MCP:` and gives the `mcpServers` entry the user adds to their client by hand.

**Done when:** the user saw the dry run and either declined it, or the real run exited 0 and its `MCP:` line was relayed; or a run exited 1 or 3 and its message was reported verbatim.

## Step 2 — Refresh

```
python3 SCRIPT refresh
```

`refresh` runs `qmd update`, then `qmd embed`, and covers every registered collection, so it takes no scope. Run it after records or notes land, move, or change. `qmd embed` can download models on its first run, so tell the user a first refresh may take minutes.

**Done when:** `refresh` exited 0, or it exited 1 and its `FAILED:` line was reported verbatim.

## Step 3 — Wire a Hook

Reach this step only when the user asks to keep the index current without running Step 2 by hand.

The scope's owner owns its hooks, so this step writes no hook file. Give the user the command their hook runs, with SCRIPT spelled as an absolute path, since a hook runs from whatever directory its harness chooses:

```
python3 <absolute path to scripts/memory-index.py> refresh
```

Name the event it belongs on: the one that fires after an agent writes under `_memory/` or `notes/` in that scope, such as a post-write or session-end hook in the user's harness.

**Done when:** the user has the absolute `refresh` command and the hook event to attach it to, and no hook file was written.
