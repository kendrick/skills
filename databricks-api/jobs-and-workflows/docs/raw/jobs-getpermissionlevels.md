Title: Get job permission levels | Jobs API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/jobs/getpermissionlevels

Markdown Content:
## Get job permission levels

`GET/api/2.0/permissions/jobs/{job_id}/permissionLevels`

Gets the permission levels that a user can have on an object.

API scopes (preview):[`jobs`](https://docs.databricks.com/api/workspace/api/scopes#jobs)

### Path parameters

[`job_id`](https://docs.databricks.com/api/workspace/jobs/getpermissionlevels#job_id)required string

The job for which to get or manage permissions.

### Responses

**200**

[`permission_levels`](https://docs.databricks.com/api/workspace/jobs/getpermissionlevels#permission_levels)Array of object

Specific permission levels

Array [

[`description`](https://docs.databricks.com/api/workspace/jobs/getpermissionlevels#permission_levels-description)string

[`permission_level`](https://docs.databricks.com/api/workspace/jobs/getpermissionlevels#permission_levels-permission_level)string

Enum: `CAN_MANAGE | IS_OWNER | CAN_MANAGE_RUN | CAN_VIEW`

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
