# inbox-to-memory

A Claude Code skill for processing raw consulting work inputs (transcripts, meeting notes, PDFs, slide decks, scratch braindumps) into structured markdown notes, and for proposing memory records across three scope tiers:

- **Project** memory, local to a single pursuit or delivery project.
- **Client** memory, shared across all engagements with one client.
- **Cross-client journal**, for patterns that generalize past any single client.

Aligned with the memory-bank schema at [`kendrick-at-slalom/memory-bank`](https://github.com/kendrick-at-slalom/memory-bank). Inspired by, not bound to.

## Why This Exists

There's already a memory-bank schema at [`kendrick-at-slalom/memory-bank`](https://github.com/kendrick-at-slalom/memory-bank), with a hydrator agent and a set of `hydrate-*` skills. If you're hydrating a code repo from settled artifacts (existing decisions, ADRs buried in PRs, design docs), use that. Don't use this.

This skill exists for a different job: forward-filling a note-taking workspace from meeting transcripts, Office docs, PDFs, and raw notes.

Four things make it stand out from other tooling:

1. **A queue, not a backfill.** Drop a transcript into `_inbox/`. Drop a PPTX. Drop a scratch braindump. Drop a half-written email someone forwarded you. Process the queue. Then the source goes away: text files get deleted (their content lives on in the groomed note), binaries move to `attachments/`. The hydrate-\* skills point you at existing artifacts. This one drains a queue.

1. **Groomed notes as the durable thing.** A memory bank treats the source as authoritative and leaves it where it is. The records get extracted and stored separately; the source stays put. That doesn't fit when your source is a `.vtt` file that's only valuable once it's been processed. Here, every input produces one groomed markdown note: frontmatter on top, extracted sections in the middle, verbatim raw content at the bottom. The note becomes the thing you grep, the thing you wiki-link to, the thing you scan six months later when you've forgotten the conversation. Records link out from it.

1. **Cross-client patterns get a home.** A memory bank's scope model is single-tier; each bank is typically independent: project, team, domain, or org. There's no cross-bank concept. Consulting work needs a third tier for patterns that generalize past any one client. This skill adds a `Journal` record type and a cross-client journal directory for that purpose.

1. **Obsidian-native filenames.** `nanoid -s 10` slug filenames that wiki-link cleanly. No sequential `<ns>-ADR-<n>` IDs (those break under cross-scope nesting). No `uuid` field (Obsidian resolves by filename anyway). Small choices, but they add up when you're working in the vault every day.

## What You'd Lose by Just Using hydrate-\*

Honest assessment: strip those four out and you're left with `hydrate-*` wrapped in a different invocation style. The workflow phases, the record schema, the status lifecycle, and the retrieval funnel all match memory-bank's — because we adopted them. You could run `hydrate-extract`, `hydrate-draft`, and the rest one at a time in a manually-arranged directory, and the records would come out looking identical.

What you'd miss is the ergonomics. No inbox UX. No groomed-note artifact. No journal tier. No Obsidian-native filename conventions. The records exist but the conversational substrate they came from doesn't have a first-class home in your vault.

If those ergonomic deltas matter to you, this is the skill. If they don't, `hydrate-*` is enough.

## Install

```bash
# Highly recommended
npx skills add https://github.com/kendrick/inbox-to-memory
```

… or

```bash
git clone git@github.com:kendrick/inbox-to-memory.git ~/.claude/skills/inbox-to-memory
```

## Use

Two modes, one skill, decided by the user's phrasing.

**Process mode** (default):

```
> drop a transcript into /Users/Wherever/Your/Notes/Live/_inbox/
> "process the inbox"
```

The skill walks up to find the nearest opted-in directory, reads each file in `_inbox/`, produces one groomed markdown note per input (three zones: frontmatter, extracted sections, Raw Content), flags memory and journal candidates inline, and waits for user sign-off before crystallizing any records.

**Scaffold mode**:

```
> cd into a new project directory
> "scaffold a new project here"
```

A short interview stands up the substrate for project, client, or journal scope. Up to four questions, the last picks memory mode (lightweight Decision/Context/Rule, or canonical adding Exception). Idempotent; existing structure isn't clobbered. See [`SKILL.md`](SKILL.md#scaffold-mode) for what each scope emits.

## Layout

```
inbox-to-memory/
├── SKILL.md                          # the skill — both modes inline
├── README.md                         # this file
├── assets/                           # templates used at output time
│   ├── claude-md/*.template.md       # CLAUDE.md per scope and per work area
│   ├── readme/*.template.md          # README.md per scope and per work area
│   ├── records/*.template.md         # Decision, Rule, PolicyRule, Exception, Context, Journal
│   ├── note.template.md              # the groomed-note shape
│   ├── personal.template.md          # _personal.md for private goals and observations
│   ├── working-state.template.md     # narrative layer for project scope
│   └── patterns-journal/journal.template.md
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
- **Memory mode picked at scaffold time.** Lightweight (Decision, Context, Rule) or canonical (adds Exception for sanctioned deviations from a Rule). The choice is recorded in the scope's `CLAUDE.md` so later candidate flags use the right vocabulary.
- **`patterns-journal/` as engagement-internal staging.** Project and client scope each get a `patterns-journal/journal.md` for rough, tagged, append-only observations. Promotion to the cross-client journal is a deliberate weekly operation, not automatic.
- **`working-state.md` as the narrative layer.** Project scope adds a `working-state.md` between raw notes and crystallized memory records — decisions in motion, open questions, active hypotheses. Updated each session.

## License

MIT.
