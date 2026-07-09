---
name: databricks-model-serving
description: Databricks Model Serving APIs for deploying, querying, and managing real-time inference endpoints for ML and foundation models. Use when creating or updating a serving endpoint, configuring rate limits or AI Gateway, setting up provisioned throughput, querying a deployed model, fetching logs/metrics/OpenAPI schema, managing endpoint permissions, or wiring up tags and notification settings.
---

# Databricks Model Serving API Skills

> Parent: [../SKILL.md](../SKILL.md) (top-level Databricks API router)

## Usage

1. Match your task to a file using Quick Lookup below
2. Read the file in `rest/` (HTTP) or `python-sdk/` (SDK)

## Quick Lookup

| Task                                                    | File                |
| ------------------------------------------------------- | ------------------- |
| Create, list, get, or delete a serving endpoint         | `serving-endpoints` |
| Update endpoint config, rate limits, or AI Gateway      | `serving-endpoints` |
| Create or update provisioned throughput endpoints        | `serving-endpoints` |
| Query a serving endpoint                                | `serving-endpoints` |
| Get logs, metrics, or OpenAPI schema                    | `serving-endpoints` |
| Manage serving endpoint permissions                     | `serving-endpoints` |
| Update tags or notification settings                    | `serving-endpoints` |

## REST API Skills

| File                            | Scope                                                              | Endpoints |
| ------------------------------- | ------------------------------------------------------------------ | --------- |
| `rest/serving-endpoints.md`     | CRUD, config, AI Gateway, provisioned throughput, query, permissions | 20        |

## Python SDK Skills

| File                                  | Key Clients            |
| ------------------------------------- | ---------------------- |
| `python-sdk/serving-endpoints.md`     | `w.serving_endpoints`  |

## Auth

`Authorization: Bearer <PAT-or-OAuth-token>` against `https://<workspace-host>`. Python SDK: `WorkspaceClient()` auto-detects from env or `.databrickscfg`. See [../SKILL.md](../SKILL.md) for the full auth block (account-level base URL, OAuth M2M, notebook auto-auth in DBR 13.1+).
