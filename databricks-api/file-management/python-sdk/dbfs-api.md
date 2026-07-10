# DBFS API -- Databricks Python SDK

> **DBFS is legacy. Prefer the Files API (`w.files`) for new work.**

> Raw docs: ../_docs/raw/ -- for full endpoint details, read dbfs-{operation}.md

> Package: `databricks-sdk`

## Setup

```python
from databricks.sdk import WorkspaceClient
w = WorkspaceClient()  # uses DATABRICKS_HOST + DATABRICKS_TOKEN env vars
# All DBFS operations: w.dbfs.*
```

## SDK Client Map

| Operation | Method |
|-----------|--------|
| Upload small file | `w.dbfs.put(path, contents, overwrite)` |
| Read file chunk | `w.dbfs.read(path, offset, length)` |
| Open stream | `w.dbfs.create(path, overwrite)` |
| Append block | `w.dbfs.add_block(handle, data)` |
| Close stream | `w.dbfs.close(handle)` |
| Delete | `w.dbfs.delete(path, recursive)` |
| Move | `w.dbfs.move(source_path, destination_path)` |
| Get status | `w.dbfs.get_status(path)` |
| List directory | `w.dbfs.list(path)` |
| Create directory | `w.dbfs.mkdirs(path)` |

---

## 1. Simple Upload / Download

```python
import base64

# Upload small file (<=1 MB content)
data = base64.b64encode(b"col1,col2\na,b").decode()
w.dbfs.put(path="/mnt/data/file.csv", contents=data, overwrite=True)

# Read file (returns base64-encoded data)
resp = w.dbfs.read(path="/mnt/data/file.csv", offset=0, length=524288)
content = base64.b64decode(resp.data)
```

Read returns max 1 MB per call. Loop with offset for larger files:

```python
offset, buf = 0, b""
while True:
    resp = w.dbfs.read(path="/mnt/data/large.csv", offset=offset, length=1048576)
    chunk = base64.b64decode(resp.data)
    buf += chunk
    if resp.bytes_read < 1048576:
        break
    offset += resp.bytes_read
```

---

## 2. Streaming Upload (files > 1 MB)

```python
import base64

CHUNK = 1024 * 1024  # 1 MB max per block

# Step 1: Open stream
handle = w.dbfs.create(path="/mnt/data/large.parquet", overwrite=True).handle

# Step 2: Append blocks
with open("large.parquet", "rb") as f:
    while True:
        chunk = f.read(CHUNK)
        if not chunk:
            break
        w.dbfs.add_block(handle=handle, data=base64.b64encode(chunk).decode())

# Step 3: Close
w.dbfs.close(handle=handle)
```

Handle has a **10-minute idle timeout**.

---

## 3. File Operations

```python
# Delete file
w.dbfs.delete(path="/mnt/data/old.csv")

# Delete directory recursively
w.dbfs.delete(path="/mnt/data/tmpdir", recursive=True)

# Move / rename
w.dbfs.move(source_path="/mnt/data/old.csv", destination_path="/mnt/data/new.csv")

# Get file info
info = w.dbfs.get_status(path="/mnt/data/file.csv")
# info.path, info.is_dir, info.file_size, info.modification_time
```

---

## 4. Directory Operations

```python
# List directory
for f in w.dbfs.list(path="/mnt/data"):
    print(f.path, f.file_size, f.is_dir)

# Create directory (parents created automatically)
w.dbfs.mkdirs(path="/mnt/data/subdir/nested")
```

List times out at ~60s for directories with >10K files. Use dbutils.fs in notebooks for large dirs.

---

## Common Patterns

### Upload local file of any size

```python
import base64, os

def upload_file(w, local_path: str, dbfs_path: str):
    size = os.path.getsize(local_path)
    if size <= 1024 * 1024:
        with open(local_path, "rb") as f:
            w.dbfs.put(path=dbfs_path, contents=base64.b64encode(f.read()).decode(), overwrite=True)
    else:
        handle = w.dbfs.create(path=dbfs_path, overwrite=True).handle
        with open(local_path, "rb") as f:
            while chunk := f.read(1024 * 1024):
                w.dbfs.add_block(handle=handle, data=base64.b64encode(chunk).decode())
        w.dbfs.close(handle=handle)
```

---

## Gotchas

1. **All data is base64-encoded** -- both upload and download require base64 encode/decode
2. **1 MB limit** per put, add_block, and read call
3. **Streaming handle**: 10-min idle timeout; always close handles in try/finally
4. **Paths must be absolute DBFS paths** (`/mnt/...`, `/FileStore/...`)
5. **Large deletes** (>10K files): may raise 503; retry or use dbutils.fs
6. **List timeout**: ~60s for large directories
7. **DBFS is legacy** -- `w.files` (Files API) supports direct binary without base64
