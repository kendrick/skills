# Files API -- Databricks Python SDK

Upload, download, delete, and manage files and directories on Unity Catalog volumes and workspace paths.

> Raw docs: ../docs/raw/ -- for full endpoint details, read files-{operation}.md
> Package: `databricks-sdk` (`pip install databricks-sdk`)

## Setup

```python
from databricks.sdk import WorkspaceClient

w = WorkspaceClient()  # uses DATABRICKS_HOST + DATABRICKS_TOKEN env vars
# or: WorkspaceClient(host="https://xxx.cloud.databricks.com", token="dapi...")
```

**Client map:** all operations are under `w.files`.

| SDK Method | REST Equivalent |
|-----------|----------------|
| `w.files.upload(...)` | PUT /fs/files |
| `w.files.download(...)` | GET /fs/files |
| `w.files.delete(...)` | DELETE /fs/files |
| `w.files.get_metadata(...)` | HEAD /fs/files |
| `w.files.create_directory(...)` | PUT /fs/directories |
| `w.files.list_directory_contents(...)` | GET /fs/directories |
| `w.files.get_directory_metadata(...)` | HEAD /fs/directories |
| `w.files.delete_directory(...)` | DELETE /fs/directories |

---

## Files

### Upload a file

```python
import io

data = b"col1,col2\na,1\nb,2"
w.files.upload(
    file_path="/Volumes/cat/sch/vol/data.csv",
    contents=io.BytesIO(data),
    overwrite=True  # default; set False to fail if exists
)
```

- **file_path** (str, required): absolute volume/workspace path
- **contents** (BinaryIO, required): file-like object
- **overwrite** (bool, optional): default True
- Max size: 5 GiB

### Download a file

```python
resp = w.files.download(file_path="/Volumes/cat/sch/vol/data.csv")
content = resp.contents.read()  # bytes
# resp.content_length, resp.content_type, resp.last_modified also available
```

- **file_path** (str, required)
- Returns a `DownloadResponse` with `.contents` (readable stream) and metadata headers

### Delete a file

```python
w.files.delete(file_path="/Volumes/cat/sch/vol/data.csv")
```

- **file_path** (str, required)

### Get file metadata

```python
meta = w.files.get_metadata(file_path="/Volumes/cat/sch/vol/data.csv")
# meta.content_length, meta.content_type, meta.last_modified
```

- **file_path** (str, required)
- No file content returned -- headers only

---

## Directories

### Create a directory

```python
w.files.create_directory(directory_path="/Volumes/cat/sch/vol/new-dir/")
```

- **directory_path** (str, required)
- Creates parents automatically. Idempotent (succeeds if dir exists).

### List directory contents

```python
for entry in w.files.list_directory_contents(
    directory_path="/Volumes/cat/sch/vol/my-dir/"
):
    print(entry.name, entry.is_directory, entry.file_size, entry.last_modified)
```

- **directory_path** (str, required)
- **page_size** (int, optional): default 1000, max 1000
- Returns iterator -- SDK handles pagination automatically

### Get directory metadata

```python
w.files.get_directory_metadata(
    directory_path="/Volumes/cat/sch/vol/my-dir/"
)
# No return value; raises error if dir doesn't exist
```

- **directory_path** (str, required)
- Use to check if a directory exists and caller has access

### Delete a directory

```python
w.files.delete_directory(directory_path="/Volumes/cat/sch/vol/my-dir/")
```

- **directory_path** (str, required)
- **Only empty directories.** Delete contents recursively first.

---

## Common Patterns

### Recursive directory delete

```python
def delete_recursive(w, path):
    for entry in w.files.list_directory_contents(directory_path=path):
        if entry.is_directory:
            delete_recursive(w, entry.path + "/")
        else:
            w.files.delete(file_path=entry.path)
    w.files.delete_directory(directory_path=path)
```

### Upload from local file

```python
with open("local.csv", "rb") as f:
    w.files.upload(file_path="/Volumes/cat/sch/vol/local.csv", contents=f)
```

## Gotchas

- `contents` for upload must be a **binary file-like object** (BytesIO or `open(..., "rb")`), not raw bytes or str.
- `list_directory_contents` returns an **iterator** that auto-paginates -- do not manually pass `page_token`.
- `delete_directory` only works on **empty** directories -- no recursive flag. Use the pattern above.
- `create_directory` is **idempotent** -- safe to call on existing dirs.
- Paths must start with `/Volumes/` for UC volumes or `/Workspace/` for workspace files.
- `download()` returns a response object; call `.contents.read()` to get bytes.
