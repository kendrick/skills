# Section Templates by Project Type

Loaded at Step 4 for root scope. Start from the funnel order in SKILL.md, then apply the type's deltas below: which sections grow, which shrink to a line, which vanish. Adapt — don't copy blindly. Every type obeys proportionality: the README's length tracks the project's surface area, not the template's.

## Library / Framework

The reader is a developer deciding whether to depend on you.

- **Grow:** install (per package manager actually used), quickstart (smallest complete snippet with its output), API reference or a link to generated docs. The bar: usable without reading the source.
- **Keep:** highlights (what it does that alternatives don't), supported language/runtime versions, contributing, license.
- **Background** section when the library implements a non-obvious concept — a paragraph of context saves readers a detour to a paper or spec.
- Frameworks additionally: a "how the pieces fit" overview and a link to a starter/example app; a Mermaid diagram only if there are genuinely multiple interacting components.

## CLI Tool

The reader wants to run a command in the next sixty seconds.

- **Grow:** install (all channels: brew, npm, cargo, binary release), a demo — terminal GIF or asciinema near the top — and a commands/flags section covering the common invocations with expected output. A table of subcommands beats prose.
- **Shrink:** API-style reference (point to `--help` or generated docs), background.
- Must show at least one full invocation → output pair; a CLI README without a visible command run fails the funnel.

## Application (web app, service, desktop)

The reader wants it running locally, then deployed.

- **Grow:** prerequisites and setup (exact versions), configuration — every required env var with purpose and example value, `.env.example` pointed to, and the explicit rule that secrets never land in the repo. Screenshots of the actual interface.
- **Keep:** development (run, test, seed), deployment notes or a link.
- **Shrink:** highlights — an app's screenshot sells it faster than a feature list.

## Docs / Learning Repo

The reader navigates; nothing installs.

- **Grow:** structure — a map of what's here and the intended reading order. Navigation is the quickstart.
- **Vanish:** install, usage, configuration (unless the docs themselves build; then a short "build the docs" under development).
- **Keep:** contributing (docs repos live on corrections), license.

## Config / Dotfiles / Small Utility

The reader is future-you, confused. Cap the README at hero + what-it-does + usage — often under 30 lines.

- Sections that earn their place: **What's Here** (annotated file map), **How to Extend**, **Gotchas** (the constraint you'll forget by next quarter), **Last Reviewed** date — config rots silently, so date it.
- **Vanish:** contributing and license unless the repo is public OSS, badges, ToC, background.

## Monorepo / Multi-Package Workspace

The root README orients; it does not document any single package.

- **Grow:** the map — a table of packages/workspaces with one-line purposes, each linking to its own nested README (write those with [nested-readmes.md](nested-readmes.md)). Repo-wide setup: toolchain, bootstrap command, how to run everything at once.
- **Shrink:** per-package usage — one representative example at most; depth lives in the nested READMEs.
- **Keep:** contributing conventions that span packages (commit format, release process), license.
- The root owns global claims (license, contribution policy) exactly once; packages link up rather than restate.

## When Types Overlap

Real projects mix signals — a library that ships a CLI, an app inside a monorepo. Pick the primary type by who the main reader is, apply its deltas, then borrow the single most valuable section from the secondary type (usually the CLI demo or the app's env-var table). Two full templates merged is how READMEs sprawl.
