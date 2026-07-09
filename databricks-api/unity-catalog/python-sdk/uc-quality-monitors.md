# Quality Monitors -- Databricks Python SDK

Table quality monitors -- create, configure, refresh, and monitor data quality metrics on Unity Catalog tables.

> **Deprecation notice:** The `w.quality_monitors` API is deprecated. Use the Data Quality Monitors API for new implementations.

> See also: `uc-catalog-schema-table` (monitors attach to tables), `uc-grants-permissions` (for access control)
> Raw docs: ../docs/raw/ — for full endpoint details, read {service}-{operation}.md

## Setup

```python
from databricks.sdk import WorkspaceClient

w = WorkspaceClient()  # uses DATABRICKS_HOST + DATABRICKS_TOKEN env vars
```

## SDK client map

| Operation | Method |
|---|---|
| Create monitor | `w.quality_monitors.create(table_name, ...)` |
| Get monitor | `w.quality_monitors.get(table_name)` |
| Update monitor | `w.quality_monitors.update(table_name, ...)` |
| Delete monitor | `w.quality_monitors.delete(table_name)` |
| List refreshes | `w.quality_monitors.list_refreshes(table_name)` |
| Run refresh | `w.quality_monitors.run_refresh(table_name)` |
| Get refresh | `w.quality_monitors.get_refresh(table_name, refresh_id)` |

All methods take `table_name` as `"catalog.schema.table"` (three-level name).

---

## Monitor CRUD

### Create monitor (snapshot)

```python
monitor = w.quality_monitors.create(
    table_name="main.default.my_table",
    assets_dir="/Workspace/Users/me/monitoring",
    output_schema_name="main.monitoring",
    snapshot={}
)
print(monitor.status)  # MONITOR_STATUS_PENDING or MONITOR_STATUS_ACTIVE
```

### Create monitor (time series)

```python
from databricks.sdk.service.catalog import MonitorTimeSeries

monitor = w.quality_monitors.create(
    table_name="main.default.events",
    assets_dir="/Workspace/Users/me/monitoring",
    output_schema_name="main.monitoring",
    time_series=MonitorTimeSeries(
        granularities=["1 day"],
        timestamp_col="event_ts"
    )
)
```

### Create monitor (inference log)

```python
from databricks.sdk.service.catalog import MonitorInferenceLog

monitor = w.quality_monitors.create(
    table_name="main.default.predictions",
    assets_dir="/Workspace/Users/me/monitoring",
    output_schema_name="main.monitoring",
    inference_log=MonitorInferenceLog(
        granularities=["1 hour"],
        timestamp_col="ts",
        model_id_col="model_name",
        prediction_col="prediction",
        problem_type="PROBLEM_TYPE_CLASSIFICATION",
        label_col="label"  # optional
    )
)
```

### Get monitor

```python
monitor = w.quality_monitors.get(table_name="main.default.my_table")
print(monitor.drift_metrics_table_name)
print(monitor.profile_metrics_table_name)
```

### Update monitor

```python
monitor = w.quality_monitors.update(
    table_name="main.default.my_table",
    output_schema_name="main.monitoring",
    slicing_exprs=["region", "score > 0.5"],
    schedule=MonitorCronSchedule(
        quartz_cron_expression="0 0 8 * * ?",
        timezone_id="UTC"
    )
)
```

### Delete monitor

```python
w.quality_monitors.delete(table_name="main.default.my_table")
```

---

## Monitor refreshes

### Run and poll refresh

```python
import time

refresh = w.quality_monitors.run_refresh(table_name="main.default.my_table")
refresh_id = refresh.refresh_id

while True:
    status = w.quality_monitors.get_refresh(
        table_name="main.default.my_table",
        refresh_id=refresh_id
    )
    if status.state in ("SUCCESS", "FAILED", "CANCELED"):
        break
    time.sleep(30)

print(f"Refresh {status.state}: {status.message}")
```

### List refreshes

```python
refreshes = w.quality_monitors.list_refreshes(table_name="main.default.my_table")
for r in refreshes.refreshes:
    print(f"{r.refresh_id}: {r.state} ({r.trigger})")
```

---

## Common patterns

### Create with custom metrics

```python
from databricks.sdk.service.catalog import MonitorMetric

monitor = w.quality_monitors.create(
    table_name="main.default.my_table",
    assets_dir="/Workspace/Users/me/monitoring",
    output_schema_name="main.monitoring",
    snapshot={},
    custom_metrics=[
        MonitorMetric(
            name="null_rate",
            type="CUSTOM_METRIC_TYPE_AGGREGATE",
            definition="sum(CASE WHEN {{column_name}} IS NULL THEN 1 ELSE 0 END) / count(*)",
            input_columns=["col_a", "col_b"],
            output_data_type="DOUBLE"
        )
    ]
)
```

### Create with notifications

```python
from databricks.sdk.service.catalog import MonitorNotifications, MonitorDestination

monitor = w.quality_monitors.create(
    table_name="main.default.my_table",
    assets_dir="/Workspace/Users/me/monitoring",
    output_schema_name="main.monitoring",
    snapshot={},
    notifications=MonitorNotifications(
        on_failure=MonitorDestination(email_addresses=["team@example.com"])
    )
)
```

---

## Gotchas

- **One monitor per table.** Creating a second monitor on the same table raises a conflict error.
- **Exactly one type required on create.** Set exactly one of `snapshot={}`, `time_series=MonitorTimeSeries(...)`, or `inference_log=MonitorInferenceLog(...)`. Cannot change type after creation.
- **`output_schema_name` is two-level** (`"catalog.schema"`), not three-level.
- **`assets_dir` is immutable** after creation; ignored on update calls.
- **Update must come from original creator** in the same workspace where the monitor was created.
- **Refresh is async.** `run_refresh()` returns immediately with a `refresh_id`. Poll `get_refresh()` until `state` is terminal (`SUCCESS`, `FAILED`, `CANCELED`).
- **`list_refreshes()` returns max 25** most recent entries.
- **Custom metric definitions** use Jinja templates with `{{column_name}}` placeholder.
- **Slicing:** high-cardinality columns capped at top 100 unique values by frequency.
- **Permissions:** Caller needs catalog/schema USE + table ownership (or catalog/schema ownership). See REST reference for full matrix.
- **Time series granularities:** `"5 minutes"`, `"30 minutes"`, `"1 hour"`, `"1 day"`, `"<n> week(s)"`, `"1 month"`, `"1 year"`.
