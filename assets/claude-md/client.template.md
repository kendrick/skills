# Claude context — {{ClientName}}

> **Purpose of this file:** Client-wide grounding for Claude Code sessions in this repo. Everything below applies to all work in this directory, regardless of which subdirectory you're in. Project and pursuit `CLAUDE.md` files add area-specific conventions on top of this foundation.
>
> **For current state and decisions in flight:** see [`working-state.md`](working-state.md) at the repo root (if present at the client level) or the relevant project's working-state.
>
> **Memory mode:** {{MEMORY_MODE}} ({{MEMORY_TYPES}}).

---

## The client in one paragraph

<!-- Fill in: 2-3 sentences describing who the client is, what industry, what scale, what relationship Slalom has, what the active engagements are. Example: "Industrial automation client, ~3k developers across 15 countries. Slalom has run three engagements over 18 months; current focus is AI-assisted PDLC coaching." -->

## The user's role

<!-- Fill in: the user's role across this client's engagements. Reporting line, peers, scope of ownership. -->

## Key context about {{ClientName}}

<!-- Fill in: industry posture, scale, tech environment, regulatory environment, prior history with Slalom, anything stable enough to live at client scope. Things that change should go in working-state.md or in project-scoped CLAUDE.md instead. -->

## Repo organization

```
./
├── CLAUDE.md                     # this file
├── README.md                     # human-facing MOC
├── _personal.md                  # user's private notes (not for shared artifacts)
├── _memory/                      # client-wide memory ({{MEMORY_TYPE_FOLDERS}})
├── notes/                        # client-wide notes
│   ├── _inbox/                   # raw drop zone
│   └── attachments/              # binary sources after grooming
├── patterns-journal/             # running observations, reusable-pattern candidates
├── projects/                     # delivery projects (each with its own substrate)
└── pursuits/                     # pre-sales work (lightweight substrate; graduates to projects/ if it converts)
```

Each project or pursuit subdirectory has its own `CLAUDE.md` that inherits from this file by virtue of being in the same tree — those files don't repeat client context; they add to it.

## Scope: client-wide vs project-scoped

This client root holds two kinds of artifact:

- **Client-wide memory** at `_memory/` (subfolders: {{MEMORY_TYPE_FOLDERS}}). Records here describe facts that hold across multiple of this client's pursuits and projects — stakeholder relationships, org chart, comms cadence, tech-environment facts.
- **Pursuit and project subdirectories** under `pursuits/` and `projects/`. Each opted-in subdirectory has its own `notes/_inbox/` and `_memory/`. Records there describe facts bound to that specific engagement.

Patterns that generalize beyond this client belong in the cross-client journal at `../11.99 Journal/`.

### When to write client-wide vs project-scoped

The skill proposes scope at candidate-flag time using heuristics in [`~/.claude/skills/inbox-to-memory/references/scope-decisions.md`](~/.claude/skills/inbox-to-memory/references/scope-decisions.md). The shortest version: project is the floor. Client scope requires positive evidence — a stakeholder fact that holds across projects, a tech-environment fact that applies broadly, or a comms cadence that's actually client-wide.

## Notes, memory, and synthesis

This directory uses the artifact pipeline from the [`inbox-to-memory`](~/.claude/skills/inbox-to-memory/SKILL.md) skill: raw notes in `notes/` flow into `_memory/` records and `patterns-journal/` candidates, all as user-reviewed proposals.

Key behaviors:

- **Watch for journal candidates during all work.** When you observe something that might generalize beyond {{ClientName}} (a methodology pattern, an anti-pattern, a coaching insight), flag it inline with `[journal candidate: ...]` before continuing. Catch them as they occur; don't try to re-detect at session end.
- **Watch for memory-bank-shaped content when processing notes.** Decisions made in meetings, facts established about the engagement, rules crystallized in conversation are all candidates for `_memory/` records. Propose during synthesis; don't wait for explicit request.
- **Stage, never auto-commit.** Outputs from grooming, synthesis, or promotion are always proposals. The user reviews and commits.
- **Preserve raw notes as source of truth.** Memory records and journal entries cite notes via `source_refs`; they don't replace them.
- **Query memory via Glob and Grep on filenames and frontmatter before reading bodies.** See [`_memory/CLAUDE.md`](_memory/CLAUDE.md) for the four-stage funnel.

Directory-specific conventions live in [`notes/CLAUDE.md`](notes/CLAUDE.md), [`_memory/CLAUDE.md`](_memory/CLAUDE.md), and [`patterns-journal/CLAUDE.md`](patterns-journal/CLAUDE.md).

## Conventions inherited from the skill

- One groomed note per input. Three zones: frontmatter, extracted sections, Raw Content (verbatim).
- Memory candidates flagged inline; crystallized only after user sign-off.
- Memory records use the {{MEMORY_MODE}} schema ({{MEMORY_TYPES}}; statuses `proposed | accepted | superseded | deprecated | rejected`).
- IDs from `nanoid -s 10`. Filenames `<slug>-<nanoid>.md` for records; `YYYY-MM-DD-<slug>-<nanoid>.md` for notes.

## File and writing conventions

- **Markdown for working files.** YAML frontmatter on Markdown for memory records specifically.
- **Lowercase, hyphen-separated filenames.** `discovery-questions.md`, not `Discovery Questions.md`. No spaces. No uppercase. Numbers prefix files when order matters.
- **Reverse chronological for logs.** The patterns journal and any other append-only logs have newest entries at the top.
- **Dated entries use ISO format.** `2026-04-22`, not `April 22, 2026`.
- **Working files include their status and last-updated date at the top.** "Status: v0 strawman" and similar markers make it clear what version of the thinking a reader is looking at.

## How Claude should behave

### Tone and approach

- **Be a thinking partner, not a scribe.** The user has a strong sense of what they want; Claude's job is to help think it through, push back where appropriate, and produce artifacts that reflect genuine design reasoning rather than defaults.
- **Push back on over-engineering.** Lean, adoptable practices beat exhaustive structure that nobody uses. When the user (or your own instincts) start adding structure that isn't earning its place, flag it. Better to strip now than refactor later.
- **Ask before making big design changes.** If you're about to propose a substantive change to settled work, raise it as a question first; don't just draft the change.
- **Match the user's tone:** direct, specific, willing to be wrong, allergic to vague generalities.

### Working with existing files

- **Read the file you're about to modify end-to-end before modifying it.** Working files accumulate rationale in sections like "open questions" and "common mistakes." Losing that by accident is expensive.
- **Preserve rationale even when updating decisions.** If a decision changes, the new version should acknowledge the old one — _"we originally chose X but discovery showed Y, so we moved to Z"_ — rather than silently overwriting.
- **Cross-file consistency matters.** If you update a field in one working file, check whether sibling files reference it and update there too.

### Uncertainty and honesty

- **When something is unclear, say so.** _"I'm not sure whether this is what we agreed"_ is better than confidently re-deriving a decision that was already made with different reasoning.
- **When the engagement is moving in a direction that concerns you, say so directly.** Time pressure can push toward choices that look fine in the moment but create downstream pain.

## Deltas

<!-- {{ClientName}}-specific overrides. Fill in during scaffold or as the client engagement evolves. -->

### Active engagements

{{engagement-list}}

### Cross-engagement stakeholders

Roster format: `Name — Role/Title. Additional facts (timezone, team affiliation, comms preference).`

These are stakeholders who appear across multiple of this client's projects. Project-specific stakeholders live in the project's own CLAUDE.md.

{{stakeholder-list}}

### Transcription-error mapping

Common misheard names from meeting transcripts, with the canonical referent. Used during inbox grooming to apply silent corrections (recorded in note frontmatter as `transcript_corrections:`).

<!-- Pattern (fill in as transcripts surface them):
> References to "<misheard>", "<misheard>", or sound-alikes are likely transcription errors and intend to refer to <Canonical Name> (Context id <nanoid>).
-->

### Client-wide tag namespace

Controlled vocabulary for memory record `tags:` frontmatter. Project-level tags layer on top.

{{tag-list}}

## Current state pointer

This `CLAUDE.md` captures stable client-wide grounding. For what's changed recently — decisions made since this file was written, work in flight, open questions being actively resolved — consult the active project's `working-state.md` before assuming this file is the whole picture. Working-state is the living layer on top of this stable layer.
