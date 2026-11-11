# Scaffold Layout

The directory tree scaffold mode writes for each scope, and what canonical memory mode changes in it.

**Client scope (lightweight default):**

```
<target>/
├── CLAUDE.md                       # from assets/claude-md/client.template.md
├── README.md                       # from assets/readme/client.template.md
├── _personal.md                    # from assets/personal.template.md
├── memory-bank.yaml                # from assets/memory-bank.template.yaml
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
├── memory-bank.yaml
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

The differences from client scope: project scope gains `working-state.md` (the narrative decisions layer, whose last section holds `## YYYY-MM-DD: Title` entries that `ltm promote` can lift to an org Bank; see [scope-decisions.md](scope-decisions.md#decisions-in-working-statemd-are-dated-entries)) and does not create `projects/` or `pursuits/` subdirectories.

**Canonical mode replaces** the `_memory/rules/` folder with `_memory/policy-rules/` and `_memory/exceptions/`, the generated CLAUDE.md templates substitute `Decision/PolicyRule/Exception/Context` for `Decision/Context/PolicyRule` throughout, and `memory-bank.yaml` loses its `folders` line.

**Journal scope:**

```
<target>/
├── CLAUDE.md                       # from assets/claude-md/journal.template.md
├── _inbox/.gitkeep
├── entries/.gitkeep
└── attachments/.gitkeep
```

Journal scope stays lightweight by design — single-tier substrate, no working-state, no patterns-journal (that's what the journal itself is), no `_personal.md`.
