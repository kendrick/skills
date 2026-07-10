Title: Get the contents of a file | DBFS API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/dbfs/read

Markdown Content:
## Get the contents of a file

`GET/api/2.0/dbfs/read`

Returns the contents of a file. If the file does not exist, this call throws an exception with `RESOURCE_DOES_NOT_EXIST`. If the path is a directory, the read length is negative, or if the offset is negative, this call throws an exception with `INVALID_PARAMETER_VALUE`. If the read length exceeds 1 MB, this call throws an exception with `MAX_READ_SIZE_EXCEEDED`.

If `offset + length` exceeds the number of bytes in a file, it reads the contents until the end of file.

API scopes:[`files`](https://docs.databricks.com/api/workspace/api/scopes#files)

### Query parameters

[`path`](https://docs.databricks.com/api/workspace/dbfs/read#path)required string

Example`path=/mnt/foo`

The path of the file to read. The path should be the absolute DBFS path.

[`offset`](https://docs.databricks.com/api/workspace/dbfs/read#offset)int64

Default`0`

The offset to read from in bytes.

[`length`](https://docs.databricks.com/api/workspace/dbfs/read#length)int64

Default`524288`

The number of bytes to read starting from the offset. This has a limit of 1 MB, and a default value of 0.5 MB.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`bytes_read`](https://docs.databricks.com/api/workspace/dbfs/read#bytes_read)int64

The number of bytes read (could be less than `length` if we hit end of file). This refers to number of bytes read in unencoded version (response data is base64-encoded).

[`data`](https://docs.databricks.com/api/workspace/dbfs/read#data)string

The base64-encoded contents of the file read.

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

# Response samples

200

{

"bytes_read":0,

"data":"string"

}
