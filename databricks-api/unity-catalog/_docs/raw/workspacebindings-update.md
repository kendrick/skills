Title: Update catalog workspace bindings | Workspace Bindings API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/workspacebindings/update

Markdown Content:
## Update catalog workspace bindings

Deprecated

`PATCH/api/2.1/unity-catalog/workspace-bindings/catalogs/{name}`

Updates workspace bindings of the catalog. The caller must be a metastore admin or an owner of the catalog.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`name`](https://docs.databricks.com/api/workspace/workspacebindings/update#name)required string

The name of the catalog.

### Request body

[`assign_workspaces`](https://docs.databricks.com/api/workspace/workspacebindings/update#assign_workspaces)Array of int64

A list of workspace IDs.

[`unassign_workspaces`](https://docs.databricks.com/api/workspace/workspacebindings/update#unassign_workspaces)Array of int64

A list of workspace IDs.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`workspaces`](https://docs.databricks.com/api/workspace/workspacebindings/update#workspaces)Array of int64

A list of workspace IDs

# Request samples

JSON

{

"assign_workspaces":[

0

],

"unassign_workspaces":[

0

]

}

# Response samples

200

{

"workspaces":[

0

]

}
