Title: Close the stream | DBFS API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/dbfs/close

Markdown Content:
## Close the stream

`POST/api/2.0/dbfs/close`

Closes the stream specified by the input handle. If the handle does not exist, this call throws an exception with `RESOURCE_DOES_NOT_EXIST`.

API scopes (preview):[`files`](https://docs.databricks.com/api/workspace/api/scopes#files)

### Request body

[`handle`](https://docs.databricks.com/api/workspace/dbfs/close#handle)required int64

The handle on an open stream.

### Responses

**200** Request completed successfully.

Request completed successfully.

 This method might return the following HTTP codes: 400, 401, 404, 500

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

404

NOT_FOUND

Operation was performed on a resource that does not exist.

500

INTERNAL_SERVER_ERROR

Internal error.

# Request samples

JSON

{

"handle":0

}

# Response samples

200

{}
