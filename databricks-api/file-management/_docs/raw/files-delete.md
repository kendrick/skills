Title: Delete a file | Files API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/files/delete

Markdown Content:
## Delete a file

Public preview

`DELETE/api/2.0/fs/files{file_path}`

Deletes a file. If the request is successful, there is no response body.

API scopes (preview):[`files`](https://docs.databricks.com/api/workspace/api/scopes#files)

### Path parameters

[`file_path`](https://docs.databricks.com/api/workspace/files/delete#file_path)required string

The absolute path of the file.

Examples

Summary

`/Volumes/my-catalog/my-schema/my-volume/directory/file.txt`

A file

### Responses

**204** Request successful, but no content returned.

Request successful, but no content returned.

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

UNAUTHENTICATED

Request does not have valid authentication credentials for the operation.

403

PERMISSION_DENIED

Caller does not have permission to execute the specified operation.

404

NOT_FOUND

Operation was performed on a resource that does not exist.

500

INTERNAL_ERROR

Internal error.
