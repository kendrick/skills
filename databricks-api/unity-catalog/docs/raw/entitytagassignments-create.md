Title: Create an entity tag assignment | Entity Tag Assignments API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/entitytagassignments/create

Markdown Content:
## Create an entity tag assignment

Public preview

`POST/api/2.1/unity-catalog/entity-tag-assignments`

Creates a tag assignment for an Unity Catalog entity.

To add tags to Unity Catalog entities, you must own the entity or have the following privileges:

*   APPLY TAG on the entity
*   USE SCHEMA on the entity's parent schema
*   USE CATALOG on the entity's parent catalog

To add a governed tag to Unity Catalog entities, you must also have the ASSIGN or MANAGE permission on the tag policy. See [Manage tag policy permissions](https://docs.databricks.com/aws/en/admin/tag-policies/manage-permissions).

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Request body

Represents a tag assignment to an entity

[`entity_name`](https://docs.databricks.com/api/workspace/entitytagassignments/create#entity_name)string Required

The fully qualified name of the entity to which the tag is assigned

[`entity_type`](https://docs.databricks.com/api/workspace/entitytagassignments/create#entity_type)string Required

The type of the entity to which the tag is assigned. Allowed values are: catalogs, schemas, tables, columns, volumes, externallocations.

[`tag_key`](https://docs.databricks.com/api/workspace/entitytagassignments/create#tag_key)string Required

The key of the tag

[`tag_value`](https://docs.databricks.com/api/workspace/entitytagassignments/create#tag_value)string Optional

The value of the tag

### Responses

**200** Request completed successfully.

Request completed successfully.

[`entity_name`](https://docs.databricks.com/api/workspace/entitytagassignments/create#entity_name)string

The fully qualified name of the entity to which the tag is assigned

[`entity_type`](https://docs.databricks.com/api/workspace/entitytagassignments/create#entity_type)string

The type of the entity to which the tag is assigned. Allowed values are: catalogs, schemas, tables, columns, volumes, externallocations.

[`source_type`](https://docs.databricks.com/api/workspace/entitytagassignments/create#source_type)string

Enum: `TAG_ASSIGNMENT_SOURCE_TYPE_SYSTEM_DATA_CLASSIFICATION`

The source type of the tag assignment, e.g., user-assigned or system-assigned

[`tag_key`](https://docs.databricks.com/api/workspace/entitytagassignments/create#tag_key)string

The key of the tag

[`tag_value`](https://docs.databricks.com/api/workspace/entitytagassignments/create#tag_value)string

The value of the tag

[`update_time`](https://docs.databricks.com/api/workspace/entitytagassignments/create#update_time)date-time

The timestamp when the tag assignment was last updated

[`updated_by`](https://docs.databricks.com/api/workspace/entitytagassignments/create#updated_by)string

The user or principal who updated the tag assignment

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

RESOURCE_ALREADY_EXISTS

Operation was performed on a resource that already exists.

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

# Request samples

JSON

{

"entity_name":"main.default.customer_data",

"entity_type":"tables",

"tag_key":"Severity",

"tag_value":"high"

}

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
