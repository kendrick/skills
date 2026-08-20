# file-issue

A skill that writes one GitHub issue worth reading, then files it with `gh`.

## Why This Exists

Plenty of tooling will check that you filled in the template. Almost none of it checks whether what you filled in is any good. You can pass every structural gate and still ship an issue whose reproduction step reads "log in and go to settings, it breaks"—perfectly shaped, and it still costs a developer a round trip to find out what you meant.

The research points at one place in particular. Developers rank steps-to-reproduce first by a wide margin, and errors in those steps are the single most severe problem they report. Reporters know this and supply them anyway less than half the time, because reproduction steps are also the hardest thing to write. That gap is the one worth closing.

So the gates here are content gates. Can a stranger run the reproduction on a clean checkout? Can the acceptance criteria fail? Does the scope have an edge? If a coding agent picks this up, does it know how to verify its own work? Each gate traces to a measured finding, and the ones that are convention rather than evidence say so out loud. The full survey is in [file-issue-research.md](../_docs/file-issue-research.md); the mapping from each gate to its claim is in [evidence-map.md](references/evidence-map.md).

## How It Works

It reads the repo before it asks you anything. If `.github/ISSUE_TEMPLATE/` has a form, that form wins: the skill fills its declared fields and invents nothing alongside them. It also samples recent issues for label taxonomy and title conventions, and pulls the build and test commands out of your manifest, which is how the agent-readiness check gets answered without spending a question on it.

Then it picks an interrogation depth, arithmetically, and tells you which one:

- **Depth 0** — typos, dependency bumps. No questions at all.
- **Depth 1** — the default. At most five questions, each one against a specific empty slot in the draft.
- **Depth 2** — breaking changes, cross-cutting work, anything headed for a coding agent. Full interrogation, plus a look at the actual code to get real file paths.

One word moves it either direction, or use `--deep` and `--fast`. Every question names the gap it's filling, which means "why are you asking me this" always has an answer.

If the answers keep spawning new workstreams, meaning seven-plus independent acceptance criteria or four-plus components, it stops and says this is a spec rather than an issue, then hands you off instead of producing one enormous ticket.

Where the technical-writing skill is installed, the finished draft takes one prose pass through it before rendering; where it isn't, the draft ships as-is.

Nothing gets posted without showing you the rendered issue first.

## Install

```bash
npx skills add kendrick/skills --skill file-issue
```

Or by hand:

```bash
git clone git@github.com:kendrick/skills.git
cp -R skills/file-issue ~/.claude/skills/file-issue
```

Needs the [GitHub CLI](https://cli.github.com) authenticated. Without it the skill still drafts, but says clearly that it can't post.

## Use

```
> file an issue: the export button does nothing on Safari
> open a bug for the session timeout race, I'm assigning it to Copilot
> --dry-run write up a feature request for CSV export
> --fast file a task to bump the eslint config
```

## What's Here

```
file-issue/
├── SKILL.md          # the skill — detect, depth, elicit, draft, check, polish, guard
├── assets/           # used only when the repo has no template of its own
│   ├── bug.template.md
│   ├── feature.template.md
│   ├── task.template.md
│   └── spike.template.md
└── references/
    ├── issue-forms.md    # issue-form YAML schema and gh mechanics
    └── evidence-map.md   # every gate traced to its claim and evidence tier
```

## Gotchas

- It creates, and that's all. No editing, closing, triaging, or relabeling existing issues, since those are different jobs needing guards this doesn't have.
- One issue per run. Splitting a plan into linked tickets is [to-tickets](https://github.com/mattpocock/skills)' job, and the escape hatch hands off to it rather than half-building decomposition here.
- Duplicates get surfaced, never blocked. This is deliberate and evidence-backed: duplicates rank low on developer annoyance, routinely carry information the original lacks, and refusing them teaches people to stop reporting. You get the candidates and the call.
- The repo's template always beats the built-in one. If your form has four fields, your issue has four fields, even where the skill's own rubric would want a fifth.
- GitHub only. Detection, creation, and duplicate search all go through `gh`.

## Maintainers

The decision ledger and the eval suite live in [`_maintenance/file-issue/`](../_maintenance/file-issue/). Every contested choice has a row in [RATIONALE.md](../_maintenance/file-issue/RATIONALE.md), including the two features the research killed. Smoke test: `bash tests/file-issue-smoke.sh` from the repo root.

## License

MIT, per the [collection license](../LICENSE). This skill is part of the [skills collection](..).
