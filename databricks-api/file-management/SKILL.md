---
name: databricks-file-management
description: File upload, download, and directory management via the modern Files API or legacy DBFS.
---

# Databricks File Management API Skills

> Parent: [../SKILL.md](../SKILL.md) (top-level Databricks API router)

## Auth

`Authorization: Bearer <PAT-or-OAuth-token>` against `https://<workspace-host>`. Python SDK: `WorkspaceClient()` auto-detects from env or `.databrickscfg`. See [../SKILL.md](../SKILL.md) for the full auth block (account-level base URL, OAuth M2M, notebook auto-auth in DBR 13.1+).

## Quick Lookup

Prefer the Files API for new work—DBFS is legacy. Read the matching bucket in `rest/` (HTTP) or `python-sdk/` (SDK).

| Task                                          | Bucket        |
| --------------------------------------------- | ----------- |
| Upload or download files on volumes/workspace  | `files-api` |
| Create, list, or delete directories            | `files-api` |
| Get file or directory metadata                 | `files-api` |
| Stream large file uploads (legacy)             | `dbfs-api`  |
| Read/write files on dbfs:/ paths (legacy)      | `dbfs-api`  |
| Move or rename files (legacy only)             | `dbfs-api`  |

## REST Buckets

| Bucket                  | Scope                                           | Endpoints |
| --------------------- | ----------------------------------------------- | --------- |
| `rest/files-api.md`   | Modern Files API — volumes and workspace files  | 8         |
| `rest/dbfs-api.md`    | Legacy DBFS — streaming uploads, file ops       | 10        |

## Python SDK Buckets

| Bucket                        | Key Clients |
| --------------------------- | ----------- |
| `python-sdk/files-api.md`   | `w.files`   |
| `python-sdk/dbfs-api.md`    | `w.dbfs`    |
