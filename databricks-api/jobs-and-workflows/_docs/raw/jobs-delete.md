Title: Delete a job | Jobs API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/jobs/delete

Markdown Content:
## Delete a job

`POST/api/2.2/jobs/delete`

Deletes a job.

API scopes (preview):[`jobs`](https://docs.databricks.com/api/workspace/api/scopes#jobs)

### Request body

[`job_id`](https://docs.databricks.com/api/workspace/jobs/delete#job_id)required int64

Example`11223344`

The canonical identifier of the job to delete. This field is required.

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

"job_id":11223344

}
