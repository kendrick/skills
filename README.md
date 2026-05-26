# inbox-to-memory

A Claude Code skill for processing raw consulting-work inputs (transcripts, meeting notes, PDFs, slide decks, scratch braindumps) into structured markdown notes, and for proposing memory records across three scope tiers:

- **Project** memory, local to a single pursuit or delivery project.
- **Client** memory, shared across all engagements with one client.
- **Cross-client journal**, for patterns that generalize past any single client.

Aligned with the memory-bank schema at [`kendrick-at-slalom/memory-bank`](https://github.com/kendrick-at-slalom/memory-bank). Inspired by, not bound to.

## Install

```bash
git clone git@github.com:kendrick/inbox-to-memory.git ~/.claude/skills/inbox-to-memory
```

That's the whole install. The skill is auto-detected by Claude Code because it lives in `~/.claude/skills/`. To update later: `cd ~/.claude/skills/inbox-to-memory && git pull`.

## Use

Two modes, one skill, decided by the user's phrasing.

**Process mode** (default):

```
> drop a transcript into 11.04 NextEra/pursuits/atlas/notes/_inbox/
> "process the inbox"
```

The skill walks up to find the nearest opted-in directory, reads each file in `_inbox/`, produces one groomed markdown note per input (three zones: frontmatter, extracted sections, Raw Content), flags memory and journal candidates inline, and waits for user sign-off before crystallizing any records.

**Scaffold mode**:

```
> cd into a new project directory
> "scaffold a new project here"
```

A 3-question interview produces the `_inbox/`, `_memory/`, and `CLAUDE.md` for project, client, or journal scope. Idempotent; existing structure isn't clobbered.

## Layout

```
inbox-to-memory/
├── SKILL.md                          # the skill — both modes inline
├── README.md                         # this file
├── assets/                           # templates used at output time
│   ├── claude-md/{client,project,journal}.template.md
│   ├── note.template.md
│   └── records/{decision,policy-rule,exception,context,journal-entry}.template.md
└── references/                       # progressive-disclosure reading
    ├── extraction-heuristics.md      # quote selection, tensions, assumptions
    ├── scope-decisions.md            # project vs client vs journal proposal heuristics
    ├── memory-bank-schema.md         # vendored schema summary
    └── retrieval-funnel.md           # token-efficient querying at scale
```

## Concepts

- **Opted-in directory.** A directory is opted in when it contains `_inbox/` plus either `_memory/` (project or client scope) or `entries/` (journal scope). The skill refuses to operate on un-opted-in directories.
- **Three zones in a groomed note.** Frontmatter, then extracted sections (Notable Quotes, Tensions, Stated/Unstated Assumptions, Open Questions, Action Items / Memory Candidates), then `## Raw Content` verbatim.
- **Two-pass memory promotion.** The skill flags candidates inline (`[memory candidate: <scope>] ...`, `[journal candidate: ...]`). The user signs off per candidate before any record is created. Unpromoted candidates keep their prefix — useful as "considered, not crystallized" provenance.
- **Scope is sticky.** Once a record is created, its scope is fixed. Moving across scopes is a manual operation. Cross-scope references between records and notes are fine.

## License

MIT.
