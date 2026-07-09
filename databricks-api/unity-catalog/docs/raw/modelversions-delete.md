Title: Delete a Model Version | Model Versions API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/modelversions/delete

Markdown Content:
## Delete a Model Version

`DELETE/api/2.1/unity-catalog/models/{full_name}/versions/{version}`

Deletes a model version from the specified registered model. Any aliases assigned to the model version will also be deleted.

The caller must be a metastore admin or an owner of the parent registered model. For the latter case, the caller must also be the owner or have the USE_CATALOG privilege on the parent catalog and the USE_SCHEMA privilege on the parent schema.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`full_name`](https://docs.databricks.com/api/workspace/modelversions/delete#full_name)required string

The three-level (fully qualified) name of the model version

[`version`](https://docs.databricks.com/api/workspace/modelversions/delete#version)required int32

The integer version number of the model version

### Responses

**200** Request completed successfully.

Request completed successfully.
