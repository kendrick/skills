Title: Delete a credential | Storage Credentials API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/storagecredentials/delete

Markdown Content:
## Delete a credential

`DELETE/api/2.1/unity-catalog/storage-credentials/{name}`

Deletes a storage credential from the metastore. The caller must be an owner of the storage credential.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`name`](https://docs.databricks.com/api/workspace/storagecredentials/delete#name)required string

Name of the storage credential.

### Query parameters

[`force`](https://docs.databricks.com/api/workspace/storagecredentials/delete#force)boolean

Force an update even if there are dependent external locations or external tables (when purpose is STORAGE) or dependent services (when purpose is SERVICE).

### Responses

**200** Request completed successfully.

Request completed successfully.

# Response samples

200

{}
