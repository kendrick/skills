Title: List directory contents | Files API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/files/listdirectorycontents

Markdown Content:
## List directory contents

Public preview

`GET/api/2.0/fs/directories{directory_path}`

Returns the contents of a directory. If there is no directory at the specified path, the API returns a HTTP 404 error.

API scopes (preview):[`files`](https://docs.databricks.com/api/workspace/api/scopes#files)

### Path parameters

[`directory_path`](https://docs.databricks.com/api/workspace/files/listdirectorycontents#directory_path)required string

The absolute path of a directory.

Examples

Summary

`/Volumes/my-catalog/my-schema/my-volume/directory/`

A directory

### Query parameters

[`page_size`](https://docs.databricks.com/api/workspace/files/listdirectorycontents#page_size)int64

Default`1000`

The maximum number of directory entries to return. The response may contain fewer entries. If the response contains a `next_page_token`, there may be more entries, even if fewer than `page_size` entries are in the response.

We recommend not to set this value unless you are intentionally listing less than the complete directory contents.

If unspecified, at most 1000 directory entries will be returned. The maximum value is 1000. Values above 1000 will be coerced to 1000.

Examples

Summary

`page_size=0`

Passing zero implies the maximum page size

`page_size=100`

User defined page size

[`page_token`](https://docs.databricks.com/api/workspace/files/listdirectorycontents#page_token)string

An opaque page token which was the `next_page_token` in the response of the previous request to list the contents of this directory. Provide this token to retrieve the next page of directory entries. When providing a `page_token`, all other parameters provided to the request must match the previous request. To list all of the entries in a directory, it is necessary to continue requesting pages of entries until the response contains no `next_page_token`. Note that the number of entries returned must not be used to determine when the listing is complete.

### Responses

**200** Request completed successfully. The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

Request completed successfully.

 The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

[`contents`](https://docs.databricks.com/api/workspace/files/listdirectorycontents#contents)Array of object

Array of DirectoryEntry.

Array [

[`file_size`](https://docs.databricks.com/api/workspace/files/listdirectorycontents#contents-file_size)int64

The length of the file in bytes. This field is omitted for directories.

[`is_directory`](https://docs.databricks.com/api/workspace/files/listdirectorycontents#contents-is_directory)boolean

True if the path is a directory.

[`last_modified`](https://docs.databricks.com/api/workspace/files/listdirectorycontents#contents-last_modified)int64

Last modification time of given file in milliseconds since unix epoch.

[`name`](https://docs.databricks.com/api/workspace/files/listdirectorycontents#contents-name)string

The name of the file or directory. This is the last component of the path.

[`path`](https://docs.databricks.com/api/workspace/files/listdirectorycontents#contents-path)string

The absolute path of the file or directory.

 ]

[`next_page_token`](https://docs.databricks.com/api/workspace/files/listdirectorycontents#next_page_token)string

A token, which can be sent as `page_token` to retrieve the next page.

 This method might return the following HTTP codes: 400, 401, 403, 404, 409, 500

Error responses are returned in the following format:

{ "error_code": "Error code", "message": "Human-readable error message." }

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

# Response samples

200

{ "contents": [ { "file_size": 0, "is_directory": true, "last_modified": 0, "name": "string", "path": "string" } ], "next_page_token": "string" }
