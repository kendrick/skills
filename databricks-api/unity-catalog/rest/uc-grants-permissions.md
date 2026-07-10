# Grants & Permissions -- Databricks Unity Catalog REST API

Grants, privileges, ABAC policies (row filters/column masks), workspace bindings, access requests, artifact allowlists.

> See also: uc-catalog-schema-table (objects you're granting on), uc-metastore-admin (metastore-level admin)
> Raw docs: ../_docs/raw/ — for full endpoint details, read {service}-{operation}.md

## Auth

All endpoints require `Authorization: Bearer <token>` header. API scope: `unity-catalog`.
Base: `https://<workspace>.cloud.databricks.com`

## Endpoint Summary

| Op | Method | Path |
|----|--------|------|
| Get permissions | GET | `/api/2.1/unity-catalog/permissions/{securable_type}/{full_name}` |
| Get effective | GET | `/api/2.1/unity-catalog/effective-permissions/{securable_type}/{full_name}` |
| Update permissions | PATCH | `/api/2.1/unity-catalog/permissions/{securable_type}/{full_name}` |
| Create ABAC policy | POST | `/api/2.1/unity-catalog/policies` |
| List ABAC policies | GET | `/api/2.1/unity-catalog/policies/{on_securable_type}/{on_securable_fullname}` |
| Get ABAC policy | GET | `/api/2.1/unity-catalog/policies/{on_securable_type}/{on_securable_fullname}/{name}` |
| Update ABAC policy | PATCH | `/api/2.1/unity-catalog/policies/{on_securable_type}/{on_securable_fullname}/{name}` |
| Delete ABAC policy | DELETE | `/api/2.1/unity-catalog/policies/{on_securable_type}/{on_securable_fullname}/{name}` |
| Get bindings | GET | `/api/2.1/unity-catalog/bindings/{securable_type}/{securable_name}` |
| Update bindings | PATCH | `/api/2.1/unity-catalog/bindings/{securable_type}/{securable_name}` |
| Create access requests | POST | `/api/3.0/rfa/requests` |
| Get RFA destinations | GET | `/api/3.0/rfa/destinations/{securable_type}/{full_name}` |
| Update RFA destinations | PATCH | `/api/3.0/rfa/destinations` |
| Get artifact allowlist | GET | `/api/2.1/unity-catalog/artifact-allowlists/{artifact_type}` |
| Set artifact allowlist | PUT | `/api/2.1/unity-catalog/artifact-allowlists/{artifact_type}` |

## 1. Grants

### Get permissions
```
GET /api/2.1/unity-catalog/permissions/{securable_type}/{full_name}
    ?principal=user@co.com&max_results=0&page_token=...
```
- Path: `securable_type` (req str), `full_name` (req str -- e.g. `main`, `main.schema1`, `main.schema1.table1`)
- Query: `principal` (opt str -- filter to one user/group), `max_results` (opt int32 -- use 0 for paginated, min valid positive value is 150; omitting it returns unpaginated results, which is deprecated), `page_token` (opt str)
- Response: `{ "privilege_assignments": [{"principal":"...","privileges":["SELECT"]}], "next_page_token":"..." }`
- Pagination: pages may be empty with token present; stop only when `next_page_token` absent
- Permission: caller needs some level of access to the securable to read its grants

### Get effective permissions (includes inherited)
```
GET /api/2.1/unity-catalog/effective-permissions/{securable_type}/{full_name}
    ?principal=...&max_results=0&page_token=...
```
Same params. Response includes `inherited_from_name` and `inherited_from_type` per privilege. Use this endpoint (not direct `GET`) for auditing who can actually access what, since direct `GET` excludes inherited grants.

### Update permissions
```
PATCH /api/2.1/unity-catalog/permissions/{securable_type}/{full_name}
```
```json
{
  "changes": [
    {"principal": "analysts", "add": ["SELECT", "USAGE"]},
    {"principal": "writers", "add": ["MODIFY"], "remove": ["CREATE_TABLE"]}
  ]
}
```
- Body: `changes` array of objects, each with `principal` (str), `add` (opt arr), `remove` (opt arr).
- Only specify one of `principal` or `principal_id` per change object, never both.
- Response: returns the full updated `privilege_assignments` array for the securable.
- Permission: caller must be owner of securable or have grant option on the privileges being modified.
- Key privileges: `SELECT`, `MODIFY`, `USAGE`, `USE_CATALOG`, `USE_SCHEMA`, `CREATE_TABLE`, `ALL_PRIVILEGES`, `BROWSE`, `EXECUTE`, `READ_VOLUME`, `WRITE_VOLUME`, `CREATE_SCHEMA`, `CREATE_MODEL`, `CREATE_FUNCTION`, `MANAGE`, `MANAGE_ALLOWLIST`

## 2. ABAC Policies

Row filter and column mask policies on securables. `policy_type`: `POLICY_TYPE_ROW_FILTER` | `POLICY_TYPE_COLUMN_MASK`. `for_securable_type` only supports `TABLE`. `on_securable_type` supports `CATALOG`, `SCHEMA`, `TABLE`.

### Create
```
POST /api/2.1/unity-catalog/policies
```
```json
{"name":"mask_ssn","policy_type":"POLICY_TYPE_COLUMN_MASK","on_securable_type":"SCHEMA",
 "on_securable_fullname":"main.hr","for_securable_type":"TABLE",
 "to_principals":["analysts"],"column_mask":{"function_name":"main.hr.mask_fn","on_column":"ssn_col"},
 "match_columns":[{"condition":"column_name = 'ssn'","alias":"ssn_col"}]}
```
Required: `name`, `policy_type`, `on_securable_type`, `on_securable_fullname`, `for_securable_type`, `to_principals`, plus `row_filter` or `column_mask`.
Optional: `comment`, `except_principals`, `when_condition`, `match_columns`.
`column_mask.function_name` must accept the masked column's type as its first argument and return that same type. `row_filter.function_name` must return a boolean.

### List
```
GET /api/2.1/unity-catalog/policies/{on_securable_type}/{on_securable_fullname}
    ?include_inherited=true&max_results=0&page_token=...
```

### Get / Update / Delete
- GET/PATCH/DELETE `.../policies/{on_securable_type}/{on_securable_fullname}/{name}`
- Update supports `update_mask` query param for partial updates.

## 3. Workspace Bindings

Bind catalogs/credentials/external locations to specific workspaces. Caller must be metastore admin or owner.

### Get bindings (preferred)
```
GET /api/2.1/unity-catalog/bindings/{securable_type}/{securable_name}
    ?max_results=0&page_token=...
```
`securable_type`: `catalog`, `storage_credential`, `credential`, `external_location`.
Response: `{"bindings":[{"workspace_id":123,"binding_type":"BINDING_TYPE_READ_WRITE"}]}`

### Update bindings
```
PATCH /api/2.1/unity-catalog/bindings/{securable_type}/{securable_name}
```
```json
{"add":[{"workspace_id":123,"binding_type":"BINDING_TYPE_READ_WRITE"}],"remove":[{"workspace_id":456}]}
```
`binding_type`: `BINDING_TYPE_READ_WRITE` (default) | `BINDING_TYPE_READ_ONLY`. Adding existing binding with different type updates it.

> Legacy catalog-only endpoints (`/workspace-bindings/catalogs/{name}`) are deprecated.

## 4. Request for Access (Public Preview)

### Create access requests (batch)
```
POST /api/3.0/rfa/requests
```
```json
{"requests":[{"behalf_of":{"id":"12345","principal_type":"USER_PRINCIPAL"},
  "comment":"Need SELECT on sales","securable_permissions":[
    {"securable":{"full_name":"main.sales","type":"SCHEMA"},"permissions":["USE_SCHEMA"]}]}]}
```
Max 30 requests/call, 30 securables per principal. Principals must be unique across the call.

### Get / Update destinations
- GET `/api/3.0/rfa/destinations/{securable_type}/{full_name}` -- needs BROWSE or metastore admin
- PATCH `/api/3.0/rfa/destinations?update_mask=destinations` -- needs MANAGE or owner
  - `destination_type`: `EMAIL` | `SLACK` | `GENERIC_WEBHOOK` | `MICROSOFT_TEAMS` | `URL`
  - Max 5 emails + 5 external destinations, or 1 URL alone
  - Cannot set destinations on sub-schema objects (tables, volumes, etc.) -- they inherit

## 5. Artifact Allowlists

### Get
```
GET /api/2.1/unity-catalog/artifact-allowlists/{artifact_type}
```
`artifact_type`: `INIT_SCRIPT` | `LIBRARY_JAR` | `LIBRARY_MAVEN`. Requires metastore admin or `MANAGE_ALLOWLIST`.

### Set (full replace)
```
PUT /api/2.1/unity-catalog/artifact-allowlists/{artifact_type}
```
```json
{"artifact_matchers":[{"artifact":"com.company.*","match_type":"PREFIX_MATCH"}]}
```
Replaces the entire allowlist -- always `GET` first, append your entries, then `PUT` back. `match_type` only supports `PREFIX_MATCH`. Requires metastore admin or `MANAGE_ALLOWLIST`.

## securable_type Values (for Grants)

`catalog`, `schema`, `table`, `storage_credential`, `external_location`, `function`, `share`, `provider`, `recipient`, `clean_room`, `metastore`, `pipeline`, `volume`, `connection`, `credential`, `registered_model`

## Privilege Enum (commonly used)

`SELECT`, `MODIFY`, `USAGE`, `USE_CATALOG`, `USE_SCHEMA`, `CREATE_SCHEMA`, `CREATE_TABLE`, `CREATE_VIEW`, `CREATE_FUNCTION`, `CREATE_MODEL`, `CREATE_VOLUME`, `EXECUTE`, `READ_VOLUME`, `WRITE_VOLUME`, `BROWSE`, `MANAGE`, `ALL_PRIVILEGES`, `MANAGE_ALLOWLIST`, `APPLY_TAG`, `REFRESH`, `CREATE_CONNECTION`, `USE_CONNECTION`, `CREATE_SHARE`, `SET_SHARE_PERMISSION`

## Common Errors

| Code | Cause |
|------|-------|
| 400 | Invalid `securable_type`; `max_results` between 1-149 for grants pagination; malformed policy body |
| 403 | Insufficient privileges -- need owner, metastore admin, or the relevant grant |
| 404 | Securable not found, deleted principal, or caller lacks any visibility |
| 409 | ABAC policy name conflict on same securable |
