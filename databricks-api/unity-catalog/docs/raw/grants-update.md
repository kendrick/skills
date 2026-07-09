Title: Update permissions | Grants API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/grants/update

Markdown Content:
## Update permissions

`PATCH/api/2.1/unity-catalog/permissions/{securable_type}/{full_name}`

Updates the permissions for a securable.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`securable_type`](https://docs.databricks.com/api/workspace/grants/update#securable_type)required string

Type of securable.

[`full_name`](https://docs.databricks.com/api/workspace/grants/update#full_name)required string

Full name of securable.

### Request body

[`changes`](https://docs.databricks.com/api/workspace/grants/update#changes)Array of object

Array of permissions change objects.

Array [

[`add`](https://docs.databricks.com/api/workspace/grants/update#changes-add)Array of string

Array [

Enum: `SELECT | READ_PRIVATE_FILES | WRITE_PRIVATE_FILES | CREATE | USAGE | USE_CATALOG | USE_SCHEMA | CREATE_SCHEMA | CREATE_VIEW | CREATE_EXTERNAL_TABLE | CREATE_MATERIALIZED_VIEW | CREATE_FUNCTION | CREATE_MODEL | CREATE_CATALOG | CREATE_MANAGED_STORAGE | CREATE_EXTERNAL_LOCATION | CREATE_STORAGE_CREDENTIAL | CREATE_SERVICE_CREDENTIAL | ACCESS | CREATE_SHARE | CREATE_RECIPIENT | CREATE_PROVIDER | USE_SHARE | USE_RECIPIENT | USE_PROVIDER | USE_MARKETPLACE_ASSETS | SET_SHARE_PERMISSION | MODIFY | REFRESH | EXECUTE | READ_FILES | WRITE_FILES | CREATE_TABLE | ALL_PRIVILEGES | CREATE_CONNECTION | USE_CONNECTION | APPLY_TAG | CREATE_FOREIGN_CATALOG | CREATE_FOREIGN_SECURABLE | MANAGE_ALLOWLIST | CREATE_VOLUME | CREATE_EXTERNAL_VOLUME | READ_VOLUME | WRITE_VOLUME | MANAGE | BROWSE | CREATE_CLEAN_ROOM | MODIFY_CLEAN_ROOM | EXECUTE_CLEAN_ROOM_TASK | EXTERNAL_USE_SCHEMA`

]

The set of privileges to add.

[`principal`](https://docs.databricks.com/api/workspace/grants/update#changes-principal)string

The principal whose privileges we are changing. Only one of principal or principal_id should be specified, never both at the same time.

[`remove`](https://docs.databricks.com/api/workspace/grants/update#changes-remove)Array of string

Array [

Enum: `SELECT | READ_PRIVATE_FILES | WRITE_PRIVATE_FILES | CREATE | USAGE | USE_CATALOG | USE_SCHEMA | CREATE_SCHEMA | CREATE_VIEW | CREATE_EXTERNAL_TABLE | CREATE_MATERIALIZED_VIEW | CREATE_FUNCTION | CREATE_MODEL | CREATE_CATALOG | CREATE_MANAGED_STORAGE | CREATE_EXTERNAL_LOCATION | CREATE_STORAGE_CREDENTIAL | CREATE_SERVICE_CREDENTIAL | ACCESS | CREATE_SHARE | CREATE_RECIPIENT | CREATE_PROVIDER | USE_SHARE | USE_RECIPIENT | USE_PROVIDER | USE_MARKETPLACE_ASSETS | SET_SHARE_PERMISSION | MODIFY | REFRESH | EXECUTE | READ_FILES | WRITE_FILES | CREATE_TABLE | ALL_PRIVILEGES | CREATE_CONNECTION | USE_CONNECTION | APPLY_TAG | CREATE_FOREIGN_CATALOG | CREATE_FOREIGN_SECURABLE | MANAGE_ALLOWLIST | CREATE_VOLUME | CREATE_EXTERNAL_VOLUME | READ_VOLUME | WRITE_VOLUME | MANAGE | BROWSE | CREATE_CLEAN_ROOM | MODIFY_CLEAN_ROOM | EXECUTE_CLEAN_ROOM_TASK | EXTERNAL_USE_SCHEMA`

]

The set of privileges to remove.

 ]

### Responses

**200** Request completed successfully.

Request completed successfully.

[`privilege_assignments`](https://docs.databricks.com/api/workspace/grants/update#privilege_assignments)Array of object

The privileges assigned to each principal

Array [

[`principal`](https://docs.databricks.com/api/workspace/grants/update#privilege_assignments-principal)string

The principal (user email address or group name). For deleted principals, `principal` is empty while `principal_id` is populated.

[`privileges`](https://docs.databricks.com/api/workspace/grants/update#privilege_assignments-privileges)Array of string

Array [

Enum: `SELECT | READ_PRIVATE_FILES | WRITE_PRIVATE_FILES | CREATE | USAGE | USE_CATALOG | USE_SCHEMA | CREATE_SCHEMA | CREATE_VIEW | CREATE_EXTERNAL_TABLE | CREATE_MATERIALIZED_VIEW | CREATE_FUNCTION | CREATE_MODEL | CREATE_CATALOG | CREATE_MANAGED_STORAGE | CREATE_EXTERNAL_LOCATION | CREATE_STORAGE_CREDENTIAL | CREATE_SERVICE_CREDENTIAL | ACCESS | CREATE_SHARE | CREATE_RECIPIENT | CREATE_PROVIDER | USE_SHARE | USE_RECIPIENT | USE_PROVIDER | USE_MARKETPLACE_ASSETS | SET_SHARE_PERMISSION | MODIFY | REFRESH | EXECUTE | READ_FILES | WRITE_FILES | CREATE_TABLE | ALL_PRIVILEGES | CREATE_CONNECTION | USE_CONNECTION | APPLY_TAG | CREATE_FOREIGN_CATALOG | CREATE_FOREIGN_SECURABLE | MANAGE_ALLOWLIST | CREATE_VOLUME | CREATE_EXTERNAL_VOLUME | READ_VOLUME | WRITE_VOLUME | MANAGE | BROWSE | CREATE_CLEAN_ROOM | MODIFY_CLEAN_ROOM | EXECUTE_CLEAN_ROOM_TASK | EXTERNAL_USE_SCHEMA`

]

The privileges assigned to the principal.

 ]

# Request samples

JSON

{

"changes":[

{

"add":[

"SELECT"

],

"principal":"string",

"remove":[

"SELECT"

]

}

]

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
