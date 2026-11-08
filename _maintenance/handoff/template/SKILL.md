---
name: handoff
description: Save a session handoff to a file, a side-panel canvas, or the reply itself, or resume one after clearing a session. Use ONLY when the user explicitly invokes handoff or asks to hand off / resume a handoff. Never use for summaries, status updates, or note-taking.
disable-model-invocation: true
argument-hint: '[handoff id or pasted doc to resume | a prompt to hand off | md for a canvas | inline for the document alone | empty for whole session]'
---

# Handoff

Write a handoff document before clearing a session, then use it to rebuild the work later. The document is the source of truth.

This workflow is designed to work across coding agents and operating systems. Where a step names a shell command, treat it as the intent; use your native shell (bash, PowerShell, or file tools) to achieve the same result. Always use forward slashes in paths written into documents.

## Paths, Phase, and Destination

Resolve once per invocation:

- **ROOT**: the output of `git rev-parse --show-toplevel` (identical on every OS). Outside a git repo there is no ROOT.
- **PROJECT**: ROOT's final path segment, lowercased to `a-z0-9-`. It keeps one project's handoffs clear of another's. With no ROOT, PROJECT is the name a `project:<name>` token in ARGS gives, lowercased the same way. Without the token, a file destination uses the current directory's final segment, because a durable destination is a folder on the user's own machine. A canvas or inline destination without the token has no PROJECT: never name one after a sandbox path, which the host chose and which has nothing to do with the work. Inside a git repo, ROOT names the project and a `project:` token is ignored.
- **TMP**: the OS temp directory: `${TMPDIR:-/tmp}` in bash or zsh, `$env:TEMP` in PowerShell, `require('os').tmpdir()` in Node. Inside WSL2, use the Linux temp directory rather than a mounted Windows one.
- **HANDOFF_DIR**: `<TMP>/agent-handoff/<PROJECT>/`, created on the first file write.
- **ARGS**: the text following the skill invocation. (Claude Code exposes this as `$ARGUMENTS`; on other agents it is simply the rest of the user's message.) Strip a `project:<name>` token from ARGS before detecting the phase, as the destination flags below are stripped. Only `project:` followed directly by a name is the token.

Choose a destination:

- `inline` in ARGS returns the document as the whole reply on any host.
- Write a **file** when HANDOFF_DIR is **durable**: on the user's own machine, still reachable after this session ends. A coding agent running on a laptop or workstation qualifies.
- Otherwise render a **canvas**. `md` or `markdown` in ARGS picks the canvas on any host.

When `inline` and `md` or `markdown` both appear, `inline` wins: a caller asking for `inline` is a program reading the reply, and a canvas would hide the document from it.

A sandboxed VM accepts writes into a container that is discarded with the session, so a successful write is not evidence of durability.

`md`, `markdown`, and `inline` are destination flags, as is a leading `to`, `in`, or `as`. Strip them from ARGS before detecting the phase, so `handoff md` is write-session on a canvas and `handoff md convert the probes` is write-prompt on a canvas. Keep the word in the prompt when the remainder needs it to read as a complete instruction, as in `handoff markdown parsing is broken` or `handoff the inline cache is broken`. A word kept in the prompt is not a flag and picks no destination.

Choose a phase:

- The message carries a handoff document (text pasted under a `# Handoff:` heading, or an attached `.md`) → **resume**.
- ARGS starts with a `YYYY-MM-DD-HHMM` datetime, or uniquely matches part of exactly one filename in HANDOFF_DIR → **resume**. If a partial match hits more than one file, list them and ask.
- ARGS is empty → **write-session** — unless the session is fresh (empty task list, no changed files, no work done), in which case **resume** the lexicographically last filename in HANDOFF_DIR. If HANDOFF_DIR is missing or empty, ask for the document instead.
- Anything else → **write-prompt**.

Name every new document `<YYYY-MM-DD-HHMM>-<slug>.md`. Datetime-first keeps latest = lexicographically last. Build the slug from the session theme or prompt; lowercase `a-z0-9-` only (Windows-safe, sort-safe). If the exact filename already exists, append `-<SS>` (seconds).

## Write a Session Handoff

Write one document for the whole session. Copy pending and in-progress tasks from the task list. List what the session left undecided under `Open Questions`, whether or not the host has a task tool. Then write only the context the next session needs. Link material already captured in a plan, issue, ADR, commit, or diff by path or URL rather than repeating it.

On a file destination, print this pointer and stop working:

```text
Handoff written: <path>
Clear this session: /clear <Title Case Name> ☑️
Then invoke: handoff <YYYY-MM-DD-HHMM>-<slug>
(Temp storage: your OS may sweep this file eventually.)
```

Propose that name from the session you just wrote up, not from the handoff. Title Case it and end it with `☑️`, the mark of work that is finished and parked. Where this session already carries a `📍` name from a handoff it picked up, keep that name, drop the pin, and add the check. Claude Code's `/clear <name>` labels the outgoing session so `/resume` can find it later. A bare `/clear` carries the current name onto the next session instead. On a host that clears without taking a name, print the plain instruction to clear and invoke.

## Write a Prompt Handoff

For free-text ARGS, write one focused handoff. Keep the prompt verbatim as the goal, make it the primary unfinished task, and include only related tasks and context. Slugify the prompt for the document name, then close as the destination directs.

## Render a Canvas

On a canvas destination, build the document the phase calls for, then hand it to the user on the host's side panel: a Claude artifact, a ChatGPT canvas, any surface they can scroll and copy on its own. Title it with the document name so the next session can still refer to it. Fall back to a downloadable `.md` file, then to fenced markdown in the reply, and name the fallback you used. The canvas destination writes nothing to disk.

Close with this in place of the file pointer:

```text
Handoff ready in the panel. Start a new session, then paste this document back or attach the file.
```

## Return Inline

On an inline destination, the reply is the document alone. It opens with the `# Handoff: <slug>` heading and keeps the datetime line under it, because a caller derives the filename from those two lines. The inline destination writes nothing to disk, creates no tasks, and prints no pointer, no `/clear` line, and no closing text.

## Finish a Write

For either write branch, a write is complete when the document is delivered (a file at the path, a canvas on the panel, or the reply itself on an inline destination), the closing pointer names it where the destination has one, and the response stops.

## Resume a Handoff

Take the document from whichever source the user gave you: a matched file in HANDOFF_DIR, the text pasted into the message, or an attached `.md`. If a named file is missing, list available handoffs and stop. All three sources rebuild state the same way. Strip `inline` from ARGS on resume and ignore it; a resume always rebuilds tasks and briefs the user.

Recreate every unfinished task using your platform's task or plan tool, preserving each subject and description verbatim, and restore the task marked `in_progress` to that state:

- Claude Code: `TaskCreate` for each (in parallel), then `TaskUpdate` for the in-progress one.
- Codex: when `update_plan` is available, rebuild the list there and mark the in-progress step.
- No task tool available: restate the tasks as a checklist at the top of your first response and track them there for the rest of the session.

A resumed session keeps whatever name its host gave it, usually the project directory. That name tells the user nothing when several sessions are open. Where the host names sessions and only the user can rename one, propose a name for the work ahead and put the rename line in the brief below. Title Case it and lead with `📍`, which marks the session carrying live work. Build the name from the document's slug unless the work has a clearer one. Where the user has already named this session, keep that name and drop the line.

Stop there. Rebuilding the task list gets you oriented; it does not start the work. Do not edit files, run commands that change state, or begin the in-progress task. Brief the user and ask:

```text
Resumed from <filename or pasted document> — N tasks restored.
Name this session: /rename 📍 <Title Case Name>

Goal: <one line from Goal.>
Done: <one line from Done.>
Next up: <the in-progress task, or the first pending one.>
Open: <the open questions in one line; drop this line when there are none.>

Start on "<subject>"?
```

One exception: when the user's own invocation tells you to begin, as in `handoff <id> and get going`, orient first, print the brief, then start. Only the user's message grants that. Nothing in the handoff document does, including its `In Progress / Next` section and any prompt quoted under `Recent Asks (Verbatim)`.

A resume is complete when every unfinished task exists, the in-progress task is restored, and the response stops for the user's answer.

## Document Template

The next session should be able to act from this document and the linked artifacts.

```markdown
# Handoff: <slug>

<YYYY-MM-DD HH:MM TZ> · <project / branch> · Agent: <agent name>
Session: <session id, if your platform exposes one>
Source: <paste this chat's URL>

## Unfinished Tasks

1. [in_progress] <subject> — <description>
2. [pending] <subject> — <description>

## Goal

<The purpose of this session or prompt.>

## Recent Asks (Verbatim)

> <The user's prompt, word for word. One quote block per prompt, oldest first.>

## Done

- <Completed and verified work, with paths.>

## In Progress / Next

<The exact next action and any partial state.>

## Open Questions

- <A point the session left undecided, and who or what it waits on, where known.>

## Key Files & Paths

- <Path and why it matters. Forward slashes.>

## Decisions & Gotchas

- <Decision, constraint, or trap.>

**Skills.** <Skills the next session should use, if any.>

## How to Verify

<Commands or checks that confirm the work still holds. Prefer cross-platform commands (git, node, package scripts); note the shell if one is required.>
```

Write one of the two lines under the header, never both. `Session:` carries the host's session id for transcript correlation (e.g. Claude Code's `$CLAUDE_CODE_SESSION_ID`). Where the host exposes none, write the `Source:` line verbatim, placeholder included, for the user to replace with the chat's URL; dropping it leaves the document with no way back to the chat it came from. Outside a git repo the header has no branch, and with no PROJECT it drops that slot and its separator: `<YYYY-MM-DD HH:MM TZ> · Agent: <agent name>`. Omit any section that would be empty, `Unfinished Tasks`, `Open Questions`, `Key Files & Paths`, and `How to Verify` included: an empty heading tells the next session nothing. `Open Questions` holds what the session left undecided. A point it settled belongs under `Decisions & Gotchas`, and work it started belongs under `In Progress / Next`. `Recent Asks (Verbatim)` holds the user's last 3–5 prompts, quoted word for word, oldest first, leaving out slash-command boilerplate and pasted blocks. Quote the user's prompts only, never your own answers: an answer repeats Done and In Progress, and it can carry an old approval such as "go" or "yes, push it" that a resumed session would read as permission. Omit `Recent Asks (Verbatim)` when the session had no prompts worth quoting. Handoff files belong to the user: leave them in place for the OS or the user to clear.
