# External Locations & Credentials -- Databricks Unity Catalog REST API

Scope: External locations, storage credentials, general credentials (storage + service), connections (Lakehouse Federation), temporary path/table credentials.

> See also: uc-grants-permissions (for granting access), uc-catalog-schema-table (for external tables)
> Raw docs: ../docs/raw/ — for full endpoint details, read {service}-{operation}.md

## Auth
All endpoints: `Authorization: Bearer <token>`, base URL `https://<workspace>.cloud.databricks.com`. API scope: `unity-catalog`.

## Endpoint Summary

| Group | Method | Endpoint | Notes |
|---|---|---|---|
| Storage Credentials | POST | `/api/2.1/unity-catalog/storage-credentials` | Create |
| | GET | `/api/2.1/unity-catalog/storage-credentials` | List (paginated) |
| | GET | `/api/2.1/unity-catalog/storage-credentials/{name}` | Get |
| | PATCH | `/api/2.1/unity-catalog/storage-credentials/{name}` | Update |
| | DELETE | `/api/2.1/unity-catalog/storage-credentials/{name}` | Delete |
| | POST | `/api/2.1/unity-catalog/validate-storage-credentials` | Validate |
| External Locations | POST | `/api/2.1/unity-catalog/external-locations` | Create |
| | GET | `/api/2.1/unity-catalog/external-locations` | List (paginated) |
| | GET | `/api/2.1/unity-catalog/external-locations/{name}` | Get |
| | PATCH | `/api/2.1/unity-catalog/external-locations/{name}` | Update |
| | DELETE | `/api/2.1/unity-catalog/external-locations/{name}` | Delete |
| Credentials | POST | `/api/2.1/unity-catalog/credentials` | Create (STORAGE or SERVICE) |
| | GET | `/api/2.1/unity-catalog/credentials` | List (filter by purpose) |
| | GET | `/api/2.1/unity-catalog/credentials/{name_arg}` | Get |
| | PATCH | `/api/2.1/unity-catalog/credentials/{name_arg}` | Update |
| | DELETE | `/api/2.1/unity-catalog/credentials/{name_arg}` | Delete |
| | POST | `/api/2.1/unity-catalog/temporary-service-credentials` | Generate temp service cred |
| | POST | `/api/2.1/unity-catalog/validate-credentials` | Validate (STORAGE or SERVICE) |
| Connections | POST | `/api/2.1/unity-catalog/connections` | Create |
| | GET | `/api/2.1/unity-catalog/connections` | List (paginated) |
| | GET | `/api/2.1/unity-catalog/connections/{name}` | Get |
| | PATCH | `/api/2.1/unity-catalog/connections/{name}` | Update |
| | DELETE | `/api/2.1/unity-catalog/connections/{name}` | Delete |
| Temp Credentials | POST | `/api/2.0/unity-catalog/temporary-path-credentials` | For external locations |
| | POST | `/api/2.0/unity-catalog/temporary-table-credentials` | For table data |

---

## Storage Credentials

### Create
```
POST /api/2.1/unity-catalog/storage-credentials
{"name": "my-s3-cred", "aws_iam_role": {"role_arn": "arn:aws:iam::123456789012:role/my-role"}, "comment": "S3 access", "read_only": false, "skip_validation": false}
```
**Required:** `name` (string), plus one cloud credential object (`aws_iam_role`, Azure/GCP equivalent).
**Optional:** `comment`, `read_only`, `skip_validation` (default false).
**Permission:** Metastore admin or `CREATE_STORAGE_CREDENTIAL` on metastore.
**Response:** Returns credential info including `aws_iam_role.external_id` and `aws_iam_role.unity_catalog_iam_arn` -- add the external_id to your IAM role trust policy.

### List / Get / Update / Delete
- **List:** `GET .../storage-credentials?max_results=0` -- use `max_results=0` for paginated (recommended). Params: `page_token`, `include_unbound`.
- **Get:** `GET .../storage-credentials/{name}` -- metastore admin, owner, or any permission.
- **Update:** `PATCH .../storage-credentials/{name}` -- body can include `aws_iam_role`, `new_name`, `owner`, `comment`, `force`, `skip_validation`, `isolation_mode`, `read_only`. Owner or metastore admin (admin can only change owner/name).
- **Delete:** `DELETE .../storage-credentials/{name}?force=true` -- owner only. `force` deletes even with dependents.

### Validate
```
POST /api/2.1/unity-catalog/validate-storage-credentials
{"storage_credential_name": "my-s3-cred", "url": "s3://my-bucket/path"}
```
**Required:** Either `storage_credential_name` or cloud credential; at least one of `url` or `external_location_name`.
**Response:** `results[]` with `operation` (LIST/READ/WRITE/DELETE/PATH_EXISTS) and `result` (PASS/FAIL/SKIP).

---

## External Locations

### Create
```
POST /api/2.1/unity-catalog/external-locations
{"name": "my-ext-loc", "url": "s3://my-bucket/data/", "credential_name": "my-s3-cred"}
```
**Required:** `name`, `url`, `credential_name`.
**Optional:** `comment`, `read_only`, `skip_validation`, `fallback`, `encryption_details`, `enable_file_events`, `file_event_queue`.
**Permission:** Metastore admin or `CREATE_EXTERNAL_LOCATION` on metastore + credential.

### List / Get / Update / Delete
- **List:** `GET .../external-locations?max_results=0` -- paginated. Params: `include_browse`, `page_token`, `include_unbound`.
- **Get:** `GET .../external-locations/{name}?include_browse=true`
- **Update:** `PATCH .../external-locations/{name}` -- body: `url`, `credential_name`, `new_name`, `owner`, `comment`, `read_only`, `force`, `skip_validation`, `isolation_mode`, `fallback`, `enable_file_events`. Admin can only rename.
- **Delete:** `DELETE .../external-locations/{name}?force=true` -- owner only.

---

## General Credentials (Unified API)

The `/api/2.1/unity-catalog/credentials` endpoint manages both STORAGE and SERVICE credentials in one API. Prefer this over the legacy storage-credentials API for new work.

### Create
```
POST /api/2.1/unity-catalog/credentials
{"name": "my-service-cred", "purpose": "SERVICE", "aws_iam_role": {"role_arn": "arn:aws:iam::123456789012:role/svc-role"}, "skip_validation": false}
```
**Required:** `name`. **Optional:** `purpose` (STORAGE|SERVICE), `aws_iam_role`, `comment`, `read_only` (STORAGE only), `skip_validation`.
**Permission:** `CREATE_STORAGE_CREDENTIAL` (for STORAGE) or `CREATE_SERVICE_CREDENTIAL` (for SERVICE).

### List
`GET .../credentials?purpose=SERVICE&max_results=0` -- filter by `purpose`, paginated.

### Get / Update / Delete
- Path param is `{name_arg}` (not `{name}`).
- **Update:** `PATCH .../credentials/{name_arg}` -- `force`, `new_name`, `owner`, `aws_iam_role`, `comment`, `skip_validation`, `isolation_mode`, `read_only`.
- **Delete:** `DELETE .../credentials/{name_arg}?force=true`

### Generate Temporary Service Credential
```
POST /api/2.1/unity-catalog/temporary-service-credentials
{"credential_name": "my-service-cred"}
```
**Permission:** Metastore admin or `ACCESS` privilege on the service credential.
**Response:** Cloud-specific credentials object plus `expiration_time`. AWS returns `aws_temp_credentials` (`access_key_id`, `secret_access_key`, `session_token`); Cloudflare R2 returns `r2_temp_credentials` with the same fields. Azure/GCP return their own variants.

### Validate
```
POST /api/2.1/unity-catalog/validate-credentials
{"credential_name": "my-cred", "purpose": "SERVICE"}
```
For STORAGE purpose, also supply `url` or `external_location_name`.

---

## Connections (Lakehouse Federation)

### Create
```
POST /api/2.1/unity-catalog/connections
{"name": "my-pg-conn", "connection_type": "POSTGRESQL", "options": {"host": "pg.example.com", "port": "5432", "user": "admin", "password": "secret"}}
```
**Required:** `name`, `connection_type`, `options` (map of key-value pairs, contents depend on type).
**Optional:** `comment`, `properties`, `read_only`, `environment_settings` (Public Preview) -- object with `environment_version` and `java_dependencies[]` for JAR-backed connections.
**Supported types:** MYSQL, POSTGRESQL, SNOWFLAKE, REDSHIFT, SQLDW, SQLSERVER, DATABRICKS, BIGQUERY, ORACLE, TERADATA, SALESFORCE, SALESFORCE_DATA_CLOUD, WORKDAY_RAAS, GA4_RAW_DATA, SERVICENOW, GLUE, HTTP, POWER_BI, CONFLUENCE, HUBSPOT, ZENDESK (Beta: META_MARKETING, GITHUB, OUTLOOK, SMARTSHEET).

### List / Get / Update / Delete
- **List:** `GET .../connections?max_results=0` -- paginated.
- **Get:** `GET .../connections/{name}`
- **Update:** `PATCH .../connections/{name}` -- body requires `options` (full replacement); optional `new_name`, `owner`.
- **Delete:** `DELETE .../connections/{name}`

---

## Temporary Credentials

### Temporary Path Credentials
```
POST /api/2.0/unity-catalog/temporary-path-credentials
{"url": "s3://my-bucket/data/", "operation": "PATH_READ"}
```
**Required:** `url`, `operation` (PATH_READ | PATH_READ_WRITE | PATH_CREATE_TABLE).
**Optional:** `dry_run` (boolean).
**Permission:** `EXTERNAL_USE_LOCATION` on the external location. Metastore must have `external_access_enabled=true`.
**Response:** Cloud-specific temp credentials + `expiration_time`.

### Temporary Table Credentials
```
POST /api/2.0/unity-catalog/temporary-table-credentials
{"table_id": "<uuid>", "operation": "READ"}
```
**Required:** `table_id` (UUID), `operation` (READ | READ_WRITE).
**Permission:** `EXTERNAL_USE_SCHEMA` on parent schema. Metastore must have `external_access_enabled=true`.

---

## Common Errors
- **403:** Missing privilege (CREATE_EXTERNAL_LOCATION, CREATE_STORAGE_CREDENTIAL, owner, metastore admin).
- **404:** Named resource not found.
- **409:** Name already exists or overlapping URL with another external location.
- **400:** Invalid params (e.g., `max_results < 0`), validation failure.

## Gotchas
- **AWS IAM trust policy:** After creating a storage/service credential, the response includes `external_id` and `unity_catalog_iam_arn`. You must update the IAM role trust policy to include both before the credential works (confused deputy prevention).
- **Cloud-specific credential objects:** AWS uses `aws_iam_role` with `role_arn`; Azure uses `azure_managed_identity` or `azure_service_principal`; GCP uses `databricks_gcp_service_account`. Only one cloud credential per request.
- **Pagination:** All list endpoints: use `max_results=0` (recommended). Pages may have zero results but still return `next_page_token` -- keep reading until `next_page_token` is absent.
- **Credentials vs Storage Credentials API:** The `/credentials` endpoint is the unified API (supports both STORAGE and SERVICE purpose). The `/storage-credentials` endpoint is the older API. Both work; prefer the unified one.
- **External location URL update with `force`:** Changing an external location URL can break dependent external tables. Use `force=true` to override.
- **Connection `options` on update:** Must provide full options map (replacement, not merge).
- **Temp path/table credentials:** Requires metastore flag `external_access_enabled=true` (default false). Only for external storage paths; managed tables not supported.
