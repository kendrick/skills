# Claude context — {{ProjectName}}

> **Purpose of this file:** Project-specific grounding for Claude Code sessions in this directory. Inherits from the client root `CLAUDE.md` (engagement-wide context). Sibling work-area `CLAUDE.md` files in `notes/`, `_memory/`, and `patterns-journal/` add directory-specific conventions on top.
>
> **For current state and decisions in flight:** see [`working-state.md`](working-state.md). It's the living layer on top of this stable layer.
>
> **For private working notes:** [`_personal.md`](_personal.md). Never quoted in shared artifacts.
>
> **Memory mode:** {{MEMORY_MODE}} ({{MEMORY_TYPES}}).

---

## The {{pursuit|project}} in one paragraph

<!-- Fill in: who, what, when, why. Scope, timing, primary deliverables. 2-3 sentences. -->

## The user's role

<!-- Fill in: the user's specific role in this project. Reporting line, peers, scope of ownership. Often inherits from the client root and narrows. -->

## Repo organization

```
./
├── CLAUDE.md                     # this file
├── README.md                     # human-facing MOC
├── working-state.md              # decisions log + current focus (update each session)
├── _personal.md                  # user's private notes (not for shared artifacts)
├── _memory/                      # {{pursuit|project}} memory ({{MEMORY_TYPE_FOLDERS}})
├── notes/                        # raw notes + grooming workflow
│   ├── _inbox/                   # raw drop zone
│   └── attachments/              # binary sources after grooming
└── patterns-journal/             # running observations, reusable-pattern candidates
```

## Scope

This {{pursuit|project}}'s memory lives at `_memory/` (subfolders: {{MEMORY_TYPE_FOLDERS}}). Facts that span multiple {{pursuits|projects}} at this client belong at the client root's `_memory/`. Patterns that generalize beyond this client belong in the cross-client journal.

## Notes, memory, and synthesis

Same artifact pipeline as the client root, scoped to this {{pursuit|project}}.

- **Watch for journal candidates during all work.** When you observe something that might generalize beyond this client, flag inline with `[journal candidate: ...]` before continuing.
- **Watch for memory-bank-shaped content when processing notes.** Decisions made in meetings, facts established about the {{pursuit|project}}, rules crystallized in conversation are all candidates for `_memory/`. Propose during synthesis.
- **Stage, never auto-commit.** Outputs from grooming, synthesis, or promotion are always proposals.
- **Preserve raw notes as source of truth.** Records cite notes via `source_refs`; they don't replace them.
- **Query memory via Glob and Grep on filenames and frontmatter before reading bodies.** See [`_memory/CLAUDE.md`](_memory/CLAUDE.md) for the four-stage funnel.

Directory-specific conventions live in [`notes/CLAUDE.md`](notes/CLAUDE.md), [`_memory/CLAUDE.md`](_memory/CLAUDE.md), and [`patterns-journal/CLAUDE.md`](patterns-journal/CLAUDE.md).

## Conventions inherited from the skill

- One groomed note per input. Three zones: frontmatter, extracted sections, Raw Content (verbatim).
- Memory candidates flagged inline as `[memory candidate: <scope>] <claim>`. Journal candidates as `[journal candidate: <pattern>]`. Crystallized only after user sign-off.
- Memory records follow the {{MEMORY_MODE}} schema ({{MEMORY_TYPES}}; statuses `proposed | accepted | superseded | deprecated | rejected`).
- IDs come from `nanoid -s 10`. Record filenames are `<slug>-<nanoid>.md`; note filenames are `YYYY-MM-DD-<slug>-<nanoid>.md`.

## Deltas

<!-- {{ProjectName}}-specific overrides. Fill in during scaffold or regenerate as the {{pursuit|project}} evolves. -->

### Note `type:` values

Controlled vocabulary for note frontmatter `type:` field. Extends the skill's baseline.

{{type-enum-values}}

### Active stakeholders

Roster format: `Name — Role/Title. Additional facts (timezone, team affiliation, comms preference).`

These are stakeholders specific to this {{pursuit|project}}. Cross-engagement stakeholders live in the client root's `CLAUDE.md`.

{{stakeholder-list}}

### Transcription-error mapping

Common misheard names from meeting transcripts for this {{pursuit|project}}, with the canonical referent and (where applicable) a pointer to the client-level Context record. Used during inbox grooming to apply silent corrections (recorded in note frontmatter as `transcript_corrections:`).

<!-- Pattern (fill in as transcripts surface them):
> References to "<misheard>", "<misheard>", or sound-alikes are likely transcription errors and intend to refer to <Canonical Name> (client-level Context id <nanoid>).
-->

### Tag namespace (suggested)

Project-specific tags layered on top of the client-wide namespace.

{{tag-list}}

### Pre-existing content

<!-- Optional, only when a project subdirectory predates this substrate. Note any legacy folders (e.g., `pending_notes/`) and how they should be treated (e.g., "out of scope for the inbox queue; move into notes/_inbox/ to groom by hand"). -->
