---
name: databricks-jobs
description: Jobs and Workflows APIs—job lifecycle, runs, repair, permissions, and policy compliance.
---

# Databricks Jobs & Workflows API Skills

> Parent: [../SKILL.md](../SKILL.md) (top-level Databricks API router)

## Auth

`Authorization: Bearer <PAT-or-OAuth-token>` against `https://<workspace-host>`. Python SDK: `WorkspaceClient()` auto-detects from env or `.databrickscfg`. See [../SKILL.md](../SKILL.md) for the full auth block (account-level base URL, OAuth M2M, notebook auto-auth in DBR 13.1+).

API versioning gotcha: job lifecycle endpoints sit on `/api/2.2/jobs/...` but policy compliance endpoints are still on `/api/2.0/policies/...`. If you're hitting 404s on compliance calls, check the base path first.

## Quick Lookup

Read the matching bucket in `rest/` (HTTP) or `python-sdk/` (SDK).

| Task                                              | Bucket             |
| ------------------------------------------------- | ---------------- |
| Create, update, or delete a job                   | `jobs-lifecycle` |
| Trigger a job run or submit a one-time run        | `jobs-lifecycle` |
| Get run status, output, or logs                   | `jobs-lifecycle` |
| Cancel, delete, or repair a run                   | `jobs-lifecycle` |
| Manage job permissions                            | `jobs-lifecycle` |
| Check or enforce job policy compliance            | `jobs-lifecycle` |

## REST Buckets

| Bucket                        | Scope                                                  | Endpoints |
| --------------------------- | ------------------------------------------------------ | --------- |
| `rest/jobs-lifecycle.md`    | Job CRUD, runs, permissions, policy compliance         | 23        |

## Python SDK Buckets

| Bucket                              | Key Clients                              |
| --------------------------------- | ---------------------------------------- |
| `python-sdk/jobs-lifecycle.md`    | `w.jobs`, `w.policy_compliance_for_jobs` |
