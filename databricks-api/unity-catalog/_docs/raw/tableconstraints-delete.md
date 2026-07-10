Title: Delete a table constraint | Table Constraints API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/tableconstraints/delete

Markdown Content:
## Delete a table constraint

`DELETE/api/2.1/unity-catalog/constraints/{full_name}`

Deletes a table constraint.

For the table constraint deletion to succeed, the user must satisfy both of these conditions:

*   the user must have the USE_CATALOG privilege on the table's parent catalog, the USE_SCHEMA privilege on the table's parent schema, and be the owner of the table.
*   if cascade argument is true, the user must have the following permissions on all of the child tables: the USE_CATALOG privilege on the table's catalog, the USE_SCHEMA privilege on the table's schema, and be the owner of the table.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`full_name`](https://docs.databricks.com/api/workspace/tableconstraints/delete#full_name)required string

Full name of the table referenced by the constraint.

### Query parameters

[`constraint_name`](https://docs.databricks.com/api/workspace/tableconstraints/delete#constraint_name)required string

The name of the constraint to delete.

[`cascade`](https://docs.databricks.com/api/workspace/tableconstraints/delete#cascade)required boolean

Default`false`

If true, try deleting all child constraints of the current constraint. If false, reject this operation if the current constraint has any child constraints.

### Responses

**200** Request completed successfully.

Request completed successfully.

# Response samples

200

{}
