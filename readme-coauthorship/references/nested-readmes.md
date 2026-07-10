# Nested READMEs

A subdirectory README is local and navigational: the root README is the lobby of the building; this one is the welcome mat for its floor. It explains this directory, points up, and stops.

## Section Set

Adapt the funnel order from SKILL.md Step 4 to this scoped shape — most nested READMEs need only:

1. Title — the package/module name
2. One-line purpose: what this directory is and why it exists
3. Owner or maintainer, when the repo tracks ownership (CODEOWNERS, manifest author)
4. How to run/test **just this package** — the scoped commands, not the repo-wide ones
5. Local dependencies and how this piece relates to its siblings
6. Gotchas — the surprises a newcomer to this directory hits
7. Link up to the root README for global setup, install, and contribution rules

## Scoped, Not Duplicated

- Cover only what is specific to this directory. Global setup, toolchain install, and org-wide conventions live at the root — link to them.
- Repo-wide claims (license, contribution policy) appear here only as links, so there is exactly one place to update them.
- Proportionality still rules: a small internal module may need five lines, not five sections.

## Consistency Across Siblings

When sibling directories already carry READMEs, mirror their section names and ordering — consistent structure is how both humans and agents navigate a monorepo. If this is the first nested README, its structure becomes the template siblings will copy; keep it minimal.

## Obligations Upward

- The root README (or its project-structure map) should link down to this file. Adding that link is Step 6's companion offer — a separate consent, since it edits a file outside the target.
- If the repo already uses nested AGENTS.md files (nearest-file-wins), note in Step 6 that this directory could mirror one; follow [agent-companions.md](agent-companions.md) if accepted.
