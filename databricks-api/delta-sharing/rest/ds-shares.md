# Shares Lifecycle — Databricks Delta Sharing REST API

> Manage shared data objects and their permissions.
> See also: [ds-recipients.md](ds-recipients.md) (who receives shares), [ds-providers.md](ds-providers.md) (external providers)
> Raw docs: ../_docs/raw/ — for full endpoint details, read shares-*.md

## Auth

All requests require:

- `Authorization: Bearer <PAT-or-OAuth-token>`
- Base URL: `https://<workspace-host>`
- API scope: `sharing` (preview)

## Endpoints

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/2.1/unity-catalog/shares` | List all shares |
| POST | `/api/2.1/unity-catalog/shares` | Create a share |
| GET | `/api/2.1/unity-catalog/shares/{name}` | Get share details |
| PATCH | `/api/2.1/unity-catalog/shares/{name}` | Update a share |
| DELETE | `/api/2.1/unity-catalog/shares/{name}` | Delete a share |
| GET | `/api/2.1/unity-catalog/shares/{name}/permissions` | Get share permissions |
| PATCH | `/api/2.1/unity-catalog/shares/{name}/permissions` | Update share permissions |

---

## Share CRUD

### List Shares

```
GET /api/2.1/unity-catalog/shares
```

**Optional:** `max_results` (int32, <=1000), `page_token` (string)

Returns all shares if `max_results` is not set.

**Response:** `200` — `shares[]` with `name`, `owner`, `comment`, `created_at`, `objects[]`, `storage_location`, `storage_root` + `next_page_token`

**Permissions:** USE_SHARE on metastore returns all; otherwise only owned shares

### Create a Share

```
POST /api/2.1/unity-catalog/shares
```

```json
{
  "name": "my_share",
  "comment": "Sales data share"
}
```

**Required:** `name`
**Optional:** `comment`, `storage_root`

**Response:** `200` — ShareInfo with `name`, `owner`, `comment`, `storage_root`, `storage_location`, `objects[]`, `created_at/by`, `updated_at/by`

**Permissions:** Metastore admin or CREATE_SHARE on metastore

### Get a Share

```
GET /api/2.1/unity-catalog/shares/{name}
```

**Required:** `name` (path)
**Optional:** `include_shared_data` (boolean — include object details)

**Response:** `200` — ShareInfo with `name`, `owner`, `comment`, `objects[]` (each with `data_object_type`, `name`, `shared_as`, `status`, `cdf_enabled`, `partitions`, `start_version`), `storage_location`, `storage_root`

**Permissions:** USE_SHARE on metastore OR share owner

### Update a Share

```
PATCH /api/2.1/unity-catalog/shares/{name}
```

```json
{
  "comment": "Updated description",
  "updates": [
    {
      "action": "ADD",
      "data_object": {
        "name": "catalog.schema.table",
        "data_object_type": "TABLE",
        "shared_as": "shared_table_name"
      }
    }
  ]
}
```

**Required:** `name` (path)
**Optional:** `comment`, `new_name`, `owner`, `storage_root`, `updates[]` (max 100 objects)

**`updates[].action`:** `ADD`, `REMOVE`, `UPDATE`

`storage_root` cannot be updated if the share contains notebook files.

**Response:** `200` — Updated ShareInfo

**Permissions:** Share owner or metastore admin. Adding tables requires SELECT on each table. Renaming requires owner + CREATE_SHARE. Metastore admins can only modify `owner`.

### Delete a Share

```
DELETE /api/2.1/unity-catalog/shares/{name}
```

**Required:** `name` (path)

**Response:** `200`

**Permissions:** Share owner

---

## Share Permissions

### Get Permissions

```
GET /api/2.1/unity-catalog/shares/{name}/permissions
```

**Required:** `name` (path)
**Optional:** `max_results` (int32, <=1000), `page_token`

**Response:** `200` — `privilege_assignments[]` with `principal` (string), `privileges[]` (SELECT, USE_SHARE, etc.)

**Permissions:** USE_SHARE on metastore OR share owner

### Update Permissions

```
PATCH /api/2.1/unity-catalog/shares/{name}/permissions
```

```json
{
  "changes": [
    {
      "principal": "recipient_name",
      "add": ["SELECT"],
      "remove": []
    }
  ]
}
```

**Required:** `name` (path), `changes[]`
**Optional:** `omit_permissions_list` (boolean — skip permissions in response)

**Response:** `200` — Updated `privilege_assignments[]`

**Permissions:** USE_SHARE + SET_SHARE_PERMISSION on metastore OR share owner. Granting to new recipients requires owning those recipients.
