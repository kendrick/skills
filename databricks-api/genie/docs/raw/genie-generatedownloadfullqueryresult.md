Title: Generate full query result download | Genie API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/genie/generatedownloadfullqueryresult

Markdown Content:
## Generate full query result download

`POST/api/2.0/genie/spaces/{space_id}/conversations/{conversation_id}/messages/{message_id}/attachments/{attachment_id}/downloads`

Initiates a new SQL execution and returns a `download_id` and `download_id_signature` that you can use to track the progress of the download. The query result is stored in an external link and can be retrieved using the [Get Download Full Query Result](https://docs.databricks.com/api/workspace/genie/getdownloadfullqueryresult) API. Both `download_id` and `download_id_signature` must be provided when calling the Get endpoint.

* * *

### Warning: Databricks strongly recommends that you protect the URLs that are returned by the `EXTERNAL_LINKS` disposition.

When you use the `EXTERNAL_LINKS` disposition, a short-lived, presigned URL is generated, which can be used to download the results directly from Amazon S3. As a short-lived access credential is embedded in this presigned URL, you should protect the URL.

Because presigned URLs are already generated with embedded temporary access credentials, you must not set an `Authorization` header in the download requests.

See [Execute Statement](https://docs.databricks.com/api/workspace/statementexecution/executestatement) for more details.

* * *

API scopes:[`genie`](https://docs.databricks.com/api/workspace/api/scopes#genie)

### Path parameters

[`space_id`](https://docs.databricks.com/api/workspace/genie/generatedownloadfullqueryresult#space_id)required uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

Genie space ID

[`conversation_id`](https://docs.databricks.com/api/workspace/genie/generatedownloadfullqueryresult#conversation_id)required uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

Conversation ID

[`message_id`](https://docs.databricks.com/api/workspace/genie/generatedownloadfullqueryresult#message_id)required uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

Message ID

[`attachment_id`](https://docs.databricks.com/api/workspace/genie/generatedownloadfullqueryresult#attachment_id)required uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

Attachment ID

### Responses

**200** Request completed successfully.

Request completed successfully.

[`download_id`](https://docs.databricks.com/api/workspace/genie/generatedownloadfullqueryresult#download_id)string

Example`"01eda0e7-e315-1846-84e2-79a963ffad44"`

Download ID. Use this ID to track the download request in subsequent polling calls

[`download_id_signature`](https://docs.databricks.com/api/workspace/genie/generatedownloadfullqueryresult#download_id_signature)string

JWT signature for the download_id to ensure secure access to query results

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

"download_id":"01eda0e7-e315-1846-84e2-79a963ff ad44",

"download_id_signature":"string"

}
