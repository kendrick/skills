# Notes: agent conventions

> **Audience:** Claude working in this directory.
>
> **Inherits from:** the scope's root `CLAUDE.md`.

Grooming isn't just filename and frontmatter. It produces a normalized, extracted file: frontmatter on top, summary-style body sections in the middle, raw content verbatim at the bottom. The raw content is the source of truth; the extracted sections are the agent's contribution and require review before commit.

## The inbox

`notes/_inbox/` is the raw-drop zone. Files there have any filename, any shape, and no frontmatter.

When the user asks to groom the inbox (or invokes "process the inbox"), for each file:

1. **Infer metadata.**
   - `date` from content (top of transcript, meeting subject). Fall back to file mtime only if nothing in content suggests a date.
   - `type` from shape — see the scope's root `CLAUDE.md` Deltas section for the `type:` enum.
   - `attendees` from transcript speakers or explicit meeting header.
   - `tags` and `topics` from controlled vocabularies in the root `CLAUDE.md`.
   - `related` only when content contains an **explicit reference** to a known nanoid or record title. Do not guess from topical similarity.
2. **Ask the user for anything ambiguous.** Don't fabricate.
3. **Generate a nanoid** via the globally-installed CLI (`nanoid -s 10`) and propose a kebab-case slug.
4. **Extract summary sections** (see "Body structure" below).
5. **Flag journal candidates inline** in the raw content as you read them.
6. **Apply transcription corrections** if the root `CLAUDE.md` Deltas section lists known sound-alike mappings. Record what you applied in the note's frontmatter as `transcript_corrections: [Saatchi→Shachi, Lince→Lancey]`.
7. **Assemble the groomed file:** frontmatter, then extracted body sections, then `## Raw Content` with the verbatim original.
8. **Rename and move:** `YYYY-MM-DD[-HHMM]-<slug>-<nanoid>.md`, out of `_inbox/` into `notes/`.
9. **Clean up the source file.** The inbox is a queue — nothing stays after grooming.
   - **Text sources** (`.md`, `.txt`, `.vtt`): delete from `_inbox/`. Raw content is preserved in the groomed note.
   - **Binary sources** (`.pdf`, `.docx`, `.pptx`): move to `notes/attachments/`. Extraction is lossy; keep the original. Set `source_file: attachments/filename.ext` in the groomed note.
10. **Summarize what was groomed and extracted.** Do not auto-commit. The user reviews extractions before committing.

## Direct authoring

When the user asks to create a fresh note (not an import):

1. Ask for `type` if ambiguous.
2. Generate a nanoid.
3. Create `notes/YYYY-MM-DD[-HHMM]-<slug>-<nanoid>.md` with scaffolded frontmatter and an empty `## Raw Content` section.
4. Let the user write. Extraction runs later on demand.

## Groomed file structure

```
---
<frontmatter>
---

## Notable Quotes

## Tensions

## Stated Assumptions

## Unstated Assumptions

## Open Questions

## Action Items / Memory Candidates

## Raw Content

<verbatim original, may contain inline [journal candidate:] markers>
```

Order matters. Summary sections come first for human scan-ability and cheap agent retrieval. Raw content stays the source of truth at the bottom.

## Frontmatter schema

```yaml
---
id: <nanoid>
date: YYYY-MM-DD
type: {{NOTE_TYPE_ENUM}}
attendees: []       # if meeting-shaped
tags: []            # from controlled vocabulary in root CLAUDE.md
topics: []          # from controlled vocabulary in root CLAUDE.md
related: []         # refs to other notes/records by id, only when explicitly referenced
source_file: ""     # optional, binary sources only — "attachments/<filename>"
transcript_corrections: []  # optional — applied sound-alike mappings, e.g. [Saatchi→Shachi]
---
```

Required: `id`, `date`, `type`. Everything else optional but populated where inferable.

## Extracted sections — what to pull

Apply heuristics from [`~/.claude/skills/inbox-to-memory/references/extraction-heuristics.md`](~/.claude/skills/inbox-to-memory/references/extraction-heuristics.md). Short version:

- **Notable Quotes** — up to 6-12 passages with line references. Pull quotes that contain numbers or estimates, express pain or rework, assert a strong or surprising claim, or capture a disagreement with common wisdom.
- **Tensions** — disagreements, opposing claims, places where two sources contradict.
- **Stated / Unstated Assumptions** — split. Stated are claimed; unstated are implied by structure or omission.
- **Open Questions** — substantive (escalate to `working-state.md` open questions list) and clarifying (stay with the note).
- **Action Items / Memory Candidates** — bullets with owner bolded; memory candidates use the `[memory candidate: <scope>]` prefix per [`~/.claude/skills/inbox-to-memory/references/scope-decisions.md`](~/.claude/skills/inbox-to-memory/references/scope-decisions.md).

## Inline flags during reading

While reading the raw content during grooming, when you notice an observation that might generalize beyond this client, add an inline marker right after the triggering passage:

```markdown
participants finally spoke up after a ten-second pause. `[journal candidate: deliberate pauses produce non-dominant-voice participation in group sessions]`
```

These stay in the raw content zone. Pattern reviews collect them later via `Grep "\[journal candidate:" notes/`. Do not move flagged observations into the top extracted sections — the surrounding context is part of what makes them useful.

## Collision handling

If a groomed filename already exists:

1. Add a time suffix (`YYYY-MM-DD-HHMM-<slug>-<nanoid>.md`).
2. Still colliding: refine the slug to be more specific.
3. Nanoid-only fallback is the last resort.

Nanoids are unique by construction, so collisions are filename-level only.

## What to never do

- Auto-commit groomed files or extractions. The user reviews and commits.
- Fabricate dates, attendees, quotes, or cross-references.
- Rewrite or summarize the raw content. Extract from it; preserve it verbatim underneath.
- Populate `related` based on topical similarity. Explicit reference only.
- Put journal entries or memory records in this directory. Those are agent-created elsewhere via promotion.
- Treat extracted sections as canonical. They are best-effort extraction from raw, subject to user correction.
