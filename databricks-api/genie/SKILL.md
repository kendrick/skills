---
name: databricks-genie
description: Genie AI data assistant APIs—spaces, conversations, query execution, feedback, and benchmark evals.
---

# Databricks Genie API Skills

> Parent: [../SKILL.md](../SKILL.md) (top-level Databricks API router)
> API status: Public Preview. Endpoints and request/response shapes can still change; verify against the current docs before relying on this for production.

## Auth

`Authorization: Bearer <PAT-or-OAuth-token>` against `https://<workspace-host>`. Python SDK: `WorkspaceClient()` auto-detects from env or `.databrickscfg`. See [../SKILL.md](../SKILL.md) for the full auth block (account-level base URL, OAuth M2M, notebook auto-auth in DBR 13.1+).

## Quick Lookup

Read the matching bucket in `rest/` (HTTP) or `python-sdk/` (SDK).

| Task                                        | Bucket                         |
| ------------------------------------------- | ---------------------------- |
| Create or manage a Genie space              | `genie-spaces-conversations` |
| Start a conversation or send messages       | `genie-spaces-conversations` |
| Execute or download query results           | `genie-spaces-conversations` |
| Send feedback on a message                  | `genie-spaces-conversations` |
| Run benchmark evaluations on a space        | `genie-evals`                |
| Check eval run status or get result details | `genie-evals`                |

## REST Buckets

| Bucket                                 | Scope                                              | Endpoints |
| ------------------------------------ | -------------------------------------------------- | --------- |
| `rest/genie-spaces-conversations.md` | Spaces, conversations, messages, queries, feedback | 17        |
| `rest/genie-evals.md`                | Benchmark evaluation runs and results              | 5         |

## Python SDK Buckets

| Bucket                                       | Key Clients |
| ------------------------------------------ | ----------- |
| `python-sdk/genie-spaces-conversations.md` | `w.genie`   |
| `python-sdk/genie-evals.md`                | `w.genie`   |
