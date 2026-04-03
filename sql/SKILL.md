# Databricks SQL API Skills

| Property    | Value                                                          |
| ----------- | -------------------------------------------------------------- |
| Name        | databricks-sql                                                 |
| Description | SQL warehouses, statement execution, saved queries, and alerts |
| Version     | 1.0                                                            |

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

### REST

```
Authorization: Bearer <PAT-or-OAuth-token>
Base URL: https://<workspace-host>
```

### Python SDK

```python
from databricks.sdk import WorkspaceClient
w = WorkspaceClient()  # auto-detects from env or .databrickscfg
```
