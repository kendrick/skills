# Metastore Administration -- Databricks Unity Catalog REST API

Metastore CRUD, workspace-metastore assignments, system schemas, resource quotas.

> See also: uc-grants-permissions (metastore-level grants), uc-external-locations (storage credentials for metastore)
> Raw docs: ../_docs/raw/ — for full endpoint details, read {service}-{operation}.md

## Auth

All endpoints require Bearer token. API scope: `unity-catalog`.
Base: `https://<workspace-host>/api/2.1/unity-catalog`

## Endpoint Summary

| Operation | Method | Path |
|---|---|---|
| Create metastore | POST | `/metastores` |
| List metastores | GET | `/metastores` |
| Get metastore | GET | `/metastores/{id}` |
| Update metastore | PATCH | `/metastores/{id}` |
| Delete metastore | DELETE | `/metastores/{id}` |
| Get current assignment | GET | `/current-metastore-assignment` |
| Get metastore summary | GET | `/metastore_summary` |
| Create assignment | PUT | `/workspaces/{workspace_id}/metastore` |
| Update assignment | PATCH | `/workspaces/{workspace_id}/metastore` |
| Delete assignment | DELETE | `/workspaces/{workspace_id}/metastore` |
| List system schemas | GET | `/metastores/{metastore_id}/systemschemas` |
| Enable system schema | PUT | `/metastores/{metastore_id}/systemschemas/{schema_name}` |
| Disable system schema | DELETE | `/metastores/{metastore_id}/systemschemas/{schema_name}` |
| List resource quotas | GET | `/resource-quotas/all-resource-quotas` |
| Get resource quota | GET | `/resource-quotas/{parent_securable_type}/{parent_full_name}/{quota_name}` |

## Metastore CRUD

### Create

```
POST /metastores
{"name": "my-metastore", "storage_root": "s3://my-bucket/uc", "region": "us-west-2"}
```
Required: `name` (string). Optional: `storage_root`, `region`, `external_access_enabled` (bool).
Returns: MetastoreInfo. Owner defaults to caller; set `owner: ""` for System User.
Permission: account admin or first metastore in region.

### List

```
GET /metastores?max_results=0
```
Optional: `max_results` (int32), `page_token`. Use `max_results=0` for server-default page size (recommended); omitting it returns all results unpaginated, which is deprecated. Paginate until `next_page_token` is absent. Pages may be empty yet still return a token.
Permission: admin.

### Get

```
GET /metastores/{id}
```
Required path: `id` (string). Permission: metastore admin.

### Update

```
PATCH /metastores/{id}
{"new_name": "renamed", "owner": "admins-group"}
```
Required path: `id`. Optional body: `new_name`, `owner`, `delta_sharing_scope` (INTERNAL|INTERNAL_AND_EXTERNAL), `delta_sharing_recipient_token_lifetime_in_seconds`, `delta_sharing_organization_name`, `external_access_enabled`, `privilege_model_version`, `storage_root_credential_id`.
Set `owner: ""` to transfer to System User. `storage_root` is immutable after creation -- only `storage_root_credential_id` can be changed. Permission: metastore admin.

### Delete

```
DELETE /metastores/{id}?force=true
```
Required path: `id`. Optional query: `force` (bool, default false) -- without it, delete fails if the metastore contains objects. Permission: metastore admin.

## Current Metastore Info

### Get current assignment
```
GET /current-metastore-assignment
```
No params. Returns: `metastore_id`, `workspace_id`, `default_catalog_name` (deprecated).

### Get metastore summary
```
GET /metastore_summary
```
No params. Returns full MetastoreInfo for the workspace's assigned metastore.

## Workspace Assignments

### Create assignment
```
PUT /workspaces/{workspace_id}/metastore
{"metastore_id": "<id>", "default_catalog_name": "main"}
```
Required path: `workspace_id` (int64). Required body: `metastore_id`, `default_catalog_name` (deprecated). Overwrites existing assignment. Permission: account admin.

### Update assignment
```
PATCH /workspaces/{workspace_id}/metastore
{"metastore_id": "<new-id>"}
```
Required path: `workspace_id`. Optional body: `metastore_id`, `default_catalog_name`. Changing `metastore_id` requires account admin; `default_catalog_name` requires workspace admin.

### Delete assignment
```
DELETE /workspaces/{workspace_id}/metastore?metastore_id=<id>
```
Required path: `workspace_id`. Required query: `metastore_id`. Permission: account admin.

## System Schemas (Public Preview)

### List
```
GET /metastores/{metastore_id}/systemschemas?max_results=0
```
Required path: `metastore_id`. Optional: `max_results`, `page_token`. Returns `schemas[]` with `schema` (name) and `state` (AVAILABLE|ENABLE_INITIALIZED|ENABLE_COMPLETED|DISABLE_INITIALIZED|UNAVAILABLE|MANAGED). Permission: account/metastore admin. Pages may be empty but still return `next_page_token`; keep paginating until the token is absent.

### Enable
```
PUT /metastores/{metastore_id}/systemschemas/{schema_name}
```
Required path: `metastore_id`, `schema_name`. Optional body: `catalog_name`. Permission: account/metastore admin.

### Disable
```
DELETE /metastores/{metastore_id}/systemschemas/{schema_name}
```
Required path: `metastore_id`, `schema_name`. Permission: account/metastore admin.

## Resource Quotas

### List all quotas
```
GET /resource-quotas/all-resource-quotas?max_results=100
```
Optional: `max_results` (int32), `page_token`. Paginated by default. Returns `quotas[]` with: `quota_name`, `quota_limit`, `quota_count`, `parent_securable_type`, `parent_full_name`, `last_refreshed_at`. Counts are not real-time; API does not trigger refresh.

### Get single quota
```
GET /resource-quotas/{parent_securable_type}/{parent_full_name}/{quota_name}
```
Required path: `parent_securable_type` (e.g. SCHEMA, CATALOG, METASTORE), `parent_full_name`, `quota_name` (e.g. table-quota). Returns single QuotaInfo.

## Common Errors

| Code | Cause |
|---|---|
| 401 | Invalid/expired token |
| 403 | Caller lacks required admin role |
| 404 | Metastore ID or resource not found |
| 409 | Assignment already exists (use update instead) |

## Gotchas

- `default_catalog_name` on assignments is deprecated; use Default Namespace API instead.
