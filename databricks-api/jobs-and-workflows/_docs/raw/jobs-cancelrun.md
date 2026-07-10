Title: Cancel a run | Jobs API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/jobs/cancelrun

Markdown Content:
## Cancel a run

`POST/api/2.2/jobs/runs/cancel`

Cancels a job run or a task run. The run is canceled asynchronously, so it may still be running when this request completes.

API scopes (preview):[`jobs`](https://docs.databricks.com/api/workspace/api/scopes#jobs)

### Request body

[`run_id`](https://docs.databricks.com/api/workspace/jobs/cancelrun#run_id)required int64

Example`455644833`

This field is required.

### Responses

**200** Request completed successfully.

Request completed successfully.

 This method might return the following HTTP codes: 400, 401, 403, 429, 500

Error responses are returned in the following format:

{ "error_code": "Error code", "message": "Human-readable error message." }

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

{ "run_id": 455644833 }
