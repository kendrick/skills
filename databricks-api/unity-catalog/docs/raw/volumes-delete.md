Title: Delete a Volume | Volumes API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/volumes/delete

Markdown Content:
## Delete a Volume

`DELETE/api/2.1/unity-catalog/volumes/{name}`

Deletes a volume from the specified parent catalog and schema.

The caller must be a metastore admin or an owner of the volume. For the latter case, the caller must also be the owner or have the USE_CATALOG privilege on the parent catalog and the USE_SCHEMA privilege on the parent schema.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`name`](https://docs.databricks.com/api/workspace/volumes/delete#name)required string

The three-level (fully qualified) name of the volume

### Responses

**200** Request completed successfully.

Request completed successfully.
