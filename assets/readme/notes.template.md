# Notes

Meeting notes, transcripts, reading notes, and braindumps. The entry point for raw content that feeds `_memory/` records, `patterns-journal/` candidates, and deliverable synthesis.

## Two entry points

- **`_inbox/`**: drop raw files here with any filename and any shape. Transcripts, pasted emails, quick thoughts, hand-written notes. No frontmatter, no slug, no nanoid required. The agent processes them via "process the inbox" (or equivalent prompting) and moves them into this directory with proper metadata.
- **Direct authoring**: ask Claude to create a dated note. The agent scaffolds filename and frontmatter; you write the content.

## Groomed file convention

Filenames: `YYYY-MM-DD[-HHMM]-<slug>-<nanoid>.md`. Frontmatter, type vocabulary, and extraction rules are in [CLAUDE.md](CLAUDE.md).

## What feeds from here

Notes are the raw substrate for `_memory/` records, `patterns-journal/` entries, and any deliverable synthesis. The transformation is always agent-proposed and user-reviewed, never auto-applied.

For the full pipeline, see [`~/.claude/skills/inbox-to-memory/SKILL.md`](~/.claude/skills/inbox-to-memory/SKILL.md).
