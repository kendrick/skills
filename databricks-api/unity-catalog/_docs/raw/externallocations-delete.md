Title: Delete an external location | External Locations API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/externallocations/delete

Markdown Content:
## Delete an external location

`DELETE/api/2.1/unity-catalog/external-locations/{name}`

Deletes the specified external location from the metastore. The caller must be the owner of the external location.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`name`](https://docs.databricks.com/api/workspace/externallocations/delete#name)required string

Name of the external location.

### Query parameters

[`force`](https://docs.databricks.com/api/workspace/externallocations/delete#force)boolean

Force deletion even if there are dependent external tables or mounts.

### Responses

**200** Request completed successfully.

Request completed successfully.

# Response samples

200

{}
