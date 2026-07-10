Title: Get the information of a file or directory | DBFS API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/dbfs/getstatus

Markdown Content:
## Get the information of a file or directory

`GET/api/2.0/dbfs/get-status`

Gets the file information for a file or directory. If the file or directory does not exist, this call throws an exception with `RESOURCE_DOES_NOT_EXIST`.

API scopes (preview):[`files`](https://docs.databricks.com/api/workspace/api/scopes#files)

### Query parameters

[`path`](https://docs.databricks.com/api/workspace/dbfs/getstatus#path)required string

Example`path=/mnt/foo`

The path of the file or directory. The path should be the absolute DBFS path.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`file_size`](https://docs.databricks.com/api/workspace/dbfs/getstatus#file_size)int64

The length of the file in bytes. This field is omitted for directories.

[`is_dir`](https://docs.databricks.com/api/workspace/dbfs/getstatus#is_dir)boolean

True if the path is a directory.

[`modification_time`](https://docs.databricks.com/api/workspace/dbfs/getstatus#modification_time)int64

Last modification time of given file in milliseconds since epoch.

[`path`](https://docs.databricks.com/api/workspace/dbfs/getstatus#path)string

The absolute path of the file or directory.

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

"file_size":0,

"is_dir":true,

"modification_time":0,

"path":"string"

}
