---
name: databricks-file-management
description: Upload, download, and manage Databricks files via the modern Files API or legacy DBFS. Use when reading or writing files on Unity Catalog volumes, workspace files, or `dbfs:/` paths; creating, listing, or deleting directories; fetching file or directory metadata; or streaming large file uploads. Prefer the Files API for new work. DBFS is legacy.
---

# Databricks File Management API Skills

> Parent: [../SKILL.md](../SKILL.md) (top-level Databricks API router)

## Usage

1. Match your task to a file using Quick Lookup below
2. Read the file in `rest/` (HTTP) or `python-sdk/` (SDK)
3. **Prefer Files API for new work** — DBFS is legacy

## Quick Lookup

| Task                                          | File        |
| --------------------------------------------- | ----------- |
| Upload or download files on volumes/workspace  | `files-api` |
| Create, list, or delete directories            | `files-api` |
| Get file or directory metadata                 | `files-api` |
| Stream large file uploads (legacy)             | `dbfs-api`  |
| Read/write files on dbfs:/ paths (legacy)      | `dbfs-api`  |
| Move or rename files (legacy only)             | `dbfs-api`  |

## REST API Skills

| File                  | Scope                                           | Endpoints |
| --------------------- | ----------------------------------------------- | --------- |
| `rest/files-api.md`   | Modern Files API — volumes and workspace files  | 8         |
| `rest/dbfs-api.md`    | Legacy DBFS — streaming uploads, file ops       | 10        |

## Python SDK Skills

| File                        | Key Clients |
| --------------------------- | ----------- |
| `python-sdk/files-api.md`   | `w.files`   |
| `python-sdk/dbfs-api.md`    | `w.dbfs`    |

## Auth

`Authorization: Bearer <PAT-or-OAuth-token>` against `https://<workspace-host>`. Python SDK: `WorkspaceClient()` auto-detects from env or `.databrickscfg`. See [../SKILL.md](../SKILL.md) for the full auth block (account-level base URL, OAuth M2M, notebook auto-auth in DBR 13.1+).
