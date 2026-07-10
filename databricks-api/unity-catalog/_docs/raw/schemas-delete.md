Title: Delete a schema | Schemas API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/schemas/delete

Markdown Content:
## Delete a schema

`DELETE/api/2.1/unity-catalog/schemas/{full_name}`

Deletes the specified schema from the parent catalog. The caller must be the owner of the schema or an owner of the parent catalog.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`full_name`](https://docs.databricks.com/api/workspace/schemas/delete#full_name)required string

Full name of the schema.

### Query parameters

[`force`](https://docs.databricks.com/api/workspace/schemas/delete#force)boolean

Force deletion even if the schema is not empty.

### Responses

**200** Request completed successfully.

Request completed successfully.

# Response samples

200

{}
