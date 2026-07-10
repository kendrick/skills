Title: Delete a share recipient | Recipients API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/recipients/delete

Markdown Content:
## Delete a share recipient

`DELETE/api/2.1/unity-catalog/recipients/{name}`

Deletes the specified recipient from the metastore. The caller must be the owner of the recipient.

API scopes (preview):[`sharing`](https://docs.databricks.com/api/workspace/api/scopes#sharing)

### Path parameters

[`name`](https://docs.databricks.com/api/workspace/recipients/delete#name)required string

Name of the recipient.

### Responses

**200** Request completed successfully.

Request completed successfully.
