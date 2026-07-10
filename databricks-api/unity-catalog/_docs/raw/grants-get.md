Title: Get permissions | Grants API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/grants/get

Markdown Content:
## Get permissions

`GET/api/2.1/unity-catalog/permissions/{securable_type}/{full_name}`

Gets the permissions for a securable. Does not include inherited permissions.

NOTE: we recommend using max_results=0 to use the paginated version of this API. Unpaginated calls will be deprecated soon.

PAGINATION BEHAVIOR: When using pagination (max_results >= 0), a page may contain zero results while still providing a next_page_token. Clients must continue reading pages until next_page_token is absent, which is the only indication that the end of results has been reached.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`securable_type`](https://docs.databricks.com/api/workspace/grants/get#securable_type)required string

Type of securable.

[`full_name`](https://docs.databricks.com/api/workspace/grants/get#full_name)required string

Full name of securable.

### Query parameters

[`principal`](https://docs.databricks.com/api/workspace/grants/get#principal)string

If provided, only the permissions for the specified principal (user or group) are returned.

[`max_results`](https://docs.databricks.com/api/workspace/grants/get#max_results)int32

Specifies the maximum number of privileges to return (page length). Every PrivilegeAssignment present in a single page response is guaranteed to contain all the privileges granted on the requested Securable for the respective principal.

If not set, all the permissions are returned. If set to

*   lesser than 0: invalid parameter error
*   0: page length is set to a server configured value
*   lesser than 150 but greater than 0: invalid parameter error (this is to ensure that server is able to return at least one complete PrivilegeAssignment in a single page response)
*   greater than (or equal to) 150: page length is the minimum of this value and a server configured value

[`page_token`](https://docs.databricks.com/api/workspace/grants/get#page_token)string

Opaque pagination token to go to next page based on previous query.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`next_page_token`](https://docs.databricks.com/api/workspace/grants/get#next_page_token)string

Opaque token to retrieve the next page of results. Absent if there are no more pages. page_token should be set to this value for the next request (for the next page of results).

[`privilege_assignments`](https://docs.databricks.com/api/workspace/grants/get#privilege_assignments)Array of object

The privileges assigned to each principal

Array [

[`principal`](https://docs.databricks.com/api/workspace/grants/get#privilege_assignments-principal)string

The principal (user email address or group name). For deleted principals, `principal` is empty while `principal_id` is populated.

[`privileges`](https://docs.databricks.com/api/workspace/grants/get#privilege_assignments-privileges)Array of string

Array [

Enum: `SELECT | READ_PRIVATE_FILES | WRITE_PRIVATE_FILES | CREATE | USAGE | USE_CATALOG | USE_SCHEMA | CREATE_SCHEMA | CREATE_VIEW | CREATE_EXTERNAL_TABLE | CREATE_MATERIALIZED_VIEW | CREATE_FUNCTION | CREATE_MODEL | CREATE_CATALOG | CREATE_MANAGED_STORAGE | CREATE_EXTERNAL_LOCATION | CREATE_STORAGE_CREDENTIAL | CREATE_SERVICE_CREDENTIAL | ACCESS | CREATE_SHARE | CREATE_RECIPIENT | CREATE_PROVIDER | USE_SHARE | USE_RECIPIENT | USE_PROVIDER | USE_MARKETPLACE_ASSETS | SET_SHARE_PERMISSION | MODIFY | REFRESH | EXECUTE | READ_FILES | WRITE_FILES | CREATE_TABLE | ALL_PRIVILEGES | CREATE_CONNECTION | USE_CONNECTION | APPLY_TAG | CREATE_FOREIGN_CATALOG | CREATE_FOREIGN_SECURABLE | MANAGE_ALLOWLIST | CREATE_VOLUME | CREATE_EXTERNAL_VOLUME | READ_VOLUME | WRITE_VOLUME | MANAGE | BROWSE | CREATE_CLEAN_ROOM | MODIFY_CLEAN_ROOM | EXECUTE_CLEAN_ROOM_TASK | EXTERNAL_USE_SCHEMA`

]

The privileges assigned to the principal.

 ]

# Response samples

200

{

"next_page_token":"string",

"privilege_assignments":[

{

"principal":"string",

"privileges":[

"SELECT"

]

}

]

}
