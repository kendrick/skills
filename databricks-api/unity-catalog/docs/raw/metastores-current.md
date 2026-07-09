Title: Get metastore assignment for workspace | Metastores API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/metastores/current

Markdown Content:
## Get metastore assignment for workspace

`GET/api/2.1/unity-catalog/current-metastore-assignment`

Gets the metastore assignment for the workspace being accessed.

API scopes:[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Responses

**200** Request completed successfully.

Request completed successfully.

[`default_catalog_name`](https://docs.databricks.com/api/workspace/metastores/current#default_catalog_name)string

Deprecated

The name of the default catalog in the metastore. This field is deprecated. Please use "Default Namespace API" to configure the default catalog for a Databricks workspace.

[`metastore_id`](https://docs.databricks.com/api/workspace/metastores/current#metastore_id)string

The unique ID of the metastore.

[`workspace_id`](https://docs.databricks.com/api/workspace/metastores/current#workspace_id)int64

The unique ID of the Databricks workspace.

# Response samples

200

{

"default_catalog_name":"string",

"metastore_id":"string",

"workspace_id":0

}
