---
name: databricks-sql
description: SQL APIs—warehouses, statement execution, saved queries, and alerts.
---

# Databricks SQL API Skills

> Parent: [../SKILL.md](../SKILL.md) (top-level Databricks API router)

## Auth

`Authorization: Bearer <PAT-or-OAuth-token>` against `https://<workspace-host>`. Python SDK: `WorkspaceClient()` auto-detects from env or `.databrickscfg`. See [../SKILL.md](../SKILL.md) for the full auth block (account-level base URL, OAuth M2M, notebook auto-auth in DBR 13.1+).

Result-fetching gotcha: with `EXTERNAL_LINKS` disposition, the API returns short-lived pre-signed URLs. Treat them as ephemeral. Fetch the chunks immediately rather than caching the URLs, and re-poll the statement to refresh them if a fetch fails.

## Quick Lookup

Read the matching bucket in `rest/` (HTTP) or `python-sdk/` (SDK).

| Task                                              | Bucket                      |
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

## REST Buckets

| Bucket                              | Scope                                                     | Endpoints |
| --------------------------------- | --------------------------------------------------------- | --------- |
| `rest/sql-warehouses.md`          | Warehouse CRUD, lifecycle, permissions, config, overrides | 18        |
| `rest/sql-statement-execution.md` | Execute SQL, poll results, get chunks, cancel             | 4         |
| `rest/sql-queries-alerts.md`      | Saved queries and alert definitions                       | 10        |

## Python SDK Buckets

| Bucket                                    | Key Clients             |
| --------------------------------------- | ----------------------- |
| `python-sdk/sql-warehouses.md`          | `w.warehouses`          |
| `python-sdk/sql-statement-execution.md` | `w.statement_execution` |
| `python-sdk/sql-queries-alerts.md`      | `w.queries`, `w.alerts` |
