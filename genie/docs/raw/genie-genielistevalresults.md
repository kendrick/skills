Title: List benchmark evaluation results | Genie API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/genie/genielistevalresults

Markdown Content:
## List benchmark evaluation results

Beta

`GET/api/2.0/genie/spaces/{space_id}/eval-runs/{eval_run_id}/results`

List evaluation results for a specific evaluation run.

API scopes:[`genie`](https://docs.databricks.com/api/workspace/api/scopes#genie)

### Path parameters

[`space_id`](https://docs.databricks.com/api/workspace/genie/genielistevalresults#space_id)required uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

The ID associated with the Genie space where the evaluation run is located.

[`eval_run_id`](https://docs.databricks.com/api/workspace/genie/genielistevalresults#eval_run_id)required uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

The unique identifier for the evaluation run.

### Query parameters

[`page_size`](https://docs.databricks.com/api/workspace/genie/genielistevalresults#page_size)int32

<= 100 

Optional

Default`20`

Maximum number of eval results to return per page.

[`page_token`](https://docs.databricks.com/api/workspace/genie/genielistevalresults#page_token)string Optional

Opaque token to retrieve the next page of results.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`eval_results`](https://docs.databricks.com/api/workspace/genie/genielistevalresults#eval_results)Array of object

List of evaluation results for the specified run.

Array [

[`benchmark_answer`](https://docs.databricks.com/api/workspace/genie/genielistevalresults#eval_results-benchmark_answer)string

Stored snapshot of original benchmark answer text.

[`benchmark_question_id`](https://docs.databricks.com/api/workspace/genie/genielistevalresults#eval_results-benchmark_question_id)uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

The ID of the benchmark question that was evaluated.

[`created_by_user`](https://docs.databricks.com/api/workspace/genie/genielistevalresults#eval_results-created_by_user)int64

User ID who created evaluation result.

[`question`](https://docs.databricks.com/api/workspace/genie/genielistevalresults#eval_results-question)string

Stored snapshot of original benchmark question text.

[`result_id`](https://docs.databricks.com/api/workspace/genie/genielistevalresults#eval_results-result_id)uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

Unique identifier for this evaluation result.

[`space_id`](https://docs.databricks.com/api/workspace/genie/genielistevalresults#eval_results-space_id)uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

The ID of the space the evaluation result belongs to.

[`status`](https://docs.databricks.com/api/workspace/genie/genielistevalresults#eval_results-status)string

Enum: `RUNNING | DONE | NOT_STARTED | EVALUATION_FAILED | EVALUATION_CANCELLED | EVALUATION_TIMEOUT`

Current status of this evaluation result.

 ]

[`next_page_token`](https://docs.databricks.com/api/workspace/genie/genielistevalresults#next_page_token)string

The token to use for retrieving the next page of results.

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

"eval_results":[

{

"benchmark_answer":"string",

"benchmark_question_id":"e1ef34712a29169db0 30324fd0e1df5f",

"created_by_user":0,

"question":"string",

"result_id":"e1ef34712a29169db030324fd0e1df 5f",

"space_id":"e1ef34712a29169db030324fd0e1df5 f",

"status":"RUNNING"

}

],

"next_page_token":"string"

}
