Title: Enable a system schema | SystemSchemas API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/systemschemas/enable

Markdown Content:
## Enable a system schema

Public preview

`PUT/api/2.1/unity-catalog/metastores/{metastore_id}/systemschemas/{schema_name}`

Enables the system schema and adds it to the system catalog. The caller must be an account admin or a metastore admin.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`metastore_id`](https://docs.databricks.com/api/workspace/systemschemas/enable#metastore_id)required string

The metastore ID under which the system schema lives.

[`schema_name`](https://docs.databricks.com/api/workspace/systemschemas/enable#schema_name)required string

Full name of the system schema.

### Request body

[`catalog_name`](https://docs.databricks.com/api/workspace/systemschemas/enable#catalog_name)string

the catalog for which the system schema is to enabled in

### Responses

**200** Request completed successfully.

Request completed successfully.

# Request samples

JSON

{

"catalog_name":"string"

}

# Response samples

200

{}
