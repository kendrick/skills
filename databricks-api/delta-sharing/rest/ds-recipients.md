# Recipients Lifecycle — Databricks Delta Sharing REST API

> Manage share recipients, tokens, and view recipient share permissions.
> See also: [ds-shares.md](ds-shares.md) (the shares themselves), [ds-recipient-auth.md](ds-recipient-auth.md) (activation & federation)
> Raw docs: ../_docs/raw/ — for full endpoint details, read recipients-*.md

## Auth

All requests require:

- `Authorization: Bearer <PAT-or-OAuth-token>`
- Base URL: `https://<workspace-host>`
- API scope: `sharing` (preview)

## Endpoints

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/2.1/unity-catalog/recipients` | List recipients |
| POST | `/api/2.1/unity-catalog/recipients` | Create a recipient |
| GET | `/api/2.1/unity-catalog/recipients/{name}` | Get recipient details |
| PATCH | `/api/2.1/unity-catalog/recipients/{name}` | Update a recipient |
| DELETE | `/api/2.1/unity-catalog/recipients/{name}` | Delete a recipient |
| POST | `/api/2.1/unity-catalog/recipients/{name}/rotate-token` | Rotate recipient token |
| GET | `/api/2.1/unity-catalog/recipients/{name}/share-permissions` | Get recipient's share permissions |

---

## Recipient CRUD

### List Recipients

```
GET /api/2.1/unity-catalog/recipients
```

**Optional:** `data_recipient_global_metastore_id` (string), `max_results` (int32, <=1000), `page_token`

**Response:** `200` — `recipients[]` with `id`, `name`, `authentication_type`, `owner`, `activated`, `tokens[]`, `ip_access_list`, `properties_kvpairs`, `cloud`, `region` + `next_page_token`

**Permissions:** Metastore admin or recipient owner

### Create a Recipient

```
POST /api/2.1/unity-catalog/recipients
```

```json
{
  "name": "partner_org",
  "authentication_type": "TOKEN",
  "comment": "External partner",
  "expiration_time": 1735689600000
}
```

**Required:** `name`, `authentication_type` (TOKEN | DATABRICKS | OIDC_FEDERATION | OAUTH_CLIENT_CREDENTIALS)
**Optional:** `comment`, `owner`, `data_recipient_global_metastore_id` (DATABRICKS only, format `cloud:region:uuid`), `sharing_code` (DATABRICKS only), `expiration_time` (int64 epoch ms), `ip_access_list.allowed_ip_addresses` (string[], CIDR, max 100), `properties_kvpairs`

**Response:** `200` — RecipientInfo with `activation_url` (deprecated), `tokens[]`

**Permissions:** Metastore admin or CREATE_RECIPIENT on metastore

### Get a Recipient

```
GET /api/2.1/unity-catalog/recipients/{name}
```

**Required:** `name` (path)

**Response:** `200` — Full RecipientInfo with `id`, `name`, `authentication_type`, `owner`, `comment`, `activated` (deprecated), `activation_url` (deprecated), `tokens[]` (TOKEN auth), `ip_access_list`, `properties_kvpairs`, `sharing_code` (DATABRICKS only), `expiration_time`, `cloud`, `region`, `metastore_id` (DATABRICKS only), `created_at/by`, `updated_at/by`

**Permissions:** USE_RECIPIENT on metastore, recipient owner, or metastore admin

### Update a Recipient

```
PATCH /api/2.1/unity-catalog/recipients/{name}
```

```json
{
  "comment": "Updated partner info",
  "ip_access_list": {
    "allowed_ip_addresses": ["10.0.0.0/8"]
  }
}
```

**Required:** `name` (path)
**Optional:** `comment`, `new_name`, `owner`, `expiration_time`, `ip_access_list`, `properties_kvpairs` (overwrites existing)

**Response:** `200` — Updated RecipientInfo

**Permissions:** Metastore admin or recipient owner. Name change requires BOTH.

### Delete a Recipient

```
DELETE /api/2.1/unity-catalog/recipients/{name}
```

**Required:** `name` (path)

**Response:** `200`

**Permissions:** Recipient owner

---

## Token Management

### Rotate Token

```
POST /api/2.1/unity-catalog/recipients/{name}/rotate-token
```

```json
{
  "existing_token_expire_in_seconds": 3600
}
```

**Required:** `name` (path), `existing_token_expire_in_seconds` (int64 — 0 = immediate expiry, must be >= 0)

**Response:** `200` — Full RecipientInfo with new `tokens[]` array

**Permissions:** Recipient owner

---

## Recipient Share Permissions

### Get Share Permissions

```
GET /api/2.1/unity-catalog/recipients/{name}/share-permissions
```

**Required:** `name` (path)
**Optional:** `max_results` (int32, <=1000), `page_token`

**Response:** `200` — `permissions_out[]` with `share_name`, `privilege_assignments[]` (each with `principal`, `privileges[]`)

**Permissions:** USE_RECIPIENT on metastore OR recipient owner

---

## Gotchas

- **authentication_type is immutable**: Set at creation, cannot be changed via update
- **properties_kvpairs overwrites**: Update replaces all existing key-value pairs, not merge
- **Rename requires dual permission**: Both metastore admin AND recipient owner needed
- **Token rotation**: Setting `existing_token_expire_in_seconds` to 0 expires the old token immediately — no grace period
- **activation_url is deprecated**: Use the recipient activation endpoints instead
- **ip_access_list max 100**: CIDR notation, maximum 100 entries
- **DATABRICKS auth type**: Requires `data_recipient_global_metastore_id` in `cloud:region:metastore-uuid` format
