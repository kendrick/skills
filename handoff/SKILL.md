---
name: handoff
description: Save a session handoff or resume one after `/clear`. Use `/handoff [id | prompt]` when you want the next Claude Code session to continue from a file instead of a compacted conversation.
disable-model-invocation: true
argument-hint: "[handoff id to resume | a prompt to hand off | empty for whole session]"
---

# Handoff

Write a handoff document before clearing a session, then use it to rebuild the work later. The document is the source of truth.

## Shared Paths and Phase Detection

Resolve these paths once for every phase. The git root is the project; use `$PWD` when Git is unavailable.

```bash
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || printf '%s\n' "$PWD")"
HANDOFF_DIR="$ROOT/.claude/handoff"
mkdir -p "$HANDOFF_DIR"
```

Use this detection before choosing a branch:

```bash
if [[ "$ARGUMENTS" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4}- ]] || [[ "$ARGUMENTS" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12} ]]; then
  PHASE=resume
elif [[ -z "$ARGUMENTS" ]]; then
  PHASE=write-session
else
  PHASE=write-prompt
fi
```

Treat a bare invocation as fresh when the task list is empty, no files have changed, and the conversation has not started work. In that case, resume the newest file in `$HANDOFF_DIR` (`ls | sort | tail -1`). If the directory has no handoff, say so and stop. A unique `*"$ARGUMENTS"*.md` match may identify a file; ask the user when it matches more than one.

Use `<YYYY-MM-DD-HHMM>-<slug>-<session-id>.md` for every new document. Build the slug from the session theme or prompt. Use `$CLAUDE_CODE_SESSION_ID`; if it is unavailable, use the most recently modified `*.jsonl` under `~/.claude/projects/<encoded-cwd>/`, where the encoded cwd replaces `/` with `-`.

## Write a Session Handoff

Write one document for the whole session. Copy pending and in-progress tasks from the task list, then write only the context the next session needs. Do not repeat material already captured in a plan, issue, ADR, commit, diff, or other artifact; link to it by path or URL instead.

Print this pointer and stop working:

```text
Handoff written: <path>
Run /clear, then: /handoff <datetime>-<slug>-<session-id>
```

## Write a Prompt Handoff

For free-text `$ARGUMENTS`, write one focused handoff. Keep the prompt verbatim as the goal, make it the primary unfinished task, and include only related tasks and context. Slugify the prompt for the filename. Print the pointer above and stop.

## Finish a Write

For either write branch, a write is complete when the document exists, the pointer names it, and the response stops.

## Resume a Handoff

Locate and read the resolved document. If it is missing, list available handoffs and stop. For every unfinished task, call `TaskCreate` in parallel and preserve its subject and description verbatim. Call `TaskUpdate` to restore the task marked `in_progress`. Then confirm in one line and continue with that task, or the first pending task:

```text
Resumed from handoff <session-id> — N tasks restored. Continuing: <subject>.
```

Resume state is rebuilt once every unfinished task has been created and the in-progress task is restored.

## Document Template

Keep the narrative short. The next session should be able to act from this file and the linked artifacts.

```markdown
# Handoff: <session-id>
<YYYY-MM-DD HH:MM TZ> · <project / branch>

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
- <Path and why it matters.>

## Decisions & Gotchas
- <Decision, constraint, or trap.>

**Skills.** <Skills the next session should use, if any.>

## How to Verify
<Commands or checks that confirm the work still holds.>
```

Omit `Unfinished Tasks` only when there are none. Keep handoff files for the user to prune or ignore; never delete them automatically.
