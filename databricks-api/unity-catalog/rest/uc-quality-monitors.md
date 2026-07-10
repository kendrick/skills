# Quality Monitors -- Databricks Unity Catalog REST API

Table quality monitors -- create, configure, refresh, and monitor data quality metrics on Unity Catalog tables.

> **Deprecation notice:** This API (`/api/2.1/unity-catalog/tables/{table_name}/monitor`) is deprecated. Use the Data Quality Monitors API (`/api/data-quality/v1/monitors`) for new implementations.

> See also: `uc-catalog-schema-table` (monitors attach to tables), `uc-grants-permissions` (for access control)
> Raw docs: ../_docs/raw/ — for full endpoint details, read {service}-{operation}.md

## Auth

```
Authorization: Bearer <token>
```

Scope: `unity-catalog`

## Endpoint summary

| Operation | Method | Path |
|---|---|---|
| Create monitor | `POST` | `/api/2.1/unity-catalog/tables/{table_name}/monitor` |
| Get monitor | `GET` | `/api/2.1/unity-catalog/tables/{table_name}/monitor` |
| Update monitor | `PUT` | `/api/2.1/unity-catalog/tables/{table_name}/monitor` |
| Delete monitor | `DELETE` | `/api/2.1/unity-catalog/tables/{table_name}/monitor` |
| List refreshes | `GET` | `/api/2.1/unity-catalog/tables/{table_name}/monitor/refreshes` |
| Run refresh | `POST` | `/api/2.1/unity-catalog/tables/{table_name}/monitor/refreshes` |
| Get refresh | `GET` | `/api/2.1/unity-catalog/tables/{table_name}/monitor/refreshes/{refresh_id}` |

Path param `table_name`: three-level UC name `catalog.schema.table_name` (case-insensitive, no spaces).

---

## Monitor CRUD

### Create monitor

```
POST /api/2.1/unity-catalog/tables/{table_name}/monitor
```

A table can have at most one monitor attached -- create fails with `409` if one already exists.

**Required fields:**
- `assets_dir` (string) -- absolute path for monitoring asset storage
- `output_schema_name` (string) -- two-level `catalog.schema` for output tables

**Exactly one monitor type must be set:**
- `snapshot` (object) -- `{}` empty object for snapshot monitoring
- `time_series` (object) -- requires `granularities` (array of string) and `timestamp_col` (string). Granularities: `"5 minutes"`, `"30 minutes"`, `"1 hour"`, `"1 day"`, `"<n> week(s)"`, `"1 month"`, `"1 year"`
- `inference_log` (object) -- requires `granularities`, `timestamp_col`, `model_id_col`, `prediction_col`, `problem_type` (`PROBLEM_TYPE_CLASSIFICATION` | `PROBLEM_TYPE_REGRESSION`). Optional: `label_col`, `prediction_proba_col`

**Optional fields:** `baseline_table_name`, `custom_metrics[]` (type: `CUSTOM_METRIC_TYPE_AGGREGATE` for raw columns, `CUSTOM_METRIC_TYPE_DERIVED` for metrics depending on aggregates, `CUSTOM_METRIC_TYPE_DRIFT` for baseline-vs-input or consecutive-window comparisons), `notifications.on_failure.email_addresses[]`, `schedule` (requires `quartz_cron_expression` + `timezone_id`), `slicing_exprs[]` (high-cardinality columns capped at the top 100 unique values by frequency), `skip_builtin_dashboard` (bool), `warehouse_id`

```json
{
  "assets_dir": "/Workspace/Users/me/monitoring",
  "output_schema_name": "main.monitoring",
  "time_series": {
    "granularities": ["1 day"],
    "timestamp_col": "ts"
  }
}
```

**Response (200):** Returns full monitor object including `status` (`MONITOR_STATUS_ACTIVE` | `MONITOR_STATUS_PENDING` | `MONITOR_STATUS_DELETE_PENDING` | `MONITOR_STATUS_ERROR` | `MONITOR_STATUS_FAILED`), `dashboard_id`, `profile_metrics_table_name`, `drift_metrics_table_name`, `monitor_version`.

**Permissions:** One of: (1) owner of parent catalog + USE_SCHEMA + SELECT on table, (2) USE_CATALOG + owner of parent schema + SELECT, (3) USE_CATALOG + USE_SCHEMA + owner of table.

### Get monitor

```
GET /api/2.1/unity-catalog/tables/{table_name}/monitor
```

No request body. Returns the full monitor object.

**Permissions:** Same as List refreshes (USE_CATALOG + USE_SCHEMA + SELECT, or schema/catalog ownership).

### Update monitor

```
PUT /api/2.1/unity-catalog/tables/{table_name}/monitor
```

**Required:** `output_schema_name`

**Updatable fields:** `baseline_table_name`, `custom_metrics`, `notifications`, `schedule`, `slicing_exprs`, `snapshot`, `time_series`, `inference_log`, `dashboard_id`

**Ignored on update:** `assets_dir`, `latest_monitor_failure_msg`, `monitor_version`, `status`, `table_name`

```json
{
  "output_schema_name": "main.monitoring",
  "slicing_exprs": ["region", "score > 0.5"],
  "schedule": {
    "quartz_cron_expression": "0 0 8 * * ?",
    "timezone_id": "UTC"
  }
}
```

**Permissions:** Same ownership as create, PLUS must be original creator and call from the workspace where monitor was created.

### Delete monitor

```
DELETE /api/2.1/unity-catalog/tables/{table_name}/monitor
```

No request body. Returns 200 on success.

**Permissions:** Same ownership requirements as update. Must call from originating workspace.

---

## Monitor refreshes

### List refreshes

```
GET /api/2.1/unity-catalog/tables/{table_name}/monitor/refreshes
```

Returns up to 25 most recent refreshes. Each refresh object: `refresh_id` (int64), `state` (`PENDING` | `RUNNING` | `SUCCESS` | `FAILED` | `CANCELED`), `trigger` (`SCHEDULE` | `MANUAL`), `start_time_ms`, `end_time_ms`, `message`.

### Run refresh

```
POST /api/2.1/unity-catalog/tables/{table_name}/monitor/refreshes
```

No request body. Queues a metric refresh in the background. Returns a single refresh object with `refresh_id` for polling.

### Get refresh

```
GET /api/2.1/unity-catalog/tables/{table_name}/monitor/refreshes/{refresh_id}
```

Path params: `table_name` (string), `refresh_id` (int64). Returns single refresh object.

---

## Common errors

| Code | Cause |
|---|---|
| 403 | Missing USE_CATALOG, USE_SCHEMA, SELECT, or not table owner |
| 404 | Table or monitor does not exist |
| 409 | Monitor already exists on table (create) |

## Gotchas

- **Exactly one type required on create.** Must set exactly one of `snapshot`, `time_series`, or `inference_log`. Cannot change type after creation.
