# Recipient Auth & Federation — Databricks Delta Sharing REST API

> Recipient activation (public endpoints) and OIDC federation policy management.
> See also: [ds-recipients.md](ds-recipients.md) (recipient CRUD and tokens)
> Raw docs: ../_docs/raw/ — for full endpoint details, read recipientactivation-*.md, recipientfederationpolicies-*.md

## Auth

**Activation endpoints are PUBLIC** — no auth required.
**Federation policy endpoints** require `Authorization: Bearer <PAT-or-OAuth-token>`.

Base URL: `https://<workspace-host>`
API scope: `sharing` (preview)

## Endpoints

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/2.1/unity-catalog/public/data_sharing_activation_info/{activation_url}` | Get activation URL info |
| GET | `/api/2.1/unity-catalog/public/data_sharing_activation/{activation_url}` | Retrieve access token |
| GET | `/api/2.0/data-sharing/recipients/{recipient_name}/federation-policies` | List federation policies |
| POST | `/api/2.0/data-sharing/recipients/{recipient_name}/federation-policies` | Create federation policy |
| GET | `/api/2.0/data-sharing/recipients/{recipient_name}/federation-policies/{name}` | Get federation policy |
| DELETE | `/api/2.0/data-sharing/recipients/{recipient_name}/federation-policies/{name}` | Delete federation policy |

---

## Recipient Activation (Public)

These endpoints require NO authentication. They are used by recipients to activate their share access. Anyone with the URL can retrieve the token.

### Get Activation URL Info

```
GET /api/2.1/unity-catalog/public/data_sharing_activation_info/{activation_url}
```

**Required:** `activation_url` (path — also accepts activation token)

**Response:** `200` — Empty object `{}`

### Retrieve Access Token

```
GET /api/2.1/unity-catalog/public/data_sharing_activation/{activation_url}
```

**Required:** `activation_url` (path — also accepts activation token)

**Response:** `200`

```json
{
  "bearerToken": "dapi...",
  "endpoint": "https://<workspace-host>/api/2.0/delta-sharing/",
  "expirationTime": "1735689600000",
  "shareCredentialsVersion": 1
}
```

**Response fields:** `bearerToken` (string), `endpoint` (string), `expirationTime` (string, epoch ms), `shareCredentialsVersion` (int32)

Activation URLs are one-time: once a token is retrieved, the activation URL is consumed.

---

## Federation Policies (OIDC)

Manage OIDC federation policies for OIDC_FEDERATION recipient types. These policies validate OIDC token claims from external identity providers.

### List Federation Policies

```
GET /api/2.0/data-sharing/recipients/{recipient_name}/federation-policies
```

**Required:** `recipient_name` (path)
**Optional:** `max_results` (int32), `page_token`

**Response:** `200` — `policies[]` with `id` (uuid), `name`, `comment`, `oidc_policy`, `create_time`, `update_time` + `next_page_token`

**Permissions:** Read access to the recipient

### Create a Federation Policy

```
POST /api/2.0/data-sharing/recipients/{recipient_name}/federation-policies
```

```json
{
  "name": "my-oidc-policy",
  "comment": "Azure AD federation",
  "oidc_policy": {
    "issuer": "https://login.microsoftonline.com/{tenant}/v2.0",
    "subject": "app-client-id",
    "subject_claim": "azp",
    "audiences": ["api://databricks"]
  }
}
```

**Required:** `recipient_name` (path)
**Conditionally required (if oidc_policy provided):** `oidc_policy.issuer`, `oidc_policy.subject`, `oidc_policy.subject_claim`
**Optional:** `name`, `comment`, `oidc_policy.audiences` (string[])

`name` must be lowercase alphanumeric and hyphens only. Common `subject_claim` values are `sub`, `azp`, `oid` — depends on the identity provider.

**Response:** `200` — Created policy with `id`, `name`, `oidc_policy`, `create_time`, `update_time`

**Permissions:** API scope `sharing`

### Get a Federation Policy

```
GET /api/2.0/data-sharing/recipients/{recipient_name}/federation-policies/{name}
```

**Required:** `recipient_name` (path), `name` (path)

**Response:** `200` — Full policy object with `oidc_policy` containing `issuer`, `subject`, `subject_claim`, `audiences`

**Permissions:** Read access to the recipient

### Delete a Federation Policy

```
DELETE /api/2.0/data-sharing/recipients/{recipient_name}/federation-policies/{name}
```

**Required:** `recipient_name` (path), `name` (path)

**Response:** `200` — Empty object

**Permissions:** Recipient owner

---

## Gotchas

- **API version difference**: Federation policies use `/api/2.0/data-sharing/`, activation uses `/api/2.1/unity-catalog/public/`
- **No update endpoint**: Federation policies can only be created and deleted, not updated — delete and recreate to change
