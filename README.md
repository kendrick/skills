```
██████╗ ██████╗ ██╗  ██╗     █████╗ ██████╗ ██╗    ███████╗██╗  ██╗██╗██╗     ██╗     ███████╗
██╔══██╗██╔══██╗╚██╗██╔╝    ██╔══██╗██╔══██╗██║    ██╔════╝██║ ██╔╝██║██║     ██║     ██╔════╝
██║  ██║██████╔╝ ╚███╔╝     ███████║██████╔╝██║    ███████╗█████╔╝ ██║██║     ██║     ███████╗
██║  ██║██╔══██╗ ██╔██╗     ██╔══██║██╔═══╝ ██║    ╚════██║██╔═██╗ ██║██║     ██║     ╚════██║
██████╔╝██████╔╝██╔╝ ██╗    ██║  ██║██║     ██║    ███████║██║  ██╗██║███████╗███████╗███████║
╚═════╝ ╚═════╝ ╚═╝  ╚═╝    ╚═╝  ╚═╝╚═╝     ╚═╝    ╚══════╝╚═╝  ╚═╝╚═╝╚══════╝╚══════╝╚══════╝
```

# Databricks API Skills for Claude Code

A set of Claude Code skills that teach Claude how to drive the Databricks platform without making things up. Compressed from the official Databricks REST and Python SDK docs, organized as a two-tier router so Claude reads only the file that matches your task.

## Why This Exists

The Databricks API surface covers hundreds of endpoints across Unity Catalog, Jobs, SQL warehouses, Model Serving, Marketplace, Delta Sharing, Genie, and the rest of the platform. Pointing Claude at the raw docs is either too much context (the whole HTML site) or too little (Claude guesses field names and gets them wrong). These skills sit in between: bucket the surface by task, keep the parts that matter (paths, params, permissions, gotchas), drop everything else.

The two-tier router means Claude scans a small top-level table, picks a domain, then opens one ~200-line file inside that domain instead of loading every skill at once.

## What's Inside

Eight domains so far, each with mirrored REST-first and Python SDK-first variants:

| Domain             | What it covers                                                                                  | Files          |
| ------------------ | ----------------------------------------------------------------------------------------------- | -------------- |
| Unity Catalog      | Catalogs, schemas, tables, volumes, grants, ABAC, lineage, quality monitors, external locations | 8 REST + 8 SDK |
| Jobs and Workflows | Job lifecycle, runs, schedules, retries, compliance                                             | 1 REST + 1 SDK |
| SQL                | Warehouses, statement execution, queries and alerts                                             | 3 REST + 3 SDK |
| Model Serving      | Endpoint create/update, traffic config, AI Gateway, provisioned throughput                      | 1 REST + 1 SDK |
| Delta Sharing      | Shares, recipients, providers, recipient auth and federation                                    | 4 REST + 4 SDK |
| Marketplace        | Consumer browsing, provider listings, private exchanges                                         | 3 REST + 3 SDK |
| Genie              | Spaces and conversations, evals                                                                 | 2 REST + 2 SDK |
| File Management    | Files API (modern), DBFS (legacy)                                                               | 2 REST + 2 SDK |

About 9,800 lines of curated reference, with each file under ~350 lines so it fits in Claude's context without crowding everything else.

Not yet built: Knowledge Assistants, Apps, Compute, Workspace, IAM, Secrets, Pipelines (DLT/Lakeflow), and Dashboards (Lakeview). The full roadmap and status table lives in [SKILL.md](SKILL.md).

## Getting Set Up

Put the repo where your Claude Code install looks for user skills (usually `~/.claude/skills/`, or wherever your team keeps the shared ones). Claude Code will surface `databricks-api` as the entry skill, and the routing takes it from there.

The skills assume the standard Databricks auth setup:

```bash
export DATABRICKS_HOST=https://<workspace-host>
export DATABRICKS_TOKEN=dapi...
```

…or a profile in `~/.databrickscfg`. The Python SDK picks these up automatically via `WorkspaceClient()`. REST calls use the same token with a `Bearer` header. Account-level APIs (metastore admin, user management) hit `https://accounts.cloud.databricks.com` instead of the workspace host, and the relevant skill files flag this where it matters.

## Using It Day to Day

You don't invoke the skills directly. Just ask Claude what you want done. "Give me a script that grants USE CATALOG to a service principal." "List all running jobs and cancel anything older than 24h." "Set up a model serving endpoint with provisioned throughput." The routing pulls in the right file.

Want to bias toward REST or Python? Say so in the prompt. The two trees mirror each other file-for-file: same buckets, same headings, same workflows, different primary syntax. Cross-domain tasks (create a table AND grant access to it) pull in multiple files.

## How It's Built

Each domain follows the same shape:

```
{domain}/
├── SKILL.md          ← domain router, points at the right bucket file
├── rest/             ← REST/HTTP-primary docs
├── python-sdk/       ← SDK-primary docs
└── docs/raw/         ← original Jina-fetched docs (for the long version)
```

`docs/raw/` keeps the full fetched documentation, so when the compressed files leave a question open Claude has somewhere to look. The skill files themselves stick to a tight template: one example per operation, required vs. optional params called out, real permissions and error codes, and a "Gotchas" section for the stuff you only learn the hard way.

## Adding a New Domain

[databricks-skill-generator-prompt.md](databricks-skill-generator-prompt.md) is the recipe. Hand a subagent the prompt plus a domain name and an endpoint list, and it will:

1. Fetch the docs via Jina Reader
2. Strip the boilerplate nav
3. Propose a bucket grouping for your review
4. Generate REST + SDK skill files for each bucket
5. Write the domain SKILL.md router
6. Self-review for coverage and token budgets

After it runs, update the Domain Status table in [SKILL.md](SKILL.md) so the roadmap stays current.

## License

MIT. See [LICENSE](LICENSE).
