# Recipients Lifecycle — Databricks Python SDK

> Manage share recipients, tokens, and view recipient share permissions.
> See also: [ds-shares.md](ds-shares.md) (the shares themselves), [ds-recipient-auth.md](ds-recipient-auth.md) (activation & federation)
> Raw docs: ../_docs/raw/ — for full endpoint details, read recipients-*.md
> Package: `databricks-sdk` — verify against your version (`pip show databricks-sdk`)

## Setup

```python
from databricks.sdk import WorkspaceClient
w = WorkspaceClient()
# SDK client map:
#   w.recipients        -- recipient CRUD, token rotation, share permissions
```

---

## 1. Recipient CRUD

### Create a Recipient
```python
from databricks.sdk.service.sharing import AuthenticationType

recipient = w.recipients.create(
    name="partner_org",
    authentication_type=AuthenticationType.TOKEN,
    comment="External partner",
    expiration_time=1735689600000,
)
print(recipient.name, recipient.tokens)
```
**Required:** `name`, `authentication_type` (TOKEN | DATABRICKS | OIDC_FEDERATION | OAUTH_CLIENT_CREDENTIALS)
**Optional:** `comment`, `owner`, `data_recipient_global_metastore_id` (DATABRICKS only), `sharing_code` (DATABRICKS only), `expiration_time`, `ip_access_list` (CIDR notation, max 100 entries), `properties_kvpairs`

### List Recipients
```python
for r in w.recipients.list():
    print(r.name, r.authentication_type, r.activated)
```
SDK auto-paginates. Filter: `data_recipient_global_metastore_id`.

### Get a Recipient
```python
recipient = w.recipients.get(name="partner_org")
print(recipient.authentication_type, recipient.ip_access_list)
```
**Permissions:** USE_RECIPIENT on metastore, recipient owner, or metastore admin

### Update a Recipient
```python
from databricks.sdk.service.sharing import IpAccessList

w.recipients.update(
    name="partner_org",
    comment="Updated partner info",
    ip_access_list=IpAccessList(allowed_ip_addresses=["10.0.0.0/8"]),
)
```
**Optional:** `comment`, `new_name`, `owner`, `expiration_time`, `ip_access_list`, `properties_kvpairs` (overwrites existing, not merged)

`authentication_type` cannot be changed after creation. Renaming (`new_name`) requires both metastore admin AND recipient owner.

### Delete a Recipient
```python
w.recipients.delete(name="partner_org")
```

---

## 2. Token Management

### Rotate Token
```python
updated = w.recipients.rotate_token(
    name="partner_org",
    existing_token_expire_in_seconds=3600,  # grace period; 0 = immediate
)
for token in updated.tokens:
    print(token.activation_url, token.expiration_time)
```
**Required:** `name`, `existing_token_expire_in_seconds` (int64, >= 0)

---

## 3. Recipient Share Permissions

### Get Share Permissions
```python
perms = w.recipients.share_permissions(name="partner_org")
for p in perms.permissions_out:
    print(p.share_name, p.privilege_assignments)
```

---

## Common Patterns

### Create recipient and grant access to a share
```python
recipient = w.recipients.create(
    name="data_consumer",
    authentication_type=AuthenticationType.TOKEN,
)
w.shares.update_permissions(
    name="my_share",
    changes=[PermissionsChange(principal="data_consumer", add=["SELECT"])],
)
```

### Rotate token with grace period
```python
# Give 1 hour for old token to expire
updated = w.recipients.rotate_token(
    name="partner_org",
    existing_token_expire_in_seconds=3600,
)
# Distribute new token, old token still works for 1 hour
```

### List all shares a recipient has access to
```python
perms = w.recipients.share_permissions(name="partner_org")
share_names = [p.share_name for p in perms.permissions_out]
```

### Error handling
```python
from databricks.sdk.errors import NotFound, PermissionDenied
try:
    w.recipients.get(name="nonexistent")
except NotFound:
    print("Recipient not found")
```

---

## Gotchas

- **SDK client**: `w.recipients` — import types from `databricks.sdk.service.sharing`
