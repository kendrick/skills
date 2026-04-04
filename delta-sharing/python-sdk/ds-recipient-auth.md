# Recipient Auth & Federation — Databricks Python SDK

> Recipient activation (public endpoints) and OIDC federation policy management.
> See also: [ds-recipients.md](ds-recipients.md) (recipient CRUD and tokens)
> Raw docs: ../docs/raw/ — for full endpoint details, read recipientactivation-*.md, recipientfederationpolicies-*.md
> Package: `databricks-sdk` — verify against your version (`pip show databricks-sdk`)

## Setup

```python
from databricks.sdk import WorkspaceClient
w = WorkspaceClient()
# SDK client map:
#   w.recipient_activation          -- public activation endpoints
#   w.recipient_federation_policies -- OIDC federation policy CRUD
```

---

## 1. Recipient Activation (Public)

These are public endpoints — no authentication needed. Used by recipients to activate their share access.

### Get Activation URL Info
```python
info = w.recipient_activation.get_activation_url_info(
    activation_url="<activation-url-or-token>",
)
```

### Retrieve Access Token
```python
token_info = w.recipient_activation.retrieve_token(
    activation_url="<activation-url-or-token>",
)
print(token_info.bearer_token)
print(token_info.endpoint)
print(token_info.expiration_time)
print(token_info.share_credentials_version)
```

**Returns:** `bearer_token` (string), `endpoint` (string), `expiration_time` (string, epoch ms), `share_credentials_version` (int32)

---

## 2. Federation Policies (OIDC)

Manage OIDC federation policies for OIDC_FEDERATION recipient types.

### List Federation Policies
```python
for policy in w.recipient_federation_policies.list(
    recipient_name="oidc_partner",
):
    print(policy.name, policy.oidc_policy.issuer)
```
SDK auto-paginates.

### Create a Federation Policy
```python
from databricks.sdk.service.sharing import OidcFederationPolicy

policy = w.recipient_federation_policies.create(
    recipient_name="oidc_partner",
    name="azure-ad-policy",
    comment="Azure AD federation",
    oidc_policy=OidcFederationPolicy(
        issuer="https://login.microsoftonline.com/{tenant}/v2.0",
        subject="app-client-id",
        subject_claim="azp",
        audiences=["api://databricks"],
    ),
)
print(policy.id, policy.name)
```
**Required:** `recipient_name`
**Conditionally required:** `oidc_policy.issuer`, `oidc_policy.subject`, `oidc_policy.subject_claim`
**Optional:** `name`, `comment`, `oidc_policy.audiences`

### Get a Federation Policy
```python
policy = w.recipient_federation_policies.get_federation_policy(
    recipient_name="oidc_partner",
    name="azure-ad-policy",
)
print(policy.oidc_policy.issuer, policy.oidc_policy.audiences)
```

### Delete a Federation Policy
```python
w.recipient_federation_policies.delete(
    recipient_name="oidc_partner",
    name="azure-ad-policy",
)
```
**Permissions:** Recipient owner

---

## Common Patterns

### Set up OIDC federation for a recipient
```python
from databricks.sdk.service.sharing import AuthenticationType, OidcFederationPolicy

# Create OIDC recipient
recipient = w.recipients.create(
    name="oidc_partner",
    authentication_type=AuthenticationType.OIDC_FEDERATION,
)

# Add federation policy
w.recipient_federation_policies.create(
    recipient_name="oidc_partner",
    name="azure-ad",
    oidc_policy=OidcFederationPolicy(
        issuer="https://login.microsoftonline.com/{tenant}/v2.0",
        subject="app-client-id",
        subject_claim="azp",
    ),
)
```

### Error handling
```python
from databricks.sdk.errors import NotFound, PermissionDenied
try:
    w.recipient_federation_policies.get_federation_policy(
        recipient_name="nonexistent", name="policy",
    )
except NotFound:
    print("Policy or recipient not found")
```

---

## Gotchas

- **Activation URLs are one-time**: Once token is retrieved, the URL is consumed
- **Public endpoints**: Activation methods require no auth — `WorkspaceClient` still needed for URL routing
- **Federation policies are OIDC_FEDERATION only**: Only for recipients with that auth type
- **No update method**: Delete and recreate to change a federation policy
- **Policy name format**: Lowercase alphanumeric and hyphens only
- **SDK clients**: `w.recipient_activation` and `w.recipient_federation_policies` — verify method names match your SDK version
- **Import path**: `from databricks.sdk.service.sharing import OidcFederationPolicy`
