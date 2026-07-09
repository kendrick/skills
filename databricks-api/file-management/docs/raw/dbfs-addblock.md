Title: Append data block | DBFS API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/dbfs/addblock

Markdown Content:
## Append data block

`POST/api/2.0/dbfs/add-block`

Appends a block of data to the stream specified by the input handle. If the handle does not exist, this call will throw an exception with `RESOURCE_DOES_NOT_EXIST`.

If the block of data exceeds 1 MB, this call will throw an exception with `MAX_BLOCK_SIZE_EXCEEDED`.

API scopes (preview):[`files`](https://docs.databricks.com/api/workspace/api/scopes#files)

### Request body

[`data`](https://docs.databricks.com/api/workspace/dbfs/addblock#data)required string

The base64-encoded data to append to the stream. This has a limit of 1 MB.

[`handle`](https://docs.databricks.com/api/workspace/dbfs/addblock#handle)required int64

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

"data":"string",

"handle":0

}

# Response samples

200

{}
