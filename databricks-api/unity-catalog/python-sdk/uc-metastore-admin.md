# Metastore Administration -- Databricks Python SDK

Metastore CRUD, workspace-metastore assignments, system schemas, resource quotas.

> See also: uc-grants-permissions (metastore-level grants), uc-external-locations (storage credentials for metastore)
> Raw docs: ../docs/raw/ — for full endpoint details, read {service}-{operation}.md

## Setup

```python
from databricks.sdk import WorkspaceClient
w = WorkspaceClient()  # uses DATABRICKS_HOST + DATABRICKS_TOKEN env vars
```

## SDK Client Map

| REST resource | SDK client |
|---|---|
| Metastores | `w.metastores` |
| SystemSchemas | `w.system_schemas` |
| ResourceQuotas | `w.resource_quotas` |

## Metastore CRUD

### Create
```python
ms = w.metastores.create(name="my-metastore", storage_root="s3://bucket/uc", region="us-west-2")
print(ms.metastore_id)
```
Required: `name`. Optional: `storage_root`, `region`, `external_access_enabled`.

### List
```python
for ms in w.metastores.list():
    print(ms.name, ms.metastore_id)
```
SDK handles pagination automatically.

### Get
```python
ms = w.metastores.get(id="<metastore-id>")
```

### Update
```python
w.metastores.update(id="<metastore-id>", new_name="renamed", owner="admins-group")
```
Optional: `new_name`, `owner`, `delta_sharing_scope`, `delta_sharing_recipient_token_lifetime_in_seconds`, `delta_sharing_organization_name`, `external_access_enabled`, `privilege_model_version`, `storage_root_credential_id`. Set `owner=""` for System User. Permission: metastore admin.

### Delete
```python
w.metastores.delete(id="<metastore-id>", force=True)
```
Optional: `force` (bool). Permission: metastore admin.

## Current Metastore Info

### Get current assignment
```python
assignment = w.metastores.current()
print(assignment.metastore_id, assignment.workspace_id)
```

### Get metastore summary
```python
summary = w.metastores.summary()
print(summary.name, summary.global_metastore_id)
```

## Workspace Assignments

### Create assignment
```python
w.metastores.assign(
    workspace_id=123456789,
    metastore_id="<id>",
    default_catalog_name="main"
)
```
Permission: account admin. `default_catalog_name` is deprecated; use Default Namespace API.

### Update assignment
```python
w.metastores.update_assignment(
    workspace_id=123456789,
    metastore_id="<new-id>"
)
```
Changing `metastore_id` requires account admin; `default_catalog_name` requires workspace admin.

### Delete assignment
```python
w.metastores.unassign(workspace_id=123456789, metastore_id="<id>")
```
Permission: account admin.

## System Schemas (Public Preview)

### List
```python
for s in w.system_schemas.list(metastore_id="<id>"):
    print(s.schema, s.state)
```
States: AVAILABLE, ENABLE_INITIALIZED, ENABLE_COMPLETED, DISABLE_INITIALIZED, UNAVAILABLE, MANAGED.
Permission: account/metastore admin.

### Enable
```python
w.system_schemas.enable(metastore_id="<id>", schema_name="access")
```

### Disable
```python
w.system_schemas.disable(metastore_id="<id>", schema_name="access")
```

## Resource Quotas

### List all quotas
```python
for q in w.resource_quotas.list_quotas():
    print(f"{q.quota_name}: {q.quota_count}/{q.quota_limit} on {q.parent_full_name}")
```
Returns: `quota_name`, `quota_count`, `quota_limit`, `parent_securable_type`, `parent_full_name`, `last_refreshed_at`.

### Get single quota
```python
q = w.resource_quotas.get_quota(
    parent_securable_type="schema",
    parent_full_name="main.default",
    quota_name="table-quota"
)
```

## Common Patterns

### Find workspace's metastore and enable all available system schemas
```python
summary = w.metastores.summary()
mid = summary.metastore_id
for s in w.system_schemas.list(metastore_id=mid):
    if s.state == "AVAILABLE":
        w.system_schemas.enable(metastore_id=mid, schema_name=s.schema)
        print(f"Enabled {s.schema}")
```

### Check quota usage approaching limits
```python
for q in w.resource_quotas.list_quotas():
    if q.quota_count and q.quota_limit:
        pct = q.quota_count / q.quota_limit * 100
        if pct > 80:
            print(f"WARNING: {q.quota_name} at {pct:.0f}% ({q.quota_count}/{q.quota_limit})")
```

## Key Response Objects

### MetastoreInfo (returned by create, get, update, summary)
Key fields: `metastore_id`, `name`, `owner`, `cloud`, `region`, `storage_root`, `storage_root_credential_id`, `storage_root_credential_name`, `global_metastore_id` (format: `cloud:region:metastore_id`), `delta_sharing_scope` (INTERNAL|INTERNAL_AND_EXTERNAL), `delta_sharing_organization_name`, `delta_sharing_recipient_token_lifetime_in_seconds`, `external_access_enabled`, `privilege_model_version`, `created_at`, `updated_at`, `created_by`, `updated_by`.

### MetastoreAssignment (returned by current)
Fields: `metastore_id`, `workspace_id`, `default_catalog_name` (deprecated).

### SystemSchemaInfo (returned by system_schemas.list)
Fields: `schema` (name string), `state` (AVAILABLE|ENABLE_INITIALIZED|ENABLE_COMPLETED|DISABLE_INITIALIZED|UNAVAILABLE|MANAGED).

### QuotaInfo (returned by resource_quotas)
Fields: `quota_name`, `quota_count` (int), `quota_limit` (int), `parent_securable_type` (CATALOG|SCHEMA|TABLE|METASTORE|etc.), `parent_full_name`, `last_refreshed_at` (epoch seconds).

## Gotchas

- `default_catalog_name` on assignments is deprecated; use Default Namespace API.
- `storage_root` is immutable after creation; only `storage_root_credential_id` can be updated.
- Quota counts have no SLA on freshness; API does not trigger a refresh.
- Deleting a metastore without `force=True` fails if it contains objects.
- System schema states: list pages may be empty but still return a continuation token; SDK handles this automatically.
- Setting `owner=""` transfers ownership to System User (not removes it).
- The `assign` method overwrites any existing assignment for that workspace.
- Changing `metastore_id` via `update_assignment` requires account admin; changing only `default_catalog_name` requires workspace admin.
