Title: Get serving endpoint permissions | Serving endpoints API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/servingendpoints/getpermissions

Markdown Content:
## Get serving endpoint permissions

`GET/api/2.0/permissions/serving-endpoints/{serving_endpoint_id}`

Gets the permissions of a serving endpoint. Serving endpoints can inherit permissions from their root object.

API scopes (preview):[`model-serving`](https://docs.databricks.com/api/workspace/api/scopes#model-serving)

### Path parameters

[`serving_endpoint_id`](https://docs.databricks.com/api/workspace/servingendpoints/getpermissions#serving_endpoint_id)required string

The serving endpoint for which to get or manage permissions.

### Responses

**200**

[`access_control_list`](https://docs.databricks.com/api/workspace/servingendpoints/getpermissions#access_control_list)Array of object

Array [

[`all_permissions`](https://docs.databricks.com/api/workspace/servingendpoints/getpermissions#access_control_list-all_permissions)Array of object

All permissions.

[`display_name`](https://docs.databricks.com/api/workspace/servingendpoints/getpermissions#access_control_list-display_name)string

Display name of the user or service principal.

[`group_name`](https://docs.databricks.com/api/workspace/servingendpoints/getpermissions#access_control_list-group_name)string

name of the group

[`service_principal_name`](https://docs.databricks.com/api/workspace/servingendpoints/getpermissions#access_control_list-service_principal_name)string

Name of the service principal.

[`user_name`](https://docs.databricks.com/api/workspace/servingendpoints/getpermissions#access_control_list-user_name)string

name of the user

 ]

[`object_id`](https://docs.databricks.com/api/workspace/servingendpoints/getpermissions#object_id)string

[`object_type`](https://docs.databricks.com/api/workspace/servingendpoints/getpermissions#object_type)string

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
