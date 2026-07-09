---
name: databricks-jobs
description: "Create, schedule, trigger, and monitor Databricks Jobs and Workflows. Use when defining or updating a job, submitting one-time runs, polling run status or output, repairing failed runs, cancelling a run, managing job permissions, or enforcing and checking job policy compliance. Heads up: policy compliance endpoints live on `/api/2.0/` while job lifecycle uses `/api/2.2/`. Easy 404 trap."
---

# Databricks Jobs & Workflows API Skills

> Parent: [../SKILL.md](../SKILL.md) (top-level Databricks API router)

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

`Authorization: Bearer <PAT-or-OAuth-token>` against `https://<workspace-host>`. Python SDK: `WorkspaceClient()` auto-detects from env or `.databrickscfg`. See [../SKILL.md](../SKILL.md) for the full auth block (account-level base URL, OAuth M2M, notebook auto-auth in DBR 13.1+).

API versioning gotcha: job lifecycle endpoints sit on `/api/2.2/jobs/...` but policy compliance endpoints are still on `/api/2.0/policies/...`. If you're hitting 404s on compliance calls, check the base path first.
