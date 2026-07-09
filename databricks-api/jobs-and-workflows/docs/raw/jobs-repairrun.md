Title: Repair a job run | Jobs API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/jobs/repairrun

Markdown Content:
## Repair a job run

`POST/api/2.2/jobs/runs/repair`

Re-run one or more tasks. Tasks are re-run as part of the original job run. They use the current job and task settings, and can be viewed in the history for the original job run.

API scopes (preview):[`jobs`](https://docs.databricks.com/api/workspace/api/scopes#jobs)

### Request body

[`job_parameters`](https://docs.databricks.com/api/workspace/jobs/repairrun#job_parameters)object

Job-level parameters used in the run. for example `"param": "overriding_val"`

[`latest_repair_id`](https://docs.databricks.com/api/workspace/jobs/repairrun#latest_repair_id)int64

Example`734650698524280`

The ID of the latest repair. This parameter is not required when repairing a run for the first time, but must be provided on subsequent requests to repair the same run.

[`performance_target`](https://docs.databricks.com/api/workspace/jobs/repairrun#performance_target)string

Enum: `PERFORMANCE_OPTIMIZED | STANDARD`

The performance mode on a serverless job. The performance target determines the level of compute performance or cost-efficiency for the run. This field overrides the performance target defined on the job level.

*   `STANDARD`: Enables cost-efficient execution of serverless workloads.
*   `PERFORMANCE_OPTIMIZED`: Prioritizes fast startup and execution times through rapid scaling and optimized cluster performance.

[`pipeline_params`](https://docs.databricks.com/api/workspace/jobs/repairrun#pipeline_params)object

Controls whether the pipeline should perform a full refresh

[`full_refresh`](https://docs.databricks.com/api/workspace/jobs/repairrun#pipeline_params-full_refresh)boolean

Default`false`

If true, triggers a full refresh on the delta live table.

[`rerun_all_failed_tasks`](https://docs.databricks.com/api/workspace/jobs/repairrun#rerun_all_failed_tasks)boolean

Default`false`

If true, repair all failed tasks. Only one of `rerun_tasks` or `rerun_all_failed_tasks` can be used.

[`rerun_dependent_tasks`](https://docs.databricks.com/api/workspace/jobs/repairrun#rerun_dependent_tasks)boolean

Default`false`

If true, repair all tasks that depend on the tasks in `rerun_tasks`, even if they were previously successful. Can be also used in combination with `rerun_all_failed_tasks`.

[`rerun_tasks`](https://docs.databricks.com/api/workspace/jobs/repairrun#rerun_tasks)Array of string

Example

The task keys of the task runs to repair.

[`run_id`](https://docs.databricks.com/api/workspace/jobs/repairrun#run_id)required int64

Example`455644833`

The job run ID of the run to repair. The run must not be in progress.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`repair_id`](https://docs.databricks.com/api/workspace/jobs/repairrun#repair_id)int64

Example`734650698524280`

The ID of the repair. Must be provided in subsequent repairs using the `latest_repair_id` field to ensure sequential repairs.

 This method might return the following HTTP codes: 400, 401, 403, 500

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

500

INTERNAL_SERVER_ERROR

Internal error.

# Request samples

JSON

{

"job_parameters":{

"property1":"string",

"property2":"string"

},

"latest_repair_id":734650698524280,

"performance_target":"PERFORMANCE_OPTIMIZED",

"pipeline_params":{

"full_refresh":false

},

"rerun_all_failed_tasks":false,

"rerun_dependent_tasks":false,

"rerun_tasks":[

"task0",

"task1"

],

"run_id":455644833

}

# Response samples

200

{

"repair_id":734650698524280

}
