# Files API -- Databricks REST API

Upload, download, delete, and manage files and directories on Unity Catalog volumes and workspace paths.

> See also: dbfs-api (for legacy DBFS operations)
> Raw docs: ../_docs/raw/ -- for full endpoint details, read files-{operation}.md

**Status:** Public preview
**API scope:** `files`
**Base:** `https://{workspace}.cloud.databricks.com`

## Auth

```
Authorization: Bearer {token}
```

Token: PAT, OAuth M2M, or OAuth U2M. Scope: `files`.

## Endpoint Summary

| Method | Path | Purpose |
|--------|------|---------|
| PUT | `/api/2.0/fs/files{file_path}` | Upload a file |
| GET | `/api/2.0/fs/files{file_path}` | Download a file |
| DELETE | `/api/2.0/fs/files{file_path}` | Delete a file |
| HEAD | `/api/2.0/fs/files{file_path}` | Get file metadata |
| PUT | `/api/2.0/fs/directories{directory_path}` | Create a directory |
| GET | `/api/2.0/fs/directories{directory_path}` | List directory contents |
| HEAD | `/api/2.0/fs/directories{directory_path}` | Get directory metadata |
| DELETE | `/api/2.0/fs/directories{directory_path}` | Delete a directory |

Path format: `/Volumes/{catalog}/{schema}/{volume}/path/to/target`

---

## Files

### Upload a file

```
PUT /api/2.0/fs/files/Volumes/cat/sch/vol/data.csv?overwrite=true
Content-Type: application/octet-stream

<raw bytes>
```

- **file_path** (required, string): absolute path in URL
- **overwrite** (optional, bool, query): default true. Set `false` to fail if file exists
- Max file size: **5 GiB**
- Body: raw bytes (octet stream) -- do NOT encode
- Response: **204** No Content

### Download a file

```
GET /api/2.0/fs/files/Volumes/cat/sch/vol/data.csv
```

- **file_path** (required, string): absolute path in URL
- **Range** (optional, header): e.g. `bytes=0-499` for partial download (returns 206)
- **If-Unmodified-Since** (optional, header): conditional; returns 412 if modified
- Response: **200** body = file bytes. Headers: `content-length`, `content-type`, `last-modified`

### Delete a file

```
DELETE /api/2.0/fs/files/Volumes/cat/sch/vol/data.csv
```

- **file_path** (required, string)
- Response: **204** No Content

### Get file metadata

```
HEAD /api/2.0/fs/files/Volumes/cat/sch/vol/data.csv
```

- **file_path** (required, string)
- **Range**, **If-Unmodified-Since** (optional, headers): same as download
- Response: **200** no body. Headers: `content-length`, `content-type`, `last-modified`

---

## Directories

### Create a directory

```
PUT /api/2.0/fs/directories/Volumes/cat/sch/vol/new-dir/
```

- **directory_path** (required, string)
- Creates parent dirs automatically (like `mkdir -p`). Idempotent.
- Response: **204** No Content

### List directory contents

```
GET /api/2.0/fs/directories/Volumes/cat/sch/vol/my-dir/?page_size=100
```

- **directory_path** (required, string)
- **page_size** (optional, int64, query): default 1000, max 1000
- **page_token** (optional, string, query): for pagination
- Response: **200** JSON `{ "contents": [{ "name", "path", "is_directory", "file_size", "last_modified" }], "next_page_token" }`
- Paginate until `next_page_token` is absent

### Get directory metadata

```
HEAD /api/2.0/fs/directories/Volumes/cat/sch/vol/my-dir/
```

- **directory_path** (required, string)
- Response: **200** no body. Use to check existence/access.

### Delete a directory

```
DELETE /api/2.0/fs/directories/Volumes/cat/sch/vol/my-dir/
```

- **directory_path** (required, string)
- **Only deletes empty directories.** List contents and delete children recursively first.
- Response: **204** No Content

---

## Common Errors

| HTTP | error_code | Meaning |
|------|-----------|---------|
| 400 | BAD_REQUEST | Invalid request or path |
| 401 | UNAUTHENTICATED | Missing/invalid credentials |
| 403 | PERMISSION_DENIED | Insufficient privileges |
| 404 | NOT_FOUND | File/directory does not exist |
| 409 | RESOURCE_CONFLICT | Conflict (e.g. non-empty dir delete, file exists with overwrite=false) |
| 412 | PRECONDITION_FAILED | If-Unmodified-Since condition failed |
| 500 | INTERNAL_ERROR | Server error |

## Gotchas

- Paths in URL are **not** JSON body fields -- they are embedded in the URL path after `/fs/files` or `/fs/directories`.
- Upload body must be **raw bytes**, not JSON or multipart. Set `Content-Type: application/octet-stream`.
- Directory delete only works on **empty** directories -- no recursive flag exists.
- `PUT` for directories is **idempotent** -- safe to call on existing dirs.
- `overwrite` defaults to **true** on upload; set `false` explicitly to prevent overwrites.
- Directory list returns max 1000 items per page; always paginate via `next_page_token`.
