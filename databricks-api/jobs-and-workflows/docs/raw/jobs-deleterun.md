Title: Delete a job run | Jobs API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/jobs/deleterun

Markdown Content:
## Delete a job run

`POST/api/2.2/jobs/runs/delete`

Deletes a non-active run. Returns an error if the run is active.

API scopes (preview):[`jobs`](https://docs.databricks.com/api/workspace/api/scopes#jobs)

### Request body

[`run_id`](https://docs.databricks.com/api/workspace/jobs/deleterun#run_id)required int64

Example`455644833`

ID of the run to delete.

### Responses

**200** Request completed successfully.

Request completed successfully.

 This method might return the following HTTP codes: 400, 401, 403, 429, 500

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

INVALID_PARAMETER_VALUE

Supplied value for a parameter was invalid.

401

UNAUTHORIZED

The request does not have valid authentication credentials for the operation.

403

PERMISSION_DENIED

Caller does not have permission to execute the specified operation.

429

REQUEST_LIMIT_EXCEEDED

Request is rejected due to throttling.

500

INTERNAL_SERVER_ERROR

Internal error.

# Request samples

JSON

{

"run_id":455644833

}
