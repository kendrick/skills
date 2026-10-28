# memory-index—rationale

Evidence tiers: **[E]** measured or observed in a real run, **[P]** practitioner reasoning from prior art, **[C]** convention inherited from this repo or its neighbors.

## Where This Came From

Four sources:

- **Issue #192**, which set the two modes, the `<scope>-<type>` naming, the rule that folders and not frontmatter decide collections, and both falsifiers. Its follow-up comment, written after #193 landed, added the v1-body and journal-candidate limits below.
- qmd's README (https://github.com/tobi/qmd)—`qmd collection add <path> --name <n> [--mask "<glob>"]` with a default mask of `**/*.md`, `qmd context add qmd://<n> "<text>"`, `qmd update`, `qmd embed`, and the MCP server entry `{"command": "qmd", "args": ["mcp"]}`. It also says a collection's `ignore` list is YAML-only, and no CLI command sets it.
- **`inbox-to-memory`'s scaffold trees**—records at `<scope-root>/_memory/<type>/<slug>-<nanoid>.md` in `decisions`, `context`, and `rules` (lightweight) or `policy-rules` and `exceptions` (canonical), groomed notes directly in `notes/`, and the `## ... in One Paragraph` and `## Record Types` sections the context strings read.
- #193's sidecar (merged as #255)—raw text moved to `notes/raw/<id>.md`, so an index could exclude it.

## Decision Ledger

| # | Decision | Why | Tier |
|---|---|---|---|
| 1 | Model-invocable (no `disable-model-invocation`) | A misfire is cheap: Step 1 runs `--dry-run` first and registers nothing without a yes, and `qmd collection remove` undoes a registration. Making it user-invoked would also mean adding it to `AGENTS.md`'s user-invoked list, which costs more than this description does. | [P] |
| 2 | One stdlib script, `scripts/memory-index.py`, with two subcommands, `register` and `refresh` | Registering is a fixed sequence of commands built from the directory tree, which is a job for a script rather than a fresh act of judgment every run, so every scope comes out registered the same way. Standard library only keeps the skill copy-in portable, per `AGENTS.md`. | [C] |
| 3 | Collections keyed on folders, and the script never opens a record | Issue #192's rule: a file belongs to `<scope>-<type>` exactly when it sits under `_memory/<type>/`. The folder is what the scope owner moves, and qmd's structured filter reads only a nested `qmd.metadata` block, which this repo's single-line frontmatter lint forbids. A frontmatter value that disagrees with its folder is the lint's to report. The smoke suite pins this with both falsifiers. | [P] |
| 4 | The notes collection excludes `notes/raw/` with `--mask "*.md"`, not with qmd's `ignore` list | qmd's README says `ignore` is YAML-only and no CLI command sets it, so using it would mean writing qmd's `index.yml`. Probed against qmd 2.8.3 (`facd35e`) on 2026-10-27 in an index isolated by `QMD_CONFIG_DIR`, `XDG_CONFIG_HOME`, and `XDG_CACHE_HOME`: `--mask "*.md"` on `notes/` indexed `notes/2026-10-27-a.md` and not `notes/raw/x.md`. The cost is that `notes/CLAUDE.md` and `notes/README.md` get indexed too. | [E] |
| 5 | Context strings come from the scope's `CLAUDE.md` "in One Paragraph" section and the type's bullet under the `_memory/CLAUDE.md` heading that starts `Record Types`, with `Memory scope <scope>.` as the fallback | Those files are where `inbox-to-memory`'s scaffold already writes what a scope is and what each record type holds, so the context restates the owner's own words and goes stale only when they do. A paragraph still holding its `<!-- Fill in -->` comment would put template text in every context, so comments are stripped and an empty result falls back. The script finds the type's bullet by its label (the first bold span, else the first backticked span, else the leading run of capitalized words), never by the whole line, because a description can name another type: "a choice made under standing rules" put the Decision line on the rules collection (PR #266 review). A bullet whose label is neither bold nor backticked and doesn't open with a capitalized word can still miss. | [P] |
| 6 | `register` runs `--dry-run` first and runs for real only on the user's yes | It writes into the user's qmd index, which other scopes share. Showing the exact commands first is what makes model-invocation (row 1) safe, and a dry run costs nothing. | [P] |
| 7 | Exit codes 0 pass, 1 a qmd command failed, 2 usage error, 3 not a memory scope or qmd not on PATH | Follows the validator convention `check-territories.py` set and `AGENTS.md` names for scripts that gate a run, except that a usage error exits 2, because argparse exits before the script's own code runs. A failed `collection add` stops the run at that command, with `FAILED: <command>` and qmd's first stderr line, so a half-registered scope is never reported as done. | [C] |

## Deliberately Not Built

| Cut | Why |
|---|---|
| Writing qmd's `index.yml` to set a collection's `ignore` list | qmd owns that file, and no CLI command writes the key. The `*.md` mask on `notes/` does the exclusion through qmd's own CLI (row 4). Pinned by a `refute_text` on `index.yml` in `scripts/memory-index.py`. |
| Running qmd as a daemon | A non-goal in #192. `refresh` is a one-shot the scope owner calls from a hook, and keeping a process alive is the user's harness's job. Pinned by a `refute_text` on `--daemon` in `SKILL.md`. |
| A `memory_type` frontmatter filter | Folders decide collections (row 3), so passing a collection name does the filter's job. qmd's structured filter also can't read the single-line frontmatter this repo's lint enforces. Pinned by a `refute_text` on `memory_type` in `scripts/memory-index.py`. |

## Known Limitations

- A second `register` on the same scope fails. qmd refuses a duplicate collection name, so the run stops at the first `collection add` with exit 1. Remove the scope's collections with `qmd collection remove` before re-registering.
- A v1-body note keeps its transcript inline. `split-raw.sh` never splits a v1 note (no `schema` key, or `body_schema: 1`), so the mask can't keep that transcript out of `<scope>-notes`. `register` doesn't detect v1 bodies (#192's comment).
- A `[journal candidate:]` marker that sits only in the raw source text is invisible to the index, because that text is now in `notes/raw/`. Candidates flagged inside the extracted sections stay in the top-level note, so the index sees them (`inbox-to-memory/SKILL.md`, "Inside the extracted sections, flag candidates **inline**"). A lookup for the raw-only markers greps `notes/` recursively instead (#192's comment).
- `notes/CLAUDE.md` and `notes/README.md` get indexed. They sit directly in `notes/`, so the `*.md` mask matches them (row 4).
