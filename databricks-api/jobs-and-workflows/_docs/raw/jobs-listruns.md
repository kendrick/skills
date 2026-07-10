Title: List job runs | Jobs API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/jobs/listruns

Markdown Content:
## List job runs

`GET/api/2.2/jobs/runs/list`

List runs in descending order by start time.

API scopes (preview):[`jobs`](https://docs.databricks.com/api/workspace/api/scopes#jobs)

### Query parameters

[`job_id`](https://docs.databricks.com/api/workspace/jobs/listruns#job_id)int64

Example`job_id=11223344`

The job for which to list runs. If omitted, the Jobs service lists runs from all jobs.

[`active_only`](https://docs.databricks.com/api/workspace/jobs/listruns#active_only)boolean

Example`active_only=false`

If active_only is `true`, only active runs are included in the results; otherwise, lists both active and completed runs. An active run is a run in the `QUEUED`, `PENDING`, `RUNNING`, or `TERMINATING`. This field cannot be `true` when completed_only is `true`.

[`completed_only`](https://docs.databricks.com/api/workspace/jobs/listruns#completed_only)boolean

Example`completed_only=false`

If completed_only is `true`, only completed runs are included in the results; otherwise, lists both active and completed runs. This field cannot be `true` when active_only is `true`.

[`limit`](https://docs.databricks.com/api/workspace/jobs/listruns#limit)int32

[ 1 .. 25 ] 

Default`20`

The number of runs to return. This value must be greater than 0 and less than 25. The default value is 20. If a request specifies a limit of 0, the service instead uses the maximum limit.

[`run_type`](https://docs.databricks.com/api/workspace/jobs/listruns#run_type)string

Enum: `JOB_RUN | WORKFLOW_RUN | SUBMIT_RUN`

Example`run_type=JOB_RUN`

The type of runs to return. For a description of run types, see [jobs/getrun](https://docs.databricks.com/api/workspace/jobs/getrun).

[`expand_tasks`](https://docs.databricks.com/api/workspace/jobs/listruns#expand_tasks)boolean

Default`false`

Whether to include task and cluster details in the response. Note that only the first 100 elements will be shown. Use [jobs/getrun](https://docs.databricks.com/api/workspace/jobs/getrun) to paginate through all tasks and clusters.

[`start_time_from`](https://docs.databricks.com/api/workspace/jobs/listruns#start_time_from)int64

Example`start_time_from=1642521600000`

Show runs that started _at or after_ this value. The value must be a UTC timestamp in milliseconds. Can be combined with _start\_time\_to_ to filter by a time range.

[`start_time_to`](https://docs.databricks.com/api/workspace/jobs/listruns#start_time_to)int64

Example`start_time_to=1642608000000`

Show runs that started _at or before_ this value. The value must be a UTC timestamp in milliseconds. Can be combined with _start\_time\_from_ to filter by a time range.

[`page_token`](https://docs.databricks.com/api/workspace/jobs/listruns#page_token)string

Example`page_token=CAEomPSriYcxMPWM_IiIxvEB`

Use `next_page_token` or `prev_page_token` returned from the previous request to list the next or previous page of runs respectively.

### Responses

**200** Request completed successfully. The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

Request completed successfully.

 The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

[`next_page_token`](https://docs.databricks.com/api/workspace/jobs/listruns#next_page_token)string

Example`"CAEomPuciYcxMKbM9JvMlwU="`

A token that can be used to list the next page of runs (if applicable).

[`prev_page_token`](https://docs.databricks.com/api/workspace/jobs/listruns#prev_page_token)string

Example`"CAAos-uriYcxMN7_rt_v7B4="`

A token that can be used to list the previous page of runs (if applicable).

[`runs`](https://docs.databricks.com/api/workspace/jobs/listruns#runs)Array of object

A list of runs, from most recently started to least. Only included in the response if there are runs to list.

Array [

[`attempt_number`](https://docs.databricks.com/api/workspace/jobs/listruns#runs-attempt_number)int32

Example`0`

The sequence number of this run attempt for a triggered job run. The initial attempt of a run has an attempt_number of 0. If the initial run attempt fails, and the job has a retry policy (`max_retries`> 0), subsequent runs are created with an `original_attempt_run_id` of the original attempt’s ID and an incrementing `attempt_number`. Runs are retried only until they succeed, and the maximum `attempt_number` is the same as the `max_retries` value for the job.

[`cleanup_duration`](https://docs.databricks.com/api/workspace/jobs/listruns#runs-cleanup_duration)int64

Example`0`

The time in milliseconds it took to terminate the cluster and clean up any associated artifacts. The duration of a task run is the sum of the `setup_duration`, `execution_duration`, and the `cleanup_duration`. The `cleanup_duration` field is set to 0 for multitask job runs. The total duration of a multitask job run is the value of the `run_duration` field.

[`cluster_instance`](https://docs.databricks.com/api/workspace/jobs/listruns#runs-cluster_instance)object

The cluster used for this run. If the run is specified to use a new cluster, this field is set once the Jobs service has requested a cluster for the run.

[`cluster_spec`](https://docs.databricks.com/api/workspace/jobs/listruns#runs-cluster_spec)object

A snapshot of the job’s cluster specification when this run was created.

[`creator_user_name`](https://docs.databricks.com/api/workspace/jobs/listruns#runs-creator_user_name)string

Example`"user.name@databricks.com"`

The creator user name. This field won’t be included in the response if the user has already been deleted.

[`description`](https://docs.databricks.com/api/workspace/jobs/listruns#runs-description)string

Description of the run

[`effective_performance_target`](https://docs.databricks.com/api/workspace/jobs/listruns#runs-effective_performance_target)string

Enum: `PERFORMANCE_OPTIMIZED | STANDARD`

The actual performance target used by the serverless run during execution. This can differ from the client-set performance target on the request depending on whether the performance mode is supported by the job type.

*   `STANDARD`: Enables cost-efficient execution of serverless workloads.
*   `PERFORMANCE_OPTIMIZED`: Prioritizes fast startup and execution times through rapid scaling and optimized cluster performance.

[`end_time`](https://docs.databricks.com/api/workspace/jobs/listruns#runs-end_time)int64

Example`1625060863413`

The time at which this run ended in epoch milliseconds (milliseconds since 1/1/1970 UTC). This field is set to 0 if the job is still running.

[`execution_duration`](https://docs.databricks.com/api/workspace/jobs/listruns#runs-execution_duration)int64

Example`0`

The time in milliseconds it took to execute the commands in the JAR or notebook until they completed, failed, timed out, were cancelled, or encountered an unexpected error. The duration of a task run is the sum of the `setup_duration`, `execution_duration`, and the `cleanup_duration`. The `execution_duration` field is set to 0 for multitask job runs. The total duration of a multitask job run is the value of the `run_duration` field.

[`git_source`](https://docs.databricks.com/api/workspace/jobs/listruns#runs-git_source)object

Example

An optional specification for a remote Git repository containing the source code used by tasks. Version-controlled source code is supported by notebook, dbt, Python script, and SQL File tasks.

If `git_source` is set, these tasks retrieve the file from the remote repository by default. However, this behavior can be overridden by setting `source` to `WORKSPACE` on the task.

Note: dbt and SQL File tasks support only version-controlled sources. If dbt or SQL File tasks are used, `git_source` must be defined on the job.

[`has_more`](https://docs.databricks.com/api/workspace/jobs/listruns#runs-has_more)boolean

Example`true`

Indicates if the run has more array properties (`tasks`, `job_clusters`) that are not shown. They can be accessed via [jobs/getrun](https://docs.databricks.com/api/workspace/jobs/getrun) endpoint. It is only relevant for API 2.2 [jobs/listruns](https://docs.databricks.com/api/workspace/jobs/listruns) requests with `expand_tasks=true`.

[`job_clusters`](https://docs.databricks.com/api/workspace/jobs/listruns#runs-job_clusters)Array of object

<= 100 items 

Example

A list of job cluster specifications that can be shared and reused by tasks of this job. Libraries cannot be declared in a shared job cluster. You must declare dependent libraries in task settings. If more than 100 job clusters are available, you can paginate through them using [jobs/getrun](https://docs.databricks.com/api/workspace/jobs/getrun).

[`job_id`](https://docs.databricks.com/api/workspace/jobs/listruns#runs-job_id)int64

Example`11223344`

The canonical identifier of the job that contains this run.

[`job_parameters`](https://docs.databricks.com/api/workspace/jobs/listruns#runs-job_parameters)Array of object

Job-level parameters used in the run

[`job_run_id`](https://docs.databricks.com/api/workspace/jobs/listruns#runs-job_run_id)int64

ID of the job run that this run belongs to. For legacy and single-task job runs the field is populated with the job run ID. For task runs, the field is populated with the ID of the job run that the task run belongs to.

[`number_in_job`](https://docs.databricks.com/api/workspace/jobs/listruns#runs-number_in_job)int64

Deprecated

Example`455644833`

A unique identifier for this job run. This is set to the same value as `run_id`.

[`original_attempt_run_id`](https://docs.databricks.com/api/workspace/jobs/listruns#runs-original_attempt_run_id)int64

Example`455644833`

If this run is a retry of a prior run attempt, this field contains the run_id of the original attempt; otherwise, it is the same as the run_id.

[`overriding_parameters`](https://docs.databricks.com/api/workspace/jobs/listruns#runs-overriding_parameters)object

The parameters used for this run.

[`queue_duration`](https://docs.databricks.com/api/workspace/jobs/listruns#runs-queue_duration)int64

Example`1625060863413`

The time in milliseconds that the run has spent in the queue.

[`repair_history`](https://docs.databricks.com/api/workspace/jobs/listruns#runs-repair_history)Array of object

The repair history of the run.

[`run_duration`](https://docs.databricks.com/api/workspace/jobs/listruns#runs-run_duration)int64

Example`110183`

The time in milliseconds it took the job run and all of its repairs to finish.

[`run_id`](https://docs.databricks.com/api/workspace/jobs/listruns#runs-run_id)int64

Example`455644833`

The canonical identifier of the run. This ID is unique across all runs of all jobs.

[`run_name`](https://docs.databricks.com/api/workspace/jobs/listruns#runs-run_name)string

<= 4096 characters 

Default`"Untitled"`

Example`"A multitask job run"`

An optional name for the run. The maximum length is 4096 bytes in UTF-8 encoding.

[`run_page_url`](https://docs.databricks.com/api/workspace/jobs/listruns#runs-run_page_url)string

Example`"https://my-workspace.cloud.databricks.com/#job/11223344/run/123"`

The URL to the detail page of the run.

[`run_type`](https://docs.databricks.com/api/workspace/jobs/listruns#runs-run_type)string

Enum: `JOB_RUN | WORKFLOW_RUN | SUBMIT_RUN`

The type of a run.

*   `JOB_RUN`: Normal job run. A run created with [jobs/runnow](https://docs.databricks.com/api/workspace/jobs/runnow).
*   `WORKFLOW_RUN`: Workflow run. A run created with [dbutils.notebook.run](https://docs.databricks.com/dev-tools/databricks-utils.html#dbutils-workflow).
*   `SUBMIT_RUN`: Submit run. A run created with [jobs/submit](https://docs.databricks.com/api/workspace/jobs/submit).

[`schedule`](https://docs.databricks.com/api/workspace/jobs/listruns#runs-schedule)object

The cron schedule that triggered this run if it was triggered by the periodic scheduler.

[`setup_duration`](https://docs.databricks.com/api/workspace/jobs/listruns#runs-setup_duration)int64

Example`0`

The time in milliseconds it took to set up the cluster. For runs that run on new clusters this is the cluster creation time, for runs that run on existing clusters this time should be very short. The duration of a task run is the sum of the `setup_duration`, `execution_duration`, and the `cleanup_duration`. The `setup_duration` field is set to 0 for multitask job runs. The total duration of a multitask job run is the value of the `run_duration` field.

[`start_time`](https://docs.databricks.com/api/workspace/jobs/listruns#runs-start_time)int64

Example`1625060460483`

The time at which this run was started in epoch milliseconds (milliseconds since 1/1/1970 UTC). This may not be the time when the job task starts executing, for example, if the job is scheduled to run on a new cluster, this is the time the cluster creation call is issued.

[`state`](https://docs.databricks.com/api/workspace/jobs/listruns#runs-state)object

Deprecated

Deprecated. Please use the `status` field instead.

[`status`](https://docs.databricks.com/api/workspace/jobs/listruns#runs-status)object

The current status of the run

[`tasks`](https://docs.databricks.com/api/workspace/jobs/listruns#runs-tasks)Array of object

<= 100 items 

Example

The list of tasks performed by the run. Each task has its own `run_id` which you can use to call `JobsGetOutput` to retrieve the run resutls. If more than 100 tasks are available, you can paginate through them using [jobs/getrun](https://docs.databricks.com/api/workspace/jobs/getrun). Use the `next_page_token` field at the object root to determine if more results are available.

[`trigger`](https://docs.databricks.com/api/workspace/jobs/listruns#runs-trigger)string

Enum: `PERIODIC | ONE_TIME | RETRY | RUN_JOB_TASK | FILE_ARRIVAL | CONTINUOUS | TABLE | CONTINUOUS_RESTART`

The type of trigger that fired this run.

*   `PERIODIC`: Schedules that periodically trigger runs, such as a cron scheduler.
*   `ONE_TIME`: One time triggers that fire a single run. This occurs you triggered a single run on demand through the UI or the API.
*   `RETRY`: Indicates a run that is triggered as a retry of a previously failed run. This occurs when you request to re-run the job in case of failures.
*   `RUN_JOB_TASK`: Indicates a run that is triggered using a Run Job task.
*   `FILE_ARRIVAL`: Indicates a run that is triggered by a file arrival.
*   `CONTINUOUS`: Indicates a run that is triggered by a continuous job.
*   `TABLE`: Indicates a run that is triggered by a table update.
*   `CONTINUOUS_RESTART`: Indicates a run created by user to manually restart a continuous job run.
*   `MODEL`: Indicates a run that is triggered by a model update.

[`trigger_info`](https://docs.databricks.com/api/workspace/jobs/listruns#runs-trigger_info)object

Additional details about what triggered the run

 ]

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

# Response samples

200

{

"next_page_token":"CAEomPuciYcxMKbM9JvMlwU=",

"prev_page_token":"CAAos-uriYcxMN7_rt_v7B4=",

"runs":[

{

"attempt_number":0,

"cleanup_duration":0,

"cluster_instance":{

"cluster_id":"0923-164208-meows279",

"spark_context_id":"string"

},

"cluster_spec":{

"existing_cluster_id":"0923-164208-meows2 79",

"job_cluster_key":"string",

"libraries":[

{

"cran":{

"package":"string",

"repo":"string"

},

"egg":"string",

"jar":"string",

"maven":{

"coordinates":"string",

"exclusions":[

"string"

],

"repo":"string"

},

"pypi":{

"package":"string",

"repo":"string"

},

"requirements":"string",

"whl":"string"

}

],

"new_cluster":{

"apply_policy_default_values":false,

"autoscale":{

"max_workers":0,

"min_workers":0

},

"autotermination_minutes":0,

"aws_attributes":{

"availability":"SPOT",

"ebs_volume_count":0,

"ebs_volume_iops":0,

"ebs_volume_size":0,

"ebs_volume_throughput":0,

"ebs_volume_type":"GENERAL_PURPOSE_SS D",

"first_on_demand":0,

"instance_profile_arn":"string",

"spot_bid_price_percent":100,

"zone_id":"string"

},

"cluster_log_conf":{

"dbfs":{

"destination":"string"

},

"s3":{

"canned_acl":"string",

"destination":"string",

"enable_encryption":true,

"encryption_type":"string",

"endpoint":"string",

"kms_key":"string",

"region":"string"

},

"volumes":{

"destination":"string"

}

},

"cluster_name":"string",

"custom_tags":{

"property1":"string",

"property2":"string"

},

"data_security_mode":"NONE",

"docker_image":{

"basic_auth":{

"password":"string",

"username":"string"

},

"url":"string"

},

"driver_instance_pool_id":"string",

"driver_node_type_flexibility":{

"alternate_node_type_ids":[

"string"

]

},

"driver_node_type_id":"string",

"enable_elastic_disk":true,

"enable_local_disk_encryption":true,

"init_scripts":[

{

"abfss":{

"destination":"string"

},

"dbfs":{

"destination":"string"

},

"file":{

"destination":"string"

},

"gcs":{

"destination":"string"

},

"s3":{

"canned_acl":"string",

"destination":"string",

"enable_encryption":true,

"encryption_type":"string",

"endpoint":"string",

"kms_key":"string",

"region":"string"

},

"volumes":{

"destination":"string"

},

"workspace":{

"destination":"string"

}

}

],

"instance_pool_id":"string",

"is_single_node":true,

"kind":"CLASSIC_PREVIEW",

"node_type_id":"string",

"num_workers":0,

"policy_id":"string",

"runtime_engine":"NULL",

"single_user_name":"string",

"spark_conf":{

"property1":"string",

"property2":"string"

},

"spark_env_vars":{

"property1":"string",

"property2":"string"

},

"spark_version":"string",

"ssh_public_keys":[

"string"

],

"use_ml_runtime":true,

"worker_node_type_flexibility":{

"alternate_node_type_ids":[

"string"

]

},

"workload_type":{

"clients":{

"jobs":true,

"notebooks":true

}

}

}

},

"creator_user_name":"user.name@databricks.c om",

"description":"string",

"effective_performance_target":"PERFORMANCE _OPTIMIZED",

"end_time":1625060863413,

"execution_duration":0,

"git_source":{

"git_branch":"main",

"git_provider":"gitHub",

"git_url":"https://github.com/databricks/databricks-cli"

},

"has_more":true,

"job_clusters":[

{

"job_cluster_key":"auto_scaling_cluster",

"new_cluster":{

"autoscale":{

"max_workers":16,

"min_workers":2

},

"node_type_id":null,

"spark_conf":{

"spark.speculation":true

},

"spark_version":"7.3.x-scala2.12"

}

}

],

"job_id":11223344,

"job_parameters":[

{

"default":"users",

"name":"table",

"value":"customers"

}

],

"job_run_id":0,

"number_in_job":455644833,

"original_attempt_run_id":455644833,

"overriding_parameters":{

"pipeline_params":{

"full_refresh":false

}

},

"queue_duration":1625060863413,

"repair_history":[

{

"effective_performance_target":"PERFORM ANCE_OPTIMIZED",

"end_time":1625060863413,

"id":734650698524280,

"start_time":1625060460483,

"state":{

"life_cycle_state":"PENDING",

"queue_reason":"Queued due to reachin g maximum concurrent runs of 1.",

"result_state":"SUCCESS",

"state_message":"string",

"user_cancelled_or_timedout":false

},

"status":{

"queue_details":{

"code":"ACTIVE_RUNS_LIMIT_REACHED",

"message":"string"

},

"state":"BLOCKED",

"termination_details":{

"code":"SUCCESS",

"message":"string",

"type":"SUCCESS"

}

},

"task_run_ids":[

1106460542112844,

988297789683452

],

"type":"ORIGINAL"

}

],

"run_duration":110183,

"run_id":455644833,

"run_name":"A multitask job run",

"run_page_url":"https://my-workspace.cloud.databricks.com/#job/11223344/run/123",

"run_type":"JOB_RUN",

"schedule":{

"pause_status":"UNPAUSED",

"quartz_cron_expression":"20 30***?",

"timezone_id":"Europe/London"

},

"setup_duration":0,

"start_time":1625060460483,

"state":{

"life_cycle_state":"PENDING",

"queue_reason":"Queued due to reaching ma ximum concurrent runs of 1.",

"result_state":"SUCCESS",

"state_message":"string",

"user_cancelled_or_timedout":false

},

"status":{

"queue_details":{

"code":"ACTIVE_RUNS_LIMIT_REACHED",

"message":"string"

},

"state":"BLOCKED",

"termination_details":{

"code":"SUCCESS",

"message":"string",

"type":"SUCCESS"

}

},

"tasks":[

{

"attempt_number":0,

"cleanup_duration":0,

"cluster_instance":{

"cluster_id":"0923-164208-meows279",

"spark_context_id":"43485853017017869 33"

},

"description":"Ingests order data",

"end_time":1629989930171,

"execution_duration":0,

"job_cluster_key":"auto_scaling_cluster",

"libraries":[

{

"jar":"dbfs:/mnt/databricks/OrderIn gest.jar"

}

],

"run_id":2112892,

"run_if":"ALL_SUCCESS",

"run_page_url":"https://my-workspace.cl oud.databricks.com/#job/39832/run/20",

"setup_duration":0,

"spark_jar_task":{

"main_class_name":"com.databricks.Ord ersIngest"

},

"start_time":1629989929660,

"state":{

"life_cycle_state":"INTERNAL_ERROR",

"result_state":"FAILED",

"state_message":"Library installation failed for library due to user error.Error messa ges:\n'Manage'permissions are required to install libraries on a cluster",

"user_cancelled_or_timedout":false

},

"task_key":"Orders_Ingest"

},

{

"attempt_number":0,

"cleanup_duration":0,

"cluster_instance":{

"cluster_id":"0923-164208-meows279"

},

"depends_on":[

{

"task_key":"Orders_Ingest"

},

{

"task_key":"Sessionize"

}

],

"description":"Matches orders with user sessions",

"end_time":1629989930238,

"execution_duration":0,

"new_cluster":{

"autoscale":{

"max_workers":16,

"min_workers":2

},

"node_type_id":null,

"spark_conf":{

"spark.speculation":true

},

"spark_version":"7.3.x-scala2.12"

},

"notebook_task":{

"notebook_path":"/Users/user.name@dat abricks.com/Match",

"source":"WORKSPACE"

},

"run_id":2112897,

"run_if":"ALL_SUCCESS",

"run_page_url":"https://my-workspace.cl oud.databricks.com/#job/39832/run/21",

"setup_duration":0,

"start_time":0,

"state":{

"life_cycle_state":"SKIPPED",

"state_message":"An upstream task fai led.",

"user_cancelled_or_timedout":false

},

"task_key":"Match"

},

{

"attempt_number":0,

"cleanup_duration":0,

"cluster_instance":{

"cluster_id":"0923-164208-meows279",

"spark_context_id":"43485853017017869 33"

},

"description":"Extracts session data fr om events",

"end_time":1629989930144,

"execution_duration":0,

"existing_cluster_id":"0923-164208-meow s279",

"libraries":[

{

"jar":"dbfs:/mnt/databricks/Session ize.jar"

}

],

"run_id":2112902,

"run_if":"ALL_SUCCESS",

"run_page_url":"https://my-workspace.cl oud.databricks.com/#job/39832/run/22",

"setup_duration":0,

"spark_jar_task":{

"main_class_name":"com.databricks.Ses sionize"

},

"start_time":1629989929668,

"state":{

"life_cycle_state":"INTERNAL_ERROR",

"result_state":"FAILED",

"state_message":"Library installation failed for library due to user error.Error messa ges:\n'Manage'permissions are required to install libraries on a cluster",

"user_cancelled_or_timedout":false

},

"task_key":"Sessionize"

}

],

"trigger":"PERIODIC",

"trigger_info":{

"run_id":0

}

}

]

}
