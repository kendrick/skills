---
name: databricks-api
description: Top-level router for Databricks platform REST APIs and the Python SDK. Use for any Databricks API or SDK task: Unity Catalog (catalogs, schemas, tables, grants, lineage, quality monitors), Jobs and Workflows, SQL warehouses and statement execution, Model Serving and AI Gateway, Delta Sharing, Genie, Marketplace, or file management on volumes and DBFS. It will route you to the right domain skill. Also use when you're not sure which Databricks API owns the task.
---

# Databricks API Reference

> Compressed from official Databricks docs. Two-tier routing: this file points you to a domain,
> each domain's SKILL.md points you to the specific sub-file for your task.

## Quick Routing

Match your task to a domain, then read that domain's `SKILL.md` for sub-file routing. Rows tagged 🔲 are not yet built; the entry point doesn't exist on disk yet.

| What are you trying to do?                                          | Domain            | Entry point                       |
| ------------------------------------------------------------------- | ----------------- | --------------------------------- |
| Manage catalogs, schemas, tables, volumes, grants, sharing, lineage | **Unity Catalog** | `unity-catalog/SKILL.md`          |
| List or distribute data products, manage private exchanges          | **Marketplace**   | `marketplace/SKILL.md`            |
| Execute SQL, manage warehouses, query history                       | **SQL**           | `sql/SKILL.md`                    |
| Create or manage jobs, workflows, runs, compliance                  | **Jobs**          | `jobs-and-workflows/SKILL.md`     |
| Serve models, manage endpoints, AI Gateway, provisioned throughput  | **Model Serving** | `model-serving/SKILL.md`          |
| AI data assistant — Genie spaces, conversations, evals              | **Genie**         | `genie/SKILL.md`                  |
| Upload, download, manage files (Files API + DBFS)                   | **File Mgmt**     | `file-management/SKILL.md`        |
| Manage shares, recipients, providers, activation, federation        | **Delta Sharing** | `delta-sharing/SKILL.md`          |
| Vector search and knowledge assistants                              | **Knowledge Assistants** | 🔲 Not started (`knowledge-assistants/`) |
| Deploy or manage Databricks Apps (Next.js, Flask, etc.)             | **Apps**          | 🔲 Not started (`apps/`)          |
| Manage clusters, instance pools, policies                           | **Compute**       | 🔲 Not started (`compute/`)       |
| Manage notebooks, repos, Git folders, workspace objects             | **Workspace**     | 🔲 Not started (`workspace/`)     |
| Manage users, groups, service principals, tokens                    | **IAM**           | 🔲 Not started (`iam/`)           |
| Manage secrets, secret scopes                                       | **Secrets**       | 🔲 Not started (`secrets/`)       |
| Build or manage pipelines (DLT / Lakeflow)                          | **Pipelines**     | 🔲 Not started (`pipelines/`)     |
| Manage dashboards (Lakeview)                                        | **Dashboards**    | 🔲 Not started (`dashboards/`)    |

## Domain Status

Tracks which domains have been built and their completeness.

| Domain               | Status         | Files          | Notes                                           |
| -------------------- | -------------- | -------------- | ----------------------------------------------- |
| Unity Catalog        | ✅ Built       | 8 REST + 8 SDK | Quality monitors added as separate bucket       |
| Marketplace          | ✅ Built       | 3 REST + 3 SDK | Consumer, provider listings, exchanges          |
| SQL                  | ✅ Built       | 3 REST + 3 SDK | Warehouses, statement execution, queries/alerts |
| Jobs                 | ✅ Built       | 1 REST + 1 SDK | All 23 endpoints in single bucket               |
| Model Serving        | ✅ Built       | 1 REST + 1 SDK | All 20 endpoints in single bucket               |
| Genie                | ✅ Built       | 2 REST + 2 SDK | Spaces/conversations + evals                    |
| File Mgmt            | ✅ Built       | 2 REST + 2 SDK | Files API (modern) + DBFS (legacy)              |
| Delta Sharing        | ✅ Built       | 4 REST + 4 SDK | Shares, recipients, providers, auth/federation  |
| Knowledge Assistants | 🔲 Not started | —              | —                                               |
| Apps                 | 🔲 Not started | —              | —                                               |
| Compute              | 🔲 Not started | —              | —                                               |
| Workspace            | 🔲 Not started | —              | —                                               |
| IAM                  | 🔲 Not started | —              | —                                               |
| Secrets              | 🔲 Not started | —              | —                                               |
| Pipelines            | 🔲 Not started | —              | —                                               |
| Dashboards           | 🔲 Not started | —              | —                                               |

## Auth (all domains)

### REST — all requests

```
Authorization: Bearer <PAT-or-OAuth-token>
Base URL: https://<workspace-host>
```

For account-level APIs (metastore admin, user management):

```
Base URL: https://accounts.cloud.databricks.com
```

### Python SDK

```bash
export DATABRICKS_HOST=https://<workspace-host>
export DATABRICKS_TOKEN=dapi...
```

```python
from databricks.sdk import WorkspaceClient
w = WorkspaceClient()  # auto-detects from env or .databrickscfg

# For account-level APIs:
from databricks.sdk import AccountClient
a = AccountClient()
```

### Auth patterns

- **Local dev:** PAT via env var or `.databrickscfg` profile
- **Deployed Apps (OAuth M2M):** Service principal with client_id + client_secret
- **Notebooks:** Auto-auth via runtime (no config needed in DBR 13.1+)

## Building new domain skills

To add a new domain, use the skill generator prompt:
`~/.local/share/skills/databricks/databricks-skill-generator-prompt.md`

Feed it a domain name + endpoint list and it will produce the full skill set with SKILL.md router.
After generating, update the Domain Status table above.
