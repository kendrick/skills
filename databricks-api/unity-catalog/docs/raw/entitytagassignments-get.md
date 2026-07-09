Title: Get an entity tag assignment | Entity Tag Assignments API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/entitytagassignments/get

Markdown Content:
## Get an entity tag assignment

Public preview

`GET/api/2.1/unity-catalog/entity-tag-assignments/{entity_type}/{entity_name}/tags/{tag_key}`

Gets a tag assignment for an Unity Catalog entity by tag key.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`entity_type`](https://docs.databricks.com/api/workspace/entitytagassignments/get#entity_type)required string

The type of the entity to which the tag is assigned. Allowed values are: catalogs, schemas, tables, columns, volumes, externallocations.

[`entity_name`](https://docs.databricks.com/api/workspace/entitytagassignments/get#entity_name)required string

The fully qualified name of the entity to which the tag is assigned

[`tag_key`](https://docs.databricks.com/api/workspace/entitytagassignments/get#tag_key)required string

Required. The key of the tag

### Responses

**200** Request completed successfully.

Request completed successfully.

[`entity_name`](https://docs.databricks.com/api/workspace/entitytagassignments/get#entity_name)string

The fully qualified name of the entity to which the tag is assigned

[`entity_type`](https://docs.databricks.com/api/workspace/entitytagassignments/get#entity_type)string

The type of the entity to which the tag is assigned. Allowed values are: catalogs, schemas, tables, columns, volumes, externallocations.

[`source_type`](https://docs.databricks.com/api/workspace/entitytagassignments/get#source_type)string

Enum: `TAG_ASSIGNMENT_SOURCE_TYPE_SYSTEM_DATA_CLASSIFICATION`

The source type of the tag assignment, e.g., user-assigned or system-assigned

[`tag_key`](https://docs.databricks.com/api/workspace/entitytagassignments/get#tag_key)string

The key of the tag

[`tag_value`](https://docs.databricks.com/api/workspace/entitytagassignments/get#tag_value)string

The value of the tag

[`update_time`](https://docs.databricks.com/api/workspace/entitytagassignments/get#update_time)date-time

The timestamp when the tag assignment was last updated

[`updated_by`](https://docs.databricks.com/api/workspace/entitytagassignments/get#updated_by)string

The user or principal who updated the tag assignment

 This method might return the following HTTP codes: 401, 403, 404, 500

Error responses are returned in the following format:

{

"error_code":"Error code",

"message":"Human-readable error message."

}

# Possible error codes:

HTTP code

error_code

Description

401

UNAUTHORIZED

The request does not have valid authentication credentials for the operation.

403

PERMISSION_DENIED

Caller does not have permission to execute the specified operation.

404

RESOURCE_DOES_NOT_EXIST

Operation was performed on a resource that does not exist.

500

INTERNAL_SERVER_ERROR

Internal error.

# Response samples

200

{

"entity_name":"main.default.customer_data",

"entity_type":"tables",

"source_type":"TAG_ASSIGNMENT_SOURCE_TYPE_UNSPE CIFIED",

"tag_key":"Severity",

"tag_value":"high",

"update_time":"2026-01-15T10:30:00.000Z",

"updated_by":"user@example.com"

}
