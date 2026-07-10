# Providers Lifecycle — Databricks Delta Sharing REST API

> Manage external data providers and browse their shared assets.
> See also: [ds-shares.md](ds-shares.md) (your own shares), [ds-recipients.md](ds-recipients.md) (who receives your shares)
> Raw docs: ../_docs/raw/ — for full endpoint details, read providers-*.md

## Auth

All requests require:

- `Authorization: Bearer <PAT-or-OAuth-token>`
- Base URL: `https://<workspace-host>`
- API scope: `sharing` (preview)

## Endpoints

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/2.1/unity-catalog/providers` | List providers |
| POST | `/api/2.1/unity-catalog/providers` | Create a provider |
| GET | `/api/2.1/unity-catalog/providers/{name}` | Get provider details |
| PATCH | `/api/2.1/unity-catalog/providers/{name}` | Update a provider |
| DELETE | `/api/2.1/unity-catalog/providers/{name}` | Delete a provider |
| GET | `/api/2.1/unity-catalog/providers/{name}/shares` | List shares from provider |
| GET | `/api/2.1/data-sharing/providers/{provider_name}/shares/{share_name}` | List provider share assets |

---

## Provider CRUD

### List Providers

```
GET /api/2.1/unity-catalog/providers
```

**Optional:** `data_provider_global_metastore_id` (string), `max_results` (int32, <=1000), `page_token`

**Response:** `200` — `providers[]` with `name`, `authentication_type`, `owner`, `comment`, `cloud`, `region`, `metastore_id`, `recipient_profile`, `created_at/by`, `updated_at/by` + `next_page_token`

**Permissions:** Metastore admin, USE_PROVIDER on providers, or provider owner

### Create a Provider

```
POST /api/2.1/unity-catalog/providers
```

```json
{
  "name": "external_vendor",
  "authentication_type": "TOKEN",
  "comment": "External data vendor",
  "recipient_profile_str": "{\"shareCredentialsVersion\":1,\"bearerToken\":\"...\",\"endpoint\":\"https://...\"}"
}
```

**Required:** `name`, `authentication_type` (TOKEN | DATABRICKS | OIDC_FEDERATION | OAUTH_CLIENT_CREDENTIALS)
**Optional:** `comment`, `owner`, `recipient_profile_str` (required for TOKEN/OAUTH_CLIENT_CREDENTIALS)

**Response:** `200` — ProviderInfo with `name`, `authentication_type`, `owner`, `comment`, `recipient_profile` (TOKEN/OAUTH only), `cloud`, `region`, `metastore_id` (DATABRICKS only), `created_at/by`, `updated_at/by`

**Permissions:** Metastore admin

### Get a Provider

```
GET /api/2.1/unity-catalog/providers/{name}
```

**Required:** `name` (path)

**Response:** `200` — ProviderInfo with `authentication_type`, `recipient_profile` (TOKEN/OAUTH only), `cloud`, `region`, `metastore_id` (DATABRICKS only)

**Permissions:** Metastore admin or provider owner

### Update a Provider

```
PATCH /api/2.1/unity-catalog/providers/{name}
```

```json
{
  "comment": "Updated vendor info",
  "recipient_profile_str": "{...}"
}
```

**Required:** `name` (path)
**Optional:** `comment`, `new_name`, `owner`, `recipient_profile_str`

**Response:** `200` — Updated ProviderInfo

**Permissions:** Metastore admin or provider owner. Name change requires BOTH.

### Delete a Provider

```
DELETE /api/2.1/unity-catalog/providers/{name}
```

**Required:** `name` (path)

**Response:** `200`

**Permissions:** Metastore admin or provider owner

---

## Browse Provider Shares

### List Shares from Provider

```
GET /api/2.1/unity-catalog/providers/{name}/shares
```

**Required:** `name` (path)
**Optional:** `max_results` (int32, <=1000), `page_token`

**Response:** `200` — `shares[]` with `name` + `next_page_token`

**Permissions:** Metastore admin or provider owner

### List Provider Share Assets

```
GET /api/2.1/data-sharing/providers/{provider_name}/shares/{share_name}
```

**Required:** `provider_name` (path), `share_name` (path)
**Optional:** `table_max_results` (int32, <=1000, default 500), `function_max_results` (int32, <=1000, default 500), `volume_max_results` (int32, <=1000, default 500), `notebook_max_results` (int32, <=100, default 100)

**Response:** `200` — `tables[]`, `functions[]`, `volumes[]`, `notebooks[]`, `share` metadata

**Permissions:** API scope `sharing`

---

## Gotchas

- **recipient_profile_str**: Required for TOKEN and OAUTH_CLIENT_CREDENTIALS auth types; must be valid JSON with `shareCredentialsVersion`, `bearerToken`, `endpoint`
- **DATABRICKS auth type**: Provider auto-populated with `cloud`, `region`, `metastore_id` — no profile string needed
- **Rename requires dual permission**: Both metastore admin AND provider owner
- **List share assets path differs**: Uses `/api/2.1/data-sharing/` base instead of `/api/2.1/unity-catalog/`
- **Asset pagination**: Each asset type (tables, functions, volumes, notebooks) has its own max_results param
