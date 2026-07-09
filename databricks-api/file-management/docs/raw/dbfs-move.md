Title: Move a file | DBFS API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/dbfs/move

Markdown Content:
## Move a file

`POST/api/2.0/dbfs/move`

Moves a file from one location to another location within DBFS. If the source file does not exist, this call throws an exception with `RESOURCE_DOES_NOT_EXIST`. If a file already exists in the destination path, this call throws an exception with `RESOURCE_ALREADY_EXISTS`. If the given source path is a directory, this call always recursively moves all files.

API scopes (preview):[`files`](https://docs.databricks.com/api/workspace/api/scopes#files)

### Request body

[`destination_path`](https://docs.databricks.com/api/workspace/dbfs/move#destination_path)required string

Example`"/mnt/bar"`

The destination path of the file or directory. The path should be the absolute DBFS path.

[`source_path`](https://docs.databricks.com/api/workspace/dbfs/move#source_path)required string

Example`"/mnt/foo"`

The source path of the file or directory. The path should be the absolute DBFS path.

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

"destination_path":"/mnt/bar",

"source_path":"/mnt/foo"

}

# Response samples

200

{}
