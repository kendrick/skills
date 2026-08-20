```
███████╗██╗  ██╗██╗██╗     ██╗     ███████╗
██╔════╝██║ ██╔╝██║██║     ██║     ██╔════╝
███████╗█████╔╝ ██║██║     ██║     ███████╗
╚════██║██╔═██╗ ██║██║     ██║     ╚════██║
███████║██║  ██╗██║███████╗███████╗███████║
╚══════╝╚═╝  ╚═╝╚═╝╚══════╝╚══════╝╚══════╝
```

# skills

Agent skills you install on individually or all at once.

Seven skills live here right now: one for driving Databricks APIs, one for turning meeting artifacts into durable notes, one for writing READMEs, one for writing GitHub issues, one for carrying unfinished coding-agent work into a fresh session, one for reviewing a diff adversarially, and one for the prose developers write around their code. Each sits in its own directory with a full guide, loads into your LLM harness the same way, and works independently of the rest.

## Install

Browse and install the whole collection with the `skills` CLI:

```bash
npx skills add kendrick/skills
```

## The Skills

### [databricks-api](databricks-api/)

A router plus eight domain skills covering the Databricks REST APIs and the Python SDK: Unity Catalog, Jobs and Workflows, SQL warehouses and statement execution, Model Serving and AI Gateway, Delta Sharing, Genie, Marketplace, and file management. The router points you to a domain, the domain points you to the exact bucket file for your task. It's built around one rule: every endpoint, field, and enum value it hands you comes from a doc it actually read, not from memory. Reach for it on any Databricks API or SDK task, or when you're not sure which API owns the job.

```bash
npx skills add kendrick/skills --skill databricks-api
```

### [file-issue](file-issue/README.md)

Writes one GitHub issue and files it with `gh`. Most issue tooling checks that you filled in the template; this checks whether what you filled in is any good—can a stranger run your reproduction steps, can your acceptance criteria fail, does the scope have an edge, does a coding agent picking it up know how to verify its own work. It reads the repo first, so an existing issue form always wins over anything it would write on its own, and the build commands it needs come off disk instead of out of you. How hard it interrogates scales with the ask: a typo gets no questions, a breaking change gets the full treatment, and every question names the gap it's filling. Each gate traces to a measured finding, and the ones that are convention say so. Reach for it when a bug report or feature request needs to survive contact with someone who wasn't in the conversation—including a coding agent.

```bash
npx skills add kendrick/skills --skill file-issue
```

### [inbox-to-memory](inbox-to-memory/)

Drop your meeting exhaust—transcripts, slide decks, PDFs, half-finished scratch notes—into an `_inbox/` folder, say "process the inbox," and each input comes back as one groomed markdown note: frontmatter up top, extracted quotes and tensions and action items in the middle, the verbatim original at the bottom. Along the way it flags candidates for longer-term memory across three tiers (a project, a client, or a cross-cutting journal), and you approve each record before it's written. It also scaffolds the directory structure for a new project, client, or journal. Reach for it when your calendar generates more paper than insight.

```bash
npx skills add kendrick/skills --skill inbox-to-memory
```

### [readme-coauthorship](readme-coauthorship/)

Co-authors READMEs—this one included—whether brand-new, long-neglected, at the repo root, or buried in a monorepo. It scans the repo before asking anything, refuses to fabricate what it can't verify, and structures what it writes as a funnel from general to specific. Runs guided (a short wizard of targeted questions) or autopilot (infers everything from repo metadata). Reach for it to write a README from scratch or refresh one that's drifted.

```bash
npx skills add kendrick/skills --skill readme-coauthorship
```

### [adversarial-review](adversarial-review/README.md)

Reviews a diff by treating every finding as a hypothesis rather than a result. It partitions the changed files into non-overlapping territories—money, authz, state transitions, schema, budgets—sends one finder at each in parallel, then hands every claim to a fresh agent that never saw the reasoning behind it and is told to break it. Only a finding that survives that can block a merge, and blocking findings get a failing test written from the reproduction command before anyone writes the fix. It keeps going after the fixes land, re-reviewing exactly the territories a fix touched, because fixes written under review pressure are where the next round of bugs comes from. Reach for it before merging something you'd rather not get wrong—and type its name, since it won't fire on its own.

```bash
npx skills add kendrick/skills --skill adversarial-review
```

### [handoff](handoff/README.md)

Use `handoff` to write a handoff before ending a coding-agent session, either to a file on your machine or to a document panel when you are working on the web. It restores unfinished tasks and context in a fresh session when conversation history would lose the detail needed to finish the work. See the [handoff guide](handoff/README.md) for Claude Code, Codex, and GitHub Copilot CLI invocation details.

```bash
npx skills add kendrick/skills --skill handoff
```

### [technical-writing](technical-writing/README.md)

Routes developer-facing prose—commit messages, code comments, PR descriptions, API reference, READMEs—to a profile that names which public standards apply: Diátaxis, Google developer style, ASD-STE100 principles, and Kohl's Global English. Two profiles ship today, commit messages and code comments; the rest fall back to the global rules until their profiles are written. Every draft ends in a mandatory audit: a self-check, then whatever prose-audit skill and house rules your setup provides. Reach for it when a commit message, comment, or doc needs to read like a person actually wrote it.

```bash
npx skills add kendrick/skills --skill technical-writing
```

## Repository Layout

- [databricks-api/](databricks-api/), [file-issue/](file-issue/), [inbox-to-memory/](inbox-to-memory/), [readme-coauthorship/](readme-coauthorship/), [handoff/](handoff/), [adversarial-review/](adversarial-review/), [technical-writing/](technical-writing/): the skills, one directory each
- [\_docs/](_docs/): research notes behind the skills, like the [readme-coauthorship writeup](_docs/readme-coauthorship-research.md) and the [issue-authorship survey](_docs/file-issue-research.md)
- [\_maintenance/](_maintenance/): maintainer tooling, one subdirectory per skill that needs it: the refresh workflow that keeps `databricks-api` synced with upstream Databricks docs, the upstream sync behind `handoff`, and the decision ledgers and evals behind `file-issue` and `adversarial-review`

## Contributing

Contributions are welcome and the process is informal: open an issue or a PR. There's no template to fill out and no CLA to sign. If you're adding a skill, a `SKILL.md` and a short `README.md` in its own directory is all it takes to match the others.

## License

MIT. See [LICENSE](LICENSE).
