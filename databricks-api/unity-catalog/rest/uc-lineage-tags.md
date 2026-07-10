# Lineage, Tags & Metadata -- Databricks Unity Catalog REST API

External lineage relationships, entity tag assignments, external metadata objects.

> See also: uc-catalog-schema-table (objects you're tagging/tracing), uc-grants-permissions (for access control on tagged objects)
> Raw docs: ../_docs/raw/ — for full endpoint details, read {service}-{operation}.md

## Auth

All endpoints require `Authorization: Bearer <token>` header. API scope: `unity-catalog`.
Base: `https://<workspace>.cloud.databricks.com`

External Lineage and External Metadata are **Public Preview**. Entity Tag Assignments is **GA**.

## Endpoint Summary

| Op | Method | Path |
|----|--------|------|
| Create lineage | POST | `/api/2.0/lineage-tracking/external-lineage` |
| List lineage | GET | `/api/2.0/lineage-tracking/external-lineage` |
| Update lineage | PATCH | `/api/2.0/lineage-tracking/external-lineage` |
| Delete lineage | DELETE | `/api/2.0/lineage-tracking/external-lineage` |
| Create tag | POST | `/api/2.1/unity-catalog/entity-tag-assignments` |
| List tags | GET | `/api/2.1/unity-catalog/entity-tag-assignments/{entity_type}/{entity_name}/tags` |
| Get tag | GET | `/api/2.1/unity-catalog/entity-tag-assignments/{entity_type}/{entity_name}/tags/{tag_key}` |
| Update tag | PATCH | `/api/2.1/unity-catalog/entity-tag-assignments/{entity_type}/{entity_name}/tags/{tag_key}` |
| Delete tag | DELETE | `/api/2.1/unity-catalog/entity-tag-assignments/{entity_type}/{entity_name}/tags/{tag_key}` |
| Create metadata | POST | `/api/2.0/lineage-tracking/external-metadata` |
| List metadata | GET | `/api/2.0/lineage-tracking/external-metadata` |
| Get metadata | GET | `/api/2.0/lineage-tracking/external-metadata/{name}` |
| Update metadata | PATCH | `/api/2.0/lineage-tracking/external-metadata/{name}` |
| Delete metadata | DELETE | `/api/2.0/lineage-tracking/external-metadata/{name}` |

## 1. External Lineage

Relationships between Databricks objects (table, model_version, path) and external metadata objects.

### Create
```
POST /api/2.0/lineage-tracking/external-lineage
```
```json
{"source":{"table":{"name":"main.sales.transactions"}},"target":{"external_metadata":{"name":"sales_dashboard"}},"columns":[{"source":"amount","target":"revenue"}],"properties":{"refresh_frequency":"daily"}}
```
- Required: `source` (obj), `target` (obj) -- each has one of: `table`, `external_metadata`, `model_version`, `path`
- Optional: `columns` (array of {source, target}), `properties` (key-value map)
- Response 200: same body + `id` (UUID)

### List
```
GET /api/2.0/lineage-tracking/external-lineage
    ?object_info.table.name=main.sales.customers&lineage_direction=DOWNSTREAM&page_size=100&page_token=...
```
- Required: `object_info` (flattened query param -- e.g. `object_info.table.name=...`), `lineage_direction` (`UPSTREAM` | `DOWNSTREAM`)
- Optional: `page_size` (max 1000), `page_token`
- Response: `{ "external_lineage_relationships": [...], "next_page_token": "..." }`

### Update
```
PATCH /api/2.0/lineage-tracking/external-lineage?update_mask=columns,properties
```
```json
{"source":{"table":{"name":"main.sales.transactions"}},"target":{"external_metadata":{"name":"sales_dashboard"}},"columns":[{"source":"amount2","target":"revenue2"}]}
```
- Query: `update_mask` (req) -- comma-separated fields, avoid `*`
- Body: same shape as create; `source` + `target` required to identify the relationship

### Delete
```
DELETE /api/2.0/lineage-tracking/external-lineage
```
Identify relationship by source/target in query params. Response: `{}`.

## 2. Entity Tag Assignments

Tags on UC entities: catalogs, schemas, tables, columns, volumes, externallocations.

**Permissions**: own the entity OR have APPLY TAG + USE SCHEMA + USE CATALOG. Governed tags also need ASSIGN or MANAGE on the tag policy.

### Create
```
POST /api/2.1/unity-catalog/entity-tag-assignments
```
```json
{"entity_name":"main.default.customer_data","entity_type":"tables","tag_key":"Severity","tag_value":"high"}
```
- Required: `entity_name` (str), `entity_type` (str), `tag_key` (str)
- Optional: `tag_value` (str)
- Response 200: full assignment with `source_type`, `update_time`, `updated_by`
- Error 400 `RESOURCE_ALREADY_EXISTS` if tag key already assigned

### List
```
GET /api/2.1/unity-catalog/entity-tag-assignments/{entity_type}/{entity_name}/tags
    ?max_results=50&page_token=...
```
- Pagination: pages may be empty with `next_page_token` present; stop only when token absent

### Get
```
GET /api/2.1/unity-catalog/entity-tag-assignments/{entity_type}/{entity_name}/tags/{tag_key}
```

### Update
```
PATCH /api/2.1/unity-catalog/entity-tag-assignments/{entity_type}/{entity_name}/tags/{tag_key}
    ?update_mask=tag_value
```
```json
{"tag_value":"medium"}
```

### Delete
```
DELETE /api/2.1/unity-catalog/entity-tag-assignments/{entity_type}/{entity_name}/tags/{tag_key}
```
Response: `{}`.

## 3. External Metadata

Represents objects outside Databricks (Kafka topics, Tableau reports, etc.) for lineage tracking.

**Permissions**: create requires metastore admin or CREATE_EXTERNAL_METADATA privilege. BROWSE granted to all account users by default. Update requires metastore admin, owner, or MODIFY; owner transfer also needs MANAGE.

### Create
```
POST /api/2.0/lineage-tracking/external-metadata
```
```json
{"name":"security_events_stream","entity_type":"Topic","system_type":"KAFKA","description":"Security event stream","columns":["type","message","date"],"url":"https://kafka.com/12345","properties":{"topic":"prod.security.events.raw"}}
```
- Required: `name` (str), `entity_type` (str), `system_type` (enum)
- Optional: `description`, `columns` (string array), `url`, `properties` (map), `owner`
- `system_type` enum: `TABLEAU`, `POWER_BI`, `LOOKER`, `KAFKA`, `SALESFORCE`, `SNOWFLAKE`, `GOOGLE_BIGQUERY`, `MICROSOFT_FABRIC`, `CONFLUENT`, `DATABRICKS`, `OTHER`, and more
- Response 200: full object + `id`, `metastore_id`, `create_time`, `created_by`

### List
```
GET /api/2.0/lineage-tracking/external-metadata?page_size=100&page_token=...
```
Returns `{ "external_metadata": [...], "next_page_token": "..." }`. Metastore admin sees all; others see only objects they have BROWSE on.

### Get
```
GET /api/2.0/lineage-tracking/external-metadata/{name}
```
Requires metastore admin, owner, or BROWSE.

### Update
```
PATCH /api/2.0/lineage-tracking/external-metadata/{name}?update_mask=description,columns,properties
```
```json
{"entity_type":"Topic","system_type":"KAFKA","description":"Updated description","columns":["type","message","date","severity"]}
```
- Query: `update_mask` (req) -- comma-separated, avoid `*`
- Body: `entity_type` and `system_type` required even for partial updates
- Cannot update owner and other fields in the same request

### Delete
```
DELETE /api/2.0/lineage-tracking/external-metadata/{name}
```
Requires metastore admin or owner. Response: `{}`.

## Common Errors

| Code | error_code | Meaning |
|------|-----------|---------|
| 400 | RESOURCE_ALREADY_EXISTS | Duplicate tag key or metadata name |
| 401 | UNAUTHORIZED | Invalid/missing credentials |
| 403 | PERMISSION_DENIED | Insufficient privileges |
| 404 | RESOURCE_DOES_NOT_EXIST | Entity/tag/metadata not found |
| 500 | INTERNAL_SERVER_ERROR | Retry with backoff |
