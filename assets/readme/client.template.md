# {{ClientName}}

Client-wide notes, memory, and patterns for {{ClientName}} engagements.

This README is a map of the directory. For grounding context and design principles, see [CLAUDE.md](CLAUDE.md). For private working notes, see [\_personal.md](_personal.md).

## Start here

- [CLAUDE.md](CLAUDE.md) — engagement-wide grounding, design principles, how Claude should behave in this repo. Read first.
- [\_personal.md](_personal.md) — the user's private working notes. Used for tradeoff decisions; never quoted in shared artifacts.

## Work areas

### Notes and memory

- [notes/](notes/) — meeting notes, transcripts, braindumps. Drop raw content in [notes/\_inbox/](notes/_inbox/) and ask the agent to "process the inbox." Conventions in [notes/CLAUDE.md](notes/CLAUDE.md).
- [\_memory/](_memory/) — structured records. Queryable by Claude via Glob and Grep without loading full bodies. Conventions in [\_memory/CLAUDE.md](_memory/CLAUDE.md); query guide in [\_memory/README.md](_memory/README.md).

### Patterns journal

- [patterns-journal/](patterns-journal/) — running observations and reusable-pattern candidates. Reverse-chronological. Conventions and weekly-review ritual in [patterns-journal/CLAUDE.md](patterns-journal/CLAUDE.md).

### Projects and pursuits

- [projects/](projects/) — opted-in delivery projects. Each project has its own substrate (CLAUDE.md, _memory/, notes/, etc.). _(Add as engagements start.)_
- [pursuits/](pursuits/) — opted-in pre-sales work. Lightweight scaffold. _(Add when pursuits open; if a pursuit converts to delivery, graduate it to projects/.)_

## Cross-client journal

Patterns that generalize beyond {{ClientName}} live in the [cross-client journal](../11.99%20Journal/). Promotion from this client's `patterns-journal/` to the cross-client journal is a deliberate operation — see [patterns-journal/CLAUDE.md](patterns-journal/CLAUDE.md).

## How processing works

The [`inbox-to-memory`](~/.claude/skills/inbox-to-memory/SKILL.md) skill handles substrate setup and inbox grooming. Drop raw inputs into any `_inbox/`, then ask the agent to "process the inbox." Memory candidates and journal candidates are flagged inline and crystallized only after explicit sign-off.

## External links

<!-- Replace with engagement-specific external resources. -->
