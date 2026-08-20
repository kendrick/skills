# Technical-Writing Provenance

| Fetch date | Source | Commit / revision | URL | Size |
| --- | --- | --- | --- | --- |
| 2026-08-20 | cursor/plugins `pstack/skills/technical-writing/SKILL.md` | `b047069f4f3a73e87dd1f11f7913386d25876b91` | <https://raw.githubusercontent.com/cursor/plugins/main/pstack/skills/technical-writing/SKILL.md> | 11,522 bytes |
| 2026-08-20 | `~/.claude/CLAUDE.md`, sections "Commit messages" and "Code comments" | migrated verbatim into `technical-writing/references/commit-messages.md` and `references/comments.md` | local file, not a URL | n/a |

The governing license for the upstream snapshot is `pstack/LICENSE`, not any license at the `cursor/plugins` repository root — the root carries no license file at all. That file is MIT, Copyright (c) 2026 Lauren Tan. `pstack` is Tan's personal plugin, vendored into `cursor/plugins`; credit for the skill is to her, not to Cursor the company. The verbatim copy in `upstream/` sits next to this notice, which satisfies MIT's notice-retention condition.

The CLAUDE.md row above is a second, independent source and carries no license question — it's the user's own private configuration, migrated by hand into the two profile files. The drift guard between the two copies is `tests/technical-writing-smoke.sh`'s pinned sentences: it fails if the profile text stops matching CLAUDE.md's wording. The duplication itself is deliberate, not an oversight; CLAUDE.md thinning down to a reference into the skill is the planned resolution, not done here.

## Deviations From Upstream

- **Router + per-artifact profiles, not an 11.5 KB monolith.** Upstream ships one file; this skill splits static knowledge and dispatch into `SKILL.md` (held under 7 KB, roughly 60% of upstream) and moves artifact-specific rules into `references/`, so a caller only loads the profile it needs.
- **Model-invocable.** Upstream sets `disable-model-invocation: true`; this skill omits it, so it can fire without an explicit slash command.
- **humanizer + `~/.claude/PROSE.md` replace upstream's `unslop` dependency, and the binding is soft.** PROSE.md's `## Plain Speech` section already carries unslop's rules 26–31 plus the colon rule, so that content arrives through the audit step instead of being vendored in separately. Upstream states its `unslop` dependency as a hard requirement; this skill can't, because it ships publicly and neither humanizer nor the author's private `~/.claude` files are things an installer will have. Step 2 therefore mandates that an audit happens and names the auditor by role rather than by vendor: `SKILL.md` and both profiles mention no prose-audit tool and no personal path anywhere. On the author's machines the pass is guaranteed independently by `~/.claude/CLAUDE.md`, which mandates humanizer and PROSE.md for all merge-bound prose — observed directly in the eval, where the without-skill arm ran both without ever reading this skill. That is what makes the soft binding free rather than a compromise: the lens still lands where it's configured, and the skill stays installable where it isn't. `tests/technical-writing-smoke.sh` refutes both `unslop` and `humanizer` in SKILL.md and fails if a personal path reappears in the description.
- **Review checklist carried but cut to 5 items** — only the checks valid for every artifact type survive. The one-mode-per-doc (Diátaxis) item was dropped from the router because the dispatch table excludes Diátaxis from commits, PR descriptions, and changesets; mode compliance is a profile concern instead.
- **Upstream's worked example dropped, replaced per-profile.** Each shipping reference file carries its own `## Example` section, harvested from this change's own eval runs rather than copied from upstream. This also removes the licensing question that reusing a crafted example near-verbatim would have raised.
- **Upstream's "Vary the rhythm" section dropped.** PROSE.md's Plain Speech covers most of the same ground. The one strand it doesn't cover — deliberate sentence-length mixing — is recorded here as a known gap and a candidate for a future PROSE.md addition, not for this skill.
- **Cursor-repo specifics dropped**: the tabs-for-snippets convention and the instruction to add offenders to unslop's abstract-metaphor rule don't apply outside that repo.
- **A code-comments profile added.** Upstream never wrote one; `references/comments.md` is new.
- **STE dictionary and numbered-rule conformance are explicitly out of scope**, principles only — same scope upstream keeps.

Record later differences from upstream here before updating snapshots.
