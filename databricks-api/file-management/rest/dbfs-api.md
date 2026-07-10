# DBFS API -- Databricks REST API

Legacy DBFS file operations -- streaming upload/download, directory management, file metadata.

> **DBFS is legacy. Prefer the Files API for new work.**

> See also: files-api (modern replacement -- supports direct binary upload, no base64 encoding)

> Raw docs: ../_docs/raw/ -- for full endpoint details, read dbfs-{operation}.md

## Auth

All endpoints require Bearer token or Databricks PAT. API scope: `files`.

```
Authorization: Bearer <token>
```

## Endpoint Summary

| Method | Path | Purpose |
|--------|------|---------|
| POST | /api/2.0/dbfs/put | Upload file (<=1 MB) |
| GET | /api/2.0/dbfs/read | Read file chunk (<=1 MB) |
| POST | /api/2.0/dbfs/create | Open streaming upload handle |
| POST | /api/2.0/dbfs/add-block | Append base64 block to stream |
| POST | /api/2.0/dbfs/close | Close streaming upload handle |
| POST | /api/2.0/dbfs/delete | Delete file or directory |
| POST | /api/2.0/dbfs/move | Move/rename file or directory |
| GET | /api/2.0/dbfs/get-status | Get file/directory metadata |
| GET | /api/2.0/dbfs/list | List directory contents |
| POST | /api/2.0/dbfs/mkdirs | Create directory (recursive) |

---

## 1. Simple Upload / Download

### PUT (upload small file)

```
POST /api/2.0/dbfs/put
```

```json
{"path": "/mnt/data/file.csv", "contents": "<base64-encoded>", "overwrite": true}
```

- **path** (string, required): absolute DBFS path
- **contents** (string, optional): base64-encoded file content -- **max 1 MB**
- **overwrite** (bool, optional, default false): overwrite existing file

For files > 1 MB, use the streaming upload pattern instead.

### READ (download chunk)

```
GET /api/2.0/dbfs/read?path=/mnt/data/file.csv&offset=0&length=524288
```

Response:

```json
{"bytes_read": 524288, "data": "<base64-encoded>"}
```

- **path** (string, required): absolute DBFS path
- **offset** (int64, optional, default 0): byte offset
- **length** (int64, optional, default 1MB): bytes to read, max 1 MB

Data returned is base64-encoded. Loop with offset to read full file.

---

## 2. Streaming Upload (files > 1 MB)

Three-step pattern: create -> add-block (repeat) -> close.

### Step 1: Create stream

```
POST /api/2.0/dbfs/create
{"path": "/mnt/data/large.parquet", "overwrite": true}
```

Response: `{"handle": 123456}`

- **path** (string, required): absolute DBFS path
- **overwrite** (bool, optional, default false)
- Handle has **10-minute idle timeout**

### Step 2: Append blocks

```
POST /api/2.0/dbfs/add-block
{"handle": 123456, "data": "<base64-encoded-chunk>"}
```

- **handle** (int64, required): from create
- **data** (string, required): base64-encoded, **max 1 MB per block**

### Step 3: Close stream

```
POST /api/2.0/dbfs/close
{"handle": 123456}
```

- **handle** (int64, required)

---

## 3. File Operations

### DELETE

```
POST /api/2.0/dbfs/delete
{"path": "/mnt/data/old.csv", "recursive": false}
```

- **path** (string, required)
- **recursive** (bool, optional, default false): required for non-empty directories
- Large deletes (>10K files) may return 503 -- retry until complete. Use dbutils.fs for bulk deletes.

### MOVE

```
POST /api/2.0/dbfs/move
{"source_path": "/mnt/data/old.csv", "destination_path": "/mnt/data/new.csv"}
```

- **source_path** (string, required)
- **destination_path** (string, required)
- Directories move recursively. Fails with RESOURCE_ALREADY_EXISTS if destination exists.

### GET-STATUS

```
GET /api/2.0/dbfs/get-status?path=/mnt/data/file.csv
```

Response: `{"path": "...", "is_dir": false, "file_size": 1024, "modification_time": 1609459200000}`

- **path** (string, required)

---

## 4. Directory Operations

### LIST

```
GET /api/2.0/dbfs/list?path=/mnt/data
```

Response: `{"files": [{"path": "...", "is_dir": false, "file_size": 1024, "modification_time": 0}]}`

- **path** (string, required)
- Times out after ~60s. Do not use for directories with >10K files; use dbutils.fs instead.

### MKDIRS

```
POST /api/2.0/dbfs/mkdirs
{"path": "/mnt/data/subdir"}
```

- **path** (string, required)
- Creates parent directories automatically. Fails with RESOURCE_ALREADY_EXISTS if a file exists at any prefix.

---

## Common Errors

| HTTP | error_code | Meaning |
|------|-----------|---------|
| 400 | BAD_REQUEST | Invalid request |
| 401 | UNAUTHORIZED | Bad/missing credentials |
| 404 | NOT_FOUND / RESOURCE_DOES_NOT_EXIST | Path not found |
| 409 | RESOURCE_ALREADY_EXISTS | Destination exists (move/create) |
| 500 | INTERNAL_SERVER_ERROR | Server error |
| 503 | Service Unavailable | Large delete in progress -- retry |

## Gotchas

1. **All data is base64-encoded** -- both upload (put/add-block) and download (read) use base64
2. **1 MB limit** on put contents, add-block data, and read length per call
3. **Streaming handle timeout**: 10 minutes idle on create handle
4. **All paths must be absolute DBFS paths** (e.g., `/mnt/...`, `/FileStore/...`)
5. **List/delete timeout**: list >10K files times out at ~60s; large deletes return 503
6. **DBFS is legacy** -- the Files API supports direct binary streaming without base64
