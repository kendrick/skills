# SQL Warehouses — Databricks SQL REST API

SQL warehouse CRUD, start/stop lifecycle, permissions, workspace configuration, default warehouse overrides.

> See also: sql-statement-execution (for running queries), sql-queries-alerts (for saved queries/alerts)
> Raw docs: ../_docs/raw/ — for full endpoint details, read {service}-{operation}.md

## Contents

- [Auth](#auth)
- [Endpoint Summary](#endpoint-summary)
- [1. Warehouse CRUD](#1-warehouse-crud) — create, list, get, edit, delete
- [2. Lifecycle](#2-lifecycle) — start, stop, polling
- [3. Permissions](#3-permissions)
- [4. Workspace Configuration](#4-workspace-configuration)
- [5. Default Warehouse Overrides (Beta)](#5-default-warehouse-overrides-beta)
- [Common Errors](#common-errors)
- [Gotchas](#gotchas)
- [Quick Reference: Create + Start + Query Flow](#quick-reference-create--start--query-flow)

## Auth

All endpoints require `Authorization: Bearer <token>` header. API scope: `sql`.
Base URL: `https://<workspace>.cloud.databricks.com`

```bash
curl -X GET "https://${DATABRICKS_HOST}/api/2.0/sql/warehouses" \
  -H "Authorization: Bearer ${DATABRICKS_TOKEN}"
```

## Endpoint Summary

| Method | Path | Purpose |
|--------|------|---------|
| POST | /api/2.0/sql/warehouses | Create warehouse |
| GET | /api/2.0/sql/warehouses | List warehouses |
| GET | /api/2.0/sql/warehouses/{id} | Get warehouse |
| POST | /api/2.0/sql/warehouses/{id}/edit | Edit warehouse |
| DELETE | /api/2.0/sql/warehouses/{id} | Delete warehouse |
| POST | /api/2.0/sql/warehouses/{id}/start | Start warehouse |
| POST | /api/2.0/sql/warehouses/{id}/stop | Stop warehouse |
| GET | /api/2.0/permissions/warehouses/{warehouse_id} | Get permissions |
| PUT | /api/2.0/permissions/warehouses/{warehouse_id} | Set permissions (replace) |
| PATCH | /api/2.0/permissions/warehouses/{warehouse_id} | Update permissions (additive) |
| GET | /api/2.0/permissions/warehouses/{warehouse_id}/permissionLevels | Get permission levels |
| GET | /api/2.0/sql/config/warehouses | Get workspace warehouse config |
| PUT | /api/2.0/sql/config/warehouses | Set workspace warehouse config |
| POST | /api/warehouses/v1/default-warehouse-overrides | Create default warehouse override (Beta) |
| GET | /api/warehouses/v1/default-warehouse-overrides | List default warehouse overrides (Beta) |
| GET | /api/warehouses/v1/default-warehouse-overrides/{id} | Get default warehouse override (Beta) |
| PATCH | /api/warehouses/v1/default-warehouse-overrides/{id} | Update default warehouse override (Beta) |
| DELETE | /api/warehouses/v1/default-warehouse-overrides/{id} | Delete default warehouse override (Beta) |

---

## 1. Warehouse CRUD

### Create

```
POST /api/2.0/sql/warehouses
```
```json
{
  "name": "My Warehouse",
  "cluster_size": "Small",
  "max_num_clusters": 2,
  "auto_stop_mins": 30,
  "warehouse_type": "PRO",
  "enable_serverless_compute": true,
  "enable_photon": true
}
```
**Required:** `name`, `cluster_size`. **Optional:** `auto_stop_mins` (default 120, 0=no autostop, min 10), `min_num_clusters` (default 1), `max_num_clusters` (max 40), `warehouse_type` (CLASSIC|PRO), `enable_serverless_compute` (requires PRO), `enable_photon` (default true), `spot_instance_policy`, `tags`, `channel`.
**Response 200:** Full warehouse object with `id`, `state`, `jdbc_url`, `odbc_params`.
**cluster_size values:** 2X-Small, X-Small, Small, Medium, Large, X-Large, 2X-Large, 3X-Large, 4X-Large, 5X-Large.
**spot_instance_policy:** POLICY_UNSPECIFIED | COST_OPTIMIZED (default) | RELIABILITY_OPTIMIZED.
**channel.name:** CHANNEL_NAME_CURRENT (default) | CHANNEL_NAME_PREVIEW | CHANNEL_NAME_PREVIOUS | CHANNEL_NAME_CUSTOM.
**warehouse_type:** `TYPE_UNSPECIFIED` is not valid for create; use `CLASSIC` or `PRO`.
**min_num_clusters/max_num_clusters:** `max_num_clusters` ceiling is 40; `min_num_clusters` ceiling is `min(max_num_clusters, 30)`.
**Name constraints:** Warehouse names must be unique within the org and under 100 characters.

### List

```
GET /api/2.0/sql/warehouses?page_size=50&page_token=...
```
**Optional params:** `page_size` (int), `page_token` (string). Returns `{warehouses: [...], next_page_token}`.
Each warehouse object in the array contains: `id`, `name`, `state`, `cluster_size`, `warehouse_type`, `num_clusters`, `min_num_clusters`, `max_num_clusters`, `auto_stop_mins`, `enable_photon`, `enable_serverless_compute`, `creator_name`, `health`, `tags`, `jdbc_url`, `odbc_params`.

### Get

```
GET /api/2.0/sql/warehouses/{id}
```
**Required:** `id` (path). Returns full warehouse object including `state` (STARTING|RUNNING|STOPPING|STOPPED|DELETING|DELETED), `health` (status: HEALTHY|DEGRADED|FAILED), `jdbc_url`, `odbc_params` (hostname, path, port, protocol).
**health.failure_reason** contains `code`, `type` (SUCCESS|INTERNAL_ERROR|etc.), and `parameters` map when state is FAILED/DEGRADED.

### Edit

```
POST /api/2.0/sql/warehouses/{id}/edit
```
Note: this endpoint is POST, not the PUT/PATCH you might expect for an edit.
```json
{"cluster_size": "Medium", "auto_stop_mins": 60}
```
**Required:** `id` (path). All body fields optional -- incremental edit; unset fields retain existing values, so this is not idempotent. Same fields as Create. **Response:** `{}`.

**Full edit example (curl):**
```bash
curl -X POST "https://${DATABRICKS_HOST}/api/2.0/sql/warehouses/${WH_ID}/edit" \
  -H "Authorization: Bearer ${DATABRICKS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"cluster_size":"Medium","auto_stop_mins":60,"max_num_clusters":4}'
```

### Delete

```
DELETE /api/2.0/sql/warehouses/{id}
```
**Required:** `id` (path). **Response:** `{}`. Warehouse transitions through DELETING -> DELETED states.

**Tags format** (for create/edit):
```json
{"tags": {"custom_tags": [{"key": "env", "value": "prod"}, {"key": "team", "value": "analytics"}]}}
```
Max 45 tags per warehouse. Tags are applied to all underlying cloud resources (EC2 instances, EBS volumes, etc.).

---

## 2. Lifecycle

### Start / Stop

```
POST /api/2.0/sql/warehouses/{id}/start
POST /api/2.0/sql/warehouses/{id}/stop
```
**Required:** `id` (path). No request body. **Response:** `{}`.

Start is async -- returns 200 immediately. Poll GET `/api/2.0/sql/warehouses/{id}` to check state transitions:
- Start: STOPPED -> STARTING -> RUNNING
- Stop: RUNNING -> STOPPING -> STOPPED

```bash
curl -X POST "https://${DATABRICKS_HOST}/api/2.0/sql/warehouses/${WH_ID}/start" \
  -H "Authorization: Bearer ${DATABRICKS_TOKEN}"
# Then poll:
curl -X GET "https://${DATABRICKS_HOST}/api/2.0/sql/warehouses/${WH_ID}" \
  -H "Authorization: Bearer ${DATABRICKS_TOKEN}"
```

---

## 3. Permissions

Permission levels: `CAN_MANAGE`, `IS_OWNER`, `CAN_USE`, `CAN_MONITOR`, `CAN_VIEW`.

### Get Permissions

```
GET /api/2.0/permissions/warehouses/{warehouse_id}
```
Returns `{access_control_list: [{user_name, group_name, all_permissions: [{permission_level, inherited}]}]}`. Warehouses inherit permissions from the root object; inherited grants show `inherited: true` with an `inherited_from_object` array.

### Set Permissions (replace all)

```
PUT /api/2.0/permissions/warehouses/{warehouse_id}
```
```json
{"access_control_list": [{"user_name": "user@example.com", "permission_level": "CAN_USE"}]}
```
Replaces all direct permissions. Omitting the list deletes all direct permissions. Inherited permissions (from root object) are unaffected.

**Permission level meanings:**
- `CAN_MANAGE` -- full control (edit, delete, manage permissions)
- `IS_OWNER` -- ownership (typically the creator)
- `CAN_USE` -- run queries on the warehouse
- `CAN_MONITOR` -- view warehouse metrics and query history
- `CAN_VIEW` -- see warehouse exists and its configuration

### Update Permissions (additive)

```
PATCH /api/2.0/permissions/warehouses/{warehouse_id}
```
Same body as Set. Adds/updates without removing unmentioned entries. Use PATCH when granting access to additional users without affecting existing grants.

Each ACL entry targets exactly one of: `user_name`, `group_name`, or `service_principal_name`.

### Get Permission Levels

```
GET /api/2.0/permissions/warehouses/{warehouse_id}/permissionLevels
```
Returns `{permission_levels: [{permission_level, description}]}`.

**Errors (all permission endpoints):** 400 BAD_REQUEST, 401 UNAUTHORIZED, 403 PERMISSION_DENIED, 404 RESOURCE_DOES_NOT_EXIST, 500 INTERNAL_SERVER_ERROR.

---

## 4. Workspace Configuration

### Get Config

```
GET /api/2.0/sql/config/warehouses
```
Returns workspace-wide settings shared by all SQL warehouses:
- `channel` -- default DBSQL version channel for new warehouses
- `security_policy` -- NONE | DATA_ACCESS_CONTROL | PASSTHROUGH
- `sql_configuration_parameters.configuration_pairs` -- [{key, value}] SQL Spark config. Use this field, not the deprecated `config_param` or `global_param`.
- `data_access_config` -- [{key, value}] for external hive metastore (max 512K serialized)
- `enabled_warehouse_types` -- [{warehouse_type, enabled}] controls allowed types
- `google_service_account` (GCP only), `instance_profile_arn` (AWS, deprecated)

### Set Config

```
PUT /api/2.0/sql/config/warehouses
```
```json
{
  "security_policy": "DATA_ACCESS_CONTROL",
  "sql_configuration_parameters": {
    "configuration_pairs": [{"key": "spark.sql.shuffle.partitions", "value": "10"}]
  },
  "enabled_warehouse_types": [{"warehouse_type": "PRO", "enabled": true}]
}
```
Idempotent full replacement. All fields optional -- but unset fields may be cleared (unlike warehouse edit).

**Important:** Disabling a warehouse type may cause existing warehouses of that type to be automatically converted. The `data_access_config` is for external Hive metastore Spark configs (serialized size must be <= 512K).

---

## 5. Default Warehouse Overrides (Beta)

Per-user override for which warehouse is used as default. Override types: `LAST_SELECTED` or `CUSTOM` (requires `warehouse_id`). Users manage their own; admins manage any user's.

### Create

```
POST /api/warehouses/v1/default-warehouse-overrides?default_warehouse_override_id=me
```
```json
{"type": "CUSTOM", "warehouse_id": "abc123"}
```
`default_warehouse_override_id`: numeric user ID or `"me"`.

### List

```
GET /api/warehouses/v1/default-warehouse-overrides?page_size=100
```
Admin only. Returns `{default_warehouse_overrides: [...], next_page_token}`.

### Get / Update / Delete

```
GET    /api/warehouses/v1/default-warehouse-overrides/{id}
PATCH  /api/warehouses/v1/default-warehouse-overrides/{id}?update_mask=type,warehouse_id
DELETE /api/warehouses/v1/default-warehouse-overrides/{id}
```
Update requires `update_mask` query param (comma-separated fields or `*` for all). Accepts `allow_missing=true` to upsert (creates if not found, ignores mask). After delete, workspace default warehouse is used.

**Response shape** (create/get/update):
```json
{
  "default_warehouse_override_id": "12345",
  "name": "default-warehouse-overrides/12345",
  "type": "CUSTOM",
  "warehouse_id": "abc123def"
}
```

---

## Common Errors

| Code | error_code | Cause |
|------|-----------|-------|
| 400 | BAD_REQUEST / INVALID_PARAMETER_VALUE | Invalid params (e.g., cluster_size, auto_stop_mins < 10) |
| 401 | UNAUTHORIZED | Bad/missing token |
| 403 | PERMISSION_DENIED | Insufficient permissions |
| 404 | RESOURCE_DOES_NOT_EXIST | Warehouse ID not found |
| 500 | INTERNAL_SERVER_ERROR | Server error |

## Gotchas

- **Pagination** -- List warehouses and list overrides both support `page_size` + `page_token`. Check `next_page_token` in response; omitted means no more pages.

## Quick Reference: Create + Start + Query Flow

```bash
# 1. Create warehouse
WH_ID=$(curl -s -X POST "https://${DATABRICKS_HOST}/api/2.0/sql/warehouses" \
  -H "Authorization: Bearer ${DATABRICKS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"name":"Analytics","cluster_size":"Small","warehouse_type":"PRO","enable_serverless_compute":true}' \
  | jq -r '.id')

# 2. Poll until running
while [ "$(curl -s "https://${DATABRICKS_HOST}/api/2.0/sql/warehouses/${WH_ID}" \
  -H "Authorization: Bearer ${DATABRICKS_TOKEN}" | jq -r '.state')" != "RUNNING" ]; do
  sleep 10
done

# 3. Grant access
curl -X PATCH "https://${DATABRICKS_HOST}/api/2.0/permissions/warehouses/${WH_ID}" \
  -H "Authorization: Bearer ${DATABRICKS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"access_control_list":[{"group_name":"analysts","permission_level":"CAN_USE"}]}'
```
