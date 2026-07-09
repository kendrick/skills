Title: Download a file | Files API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/files/download

Markdown Content:
## Download a file

Public preview

`GET/api/2.0/fs/files{file_path}`

Downloads a file. The file contents are the response body. This is a standard HTTP file download, not a JSON RPC. It supports the Range and If-Unmodified-Since HTTP headers.

API scopes (preview):[`files`](https://docs.databricks.com/api/workspace/api/scopes#files)

### Path parameters

[`file_path`](https://docs.databricks.com/api/workspace/files/download#file_path)required string

The absolute path of the file.

Examples

Summary

`/Volumes/my-catalog/my-schema/my-volume/directory/file.txt`

A file

### Header parameters

[`Range`](https://docs.databricks.com/api/workspace/files/download#Range)string

The range of bytes to retrieve. The range is inclusive and zero-based, see [RFC 9110](https://datatracker.ietf.org/doc/html/rfc9110#name-range) for further details.

Examples

Summary

`bytes=0-499`

Retrieve the first 500 bytes

`bytes=500-`

Retrieve the 501st byte onwards

[`If-Unmodified-Since`](https://docs.databricks.com/api/workspace/files/download#If_Unmodified_Since)string

Download the file only if it has not been modified since the specified timestamp. If it has, a 412 Precondition Failed error will be returned. See [RFC 9110](https://datatracker.ietf.org/doc/html/rfc9110#name-if-unmodified-since) for further details.

Examples

Summary

`Wed, 24 Jan 2024 14:10:56 GMT`

The time that the file must be unmodified since

### Responses

**200** Request completed successfully.

Request completed successfully.

#### Response Headers

[`content-length`](https://docs.databricks.com/api/workspace/files/download#content_length)int64

The length of the HTTP response body in bytes.

[`content-type`](https://docs.databricks.com/api/workspace/files/download#content_type)string

Example`"application/octet-stream"`

[`last-modified`](https://docs.databricks.com/api/workspace/files/download#last_modified)HTTP-date

Example`"Wed, 24 Jan 2024 14:10:56 GMT"`

The last modified time of the file in HTTP-date (RFC 7231) format.

**206** Request successful. Partial content returned.

Request successful. Partial content returned.

#### Response Headers

[`content-length`](https://docs.databricks.com/api/workspace/files/download#content_length)int64

The length of the HTTP response body in bytes.

[`content-range`](https://docs.databricks.com/api/workspace/files/download#content_range)string

Example`"bytes 0-499/500"`

The position of the content of the response body within the complete file. Further information about this header is available in [RFC 9110](https://datatracker.ietf.org/doc/html/rfc9110#name-content-range).

[`content-type`](https://docs.databricks.com/api/workspace/files/download#content_type)string

Example`"application/octet-stream"`

[`last-modified`](https://docs.databricks.com/api/workspace/files/download#last_modified)HTTP-date

Example`"Wed, 24 Jan 2024 14:10:56 GMT"`

The last modified time of the file in HTTP-date (RFC 7231) format.

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
