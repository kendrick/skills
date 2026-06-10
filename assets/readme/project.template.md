# {{ProjectName}}

{{one-sentence-project-description}}

This README is the map of the project directory. For grounding context and design principles, see [CLAUDE.md](CLAUDE.md). For in-flight state and decisions, see [working-state.md](working-state.md). For private working notes, see [\_personal.md](_personal.md).

## Start here

- [CLAUDE.md](CLAUDE.md) — project-specific grounding, design principles, how Claude should behave. Read first.
- [working-state.md](working-state.md) — decisions log and current focus. Updated each session.
- [\_personal.md](_personal.md) — user's private working notes. Used for tradeoff decisions; never quoted in shared artifacts.

## Key dates

<!-- Optional table of milestones and due dates. Fill in as the project schedule firms up. -->

| Milestone | Due | Status |
| --------- | --- | ------ |

## Work areas

### Notes and memory

- [notes/](notes/) — meeting notes, transcripts, braindumps. Drop raw content in [notes/\_inbox/](notes/_inbox/) and ask the agent to "process the inbox." Conventions in [notes/CLAUDE.md](notes/CLAUDE.md).
- [\_memory/](_memory/) — structured records ({{MEMORY_TYPES}}). Queryable by Claude via Glob and Grep without loading full bodies. Conventions in [\_memory/CLAUDE.md](_memory/CLAUDE.md).

### Patterns journal

- [patterns-journal/](patterns-journal/) — running observations and cross-client pattern candidates. Reverse-chronological. Conventions in [patterns-journal/CLAUDE.md](patterns-journal/CLAUDE.md).

### Deliverables _(optional)_

<!-- Add a deliverables directory by hand when the project has client-facing artifacts to produce. -->

## How processing works

The [`inbox-to-memory`](~/.claude/skills/inbox-to-memory/SKILL.md) skill handles substrate setup and inbox grooming. Drop raw inputs into `notes/_inbox/`, then ask the agent to "process the inbox." Memory candidates and journal candidates are flagged inline and crystallized only after explicit sign-off.

## External links

<!-- Replace with project-specific external resources. -->
