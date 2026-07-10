---
name: databricks-model-serving
description: Model Serving APIs—endpoint lifecycle, AI Gateway, provisioned throughput, queries, and permissions.
---

# Databricks Model Serving API Skills

> Parent: [../SKILL.md](../SKILL.md) (top-level Databricks API router)

## Auth

`Authorization: Bearer <PAT-or-OAuth-token>` against `https://<workspace-host>`. Python SDK: `WorkspaceClient()` auto-detects from env or `.databrickscfg`. See [../SKILL.md](../SKILL.md) for the full auth block (account-level base URL, OAuth M2M, notebook auto-auth in DBR 13.1+).

## Quick Lookup

Read the matching bucket in `rest/` (HTTP) or `python-sdk/` (SDK).

| Task                                                    | Bucket                |
| ------------------------------------------------------- | ------------------- |
| Create, list, get, or delete a serving endpoint         | `serving-endpoints` |
| Update endpoint config, rate limits, or AI Gateway      | `serving-endpoints` |
| Create or update provisioned throughput endpoints        | `serving-endpoints` |
| Query a serving endpoint                                | `serving-endpoints` |
| Get logs, metrics, or OpenAPI schema                    | `serving-endpoints` |
| Manage serving endpoint permissions                     | `serving-endpoints` |
| Update tags or notification settings                    | `serving-endpoints` |

## REST Buckets

| Bucket                            | Scope                                                              | Endpoints |
| ------------------------------- | ------------------------------------------------------------------ | --------- |
| `rest/serving-endpoints.md`     | CRUD, config, AI Gateway, provisioned throughput, query, permissions | 20        |

## Python SDK Buckets

| Bucket                                  | Key Clients            |
| ------------------------------------- | ---------------------- |
| `python-sdk/serving-endpoints.md`     | `w.serving_endpoints`  |
