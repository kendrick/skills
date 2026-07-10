---
name: databricks-unity-catalog
description: Unity Catalog governance APIs—catalogs, schemas, tables, volumes, grants, lineage, and quality monitors—via REST and the Python SDK.
---

# Databricks Unity Catalog API Skills

> Parent: [../SKILL.md](../SKILL.md) (top-level Databricks API router)
> Compressed from official docs. Verify against your workspace config and SDK version.

## Auth

`Authorization: Bearer <PAT-or-OAuth-token>` against `https://<workspace-host>`. Python SDK: `WorkspaceClient()` auto-detects from env or `.databrickscfg`. See [../SKILL.md](../SKILL.md) for the full auth block (account-level base URL, OAuth M2M, notebook auto-auth in DBR 13.1+).

UC-specific: most operations require `USE CATALOG` + `USE SCHEMA` on the parent objects. See `uc-grants-permissions` for the full grant model.

## Core Concept

All UC objects live in a three-level namespace: `catalog.schema.object`.
You must create parent objects before children (catalog → schema → table/view/volume/function).
Grants cascade: `USE CATALOG` on a catalog is required before any schema-level access.

## Quick Lookup

Read the matching bucket in `rest/` (HTTP) or `python-sdk/` (SDK). Tasks that span files (e.g. create a table AND grant access to it): read every matching file.

| Task                                           | Bucket                      |
| ---------------------------------------------- | ------------------------- |
| Create/list/update a catalog, schema, or table | `uc-catalog-schema-table` |
| Manage table constraints or online tables      | `uc-catalog-schema-table` |
| Grant/revoke access to anything                | `uc-grants-permissions`   |
| Set ABAC policies or workspace bindings        | `uc-grants-permissions`   |
| Request access to securable objects            | `uc-grants-permissions`   |
| Upload files or manage volumes                 | `uc-volumes-files`        |
| Connect to S3/ADLS/GCS (storage credentials)   | `uc-external-locations`   |
| Set up external locations                      | `uc-external-locations`   |
| Create Lakehouse Federation connections        | `uc-external-locations`   |
| Generate temporary credentials                 | `uc-external-locations`   |
| Set up a new metastore or workspace            | `uc-metastore-admin`      |
| Manage system schemas or resource quotas       | `uc-metastore-admin`      |
| Register a UDF or ML model                     | `uc-functions-models`     |
| Manage model versions and aliases              | `uc-functions-models`     |
| Track lineage or tag objects                   | `uc-lineage-tags`         |
| Register external metadata                     | `uc-lineage-tags`         |
| Create or manage data quality monitors         | `uc-quality-monitors`     |
| Run or check monitor refreshes                 | `uc-quality-monitors`     |

## REST Buckets

| Bucket                              | Scope                                                                           | Endpoints |
| --------------------------------- | ------------------------------------------------------------------------------- | --------- |
| `rest/uc-catalog-schema-table.md` | Catalogs, schemas, tables, constraints, online tables                           | 21        |
| `rest/uc-volumes-files.md`        | Volumes (managed + external)                                                    | 5         |
| `rest/uc-grants-permissions.md`   | Grants, ABAC policies, workspace bindings, access requests, artifact allowlists | 17        |
| `rest/uc-external-locations.md`   | Storage credentials, external locations, connections, temporary credentials     | 25        |
| `rest/uc-lineage-tags.md`         | External lineage, tags, external metadata                                       | 14        |
| `rest/uc-functions-models.md`     | UDFs, registered models, model versions                                         | 17        |
| `rest/uc-metastore-admin.md`      | Metastore config, workspace assignment, system schemas, quotas                  | 15        |
| `rest/uc-quality-monitors.md`     | Table quality monitors and refreshes                                            | 7         |

## Python SDK Buckets

Same domains, Python SDK-first examples. Files in `python-sdk/` with matching names.

| Bucket                                    | Key SDK Clients                                                                    |
| --------------------------------------- | ---------------------------------------------------------------------------------- |
| `python-sdk/uc-catalog-schema-table.md` | `w.catalogs`, `w.schemas`, `w.tables`, `w.table_constraints`, `w.online_tables`    |
| `python-sdk/uc-volumes-files.md`        | `w.volumes`                                                                        |
| `python-sdk/uc-grants-permissions.md`   | `w.grants`, `w.policies`, `w.workspace_bindings`, `w.rfa`, `w.artifact_allowlists` |
| `python-sdk/uc-external-locations.md`   | `w.storage_credentials`, `w.external_locations`, `w.credentials`, `w.connections`  |
| `python-sdk/uc-lineage-tags.md`         | `w.external_lineage`, `w.entity_tag_assignments`, `w.external_metadata`            |
| `python-sdk/uc-functions-models.md`     | `w.functions`, `w.registered_models`, `w.model_versions`                           |
| `python-sdk/uc-metastore-admin.md`      | `w.metastores`, `w.system_schemas`, `w.resource_quotas`                            |
| `python-sdk/uc-quality-monitors.md`     | `w.quality_monitors`                                                               |
