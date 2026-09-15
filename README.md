```
███████╗██╗  ██╗██╗██╗     ██╗     ███████╗
██╔════╝██║ ██╔╝██║██║     ██║     ██╔════╝
███████╗█████╔╝ ██║██║     ██║     ███████╗
╚════██║██╔═██╗ ██║██║     ██║     ╚════██║
███████║██║  ██╗██║███████╗███████╗███████║
╚══════╝╚═╝  ╚═╝╚═╝╚══════╝╚══════╝╚══════╝
```

# skills

Agent skills you can install individually or all at once. Each skill is its own directory with its own guide, with no dependencies.

- [Install](#install)
- [The Skills](#the-skills): [Filing and memory](#filing-and-memory) · [Writing around code](#writing-around-code) · [Inside a coding session](#inside-a-coding-session) · [Platform APIs](#platform-apis)
- [Repository Layout](#repository-layout)
- [Contributing](#contributing)
- [License](#license)

## Install

You need Node 22.20 or newer, which is what the [`skills` CLI](https://github.com/vercel-labs/skills) asks for, and nothing else.

Install the whole collection:

```bash
npx skills add kendrick/skills
```

Or take one:

```bash
npx skills add kendrick/skills --skill technical-writing
```

Either way the CLI writes the skill directories where your harness looks for them, and the skill is live in your next session. To check it landed, ask your agent to use it by name:

```
> use technical-writing on this commit message
```

If you're picking a first one, start with `technical-writing`, `file-issue`, or `readme-coauthorship`. None of them need a vault or an approved plan, and all three land on work you already do. One thing to know about the middle one: `file-issue` posts through the [GitHub CLI](https://cli.github.com), so authenticate `gh` before you expect it to file anything. Without that it still drafts, and says plainly that it can't post.

Each skill's own README covers which harnesses it's been used in and how to invoke it there, along with any CLI it expects.

## The Skills

| Skill                                              | What it does                                                        | Install flag                  |
| -------------------------------------------------- | ------------------------------------------------------------------- | ----------------------------- |
| [inbox-to-memory](inbox-to-memory/)                | Meeting exhaust into groomed notes and durable memory               | `--skill inbox-to-memory`     |
| [jd-file](jd-file/README.md)                       | Gives an arriving thing its Johnny.Decimal number and register line | `--skill jd-file`             |
| [jd-audit](jd-audit/README.md)                     | Finds drift between a Johnny.Decimal register and its folders       | `--skill jd-audit`            |
| [technical-writing](technical-writing/README.md)   | Commits, comments, and PR prose against named public standards      | `--skill technical-writing`   |
| [readme-coauthorship](readme-coauthorship/)        | READMEs, brand-new or long-neglected, root or nested                | `--skill readme-coauthorship` |
| [file-issue](file-issue/README.md)                 | One GitHub issue, interrogated before it's filed                    | `--skill file-issue`          |
| [jira-refine](jira-refine/README.md)               | Refinement transcripts into enriched Jira issues                    | `--skill jira-refine`         |
| [eli5](eli5/README.md)                             | Says the last message again, shorter and without jargon             | `--skill eli5`                |
| [adversarial-review](adversarial-review/README.md) | Reviews a diff by trying to break its own findings                  | `--skill adversarial-review`  |
| [divvy-up](divvy-up/README.md)                     | Runs an approved plan as waves of parallel subagents                | `--skill divvy-up`            |
| [handoff](handoff/README.md)                       | Carries unfinished work into a fresh session                        | `--skill handoff`             |
| [databricks-api](databricks-api/)                  | Databricks REST APIs and the Python SDK, eight domains              | `--skill databricks-api`      |

### Filing and memory

#### [inbox-to-memory](inbox-to-memory/)

Drop your meeting exhaust—transcripts, slide decks, PDFs, half-finished scratch notes—into an `_inbox/` folder, say "process the inbox," and each input comes back as one groomed markdown note: frontmatter up top, extracted quotes and tensions and action items in the middle, the verbatim original at the bottom. Along the way it flags memory candidates across three tiers, and you approve each record before it's written.

#### [jd-file](jd-file/README.md)

Gives an incoming thing its Johnny.Decimal number, puts it in the right tree, and writes the register line in the same motion, so the index can't quietly fall behind the folders. It reads the vault's own conventions file for the grammar instead of hardcoding rules, and scales its caution to the stakes: a clean match files without a question, a new area never happens without you saying so.

#### [jd-audit](jd-audit/README.md)

Checks a Johnny.Decimal system for drift and walks you through reconciling what it finds. The comparison itself is a standard-library Python script reading the same conventions file `jd-file` reads, because a diff wants a diff tool rather than a fresh act of judgment every run. Severity tracks how much judgment a finding still needs, and reconciliation decisions stay yours.

### Writing around code

#### [technical-writing](technical-writing/README.md)

Routes developer-facing prose—commit messages, code comments, PR descriptions, API reference, READMEs—to a profile that names which public standards apply: [Diátaxis](https://diataxis.fr/start-here/), [Google developer style](https://developers.google.com/style), [ASD-STE100](https://www.techwriter.ai/s1000d/writing-for-s1000d/simplified-technical-english) principles, and [Kohl's Global English](https://books.google.com/books?id=r0AiqqRBPF0C&printsec=frontcover#v=onepage&q&f=false). Four profiles ship today; the rest fall back to global rules. Every draft ends in a mandatory audit.

#### [readme-coauthorship](readme-coauthorship/)

Co-authors READMEs—this one included—whether brand-new, long-neglected, at the repo root, or buried in a monorepo. It scans the repo before asking anything, refuses to fabricate what it can't verify, and structures what it writes as a funnel from general to specific. Runs guided, a short wizard of targeted questions, or autopilot, which infers everything from repo metadata.

#### [file-issue](file-issue/README.md)

Writes one GitHub issue and files it with `gh`. Most issue tooling checks that you filled in the template; this checks whether what you filled in is any good—can a stranger run your reproduction steps, can your acceptance criteria fail, does a coding agent picking it up know how to verify its own work. It reads the repo first, so an existing issue form always wins.

#### [jira-refine](jira-refine/README.md)

Turns a recorded backlog-refinement transcript into enriched Jira issues. It segments by the project keys spoken aloud, fills a fixed seven-field template only from what was actually said, and anchors every acceptance criterion to a verbatim quote—a slot the room never reached gets a `- not discussed` line instead of a guess. Nothing reaches Jira until you mark a staged ticket `approved`.

#### [eli5](eli5/README.md)

Type `/eli5` when the agent's last message didn't land, and it says it again—shorter, no jargon, like one human talking to another. Pass the confusing part as an argument (`/eli5 the part about cache invalidation`) to re-pitch just that piece. The restatement adds no new claims and only ever fires when you type it. A mashup of `bro` from Lauren Tan's pstack and `wait-what` from Matt Pocock's skills, both MIT.

### Inside a coding session

#### [adversarial-review](adversarial-review/README.md)

Reviews a diff by treating every finding as a hypothesis rather than a result. It partitions the changed files into non-overlapping territories—money, authz, state transitions, schema, budgets—sends one finder at each in parallel, then hands every claim to a fresh agent that never saw the reasoning behind it and is told to break it. Only a finding that survives can block a merge, and blockers get a failing test before anyone writes the fix.

#### [divvy-up](divvy-up/README.md)

Runs an implementation plan you've already approved as waves of parallel subagents rather than one task at a time. One mechanism makes that safe: every task declares the exact files it owns, and a script proves no two tasks in a wave own the same path before anything is dispatched. An overlap stops the run rather than warning about it, because two agents editing one file in one working tree lose a write and neither reports it.

#### [handoff](handoff/README.md)

Writes a handoff before you end a coding-agent session, either to a file on your machine or to a document panel when you're working on the web. A fresh session picks it up and keeps going, where raw conversation history would lose the detail needed to finish the work. The [handoff guide](handoff/README.md) covers Claude Code, Codex, and GitHub Copilot CLI invocation.

### Platform APIs

#### [databricks-api](databricks-api/)

A router plus eight domain skills covering the Databricks REST APIs and the Python SDK: Unity Catalog, Jobs and Workflows, SQL warehouses, Model Serving, Delta Sharing, Genie, Marketplace, and file management. One rule holds it together: every endpoint, field, and enum value it hands you comes from a doc it actually read, not from memory. The router points you to a domain, the domain points you to the bucket file.

## Repository Layout

- [databricks-api/](databricks-api/), [file-issue/](file-issue/), [jira-refine/](jira-refine/), [inbox-to-memory/](inbox-to-memory/), [jd-file/](jd-file/), [jd-audit/](jd-audit/), [readme-coauthorship/](readme-coauthorship/), [handoff/](handoff/), [adversarial-review/](adversarial-review/), [divvy-up/](divvy-up/), [technical-writing/](technical-writing/), [eli5/](eli5/): the skills themselves, one directory each
- **[\_docs/](_docs/)**: research notes behind the skills, like the [readme-coauthorship writeup](_docs/readme-coauthorship-research.md) and the [issue-authorship survey](_docs/file-issue-research.md)
- **[\_maintenance/](_maintenance/)**: maintainer tooling, one subdirectory per skill that needs it: the refresh workflow that keeps `databricks-api` synced with upstream Databricks docs, the upstream sync behind `handoff`, the check that holds the `jd` pair's prose to the vault register, and the decision ledgers, evals, and provenance records behind the rest
- **[tests/](tests/)**: smoke scripts that pin the load-bearing decisions in each skill and in the repo's agent docs; each runs standalone from the repo root, like `bash tests/technical-writing-smoke.sh`

## Contributing

Contributions are welcome and the process is informal: open an issue or a PR. There's no template to fill out and no CLA to sign. If you're adding a skill, `AGENTS.md` describes what one ships: a `SKILL.md` and a `README.md` in its own directory, a decision ledger under `_maintenance/`, and a smoke test under `tests/`. The first two are the skill; the last two are what keep it honest as it changes.

## License

MIT. See [LICENSE](LICENSE).
