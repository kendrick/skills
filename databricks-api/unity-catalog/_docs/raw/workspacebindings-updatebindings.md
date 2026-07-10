Title: Update securable workspace bindings | Workspace Bindings API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/workspacebindings/updatebindings

Markdown Content:
## Update securable workspace bindings

`PATCH/api/2.1/unity-catalog/bindings/{securable_type}/{securable_name}`

Updates workspace bindings of the securable. The caller must be a metastore admin or an owner of the securable.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`securable_type`](https://docs.databricks.com/api/workspace/workspacebindings/updatebindings#securable_type)required string

The type of the securable to bind to a workspace (catalog, storage_credential, credential, or external_location).

[`securable_name`](https://docs.databricks.com/api/workspace/workspacebindings/updatebindings#securable_name)required string

The name of the securable.

### Request body

[`add`](https://docs.databricks.com/api/workspace/workspacebindings/updatebindings#add)Array of object

List of workspace bindings to add. If a binding for the workspace already exists with a different binding_type, adding it again with a new binding_type will update the existing binding (e.g., from READ_WRITE to READ_ONLY).

Array [

[`binding_type`](https://docs.databricks.com/api/workspace/workspacebindings/updatebindings#add-binding_type)string

Enum: `BINDING_TYPE_READ_WRITE | BINDING_TYPE_READ_ONLY`

One of READ_WRITE/READ_ONLY. Default is READ_WRITE.

[`workspace_id`](https://docs.databricks.com/api/workspace/workspacebindings/updatebindings#add-workspace_id)required int64

Required

 ]

[`remove`](https://docs.databricks.com/api/workspace/workspacebindings/updatebindings#remove)Array of object

List of workspace bindings to remove.

Array [

[`binding_type`](https://docs.databricks.com/api/workspace/workspacebindings/updatebindings#remove-binding_type)string

Enum: `BINDING_TYPE_READ_WRITE | BINDING_TYPE_READ_ONLY`

One of READ_WRITE/READ_ONLY. Default is READ_WRITE.

[`workspace_id`](https://docs.databricks.com/api/workspace/workspacebindings/updatebindings#remove-workspace_id)required int64

Required

 ]

### Responses

**200** Request completed successfully.

Request completed successfully.

[`bindings`](https://docs.databricks.com/api/workspace/workspacebindings/updatebindings#bindings)Array of object

List of workspace bindings.

Array [

[`binding_type`](https://docs.databricks.com/api/workspace/workspacebindings/updatebindings#bindings-binding_type)string

Enum: `BINDING_TYPE_READ_WRITE | BINDING_TYPE_READ_ONLY`

One of READ_WRITE/READ_ONLY. Default is READ_WRITE.

[`workspace_id`](https://docs.databricks.com/api/workspace/workspacebindings/updatebindings#bindings-workspace_id)int64

Required

 ]

# Request samples

JSON

{

"add":[

{

"binding_type":"BINDING_TYPE_READ_WRITE",

"workspace_id":0

}

],

"remove":[

{

"binding_type":"BINDING_TYPE_READ_WRITE",

"workspace_id":0

}

]

}

# Response samples

200

{

"bindings":[

{

"binding_type":"BINDING_TYPE_READ_WRITE",

"workspace_id":0

}

]

}
