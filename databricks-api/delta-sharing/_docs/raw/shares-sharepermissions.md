Title: Get permissions | Shares API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/shares/sharepermissions

Markdown Content:
## Get permissions

`GET/api/2.1/unity-catalog/shares/{name}/permissions`

Gets the permissions for a data share from the metastore. The caller must have the USE_SHARE privilege on the metastore or be the owner of the share.

API scopes (preview):[`sharing`](https://docs.databricks.com/api/workspace/api/scopes#sharing)

### Path parameters

[`name`](https://docs.databricks.com/api/workspace/shares/sharepermissions#name)required string

The name of the share.

### Query parameters

[`max_results`](https://docs.databricks.com/api/workspace/shares/sharepermissions#max_results)int32

<= 1000 

Maximum number of permissions to return.

*   when set to 0, the page length is set to a server configured value (recommended);
*   when set to a value greater than 0, the page length is the minimum of this value and a server configured value;
*   when set to a value less than 0, an invalid parameter error is returned;
*   If not set, all valid permissions are returned (not recommended).
*   Note: The number of returned permissions might be less than the specified max_results size, even zero. The only definitive indication that no further permissions can be fetched is when the next_page_token is unset from the response.

[`page_token`](https://docs.databricks.com/api/workspace/shares/sharepermissions#page_token)string

Opaque pagination token to go to next page based on previous query.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`next_page_token`](https://docs.databricks.com/api/workspace/shares/sharepermissions#next_page_token)string

Opaque token to retrieve the next page of results. Absent if there are no more pages. page_token should be set to this value for the next request (for the next page of results).

[`privilege_assignments`](https://docs.databricks.com/api/workspace/shares/sharepermissions#privilege_assignments)Array of object

The privileges assigned to each principal

Array [

[`principal`](https://docs.databricks.com/api/workspace/shares/sharepermissions#privilege_assignments-principal)string

The principal (user email address or group name). For deleted principals, `principal` is empty while `principal_id` is populated.

[`privileges`](https://docs.databricks.com/api/workspace/shares/sharepermissions#privilege_assignments-privileges)Array of string

Array [

Enum: `SELECT | READ_PRIVATE_FILES | WRITE_PRIVATE_FILES | CREATE | USAGE | USE_CATALOG | USE_SCHEMA | CREATE_SCHEMA | CREATE_VIEW | CREATE_EXTERNAL_TABLE | CREATE_MATERIALIZED_VIEW | CREATE_FUNCTION | CREATE_MODEL | CREATE_CATALOG | CREATE_MANAGED_STORAGE | CREATE_EXTERNAL_LOCATION | CREATE_STORAGE_CREDENTIAL | CREATE_SERVICE_CREDENTIAL | ACCESS | CREATE_SHARE | CREATE_RECIPIENT | CREATE_PROVIDER | USE_SHARE | USE_RECIPIENT | USE_PROVIDER | USE_MARKETPLACE_ASSETS | SET_SHARE_PERMISSION | MODIFY | REFRESH | EXECUTE | READ_FILES | WRITE_FILES | CREATE_TABLE | ALL_PRIVILEGES | CREATE_CONNECTION | USE_CONNECTION | APPLY_TAG | CREATE_FOREIGN_CATALOG | CREATE_FOREIGN_SECURABLE | MANAGE_ALLOWLIST | CREATE_VOLUME | CREATE_EXTERNAL_VOLUME | READ_VOLUME | WRITE_VOLUME | MANAGE`

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
