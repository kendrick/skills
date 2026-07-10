Title: Delete a function | Functions API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/functions/delete

Markdown Content:
## Delete a function

`DELETE/api/2.1/unity-catalog/functions/{name}`

Deletes the function that matches the supplied name. For the deletion to succeed, the user must satisfy one of the following conditions:

*   Is the owner of the function's parent catalog
*   Is the owner of the function's parent schema and have the USE_CATALOG privilege on its parent catalog
*   Is the owner of the function itself and have both the USE_CATALOG privilege on its parent catalog and the USE_SCHEMA privilege on its parent schema

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`name`](https://docs.databricks.com/api/workspace/functions/delete#name)required string

The fully-qualified name of the function (of the form catalog_name.schema_name.function__name) .

### Query parameters

[`force`](https://docs.databricks.com/api/workspace/functions/delete#force)boolean

Force deletion even if the function is notempty.

### Responses

**200** Request completed successfully.

Request completed successfully.
