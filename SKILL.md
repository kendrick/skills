# Databricks API Reference

| Property    | Value                                                                  |
| ----------- | ---------------------------------------------------------------------- |
| Name        | databricks-api                                                         |
| Description | Task-oriented REST & Python SDK reference for Databricks platform APIs |
| Version     | 1.0                                                                    |

> Compressed from official Databricks docs. Two-tier routing: this file points you to a domain,
> each domain's SKILL.md points you to the specific sub-file for your task.

## Quick Routing

Match your task to a domain, then read that domain's `SKILL.md` for sub-file routing.

| What are you trying to do?                                          | Domain            | Entry point                |
| ------------------------------------------------------------------- | ----------------- | -------------------------- |
| Manage catalogs, schemas, tables, volumes, grants, sharing, lineage | **Unity Catalog** | `unity-catalog/SKILL.md`   |
| List or distribute data products, manage private exchanges          | **Marketplace**   | `marketplace/SKILL.md`     |
| Deploy or manage Databricks Apps (Next.js, Flask, etc.)             | **Apps**          | `apps/SKILL.md`            |
| Execute SQL, manage warehouses, query history                       | **SQL**           | `sql/SKILL.md`             |
| Create or manage jobs, workflows, runs, compliance                  | **Jobs**          | `jobs-and-workflows/SKILL.md` |
| Manage clusters, instance pools, policies                           | **Compute**       | `compute/SKILL.md`         |
| Serve models, manage endpoints, AI Gateway, provisioned throughput  | **Model Serving** | `model-serving/SKILL.md`   |
| Manage notebooks, repos, Git folders, workspace objects             | **Workspace**     | `workspace/SKILL.md`       |
| Manage users, groups, service principals, tokens                    | **IAM**           | `iam/SKILL.md`             |
| Manage secrets, secret scopes                                       | **Secrets**       | `secrets/SKILL.md`         |
| Build or manage pipelines (DLT / Lakeflow)                          | **Pipelines**     | `pipelines/SKILL.md`       |
| Manage dashboards (Lakeview)                                        | **Dashboards**    | `dashboards/SKILL.md`      |
| AI data assistant — Genie spaces, conversations, evals              | **Genie**         | `genie/SKILL.md`           |
| Upload, download, manage files (Files API + DBFS)                   | **File Mgmt**     | `file-management/SKILL.md` |
| Manage shares, recipients, providers, activation, federation        | **Delta Sharing** | `delta-sharing/SKILL.md`   |

## Domain Status

Tracks which domains have been built and their completeness.

| Domain        | Status         | Files          | Notes                                           |
| ------------- | -------------- | -------------- | ----------------------------------------------- |
| Unity Catalog | ✅ Built       | 8 REST + 8 SDK | Quality monitors added as separate bucket       |
| Marketplace   | ✅ Built       | 3 REST + 3 SDK | Consumer, provider listings, exchanges          |
| Apps          | 🔲 Not started | —              | —                                               |
| SQL           | ✅ Built       | 3 REST + 3 SDK | Warehouses, statement execution, queries/alerts |
| Jobs          | ✅ Built       | 1 REST + 1 SDK | All 23 endpoints in single bucket               |
| Compute       | 🔲 Not started | —              | —                                               |
| Model Serving | ✅ Built       | 1 REST + 1 SDK | All 20 endpoints in single bucket               |
| Workspace     | 🔲 Not started | —              | —                                               |
| IAM           | 🔲 Not started | —              | —                                               |
| Secrets       | 🔲 Not started | —              | —                                               |
| Pipelines     | 🔲 Not started | —              | —                                               |
| Dashboards    | 🔲 Not started | —              | —                                               |
| Genie         | ✅ Built       | 2 REST + 2 SDK | Spaces/conversations + evals                    |
| File Mgmt     | ✅ Built       | 2 REST + 2 SDK | Files API (modern) + DBFS (legacy)              |
| Delta Sharing | ✅ Built       | 4 REST + 4 SDK | Shares, recipients, providers, auth/federation  |

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

## Directory Structure

```
databricks/
├── SKILL.md                          ← YOU ARE HERE — top-level router
├── unity-catalog/
│   ├── SKILL.md                      ← UC domain router
│   ├── rest/
│   │   ├── uc-catalog-schema-table.md
│   │   ├── uc-volumes-files.md
│   │   ├── uc-grants-permissions.md
│   │   ├── uc-external-locations.md
│   │   ├── uc-lineage-tags.md
│   │   ├── uc-functions-models.md
│   │   ├── uc-metastore-admin.md
│   │   └── uc-quality-monitors.md
│   └── python-sdk/
│       └── (matching files)
├── genie/
│   ├── SKILL.md                      ← Genie domain router
│   ├── rest/
│   │   ├── genie-spaces-conversations.md
│   │   └── genie-evals.md
│   └── python-sdk/
│       └── (matching files)
├── marketplace/
│   ├── SKILL.md                      ← Marketplace domain router
│   ├── rest/
│   │   ├── mkt-consumer.md
│   │   ├── mkt-provider-listings.md
│   │   └── mkt-provider-exchanges.md
│   └── python-sdk/
│       └── (matching files)
├── sql/
│   ├── SKILL.md                      ← SQL domain router
│   ├── rest/
│   │   ├── sql-warehouses.md
│   │   ├── sql-statement-execution.md
│   │   └── sql-queries-alerts.md
│   └── python-sdk/
│       └── (matching files)
├── model-serving/
│   ├── SKILL.md                      ← Model Serving domain router
│   ├── rest/
│   │   └── serving-endpoints.md
│   └── python-sdk/
│       └── (matching files)
├── file-management/
│   ├── SKILL.md                      ← File Management domain router
│   ├── rest/
│   │   ├── files-api.md
│   │   └── dbfs-api.md
│   └── python-sdk/
│       └── (matching files)
├── jobs-and-workflows/
│   ├── SKILL.md                      ← Jobs domain router
│   ├── rest/
│   │   └── jobs-lifecycle.md
│   └── python-sdk/
│       └── (matching files)
├── delta-sharing/
│   ├── SKILL.md                      ← Delta Sharing domain router
│   ├── rest/
│   │   ├── ds-shares.md
│   │   ├── ds-recipients.md
│   │   ├── ds-providers.md
│   │   └── ds-recipient-auth.md
│   └── python-sdk/
│       └── (matching files)
├── apps/
│   └── ...
└── (other domains as built)
```

## Building new domain skills

To add a new domain, use the skill generator prompt:
`~/.local/share/skills/databricks/databricks-skill-generator-prompt.md`

Feed it a domain name + endpoint list and it will produce the full skill set with SKILL.md router.
After generating, update the Domain Status table above.
