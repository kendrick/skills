# Providers Lifecycle — Databricks Python SDK

> Manage external data providers and browse their shared assets.
> See also: [ds-shares.md](ds-shares.md) (your own shares), [ds-recipients.md](ds-recipients.md) (who receives your shares)
> Raw docs: ../_docs/raw/ — for full endpoint details, read providers-*.md
> Package: `databricks-sdk` — verify against your version (`pip show databricks-sdk`)

## Setup

```python
from databricks.sdk import WorkspaceClient
w = WorkspaceClient()
# SDK client map:
#   w.providers          -- provider CRUD, list shares, list share assets
```

---

## 1. Provider CRUD

### Create a Provider
```python
from databricks.sdk.service.sharing import AuthenticationType

provider = w.providers.create(
    name="external_vendor",
    authentication_type=AuthenticationType.TOKEN,
    comment="External data vendor",
    recipient_profile_str='{"shareCredentialsVersion":1,"bearerToken":"dapi...","endpoint":"https://..."}',
)
print(provider.name)
```
**Required:** `name`, `authentication_type` (TOKEN | DATABRICKS | OIDC_FEDERATION | OAUTH_CLIENT_CREDENTIALS)
**Optional:** `comment`, `owner`, `recipient_profile_str` (required for TOKEN/OAUTH_CLIENT_CREDENTIALS; must be valid JSON with `shareCredentialsVersion`, `bearerToken`, `endpoint`)

For DATABRICKS auth, the provider is auto-populated with cloud/region/metastore — no profile string needed.

**Permissions:** Metastore admin

### List Providers
```python
for p in w.providers.list():
    print(p.name, p.authentication_type, p.owner)
```
SDK auto-paginates. Filter: `data_provider_global_metastore_id`.

### Get a Provider
```python
provider = w.providers.get(name="external_vendor")
print(provider.authentication_type, provider.recipient_profile)
```

### Update a Provider
```python
w.providers.update(
    name="external_vendor",
    comment="Updated vendor info",
    recipient_profile_str='{"shareCredentialsVersion":1,"bearerToken":"new-token","endpoint":"https://..."}',
)
```
**Optional:** `comment`, `new_name`, `owner`, `recipient_profile_str`

Renaming (`new_name`) requires both metastore admin AND provider owner.

### Delete a Provider
```python
w.providers.delete(name="external_vendor")
```

---

## 2. Browse Provider Shares

### List Shares from Provider
```python
for share in w.providers.list_shares(name="external_vendor"):
    print(share.name)
```
SDK auto-paginates.

### List Provider Share Assets
```python
assets = w.providers.list_provider_share_assets(
    provider_name="external_vendor",
    share_name="shared_data",
    table_max_results=100,
)
for table in assets.tables:
    print(table.name, table.schema)
for volume in assets.volumes:
    print(volume.name)
```
**Required:** `provider_name`, `share_name`
**Optional:** `table_max_results` (<=1000, default 500), `function_max_results` (<=1000, default 500), `volume_max_results` (<=1000, default 500), `notebook_max_results` (<=100, default 100)

**Returns:** `tables[]`, `functions[]`, `volumes[]`, `notebooks[]`, `share` metadata

---

## Common Patterns

### Register a provider and browse their shares
```python
provider = w.providers.create(
    name="vendor",
    authentication_type=AuthenticationType.TOKEN,
    recipient_profile_str=profile_json,
)
for share in w.providers.list_shares(name="vendor"):
    assets = w.providers.list_provider_share_assets(
        provider_name="vendor",
        share_name=share.name,
    )
    print(f"Share {share.name}: {len(assets.tables)} tables, {len(assets.volumes)} volumes")
```

### Error handling
```python
from databricks.sdk.errors import NotFound, PermissionDenied
try:
    w.providers.get(name="nonexistent")
except NotFound:
    print("Provider not found")
```

---

## Gotchas

- **SDK client**: `w.providers` — import types from `databricks.sdk.service.sharing`
