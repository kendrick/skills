Title: Get SQL warehouse permission levels | SQL Warehouses API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/warehouses/getpermissionlevels

Markdown Content:
## Get SQL warehouse permission levels

`GET/api/2.0/permissions/warehouses/{warehouse_id}/permissionLevels`

Gets the permission levels that a user can have on an object.

API scopes (preview):[`sql`](https://docs.databricks.com/api/workspace/api/scopes#sql)

### Path parameters

[`warehouse_id`](https://docs.databricks.com/api/workspace/warehouses/getpermissionlevels#warehouse_id)required string

The SQL warehouse for which to get or manage permissions.

### Responses

**200**

[`permission_levels`](https://docs.databricks.com/api/workspace/warehouses/getpermissionlevels#permission_levels)Array of object

Specific permission levels

Array [

[`description`](https://docs.databricks.com/api/workspace/warehouses/getpermissionlevels#permission_levels-description)string

[`permission_level`](https://docs.databricks.com/api/workspace/warehouses/getpermissionlevels#permission_levels-permission_level)string

Enum: `CAN_MANAGE | IS_OWNER | CAN_USE | CAN_MONITOR | CAN_VIEW`

Permission level

 ]

 This method might return the following HTTP codes: 400, 401, 403, 404, 500

Error responses are returned in the following format:

{

"error_code":"Error code",

"message":"Human-readable error message."

}

# Possible error codes:

HTTP code

error_code

Description

400

BAD_REQUEST

Request is invalid.

401

UNAUTHORIZED

The request does not have valid authentication credentials for the operation.

403

PERMISSION_DENIED

Caller does not have permission to execute the specified operation.

404

FEATURE_DISABLED, RESOURCE_DOES_NOT_EXIST

FEATURE_DISABLED - If a given user/entity is trying to use a feature which has been disabled. RESOURCE_DOES_NOT_EXIST - Operation was performed on a resource that does not exist.

500

INTERNAL_SERVER_ERROR

Internal error.

# Response samples

200

{

"permission_levels":[

{

"description":"string",

"permission_level":"CAN_MANAGE"

}

]

}
