Title: Delete an assignment | Metastores API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/metastores/unassign

Markdown Content:
## Delete an assignment

`DELETE/api/2.1/unity-catalog/workspaces/{workspace_id}/metastore`

Deletes a metastore assignment. The caller must be an account administrator.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`workspace_id`](https://docs.databricks.com/api/workspace/metastores/unassign#workspace_id)required int64

A workspace ID.

### Query parameters

[`metastore_id`](https://docs.databricks.com/api/workspace/metastores/unassign#metastore_id)required string

Query for the ID of the metastore to delete.

### Responses

**200** Request completed successfully.

Request completed successfully.

# Response samples

200

{}
