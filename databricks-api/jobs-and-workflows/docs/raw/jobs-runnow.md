Title: Trigger a new job run | Jobs API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/jobs/runnow

Markdown Content:
## Trigger a new job run

`POST/api/2.2/jobs/run-now`

Run a job and return the `run_id` of the triggered run.

API scopes (preview):[`jobs`](https://docs.databricks.com/api/workspace/api/scopes#jobs)

### Request body

[`idempotency_token`](https://docs.databricks.com/api/workspace/jobs/runnow#idempotency_token)string

Example`"8f018174-4792-40d5-bcbc-3e6a527352c8"`

An optional token to guarantee the idempotency of job run requests. If a run with the provided token already exists, the request does not create a new run but returns the ID of the existing run instead. If a run with the provided token is deleted, an error is returned.

If you specify the idempotency token, upon failure you can retry until the request succeeds. Databricks guarantees that exactly one run is launched with that idempotency token.

This token must have at most 64 characters.

For more information, see [How to ensure idempotency for jobs](https://kb.databricks.com/jobs/jobs-idempotency.html).

[`job_id`](https://docs.databricks.com/api/workspace/jobs/runnow#job_id)required int64

Example`11223344`

The ID of the job to be executed

[`job_parameters`](https://docs.databricks.com/api/workspace/jobs/runnow#job_parameters)object

Job-level parameters used in the run. for example `"param": "overriding_val"`

[`only`](https://docs.databricks.com/api/workspace/jobs/runnow#only)Array of string

A list of task keys to run inside of the job. If this field is not provided, all tasks in the job will be run.

[`performance_target`](https://docs.databricks.com/api/workspace/jobs/runnow#performance_target)string

Enum: `PERFORMANCE_OPTIMIZED | STANDARD`

The performance mode on a serverless job. The performance target determines the level of compute performance or cost-efficiency for the run. This field overrides the performance target defined on the job level.

*   `STANDARD`: Enables cost-efficient execution of serverless workloads.
*   `PERFORMANCE_OPTIMIZED`: Prioritizes fast startup and execution times through rapid scaling and optimized cluster performance.

[`pipeline_params`](https://docs.databricks.com/api/workspace/jobs/runnow#pipeline_params)object

Controls whether the pipeline should perform a full refresh

[`full_refresh`](https://docs.databricks.com/api/workspace/jobs/runnow#pipeline_params-full_refresh)boolean

Default`false`

If true, triggers a full refresh on the delta live table.

[`queue`](https://docs.databricks.com/api/workspace/jobs/runnow#queue)object

The queue settings of the run.

[`enabled`](https://docs.databricks.com/api/workspace/jobs/runnow#queue-enabled)required boolean

Default`true`

If true, enable queueing for the job. This is a required field.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`number_in_job`](https://docs.databricks.com/api/workspace/jobs/runnow#number_in_job)int64

Deprecated

Example`455644833`

A unique identifier for this job run. This is set to the same value as `run_id`.

[`run_id`](https://docs.databricks.com/api/workspace/jobs/runnow#run_id)int64

Example`455644833`

The globally unique ID of the newly triggered run.

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

"idempotency_token":"8f018174-4792-40d5-bcbc-3e 6a527352c8",

"job_id":11223344,

"job_parameters":{

"property1":"string",

"property2":"string"

},

"only":[

"notebook_task_1"

],

"performance_target":"PERFORMANCE_OPTIMIZED",

"pipeline_params":{

"full_refresh":false

},

"queue":{

"enabled":true

}

}

# Response samples

200

{

"number_in_job":455644833,

"run_id":455644833

}
