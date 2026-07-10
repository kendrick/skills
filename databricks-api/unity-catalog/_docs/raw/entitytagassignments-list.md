Title: List entity tag assignments | Entity Tag Assignments API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/entitytagassignments/list

Markdown Content:
## List entity tag assignments

Public preview

`GET/api/2.1/unity-catalog/entity-tag-assignments/{entity_type}/{entity_name}/tags`

List tag assignments for an Unity Catalog entity

PAGINATION BEHAVIOR: The API is by default paginated, a page may contain zero results while still providing a next_page_token. Clients must continue reading pages until next_page_token is absent, which is the only indication that the end of results has been reached.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`entity_type`](https://docs.databricks.com/api/workspace/entitytagassignments/list#entity_type)required string

The type of the entity to which the tag is assigned. Allowed values are: catalogs, schemas, tables, columns, volumes, externallocations.

[`entity_name`](https://docs.databricks.com/api/workspace/entitytagassignments/list#entity_name)required string

The fully qualified name of the entity to which the tag is assigned

### Query parameters

[`max_results`](https://docs.databricks.com/api/workspace/entitytagassignments/list#max_results)int32 Optional

Optional. Maximum number of tag assignments to return in a single page

[`page_token`](https://docs.databricks.com/api/workspace/entitytagassignments/list#page_token)string Optional

Optional. Pagination token to retrieve the next page of results

### Responses

**200** Request completed successfully. The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

Request completed successfully.

 The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

[`next_page_token`](https://docs.databricks.com/api/workspace/entitytagassignments/list#next_page_token)string

Optional. Pagination token for retrieving the next page of results

[`tag_assignments`](https://docs.databricks.com/api/workspace/entitytagassignments/list#tag_assignments)Array of object

The list of tag assignments

Array [

[`entity_name`](https://docs.databricks.com/api/workspace/entitytagassignments/list#tag_assignments-entity_name)string

The fully qualified name of the entity to which the tag is assigned

[`entity_type`](https://docs.databricks.com/api/workspace/entitytagassignments/list#tag_assignments-entity_type)string

The type of the entity to which the tag is assigned. Allowed values are: catalogs, schemas, tables, columns, volumes, externallocations.

[`source_type`](https://docs.databricks.com/api/workspace/entitytagassignments/list#tag_assignments-source_type)string

Enum: `TAG_ASSIGNMENT_SOURCE_TYPE_SYSTEM_DATA_CLASSIFICATION`

The source type of the tag assignment, e.g., user-assigned or system-assigned

[`tag_key`](https://docs.databricks.com/api/workspace/entitytagassignments/list#tag_assignments-tag_key)string

The key of the tag

[`tag_value`](https://docs.databricks.com/api/workspace/entitytagassignments/list#tag_assignments-tag_value)string

The value of the tag

[`update_time`](https://docs.databricks.com/api/workspace/entitytagassignments/list#tag_assignments-update_time)date-time

The timestamp when the tag assignment was last updated

[`updated_by`](https://docs.databricks.com/api/workspace/entitytagassignments/list#tag_assignments-updated_by)string

The user or principal who updated the tag assignment

 ]

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

"next_page_token":"eyJsYXN0X2V2YWx1YXRlZF9rZXki OiAiT3duZXIifQ==",

"tag_assignments":[

{

"entity_name":"main.default.customer_data.p hone",

"entity_type":"columns",

"source_type":"TAG_ASSIGNMENT_SOURCE_TYPE_S YSTEM_DATA_CLASSIFICATION",

"tag_key":"class.phone_number",

"tag_value":"true",

"update_time":"2026-01-14T08:15:00.000Z",

"updated_by":"a1b2c3d4-e5f6-7890-abcd-ef123 4567890"

},

{

"entity_name":"main.default.customer_data.p hone",

"entity_type":"columns",

"source_type":"TAG_ASSIGNMENT_SOURCE_TYPE_U NSPECIFIED",

"tag_key":"Sensitivity",

"tag_value":"high",

"update_time":"2026-01-15T10:30:00.000Z",

"updated_by":"user@example.com"

},

{

"entity_name":"main.default.customer_data.p hone",

"entity_type":"columns",

"source_type":"TAG_ASSIGNMENT_SOURCE_TYPE_U NSPECIFIED",

"tag_key":"Owner",

"tag_value":"data-team",

"update_time":"2026-01-13T14:20:00.000Z",

"updated_by":"admin@example.com"

}

]

}
