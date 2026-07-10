Title: Get directory metadata | Files API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/files/getdirectorymetadata

Markdown Content:
## Get directory metadata

Public preview

`HEAD/api/2.0/fs/directories{directory_path}`

Get the metadata of a directory. The response HTTP headers contain the metadata. There is no response body.

This method is useful to check if a directory exists and the caller has access to it.

If you wish to ensure the directory exists, you can instead use `PUT`, which will create the directory if it does not exist, and is idempotent (it will succeed if the directory already exists).

API scopes (preview):[`files`](https://docs.databricks.com/api/workspace/api/scopes#files)

### Path parameters

[`directory_path`](https://docs.databricks.com/api/workspace/files/getdirectorymetadata#directory_path)required string

The absolute path of a directory.

Examples

Summary

`/Volumes/my-catalog/my-schema/my-volume/directory/`

A directory

### Responses

**200** Request completed successfully.

Request completed successfully.

 This method might return the following HTTP codes: 401, 500

Error responses are returned in the following format:

{

"error_code":"Error code",

"message":"Human-readable error message."

}

# Possible error codes:

HTTP code

error_code

Description

401

UNAUTHENTICATED

Request does not have valid authentication credentials for the operation.

500

INTERNAL_ERROR

Internal error.
