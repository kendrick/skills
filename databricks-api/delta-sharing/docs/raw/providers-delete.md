Title: Delete a provider | Providers API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/providers/delete

Markdown Content:
## Delete a provider

`DELETE/api/2.1/unity-catalog/providers/{name}`

Deletes an authentication provider, if the caller is a metastore admin or is the owner of the provider.

API scopes (preview):[`sharing`](https://docs.databricks.com/api/workspace/api/scopes#sharing)

### Path parameters

[`name`](https://docs.databricks.com/api/workspace/providers/delete#name)required string

Name of the provider.

### Responses

**200** Request completed successfully.

Request completed successfully.
