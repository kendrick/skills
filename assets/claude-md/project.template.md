# {{ProjectName}}

Note and memory processing for this {{pursuit|delivery project}} is handled by the [`inbox-to-memory`](~/.claude/skills/inbox-to-memory/SKILL.md) skill. Drop raw inputs into `notes/_inbox/` and ask the agent to "process the inbox" or "groom these notes."

## Scope

This {{pursuit|project}}'s memory lives at `_memory/` (subfolders: `context/`, `decisions/`, `policy-rules/`, `exceptions/`). Facts that span multiple {{pursuits|projects}} at this client belong at the client root's `_memory/`. Patterns that generalize beyond this client belong in the cross-client journal.

## Conventions inherited from the skill

- One groomed note per input. Three zones: frontmatter, extracted sections, Raw Content (verbatim).
- Memory candidates flagged inline as `[memory candidate: <scope>] <claim>`. Journal candidates as `[journal candidate: <pattern>]`. Crystallized only after user sign-off.
- Memory records follow the memory-bank schema: `memory_type` is one of Decision, PolicyRule, Exception, Context; status moves through `proposed → accepted → (superseded | deprecated | rejected)`.
- IDs come from `nanoid -s 10`. Record filenames are `<slug>-<nanoid>.md`; note filenames are `YYYY-MM-DD-<slug>-<nanoid>.md`.

## Deltas

<!-- {{ProjectName}}-specific overrides. Fill in during scaffold or regenerate. -->

**Note `type:` values for this {{pursuit|project}}:**
{{type-enum-values}}

**Active stakeholders:**
{{stakeholder-list}}

**Tag namespace (suggested):**
{{tag-list}}
