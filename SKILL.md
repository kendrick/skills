---
name: inbox-to-memory
description: Process raw inputs (transcripts, meeting notes, PDFs, slide decks, scratch braindumps) from a `_inbox/` queue into one groomed markdown note per input, and propose memory records across three scope tiers — project, client, and a cross-client journal. Use whenever the user wants to process the inbox, groom notes, drain the inbox, crystallize a memory candidate, promote something to memory or to a journal — even if they don't say "skill" or name a file type. Also use to set up the substrate for a new project, client, or the journal — scaffold a new project here, set up notes substrate, spin up a client, set up the journal, create a memory bank here. Client and project scaffolds default to a lightweight 3-type memory schema (Decision/Context/Rule) with a canonical 4-type opt; they also produce a README, `_personal.md`, `working-state.md` (project scope), and a `patterns-journal/`. Only operates on opted-in directories (containing `_inbox/` plus either `_memory/` or `entries/`).
---

# inbox-to-memory

Two modes:

- **Process** (default): pulls raw inputs from a `_inbox/` queue, produces one groomed markdown note per input, and proposes memory records or journal entries for the user to approve.
- **Scaffold**: stands up the directory structure and CLAUDE.md for a new scope — a project, a client, or the cross-client journal.

Decide the mode from the user's phrasing. When ambiguous, ask.

| Phrasing                                                                                                                             | Mode     |
| ------------------------------------------------------------------------------------------------------------------------------------ | -------- |
| "process the inbox", "groom these notes", "drain the inbox", "crystallize this candidate", "promote to memory", "promote to journal" | process  |
| "scaffold a new project here", "set up notes substrate", "spin up a client", "set up the journal", "create a memory bank here"       | scaffold |

---

## Process mode

Six phases. The user reviews and approves between phase 4 and phase 5; never auto-promote.

### Phase 1 — Detect scope

Walk up from the user's cwd to find the nearest opted-in directory. A directory is opted in when it contains both `_inbox/` and one of these markers:

- `_memory/` → project or client scope.
- `entries/` → journal scope.

Distinguish project from client scope by path: a project sits under `pursuits/<name>/` or `projects/<name>/`; a client root is the directory that _contains_ those (and is itself opted in). Journal scope is set by the `entries/` marker.

State the detected scope and root path back to the user before doing anything destructive. If nothing is opted in, stop and ask whether to scaffold — do not create directories silently.

### Phase 2 — Extract content from each inbox file

For each file in `_inbox/`, dispatch by extension:

| Extension             | Tool                    |
| --------------------- | ----------------------- |
| `.md`, `.txt`, `.vtt` | Read directly           |
| `.pdf`                | invoke the `pdf` skill  |
| `.docx`               | invoke the `docx` skill |
| `.pptx`               | invoke the `pptx` skill |
| anything else         | ask the user            |

While reading, apply the extraction heuristics in [references/extraction-heuristics.md](references/extraction-heuristics.md). The short version: pull 6-12 surprising or contradictory quotes; flag tensions; split stated and unstated assumptions; capture action items with owner + priority; tag cross-note relationships as `confirms | contradicts | extends | introduces`.

### Phase 3 — Groom into a single note

Emit one note per input at `<scope-root>/notes/YYYY-MM-DD-<slug>-<nanoid>.md`. The template is at [assets/note.template.md](assets/note.template.md).

Three zones, always in this order:

1. **Frontmatter** — `id`, `date`, `type`, `attendees`, `tags`, `topics`, optional `source_file` (binary sources only), optional `related`.
2. **Extracted sections** — `## Notable Quotes`, `## Tensions`, `## Stated Assumptions`, `## Unstated Assumptions`, `## Open Questions`, `## Action Items / Memory Candidates`.
3. **Raw Content** — `## Raw Content` followed by the verbatim original (text sources) or extracted text (binary sources). Always last.

Inside the extracted sections, flag candidates **inline** using the taxonomy below. Don't hide candidates in a separate file or section — keep them where the triggering passage lives, so the user can read both together.

### Candidate flag taxonomy

```
[memory candidate: project] <claim>
[memory candidate: client] <claim>
[memory candidate: update existing [[<filename>|<short-name>]]] <amended claim>
[journal candidate: <generalized pattern>]
```

- The scope token (`project` or `client`) is the skill's _proposal_, not a decision. The user confirms or overrides at phase 5.
- The "update existing" variant signals an amendment to an already-crystallized record. Its scope is inherited from the target.
- Journal candidates take no scope token — their destination is always the cross-client journal.

Use the heuristics in [references/scope-decisions.md](references/scope-decisions.md) to pick a scope. The short version: project is the floor (cheapest to be wrong); client requires recurrence across projects or stakeholder-level facts; journal requires generalization beyond this client.

### Phase 4 — Dispose source

Text sources (`.md`, `.txt`, `.vtt`) get deleted from `_inbox/` — the verbatim content is preserved in the note's Raw Content zone.

Binary sources (`.pdf`, `.docx`, `.pptx`) move to `<scope-root>/notes/attachments/<original-filename>`. Set `source_file: attachments/<filename>` in the note's frontmatter so the original is referenceable.

Never leave a file in `_inbox/` after grooming. The inbox is a queue, not a library.

### Phase 5 — Propose and crystallize (gated)

Stop here. Show the user every groomed note and every flagged candidate, organized by candidate type and proposed scope. Wait for explicit per-candidate sign-off.

For each candidate the user approves:

1. **Generate a nanoid**: `nanoid -s 10` (globally-installed CLI). Never random-generate or use Python's random module.
2. **Create the record file** using the matching template in [assets/records/](assets/records/):
   - Memory record (project or client scope): `<scope-root>/_memory/<type-folder>/<slug>-<nanoid>.md`. The folder set depends on the scope's memory mode (declared at the top of its `CLAUDE.md`):
     - Lightweight: `decisions/`, `context/`, `rules/`.
     - Canonical: `decisions/`, `context/`, `policy-rules/`, `exceptions/`.
     The folder must match `memory_type` in the frontmatter (`Rule` in lightweight = `PolicyRule` in canonical; see [references/memory-bank-schema.md](references/memory-bank-schema.md)).
   - Journal entry: `11 Clients/11.99 Journal/entries/YYYY-MM-DD-<slug>-<nanoid>.md`.
3. **Rewrite the candidate line** in the source note to a wiki link:
   - `[memory candidate: <scope>] <claim>` → `[[<record-filename-without-ext>|memory]] <claim>`
   - `[memory candidate: update existing [[<target>|<name>]]] <claim>` → `[[<target>|memory — updated]] <claim>`
   - `[journal candidate: <pattern>]` → `[[<relative-path-to-journal-entry>|journal]] <pattern>`
4. **For "update existing" promotions** (this is how a record grows over time rather than spawning duplicates):
   - Append the source note's `id` to the target record's `source_refs`.
   - Amend the target record's body. Mark new content inline with `(added YYYY-MM-DD, <note-id>)` so the next reader can trace which source contributed which passage.
   - Keep the original `date` field. Only bump it if the core claim has materially changed — at which point consider whether the old record should be `status: superseded` and a new record created instead.

Never auto-promote. Every record creation requires explicit user approval per candidate. Unpromoted candidates keep their `[memory candidate: ...]` or `[journal candidate: ...]` prefix — the prefix signals "considered, not crystallized," which is itself useful provenance.

### Phase 6 — Verify

Final pass before reporting done:

- Every candidate flag in every groomed note has either been resolved to a wiki link OR retains its original prefix. No half-rewrites, no orphans.
- Every record file has a valid `id`, a `memory_type` matching its folder, and at least one entry in `source_refs`.
- Every wiki-link path resolves (the target file exists at the expected location).
- The `_inbox/` is empty.

Report failures. Don't silently retry or auto-fix — those bugs hide.

---

## Scaffold mode

Stand up the directory structure and CLAUDE.md set for a new scope. Ask at most four questions:

1. **Scope** — project, client, or journal. (Suggest a default based on cwd: inside a client root, suggest client; inside `pursuits/` or `projects/`, suggest project; matches `*/11.99 Journal*`, suggest journal.)
2. **Target path** — where to scaffold. Default: cwd. Exception: journal scope defaults to `11 Clients/11.99 Journal/` relative to the nearest vault root.
3. **For project scope only** — pursuit (pre-sale, RFP work) or delivery (post-sale, working sessions)? This drives the `type:` enum baked into the generated CLAUDE.md.
4. **For client and project scope** — memory mode: **lightweight** (default, 3 types: Decision/Context/Rule) or **canonical** (4 types: Decision/PolicyRule/Exception/Context). The user can answer simply "lightweight" / "canonical" or "use the full schema". See [references/memory-bank-schema.md](references/memory-bank-schema.md) for the trade-off. Default is lightweight — Exception folds into Decision.

The chosen memory mode gets recorded in the scope's `CLAUDE.md` (top frontmatter blockquote) so later `process inbox` runs flag candidates against the right type set.

### Outputs per scope

**Client scope (lightweight default):**

```
<target>/
├── CLAUDE.md                       # from assets/claude-md/client.template.md
├── README.md                       # from assets/readme/client.template.md
├── _personal.md                    # from assets/personal.template.md
├── notes/
│   ├── CLAUDE.md                   # from assets/claude-md/notes.template.md
│   ├── README.md                   # from assets/readme/notes.template.md
│   ├── _inbox/.gitkeep
│   └── attachments/.gitkeep
├── _memory/
│   ├── CLAUDE.md                   # from assets/claude-md/_memory.template.md
│   ├── README.md                   # from assets/readme/_memory.template.md
│   ├── decisions/.gitkeep
│   ├── context/.gitkeep
│   └── rules/.gitkeep              # canonical mode: policy-rules/ + exceptions/ instead
└── patterns-journal/
    ├── CLAUDE.md                   # from assets/claude-md/patterns-journal.template.md
    └── journal.md                  # from assets/patterns-journal/journal.template.md
```

`projects/` and `pursuits/` subdirectories are not pre-created — they're added by hand or via subsequent scaffold-mode runs when projects/pursuits open.

**Project scope (lightweight default):**

```
<target>/
├── CLAUDE.md                       # from assets/claude-md/project.template.md
├── README.md                       # from assets/readme/project.template.md
├── working-state.md                # from assets/working-state.template.md
├── _personal.md                    # from assets/personal.template.md
├── notes/
│   ├── CLAUDE.md
│   ├── README.md
│   ├── _inbox/.gitkeep
│   └── attachments/.gitkeep
├── _memory/
│   ├── CLAUDE.md
│   ├── README.md
│   ├── decisions/.gitkeep
│   ├── context/.gitkeep
│   └── rules/.gitkeep              # canonical mode: policy-rules/ + exceptions/ instead
└── patterns-journal/
    ├── CLAUDE.md
    └── journal.md
```

The differences from client scope: project scope gains `working-state.md` (the narrative decisions layer) and does not create `projects/` or `pursuits/` subdirectories.

**Canonical mode replaces** the `_memory/rules/` folder with `_memory/policy-rules/` and `_memory/exceptions/`, and the generated CLAUDE.md templates substitute `Decision/PolicyRule/Exception/Context` for `Decision/Context/Rule` throughout.

**Journal scope:**

```
<target>/
├── CLAUDE.md                       # from assets/claude-md/journal.template.md
├── _inbox/.gitkeep
├── entries/.gitkeep
└── attachments/.gitkeep
```

Journal scope stays lightweight by design — single-tier substrate, no working-state, no patterns-journal (that's what the journal itself is), no `_personal.md`.

### Template substitution

The CLAUDE.md and README templates use double-curly placeholders. Substitute these at scaffold time:

| Placeholder | Replacement |
| ----------- | ----------- |
| `{{ClientName}}` / `{{ProjectName}}` / `{{ScopeName}}` | Human-readable name supplied by the user. |
| `{{pursuit\|delivery project}}` / `{{pursuit\|project}}` / `{{pursuits\|projects}}` | Pick one side of the pipe based on question 3. |
| `{{MEMORY_MODE}}` | `lightweight` or `canonical`. |
| `{{MEMORY_TYPES}}` | `Decision, Context, Rule` (lightweight) or `Decision, PolicyRule, Exception, Context` (canonical). |
| `{{MEMORY_TYPE_ENUM}}` | `Decision \| Context \| Rule` or `Decision \| PolicyRule \| Exception \| Context`. |
| `{{MEMORY_TYPE_FOLDERS}}` | `decisions/, context/, rules/` or `decisions/, policy-rules/, exceptions/, context/`. |
| `{{MEMORY_TYPE_LIST}}` | Markdown bullet list of types with one-line descriptions (pull from `references/memory-bank-schema.md`). |
| `{{MEMORY_TYPE_SUMMARY}}` | Short table or bullet list summarizing types for the human-facing `_memory/README.md`. |
| `{{RULES_FOLDER}}` | `rules` (lightweight) or `policy-rules` (canonical). |
| `{{NOTE_TYPE_ENUM}}` | Pipe-separated baseline note types: `scoping-call \| working-session \| stakeholder-call \| internal \| reading \| braindump \| transcript \| status`. The generated project CLAUDE.md will override this in its Deltas section if the user provides project-specific values. |
| `{{date}}` | Today's date in ISO format. |
| `{{engagement-list}}`, `{{stakeholder-list}}`, `{{tag-list}}`, `{{type-enum-values}}`, `{{one-sentence-project-description}}` | User-supplied during scaffold; left as HTML-commented placeholders if the user defers. |

Leave placeholders that the user defers as `<!-- Fill in: ... -->` comments rather than blanks — that way they're easy to grep for later.

### The Deltas convention

Each generated CLAUDE.md (client and project) carries a `## Deltas` section with a fixed structural shape, not free-form. The shape:

**Client-level Deltas:**
- `### Active engagements` — short list of in-flight projects and pursuits.
- `### Cross-engagement stakeholders` — roster of people who appear across multiple projects at this client. Format: `Name — Role/Title. Additional facts.`
- `### Transcription-error mapping` — common misheard names with the canonical referent.
- `### Client-wide tag namespace` — controlled vocabulary for memory record `tags:`.

**Project-level Deltas:**
- `### Note type: values` — controlled vocabulary for note frontmatter `type:`.
- `### Active stakeholders` — project-specific roster.
- `### Transcription-error mapping` — project-specific misheard names, optionally pointing to client-level Context records.
- `### Tag namespace (suggested)` — project-specific tags.
- `### Pre-existing content` — optional, only when a project subdirectory predates the substrate.

The transcription-error mapping is load-bearing for inbox-grooming accuracy on meeting transcripts. During process mode, the agent reads the Deltas section, applies known sound-alikes silently while grooming, and records what was applied in the groomed note's frontmatter as `transcript_corrections: [Saatchi→Shachi, Lince→Lancey]`.

During scaffold mode, prompt the user for known stakeholders and tag namespace seeds. Offer to populate the roster inline. If the user defers, leave the structure with `<!-- Fill in -->` comments.

### What never lands in `_memory/`

No `MEMORY.md` or `INDEX.md` summary file in any `_memory/` directory. Filenames already carry slug + id; subfolders carry type. An index would duplicate information that globbing already surfaces, drift the moment a record is renamed or superseded, and teach a retrieval path that doesn't exist in Copilot Spaces or MCP queries. If you need "what's currently in memory," generate it on demand: `Grep "^title:" _memory/`.

### Idempotency

If the target directory already contains an opted-in structure (matching markers), do **not** clobber. Report "already scaffolded at <path>" and offer to regenerate just the CLAUDE.md set. If the user agrees, write regenerated content to `CLAUDE.md.new` (and `README.md.new`, etc.) rather than overwriting — they may have customizations to merge by hand.

### Existing-directory regeneration

When invoked at a pre-existing project (e.g., `pursuits/atlas/`) that already has notes and `_memory/`:

1. Detect existing structure; do not overwrite content.
2. Add any missing subdirectories per the chosen memory mode (e.g., `_memory/rules/` for lightweight, `_memory/policy-rules/` and `_memory/exceptions/` for canonical) with `.gitkeep`.
3. Add any missing top-level files (`README.md`, `_personal.md`, `working-state.md` for projects, `patterns-journal/{CLAUDE.md,journal.md}`) without clobbering existing content.
4. Regenerate `CLAUDE.md` from the project template (write to `CLAUDE.md.new` if the existing file has been edited beyond template substitution).
5. Ask the user for **deltas** — active stakeholders, custom tag namespace, custom `type:` enum values, transcription-error mappings. Append them under the regenerated `## Deltas` section.
6. If the pre-existing `_memory/` uses a different mode than the user requests (e.g., existing canonical 4-type vs. requested lightweight), report the mismatch and ask before changing anything. Do not auto-migrate.

---

## Frontmatter quick reference

Full shapes live in the templates. Quick reference for scanning:

**Groomed note**: `id`, `date`, `type`, `attendees[]`, `tags[]`, `topics[]`, optional `source_file`, optional `related[]`.

**Memory record** (memory-bank-aligned): `id`, `memory_type`, `title`, `status` (proposed|accepted|superseded|deprecated|rejected), `date`, optional `effective_from`/`effective_to`, `source_refs[]`, `applies_to[]`, `owners[]`, `tags[]`, `related[]`, optional `supersedes`/`superseded_by`. Plus type-specific body fields per [references/memory-bank-schema.md](references/memory-bank-schema.md).

`memory_type` values depend on the scope's chosen memory mode:
- **Lightweight** (default): `Decision | Context | Rule`. Exception is folded into Decision.
- **Canonical**: `Decision | PolicyRule | Exception | Context`. Matches `kendrick-at-slalom/memory-bank` exactly.

The scope's `CLAUDE.md` declares the mode in its top frontmatter blockquote. Read it before flagging candidates so the suggested type uses the right vocabulary.

**Journal entry**: `id`, `memory_type: Journal`, `title`, `status` (current|superseded|archived), `date`, `themes[]`, `applies_to[]`, qualified `source_refs[]` (each entry has `scope`, `path`, `note_id`), `related[]`. Body is free prose.

---

## Filename and ID conventions

- All IDs come from the globally-installed `nanoid -s 10` CLI. Never generate manually or via Python's random module.
- Notes: `YYYY-MM-DD-<slug>-<nanoid>.md`.
- Memory records: `<slug>-<nanoid>.md` inside the type folder.
- Journal entries: `YYYY-MM-DD-<slug>-<nanoid>.md` inside `entries/`.
- Slugs: lowercase, kebab-case, 3-6 words, descriptive of the primary subject.

---

## Operating rules

- **Stage, never auto-commit.** Outputs are proposals. Never run `git commit` unless the user asks.
- **Preserve raw content as the source of truth.** Memory records cite notes; they don't replace them.
- **One groomed note per input.** No four-file fragmentation. Sections, not separate files.
- **Never auto-promote across scopes.** Scope is decided at flagging time, confirmed at sign-off, sticky after crystallization. If a record needs to move, the user moves it by hand. (This trades convenience for audit safety — at high enough volume, v2 may add a guarded `promote` mode.)
- **Cross-scope references are fine.** A project note can wiki-link to a client-scope record. A client record can list project note ids in its `source_refs`. The record's _home_ (which `_memory/` it lives in) defines its scope, not its references.

---

## When NOT to use this skill

- The user has a single ad-hoc note they want to write directly. The skill is for queue-driven processing, not freeform composition.
- The cwd is not inside an opted-in directory and the user hasn't asked to scaffold one. Do not silently create memory infrastructure where none was intended.
- The user is asking about memory records for an existing skill or code repo. This skill targets consulting notes in an Obsidian vault. For code-repo memory, see [`kendrick-at-slalom/memory-bank`](https://github.com/kendrick-at-slalom/memory-bank).

---

## Further reading

- [references/extraction-heuristics.md](references/extraction-heuristics.md) — quote selection, tension surfacing, assumption mining.
- [references/scope-decisions.md](references/scope-decisions.md) — full heuristics for proposing project vs client vs journal scope.
- [references/memory-bank-schema.md](references/memory-bank-schema.md) — vendored summary of the substrate schema. Inspired by, not bound to.
- [references/retrieval-funnel.md](references/retrieval-funnel.md) — token-efficient four-stage retrieval at scale.
