# Functions & Models -- Databricks Python SDK

Registered functions (UDFs), registered models (MLflow UC), model versions, and aliases.

> See also: uc-catalog-schema-table (functions/models live in schemas), uc-grants-permissions (for access control)
> Raw docs: ../docs/raw/ — for full endpoint details, read {service}-{operation}.md

## Setup
```python
from databricks.sdk import WorkspaceClient
w = WorkspaceClient()  # uses DATABRICKS_HOST + DATABRICKS_TOKEN env vars
```

## SDK client map
| REST resource | SDK client | Key methods |
|--------------|-----------|-------------|
| Functions | `w.functions` | `list`, `create`, `get`, `update`, `delete` |
| Registered Models | `w.registered_models` | `list`, `create`, `get`, `update`, `delete`, `set_alias`, `delete_alias` |
| Model Versions | `w.model_versions` | `list`, `get`, `get_by_alias`, `update`, `delete` |

## Functions (UDFs)

**WARNING**: Functions API is experimental.

### List functions
```python
fns = w.functions.list(catalog_name="main", schema_name="default", max_results=0)
for fn in fns:
    print(fn.full_name)
```
Required: `catalog_name`, `schema_name`. Optional: `max_results` (use 0 for paginated), `include_browse`.
SDK handles pagination automatically.

### Create function
```python
from databricks.sdk.service.catalog import (
    FunctionInfo, FunctionParameterInfos, FunctionParameterInfo,
    ColumnTypeName, RoutineBody
)
fn = w.functions.create(
    function_info=FunctionInfo(
        name="add_one", catalog_name="main", schema_name="default",
        data_type=ColumnTypeName.INT, full_data_type="INT",
        input_params=FunctionParameterInfos(parameters=[
            FunctionParameterInfo(name="x", type_name=ColumnTypeName.INT,
                type_text="int", position=0, parameter_type="PARAM", parameter_mode="IN")
        ]),
        routine_body=RoutineBody.SQL, routine_definition="x + 1",
        parameter_style="S", is_deterministic=True, is_null_call=True,
        security_type="DEFINER", sql_data_access="CONTAINS_SQL", specific_name="add_one"
    )
)
```
Permissions: USE_CATALOG + USE_SCHEMA + CREATE_FUNCTION on parent schema.

### Get / Update / Delete
```python
fn = w.functions.get(name="main.default.add_one")

w.functions.update(name="main.default.add_one", owner="new_owner@example.com")

w.functions.delete(name="main.default.add_one", force=True)
```
`name` param is always three-level: `catalog.schema.function`.
Update can only change `owner`. To change logic, delete + recreate.

## Registered Models

### Create model
```python
model = w.registered_models.create(
    name="my_model", catalog_name="main", schema_name="default",
    comment="XGBoost classifier"
)
```
Permissions: USE_CATALOG + USE_SCHEMA + CREATE_MODEL (or CREATE_FUNCTION).

### List models
```python
# Scoped to schema
models = w.registered_models.list(catalog_name="main", schema_name="default")
# All models in metastore
models = w.registered_models.list()
```
If `catalog_name` given, `schema_name` required too. SDK paginates automatically.

### Get / Update / Delete
```python
model = w.registered_models.get(full_name="main.default.my_model", include_aliases=True)

w.registered_models.update(
    full_name="main.default.my_model",
    comment="Updated description",
    new_name="renamed_model",
    owner="team@example.com"
)

w.registered_models.delete(full_name="main.default.my_model")
# WARNING: deletes ALL versions too
```
Update can only change `name` (via `new_name`), `owner`, `comment`.

### Aliases
```python
alias = w.registered_models.set_alias(
    full_name="main.default.my_model", alias="champion", version_num=3
)

w.registered_models.delete_alias(
    full_name="main.default.my_model", alias="champion"
)
```

## Model Versions

No create method -- versions are created by logging models via MLflow.

### List versions
```python
versions = w.model_versions.list(full_name="main.default.my_model", max_results=100)
for v in versions:
    print(f"v{v.version}: {v.status}")
```
Response does NOT include aliases or tags. SDK paginates automatically.

### Get version
```python
v = w.model_versions.get(
    full_name="main.default.my_model", version=3, include_aliases=True
)
```

### Get version by alias
```python
v = w.model_versions.get_by_alias(
    full_name="main.default.my_model", alias="champion"
)
```

### Update / Delete version
```python
w.model_versions.update(
    full_name="main.default.my_model", version=3,
    comment="Improved accuracy to 95%"
)

w.model_versions.delete(full_name="main.default.my_model", version=3)
```
Update can only change `comment`.

## Common patterns

### Promote model version to champion
```python
w.registered_models.set_alias(
    full_name="main.default.my_model", alias="champion", version_num=5
)
```

### Find champion version
```python
v = w.model_versions.get_by_alias(
    full_name="main.default.my_model", alias="champion"
)
print(f"Champion is v{v.version}, status={v.status}")
```

### List all READY versions
```python
versions = w.model_versions.list(full_name="main.default.my_model")
ready = [v for v in versions if v.status == "READY"]
```

## Model version status values
`PENDING_REGISTRATION` -> `READY` (or `FAILED_REGISTRATION`). Only `READY` versions can be served.

## Gotchas
- Functions API is experimental; expect breaking changes
- Function update only changes `owner` -- delete + recreate to modify logic
- Model update can change `name`/`owner`/`comment` only
- Model version update can only change `comment`
- Deleting a registered model cascades to ALL its versions
- `include_aliases` defaults to False -- pass explicitly to get alias data
- List endpoints paginate automatically in the SDK; raw REST requires manual `next_page_token` handling
- Pages may return 0 results with a `next_page_token` -- not end of results until token absent
