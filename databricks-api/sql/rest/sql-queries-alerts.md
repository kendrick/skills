# Queries & Alerts -- Databricks SQL REST API

Saved SQL queries CRUD, alert definitions CRUD.

> See also: sql-statement-execution (for executing queries), sql-warehouses (for the warehouses queries run on)

> Raw docs: ../docs/raw/ -- for full endpoint details, read {service}-{operation}.md

## Auth

All endpoints require Bearer token or Databricks PAT. API scope: `sql`.

```
Authorization: Bearer <token>
Host: <workspace>.cloud.databricks.com
```

## Endpoint Summary

| Method | Path | Purpose |
|--------|------|---------|
| POST | /api/2.0/sql/queries | Create query |
| GET | /api/2.0/sql/queries | List queries |
| GET | /api/2.0/sql/queries/{id} | Get query |
| PATCH | /api/2.0/sql/queries/{id} | Update query |
| DELETE | /api/2.0/sql/queries/{id} | Trash query |
| POST | /api/2.0/sql/alerts | Create alert |
| GET | /api/2.0/sql/alerts | List alerts |
| GET | /api/2.0/sql/alerts/{id} | Get alert |
| PATCH | /api/2.0/sql/alerts/{id} | Update alert |
| DELETE | /api/2.0/sql/alerts/{id} | Trash alert |

---

## Queries

### Create Query

`POST /api/2.0/sql/queries`

```json
{
  "query": {
    "display_name": "My Query",
    "query_text": "SELECT * FROM catalog.schema.table",
    "warehouse_id": "a7066a8ef796be84",
    "parent_path": "/Workspace/Users/user@acme.com"
  }
}
```

**Required (in `query` object):** `display_name` (string), `query_text` (string)
**Optional:** `warehouse_id`, `catalog`, `schema`, `description`, `tags` (array), `parameters` (array), `parent_path`, `run_as_mode` (OWNER|VIEWER), `apply_auto_limit` (bool)
**Top-level optional:** `auto_resolve_display_name` (bool, default true)
**Response:** Full query object with `id`, `create_time`, `lifecycle_state`, `owner_user_name`.

### List Queries

`GET /api/2.0/sql/queries?page_size=20&page_token=<token>`

**Optional params:** `page_size` (int, max 100, default 20), `page_token` (string)
**Response:** `{ "results": [...], "next_page_token": "..." }` -- paginate while `next_page_token` is present.

### Get Query

`GET /api/2.0/sql/queries/{id}`

**Required:** `id` (path, string UUID)
**Response:** Full query object. Returns 404 if not found, 403 if no permission.

### Update Query

`PATCH /api/2.0/sql/queries/{id}`

```json
{
  "query": {
    "display_name": "Updated Name",
    "query_text": "SELECT 2"
  },
  "update_mask": "display_name,query_text"
}
```

**Required:** `id` (path), `update_mask` (string -- comma-separated field names, relative to `query` object)
**Optional (in `query`):** Any query field: `display_name`, `query_text`, `description`, `warehouse_id`, `catalog`, `schema`, `tags`, `parameters`, `run_as_mode`, `apply_auto_limit`, `owner_user_name`
**Gotcha:** `update_mask` is required. List only fields you are changing. Avoid `*` wildcard.

### Delete Query

`DELETE /api/2.0/sql/queries/{id}`

**Required:** `id` (path). Moves to trash (lifecycle_state=TRASHED). Permanently deleted after 30 days. Restorable via UI. Trashed queries cannot be used for alerts.

---

## Alerts

Alerts monitor a saved query's results against a condition and trigger notifications.

### Create Alert

`POST /api/2.0/sql/alerts`

```json
{
  "alert": {
    "display_name": "High row count",
    "query_id": "dee5cca8-1c79-4b5e-a711-e7f9d241bdf6",
    "condition": {
      "op": "GREATER_THAN",
      "operand": { "column": { "name": "row_count" } },
      "threshold": { "value": { "double_value": 1000 } }
    },
    "parent_path": "/Workspace/Users/user@acme.com"
  }
}
```

**Required (in `alert`):** `display_name`, `query_id`, `condition` (with `op`, `operand.column.name`, `threshold.value`)
**Optional:** `custom_body`, `custom_subject`, `notify_on_ok` (bool), `seconds_to_retrigger` (int, 0=fire once), `parent_path`
**Top-level optional:** `auto_resolve_display_name` (bool, default true)
**Condition ops:** GREATER_THAN, GREATER_THAN_OR_EQUAL, LESS_THAN, LESS_THAN_OR_EQUAL, EQUAL, NOT_EQUAL, IS_NULL
**Threshold value types:** `double_value`, `bool_value`, `string_value`
**Response:** Full alert object with `id`, `state` (UNKNOWN|OK|TRIGGERED), `create_time`.

### List Alerts

`GET /api/2.0/sql/alerts?page_size=20&page_token=<token>`

Same pagination as queries. Returns `results` array and `next_page_token`.

### Get Alert

`GET /api/2.0/sql/alerts/{id}`

**Required:** `id` (path). Returns 404 if not found, 403 if no permission.

### Update Alert

`PATCH /api/2.0/sql/alerts/{id}`

```json
{
  "alert": {
    "display_name": "Renamed alert",
    "condition": { "op": "EQUAL", "operand": { "column": { "name": "bar" } }, "threshold": { "value": { "bool_value": true } } }
  },
  "update_mask": "display_name,condition"
}
```

**Required:** `id` (path), `update_mask` (string)
**Optional (in `alert`):** `display_name`, `condition`, `custom_body`, `custom_subject`, `notify_on_ok`, `owner_user_name`, `query_id`, `seconds_to_retrigger`

### Delete Alert

`DELETE /api/2.0/sql/alerts/{id}`

Moves to trash. Trashed alerts stop triggering. Permanently deleted after 30 days.

---

## Common Errors

| HTTP | Code | Meaning |
|------|------|---------|
| 400 | BAD_REQUEST | Invalid request body or params |
| 401 | UNAUTHENTICATED | Missing or invalid credentials |
| 403 | PERMISSION_DENIED | No access (get/update/delete) |
| 404 | NOT_FOUND | Resource does not exist |
| 500 | INTERNAL_SERVER_ERROR | Server-side failure |

## Gotchas

- **Throttling:** Calling list endpoints concurrently 10+ times may cause throttling or temporary bans.
- **update_mask required:** PATCH endpoints require `update_mask`. Omitting it or using `*` risks unintended overwrites.
- **Delete is soft-delete:** DELETE moves to trash (restorable via UI for 30 days), not permanent deletion.
- **seconds_to_retrigger=0:** Alert fires once and does not retrigger until manually reset.
- **Condition column:** The `operand.column.name` must match a column name in the query result set.
- **Query must exist for alert:** Creating an alert with a nonexistent `query_id` returns 404.
