Title: Update permissions | Shares API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/shares/updatepermissions

Markdown Content:
## Update permissions

`PATCH/api/2.1/unity-catalog/shares/{name}/permissions`

Updates the permissions for a data share in the metastore. The caller must have both the USE_SHARE and SET_SHARE_PERMISSION privileges on the metastore, or be the owner of the share.

For new recipient grants, the user must also be the owner of the recipients. recipient revocations do not require additional privileges.

API scopes (preview):[`sharing`](https://docs.databricks.com/api/workspace/api/scopes#sharing)

### Path parameters

[`name`](https://docs.databricks.com/api/workspace/shares/updatepermissions#name)required string

The name of the share.

### Request body

[`changes`](https://docs.databricks.com/api/workspace/shares/updatepermissions#changes)Array of object

Array of permissions change objects.

Array [

[`add`](https://docs.databricks.com/api/workspace/shares/updatepermissions#changes-add)Array of string

The set of privileges to add.

[`principal`](https://docs.databricks.com/api/workspace/shares/updatepermissions#changes-principal)string

The principal whose privileges we are changing. Only one of principal or principal_id should be specified, never both at the same time.

[`remove`](https://docs.databricks.com/api/workspace/shares/updatepermissions#changes-remove)Array of string

The set of privileges to remove.

 ]

[`omit_permissions_list`](https://docs.databricks.com/api/workspace/shares/updatepermissions#omit_permissions_list)boolean

Optional. Whether to return the latest permissions list of the share in the response.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`privilege_assignments`](https://docs.databricks.com/api/workspace/shares/updatepermissions#privilege_assignments)Array of object

The privileges assigned to each principal

Array [

[`principal`](https://docs.databricks.com/api/workspace/shares/updatepermissions#privilege_assignments-principal)string

The principal (user email address or group name). For deleted principals, `principal` is empty while `principal_id` is populated.

[`privileges`](https://docs.databricks.com/api/workspace/shares/updatepermissions#privilege_assignments-privileges)Array of string

Array [

Enum: `SELECT | READ_PRIVATE_FILES | WRITE_PRIVATE_FILES | CREATE | USAGE | USE_CATALOG | USE_SCHEMA | CREATE_SCHEMA | CREATE_VIEW | CREATE_EXTERNAL_TABLE | CREATE_MATERIALIZED_VIEW | CREATE_FUNCTION | CREATE_MODEL | CREATE_CATALOG | CREATE_MANAGED_STORAGE | CREATE_EXTERNAL_LOCATION | CREATE_STORAGE_CREDENTIAL | CREATE_SERVICE_CREDENTIAL | ACCESS | CREATE_SHARE | CREATE_RECIPIENT | CREATE_PROVIDER | USE_SHARE | USE_RECIPIENT | USE_PROVIDER | USE_MARKETPLACE_ASSETS | SET_SHARE_PERMISSION | MODIFY | REFRESH | EXECUTE | READ_FILES | WRITE_FILES | CREATE_TABLE | ALL_PRIVILEGES | CREATE_CONNECTION | USE_CONNECTION | APPLY_TAG | CREATE_FOREIGN_CATALOG | CREATE_FOREIGN_SECURABLE | MANAGE_ALLOWLIST | CREATE_VOLUME | CREATE_EXTERNAL_VOLUME | READ_VOLUME | WRITE_VOLUME | MANAGE`

]

The privileges assigned to the principal.

 ]

# Request samples

JSON

{

"changes":[

{

"add":[

"string"

],

"principal":"string",

"remove":[

"string"

]

}

],

"omit_permissions_list":true

}

# Response samples

200

{

"privilege_assignments":[

{

"principal":"string",

"privileges":[

"SELECT"

]

}

]

}
