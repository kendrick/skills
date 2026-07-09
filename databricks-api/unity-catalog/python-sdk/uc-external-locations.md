# External Locations & Credentials -- Databricks Python SDK

Scope: External locations, storage credentials, general credentials (storage + service), connections (Lakehouse Federation), temporary credentials.

> See also: uc-grants-permissions (for granting access), uc-catalog-schema-table (for external tables)
> Raw docs: ../docs/raw/ — for full endpoint details, read {service}-{operation}.md

## Setup
```python
from databricks.sdk import WorkspaceClient
w = WorkspaceClient()  # uses DATABRICKS_HOST + DATABRICKS_TOKEN env vars
```

## SDK Client Map
| REST Resource | SDK Client | Key Methods |
|---|---|---|
| Storage Credentials | `w.storage_credentials` | `create`, `list`, `get`, `update`, `delete`, `validate` |
| External Locations | `w.external_locations` | `create`, `list`, `get`, `update`, `delete` |
| Credentials (unified) | `w.credentials` | `create_credential`, `list_credentials`, `get_credential`, `update_credential`, `delete_credential`, `generate_temporary_service_credential`, `validate_credential` |
| Connections | `w.connections` | `create`, `list`, `get`, `update`, `delete` |
| Temp Path Credentials | `w.temporary_path_credentials` | `generate_temporary_path_credentials` |
| Temp Table Credentials | `w.temporary_table_credentials` | `generate_temporary_table_credentials` |

---

## Storage Credentials

### Create
```python
from databricks.sdk.service.catalog import AwsIamRoleRequest

cred = w.storage_credentials.create(
    name="my-s3-cred",
    aws_iam_role=AwsIamRoleRequest(role_arn="arn:aws:iam::123456789012:role/my-role"),
    comment="S3 access",
    read_only=False,
    skip_validation=False,
)
# IMPORTANT: Add cred.aws_iam_role.external_id to your IAM trust policy
print(cred.aws_iam_role.external_id, cred.aws_iam_role.unity_catalog_iam_arn)
```

### List / Get / Update / Delete
```python
# List (paginated by default)
for c in w.storage_credentials.list(max_results=0):
    print(c.name)

# Get
cred = w.storage_credentials.get(name="my-s3-cred")

# Update
updated = w.storage_credentials.update(name="my-s3-cred", comment="updated", force=True)

# Delete
w.storage_credentials.delete(name="my-s3-cred", force=True)
```

### Validate
```python
result = w.storage_credentials.validate(
    storage_credential_name="my-s3-cred",
    url="s3://my-bucket/path",
)
for r in result.results:
    print(r.operation, r.result, r.message)
```

---

## External Locations

### Create
```python
loc = w.external_locations.create(
    name="my-ext-loc",
    url="s3://my-bucket/data/",
    credential_name="my-s3-cred",
    comment="External data",
    read_only=False,
    skip_validation=False,
)
```
**Permission:** Metastore admin or `CREATE_EXTERNAL_LOCATION` on metastore + credential.

### List / Get / Update / Delete
```python
# List (paginated)
for loc in w.external_locations.list(max_results=0):
    print(loc.name, loc.url)

# Get
loc = w.external_locations.get(name="my-ext-loc")

# Update (force=True if changing url with dependents)
w.external_locations.update(name="my-ext-loc", comment="updated", owner="new-owner@co.com")

# Delete
w.external_locations.delete(name="my-ext-loc", force=True)
```

---

## General Credentials (Unified API)

Manages both STORAGE and SERVICE credentials. Prefer over legacy `storage_credentials` for new work.

### Create
```python
from databricks.sdk.service.catalog import CredentialPurpose

cred = w.credentials.create_credential(
    name="my-service-cred",
    purpose=CredentialPurpose.SERVICE,
    aws_iam_role=AwsIamRoleRequest(role_arn="arn:aws:iam::123456789012:role/svc-role"),
    skip_validation=False,
)
```

### List / Get / Update / Delete
```python
# List service credentials only
for c in w.credentials.list_credentials(purpose=CredentialPurpose.SERVICE, max_results=0):
    print(c.name, c.purpose)

# Get
cred = w.credentials.get_credential(name_arg="my-service-cred")

# Update
w.credentials.update_credential(name_arg="my-service-cred", comment="updated", force=True)

# Delete
w.credentials.delete_credential(name_arg="my-service-cred", force=True)
```

### Generate Temporary Service Credential
```python
temp = w.credentials.generate_temporary_service_credential(credential_name="my-service-cred")
print(temp.aws_temp_credentials.access_key_id)
print(temp.expiration_time)
```
**Permission:** Metastore admin or `ACCESS` privilege on the service credential.

### Validate
```python
from databricks.sdk.service.catalog import CredentialPurpose

result = w.credentials.validate_credential(
    credential_name="my-cred",
    purpose=CredentialPurpose.STORAGE,
    url="s3://my-bucket/path",
)
for r in result.results:
    print(r.result, r.message)
```

---

## Connections (Lakehouse Federation)

### Create
```python
conn = w.connections.create(
    name="my-pg-conn",
    connection_type="POSTGRESQL",
    options={"host": "pg.example.com", "port": "5432", "user": "admin", "password": "secret"},
    comment="Production PG",
)
```
**Supported types:** MYSQL, POSTGRESQL, SNOWFLAKE, REDSHIFT, SQLDW, SQLSERVER, DATABRICKS, BIGQUERY, ORACLE, TERADATA, SALESFORCE, SALESFORCE_DATA_CLOUD, WORKDAY_RAAS, GA4_RAW_DATA, SERVICENOW, GLUE, HTTP, POWER_BI, CONFLUENCE, HUBSPOT, ZENDESK (Beta: META_MARKETING, GITHUB, OUTLOOK, SMARTSHEET).
Optional `environment_settings` (Public Preview) -- object with `environment_version` and `java_dependencies` for JAR-backed connections.

### List / Get / Update / Delete
```python
for conn in w.connections.list(max_results=0):
    print(conn.name, conn.connection_type)

conn = w.connections.get(name="my-pg-conn")

# Update -- options is a full replacement, not a merge
w.connections.update(name="my-pg-conn", options={"host": "new-pg.example.com", "port": "5432", "user": "admin", "password": "newsecret"})

w.connections.delete(name="my-pg-conn")
```

---

## Temporary Credentials

### Temporary Path Credentials
```python
from databricks.sdk.service.catalog import PathOperation

temp = w.temporary_path_credentials.generate_temporary_path_credentials(
    url="s3://my-bucket/data/",
    operation=PathOperation.PATH_READ,
)
print(temp.aws_temp_credentials.access_key_id)
print(temp.expiration_time)
```
**Permission:** `EXTERNAL_USE_LOCATION` on external location. Metastore `external_access_enabled` must be true.

### Temporary Table Credentials
```python
from databricks.sdk.service.catalog import TableOperation

temp = w.temporary_table_credentials.generate_temporary_table_credentials(
    table_id="<table-uuid>",
    operation=TableOperation.READ,
)
print(temp.url, temp.expiration_time)
```
**Permission:** `EXTERNAL_USE_SCHEMA` on parent schema. Metastore `external_access_enabled` must be true.

---

## Common Patterns

### Full setup: credential + external location
```python
# 1. Create storage credential
cred = w.storage_credentials.create(
    name="s3-cred", aws_iam_role=AwsIamRoleRequest(role_arn="arn:aws:iam::123:role/role")
)
# 2. Update IAM trust policy with cred.aws_iam_role.external_id (manual step)
# 3. Validate
w.storage_credentials.validate(storage_credential_name="s3-cred", url="s3://bucket/path")
# 4. Create external location
w.external_locations.create(name="ext-loc", url="s3://bucket/path", credential_name="s3-cred")
```

### Paginate through all items
```python
# SDK handles pagination automatically when you iterate
all_locs = list(w.external_locations.list(max_results=0))
```

---

## Gotchas
- **AWS IAM trust policy:** After creating a credential, you must add the returned `external_id` and configure `unity_catalog_iam_arn` as the trusted principal in the IAM role trust policy. The credential will not work until this is done.
- **Cloud-specific credential objects:** AWS uses `AwsIamRoleRequest(role_arn=...)`. Azure and GCP have different request objects. Only one cloud credential per call.
- **Unified credentials API path param:** The get/update/delete methods use `name_arg` (not `name`) as the parameter name.
- **Connection options on update:** Must provide the full options dict (replacement, not merge).
- **Temp credentials require metastore flag:** `external_access_enabled` must be set to true on the metastore (default is false). Only works for external storage paths, not managed tables.
- **Pagination:** SDK auto-paginates when iterating. Pages may return zero results before the final page -- this is normal.
- **Force delete:** Pass `force=True` to delete credentials/locations that have dependent objects.
