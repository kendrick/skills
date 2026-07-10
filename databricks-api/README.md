```
██████╗ ██████╗ ██╗  ██╗     █████╗ ██████╗ ██╗    ███████╗██╗  ██╗██╗██╗     ██╗     ███████╗
██╔══██╗██╔══██╗╚██╗██╔╝    ██╔══██╗██╔══██╗██║    ██╔════╝██║ ██╔╝██║██║     ██║     ██╔════╝
██║  ██║██████╔╝ ╚███╔╝     ███████║██████╔╝██║    ███████╗█████╔╝ ██║██║     ██║     ███████╗
██║  ██║██╔══██╗ ██╔██╗     ██╔══██║██╔═══╝ ██║    ╚════██║██╔═██╗ ██║██║     ██║     ╚════██║
██████╔╝██████╔╝██╔╝ ██╗    ██║  ██║██║     ██║    ███████║██║  ██╗██║███████╗███████╗███████║
╚═════╝ ╚═════╝ ╚═╝  ╚═╝    ╚═╝  ╚═╝╚═╝     ╚═╝    ╚══════╝╚═╝  ╚═╝╚═╝╚══════╝╚══════╝╚══════╝
```

# Databricks API Skills for Claude Code

A set of skills that teach an agent how to drive the Databricks platform without making things up. Compressed from the official Databricks REST and Python SDK docs, organized as a two-tier router so an agent reads only the file that matches your task.

## Why This Exists

The Databricks API surface covers hundreds of endpoints across Unity Catalog, Jobs, SQL warehouses, Model Serving, Marketplace, Delta Sharing, Genie, and the rest of the platform. Pointing an agent at the raw docs is either too much context (the whole HTML site) or too little (agents guess field names and gets them wrong). These skills sit in between: bucket the surface by task, keep the parts that matter (paths, params, permissions, gotchas), drop everything else. The top router also carries a grounding rule—paths and field names come from the bucket files, never from memory.

The two-tier router means agents scan a small top-level table, picks a domain, then open one focused file inside that domain instead of loading every skill at once.

## What's Inside

This table is the source of truth for build status.

| Domain                   | Status         | What it covers                                                                                  |
| ------------------------ | -------------- | ----------------------------------------------------------------------------------------------- |
| Unity Catalog            | ✅ Built       | Catalogs, schemas, tables, volumes, grants, ABAC, lineage, quality monitors, external locations |
| Jobs and Workflows       | ✅ Built       | Job lifecycle, runs, schedules, retries, compliance                                             |
| SQL                      | ✅ Built       | Warehouses, statement execution, queries and alerts                                             |
| Model Serving            | ✅ Built       | Endpoint create/update, traffic config, AI Gateway, provisioned throughput                      |
| Delta Sharing            | ✅ Built       | Shares, recipients, providers, recipient auth and federation                                    |
| Marketplace              | ✅ Built       | Consumer browsing, provider listings, private exchanges                                         |
| Genie                    | ✅ Built       | Spaces and conversations, evals                                                                 |
| File Management          | ✅ Built       | Files API (modern), DBFS (legacy)                                                               |
| Knowledge Assistants     | 🔲 Not started | —                                                                                               |
| Apps                     | 🔲 Not started | —                                                                                               |
| Compute                  | 🔲 Not started | —                                                                                               |
| Workspace                | 🔲 Not started | —                                                                                               |
| IAM                      | 🔲 Not started | —                                                                                               |
| Secrets                  | 🔲 Not started | —                                                                                               |
| Pipelines (DLT/Lakeflow) | 🔲 Not started | —                                                                                               |
| Dashboards (Lakeview)    | 🔲 Not started | —                                                                                               |

Each built domain ships mirrored REST-first and Python SDK-first variants, and every skill file stays small enough to fit in Claude's context without crowding everything else.

## Getting Set Up

Symlink (or copy) the `databricks-api/` folder into wherever your Claude Code install looks for user skills (usually `~/.claude/skills/`, or wherever your team keeps the shared ones). Claude Code will surface `databricks-api` as the entry skill, and the routing takes it from there.

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
└── _docs/raw/        ← original Jina-fetched docs (for the long version)
```

`_docs/raw/` keeps the full fetched documentation, so when the compressed files leave a question open Claude has somewhere to look. The skill files themselves stick to a tight template: one example per operation, required vs. optional params called out, real permissions and error codes, and a "Gotchas" section for the stuff you only learn the hard way.

## Maintenance

Everything a maintainer needs lives in `_maintenance/` at the repo root, deliberately outside the shipped `databricks-api/` folder so skill installers that scan for SKILL.md files never pick it up.

### Adding a New Domain

[\_maintenance/databricks-skill-generator-prompt.md](../_maintenance/databricks-skill-generator-prompt.md) is the recipe. Hand a subagent the prompt plus a domain name and an endpoint list; it fetches docs via Jina, proposes a bucket grouping for your review, generates the REST + SDK skill files and the domain router, then self-reviews for coverage and token budgets. After it runs, update the status table above.

### Keeping Skills Current

Databricks docs evolve: fields get added, endpoints come out of preview, occasionally something gets renamed. Each domain tracks its fetched docs' source URLs and content hashes in `{domain}/_docs/sources.json`. From `_maintenance/`, a bash script handles the deterministic side:

```bash
bash tools/refresh.sh --check --domain <name>      # detect drift, write a report
bash tools/refresh.sh --apply --domain <name>      # apply upstream changes to raw docs + manifest
bash tools/refresh.sh --backfill --domain <name>   # (re)build the manifest from on-disk raw docs
```

For the semantic side (deciding which compressed skill files need updating based on the drift report), the companion workflow at [\_maintenance/refresh-skill/SKILL.md](../_maintenance/refresh-skill/SKILL.md) walks Claude through proposing edits.

### A Note on the Nested SKILL.md Files

The domain routers carry one-line descriptions because this repo assumes symlink-only deployment, where nested SKILL.mds never register as standalone skills and trigger phrasing in their descriptions would be dead weight. If distribution ever moves to a scanner that registers them (e.g. `npx skills`), revisit those descriptions—they'd become live triggering surface.

## License

MIT. See [LICENSE](LICENSE).
