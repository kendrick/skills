Title: List queries | Queries API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/queries/list

Markdown Content:
## List queries

`GET/api/2.0/sql/queries`

Gets a list of queries accessible to the user, ordered by creation time. Warning: Calling this API concurrently 10 or more times could result in throttling, service degradation, or a temporary ban.

API scopes (preview):[`sql`](https://docs.databricks.com/api/workspace/api/scopes#sql)

### Query parameters

[`page_token`](https://docs.databricks.com/api/workspace/queries/list#page_token)string

[`page_size`](https://docs.databricks.com/api/workspace/queries/list#page_size)int32

<= 100 

Default`20`

### Responses

**200** Request completed successfully. The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

Request completed successfully.

 The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

[`next_page_token`](https://docs.databricks.com/api/workspace/queries/list#next_page_token)string

[`results`](https://docs.databricks.com/api/workspace/queries/list#results)Array of object

Array [

[`apply_auto_limit`](https://docs.databricks.com/api/workspace/queries/list#results-apply_auto_limit)boolean

Whether to apply a 1000 row limit to the query result.

[`catalog`](https://docs.databricks.com/api/workspace/queries/list#results-catalog)string

Name of the catalog where this query will be executed.

[`create_time`](https://docs.databricks.com/api/workspace/queries/list#results-create_time)date-time

Timestamp when this query was created.

[`description`](https://docs.databricks.com/api/workspace/queries/list#results-description)string

Example`"Example description"`

General description that conveys additional information about this query such as usage notes.

[`display_name`](https://docs.databricks.com/api/workspace/queries/list#results-display_name)string

Example`"Example query"`

Display name of the query that appears in list views, widget headings, and on the query page.

[`id`](https://docs.databricks.com/api/workspace/queries/list#results-id)string

Example`"fe25e731-92f2-4838-9fb2-1ca364320a3d"`

UUID identifying the query.

[`last_modifier_user_name`](https://docs.databricks.com/api/workspace/queries/list#results-last_modifier_user_name)string

Example`"user@acme.com"`

Username of the user who last saved changes to this query.

[`lifecycle_state`](https://docs.databricks.com/api/workspace/queries/list#results-lifecycle_state)string

Enum: `ACTIVE | TRASHED`

Indicates whether the query is trashed.

[`owner_user_name`](https://docs.databricks.com/api/workspace/queries/list#results-owner_user_name)string

Example`"user@acme.com"`

Username of the user that owns the query.

[`parameters`](https://docs.databricks.com/api/workspace/queries/list#results-parameters)Array of object

List of query parameter definitions.

[`query_text`](https://docs.databricks.com/api/workspace/queries/list#results-query_text)string

Example`"SELECT 1"`

Text of the query to be run.

[`run_as_mode`](https://docs.databricks.com/api/workspace/queries/list#results-run_as_mode)string

Enum: `OWNER | VIEWER`

Sets the "Run as" role for the object.

[`schema`](https://docs.databricks.com/api/workspace/queries/list#results-schema)string

Name of the schema where this query will be executed.

[`tags`](https://docs.databricks.com/api/workspace/queries/list#results-tags)Array of string

[`update_time`](https://docs.databricks.com/api/workspace/queries/list#results-update_time)date-time

Timestamp when this query was last updated.

[`warehouse_id`](https://docs.databricks.com/api/workspace/queries/list#results-warehouse_id)string

Example`"a7066a8ef796be84"`

ID of the SQL warehouse attached to the query.

 ]

 This method might return the following HTTP codes: 400, 401, 500

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

UNAUTHENTICATED

Request does not have valid authentication credentials for the operation.

500

INTERNAL_SERVER_ERROR

Internal error.

# Response samples

200

{

"next_page_token":"eDg",

"results":[

{

"create_time":"2019-08-24T14:15:22Z",

"description":"Example description",

"display_name":"Example query 1",

"id":"ae25e731-92f2-4838-9fb2-1ca364320a3d",

"last_modifier_user_name":"user@acme.com",

"lifecycle_state":"ACTIVE",

"owner_user_name":"user@acme.com",

"parameters":[

{

"name":"foo",

"text_value":{

"value":"bar"

},

"title":"foo"

}

],

"query_text":"SELECT 1",

"run_as_mode":"OWNER",

"tags":[

"Tag 1"

],

"update_time":"2019-08-24T14:15:22Z",

"warehouse_id":"a7066a8ef796be84"

},

{

"create_time":"2019-08-24T14:15:22Z",

"description":"Example description",

"display_name":"Example query 2",

"id":"be25e731-92f2-4838-9fb2-1ca364320a3d",

"last_modifier_user_name":"user@acme.com",

"lifecycle_state":"ACTIVE",

"owner_user_name":"user@acme.com",

"parameters":[

{

"name":"foo",

"text_value":{

"value":"bar"

},

"title":"foo"

}

],

"query_text":"SELECT 1",

"run_as_mode":"OWNER",

"tags":[

"Tag 1"

],

"update_time":"2019-08-24T14:15:22Z",

"warehouse_id":"a7066a8ef796be84"

}

]

}
