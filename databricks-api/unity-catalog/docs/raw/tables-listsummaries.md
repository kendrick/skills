Title: List table summaries | Tables API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/tables/listsummaries

Markdown Content:
## List table summaries

`GET/api/2.1/unity-catalog/table-summaries`

Gets an array of summaries for tables for a schema and catalog within the metastore. The table summaries returned are either:

*   summaries for tables (within the current metastore and parent catalog and schema), when the user is a metastore admin, or:
*   summaries for tables and schemas (within the current metastore and parent catalog) for which the user has ownership or the SELECT privilege on the table and ownership or USE_SCHEMA privilege on the schema, provided that the user also has ownership or the USE_CATALOG privilege on the parent catalog.

There is no guarantee of a specific ordering of the elements in the array.

PAGINATION BEHAVIOR: The API is by default paginated, a page may contain zero results while still providing a next_page_token. Clients must continue reading pages until next_page_token is absent, which is the only indication that the end of results has been reached.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Query parameters

[`catalog_name`](https://docs.databricks.com/api/workspace/tables/listsummaries#catalog_name)required string

Name of parent catalog for tables of interest.

[`schema_name_pattern`](https://docs.databricks.com/api/workspace/tables/listsummaries#schema_name_pattern)string

A sql LIKE pattern (% and _) for schema names. All schemas will be returned if not set or empty.

[`table_name_pattern`](https://docs.databricks.com/api/workspace/tables/listsummaries#table_name_pattern)string

A sql LIKE pattern (% and _) for table names. All tables will be returned if not set or empty.

[`max_results`](https://docs.databricks.com/api/workspace/tables/listsummaries#max_results)int32

<= 10000 

Maximum number of summaries for tables to return. If not set, the page length is set to a server configured value (10000, as of 1/5/2024).

*   when set to a value greater than 0, the page length is the minimum of this value and a server configured value (10000, as of 1/5/2024);
*   when set to 0, the page length is set to a server configured value (10000, as of 1/5/2024) (recommended);
*   when set to a value less than 0, an invalid parameter error is returned;

[`page_token`](https://docs.databricks.com/api/workspace/tables/listsummaries#page_token)string

Opaque pagination token to go to next page based on previous query.

[`include_manifest_capabilities`](https://docs.databricks.com/api/workspace/tables/listsummaries#include_manifest_capabilities)boolean

Whether to include a manifest containing table capabilities in the response.

### Responses

**200** Request completed successfully. The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

Request completed successfully.

 The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

[`next_page_token`](https://docs.databricks.com/api/workspace/tables/listsummaries#next_page_token)string

Opaque token to retrieve the next page of results. Absent if there are no more pages. page_token should be set to this value for the next request (for the next page of results).

[`tables`](https://docs.databricks.com/api/workspace/tables/listsummaries#tables)Array of object

List of table summaries.

Array [

[`full_name`](https://docs.databricks.com/api/workspace/tables/listsummaries#tables-full_name)string

The full name of the table.

[`securable_kind_manifest`](https://docs.databricks.com/api/workspace/tables/listsummaries#tables-securable_kind_manifest)object

SecurableKindManifest of table, including capabilities the table has.

[`table_type`](https://docs.databricks.com/api/workspace/tables/listsummaries#tables-table_type)string

Enum: `MANAGED | EXTERNAL | VIEW | MATERIALIZED_VIEW | STREAMING_TABLE | MANAGED_SHALLOW_CLONE | FOREIGN | EXTERNAL_SHALLOW_CLONE | METRIC_VIEW`

 ]

# Response samples

200

{

"next_page_token":"string",

"tables":[

{

"full_name":"string",

"securable_kind_manifest":{

"assignable_privileges":[

"string"

],

"capabilities":[

"string"

],

"options":[

{

"allowed_values":[

"string"

],

"default_value":"string",

"description":"string",

"hint":"string",

"is_copiable":true,

"is_creatable":true,

"is_hidden":true,

"is_loggable":true,

"is_required":true,

"is_secret":true,

"is_updatable":true,

"name":"string",

"oauth_stage":"BEFORE_AUTHORIZATION_C ODE",

"type":"OPTION_BOOLEAN"

}

],

"securable_kind":"TABLE_STANDARD",

"securable_type":"CATALOG"

},

"table_type":"MANAGED"

}

]

}
