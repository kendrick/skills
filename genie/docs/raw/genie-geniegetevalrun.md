Title: Get benchmark evaluation run | Genie API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/genie/geniegetevalrun

Markdown Content:
## Get benchmark evaluation run

Beta

`GET/api/2.0/genie/spaces/{space_id}/eval-runs/{eval_run_id}`

Get evaluation run details.

API scopes:[`genie`](https://docs.databricks.com/api/workspace/api/scopes#genie)

### Path parameters

[`space_id`](https://docs.databricks.com/api/workspace/genie/geniegetevalrun#space_id)required uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

The ID associated with the Genie space where the evaluation run is located.

[`eval_run_id`](https://docs.databricks.com/api/workspace/genie/geniegetevalrun#eval_run_id)required uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

### Responses

**200** Request completed successfully.

Request completed successfully.

[`created_timestamp`](https://docs.databricks.com/api/workspace/genie/geniegetevalrun#created_timestamp)int64

Timestamp when the evaluation run was created (milliseconds since epoch).

[`eval_run_id`](https://docs.databricks.com/api/workspace/genie/geniegetevalrun#eval_run_id)uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

The unique identifier for the evaluation run.

[`eval_run_status`](https://docs.databricks.com/api/workspace/genie/geniegetevalrun#eval_run_status)string

Enum: `RUNNING | DONE | NOT_STARTED | EVALUATION_FAILED | EVALUATION_CANCELLED | EVALUATION_TIMEOUT`

Current status of the evaluation run.

[`last_updated_timestamp`](https://docs.databricks.com/api/workspace/genie/geniegetevalrun#last_updated_timestamp)int64

Timestamp when the evaluation run was last updated (milliseconds since epoch).

[`num_correct`](https://docs.databricks.com/api/workspace/genie/geniegetevalrun#num_correct)int64

Number of questions answered correctly.

[`num_done`](https://docs.databricks.com/api/workspace/genie/geniegetevalrun#num_done)int64

Number of questions that have been completed.

[`num_needs_review`](https://docs.databricks.com/api/workspace/genie/geniegetevalrun#num_needs_review)int64

Number of questions that need manual review.

[`num_questions`](https://docs.databricks.com/api/workspace/genie/geniegetevalrun#num_questions)int64

Total number of questions in the evaluation run.

[`run_by_user`](https://docs.databricks.com/api/workspace/genie/geniegetevalrun#run_by_user)int64

User ID who initiated the evaluation run.

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

UNAUTHORIZED

The request does not have valid authentication credentials for the operation.

403

PERMISSION_DENIED

Caller does not have permission to execute the specified operation.

404

NOT_FOUND, FEATURE_DISABLED

NOT_FOUND - Operation was performed on a resource that does not exist. FEATURE_DISABLED - If a given user/entity is trying to use a feature which has been disabled.

500

INTERNAL_ERROR

Internal error.

# Response samples

200

{

"created_timestamp":0,

"eval_run_id":"e1ef34712a29169db030324fd0e1df5f",

"eval_run_status":"RUNNING",

"last_updated_timestamp":0,

"num_correct":0,

"num_done":0,

"num_needs_review":0,

"num_questions":0,

"run_by_user":0

}
