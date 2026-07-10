Title: Update an assignment | Metastores API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/metastores/updateassignment

Markdown Content:
## Update an assignment

`PATCH/api/2.1/unity-catalog/workspaces/{workspace_id}/metastore`

Updates a metastore assignment. This operation can be used to update metastore_id or default_catalog_name for a specified Workspace, if the Workspace is already assigned a metastore. The caller must be an account admin to update metastore_id; otherwise, the caller can be a Workspace admin.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`workspace_id`](https://docs.databricks.com/api/workspace/metastores/updateassignment#workspace_id)required int64

A workspace ID.

### Request body

[`default_catalog_name`](https://docs.databricks.com/api/workspace/metastores/updateassignment#default_catalog_name)string

The name of the default catalog in the metastore. This field is deprecated. Please use "Default Namespace API" to configure the default catalog for a Databricks workspace.

[`metastore_id`](https://docs.databricks.com/api/workspace/metastores/updateassignment#metastore_id)string

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
