Title: Update a query | Queries API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/queries/update

Markdown Content:
## Update a query

`PATCH/api/2.0/sql/queries/{id}`

Updates a query.

API scopes (preview):[`sql`](https://docs.databricks.com/api/workspace/api/scopes#sql)

### Path parameters

[`id`](https://docs.databricks.com/api/workspace/queries/update#id)required string

### Request body

[`auto_resolve_display_name`](https://docs.databricks.com/api/workspace/queries/update#auto_resolve_display_name)boolean

Default`true`

If true, automatically resolve alert display name conflicts. Otherwise, fail the request if the alert's display name conflicts with an existing alert's display name.

[`query`](https://docs.databricks.com/api/workspace/queries/update#query)object

[`apply_auto_limit`](https://docs.databricks.com/api/workspace/queries/update#query-apply_auto_limit)boolean

Whether to apply a 1000 row limit to the query result.

[`catalog`](https://docs.databricks.com/api/workspace/queries/update#query-catalog)string

Name of the catalog where this query will be executed.

[`description`](https://docs.databricks.com/api/workspace/queries/update#query-description)string

Example`"Example description"`

General description that conveys additional information about this query such as usage notes.

[`display_name`](https://docs.databricks.com/api/workspace/queries/update#query-display_name)string

Example`"Example query"`

Display name of the query that appears in list views, widget headings, and on the query page.

[`owner_user_name`](https://docs.databricks.com/api/workspace/queries/update#query-owner_user_name)string

Example`"user@acme.com"`

Username of the user that owns the query.

[`parameters`](https://docs.databricks.com/api/workspace/queries/update#query-parameters)Array of object

List of query parameter definitions.

[`query_text`](https://docs.databricks.com/api/workspace/queries/update#query-query_text)string

Example`"SELECT 1"`

Text of the query to be run.

[`run_as_mode`](https://docs.databricks.com/api/workspace/queries/update#query-run_as_mode)string

Enum: `OWNER | VIEWER`

Sets the "Run as" role for the object.

[`schema`](https://docs.databricks.com/api/workspace/queries/update#query-schema)string

Name of the schema where this query will be executed.

[`tags`](https://docs.databricks.com/api/workspace/queries/update#query-tags)Array of string

[`warehouse_id`](https://docs.databricks.com/api/workspace/queries/update#query-warehouse_id)string

Example`"a7066a8ef796be84"`

ID of the SQL warehouse attached to the query.

[`update_mask`](https://docs.databricks.com/api/workspace/queries/update#update_mask)required string

The field mask must be a single string, with multiple fields separated by commas (no spaces). The field path is relative to the resource object, using a dot (`.`) to navigate sub-fields (e.g., `author.given_name`). Specification of elements in sequence or map fields is not allowed, as only the entire collection field can be specified. Field names must exactly match the resource field names.

A field mask of `*` indicates full replacement. It’s recommended to always explicitly list the fields being updated and avoid using `*` wildcards, as it can lead to unintended results if the API changes in the future.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`apply_auto_limit`](https://docs.databricks.com/api/workspace/queries/update#apply_auto_limit)boolean

Whether to apply a 1000 row limit to the query result.

[`catalog`](https://docs.databricks.com/api/workspace/queries/update#catalog)string

Name of the catalog where this query will be executed.

[`create_time`](https://docs.databricks.com/api/workspace/queries/update#create_time)date-time

Timestamp when this query was created.

[`description`](https://docs.databricks.com/api/workspace/queries/update#description)string

Example`"Example description"`

General description that conveys additional information about this query such as usage notes.

[`display_name`](https://docs.databricks.com/api/workspace/queries/update#display_name)string

Example`"Example query"`

Display name of the query that appears in list views, widget headings, and on the query page.

[`id`](https://docs.databricks.com/api/workspace/queries/update#id)string

Example`"fe25e731-92f2-4838-9fb2-1ca364320a3d"`

UUID identifying the query.

[`last_modifier_user_name`](https://docs.databricks.com/api/workspace/queries/update#last_modifier_user_name)string

Example`"user@acme.com"`

Username of the user who last saved changes to this query.

[`lifecycle_state`](https://docs.databricks.com/api/workspace/queries/update#lifecycle_state)string

Enum: `ACTIVE | TRASHED`

Indicates whether the query is trashed.

[`owner_user_name`](https://docs.databricks.com/api/workspace/queries/update#owner_user_name)string

Example`"user@acme.com"`

Username of the user that owns the query.

[`parameters`](https://docs.databricks.com/api/workspace/queries/update#parameters)Array of object

List of query parameter definitions.

Array [

[`date_range_value`](https://docs.databricks.com/api/workspace/queries/update#parameters-date_range_value)object

Date-range query parameter value. Can only specify one of `dynamic_date_range_value` or `date_range_value`.

[`date_value`](https://docs.databricks.com/api/workspace/queries/update#parameters-date_value)object

Date query parameter value. Can only specify one of `dynamic_date_value` or `date_value`.

[`enum_value`](https://docs.databricks.com/api/workspace/queries/update#parameters-enum_value)object

Dropdown query parameter value.

[`name`](https://docs.databricks.com/api/workspace/queries/update#parameters-name)string

Literal parameter marker that appears between double curly braces in the query text.

[`numeric_value`](https://docs.databricks.com/api/workspace/queries/update#parameters-numeric_value)object

Numeric query parameter value.

[`query_backed_value`](https://docs.databricks.com/api/workspace/queries/update#parameters-query_backed_value)object

Query-based dropdown query parameter value.

[`text_value`](https://docs.databricks.com/api/workspace/queries/update#parameters-text_value)object

Text query parameter value.

[`title`](https://docs.databricks.com/api/workspace/queries/update#parameters-title)string

Text displayed in the user-facing parameter widget in the UI.

 ]

[`parent_path`](https://docs.databricks.com/api/workspace/queries/update#parent_path)string

Example`"/Users/user@acme.com"`

Workspace path of the workspace folder containing the object.

[`query_text`](https://docs.databricks.com/api/workspace/queries/update#query_text)string

Example`"SELECT 1"`

Text of the query to be run.

[`run_as_mode`](https://docs.databricks.com/api/workspace/queries/update#run_as_mode)string

Enum: `OWNER | VIEWER`

Sets the "Run as" role for the object.

[`schema`](https://docs.databricks.com/api/workspace/queries/update#schema)string

Name of the schema where this query will be executed.

[`tags`](https://docs.databricks.com/api/workspace/queries/update#tags)Array of string

[`update_time`](https://docs.databricks.com/api/workspace/queries/update#update_time)date-time

Timestamp when this query was last updated.

[`warehouse_id`](https://docs.databricks.com/api/workspace/queries/update#warehouse_id)string

Example`"a7066a8ef796be84"`

ID of the SQL warehouse attached to the query.

 This method might return the following HTTP codes: 400, 401, 403, 404, 500

Error responses are returned in the following format:

{ "error_code": "Error code", "message": "Human-readable error message." }

# Possible error codes:

HTTP code

error_code

Description

400

BAD_REQUEST

Request is invalid.

401

UNAUTHENTICATED

Request does not have valid authentication credentials for the operation.

403

PERMISSION_DENIED

Caller does not have permission to execute the specified operation.

404

NOT_FOUND

Operation was performed on a resource that does not exist.

500

INTERNAL_SERVER_ERROR

Internal error.

# Request samples

JSON

{ "query": { "description": "Example description updated", "display_name": "Example query updated", "query_text": "SELECT 2" }, "update_mask": "display_name,description,query_text" }

# Response samples

200

{ "create_time": "2019-08-24T14:15:22Z", "description": "Example description updated", "display_name": "Example query updated", "id": "fe25e731-92f2-4838-9fb2-1ca364320a3d", "last_modifier_user_name": "user@acme.com", "lifecycle_state": "ACTIVE", "owner_user_name": "user@acme.com", "parameters": [ { "name": "foo", "text_value": { "value": "bar" }, "title": "foo" } ], "parent_path": "/Workspace/Users/user@acme.com", "query_text": "SELECT 2", "run_as_mode": "OWNER", "tags": [ "Tag 1" ], "update_time": "2019-08-24T14:15:22Z", "warehouse_id": "a7066a8ef796be84" }
