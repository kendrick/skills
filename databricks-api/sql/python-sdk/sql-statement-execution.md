# SQL Statement Execution -- Databricks Python SDK

> Raw docs: ../_docs/raw/ -- for full endpoint details, read {service}-{operation}.md

> Package: `databricks-sdk` (`pip install databricks-sdk`)

## Setup

```python
from databricks.sdk import WorkspaceClient

w = WorkspaceClient()  # uses DATABRICKS_HOST + DATABRICKS_TOKEN env vars
# or: WorkspaceClient(host="https://xxx.cloud.databricks.com", token="dapi...")
```

## SDK Client Map

All operations via `w.statement_execution`:

| Method | Purpose |
|--------|---------|
| `w.statement_execution.execute_statement(...)` | Execute SQL, optionally wait for results |
| `w.statement_execution.get_statement(statement_id)` | Get status, manifest, first result chunk |
| `w.statement_execution.get_statement_result_chunk_n(statement_id, chunk_index)` | Get Nth result chunk |
| `w.statement_execution.cancel_execution(statement_id)` | Cancel running statement |

---

## 1. Execute Statement

### Synchronous -- INLINE (small results)

```python
from databricks.sdk.service.sql import Disposition, Format, StatementParameterListItem

resp = w.statement_execution.execute_statement(
    statement="SELECT * FROM samples.nyctaxi.trips LIMIT 100",
    warehouse_id="a1b2c3d4e5f6",
    catalog="samples",
    schema="nyctaxi",
    disposition=Disposition.INLINE,
    format=Format.JSON_ARRAY,
    wait_timeout="30s",
)
# resp.status.state == StatementState.SUCCEEDED
# resp.manifest.schema.columns -> column metadata
# resp.result.data_array -> list[list[str | None]]
```

### Async -- EXTERNAL_LINKS (large results)

```python
resp = w.statement_execution.execute_statement(
    statement="SELECT * FROM big_table",
    warehouse_id="a1b2c3d4e5f6",
    disposition=Disposition.EXTERNAL_LINKS,
    format=Format.ARROW_STREAM,
    wait_timeout="0s",  # return immediately
)
statement_id = resp.statement_id
# Poll for completion (see pattern below)
```

External link presigned URLs expire in <=15 min -- re-fetch the chunk via `get_statement_result_chunk_n` if expired. Never log these URLs.

### Key Parameters

| Param | Type | Req? | Notes |
|-------|------|------|-------|
| `statement` | str | **yes** | SQL to execute |
| `warehouse_id` | str | **yes** | Target warehouse |
| `catalog` | str | opt | Default catalog |
| `schema` | str | opt | Default schema |
| `parameters` | list[StatementParameterListItem] | opt | Parameterized query values |
| `disposition` | Disposition | opt | `INLINE` (default) or `EXTERNAL_LINKS`. `ARROW_STREAM`/`CSV` formats require `EXTERNAL_LINKS` -- only `JSON_ARRAY` works with `INLINE` |
| `format` | Format | opt | `JSON_ARRAY`, `ARROW_STREAM`, `CSV` |
| `wait_timeout` | str | opt | e.g. `"30s"`, `"0s"` for fully async. Default `"10s"` waits synchronously up to that duration |
| `on_wait_timeout` | TimeoutAction | opt | `CONTINUE` (default, keeps statement running for later polling) or `CANCEL` (aborts it) |
| `byte_limit` | int | opt | Max bytes for INLINE first chunk. Default 16 MiB, max 100 MiB; exceeding it silently chunks the response |
| `row_limit` | int | opt | Truncate result rows; check `resp.manifest.truncated` |

**Warehouse must be running:** Statements against stopped warehouses may hang or fail with `TEMPORARILY_UNAVAILABLE`.

---

## 2. Get Statement (Poll for Status)

```python
resp = w.statement_execution.get_statement(statement_id=statement_id)
# resp.status.state -> PENDING, RUNNING, SUCCEEDED, FAILED, CANCELED, CLOSED
```

---

## 3. Get Result Chunk N

```python
chunk = w.statement_execution.get_statement_result_chunk_n(
    statement_id=statement_id,
    chunk_index=1,
)
# chunk.data_array or chunk.external_links
# chunk.next_chunk_index (None if last chunk)
```

---

## 4. Cancel Execution

```python
w.statement_execution.cancel_execution(statement_id=statement_id)
```

---

## Common Patterns

### Synchronous execute with result iteration

```python
resp = w.statement_execution.execute_statement(
    statement="SELECT * FROM my_table",
    warehouse_id=wh_id,
    disposition=Disposition.INLINE,
    wait_timeout="50s",
)
assert resp.status.state.value == "SUCCEEDED"

rows = resp.result.data_array or []
next_idx = resp.result.next_chunk_index
while next_idx is not None:
    chunk = w.statement_execution.get_statement_result_chunk_n(
        statement_id=resp.statement_id, chunk_index=next_idx
    )
    rows.extend(chunk.data_array or [])
    next_idx = chunk.next_chunk_index
```

### Async polling pattern

```python
import time
from databricks.sdk.service.sql import StatementState

resp = w.statement_execution.execute_statement(
    statement="SELECT * FROM huge_table",
    warehouse_id=wh_id,
    wait_timeout="0s",
    disposition=Disposition.EXTERNAL_LINKS,
    format=Format.ARROW_STREAM,
)

while True:
    resp = w.statement_execution.get_statement(resp.statement_id)
    state = resp.status.state
    if state == StatementState.SUCCEEDED:
        break
    if state in (StatementState.FAILED, StatementState.CANCELED, StatementState.CLOSED):
        raise RuntimeError(f"Statement {state.value}: {resp.status.error}")
    time.sleep(2)

# Process external links from resp.result.external_links
for link_info in resp.result.external_links:
    url = link_info.external_link  # presigned URL, download with requests/httpx
```

### Parameterized queries

```python
resp = w.statement_execution.execute_statement(
    statement="SELECT * FROM trips WHERE fare_amount > :min_fare",
    warehouse_id=wh_id,
    parameters=[
        StatementParameterListItem(name="min_fare", value="25.0", type="DECIMAL")
    ],
)
```

---

## Gotchas

- **Statement results TTL**: ~1 hour after completion. After that, `get_statement` returns NOT_FOUND.
- **Enums**: Import from `databricks.sdk.service.sql` -- `Disposition`, `Format`, `StatementState`, `TimeoutAction`, `StatementParameterListItem`.
- **Error handling**: Failed statements have `resp.status.error` with `error_code` and `message` fields.
