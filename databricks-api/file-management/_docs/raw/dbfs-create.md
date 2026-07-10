Title: Open a stream | DBFS API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/dbfs/create

Markdown Content:
## Open a stream

`POST/api/2.0/dbfs/create`

Opens a stream to write to a file and returns a handle to this stream. There is a 10 minute idle timeout on this handle. If a file or directory already exists on the given path and overwrite is set to false, this call will throw an exception with `RESOURCE_ALREADY_EXISTS`.

A typical workflow for file upload would be:

1.   Issue a `create` call and get a handle.
2.   Issue one or more `add-block` calls with the handle you have.
3.   Issue a `close` call with the handle you have.

API scopes (preview):[`files`](https://docs.databricks.com/api/workspace/api/scopes#files)

### Request body

[`overwrite`](https://docs.databricks.com/api/workspace/dbfs/create#overwrite)boolean

Default`false`

The flag that specifies whether to overwrite existing file/files.

[`path`](https://docs.databricks.com/api/workspace/dbfs/create#path)required string

Example`"/mnt/foo"`

The path of the new file. The path should be the absolute DBFS path.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`handle`](https://docs.databricks.com/api/workspace/dbfs/create#handle)int64

Handle which should subsequently be passed into the AddBlock and Close calls when writing to a file through a stream.

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

JSON Terraform

{

"overwrite":false,

"path":"/mnt/foo"

}

# Response samples

200

{

"handle":0

}
