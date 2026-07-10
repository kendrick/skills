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

Three skills live here right now: one for driving Databricks APIs, one for turning meeting artifacts into durable notes, and one for writing READMEs. Each sits in its own directory with a full guide, loads into your LLM harness the same way, and works independently of the rest.

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

## Repository Layout

- [databricks-api/](databricks-api/), [inbox-to-memory/](inbox-to-memory/), [readme-coauthorship/](readme-coauthorship/): the skills, one directory each
- [\_docs/](_docs/): research notes behind the skills, like the [readme-coauthorship writeup](_docs/readme-coauthorship-research.md)
- [\_maintenance/](_maintenance/): maintainer tooling, including the refresh workflow that keeps `databricks-api` synced with upstream Databricks docs

## Contributing

Contributions are welcome and the process is informal: open an issue or a PR. There's no template to fill out and no CLA to sign. If you're adding a skill, a `SKILL.md` and a short `README.md` in its own directory is all it takes to match the others.

## License

MIT. See [LICENSE](LICENSE).
