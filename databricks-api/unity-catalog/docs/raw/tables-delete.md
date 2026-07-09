Title: Delete a table | Tables API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/tables/delete

Markdown Content:
## Delete a table

`DELETE/api/2.1/unity-catalog/tables/{full_name}`

Deletes a table from the specified parent catalog and schema. The caller must be the owner of the parent catalog, have the USE_CATALOG privilege on the parent catalog and be the owner of the parent schema, or be the owner of the table and have the USE_CATALOG privilege on the parent catalog and the USE_SCHEMA privilege on the parent schema.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`full_name`](https://docs.databricks.com/api/workspace/tables/delete#full_name)required string

Full name of the table.

### Responses

**200** Request completed successfully.

Request completed successfully.

# Response samples

200

{}
