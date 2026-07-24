---
name: handoff
description: Save a session handoff or resume one after clearing a session. Use ONLY when the user explicitly invokes handoff or asks to hand off / resume a handoff. Never use for summaries, status updates, or note-taking.
disable-model-invocation: true
argument-hint: '[handoff id to resume | a prompt to hand off | empty for whole session]'
---

# Handoff

Write a handoff document before clearing a session, then use it to rebuild the work later. The document is the source of truth.

This workflow is designed to work across coding agents and operating systems. Where a step names a shell command, treat it as the intent; use your native shell (bash, PowerShell, or file tools) to achieve the same result. Always use forward slashes in paths written into documents.

## Shared Paths and Phase Detection

Resolve once per invocation:

- **ROOT**: the output of `git rev-parse --show-toplevel` (identical on every OS); fall back to the current working directory if not in a git repo.
- **HANDOFF_DIR**: `<ROOT>/.agents/handoff/`. Create it if missing.
- **ARGS**: the text following the skill invocation. (Claude Code exposes this as `$ARGUMENTS`; on other agents it is simply the rest of the user's message.)

Choose a phase:

- ARGS starts with a `YYYY-MM-DD-HHMM` datetime, or uniquely matches part of exactly one filename in HANDOFF_DIR → **resume**. If a partial match hits more than one file, list them and ask.
- ARGS is empty → **write-session** — unless the session is fresh (empty task list, no changed files, no work done), in which case **resume** the lexicographically last filename in HANDOFF_DIR. If HANDOFF_DIR is empty, say so and stop.
- Anything else → **write-prompt**.

Name every new document `<YYYY-MM-DD-HHMM>-<slug>.md`. Datetime-first keeps latest = lexicographically last. Build the slug from the session theme or prompt; lowercase `a-z0-9-` only (Windows-safe, sort-safe). If the exact filename already exists, append `-<SS>` (seconds).

## Write a Session Handoff

Write one document for the whole session. Copy pending and in-progress tasks from the task list, then write only the context the next session needs. Do not repeat material already captured in a plan, issue, ADR, commit, diff, or other artifact; link to it by path or URL instead.

Print this pointer and stop working:

```text
Handoff written: <path>
Clear this session, then invoke: handoff <YYYY-MM-DD-HHMM>-<slug>
```

## Write a Prompt Handoff

For free-text ARGS, write one focused handoff. Keep the prompt verbatim as the goal, make it the primary unfinished task, and include only related tasks and context. Slugify the prompt for the filename. Print the pointer above and stop.

## Finish a Write

For either write branch, a write is complete when the document exists, the pointer names it, and the response stops.

## Resume a Handoff

Locate and read the resolved document. If it is missing, list available handoffs and stop.

Recreate every unfinished task using your platform's task or plan tool, preserving each subject and description verbatim, and restore the task marked `in_progress` to that state:

- Claude Code: `TaskCreate` for each (in parallel), then `TaskUpdate` for the in-progress one.
- Codex: when `update_plan` is available, rebuild the list there and mark the in-progress step.
- No task tool available: restate the tasks as a checklist at the top of your first response and track them there for the rest of the session.

Then confirm in one line and continue with the in-progress task, or the first pending task:

```text
Resumed from <filename> — N tasks restored. Continuing: <subject>.
```

Resume state is rebuilt once every unfinished task exists and the in-progress task is restored.

## Document Template

Keep the narrative short. The next session should be able to act from this file and the linked artifacts.

```markdown
# Handoff: <slug>

<YYYY-MM-DD HH:MM TZ> · <project / branch> · Agent: <agent name>
Session: <session id, if your platform exposes one; omit otherwise>

## Unfinished Tasks

1. [in_progress] <subject> — <description>
2. [pending] <subject> — <description>

## Goal

<The purpose of this session or prompt.>

## Done

- <Completed and verified work, with paths.>

## In Progress / Next

<The exact next action and any partial state.>

## Key Files & Paths

- <Path and why it matters. Forward slashes.>

## Decisions & Gotchas

- <Decision, constraint, or trap.>

**Skills.** <Skills the next session should use, if any.>

## How to Verify

<Commands or checks that confirm the work still holds. Prefer cross-platform commands (git, node, package scripts); note the shell if one is required.>
```

The `Session:` line is optional metadata for transcript correlation (e.g. Claude Code's `$CLAUDE_CODE_SESSION_ID`); nothing in this skill depends on it. Omit `Unfinished Tasks` only when there are none. Keep handoff files for the user to prune or ignore; never delete them automatically.
