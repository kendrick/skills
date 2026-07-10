Title: List directory contents or file details | DBFS API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/dbfs/list

Markdown Content:
## List directory contents or file details

`GET/api/2.0/dbfs/list`

List the contents of a directory, or details of the file. If the file or directory does not exist, this call throws an exception with `RESOURCE_DOES_NOT_EXIST`.

When calling list on a large directory, the list operation will time out after approximately 60 seconds. We strongly recommend using list only on directories containing less than 10K files and discourage using the DBFS REST API for operations that list more than 10K files. Instead, we recommend that you perform such operations in the context of a cluster, using the [File system utility (dbutils.fs)](https://docs.databricks.com/dev-tools/databricks-utils.html#dbutils-fs), which provides the same functionality without timing out.

API scopes (preview):[`files`](https://docs.databricks.com/api/workspace/api/scopes#files)

### Query parameters

[`path`](https://docs.databricks.com/api/workspace/dbfs/list#path)required string

Example`path=/mnt/foo`

The path of the file or directory. The path should be the absolute DBFS path.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`files`](https://docs.databricks.com/api/workspace/dbfs/list#files)Array of object

A list of FileInfo's that describe contents of directory or file. See example above.

Array [

[`file_size`](https://docs.databricks.com/api/workspace/dbfs/list#files-file_size)int64

The length of the file in bytes. This field is omitted for directories.

[`is_dir`](https://docs.databricks.com/api/workspace/dbfs/list#files-is_dir)boolean

True if the path is a directory.

[`modification_time`](https://docs.databricks.com/api/workspace/dbfs/list#files-modification_time)int64

Last modification time of given file in milliseconds since epoch.

[`path`](https://docs.databricks.com/api/workspace/dbfs/list#files-path)string

The absolute path of the file or directory.

 ]

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

"files":[

{

"file_size":0,

"is_dir":true,

"modification_time":0,

"path":"string"

}

]

}
