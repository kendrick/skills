# Databricks Jobs & Workflows API Skills

| Property    | Value                                                         |
| ----------- | ------------------------------------------------------------- |
| Name        | databricks-jobs                                               |
| Description | Create, trigger, and manage jobs, runs, and policy compliance |
| Version     | 1.0                                                           |

## Usage

1. Match your task to a file using Quick Lookup below
2. Read the file in `rest/` (HTTP) or `python-sdk/` (SDK)

## Quick Lookup

| Task                                              | File             |
| ------------------------------------------------- | ---------------- |
| Create, update, or delete a job                   | `jobs-lifecycle` |
| Trigger a job run or submit a one-time run        | `jobs-lifecycle` |
| Get run status, output, or logs                   | `jobs-lifecycle` |
| Cancel, delete, or repair a run                   | `jobs-lifecycle` |
| Manage job permissions                            | `jobs-lifecycle` |
| Check or enforce job policy compliance            | `jobs-lifecycle` |

## REST API Skills

| File                        | Scope                                                  | Endpoints |
| --------------------------- | ------------------------------------------------------ | --------- |
| `rest/jobs-lifecycle.md`    | Job CRUD, runs, permissions, policy compliance         | 23        |

## Python SDK Skills

| File                              | Key Clients                              |
| --------------------------------- | ---------------------------------------- |
| `python-sdk/jobs-lifecycle.md`    | `w.jobs`, `w.policy_compliance_for_jobs` |

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
