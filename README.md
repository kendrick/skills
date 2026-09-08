```
███████╗██╗  ██╗██╗██╗     ██╗     ███████╗
██╔════╝██║ ██╔╝██║██║     ██║     ██╔════╝
███████╗█████╔╝ ██║██║     ██║     ███████╗
╚════██║██╔═██╗ ██║██║     ██║     ╚════██║
███████║██║  ██╗██║███████╗███████╗███████║
╚══════╝╚═╝  ╚═╝╚═╝╚══════╝╚══════╝╚══════╝
```

# skills

Agent skills you can install individually or all at once.

Twelve skills live here right now. One drives the Databricks APIs. Three keep your working life filed: meeting exhaust into durable notes, Johnny.Decimal filing, and the audit that keeps that system honest. Five cover the writing developers do around code: READMEs, GitHub issues, backlog-refinement transcripts turned into Jira tickets, commit-and-PR prose, and a plain restatement when a message didn't land. The last three attach to a coding session: one reviews a diff adversarially, one runs an approved plan as waves of parallel subagents, and one carries unfinished work into a fresh session. Each sits in its own directory with a full guide, loads into your LLM harness the same way, and works independently of the rest.

- [Install](#install)
- [The Skills](#the-skills): [databricks-api](#databricks-api) · [file-issue](#file-issue) · [jira-refine](#jira-refine) · [inbox-to-memory](#inbox-to-memory) · [jd-file](#jd-file) · [jd-audit](#jd-audit) · [readme-coauthorship](#readme-coauthorship) · [adversarial-review](#adversarial-review) · [divvy-up](#divvy-up) · [handoff](#handoff) · [technical-writing](#technical-writing) · [eli5](#eli5)
- [Repository Layout](#repository-layout)
- [Contributing](#contributing)
- [License](#license)

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

### [jira-refine](jira-refine/README.md)

Turns the transcript of a recorded backlog-refinement session into enriched Jira issues. It segments the transcript by the project keys spoken aloud, fills a fixed seven-field template only from what was actually said, and anchors every acceptance criterion, dependency, and goal to a verbatim quote from its own excerpt—a slot the room never reached gets a `- not discussed` line instead of a guess. Every ticket lands first in a staging file beside its source excerpt, and nothing reaches Jira until a person marks it `approved`; apply mode then previews the writes in a dry run and asks for confirmation before pushing anything for real. It enriches issues that already exist, so a gap the room named but never ticketed gets drafted in `file-issue`'s task shape instead—`file-issue` only creates GitHub issues today, not Jira ones. Reach for it right after a refinement call, before what the room decided lives only in a recording—and type its name, since it won't fire on its own.

```bash
npx skills add kendrick/skills --skill jira-refine
```

### [inbox-to-memory](inbox-to-memory/)

Drop your meeting exhaust—transcripts, slide decks, PDFs, half-finished scratch notes—into an `_inbox/` folder, say "process the inbox," and each input comes back as one groomed markdown note: frontmatter up top, extracted quotes and tensions and action items in the middle, the verbatim original at the bottom. Along the way it flags candidates for longer-term memory across three tiers (a project, a client, or a cross-cutting journal), and you approve each record before it's written. It also scaffolds the directory structure for a new project, client, or journal. Reach for it when your calendar generates more paper than insight.

```bash
npx skills add kendrick/skills --skill inbox-to-memory
```

### [jd-file](jd-file/README.md)

Gives an incoming thing its Johnny.Decimal number, puts it in the right tree, and writes the register line in the same motion, so the index can't quietly fall behind the folders. It reads the vault's own conventions file for the grammar instead of hardcoding rules, follows the precedent a category already sets, and scales its caution to the stakes: a clean match files without a question, a new ID gets a confirm, and a new area or category never happens without you saying so. Reach for it when something arrives—a PDF, a deck, a client, a whole project—and you don't know where it lives.

```bash
npx skills add kendrick/skills --skill jd-file
```

### [jd-audit](jd-audit/README.md)

Checks a Johnny.Decimal system for drift and walks you through reconciling what it finds. The comparison itself is a standard-library Python script reading the same conventions file jd-file reads, because a diff wants a diff tool, not a fresh act of judgment every run. Severity tracks how much judgment a finding still needs: the register and the folders disagreeing is an error, a name recurring under two IDs is a warning that asks for a call, and a link another machine owns is informational. Reconciliation decisions stay yours, and filing new things belongs to jd-file. Reach for it when your numbering feels off or your index has drifted from your folders.

```bash
npx skills add kendrick/skills --skill jd-audit
```

### [readme-coauthorship](readme-coauthorship/)

Co-authors READMEs—this one included—whether brand-new, long-neglected, at the repo root, or buried in a monorepo. It scans the repo before asking anything, refuses to fabricate what it can't verify, and structures what it writes as a funnel from general to specific. Runs guided (a short wizard of targeted questions) or autopilot (infers everything from repo metadata). Where the technical-writing skill is installed, the draft takes a polish pass through its README profile before validation. Reach for it to write a README from scratch or refresh one that's drifted.

```bash
npx skills add kendrick/skills --skill readme-coauthorship
```

### [adversarial-review](adversarial-review/README.md)

Reviews a diff by treating every finding as a hypothesis rather than a result. It partitions the changed files into non-overlapping territories—money, authz, state transitions, schema, budgets—sends one finder at each in parallel, then hands every claim to a fresh agent that never saw the reasoning behind it and is told to break it. Only a finding that survives that can block a merge, and blocking findings get a failing test written from the reproduction command before anyone writes the fix. It keeps going after the fixes land, re-reviewing exactly the territories a fix touched, because fixes written under review pressure are where the next round of bugs comes from. Reach for it before merging something you'd rather not get wrong—and type its name, since it won't fire on its own.

```bash
npx skills add kendrick/skills --skill adversarial-review
```

### [divvy-up](divvy-up/README.md)

Runs an implementation plan you've already approved as waves of parallel subagents rather than one task at a time. One mechanism makes that safe: every task declares the exact files it owns, and a script proves that no two tasks in the same wave own the same path before anything is dispatched. An overlap stops the run rather than warning about it, because two agents editing one file in one working tree lose a write and neither of them reports it. Each task also goes to the cheapest model that can do it correctly, and the savings hold because deriving the tasks, gating each wave, and reading the merged diff at the end all stay on the session model. Delegation that also delegates the judgment of whether the work came back right doesn't save you anything. Reach for it when a plan is settled and its tasks can be carved into disjoint files—and type its name, since it won't fire on its own.

```bash
npx skills add kendrick/skills --skill divvy-up
```

### [handoff](handoff/README.md)

Use `handoff` to write a handoff before ending a coding-agent session, either to a file on your machine or to a document panel when you are working on the web. It restores unfinished tasks and context in a fresh session when conversation history would lose the detail needed to finish the work. See the [handoff guide](handoff/README.md) for Claude Code, Codex, and GitHub Copilot CLI invocation details.

```bash
npx skills add kendrick/skills --skill handoff
```

### [technical-writing](technical-writing/README.md)

Routes developer-facing prose—commit messages, code comments, PR descriptions, API reference, READMEs—to a profile that names which public standards apply: [Diátaxis](https://diataxis.fr/start-here/), [Google developer style](https://developers.google.com/style), [ASD-STE100](https://www.techwriter.ai/s1000d/writing-for-s1000d/simplified-technical-english) principles, and [Kohl's Global English](https://books.google.com/books?id=r0AiqqRBPF0C&printsec=frontcover#v=onepage&q&f=false). Four profiles ship today: commit messages, code comments, PR descriptions, and README prose; the rest fall back to the global rules until their profiles are written. Every draft ends in a mandatory audit: a self-check, then whatever prose-audit skill and house rules your setup provides. Reach for it when a commit message, comment, or doc needs to read like a person actually wrote it.

```bash
npx skills add kendrick/skills --skill technical-writing
```

### [eli5](eli5/README.md)

Type `/eli5` when the agent's last message didn't land, and it says it again—shorter, no jargon, like one human talking to another. Pass the confusing part as an argument (`/eli5 the part about cache invalidation`) to re-pitch just that piece; bare `/eli5` re-pitches the whole response, including what the tool activity concluded. The restatement follows a distilled ASD-STE100 (one idea per sentence, imperative mood, one meaning per word), adds no new claims, and only ever fires when you type it. A mashup of `bro` from Lauren Tan's pstack and `wait-what` from Matt Pocock's skills, both MIT.

```bash
npx skills add kendrick/skills --skill eli5
```

## Repository Layout

- [databricks-api/](databricks-api/), [file-issue/](file-issue/), [jira-refine/](jira-refine/), [inbox-to-memory/](inbox-to-memory/), [jd-file/](jd-file/), [jd-audit/](jd-audit/), [readme-coauthorship/](readme-coauthorship/), [handoff/](handoff/), [adversarial-review/](adversarial-review/), [divvy-up/](divvy-up/), [technical-writing/](technical-writing/), [eli5/](eli5/): the skills, one directory each
- [\_docs/](_docs/): research notes behind the skills, like the [readme-coauthorship writeup](_docs/readme-coauthorship-research.md) and the [issue-authorship survey](_docs/file-issue-research.md)
- [\_maintenance/](_maintenance/): maintainer tooling, one subdirectory per skill that needs it: the refresh workflow that keeps `databricks-api` synced with upstream Databricks docs, the upstream sync behind `handoff`, the check that holds the `jd` pair's prose to the vault register, and the decision ledgers, evals, and provenance records behind the rest
- [tests/](tests/): smoke scripts that pin the load-bearing decisions in each skill and in the repo's agent docs; each runs standalone from the repo root, like `bash tests/technical-writing-smoke.sh`

## Contributing

Contributions are welcome and the process is informal: open an issue or a PR. There's no template to fill out and no CLA to sign. If you're adding a skill, `AGENTS.md` describes what one ships: a `SKILL.md` and a `README.md` in its own directory, a decision ledger under `_maintenance/`, and a smoke test under `tests/`. The first two are the skill; the last two are what keep it honest as it changes.

## License

MIT. See [LICENSE](LICENSE).
