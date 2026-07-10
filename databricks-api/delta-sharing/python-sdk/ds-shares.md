# Shares Lifecycle — Databricks Python SDK

> Manage shared data objects and their permissions.
> See also: [ds-recipients.md](ds-recipients.md) (who receives shares), [ds-providers.md](ds-providers.md) (external providers)
> Raw docs: ../_docs/raw/ — for full endpoint details, read shares-*.md
> Package: `databricks-sdk` — verify against your version (`pip show databricks-sdk`)

## Setup

```python
from databricks.sdk import WorkspaceClient
w = WorkspaceClient()
# SDK client map:
#   w.shares           -- share CRUD + permissions
```

---

## 1. Share CRUD

### Create a Share
```python
share = w.shares.create(
    name="my_share",
    comment="Sales data share",
)
print(share.name)
```
**Required:** `name`
**Optional:** `comment`, `storage_root`

### List Shares
```python
for share in w.shares.list():
    print(share.name, share.owner)
```
SDK auto-paginates. If caller has USE_SHARE on metastore, returns all shares; otherwise only owned.

### Get a Share
```python
share = w.shares.get(name="my_share", include_shared_data=True)
for obj in share.objects:
    print(obj.name, obj.data_object_type, obj.status)
```
**Required:** `name`
**Optional:** `include_shared_data: bool`

### Update a Share
```python
from databricks.sdk.service.sharing import SharedDataObjectUpdate, SharedDataObject

updated = w.shares.update(
    name="my_share",
    comment="Updated description",
    updates=[
        SharedDataObjectUpdate(
            action=SharedDataObjectUpdateAction.ADD,
            data_object=SharedDataObject(
                name="catalog.schema.table",
                data_object_type=SharedDataObjectDataObjectType.TABLE,
                shared_as="shared_table_name",
            ),
        ),
    ],
)
```
**Required:** `name`
**Optional:** `comment`, `new_name`, `owner`, `storage_root`, `updates` (max 100 objects)

`storage_root` cannot be updated if the share contains notebook files. Metastore admins can only change `owner`; renaming requires ownership AND CREATE_SHARE privilege.

### Delete a Share
```python
w.shares.delete(name="my_share")
```

---

## 2. Share Permissions

### Get Permissions
```python
perms = w.shares.share_permissions(name="my_share")
for pa in perms.privilege_assignments:
    print(pa.principal, pa.privileges)
```

### Update Permissions
```python
from databricks.sdk.service.sharing import PermissionsChange

w.shares.update_permissions(
    name="my_share",
    changes=[
        PermissionsChange(
            principal="recipient_name",
            add=["SELECT"],
        ),
    ],
)
```
**Required:** `name`, `changes`

---

## Common Patterns

### Create share and add tables
```python
share = w.shares.create(name="analytics_share")
w.shares.update(
    name="analytics_share",
    updates=[
        SharedDataObjectUpdate(
            action=SharedDataObjectUpdateAction.ADD,
            data_object=SharedDataObject(
                name="catalog.schema.customers",
                data_object_type=SharedDataObjectDataObjectType.TABLE,
            ),
        ),
        SharedDataObjectUpdate(
            action=SharedDataObjectUpdateAction.ADD,
            data_object=SharedDataObject(
                name="catalog.schema.orders",
                data_object_type=SharedDataObjectDataObjectType.TABLE,
            ),
        ),
    ],
)
```

### Grant share to a recipient
```python
w.shares.update_permissions(
    name="analytics_share",
    changes=[PermissionsChange(principal="partner_org", add=["SELECT"])],
)
```

### Error handling
```python
from databricks.sdk.errors import NotFound, PermissionDenied
try:
    share = w.shares.get(name="nonexistent")
except NotFound:
    print("Share not found")
except PermissionDenied:
    print("Insufficient privileges")
```

---

## Gotchas

- **SDK client**: `w.shares` (not `w.delta_sharing` or similar)
