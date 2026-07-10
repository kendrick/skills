Title: Delete a Registered Model | Registered Models API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/registeredmodels/delete

Markdown Content:
## Delete a Registered Model

`DELETE/api/2.1/unity-catalog/models/{full_name}`

Deletes a registered model and all its model versions from the specified parent catalog and schema.

The caller must be a metastore admin or an owner of the registered model. For the latter case, the caller must also be the owner or have the USE_CATALOG privilege on the parent catalog and the USE_SCHEMA privilege on the parent schema.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`full_name`](https://docs.databricks.com/api/workspace/registeredmodels/delete#full_name)required string

The three-level (fully qualified) name of the registered model

### Responses

**200** Request completed successfully.

Request completed successfully.
