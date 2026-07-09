---
name: databricks-sql
description: "Run SQL on Databricks via warehouses, statement execution, saved queries, and alerts. Use when creating, starting, or stopping a SQL warehouse, setting warehouse permissions or workspace defaults, executing a SQL statement (sync or async), polling for results via INLINE or EXTERNAL_LINKS disposition, downloading result chunks, cancelling a long-running statement, saving queries, or building alerts on query results. Heads up: EXTERNAL_LINKS pre-signed URLs expire fast, so fetch chunks promptly."
---

# Databricks SQL API Skills

> Parent: [../SKILL.md](../SKILL.md) (top-level Databricks API router)

## Usage

1. Match your task to a file using Quick Lookup below
2. Read the file in `rest/` (HTTP) or `python-sdk/` (SDK)
3. For cross-domain tasks, read multiple files

## Quick Lookup

| Task                                              | File                      |
| ------------------------------------------------- | ------------------------- |
| Create, edit, start, or stop a SQL warehouse      | `sql-warehouses`          |
| Set permissions on a warehouse                    | `sql-warehouses`          |
| Configure workspace warehouse defaults            | `sql-warehouses`          |
| Manage default warehouse overrides                | `sql-warehouses`          |
| Execute a SQL statement and get results           | `sql-statement-execution` |
| Poll for async query results or get result chunks | `sql-statement-execution` |
| Cancel a running statement                        | `sql-statement-execution` |
| Create or manage saved queries                    | `sql-queries-alerts`      |
| Create or manage alerts on query results          | `sql-queries-alerts`      |

## REST API Skills

| File                              | Scope                                                     | Endpoints |
| --------------------------------- | --------------------------------------------------------- | --------- |
| `rest/sql-warehouses.md`          | Warehouse CRUD, lifecycle, permissions, config, overrides | 18        |
| `rest/sql-statement-execution.md` | Execute SQL, poll results, get chunks, cancel             | 4         |
| `rest/sql-queries-alerts.md`      | Saved queries and alert definitions                       | 10        |

## Python SDK Skills

| File                                    | Key Clients             |
| --------------------------------------- | ----------------------- |
| `python-sdk/sql-warehouses.md`          | `w.warehouses`          |
| `python-sdk/sql-statement-execution.md` | `w.statement_execution` |
| `python-sdk/sql-queries-alerts.md`      | `w.queries`, `w.alerts` |

## Auth

`Authorization: Bearer <PAT-or-OAuth-token>` against `https://<workspace-host>`. Python SDK: `WorkspaceClient()` auto-detects from env or `.databrickscfg`. See [../SKILL.md](../SKILL.md) for the full auth block (account-level base URL, OAuth M2M, notebook auto-auth in DBR 13.1+).

Result-fetching gotcha: with `EXTERNAL_LINKS` disposition, the API returns short-lived pre-signed URLs. Treat them as ephemeral. Fetch the chunks immediately rather than caching the URLs, and re-poll the statement to refresh them if a fetch fails.
