# Catalogs, Schemas & Tables -- Databricks Unity Catalog REST API

CRUD operations for the three-level namespace (catalog > schema > table), plus table constraints and online tables.

> See also: `uc-grants-permissions` (access control), `uc-external-locations` (external tables)
> Raw docs: ../_docs/raw/ — for full endpoint details, read {service}-{operation}.md

## Auth

```
Authorization: Bearer <token>
Base URL: https://<workspace>.cloud.databricks.com
```

## Endpoint Summary

| Method | Path | Purpose |
|--------|------|---------|
| POST | /api/2.1/unity-catalog/catalogs | Create catalog |
| GET | /api/2.1/unity-catalog/catalogs | List catalogs |
| GET | /api/2.1/unity-catalog/catalogs/{name} | Get catalog |
| PATCH | /api/2.1/unity-catalog/catalogs/{name} | Update catalog |
| DELETE | /api/2.1/unity-catalog/catalogs/{name} | Delete catalog |
| POST | /api/2.1/unity-catalog/schemas | Create schema |
| GET | /api/2.1/unity-catalog/schemas | List schemas |
| GET | /api/2.1/unity-catalog/schemas/{full_name} | Get schema |
| PATCH | /api/2.1/unity-catalog/schemas/{full_name} | Update schema |
| DELETE | /api/2.1/unity-catalog/schemas/{full_name} | Delete schema |
| POST | /api/2.1/unity-catalog/tables | Create table (preview) |
| GET | /api/2.1/unity-catalog/tables | List tables |
| GET | /api/2.1/unity-catalog/table-summaries | List table summaries |
| GET | /api/2.1/unity-catalog/tables/{full_name} | Get table |
| DELETE | /api/2.1/unity-catalog/tables/{full_name} | Delete table |
| GET | /api/2.1/unity-catalog/tables/{full_name}/exists | Check table exists |
| POST | /api/2.1/unity-catalog/constraints | Create constraint |
| DELETE | /api/2.1/unity-catalog/constraints/{full_name} | Delete constraint |
| POST | /api/2.0/online-tables | Create online table (preview) |
| GET | /api/2.0/online-tables/{name} | Get online table |
| DELETE | /api/2.0/online-tables/{name} | Delete online table |

## Catalogs

### Create Catalog

```
POST /api/2.1/unity-catalog/catalogs
{"name": "my_catalog", "comment": "Production data"}
```
- **Required:** `name` (string)
- **Optional:** `comment`, `storage_root`, `properties` (object), `connection_name`, `provider_name`, `share_name`, `custom_max_retention_hours` (Public Preview, int64), `managed_encryption_settings` (object, CMK control)
- **Permission:** Metastore admin or CREATE_CATALOG privilege
- **Returns:** Catalog object with `name`, `catalog_type`, `owner`, `metastore_id`, `created_at`

### List Catalogs

```
GET /api/2.1/unity-catalog/catalogs?max_results=0
```
- **Optional:** `max_results` (int32, <=1000; use 0 for server-default pagination), `page_token`, `include_browse` (bool)
- **Permission:** Returns catalogs caller owns or has USE_CATALOG on; metastore admin sees all
- **Pagination:** Keep reading while `next_page_token` present. Pages may be empty.

### Get / Update / Delete Catalog

- **GET** `.../{name}` -- requires USE_CATALOG or owner or metastore admin
- **PATCH** `.../{name}` -- body: `comment`, `owner`, `properties`, `isolation_mode`, `custom_max_retention_hours` (Public Preview, int64), `managed_encryption_settings` (object, CMK control). Requires owner or metastore admin
- **DELETE** `.../{name}` -- query: `force` (bool) to delete non-empty. Requires owner or metastore admin

## Schemas

### Create Schema

```
POST /api/2.1/unity-catalog/schemas
{"catalog_name": "my_catalog", "name": "my_schema", "comment": "Analytics schema"}
```
- **Required:** `catalog_name` (string), `name` (string)
- **Optional:** `comment`, `storage_root`, `properties`, `custom_max_retention_hours` (Public Preview, int64)
- **Permission:** Metastore admin or CREATE_SCHEMA on parent catalog

### List Schemas

```
GET /api/2.1/unity-catalog/schemas?catalog_name=my_catalog&max_results=0
```
- **Required:** `catalog_name`
- **Optional:** `max_results` (<=1000, use 0), `page_token`, `include_browse`

### Get / Update / Delete Schema

- Path uses `full_name` = `catalog_name.schema_name`
- **GET** `.../{full_name}` -- requires USE_SCHEMA or owner or metastore admin
- **PATCH** `.../{full_name}` -- body: `comment`, `owner`, `properties`, `name` (rename), `custom_max_retention_hours` (Public Preview, int64)
- **DELETE** `.../{full_name}?force=true` -- `force` (bool) deletes non-empty schema

## Tables

### Create Table (Public Preview)

```
POST /api/2.1/unity-catalog/tables
{
  "catalog_name": "my_catalog",
  "schema_name": "my_schema",
  "name": "my_table",
  "table_type": "EXTERNAL",
  "data_source_format": "DELTA",
  "storage_location": "s3://bucket/path",
  "columns": [
    {"name": "id", "type_name": "LONG", "type_text": "bigint", "position": 0}
  ]
}
```
- **Required:** `catalog_name`, `schema_name`, `name`, `table_type` (EXTERNAL only via API), `data_source_format` (DELTA only via API), `storage_location`, `columns`
- **Permission:** USE_CATALOG + CREATE_TABLE + USE_SCHEMA + CREATE_EXTERNAL_TABLE on external location; also EXTERNAL_USE_SCHEMA + EXTERNAL_USE_LOCATION (must be explicitly granted)
- **Note:** Column spec must be Spark-compatible. API does not validate column correctness.

### List Tables

```
GET /api/2.1/unity-catalog/tables?catalog_name=my_catalog&schema_name=my_schema&max_results=0
```
- **Required:** `catalog_name`, `schema_name`
- **Optional:** `max_results` (<=50), `page_token`, `omit_columns`, `omit_properties`, `include_browse`
- **Note:** `table_constraints` and `view_dependencies` are NOT returned by list.

### List Table Summaries

```
GET /api/2.1/unity-catalog/table-summaries?catalog_name=my_catalog
```
- **Optional:** `schema_name_pattern`, `table_name_pattern` (SQL LIKE with % and _), `max_results` (<=10000)
- Returns lightweight objects: `full_name`, `table_type` only.

### Get / Delete / Exists

- **GET** `.../tables/{full_name}` -- `full_name` = `catalog.schema.table`. Optional: `include_delta_metadata`
- **DELETE** `.../tables/{full_name}` -- owner of table (with USE_CATALOG + USE_SCHEMA) or parent owner
- **GET** `.../tables/{full_name}/exists` -- returns `{"table_exists": true|false}`

## Table Constraints

### Create Constraint

```
POST /api/2.1/unity-catalog/constraints
{
  "full_name_arg": "catalog.schema.table",
  "constraint": {
    "primary_key_constraint": {
      "name": "pk_id",
      "child_columns": ["id"]
    }
  }
}
```
- **Required:** `full_name_arg` (string), `constraint` (one of: `primary_key_constraint`, `foreign_key_constraint`, `named_table_constraint`)
- **Permission:** USE_CATALOG + USE_SCHEMA + table owner. For FK: also owner of referenced parent table.

### Delete Constraint

```
DELETE /api/2.1/unity-catalog/constraints/{full_name}?constraint_name=pk_id&cascade=false
```
- **Required:** `constraint_name` (string), `cascade` (bool, default false)

## Online Tables (Public Preview)

### Create Online Table

```
POST /api/2.0/online-tables
{
  "name": "catalog.schema.online_table",
  "spec": {
    "source_table_full_name": "catalog.schema.source_table",
    "primary_key_columns": ["id"],
    "run_triggered": {}
  }
}
```
- **Optional spec fields:** `run_continuously` (object) or `run_triggered` (object), `timeseries_key`, `perform_full_copy` (bool)
- **Note:** Uses `/api/2.0/` (not 2.1). `pipeline_id` is server-generated.

### Get / Delete Online Table

- **GET** `/api/2.0/online-tables/{name}` -- returns spec + `status.detailed_state` + `table_serving_url`
- **DELETE** `/api/2.0/online-tables/{name}` -- WARNING: deletes all data permanently

## Common Errors

| Code | Meaning |
|------|---------|
| 400 | Invalid params (e.g., bad `max_results`, missing required field) |
| 403 | Insufficient privileges (missing USE_CATALOG, CREATE_SCHEMA, etc.) |
| 404 | Resource not found (wrong name or full_name) |
| 409 | Already exists (duplicate name) or non-empty container (delete without force) |

## Gotchas

- **Pagination:** Always use `max_results=0` for paginated calls. Unpaginated calls are deprecated. Pages can be empty -- only stop when `next_page_token` is absent.
- **Three-level naming:** Schemas use `catalog.schema`, tables use `catalog.schema.table` as `full_name`.
- **Create Table API:** Only supports EXTERNAL + DELTA. Use Spark/SQL for managed tables.
- **List Tables:** Does NOT return `table_constraints` or `view_dependencies`. Use Get Table for those.
- **Online Tables:** Use API version 2.0, not 2.1. Provisioning is async -- poll `status.detailed_state`.
- **Delete cascade:** Catalogs and schemas require `force=true` to delete when non-empty. Table constraint delete uses `cascade` param.
- **storage_root vs storage_location:** Set `storage_root` on create; response includes computed `storage_location`.
- **CMK on catalogs (Public Preview):** `managed_encryption_settings` is accepted on `catalogs.create` and `catalogs.update` and returned by all four catalog ops (create/get/list/update). Shape: `customer_managed_key_id` on AWS/GCP, `azure_encryption_settings` (with `azure_cmk_access_connector_id`, `azure_cmk_managed_identity_id`, `azure_tenant_id`) plus `azure_key_vault_key_id` on Azure.
- **Custom retention (Public Preview):** Catalogs and schemas can set `custom_max_retention_hours` (int64) to override the metastore default. Returned by get/list and accepted on create and update.
