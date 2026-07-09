# Catalogs, Schemas & Tables -- Databricks Python SDK

CRUD operations for the three-level namespace (catalog > schema > table), plus table constraints and online tables.

> Package: `databricks-sdk` (`pip install databricks-sdk`)
> Raw docs: ../docs/raw/ — for full endpoint details, read {service}-{operation}.md

## Setup

```python
from databricks.sdk import WorkspaceClient
w = WorkspaceClient()  # uses DATABRICKS_HOST + DATABRICKS_TOKEN env vars
```

## SDK Client Map

| SDK accessor | REST resource | Key methods |
|-------------|--------------|-------------|
| `w.catalogs` | Catalogs | `create`, `list`, `get`, `update`, `delete` |
| `w.schemas` | Schemas | `create`, `list`, `get`, `update`, `delete` |
| `w.tables` | Tables | `create`, `list`, `list_summaries`, `get`, `delete`, `exists` |
| `w.table_constraints` | Table Constraints | `create`, `delete` |
| `w.online_tables` | Online Tables | `create`, `get`, `delete` |

## Catalogs

### Create

```python
cat = w.catalogs.create(name="my_catalog", comment="Production data")
```

### List (paginated)

```python
for cat in w.catalogs.list():
    print(cat.name)
```

### Get / Update / Delete

```python
cat = w.catalogs.get(name="my_catalog")
cat = w.catalogs.update(name="my_catalog", comment="Updated comment", owner="new_owner@co.com")
w.catalogs.delete(name="my_catalog", force=True)  # force=True for non-empty
```

## Schemas

### Create

```python
schema = w.schemas.create(catalog_name="my_catalog", name="my_schema", comment="Analytics")
```

### List

```python
for s in w.schemas.list(catalog_name="my_catalog"):
    print(s.full_name)
```

### Get / Update / Delete

```python
schema = w.schemas.get(full_name="my_catalog.my_schema")
schema = w.schemas.update(full_name="my_catalog.my_schema", comment="Updated")
w.schemas.delete(full_name="my_catalog.my_schema", force=True)
```

## Tables

### Create (Public Preview -- external delta only)

```python
from databricks.sdk.service.catalog import ColumnInfo

table = w.tables.create(
    catalog_name="my_catalog",
    schema_name="my_schema",
    name="my_table",
    table_type="EXTERNAL",
    data_source_format="DELTA",
    storage_location="s3://bucket/path",
    columns=[
        ColumnInfo(name="id", type_name="LONG", type_text="bigint", position=0)
    ]
)
```

### List

```python
for t in w.tables.list(catalog_name="my_catalog", schema_name="my_schema"):
    print(t.full_name, t.table_type)
```

### List Summaries (lightweight, cross-schema)

```python
for s in w.tables.list_summaries(catalog_name="my_catalog", schema_name_pattern="prod_%"):
    print(s.full_name, s.table_type)
```

### Get / Delete / Exists

```python
table = w.tables.get(full_name="my_catalog.my_schema.my_table")
w.tables.delete(full_name="my_catalog.my_schema.my_table")
result = w.tables.exists(full_name="my_catalog.my_schema.my_table")
print(result.table_exists)  # True/False
```

## Table Constraints

### Create Primary Key

```python
from databricks.sdk.service.catalog import PrimaryKeyConstraint, TableConstraint

constraint = w.table_constraints.create(
    full_name_arg="my_catalog.my_schema.my_table",
    constraint=TableConstraint(
        primary_key_constraint=PrimaryKeyConstraint(
            name="pk_id",
            child_columns=["id"]
        )
    )
)
```

### Delete Constraint

```python
w.table_constraints.delete(
    full_name="my_catalog.my_schema.my_table",
    constraint_name="pk_id",
    cascade=False
)
```

## Online Tables (Public Preview)

### Create

```python
from databricks.sdk.service.catalog import OnlineTableSpec

ot = w.online_tables.create(
    name="my_catalog.my_schema.online_table",
    spec=OnlineTableSpec(
        source_table_full_name="my_catalog.my_schema.source_table",
        primary_key_columns=["id"],
        run_triggered={}
    )
)
```

### Get / Delete

```python
ot = w.online_tables.get(name="my_catalog.my_schema.online_table")
print(ot.status.detailed_state)  # PROVISIONING, ONLINE, OFFLINE_FAILED, etc.

w.online_tables.delete(name="my_catalog.my_schema.online_table")
# WARNING: deletes all online data permanently
```

## Common Patterns

### Pagination

The SDK handles pagination automatically via iterators. Just iterate:
```python
for item in w.catalogs.list():  # auto-paginates
    pass
```

### Error Handling

```python
from databricks.sdk.errors import NotFound, PermissionDenied

try:
    w.catalogs.get(name="nonexistent")
except NotFound:
    print("Catalog not found")
except PermissionDenied:
    print("Insufficient privileges")
```

## Gotchas

- **Three-level naming:** Schema `full_name` = `catalog.schema`. Table `full_name` = `catalog.schema.table`.
- **Create Table API:** Only supports `table_type=EXTERNAL` + `data_source_format=DELTA`. Use Spark SQL for managed tables.
- **Column spec:** Must be Spark-compatible. SDK does not validate column correctness.
- **List Tables:** Does NOT return `table_constraints` or `view_dependencies`. Call `get()` for full details.
- **Online Tables:** Provisioning is async. Poll `status.detailed_state` until `ONLINE`.
- **Delete non-empty:** Use `force=True` for catalogs/schemas. Otherwise returns 409.
- **SDK iterators:** `list()` returns a generator. Wrap in `list()` if you need a concrete list.
- **Permissions cascade:** Creating external tables needs explicit EXTERNAL_USE_SCHEMA + EXTERNAL_USE_LOCATION (not inherited via ALL_PRIVILEGES).
