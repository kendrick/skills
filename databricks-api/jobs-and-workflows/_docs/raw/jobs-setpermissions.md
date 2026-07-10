Title: Set job permissions | Jobs API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/jobs/setpermissions

Markdown Content:
## Set job permissions

`PUT/api/2.0/permissions/jobs/{job_id}`

Sets permissions on an object, replacing existing permissions if they exist. Deletes all direct permissions if none are specified. Objects can inherit permissions from their root object.

API scopes (preview):[`jobs`](https://docs.databricks.com/api/workspace/api/scopes#jobs)

### Path parameters

[`job_id`](https://docs.databricks.com/api/workspace/jobs/setpermissions#job_id)required string

The job for which to get or manage permissions.

### Request body

[`access_control_list`](https://docs.databricks.com/api/workspace/jobs/setpermissions#access_control_list)Array of object

Array [

[`group_name`](https://docs.databricks.com/api/workspace/jobs/setpermissions#access_control_list-group_name)string

name of the group

[`permission_level`](https://docs.databricks.com/api/workspace/jobs/setpermissions#access_control_list-permission_level)string

Enum: `CAN_MANAGE | IS_OWNER | CAN_MANAGE_RUN | CAN_VIEW`

Permission level

[`service_principal_name`](https://docs.databricks.com/api/workspace/jobs/setpermissions#access_control_list-service_principal_name)string

application ID of a service principal

[`user_name`](https://docs.databricks.com/api/workspace/jobs/setpermissions#access_control_list-user_name)string

name of the user

 ]

### Responses

**200**

[`access_control_list`](https://docs.databricks.com/api/workspace/jobs/setpermissions#access_control_list)Array of object

Array [

[`all_permissions`](https://docs.databricks.com/api/workspace/jobs/setpermissions#access_control_list-all_permissions)Array of object

All permissions.

[`display_name`](https://docs.databricks.com/api/workspace/jobs/setpermissions#access_control_list-display_name)string

Display name of the user or service principal.

[`group_name`](https://docs.databricks.com/api/workspace/jobs/setpermissions#access_control_list-group_name)string

name of the group

[`service_principal_name`](https://docs.databricks.com/api/workspace/jobs/setpermissions#access_control_list-service_principal_name)string

Name of the service principal.

[`user_name`](https://docs.databricks.com/api/workspace/jobs/setpermissions#access_control_list-user_name)string

name of the user

 ]

[`object_id`](https://docs.databricks.com/api/workspace/jobs/setpermissions#object_id)string

[`object_type`](https://docs.databricks.com/api/workspace/jobs/setpermissions#object_type)string

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

BAD_REQUEST, INVALID_PARAMETER_VALUE

BAD_REQUEST - Request is invalid. INVALID_PARAMETER_VALUE - Supplied value for a parameter was invalid.

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

# Request samples

JSON

{

"access_control_list":[

{

"group_name":"string",

"permission_level":"CAN_MANAGE",

"service_principal_name":"string",

"user_name":"string"

}

]

}

# Response samples

200

{

"access_control_list":[

{

"all_permissions":[

{

"inherited":true,

"inherited_from_object":[

"string"

],

"permission_level":"CAN_MANAGE"

}

],

"display_name":"string",

"group_name":"string",

"service_principal_name":"string",

"user_name":"string"

}

],

"object_id":"string",

"object_type":"string"

}
