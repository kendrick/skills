# SQL Statement Execution -- Databricks SQL REST API

Execute SQL statements, poll for results, retrieve result chunks, cancel execution.

> See also: sql-warehouses (for managing the warehouses you execute against), sql-queries-alerts (for saved queries)

> Raw docs: ../_docs/raw/ -- for full endpoint details, read {service}-{operation}.md

## Auth

All endpoints require Bearer token or Databricks PAT.
Header: `Authorization: Bearer <token>`
API scope (preview): `sql`

## Endpoint Summary

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/api/2.0/sql/statements/` | Execute a SQL statement |
| GET | `/api/2.0/sql/statements/{statement_id}` | Get status, manifest, and first result chunk |
| GET | `/api/2.0/sql/statements/{statement_id}/result/chunks/{chunk_index}` | Get result chunk by index |
| POST | `/api/2.0/sql/statements/{statement_id}/cancel` | Cancel a running statement |

---

## 1. Execute Statement

`POST /api/2.0/sql/statements/`

### Request Body

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `statement` | string | **yes** | SQL statement to execute |
| `warehouse_id` | string | **yes** | SQL warehouse ID to execute against |
| `catalog` | string | opt | Default catalog |
| `schema` | string | opt | Default schema |
| `parameters` | array[obj] | opt | Query parameters `{name, value, type}` for parameterized queries |
| `disposition` | string | opt | `INLINE` (default) or `EXTERNAL_LINKS` |
| `format` | string | opt | `JSON_ARRAY` (default), `ARROW_STREAM`, or `CSV` |
| `wait_timeout` | string | opt | Max wait time (e.g. `"50s"`). `"0s"` = async immediately. Default `"10s"` |
| `on_wait_timeout` | string | opt | `CONTINUE` (default) or `CANCEL` -- what to do if wait_timeout expires |
| `byte_limit` | int64 | opt | Max bytes for first INLINE chunk (default 16 MiB, max 100 MiB) |
| `row_limit` | int64 | opt | Max rows returned (truncation) |

### Disposition Modes

**INLINE** (default): Result data embedded in JSON response as `data_array`. Best for small results (< 25 MiB).

**EXTERNAL_LINKS**: Results stored externally; response contains presigned URLs. Required for large results or `ARROW_STREAM`/`CSV` formats. Links expire in <=15 min -- do not log them.

### Minimal Example -- Synchronous INLINE

```bash
curl -X POST "${DATABRICKS_HOST}/api/2.0/sql/statements/" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "statement": "SELECT * FROM samples.nyctaxi.trips LIMIT 100",
    "warehouse_id": "a1b2c3d4e5f6",
    "wait_timeout": "30s",
    "disposition": "INLINE",
    "format": "JSON_ARRAY"
  }'
```

### Minimal Example -- Async with EXTERNAL_LINKS

```bash
curl -X POST "${DATABRICKS_HOST}/api/2.0/sql/statements/" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "statement": "SELECT * FROM big_table",
    "warehouse_id": "a1b2c3d4e5f6",
    "wait_timeout": "0s",
    "disposition": "EXTERNAL_LINKS",
    "format": "ARROW_STREAM"
  }'
```

### Response (200)

Returns a statement object with `statement_id`, `status` (`{state, error}`), `manifest` (schema + chunk info), and `result` (first chunk data or external links).

Key `status.state` values: `PENDING`, `RUNNING`, `SUCCEEDED`, `FAILED`, `CANCELED`, `CLOSED`.

**Permissions**: Requires CAN_USE on the warehouse and appropriate data permissions.

---

## 2. Get Statement Status & Results

`GET /api/2.0/sql/statements/{statement_id}`

Use to poll for completion and retrieve results. Returns the same structure as execute.

**Path params**: `statement_id` (required, string)

```bash
curl -X GET "${DATABRICKS_HOST}/api/2.0/sql/statements/${STATEMENT_ID}" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Response includes:
- `status.state` -- poll until `SUCCEEDED`, `FAILED`, `CANCELED`, or `CLOSED`
- `manifest` -- column schema (`name`, `type_name`, `type_text`), `total_chunk_count`, `total_row_count`, `truncated`
- `result` -- first chunk: `data_array` (INLINE) or `external_links` (EXTERNAL_LINKS), plus `next_chunk_index` / `next_chunk_internal_link`

---

## 3. Get Result Chunk N

`GET /api/2.0/sql/statements/{statement_id}/result/chunks/{chunk_index}`

Fetch subsequent result chunks after statement SUCCEEDED. Use `next_chunk_index` from previous response to iterate.

**Path params**: `statement_id` (required), `chunk_index` (required, int32)

```bash
curl -X GET "${DATABRICKS_HOST}/api/2.0/sql/statements/${STATEMENT_ID}/result/chunks/1" \
  -H "Authorization: Bearer ${TOKEN}"
```

Response contains `data_array` or `external_links`, `row_count`, `row_offset`, `next_chunk_index`, `next_chunk_internal_link`. Absent `next_chunk_index` means no more chunks.

---

## 4. Cancel Execution

`POST /api/2.0/sql/statements/{statement_id}/cancel`

Cancel a running or pending statement. Returns empty body on success.

**Path params**: `statement_id` (required, string)

```bash
curl -X POST "${DATABRICKS_HOST}/api/2.0/sql/statements/${STATEMENT_ID}/cancel" \
  -H "Authorization: Bearer ${TOKEN}"
```

---

## Async Polling Workflow

1. POST execute with `wait_timeout: "0s"` -- returns immediately with `PENDING` state
2. GET statement repeatedly until `status.state` is terminal
3. On `SUCCEEDED`, read `result` from response (first chunk) and iterate via `next_chunk_index`
4. Recommended polling interval: start at 1s, back off to 5-10s

## Common Errors

| HTTP | error_code | Cause |
|------|-----------|-------|
| 400 | INVALID_PARAMETER_VALUE | Bad param (missing warehouse_id, bad SQL, etc.) |
| 401 | UNAUTHENTICATED | Missing/invalid auth |
| 403 | PERMISSION_DENIED | No access to warehouse or data |
| 404 | NOT_FOUND | Invalid statement_id or expired results |
| 429 | REQUEST_LIMIT_EXCEEDED | Rate throttled -- back off and retry |
| 500 | INTERNAL_ERROR | Server-side issue |
| 503 | TEMPORARILY_UNAVAILABLE | Service unavailable / warehouse starting |

## Gotchas

- **Statement TTL**: Results are available for **~1 hour** after completion, then the statement_id becomes NOT_FOUND.
- **EXTERNAL_LINKS expiry**: Presigned URLs expire in <=15 min. Re-fetch the chunk if expired. Never log these URLs (they contain credentials).
- **INLINE size limit**: Default 16 MiB per chunk. If results exceed this, use EXTERNAL_LINKS or increase `byte_limit` (max 100 MiB).
- **ARROW_STREAM/CSV require EXTERNAL_LINKS**: Only `JSON_ARRAY` works with `INLINE` disposition.
- **wait_timeout="0s"** forces async mode. Without it, the API waits up to `wait_timeout` then either continues (poll later) or cancels depending on `on_wait_timeout`.
- **Parameterized queries**: Use `parameters` array with `{name, value, type}` objects. Reference as `:name` in SQL. Types: `STRING`, `INT`, `DECIMAL`, `DOUBLE`, `BOOLEAN`, `DATE`, `TIMESTAMP`.
- **Warehouse must be running**: If stopped, the statement may block until the warehouse starts (within wait_timeout) or fail with 503.
- **row_limit** truncates results server-side; `manifest.truncated` will be `true`.
