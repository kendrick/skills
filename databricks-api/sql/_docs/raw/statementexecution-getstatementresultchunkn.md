Title: Get result chunk by index | Statement Execution API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/statementexecution/getstatementresultchunkn

Markdown Content:
## Get result chunk by index

`GET/api/2.0/sql/statements/{statement_id}/result/chunks/{chunk_index}`

After the statement execution has `SUCCEEDED`, this request can be used to fetch any chunk by index. Whereas the first chunk with `chunk_index=0` is typically fetched with [statementexecution/executestatement](https://docs.databricks.com/api/workspace/statementexecution/executestatement) or [statementexecution/getstatement](https://docs.databricks.com/api/workspace/statementexecution/getstatement), this request can be used to fetch subsequent chunks. The response structure is identical to the nested `result` element described in the [statementexecution/getstatement](https://docs.databricks.com/api/workspace/statementexecution/getstatement) request, and similarly includes the `next_chunk_index` and `next_chunk_internal_link` fields for simple iteration through the result set. Depending on `disposition`, the response returns chunks of data either inline, or as links.

API scopes (preview):[`sql`](https://docs.databricks.com/api/workspace/api/scopes#sql)

### Path parameters

[`statement_id`](https://docs.databricks.com/api/workspace/statementexecution/getstatementresultchunkn#statement_id)required string

The statement ID is returned upon successfully submitting a SQL statement, and is a required reference for all subsequent calls.

[`chunk_index`](https://docs.databricks.com/api/workspace/statementexecution/getstatementresultchunkn#chunk_index)required int32

### Responses

**200** Request completed successfully.

Request completed successfully.

[`byte_count`](https://docs.databricks.com/api/workspace/statementexecution/getstatementresultchunkn#byte_count)int64

The number of bytes in the result chunk. This field is not available when using `INLINE` disposition.

[`chunk_index`](https://docs.databricks.com/api/workspace/statementexecution/getstatementresultchunkn#chunk_index)int32

The position within the sequence of result set chunks.

[`data_array`](https://docs.databricks.com/api/workspace/statementexecution/getstatementresultchunkn#data_array)Array of Array of string

The `JSON_ARRAY` format is an array of arrays of values, where each non-null value is formatted as a string. Null values are encoded as JSON `null`.

[`external_links`](https://docs.databricks.com/api/workspace/statementexecution/getstatementresultchunkn#external_links)Array of object

Array [

[`byte_count`](https://docs.databricks.com/api/workspace/statementexecution/getstatementresultchunkn#external_links-byte_count)int64

The number of bytes in the result chunk. This field is not available when using `INLINE` disposition.

[`chunk_index`](https://docs.databricks.com/api/workspace/statementexecution/getstatementresultchunkn#external_links-chunk_index)int32

The position within the sequence of result set chunks.

[`expiration`](https://docs.databricks.com/api/workspace/statementexecution/getstatementresultchunkn#external_links-expiration)date-time

Indicates the date-time that the given external link will expire and becomes invalid, after which point a new `external_link` must be requested.

[`external_link`](https://docs.databricks.com/api/workspace/statementexecution/getstatementresultchunkn#external_links-external_link)string

A presigned URL pointing to a chunk of result data, hosted by an external service, with a short expiration time (<= 15 minutes). As this URL contains a temporary credential, it should be considered sensitive and the client should not expose this URL in a log.

[`next_chunk_index`](https://docs.databricks.com/api/workspace/statementexecution/getstatementresultchunkn#external_links-next_chunk_index)int32

When fetching, provides the `chunk_index` for the _next_ chunk. If absent, indicates there are no more chunks. The next chunk can be fetched with a [statementexecution/getstatementresultchunkn](https://docs.databricks.com/api/workspace/statementexecution/getstatementresultchunkn) request.

[`next_chunk_internal_link`](https://docs.databricks.com/api/workspace/statementexecution/getstatementresultchunkn#external_links-next_chunk_internal_link)string

When fetching, provides a link to fetch the _next_ chunk. If absent, indicates there are no more chunks. This link is an absolute `path` to be joined with your `$DATABRICKS_HOST`, and should be treated as an opaque link. This is an alternative to using `next_chunk_index`.

[`row_count`](https://docs.databricks.com/api/workspace/statementexecution/getstatementresultchunkn#external_links-row_count)int64

The number of rows within the result chunk.

[`row_offset`](https://docs.databricks.com/api/workspace/statementexecution/getstatementresultchunkn#external_links-row_offset)int64

The starting row offset within the result set.

 ]

[`next_chunk_index`](https://docs.databricks.com/api/workspace/statementexecution/getstatementresultchunkn#next_chunk_index)int32

When fetching, provides the `chunk_index` for the _next_ chunk. If absent, indicates there are no more chunks. The next chunk can be fetched with a [statementexecution/getstatementresultchunkn](https://docs.databricks.com/api/workspace/statementexecution/getstatementresultchunkn) request.

[`next_chunk_internal_link`](https://docs.databricks.com/api/workspace/statementexecution/getstatementresultchunkn#next_chunk_internal_link)string

When fetching, provides a link to fetch the _next_ chunk. If absent, indicates there are no more chunks. This link is an absolute `path` to be joined with your `$DATABRICKS_HOST`, and should be treated as an opaque link. This is an alternative to using `next_chunk_index`.

[`row_count`](https://docs.databricks.com/api/workspace/statementexecution/getstatementresultchunkn#row_count)int64

The number of rows within the result chunk.

[`row_offset`](https://docs.databricks.com/api/workspace/statementexecution/getstatementresultchunkn#row_offset)int64

The starting row offset within the result set.

 This method might return the following HTTP codes: 400, 401, 403, 404, 429, 500, 503

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

INVALID_PARAMETER_VALUE

Supplied value for a parameter was invalid.

401

UNAUTHENTICATED

Request does not have valid authentication credentials for the operation.

403

PERMISSION_DENIED

Caller does not have permission to execute the specified operation.

404

NOT_FOUND

Operation was performed on a resource that does not exist.

429

REQUEST_LIMIT_EXCEEDED

Request is rejected due to throttling.

500

INTERNAL_ERROR

Internal error.

503

TEMPORARILY_UNAVAILABLE

Service is currently unavailable.

# Response samples

200

EXTERNAL_LINKS, has next chunk

{

"external_links":[

{

"byte_count":24486486,

"chunk_index":0,

"expiration":"2023-01-30T22:23:23.140Z",

"external_link":"https://someplace.cloud-pr ovider.com/very/long/path/...",

"next_chunk_index":1,

"next_chunk_internal_link":"/api/2.0/sql/st atements/01ee4b3f-4f56-1648-825a-c261d31be5f1/resu lt/chunks/1",

"row_count":100,

"row_offset":0

}

]

}
