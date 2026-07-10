# Queries & Alerts -- Databricks Python SDK

> Raw docs: ../_docs/raw/ -- for full endpoint details, read {service}-{operation}.md

> Package: databricks-sdk

## Setup

```python
from databricks.sdk import WorkspaceClient
w = WorkspaceClient()  # uses DATABRICKS_HOST + DATABRICKS_TOKEN env vars
```

## SDK Client Map

| Service | Client | Methods |
|---------|--------|---------|
| Queries | `w.queries` | `create()`, `list()`, `get()`, `update()`, `delete()` |
| Alerts | `w.alerts` | `create()`, `list()`, `get()`, `update()`, `delete()` |

---

## Queries

### Create Query

```python
from databricks.sdk.service.sql import CreateQueryRequestQuery

query = w.queries.create(
    query=CreateQueryRequestQuery(
        display_name="My Query",
        query_text="SELECT * FROM catalog.schema.table",
        warehouse_id="a7066a8ef796be84",
        parent_path="/Workspace/Users/user@acme.com",
    )
)
print(query.id)
```

**Required:** `display_name`, `query_text` (inside `query` param)
**Optional:** `warehouse_id`, `catalog`, `schema`, `description`, `tags`, `parameters`, `parent_path`, `run_as_mode`, `apply_auto_limit`, `auto_resolve_display_name`

### List Queries

```python
for q in w.queries.list(page_size=50):
    print(q.id, q.display_name)
```

Returns an iterator that handles pagination automatically. Optional: `page_size` (max 100, default 20).

### Get Query

```python
query = w.queries.get(id="<query-uuid>")
```

### Update Query

```python
from databricks.sdk.service.sql import UpdateQueryRequestQuery

updated = w.queries.update(
    id="<query-uuid>",
    query=UpdateQueryRequestQuery(
        display_name="Updated Name",
        query_text="SELECT 2",
    ),
    update_mask="display_name,query_text",
)
```

**Required:** `id`, `update_mask` (comma-separated field names)
**Gotcha:** `update_mask` must list every field being changed. Avoid `*`.

### Delete Query

```python
w.queries.delete(id="<query-uuid>")
```

Moves to trash (soft-delete). Permanently deleted after 30 days, restorable via UI only.

---

## Alerts

### Create Alert

```python
from databricks.sdk.service.sql import (
    CreateAlertRequestAlert,
    AlertCondition,
    AlertConditionOperand,
    AlertOperandColumn,
    AlertConditionThreshold,
    AlertOperandValue,
)

alert = w.alerts.create(
    alert=CreateAlertRequestAlert(
        display_name="High row count",
        query_id="<query-uuid>",
        condition=AlertCondition(
            op=AlertCondition.Operator.GREATER_THAN,
            operand=AlertConditionOperand(
                column=AlertOperandColumn(name="row_count")
            ),
            threshold=AlertConditionThreshold(
                value=AlertOperandValue(double_value=1000)
            ),
        ),
    )
)
print(alert.id, alert.state)
```

**Required:** `display_name`, `query_id`, `condition` (op, operand, threshold)
**Optional:** `custom_body`, `custom_subject`, `notify_on_ok`, `seconds_to_retrigger` (0 = fire once, no retrigger), `parent_path`, `auto_resolve_display_name`
**Condition ops:** GREATER_THAN, GREATER_THAN_OR_EQUAL, LESS_THAN, LESS_THAN_OR_EQUAL, EQUAL, NOT_EQUAL, IS_NULL
**Column name:** `operand.column.name` must be an exact column name from the query result.

### List Alerts

```python
for a in w.alerts.list(page_size=50):
    print(a.id, a.display_name, a.state)
```

### Get Alert

```python
alert = w.alerts.get(id="<alert-uuid>")
```

### Update Alert

```python
from databricks.sdk.service.sql import UpdateAlertRequestAlert

updated = w.alerts.update(
    id="<alert-uuid>",
    alert=UpdateAlertRequestAlert(
        display_name="Renamed alert",
    ),
    update_mask="display_name",
)
```

**Required:** `id`, `update_mask`
**Gotcha:** `update_mask` is required. Omitting it silently changes nothing.

### Delete Alert

```python
w.alerts.delete(id="<alert-uuid>")
```

Moves to trash. Trashed alerts stop triggering. Permanently deleted after 30 days, restorable via UI only.

---

## Common Patterns

### Create query then attach alert

```python
query = w.queries.create(
    query=CreateQueryRequestQuery(
        display_name="Monitor table size",
        query_text="SELECT count(*) AS row_count FROM my_table",
        warehouse_id="<warehouse-id>",
    )
)
alert = w.alerts.create(
    alert=CreateAlertRequestAlert(
        display_name="Table too large",
        query_id=query.id,
        condition=AlertCondition(
            op=AlertCondition.Operator.GREATER_THAN,
            operand=AlertConditionOperand(column=AlertOperandColumn(name="row_count")),
            threshold=AlertConditionThreshold(value=AlertOperandValue(double_value=1000000)),
        ),
    )
)
```

## Gotchas

- **Throttling:** Concurrent list calls (10+) may cause throttling or temporary bans.
- **SDK class imports:** Alert condition types are in `databricks.sdk.service.sql`. Check SDK version for exact class names.
