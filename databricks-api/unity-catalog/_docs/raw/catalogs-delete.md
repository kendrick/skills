Title: Delete a catalog | Catalogs API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/catalogs/delete

Markdown Content:
## Delete a catalog

`DELETE/api/2.1/unity-catalog/catalogs/{name}`

Deletes the catalog that matches the supplied name. The caller must be a metastore admin or the owner of the catalog.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`name`](https://docs.databricks.com/api/workspace/catalogs/delete#name)required string

The name of the catalog.

### Query parameters

[`force`](https://docs.databricks.com/api/workspace/catalogs/delete#force)boolean

Force deletion even if the catalog is not empty.

### Responses

**200** Request completed successfully.

Request completed successfully.

# Response samples

200

{}
