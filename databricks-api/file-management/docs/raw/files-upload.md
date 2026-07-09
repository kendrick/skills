Title: Upload a file | Files API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/files/upload

Markdown Content:
## Upload a file

Public preview

`PUT/api/2.0/fs/files{file_path}`

Uploads a file of up to 5 GiB. The file contents should be sent as the request body as raw bytes (an octet stream); do not encode or otherwise modify the bytes before sending. The contents of the resulting file will be exactly the bytes sent in the request body. If the request is successful, there is no response body.

API scopes (preview):[`files`](https://docs.databricks.com/api/workspace/api/scopes#files)

### Path parameters

[`file_path`](https://docs.databricks.com/api/workspace/files/upload#file_path)required string

The absolute path of the file.

Examples

Summary

`/Volumes/my-catalog/my-schema/my-volume/directory/file.txt`

A file

### Query parameters

[`overwrite`](https://docs.databricks.com/api/workspace/files/upload#overwrite)boolean

If true or unspecified, an existing file will be overwritten. If false, an error will be returned if the path points to an existing file.

### Responses

**204** Request successful, but no content returned.

Request successful, but no content returned.

 This method might return the following HTTP codes: 400, 401, 500

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

500

INTERNAL_ERROR

Internal error.
