# SQL Warehouses — Databricks Python SDK

> Raw docs: ../_docs/raw/ — for full endpoint details, read {service}-{operation}.md
> Package: `databricks-sdk`

## Contents

- [Setup](#setup)
- [1. Warehouse CRUD](#1-warehouse-crud) — create, list, get, edit, delete
- [2. Lifecycle](#2-lifecycle) — start, stop, wait-for-ready
- [3. Permissions](#3-permissions)
- [4. Workspace Configuration](#4-workspace-configuration)
- [5. Default Warehouse Overrides (Beta)](#5-default-warehouse-overrides-beta)
- [Common Patterns](#common-patterns) — wait for ready, find running, stop idle, custom polling
- [Gotchas](#gotchas)
- [Error Handling Example](#error-handling-example)
- [Key Enums and Types](#key-enums-and-types)
- [Workspace Config Details](#workspace-config-details)

## Setup

```python
from databricks.sdk import WorkspaceClient
w = WorkspaceClient()  # uses DATABRICKS_HOST + DATABRICKS_TOKEN env vars
```

**SDK client:** `w.warehouses` — maps to the SQL Warehouses API.

Methods overview:
- CRUD: `create()`, `create_and_wait()`, `list()`, `get()`, `edit()`, `edit_and_wait()`, `delete()`
- Lifecycle: `start()`, `start_and_wait()`, `stop()`, `stop_and_wait()`
- Permissions: `get_permissions()`, `set_permissions()`, `update_permissions()`, `get_permission_levels()`
- Config: `get_workspace_warehouse_config()`, `set_workspace_warehouse_config()`
- Overrides (Beta): `create_default_warehouse_override()`, `list_default_warehouse_overrides()`, `get_default_warehouse_override()`, `update_default_warehouse_override()`, `delete_default_warehouse_override()`

---

## 1. Warehouse CRUD

### Create

```python
from databricks.sdk.service.sql import EndpointInfoWarehouseType

wh = w.warehouses.create_and_wait(
    name="My Warehouse",
    cluster_size="Small",
    max_num_clusters=2,
    auto_stop_mins=30,
    warehouse_type=EndpointInfoWarehouseType.PRO,
    enable_serverless_compute=True,
)
print(wh.id)
```
`create()` returns a waiter; `create_and_wait()` blocks until RUNNING. Key params: `name` (required, str, unique, <100 chars), `cluster_size` (required, str: "2X-Small"|"X-Small"|"Small"|"Medium"|"Large"|"X-Large"|"2X-Large"|"3X-Large"|"4X-Large"|"5X-Large"), `auto_stop_mins` (int, default 120, 0=disabled, min 10), `min_num_clusters` (int, default 1, max min(max,30)), `max_num_clusters` (int, max 40), `enable_photon` (bool, default True), `warehouse_type` (EndpointInfoWarehouseType: CLASSIC|PRO), `enable_serverless_compute` (bool, requires PRO), `tags` (EndpointTags), `channel` (Channel), `spot_instance_policy` (SpotInstancePolicy: COST_OPTIMIZED|RELIABILITY_OPTIMIZED).

### List

```python
for wh in w.warehouses.list():
    print(wh.id, wh.name, wh.state)
```
Returns iterator over `EndpointInfo` objects. Handles pagination automatically.
Key attributes per warehouse: `id`, `name`, `state` (State enum), `cluster_size`, `warehouse_type`, `num_clusters`, `health`, `creator_name`, `jdbc_url`, `odbc_params`.

### Get

```python
wh = w.warehouses.get(id="abc123")
print(wh.state, wh.health, wh.jdbc_url)
```
States: STARTING, RUNNING, STOPPING, STOPPED, DELETING, DELETED. Access via `wh.state` (State enum) or `wh.state.value` (string).
Health: `wh.health.status` (HEALTHY|DEGRADED|FAILED), `wh.health.summary`, `wh.health.details`.

### Edit

```python
w.warehouses.edit_and_wait(
    id="abc123",
    cluster_size="Medium",
    auto_stop_mins=60,
)
```
Incremental -- omitted fields keep current values. `edit()` returns waiter; `edit_and_wait()` blocks until RUNNING. Accepts same params as `create()` plus required `id`.

### Delete

```python
w.warehouses.delete(id="abc123")
```
Warehouse transitions through DELETING -> DELETED. No return value.

---

## 2. Lifecycle

### Start / Stop

```python
w.warehouses.start_and_wait(id="abc123")  # blocks until RUNNING
w.warehouses.stop_and_wait(id="abc123")   # blocks until STOPPED
```
Non-blocking versions: `start()` / `stop()` return waiter objects.

```python
waiter = w.warehouses.start(id="abc123")
wh = waiter.result(timeout=datetime.timedelta(minutes=15))
```

---

## 3. Permissions

```python
from databricks.sdk.service.iam import PermissionLevel

# Get
perms = w.warehouses.get_permissions(warehouse_id="abc123")

# Update (additive)
w.warehouses.update_permissions(
    warehouse_id="abc123",
    access_control_list=[{
        "user_name": "user@example.com",
        "permission_level": PermissionLevel.CAN_USE,
    }],
)

# Set (replace all)
w.warehouses.set_permissions(
    warehouse_id="abc123",
    access_control_list=[{
        "group_name": "analysts",
        "permission_level": PermissionLevel.CAN_USE,
    }],
)

# Get available levels
levels = w.warehouses.get_permission_levels(warehouse_id="abc123")
```
Levels: CAN_MANAGE, IS_OWNER, CAN_USE, CAN_MONITOR, CAN_VIEW.

- `set_permissions()` -- replaces all direct permissions (PUT). Omitting list removes all.
- `update_permissions()` -- adds/updates without affecting unmentioned entries (PATCH).
- Each ACL entry targets exactly one of: `user_name`, `group_name`, or `service_principal_name`.

Response `access_control_list` entries include `all_permissions` with `inherited` flag and `inherited_from_object` list.

---

## 4. Workspace Configuration

```python
# Get
config = w.warehouses.get_workspace_warehouse_config()
print(config.security_policy, config.sql_configuration_parameters)

# Set
from databricks.sdk.service.sql import (
    SetWorkspaceWarehouseConfigRequest,
    EndpointConfPair,
    RepeatedEndpointConfPairs,
)
w.warehouses.set_workspace_warehouse_config(
    security_policy="DATA_ACCESS_CONTROL",
    sql_configuration_parameters=RepeatedEndpointConfPairs(
        configuration_pairs=[EndpointConfPair(key="spark.sql.shuffle.partitions", value="10")]
    ),
)
```

---

## 5. Default Warehouse Overrides (Beta)

```python
# Create override for current user
override = w.warehouses.create_default_warehouse_override(
    default_warehouse_override_id="me",
    type="CUSTOM",
    warehouse_id="abc123",
)

# List all (admin only)
for o in w.warehouses.list_default_warehouse_overrides():
    print(o.default_warehouse_override_id, o.type, o.warehouse_id)

# Get
o = w.warehouses.get_default_warehouse_override(name="default-warehouse-overrides/me")

# Update
w.warehouses.update_default_warehouse_override(
    name="default-warehouse-overrides/me",
    update_mask="type,warehouse_id",
    type="LAST_SELECTED",
)

# Delete (reverts to workspace default)
w.warehouses.delete_default_warehouse_override(name="default-warehouse-overrides/me")
```
Override types: `LAST_SELECTED` (uses last warehouse the user selected in UI) or `CUSTOM` (requires explicit `warehouse_id`). Use `"me"` for current user or numeric user ID string.

`update_default_warehouse_override()` requires `update_mask` (comma-separated field names or `"*"`). Pass `allow_missing=True` to upsert. List is admin-only and returns paginated results automatically.

---

## Common Patterns

### Wait for warehouse to be ready

```python
import datetime
waiter = w.warehouses.start(id="abc123")
wh = waiter.result(timeout=datetime.timedelta(minutes=20))
assert wh.state.value == "RUNNING"
```

### Create serverless warehouse and run query

```python
wh = w.warehouses.create_and_wait(
    name="Serverless WH",
    cluster_size="Small",
    warehouse_type=EndpointInfoWarehouseType.PRO,
    enable_serverless_compute=True,
)
# Then use w.statement_execution.execute_statement(warehouse_id=wh.id, statement="SELECT 1")
```

### Find running warehouses

```python
running = [wh for wh in w.warehouses.list() if wh.state.value == "RUNNING"]
```

### Stop all idle warehouses

```python
from databricks.sdk.service.sql import State
for wh in w.warehouses.list():
    if wh.state == State.RUNNING and wh.num_active_sessions == 0:
        w.warehouses.stop(id=wh.id)
        print(f"Stopping {wh.name}")
```

### Poll with custom timeout

```python
import datetime
waiter = w.warehouses.create(
    name="Analytics WH", cluster_size="Medium", warehouse_type=EndpointInfoWarehouseType.PRO
)
try:
    wh = waiter.result(timeout=datetime.timedelta(minutes=30))
except TimeoutError:
    print("Warehouse creation timed out")
```

### Grant CAN_USE to a group and a service principal

```python
from databricks.sdk.service.iam import PermissionLevel
w.warehouses.update_permissions(
    warehouse_id="abc123",
    access_control_list=[
        {"group_name": "data-analysts", "permission_level": PermissionLevel.CAN_USE},
        {"service_principal_name": "my-sp-app-id", "permission_level": PermissionLevel.CAN_MONITOR},
    ],
)
```

---

## Gotchas

- **`create_and_wait` / `edit_and_wait`** block until RUNNING. Use `create()` / `edit()` for async.
- **Edit is incremental** -- omitted fields keep existing values; this is not idempotent.
- **Serverless requires PRO** -- set `warehouse_type=EndpointInfoWarehouseType.PRO` AND `enable_serverless_compute=True`.
- **auto_stop_mins** must be 0 (disabled) or >= 10.
- **max_num_clusters** max is 40; **min_num_clusters** max is min(max_num_clusters, 30).
- **set_permissions replaces all** direct permissions; **update_permissions** is additive.
- **Default warehouse overrides are Beta** -- API may change.
- **Workspace config deprecated fields** -- use `sql_configuration_parameters` with `configuration_pairs`, not `config_param` or `global_param`.
- **Warehouse name** must be unique within the workspace and under 100 characters.
- **Tags** -- max 45 custom tags per warehouse. Applied to underlying cloud resources.
- **Workspace config set_workspace_warehouse_config** is a full replacement (idempotent), unlike warehouse edit which is incremental.
- **Error handling** -- SDK raises `databricks.sdk.errors.NotFound` (404), `databricks.sdk.errors.PermissionDenied` (403), `databricks.sdk.errors.BadRequest` (400), etc.
- **Pagination** -- `list()` and `list_default_warehouse_overrides()` handle pagination automatically via iterators. No need to manage `page_token` manually.
- **Permission inheritance** -- `get_permissions()` returns entries with `inherited=True` and `inherited_from_object` for permissions inherited from root object.
- **Warehouse types** -- use `EndpointInfoWarehouseType.CLASSIC` or `EndpointInfoWarehouseType.PRO` enum values.
- **Security policy** values for workspace config: `"NONE"`, `"DATA_ACCESS_CONTROL"`, `"PASSTHROUGH"`.

## Error Handling Example

```python
from databricks.sdk.errors import NotFound, PermissionDenied, BadRequest

try:
    wh = w.warehouses.get(id="nonexistent")
except NotFound:
    print("Warehouse not found")
except PermissionDenied:
    print("No access to this warehouse")

try:
    w.warehouses.create_and_wait(name="Bad WH", cluster_size="Small", auto_stop_mins=5)
except BadRequest as e:
    print(f"Invalid config: {e}")  # auto_stop_mins must be 0 or >= 10
```

## Key Enums and Types

```python
from databricks.sdk.service.sql import (
    EndpointInfoWarehouseType,  # CLASSIC, PRO
    State,                       # STARTING, RUNNING, STOPPING, STOPPED, DELETING, DELETED
    SpotInstancePolicy,          # COST_OPTIMIZED, RELIABILITY_OPTIMIZED
    Status,                      # HEALTHY, DEGRADED, FAILED (for health)
    EndpointConfPair,            # key-value config pair
    RepeatedEndpointConfPairs,   # wrapper for configuration_pairs list
    EndpointTags,                # wrapper for custom_tags list
    EndpointTagPair,             # key-value tag pair
)
from databricks.sdk.service.iam import PermissionLevel  # CAN_MANAGE, IS_OWNER, CAN_USE, CAN_MONITOR, CAN_VIEW
```

## Workspace Config Details

```python
from databricks.sdk.service.sql import (
    RepeatedEndpointConfPairs,
    EndpointConfPair,
    WarehouseTypePair,
    EndpointInfoWarehouseType,
)

# Set SQL config params and restrict to PRO warehouses only
w.warehouses.set_workspace_warehouse_config(
    security_policy="DATA_ACCESS_CONTROL",
    sql_configuration_parameters=RepeatedEndpointConfPairs(
        configuration_pairs=[
            EndpointConfPair(key="spark.sql.shuffle.partitions", value="10"),
            EndpointConfPair(key="spark.sql.adaptive.enabled", value="true"),
        ]
    ),
    data_access_config=[
        EndpointConfPair(key="spark.hadoop.fs.s3a.access.key", value="AKIA..."),
    ],
    enabled_warehouse_types=[
        WarehouseTypePair(warehouse_type=EndpointInfoWarehouseType.PRO, enabled=True),
        WarehouseTypePair(warehouse_type=EndpointInfoWarehouseType.CLASSIC, enabled=False),
    ],
)
```
Note: `set_workspace_warehouse_config` is a full replacement -- all fields not provided may be reset. Read config first with `get_workspace_warehouse_config()` if you need to preserve existing settings.

The `data_access_config` field is for external Hive metastore Spark configurations. Serialized JSON size must be <= 512K. GCP users should set `google_service_account` for Cloud Storage access.
