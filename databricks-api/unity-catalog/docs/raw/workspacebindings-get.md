Title: Get catalog workspace bindings | Workspace Bindings API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/workspacebindings/get

Markdown Content:
## Get catalog workspace bindings

Deprecated

`GET/api/2.1/unity-catalog/workspace-bindings/catalogs/{name}`

Gets workspace bindings of the catalog. The caller must be a metastore admin or an owner of the catalog.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`name`](https://docs.databricks.com/api/workspace/workspacebindings/get#name)required string

The name of the catalog.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`workspaces`](https://docs.databricks.com/api/workspace/workspacebindings/get#workspaces)Array of int64

A list of workspace IDs

# Response samples

200

{

"workspaces":[

0

]

}
