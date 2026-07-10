Title: Disable a system schema | SystemSchemas API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/systemschemas/disable

Markdown Content:
## Disable a system schema

Public preview

`DELETE/api/2.1/unity-catalog/metastores/{metastore_id}/systemschemas/{schema_name}`

Disables the system schema and removes it from the system catalog. The caller must be an account admin or a metastore admin.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`metastore_id`](https://docs.databricks.com/api/workspace/systemschemas/disable#metastore_id)required string

The metastore ID under which the system schema lives.

[`schema_name`](https://docs.databricks.com/api/workspace/systemschemas/disable#schema_name)required string

Full name of the system schema.

### Responses

**200** Request completed successfully.

Request completed successfully.

# Response samples

200

{}
