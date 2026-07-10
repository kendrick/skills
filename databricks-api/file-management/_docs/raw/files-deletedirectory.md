Title: Delete a directory | Files API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/files/deletedirectory

Markdown Content:
## Delete a directory

Public preview

`DELETE/api/2.0/fs/directories{directory_path}`

Deletes an empty directory.

To delete a non-empty directory, first delete all of its contents. This can be done by listing the directory contents and deleting each file and subdirectory recursively.

API scopes (preview):[`files`](https://docs.databricks.com/api/workspace/api/scopes#files)

### Path parameters

[`directory_path`](https://docs.databricks.com/api/workspace/files/deletedirectory#directory_path)required string

The absolute path of a directory.

Examples

Summary

`/Volumes/my-catalog/my-schema/my-volume/directory/`

A directory

### Responses

**204** Request successful, but no content returned.

Request successful, but no content returned.

 This method might return the following HTTP codes: 400, 401, 403, 404, 409, 500

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

UNAUTHENTICATED

Request does not have valid authentication credentials for the operation.

403

PERMISSION_DENIED

Caller does not have permission to execute the specified operation.

404

NOT_FOUND

Operation was performed on a resource that does not exist.

409

RESOURCE_CONFLICT

Request was rejected due a conflict with an existing resource.

500

INTERNAL_ERROR

Internal error.
