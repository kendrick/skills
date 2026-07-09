Title: List system schemas | SystemSchemas API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/systemschemas/list

Markdown Content:
## List system schemas

Public preview

`GET/api/2.1/unity-catalog/metastores/{metastore_id}/systemschemas`

Gets an array of system schemas for a metastore. The caller must be an account admin or a metastore admin.

NOTE: we recommend using max_results=0 to use the paginated version of this API. Unpaginated calls will be deprecated soon.

PAGINATION BEHAVIOR: When using pagination (max_results >= 0), a page may contain zero results while still providing a next_page_token. Clients must continue reading pages until next_page_token is absent, which is the only indication that the end of results has been reached.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`metastore_id`](https://docs.databricks.com/api/workspace/systemschemas/list#metastore_id)required string

The ID for the metastore in which the system schema resides.

### Query parameters

[`max_results`](https://docs.databricks.com/api/workspace/systemschemas/list#max_results)int32

<= 1000 

Maximum number of schemas to return.

*   When set to 0, the page length is set to a server configured value (recommended);
*   When set to a value greater than 0, the page length is the minimum of this value and a server configured value;
*   When set to a value less than 0, an invalid parameter error is returned;
*   If not set, all the schemas are returned (not recommended).

[`page_token`](https://docs.databricks.com/api/workspace/systemschemas/list#page_token)string

Opaque pagination token to go to next page based on previous query.

### Responses

**200** Request completed successfully. The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

Request completed successfully.

 The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

[`next_page_token`](https://docs.databricks.com/api/workspace/systemschemas/list#next_page_token)string

Opaque token to retrieve the next page of results. Absent if there are no more pages. page_token should be set to this value for the next request (for the next page of results).

[`schemas`](https://docs.databricks.com/api/workspace/systemschemas/list#schemas)Array of object

An array of system schema information objects.

Array [

[`schema`](https://docs.databricks.com/api/workspace/systemschemas/list#schemas-schema)string

Name of the system schema.

[`state`](https://docs.databricks.com/api/workspace/systemschemas/list#schemas-state)string

The current state of enablement for the system schema. An empty string means the system schema is available and ready for opt-in. Possible values: AVAILABLE | ENABLE_INITIALIZED | ENABLE_COMPLETED | DISABLE_INITIALIZED | UNAVAILABLE | MANAGED

 ]

# Response samples

200

{

"next_page_token":"string",

"schemas":[

{

"schema":"string",

"state":"string"

}

]

}
