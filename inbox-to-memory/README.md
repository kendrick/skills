# inbox-to-memory

A Claude Code skill that drains a folder of meeting artifacts into groomed notes and durable memory records.

If your calendar generates more paper than insight—transcripts, slide decks, PDFs, half-finished scratch notes—this gives the pile a queue. Drop everything into `_inbox/`, say "process the inbox," and each input becomes one groomed markdown note: frontmatter on top, extracted quotes and tensions and action items in the middle, the verbatim original at the bottom. Along the way the skill flags candidates for longer-term memory, and you approve each one before any record is created.

Records land in one of three tiers: a single project, a client (any organization or relationship you work with repeatedly), or a cross-cutting journal for patterns that outlive both.

## Install

The preferred route is the `skills` CLI:

```bash
npx skills add https://github.com/kendrick/skills
```

Prefer to manage it by hand? Clone the collection and copy this directory in:

```bash
git clone git@github.com:kendrick/skills.git
cp -R skills/inbox-to-memory ~/.claude/skills/inbox-to-memory
```

## Use

**Process mode** (the default). From anywhere inside a set-up directory:

```
> process the inbox
```

The skill finds the nearest opted-in directory, grooms every file in `_inbox/` into a note under `notes/`, flags memory and journal candidates inline, and stops for your sign-off before crystallizing anything. When it finishes, the inbox is empty: text sources are deleted (their content lives on in the note's Raw Content zone), binaries move to `notes/attachments/`.

**Scaffold mode.** In a fresh directory:

```
> scaffold a new project here
```

A short interview (four questions at most) stands up the substrate for a project, a client, or the journal. Existing structure is never clobbered.

Both modes, their phases, and the record schema are specified in [SKILL.md](SKILL.md).

## What's Here

```
inbox-to-memory/
├── SKILL.md          # the skill — both modes inline
├── assets/           # templates emitted at scaffold and crystallize time
│   ├── claude-md/    # CLAUDE.md per scope
│   ├── readme/       # README.md per scope
│   ├── records/      # Decision, Rule, PolicyRule, Exception, Context, Journal
│   └── ...           # note, personal, working-state, journal templates
├── scripts/
│   ├── lint-scope.sh     # what the verify phase runs
│   ├── migrate-scope.sh  # brings a v1 scope onto the v2 contract
│   └── collapse-vtt.sh   # merges VTT cues into speaker turns
└── references/       # progressive-disclosure reading
    ├── extraction-heuristics.md
    ├── scope-decisions.md
    ├── memory-bank-schema.md
    ├── machine-contracts.md
    ├── migration.md
    └── retrieval-funnel.md
```

## Gotchas

- The skill only operates on opted-in directories (ones containing `_inbox/` plus `_memory/` or `entries/`). Anywhere else, it refuses and offers to scaffold instead.
- IDs come from the `nanoid` CLI (`nanoid -s 10`), which must be installed globally.
- The verify step runs `scripts/lint-scope.sh` over the scope, and it parses YAML with `yq`. Install that alongside `nanoid` (`brew install yq`). Neither ships with macOS, and a missing one fails for a reason that has nothing to do with your notes.
- Notes written before the v2 contract keep working untouched; nothing forces a migration. When you do want one, `scripts/migrate-scope.sh` rewrites frontmatter only and never touches a body. It dry-runs by default and wants a clean working tree before it writes. See [references/migration.md](references/migration.md).
- Draining the inbox is destructive by design: after grooming, text sources are gone from `_inbox/` and binaries have moved. The content survives in the notes, but if you want pristine originals kept elsewhere, copy before you drop.
- Nothing is ever promoted to memory automatically. Every record requires your explicit per-candidate approval, and unpromoted candidates keep their `[memory candidate: ...]` flag as a record of what was considered. One date is the exception. When an input restates a claim an accepted record already makes, the run stamps that input's date onto the record's `last_confirmed` and names it in the closing report, so `git status` can show modified memory files after a run where you approved nothing. No record is created and nothing a record claims is edited — only the date saying when the claim was last seen to hold.

## License

MIT, per the [collection license](../LICENSE). This skill is part of the [skills collection](..).
