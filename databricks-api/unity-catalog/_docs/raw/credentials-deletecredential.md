Title: Delete a credential | Credentials API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/credentials/deletecredential

Markdown Content:
## Delete a credential

`DELETE/api/2.1/unity-catalog/credentials/{name_arg}`

Deletes a service or storage credential from the metastore. The caller must be an owner of the credential.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`name_arg`](https://docs.databricks.com/api/workspace/credentials/deletecredential#name_arg)required string

Name of the credential.

### Query parameters

[`force`](https://docs.databricks.com/api/workspace/credentials/deletecredential#force)boolean

Force an update even if there are dependent services (when purpose is SERVICE) or dependent external locations and external tables (when purpose is STORAGE).

### Responses

**200** Request completed successfully.

Request completed successfully.

# Response samples

200

{}
