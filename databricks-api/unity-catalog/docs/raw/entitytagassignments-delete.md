Title: Delete an entity tag assignment | Entity Tag Assignments API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/entitytagassignments/delete

Markdown Content:
## Delete an entity tag assignment

Public preview

`DELETE/api/2.1/unity-catalog/entity-tag-assignments/{entity_type}/{entity_name}/tags/{tag_key}`

Deletes a tag assignment for an Unity Catalog entity by its key.

To delete tags from Unity Catalog entities, you must own the entity or have the following privileges:

*   APPLY TAG on the entity
*   USE_SCHEMA on the entity's parent schema
*   USE_CATALOG on the entity's parent catalog

To delete a governed tag from Unity Catalog entities, you must also have the ASSIGN or MANAGE permission on the tag policy. See [Manage tag policy permissions](https://docs.databricks.com/aws/en/admin/tag-policies/manage-permissions).

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`entity_type`](https://docs.databricks.com/api/workspace/entitytagassignments/delete#entity_type)required string

Example`"tables"`

The type of the entity to which the tag is assigned. Allowed values are: catalogs, schemas, tables, columns, volumes, externallocations.

[`entity_name`](https://docs.databricks.com/api/workspace/entitytagassignments/delete#entity_name)required string

Example`"main.default.customer_data"`

The fully qualified name of the entity to which the tag is assigned

[`tag_key`](https://docs.databricks.com/api/workspace/entitytagassignments/delete#tag_key)required string

Example`"Severity"`

Required. The key of the tag to delete

### Responses

**200** Request completed successfully.

Request completed successfully.

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

{}
