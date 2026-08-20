# technical-writing

A layered prose standard for developer-facing writing: commit messages, code comments, PR descriptions, API reference, and README-style docs.

## Why This Exists

Most prose skills are either a giant rulebook nobody reads in full or a single voice applied to everything, docblock and README alike. Neither survives contact with real repos, where a docblock needs to stay dry and an inline comment needs room to explain a rejected alternative.

This skill routes each artifact type to a profile that says which public standards apply and how, then runs every draft through a mandatory audit before it ships. It's adapted from Lauren Tan's `pstack/technical-writing` skill in `cursor/plugins`—an 11.5 KB monolith that this version splits into a thin router plus per-artifact profiles, so a caller loads only the profile it needs.

## How It Works

Four house rules sit above four public standards—Diátaxis, Google developer style, ASD-STE100 principles, and Kohl's Global English—and every artifact dispatches to a profile that names which of the four apply to it.

- **Dispatch.** The artifact type picks a profile: commit messages and code comments ship today; PR descriptions, API reference, and README-style docs fall back to the global rules and layers until their profiles are written.
- **Draft.** Write under the dispatched profile, or under the fallback globals when no profile exists yet.
- **Audit.** Every draft runs through a self-check, then a prose audit, then whatever house rules your setup defines. The audit is mandatory; the tool that performs it is yours to pick.

## Install

```bash
npx skills add kendrick/skills --skill technical-writing
```

Nothing else is required. Two optional pieces make the audit step stronger, and the skill was written against both:

- a prose-audit skill. Step 2 invokes whichever one your setup provides, by name of role rather than of vendor, so any of them works. This was built against [`humanizer`](https://github.com/blader/humanizer).
- house prose rules. Where your setup defines them, Step 2 reads them fresh and layers them over the audit. On the author's machines that's `~/.claude/PROSE.md`, wired up by `~/.claude/CLAUDE.md` rather than by this skill.

With neither installed, the router, the layers, the profiles, and the self-check all still work; you just do the last pass by hand.

Or install by hand:

```bash
git clone git@github.com:kendrick/skills.git
cp -R skills/technical-writing ~/.claude/skills/technical-writing
```

## Use

```
> write a commit message for this diff
> audit the comments in src/parser.ts against the house style
> draft a PR description for this branch
```

## What's Here

```
technical-writing/
├── SKILL.md                    # the skill — four layers, dispatch table, audit loop
├── README.md                   # this file
└── references/
    ├── commit-messages.md      # register, content, subject-line conventions
    └── comments.md             # when to comment, docblock/inline mode mapping, auditing
```

## Gotchas

- Anything addressed to a person—email, DM, note—is out of scope here and belongs to whatever voice process your setup defines, which replaces the prose audit rather than layering on top of it. On the author's machines that's `~/.claude/VOICE.md`.
- The three unwritten profiles (PR descriptions, API reference, README-style docs) fall back to the global rules and layers by design. That fallback is a real standard, not a placeholder to improvise past.
- The two shipped profiles duplicate the commit-message and code-comment sections of the user's `~/.claude/CLAUDE.md` on purpose, copied verbatim rather than paraphrased so the two can't drift apart silently. Thinning CLAUDE.md down to a reference into this skill is the planned resolution, not done yet.

## License

MIT, per the [collection license](../LICENSE). This skill is part of the [skills collection](..).

The upstream `pstack/technical-writing` skill this one adapts is MIT, Copyright (c) 2026 Lauren Tan. Full provenance and deviations: [`_maintenance/technical-writing/PROVENANCE.md`](../_maintenance/technical-writing/PROVENANCE.md).
