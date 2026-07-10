Title: Delete a file/directory | DBFS API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/dbfs/delete

Markdown Content:
## Delete a file/directory

`POST/api/2.0/dbfs/delete`

Delete the file or directory (optionally recursively delete all files in the directory). This call throws an exception with `IO_ERROR` if the path is a non-empty directory and `recursive` is set to `false` or on other similar errors.

When you delete a large number of files, the delete operation is done in increments. The call returns a response after approximately 45 seconds with an error message (503 Service Unavailable) asking you to re-invoke the delete operation until the directory structure is fully deleted.

For operations that delete more than 10K files, we discourage using the DBFS REST API, but advise you to perform such operations in the context of a cluster, using the [File system utility (dbutils.fs)](https://docs.databricks.com/dev-tools/databricks-utils.html#dbutils-fs). `dbutils.fs` covers the functional scope of the DBFS REST API, but from notebooks. Running such operations using notebooks provides better control and manageability, such as selective deletes, and the possibility to automate periodic delete jobs.

API scopes (preview):[`files`](https://docs.databricks.com/api/workspace/api/scopes#files)

### Request body

[`path`](https://docs.databricks.com/api/workspace/dbfs/delete#path)required string

Example`"/mnt/foo"`

The path of the file or directory to delete. The path should be the absolute DBFS path.

[`recursive`](https://docs.databricks.com/api/workspace/dbfs/delete#recursive)boolean

Default`false`

Whether or not to recursively delete the directory's contents. Deleting empty directories can be done without providing the recursive flag.

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

"path":"/mnt/foo",

"recursive":false

}

# Response samples

200

{}
