Title: Execute message attachment SQL query | Genie API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/genie/executemessageattachmentquery

Markdown Content:
## Execute message attachment SQL query

`POST/api/2.0/genie/spaces/{space_id}/conversations/{conversation_id}/messages/{message_id}/attachments/{attachment_id}/execute-query`

Execute the SQL for a message query attachment. Use this API when the query attachment has expired and needs to be re-executed.

API scopes:[`genie`](https://docs.databricks.com/api/workspace/api/scopes#genie)

### Path parameters

[`space_id`](https://docs.databricks.com/api/workspace/genie/executemessageattachmentquery#space_id)required uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

Genie space ID

[`conversation_id`](https://docs.databricks.com/api/workspace/genie/executemessageattachmentquery#conversation_id)required uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

Conversation ID

[`message_id`](https://docs.databricks.com/api/workspace/genie/executemessageattachmentquery#message_id)required uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

Message ID

[`attachment_id`](https://docs.databricks.com/api/workspace/genie/executemessageattachmentquery#attachment_id)required uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

Attachment ID

### Responses

**200** Request completed successfully.

Request completed successfully.

[`statement_response`](https://docs.databricks.com/api/workspace/genie/executemessageattachmentquery#statement_response)object

SQL Statement Execution response. See [Get status, manifest, and result first chunk](https://docs.databricks.com/api/workspace/statementexecution/getstatement) for more details.

[`manifest`](https://docs.databricks.com/api/workspace/genie/executemessageattachmentquery#statement_response-manifest)object

The result manifest provides schema and metadata for the result set.

[`result`](https://docs.databricks.com/api/workspace/genie/executemessageattachmentquery#statement_response-result)object

Contains the result data of a single chunk when using `INLINE` disposition. When using `EXTERNAL_LINKS` disposition, the array `external_links` is used instead to provide presigned URLs to the result data in cloud storage. Exactly one of these alternatives is used. (While the `external_links` array prepares the API to return multiple links in a single response. Currently only a single link is returned.)

[`statement_id`](https://docs.databricks.com/api/workspace/genie/executemessageattachmentquery#statement_response-statement_id)string

The statement ID is returned upon successfully submitting a SQL statement, and is a required reference for all subsequent calls.

[`status`](https://docs.databricks.com/api/workspace/genie/executemessageattachmentquery#statement_response-status)object

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

# Request samples

JSON

{}

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
