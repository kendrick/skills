# Functions & Models -- Databricks Unity Catalog REST API

Registered functions (UDFs), registered models (MLflow UC), model versions, and aliases.

> See also: uc-catalog-schema-table (functions/models live in schemas), uc-grants-permissions (for access control)
> Raw docs: ../_docs/raw/ — for full endpoint details, read {service}-{operation}.md

## Auth
```
Authorization: Bearer <token>
Host: <workspace>.cloud.databricks.com
```

## Endpoint summary

| Op | Method | Path |
|----|--------|------|
| List functions | GET | /api/2.1/unity-catalog/functions |
| Create function | POST | /api/2.1/unity-catalog/functions |
| Get function | GET | /api/2.1/unity-catalog/functions/{name} |
| Update function | PATCH | /api/2.1/unity-catalog/functions/{name} |
| Delete function | DELETE | /api/2.1/unity-catalog/functions/{name} |
| List models | GET | /api/2.1/unity-catalog/models |
| Create model | POST | /api/2.1/unity-catalog/models |
| Get model | GET | /api/2.1/unity-catalog/models/{full_name} |
| Update model | PATCH | /api/2.1/unity-catalog/models/{full_name} |
| Delete model | DELETE | /api/2.1/unity-catalog/models/{full_name} |
| Set alias | PUT | /api/2.1/unity-catalog/models/{full_name}/aliases/{alias} |
| Delete alias | DELETE | /api/2.1/unity-catalog/models/{full_name}/aliases/{alias} |
| List versions | GET | /api/2.1/unity-catalog/models/{full_name}/versions |
| Get version | GET | /api/2.1/unity-catalog/models/{full_name}/versions/{version} |
| Get version by alias | GET | /api/2.1/unity-catalog/models/{full_name}/aliases/{alias} |
| Update version | PATCH | /api/2.1/unity-catalog/models/{full_name}/versions/{version} |
| Delete version | DELETE | /api/2.1/unity-catalog/models/{full_name}/versions/{version} |

## Functions (UDFs)

**WARNING**: Functions API is experimental and will change.

### List functions
```
GET /api/2.1/unity-catalog/functions?catalog_name=main&schema_name=default&max_results=0
```
Required query: `catalog_name` (string), `schema_name` (string). Optional: `max_results` (int, <=1000, use 0 for paginated -- unpaginated mode is deprecated), `page_token`, `include_browse` (bool).
Permissions: USE_CATALOG + USE_SCHEMA, or metastore admin. Returns only functions caller owns or has EXECUTE on.
Response: `{"functions": [...], "next_page_token": "..."}`. Paginate until `next_page_token` absent.

### Create function
```
POST /api/2.1/unity-catalog/functions
{"function_info": {"name": "add_one", "catalog_name": "main", "schema_name": "default",
  "data_type": "INT", "full_data_type": "INT", "input_params": {"parameters": [
    {"name": "x", "type_name": "INT", "type_text": "int", "position": 0, "parameter_type": "PARAM", "parameter_mode": "IN"}]},
  "routine_body": "SQL", "routine_definition": "x + 1", "parameter_style": "S",
  "is_deterministic": true, "is_null_call": true, "security_type": "DEFINER",
  "sql_data_access": "CONTAINS_SQL", "specific_name": "add_one"}}
```
Required fields: `name`, `catalog_name`, `schema_name`, `data_type`, `full_data_type`, `input_params`, `routine_body`, `routine_definition`, `parameter_style` ("S"), `is_deterministic`, `is_null_call`, `security_type` ("DEFINER"), `sql_data_access`, `specific_name`.
Optional: `comment`, `external_language`, `external_name`, `properties`, `return_params`, `routine_dependencies`, `sql_path`.
When `routine_body=EXTERNAL`: set `external_language`, `sql_data_access=NO_SQL`, no TABLE return type.
Permissions: USE_CATALOG on parent catalog + USE_SCHEMA + CREATE_FUNCTION on parent schema.

### Get function
```
GET /api/2.1/unity-catalog/functions/main.default.add_one
```
Path: `{name}` = three-level name `catalog.schema.function`. Optional query: `include_browse`.
Permissions: metastore admin, catalog owner, function owner, or USE_CATALOG + USE_SCHEMA + EXECUTE.

### Update function
```
PATCH /api/2.1/unity-catalog/functions/main.default.add_one
{"owner": "new_owner@example.com"}
```
Only `owner` can be updated -- to modify logic, delete + recreate. Caller must be metastore admin, catalog owner, schema owner (with USE_CATALOG), or function owner (with USE_CATALOG + USE_SCHEMA).

### Delete function
```
DELETE /api/2.1/unity-catalog/functions/main.default.add_one?force=true
```
Path: three-level name. Optional query: `force` (bool). Same permission hierarchy as update.

## Registered Models

### Create model
```
POST /api/2.1/unity-catalog/models
{"name": "my_model", "catalog_name": "main", "schema_name": "default", "comment": "XGBoost classifier"}
```
Required: `name`, `catalog_name`, `schema_name`. Optional: `comment`, `storage_location`.
Permissions: USE_CATALOG + USE_SCHEMA + (CREATE_MODEL or CREATE_FUNCTION) on parent schema.

### List models
```
GET /api/2.1/unity-catalog/models?catalog_name=main&schema_name=default&max_results=100
```
All query params optional. If `catalog_name` given, `schema_name` required too. Optional: `max_results` (<=100), `page_token`, `include_browse`.
Without catalog/schema filter: lists all models in metastore (default page 100); with scope, default page size is 10000.
Permissions: metastore admin sees all; others need EXECUTE or ownership + USE_CATALOG + USE_SCHEMA.

### Get model
```
GET /api/2.1/unity-catalog/models/main.default.my_model?include_aliases=true
```
Path: three-level `full_name`. Optional query: `include_aliases`, `include_browse`.
Permissions: metastore admin, or owner/EXECUTE + USE_CATALOG + USE_SCHEMA.

### Update model
```
PATCH /api/2.1/unity-catalog/models/main.default.my_model
{"comment": "Updated description", "new_name": "renamed_model", "owner": "team@example.com"}
```
Only `name` (via `new_name`), `owner`, and `comment` can be updated. Caller: metastore admin or owner + USE_CATALOG + USE_SCHEMA.

### Delete model
```
DELETE /api/2.1/unity-catalog/models/main.default.my_model
```
Deletes model AND all its versions. Permissions: metastore admin or owner + USE_CATALOG + USE_SCHEMA.

### Set alias
```
PUT /api/2.1/unity-catalog/models/main.default.my_model/aliases/champion
{"version_num": 3}
```
Required body: `version_num` (int). Permissions: metastore admin or model owner + USE_CATALOG + USE_SCHEMA.

### Delete alias
```
DELETE /api/2.1/unity-catalog/models/main.default.my_model/aliases/champion
```

## Model Versions

No create endpoint -- versions are created by logging models via MLflow.

### List versions
```
GET /api/2.1/unity-catalog/models/main.default.my_model/versions?max_results=100
```
Optional query: `max_results` (<=1000, default 100), `page_token`, `include_browse`.
Response does NOT include aliases or tags. Paginate until `next_page_token` absent.

### Get version
```
GET /api/2.1/unity-catalog/models/main.default.my_model/versions/3?include_aliases=true
```
Path: `{version}` (int). Optional query: `include_aliases`, `include_browse`.

### Get version by alias
```
GET /api/2.1/unity-catalog/models/main.default.my_model/aliases/champion?include_aliases=true
```

### Update version
```
PATCH /api/2.1/unity-catalog/models/main.default.my_model/versions/3
{"comment": "Improved accuracy to 95%"}
```
Only `comment` can be updated. Caller: metastore admin or parent model owner + USE_CATALOG + USE_SCHEMA.

### Delete version
```
DELETE /api/2.1/unity-catalog/models/main.default.my_model/versions/3
```

## Model version status values
`PENDING_REGISTRATION` -> `READY` (or `FAILED_REGISTRATION`). Only `READY` versions can be served or loaded.

## Common errors
- 403: missing USE_CATALOG, USE_SCHEMA, EXECUTE, CREATE_FUNCTION, or CREATE_MODEL privileges
- 404: object not found (check three-level name spelling)
- 409: name already exists (functions, models)

## Gotchas
- List pagination: pages may have 0 results but still return `next_page_token` -- keep reading until token absent
- `include_aliases` defaults to false on get endpoints -- pass explicitly if needed
