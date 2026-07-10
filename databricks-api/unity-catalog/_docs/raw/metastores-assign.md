Title: Create an assignment | Metastores API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/metastores/assign

Markdown Content:
## Create an assignment

`PUT/api/2.1/unity-catalog/workspaces/{workspace_id}/metastore`

Creates a new metastore assignment. If an assignment for the same workspace_id exists, it will be overwritten by the new metastore_id and default_catalog_name. The caller must be an account admin.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`workspace_id`](https://docs.databricks.com/api/workspace/metastores/assign#workspace_id)required int64

A workspace ID.

### Request body

[`default_catalog_name`](https://docs.databricks.com/api/workspace/metastores/assign#default_catalog_name)required string

Deprecated

The name of the default catalog in the metastore. This field is deprecated. Please use "Default Namespace API" to configure the default catalog for a Databricks workspace.

[`metastore_id`](https://docs.databricks.com/api/workspace/metastores/assign#metastore_id)required string

The unique ID of the metastore.

### Responses

**200** Request completed successfully.

Request completed successfully.

# Request samples

JSON

{

"default_catalog_name":"string",

"metastore_id":"string"

}

# Response samples

200

{}
