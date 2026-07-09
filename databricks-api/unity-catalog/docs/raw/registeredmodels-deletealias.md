Title: Delete a Registered Model Alias | Registered Models API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/registeredmodels/deletealias

Markdown Content:
## Delete a Registered Model Alias

`DELETE/api/2.1/unity-catalog/models/{full_name}/aliases/{alias}`

Deletes a registered model alias.

The caller must be a metastore admin or an owner of the registered model. For the latter case, the caller must also be the owner or have the USE_CATALOG privilege on the parent catalog and the USE_SCHEMA privilege on the parent schema.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`full_name`](https://docs.databricks.com/api/workspace/registeredmodels/deletealias#full_name)required string

The three-level (fully qualified) name of the registered model

[`alias`](https://docs.databricks.com/api/workspace/registeredmodels/deletealias#alias)required string

The name of the alias

### Responses

**200** Request completed successfully.

Request completed successfully.
