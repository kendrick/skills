# Volumes & Files -- Databricks Python SDK

Managed and external volume CRUD within Unity Catalog schemas.

> See also: uc-catalog-schema-table (volumes live inside schemas), uc-external-locations (required for external volumes)
> Raw docs: ../docs/raw/ — for full endpoint details, read {service}-{operation}.md

## Setup

```python
from databricks.sdk import WorkspaceClient
from databricks.sdk.service.catalog import VolumeType

w = WorkspaceClient()  # uses DATABRICKS_HOST + DATABRICKS_TOKEN env vars
```

## SDK Client Map

| Operation | Method |
|-----------|--------|
| Create | `w.volumes.create(...)` |
| List | `w.volumes.list(...)` |
| Get | `w.volumes.read(full_name)` |
| Update | `w.volumes.update(full_name, ...)` |
| Delete | `w.volumes.delete(full_name)` |

---

## Create Volume

```python
# Managed volume
vol = w.volumes.create(
    catalog_name="prod",
    schema_name="raw",
    name="landing_files",
    volume_type=VolumeType.MANAGED,
)
print(vol.volume_id, vol.storage_location)

# External volume
ext_vol = w.volumes.create(
    catalog_name="prod",
    schema_name="raw",
    name="ext_data",
    volume_type=VolumeType.EXTERNAL,
    storage_location="s3://my-bucket/volumes/ext_data",
)
```

**Required:** `catalog_name` (str), `schema_name` (str), `name` (str), `volume_type` (VolumeType).
**Optional:** `storage_location` (str -- required when EXTERNAL), `comment` (str).

**Permissions:** USE_CATALOG + USE_SCHEMA + CREATE VOLUME on schema. External volumes also need CREATE EXTERNAL VOLUME on the external location.

---

## List Volumes

```python
for v in w.volumes.list(catalog_name="prod", schema_name="raw"):
    print(v.full_name, v.volume_type)
```

**Required:** `catalog_name` (str), `schema_name` (str).
**Optional:** `max_results` (int), `include_browse` (bool).

The SDK handles pagination automatically -- the iterator yields all results across pages.

**Permissions:** Returns only volumes caller owns or has READ VOLUME on (+ USE_CATALOG/USE_SCHEMA).

---

## Get Volume

```python
vol = w.volumes.read("prod.raw.landing_files")
print(vol.volume_type, vol.storage_location, vol.owner)
```

**Required:** `name` (str) -- three-level fully qualified name.
**Optional:** `include_browse` (bool).

---

## Update Volume

```python
updated = w.volumes.update(
    "prod.raw.landing_files",
    new_name="landing_files_v2",
    comment="Renamed volume",
)
```

**Required:** `name` (str) -- current three-level name.
**Optional:** `new_name` (str), `owner` (str), `comment` (str).

**Permissions:** Must be volume owner or metastore admin.

---

## Delete Volume

```python
w.volumes.delete("prod.raw.landing_files")
```

**Required:** `name` (str) -- three-level fully qualified name.

**Permissions:** Metastore admin or volume owner (+ USE_CATALOG + USE_SCHEMA).

---

## Common Patterns

```python
# List all volumes across all schemas in a catalog
for schema in w.schemas.list(catalog_name="prod"):
    for vol in w.volumes.list(catalog_name="prod", schema_name=schema.name):
        print(vol.full_name)

# Check if volume exists before creating
try:
    w.volumes.read("prod.raw.landing_files")
except Exception:
    w.volumes.create(
        catalog_name="prod",
        schema_name="raw",
        name="landing_files",
        volume_type=VolumeType.MANAGED,
    )

# Access files in a volume (via Files API, not volumes API)
# Path format: /Volumes/<catalog>/<schema>/<volume>/<path>
data = w.files.download("/Volumes/prod/raw/landing_files/data.csv").read()
```

---

## Gotchas

- The `name` parameter for read/update/delete is always the **three-level** name (`catalog.schema.volume`), not just the volume name.
- `VolumeType.MANAGED` vs `VolumeType.EXTERNAL` -- use the enum, not raw strings.
- Managed volumes: storage location is auto-assigned; do not supply `storage_location`.
- External volume `storage_location` must not overlap with other UC object locations.
- Deleting a managed volume deletes underlying data; deleting an external volume only removes UC metadata.
- The Volumes API manages volume metadata only. To read/write **files within** a volume, use `w.files` (Files API) with path `/Volumes/<catalog>/<schema>/<volume>/<file_path>`.
- SDK `list()` auto-paginates; the REST API may return empty pages with a `next_page_token`.
