Title: Delete a share | Shares API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/shares/delete

Markdown Content:
## Delete a share

`DELETE/api/2.1/unity-catalog/shares/{name}`

Deletes a data object share from the metastore. The caller must be an owner of the share.

API scopes (preview):[`sharing`](https://docs.databricks.com/api/workspace/api/scopes#sharing)

### Path parameters

[`name`](https://docs.databricks.com/api/workspace/shares/delete#name)required string

The name of the share.

### Responses

**200** Request completed successfully.

Request completed successfully.
