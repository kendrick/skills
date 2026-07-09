Title: Delete a metastore | Metastores API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/metastores/delete

Markdown Content:
## Delete a metastore

`DELETE/api/2.1/unity-catalog/metastores/{id}`

Deletes a metastore. The caller must be a metastore admin.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`id`](https://docs.databricks.com/api/workspace/metastores/delete#id)required string

Unique ID of the metastore.

### Query parameters

[`force`](https://docs.databricks.com/api/workspace/metastores/delete#force)boolean

Force deletion even if the metastore is not empty. Default is false.

### Responses

**200** Request completed successfully.

Request completed successfully.

# Response samples

200

{}
