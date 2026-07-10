Title: Get download full query result | Genie API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/genie/getdownloadfullqueryresult

Markdown Content:
## Get download full query result

`GET/api/2.0/genie/spaces/{space_id}/conversations/{conversation_id}/messages/{message_id}/attachments/{attachment_id}/downloads/{download_id}`

After [Generating a Full Query Result Download](https://docs.databricks.com/api/workspace/genie/generatedownloadfullqueryresult) and successfully receiving a `download_id` and `download_id_signature`, use this API to poll the download progress. Both `download_id` and `download_id_signature` are required to call this endpoint. When the download is complete, the API returns the result in the `EXTERNAL_LINKS` disposition, containing one or more external links to the query result files.

* * *

### Warning: Databricks strongly recommends that you protect the URLs that are returned by the `EXTERNAL_LINKS` disposition.

When you use the `EXTERNAL_LINKS` disposition, a short-lived, presigned URL is generated, which can be used to download the results directly from Amazon S3. As a short-lived access credential is embedded in this presigned URL, you should protect the URL.

Because presigned URLs are already generated with embedded temporary access credentials, you must not set an `Authorization` header in the download requests.

See [Execute Statement](https://docs.databricks.com/api/workspace/statementexecution/executestatement) for more details.

* * *

API scopes:[`genie`](https://docs.databricks.com/api/workspace/api/scopes#genie)

### Path parameters

[`space_id`](https://docs.databricks.com/api/workspace/genie/getdownloadfullqueryresult#space_id)required uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

Genie space ID

[`conversation_id`](https://docs.databricks.com/api/workspace/genie/getdownloadfullqueryresult#conversation_id)required uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

Conversation ID

[`message_id`](https://docs.databricks.com/api/workspace/genie/getdownloadfullqueryresult#message_id)required uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

Message ID

[`attachment_id`](https://docs.databricks.com/api/workspace/genie/getdownloadfullqueryresult#attachment_id)required uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

Attachment ID

[`download_id`](https://docs.databricks.com/api/workspace/genie/getdownloadfullqueryresult#download_id)required uuid

Example`"01eda0e7-e315-1846-84e2-79a963ffad44"`

Download ID. This ID is provided by the [Generate Download endpoint](https://docs.databricks.com/api/workspace/genie/generatedownloadfullqueryresult)

### Query parameters

[`download_id_signature`](https://docs.databricks.com/api/workspace/genie/getdownloadfullqueryresult#download_id_signature)required string

JWT signature for the download_id to ensure secure access to query results

### Responses

**200** Request completed successfully.

Request completed successfully.

[`statement_response`](https://docs.databricks.com/api/workspace/genie/getdownloadfullqueryresult#statement_response)object

SQL Statement Execution response. See [Get status, manifest, and result first chunk](https://docs.databricks.com/api/workspace/statementexecution/getstatement) for more details.

[`manifest`](https://docs.databricks.com/api/workspace/genie/getdownloadfullqueryresult#statement_response-manifest)object

The result manifest provides schema and metadata for the result set.

[`result`](https://docs.databricks.com/api/workspace/genie/getdownloadfullqueryresult#statement_response-result)object

Contains the result data of a single chunk when using `INLINE` disposition. When using `EXTERNAL_LINKS` disposition, the array `external_links` is used instead to provide presigned URLs to the result data in cloud storage. Exactly one of these alternatives is used. (While the `external_links` array prepares the API to return multiple links in a single response. Currently only a single link is returned.)

[`statement_id`](https://docs.databricks.com/api/workspace/genie/getdownloadfullqueryresult#statement_response-statement_id)string

The statement ID is returned upon successfully submitting a SQL statement, and is a required reference for all subsequent calls.

[`status`](https://docs.databricks.com/api/workspace/genie/getdownloadfullqueryresult#statement_response-status)object

The status response includes execution state and if relevant, error information.

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

BAD_REQUEST

Request is invalid.

401

UNAUTHORIZED

The request does not have valid authentication credentials for the operation.

403

PERMISSION_DENIED

Caller does not have permission to execute the specified operation.

404

NOT_FOUND, FEATURE_DISABLED

NOT_FOUND - Operation was performed on a resource that does not exist. FEATURE_DISABLED - If a given user/entity is trying to use a feature which has been disabled.

500

INTERNAL_ERROR

Internal error.

# Response samples

200

{

"statement_response":{

"manifest":{

"chunks":[

{

"byte_count":0,

"chunk_index":0,

"row_count":0,

"row_offset":0

}

],

"format":"JSON_ARRAY",

"schema":{

"column_count":0,

"columns":[

{

"name":"string",

"position":0,

"type_interval_type":"string",

"type_name":"BOOLEAN",

"type_precision":0,

"type_scale":0,

"type_text":"string"

}

]

},

"total_byte_count":0,

"total_chunk_count":0,

"total_row_count":0,

"truncated":true

},

"result":{

"byte_count":0,

"chunk_index":0,

"data_array":[

[

"string"

]

],

"external_links":[

{

"byte_count":0,

"chunk_index":0,

"expiration":"2019-08-24T14:15:22Z",

"external_link":"string",

"next_chunk_index":0,

"next_chunk_internal_link":"string",

"row_count":0,

"row_offset":0

}

],

"next_chunk_index":0,

"next_chunk_internal_link":"string",

"row_count":0,

"row_offset":0

},

"statement_id":"string",

"status":{

"error":{

"error_code":"UNKNOWN",

"message":"string"

},

"sql_state":"string",

"state":"PENDING"

}

}

}
