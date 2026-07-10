# Agent Companions — AGENTS.md, CLAUDE.md, llms.txt

Loaded at Step 6 only when the user accepts a companion. The division of labor: the README stays human and warm; operational minutiae that would clutter it — build steps, test commands, conventions — moves here.

## AGENTS.md

An open-standard "README for agents": plain Markdown, no required fields, nearest-file-wins when nested (a subdirectory's AGENTS.md overrides the root's for work in that subtree).

**Content rule — only the non-inferable.** ETH Zurich's evaluation of repository context files (arXiv:2602.11988) found they tend to *reduce* agent task success while raising cost, because agents dutifully follow redundant instructions; the content that helps is what the agent cannot discover by reading the repo. So include:

- Custom or non-standard commands — the exact build, test, lint invocations, fenced. If it's `npm test`, the agent will find it; if it's `make check ENV=ci`, write it down.
- Hard constraints and negative rules the repo can't express: "never commit `.env`", "IMPORTANT: migrations run only via `bin/migrate`".
- Specific tooling choices where alternatives exist (the formatter, the package manager in a repo where both lockfiles appear).
- A short project-structure map when entry points aren't obvious.
- Conventions for commits/PRs that CI enforces.

Leave out architecture overviews and anything a manifest, script, or directory listing already states — restating discoverable facts costs tokens and measurably lowers success. When a section merely narrates what the repo shows, cut it.

**Form:**

- Under ~150–200 lines. Instruction-following degrades as instruction count climbs, so every line competes with the others; past that size, split into nested per-directory AGENTS.md files.
- Emphasis markers (IMPORTANT, YOU MUST) on the few rules that are load-bearing.
- Point with `path/file.ts:123` references; paste no code.

## CLAUDE.md

Claude Code's auto-loaded memory file, same content rules as AGENTS.md. When the repo wants both, keep one source of truth: write AGENTS.md and symlink it —

```sh
ln -s AGENTS.md CLAUDE.md
```

If a CLAUDE.md already exists (Step 2 harvest knows), extend it in place rather than introducing a competing AGENTS.md.

## llms.txt

For docs-heavy projects: a root `/llms.txt` file that helps LLMs navigate the published docs at inference time. Format, in full:

1. An H1 with the project name — the only required element.
2. A blockquote summary, one short paragraph.
3. H2-delimited sections of curated link lists (`- [Title](url): one-line note`).
4. An optional final `## Optional` section for links safe to skip under a tight context budget.

Offer it only when the harvest found a docs site or a docs-dominant repo; for a code repo, AGENTS.md is the useful companion.
