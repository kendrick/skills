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
| 1 | a qmd command failed; the script printed `FAILED: <command>` and qmd's first stderr line, and ran nothing after it. Also `refresh` wrote no stamp after every qmd command succeeded; it printed `FAILED: write <path>` and the OS error |
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

Then, once the real run exited 0, run Step 2's `refresh` once before the hook offer. The last stamp doesn't list the new collection, so the hook doesn't watch it until some refresh runs. Tell the user this first refresh may take minutes. If it exits 1, report its `FAILED:` line verbatim and still make the offer: this is the one exit 1 that doesn't stop Step 1. When an earlier refresh left a stamp, a failed one keeps that stamp, which doesn't list the new collection, so the hook doesn't retry it. Tell the user the new scope stays out of the index until a `refresh` succeeds, so they rerun Step 2's `refresh` by hand once the failure is fixed. Then make Step 3's hook offer. A dry run, a declined dry run, and a run that exited 1 or 3 end Step 1 without either.

**Done when:** the user saw the dry run and either declined it, or the real run exited 0, its `MCP:` line was relayed, `refresh` ran once, and Step 3 ran; or a run exited 1 or 3 and its message was reported verbatim.

## Step 2 — Refresh

```
python3 SCRIPT refresh
python3 SCRIPT refresh --if-changed
```

`refresh` runs `qmd update`, then `qmd embed`, and covers every registered collection, so it takes no scope. Run it after records or notes land, move, or change. `qmd embed` can download models on its first run, so tell the user a first refresh may take minutes.

Every successful `refresh` records its start time and the registered collections in `~/.local/state/memory-index/` (under `$XDG_STATE_HOME` when that is set), outside every scope.

`refresh --if-changed` is the hook mode. It prints nothing on stdout and exits 0 in every case. It starts a detached `refresh` only when a file in a registered collection, under the collection's path and matching its pattern, is newer than the last successful refresh, or when a matching file was added, renamed, moved, or deleted since then. Two calls while that refresh runs start it once. The detached run logs to `refresh.log` in the same state folder; read that file when a hook refresh seems not to land.

**Done when:** `refresh` exited 0, or it exited 1 and its `FAILED:` line was reported verbatim.

## Step 3 — Wire a Hook

Reach this step from Step 1 after a real `register` exits 0, when the user asks to keep the index current without running Step 2 by hand, or when `inbox-to-memory` reports `vec stale:`. A scope registered before this offer existed reaches it this way, since a second `register` fails on qmd's duplicate collection name.

The scope's owner owns its hooks, so this step writes no hook file. It makes one offer, and the harness's own config mechanism does the writing.

Check for a refresh hook first. Read the harness's hook config wherever it is readable: in Claude Code, the `hooks` key in `~/.claude/settings.json`, and in `.claude/settings.json` and `.claude/settings.local.json` under the working directory. A hook counts only when its command contains `memory-index.py refresh`. A hook on Stop or SessionStart that runs anything else, such as a notifier, leaves the question to ask. When a hook counts, name its file and event, quote its command, and end the step without asking. If that command lacks `--if-changed`, tell the user a per-turn hook should run `refresh --if-changed`; that is information, not a question.

In a harness with no hooks, end the step here. Step 2 runs by hand any time.

Otherwise, ask once per invocation whether to add a hook that runs:

```
python3 <absolute path to scripts/memory-index.py> refresh --if-changed
```

Spell SCRIPT as an absolute path, since a hook runs from whatever directory its harness chooses. Attach it to two events: Stop, which fires after each agent turn, and SessionStart, which catches the last turn before a quit. These are Claude Code's names; elsewhere, use the harness's equivalents. Step 2's hook-mode paragraph covers why `--if-changed` is safe to run every turn.

- **Yes:** hand the write to the harness's config mechanism, which in Claude Code is the `update-config` skill, with the command and both events. Recommend user-level placement (`~/.claude/settings.json` in Claude Code). `refresh` covers every registered collection, so one hook serves every scope on the machine, while a hook in one repo's project settings fires only in sessions started there.
- **No:** end the step. Step 2 runs by hand any time.

**Done when:** an existing refresh hook was reported and nothing was asked; or the user was asked once and either declined, or the write went to the harness's config mechanism with the absolute `refresh --if-changed` command on Stop and SessionStart and user-level placement recommended; and this skill wrote no hook file.
