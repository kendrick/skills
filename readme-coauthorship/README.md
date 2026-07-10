# readme-coauthorship

A Claude Code skill that co-authors READMEs, brand-new or long-neglected, root-level or buried deep in a monorepo.

## Why This Exists

Most READMEs bury the answers a reader actually shows up with: what is this, and how do I run it? Instead there's a badge wall, a philosophy section, and install steps that assume the maintainer's machine. Generic doc tooling doesn't help much, because it treats a README like any other document. READMEs have their own settled craft—readers decide in seconds, structure works as a funnel from general to specific, section sets differ by project type, and a subdirectory README is a different animal from a root one.

This skill encodes that craft. It scans the repo before asking anything and refuses to fabricate what it can't verify. What it writes adapts to the target: library, CLI, app, docs repo, config directory, or monorepo. The research behind it is in [research.md](research.md).

## How It Works

Every run resolves four choices up front, then follows the same pipeline: harvest repo facts, fill a brief, generate, validate.

- Mode — guided asks up to eight targeted questions; autopilot infers everything from the repo and asks nothing past setup.
- Scope — a root README gets the full funnel; a nested one stays scoped to its directory and links up.
- Posture — create a missing README, enhance an existing one (its voice and live content survive), or rewrite from scratch.
- Output — write in place, or to a draft like `README.new.md` so you can diff before committing.

At the end it can offer a companion AGENTS.md or llms.txt, so build-and-test minutiae for agents has a home that isn't the README.

## Install

The preferred route is the `skills` CLI:

```bash
npx skills add https://github.com/kendrick/skills
```

Prefer to manage it by hand? Clone the collection and copy this directory in:

```bash
git clone git@github.com:kendrick/skills.git
cp -R skills/readme-coauthorship ~/.claude/skills/readme-coauthorship
```

## Use

```
> write a readme for this repo
> autopilot, improve the readme in packages/parser
> rewrite my readme from scratch, walk me through it
```

The first thing any run does is settle the four axes above; anything your phrasing already decided, it won't ask about.

## What's Here

```
readme-coauthorship/
├── SKILL.md          # the skill — six steps, all four axes
└── references/       # loaded per-branch at generate time
    ├── elicitation.md
    ├── readme-craft.md
    ├── section-templates.md
    ├── nested-readmes.md
    └── agent-companions.md
```

## Gotchas

- No version control means no in-place writes. Without git, output defaults to a draft file, since replacing a README there would be unrecoverable.
- Missing sections are usually deliberate. Every claim must trace to a harvested fact or your answer, so a repo with no CI gets no CI badge and a project with no visuals gets no screenshot section.
- The root README is its own decision. A nested run offers to add a link from the root down to the new README; it never edits the root without that consent.

## License

MIT, per the [collection license](../LICENSE). This skill is part of the [skills collection](..).
