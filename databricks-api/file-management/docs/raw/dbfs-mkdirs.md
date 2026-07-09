Title: Create a directory | DBFS API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/dbfs/mkdirs

Markdown Content:
## Create a directory

`POST/api/2.0/dbfs/mkdirs`

Creates the given directory and necessary parent directories if they do not exist. If a file (not a directory) exists at any prefix of the input path, this call throws an exception with `RESOURCE_ALREADY_EXISTS`. Note: If this operation fails, it might have succeeded in creating some of the necessary parent directories.

API scopes (preview):[`files`](https://docs.databricks.com/api/workspace/api/scopes#files)

### Request body

[`path`](https://docs.databricks.com/api/workspace/dbfs/mkdirs#path)required string

Example`"/mnt/foo"`

The path of the new directory. The path should be the absolute DBFS path.

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

"path":"/mnt/foo"

}

# Response samples

200

{}
