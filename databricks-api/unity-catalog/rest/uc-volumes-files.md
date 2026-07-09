# Volumes & Files -- Databricks Unity Catalog REST API

Managed and external volume CRUD within Unity Catalog schemas.

> See also: uc-catalog-schema-table (volumes live inside schemas), uc-external-locations (required for external volumes)
> Raw docs: ../docs/raw/ — for full endpoint details, read {service}-{operation}.md

## Auth

All requests require `Authorization: Bearer <token>` header. API scope: `unity-catalog`.

```
BASE = https://<workspace>.cloud.databricks.com
PREFIX = /api/2.1/unity-catalog/volumes
```

## Endpoint Summary

| Op | Method | Path | Notes |
|----|--------|------|-------|
| Create | POST | `/api/2.1/unity-catalog/volumes` | Body params |
| List | GET | `/api/2.1/unity-catalog/volumes` | Query params `catalog_name` + `schema_name` |
| Get | GET | `/api/2.1/unity-catalog/volumes/{full_name}` | Three-level name in path |
| Update | PATCH | `/api/2.1/unity-catalog/volumes/{full_name}` | Rename, change owner/comment |
| Delete | DELETE | `/api/2.1/unity-catalog/volumes/{full_name}` | No request body |

---

## Create Volume

**POST** `/api/2.1/unity-catalog/volumes`

Required fields: `catalog_name` (str), `schema_name` (str), `name` (str), `volume_type` (str: `MANAGED` | `EXTERNAL`).
Optional: `storage_location` (str -- required if EXTERNAL), `comment` (str, 1-65536 chars).

```json
POST /api/2.1/unity-catalog/volumes
{
  "catalog_name": "prod",
  "schema_name": "raw",
  "name": "landing_files",
  "volume_type": "MANAGED"
}
```

**External volume** -- also supply `storage_location`:
```json
{
  "catalog_name": "prod",
  "schema_name": "raw",
  "name": "ext_data",
  "volume_type": "EXTERNAL",
  "storage_location": "s3://my-bucket/volumes/ext_data"
}
```

**Response 200:** Returns volume object with `volume_id`, `full_name`, `storage_location`, `owner`, timestamps.

**Permissions:**
- Caller needs USE_CATALOG on parent catalog + USE_SCHEMA on parent schema + CREATE VOLUME on schema (or be metastore admin / catalog+schema owner).
- External volumes additionally require CREATE EXTERNAL VOLUME on the external location.
- Storage location must not overlap with other tables, volumes, catalogs, or schemas.

---

## List Volumes

**GET** `/api/2.1/unity-catalog/volumes?catalog_name=prod&schema_name=raw`

Required query params: `catalog_name` (str), `schema_name` (str).
Optional: `max_results` (int, <= 10000, default 10000), `page_token` (str), `include_browse` (bool).

**Response 200:** `{ "volumes": [...], "next_page_token": "..." }`

**Pagination:** API may return zero results with a `next_page_token` -- keep paging until `next_page_token` is absent.

**Permissions:** Returns only volumes the caller owns or has READ VOLUME on (plus USE_CATALOG/USE_SCHEMA). Metastore admin sees all.

---

## Get Volume

**GET** `/api/2.1/unity-catalog/volumes/{catalog.schema.volume}`

Path param `name` (str, required): three-level fully qualified name.
Optional query: `include_browse` (bool).

**Response 200:** Full volume object.

**Permissions:** Metastore admin, volume owner, or READ VOLUME + USE_CATALOG + USE_SCHEMA.

---

## Update Volume

**PATCH** `/api/2.1/unity-catalog/volumes/{catalog.schema.volume}`

Path param `name` (str, required): current three-level name.
Optional body fields: `new_name` (str), `owner` (str), `comment` (str).

```json
PATCH /api/2.1/unity-catalog/volumes/prod.raw.landing_files
{
  "new_name": "landing_files_v2",
  "comment": "Renamed volume"
}
```

**Response 200:** Updated volume object.

**Permissions:** Must be volume owner or metastore admin. Transferring ownership requires being metastore admin or current owner.

---

## Delete Volume

**DELETE** `/api/2.1/unity-catalog/volumes/{catalog.schema.volume}`

Path param `name` (str, required): three-level fully qualified name.

**Response 200:** Empty body.

**Permissions:** Metastore admin or volume owner (+ USE_CATALOG + USE_SCHEMA for non-admins).

---

## Common Errors

| Code | Cause |
|------|-------|
| 403 | Missing USE_CATALOG, USE_SCHEMA, CREATE VOLUME, or READ VOLUME privilege |
| 404 | Volume, schema, or catalog does not exist |
| 409 | Storage location overlaps with existing volume/table (create external) |
| 400 | `volume_type` missing or invalid; `storage_location` required for EXTERNAL |

## Gotchas

- `name` in path params is always the **three-level** name (`catalog.schema.volume`), not just the volume name.
- Managed volumes have their storage location auto-assigned; you cannot specify `storage_location` for MANAGED type.
- External volume `storage_location` must not nest under or contain other UC object locations.
- List pagination can return empty pages with a `next_page_token` -- always loop until token is absent.
- Deleting a managed volume deletes its underlying data; deleting an external volume only removes the UC metadata.
