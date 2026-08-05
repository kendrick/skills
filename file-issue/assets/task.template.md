<!--
Task template. The catch-all: chores, tech debt, upgrades, cleanups, config
changes — anything that is neither a defect nor new capability.

This template exists to remove the "too small to write up" excuse. Its floor is
three things: a title, a description, and one acceptance criterion. Nothing
below that floor is worth filing; nothing above it needs more ceremony.

Strip every HTML comment before rendering the draft.
-->

# <title>

<!-- What changes, and where. Match observed title prefix conventions. -->

## What and Why

<!--
[gate] One or two sentences. The "why" is the part that survives — six months
on, nobody can reconstruct why a dependency was pinned or a module was split,
and the issue is the only place that reasoning ever lived.
-->

## Acceptance Criteria

<!--
[gate] At least one binary condition. For a task this is usually a single line,
and that is fine — the point is that someone other than you can tell when it is
finished.

  Bad:  "clean up the auth module"
  Good: "- [ ] `src/auth/` has no references to the deprecated `legacySession` helper"
-->

- [ ]

## Non-Goals

<!--
[default, convention] Include when the task sits next to work it must not
touch. Cleanups sprawl; this is where you say how far.
-->

## For a Coding Agent

<!--
Include only when the issue will be assigned to a coding agent — then every
line is a gate. Tasks are the category GitHub explicitly recommends handing to
agents (tech debt, test coverage, docs, accessibility), so this block earns its
place here more often than on the other templates.
-->

- **Verify with:** <the exact command>
- **Setup:** <deps, versions, env vars, or the file that documents them>
- **Start here:** <file and module paths>
- **Done when:** <binary condition>
- **Out of scope:** <what not to touch>
