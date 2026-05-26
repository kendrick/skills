# {{ClientName}}

Client-wide note and memory processing is handled by the [`inbox-to-memory`](~/.claude/skills/inbox-to-memory/SKILL.md) skill. Drop raw inputs into this directory's `notes/_inbox/` and ask the agent to "process the inbox."

## Scope

This client root holds two kinds of artifact:

- **Client-wide memory** at `_memory/` (subfolders: `context/`, `decisions/`, `policy-rules/`, `exceptions/`). Records here describe facts that hold across multiple of this client's pursuits and projects — stakeholder relationships, org chart, comms cadence, environmental tech facts.
- **Pursuit and project subdirectories** under `pursuits/` and `projects/`. Each opted-in subdirectory has its own `notes/_inbox/` and `_memory/`. Records there describe facts bound to that specific engagement.

Patterns that generalize beyond this client belong in the cross-client journal at `../11.99 Journal/`.

## When to write client-wide vs project-scoped

The skill proposes scope at candidate-flag time using heuristics in [references/scope-decisions.md](~/.claude/skills/inbox-to-memory/references/scope-decisions.md). The shortest version: project is the floor. Client scope requires positive evidence — a stakeholder fact that holds across projects, a tech-environment fact like "all NEE pursuits run on Databricks", a comms cadence that applies broadly.

## Conventions inherited from the skill

- One groomed note per input. Three zones: frontmatter, extracted sections, Raw Content (verbatim).
- Memory candidates flagged inline; crystallized only after user sign-off.
- Memory records use the memory-bank schema (`memory_type`, statuses `proposed | accepted | superseded | deprecated | rejected`).
- IDs from `nanoid -s 10`. Filenames `<slug>-<nanoid>.md` for records; `YYYY-MM-DD-<slug>-<nanoid>.md` for notes.

## Deltas

<!-- {{ClientName}}-specific overrides. Fill in during scaffold. -->

**Active engagements:**
{{engagement-list}}

**Cross-engagement stakeholders:**
{{stakeholder-list}}

**Client-wide tag namespace:**
{{tag-list}}
