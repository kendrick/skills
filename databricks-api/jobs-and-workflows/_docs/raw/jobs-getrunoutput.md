Title: Get the output for a single run | Jobs API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/jobs/getrunoutput

Markdown Content:
## Get the output for a single run

`GET/api/2.2/jobs/runs/get-output`

Retrieve the output and metadata of a single task run. When a notebook task returns a value through the `dbutils.notebook.exit()` call, you can use this endpoint to retrieve that value. Databricks restricts this API to returning the first 5 MB of the output. To return a larger result, you can store job results in a cloud storage service.

This endpoint validates that the run_id parameter is valid and returns an HTTP status code 400 if the run_id parameter is invalid. Runs are automatically removed after 60 days. If you to want to reference them beyond 60 days, you must save old run results before they expire.

API scopes (preview):[`jobs`](https://docs.databricks.com/api/workspace/api/scopes#jobs)

### Query parameters

[`run_id`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#run_id)required int64

Example`run_id=455644833`

The canonical identifier for the run.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`alert_output`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#alert_output)object

Beta

The output of an alert task, if available

[`alert_state`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#alert_output-alert_state)string

Beta

Enum: `UNKNOWN | TRIGGERED | OK | ERROR`

Same alert evaluation state as in redash-v2/api/proto/alertsv2/alerts.proto

[`clean_rooms_notebook_output`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#clean_rooms_notebook_output)object

The output of a clean rooms notebook task, if available

[`clean_room_job_run_state`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#clean_rooms_notebook_output-clean_room_job_run_state)object

The run state of the clean rooms notebook task.

[`notebook_output`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#clean_rooms_notebook_output-notebook_output)object

The notebook output for the clean room run

[`output_schema_info`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#clean_rooms_notebook_output-output_schema_info)object

Information on how to access the output schema for the clean room run

[`dashboard_output`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#dashboard_output)object

The output of a dashboard task, if available

[`page_snapshots`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#dashboard_output-page_snapshots)Array of object

Should only be populated for manual PDF download jobs.

[`dbt_output`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#dbt_output)object

The output of a dbt task, if available.

[`artifacts_headers`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#dbt_output-artifacts_headers)object

An optional map of headers to send when retrieving the artifact from the `artifacts_link`.

[`artifacts_link`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#dbt_output-artifacts_link)string

A pre-signed URL to download the (compressed) dbt artifacts. This link is valid for a limited time (30 minutes). This information is only available after the run has finished.

[`error`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#error)string

Example`"ZeroDivisionError: integer division or modulo by zero"`

An error message indicating why a task failed or why output is not available. The message is unstructured, and its exact format is subject to change.

[`error_trace`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#error_trace)string

If there was an error executing the run, this field contains any available stack traces.

[`info`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#info)string

[`logs`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#logs)string

Example`"Hello World!"`

The output from tasks that write to standard streams (stdout/stderr) such as spark_jar_task, spark_python_task, python_wheel_task.

It's not supported for the notebook_task, pipeline_task or spark_submit_task.

Databricks restricts this API to return the last 5 MB of these logs.

[`logs_truncated`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#logs_truncated)boolean

Example`true`

Whether the logs are truncated.

[`metadata`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#metadata)object

All details of the run except for its output.

[`attempt_number`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#metadata-attempt_number)int32

Example`0`

The sequence number of this run attempt for a triggered job run. The initial attempt of a run has an attempt_number of 0. If the initial run attempt fails, and the job has a retry policy (`max_retries`> 0), subsequent runs are created with an `original_attempt_run_id` of the original attempt’s ID and an incrementing `attempt_number`. Runs are retried only until they succeed, and the maximum `attempt_number` is the same as the `max_retries` value for the job.

[`cleanup_duration`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#metadata-cleanup_duration)int64

Example`0`

The time in milliseconds it took to terminate the cluster and clean up any associated artifacts. The duration of a task run is the sum of the `setup_duration`, `execution_duration`, and the `cleanup_duration`. The `cleanup_duration` field is set to 0 for multitask job runs. The total duration of a multitask job run is the value of the `run_duration` field.

[`cluster_instance`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#metadata-cluster_instance)object

The cluster used for this run. If the run is specified to use a new cluster, this field is set once the Jobs service has requested a cluster for the run.

[`cluster_spec`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#metadata-cluster_spec)object

A snapshot of the job’s cluster specification when this run was created.

[`creator_user_name`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#metadata-creator_user_name)string

Example`"user.name@databricks.com"`

The creator user name. This field won’t be included in the response if the user has already been deleted.

[`description`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#metadata-description)string

Description of the run

[`effective_performance_target`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#metadata-effective_performance_target)string

Enum: `PERFORMANCE_OPTIMIZED | STANDARD`

The actual performance target used by the serverless run during execution. This can differ from the client-set performance target on the request depending on whether the performance mode is supported by the job type.

*   `STANDARD`: Enables cost-efficient execution of serverless workloads.
*   `PERFORMANCE_OPTIMIZED`: Prioritizes fast startup and execution times through rapid scaling and optimized cluster performance.

[`end_time`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#metadata-end_time)int64

Example`1625060863413`

The time at which this run ended in epoch milliseconds (milliseconds since 1/1/1970 UTC). This field is set to 0 if the job is still running.

[`execution_duration`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#metadata-execution_duration)int64

Example`0`

The time in milliseconds it took to execute the commands in the JAR or notebook until they completed, failed, timed out, were cancelled, or encountered an unexpected error. The duration of a task run is the sum of the `setup_duration`, `execution_duration`, and the `cleanup_duration`. The `execution_duration` field is set to 0 for multitask job runs. The total duration of a multitask job run is the value of the `run_duration` field.

[`git_source`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#metadata-git_source)object

Example

An optional specification for a remote Git repository containing the source code used by tasks. Version-controlled source code is supported by notebook, dbt, Python script, and SQL File tasks.

If `git_source` is set, these tasks retrieve the file from the remote repository by default. However, this behavior can be overridden by setting `source` to `WORKSPACE` on the task.

Note: dbt and SQL File tasks support only version-controlled sources. If dbt or SQL File tasks are used, `git_source` must be defined on the job.

[`has_more`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#metadata-has_more)boolean

Example`true`

Indicates if the run has more array properties (`tasks`, `job_clusters`) that are not shown. They can be accessed via [jobs/getrun](https://docs.databricks.com/api/workspace/jobs/getrun) endpoint. It is only relevant for API 2.2 [jobs/listruns](https://docs.databricks.com/api/workspace/jobs/listruns) requests with `expand_tasks=true`.

[`job_clusters`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#metadata-job_clusters)Array of object

<= 100 items 

Example

A list of job cluster specifications that can be shared and reused by tasks of this job. Libraries cannot be declared in a shared job cluster. You must declare dependent libraries in task settings. If more than 100 job clusters are available, you can paginate through them using [jobs/getrun](https://docs.databricks.com/api/workspace/jobs/getrun).

[`job_id`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#metadata-job_id)int64

Example`11223344`

The canonical identifier of the job that contains this run.

[`job_parameters`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#metadata-job_parameters)Array of object

Job-level parameters used in the run

[`job_run_id`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#metadata-job_run_id)int64

ID of the job run that this run belongs to. For legacy and single-task job runs the field is populated with the job run ID. For task runs, the field is populated with the ID of the job run that the task run belongs to.

[`next_page_token`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#metadata-next_page_token)string

Example`"CAAos-uriYcxMN7_rt_v7B4="`

A token that can be used to list the next page of array properties.

[`number_in_job`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#metadata-number_in_job)int64

Deprecated

Example`455644833`

A unique identifier for this job run. This is set to the same value as `run_id`.

[`original_attempt_run_id`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#metadata-original_attempt_run_id)int64

Example`455644833`

If this run is a retry of a prior run attempt, this field contains the run_id of the original attempt; otherwise, it is the same as the run_id.

[`overriding_parameters`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#metadata-overriding_parameters)object

The parameters used for this run.

[`queue_duration`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#metadata-queue_duration)int64

Example`1625060863413`

The time in milliseconds that the run has spent in the queue.

[`repair_history`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#metadata-repair_history)Array of object

The repair history of the run.

[`run_duration`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#metadata-run_duration)int64

Example`110183`

The time in milliseconds it took the job run and all of its repairs to finish.

[`run_id`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#metadata-run_id)int64

Example`455644833`

The canonical identifier of the run. This ID is unique across all runs of all jobs.

[`run_name`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#metadata-run_name)string

<= 4096 characters 

Default`"Untitled"`

Example`"A multitask job run"`

An optional name for the run. The maximum length is 4096 bytes in UTF-8 encoding.

[`run_page_url`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#metadata-run_page_url)string

Example`"https://my-workspace.cloud.databricks.com/#job/11223344/run/123"`

The URL to the detail page of the run.

[`run_type`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#metadata-run_type)string

Enum: `JOB_RUN | WORKFLOW_RUN | SUBMIT_RUN`

The type of a run.

*   `JOB_RUN`: Normal job run. A run created with [jobs/runnow](https://docs.databricks.com/api/workspace/jobs/runnow).
*   `WORKFLOW_RUN`: Workflow run. A run created with [dbutils.notebook.run](https://docs.databricks.com/dev-tools/databricks-utils.html#dbutils-workflow).
*   `SUBMIT_RUN`: Submit run. A run created with [jobs/submit](https://docs.databricks.com/api/workspace/jobs/submit).

[`schedule`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#metadata-schedule)object

The cron schedule that triggered this run if it was triggered by the periodic scheduler.

[`setup_duration`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#metadata-setup_duration)int64

Example`0`

The time in milliseconds it took to set up the cluster. For runs that run on new clusters this is the cluster creation time, for runs that run on existing clusters this time should be very short. The duration of a task run is the sum of the `setup_duration`, `execution_duration`, and the `cleanup_duration`. The `setup_duration` field is set to 0 for multitask job runs. The total duration of a multitask job run is the value of the `run_duration` field.

[`start_time`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#metadata-start_time)int64

Example`1625060460483`

The time at which this run was started in epoch milliseconds (milliseconds since 1/1/1970 UTC). This may not be the time when the job task starts executing, for example, if the job is scheduled to run on a new cluster, this is the time the cluster creation call is issued.

[`state`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#metadata-state)object

Deprecated

Deprecated. Please use the `status` field instead.

[`status`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#metadata-status)object

The current status of the run

[`tasks`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#metadata-tasks)Array of object

<= 100 items 

Example

The list of tasks performed by the run. Each task has its own `run_id` which you can use to call `JobsGetOutput` to retrieve the run resutls. If more than 100 tasks are available, you can paginate through them using [jobs/getrun](https://docs.databricks.com/api/workspace/jobs/getrun). Use the `next_page_token` field at the object root to determine if more results are available.

[`trigger`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#metadata-trigger)string

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

[`trigger_info`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#metadata-trigger_info)object

Additional details about what triggered the run

[`notebook_output`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#notebook_output)object

The output of a notebook task, if available. A notebook task that terminates (either successfully or with a failure) without calling `dbutils.notebook.exit()` is considered to have an empty output. This field is set but its result value is empty. Databricks restricts this API to return the first 5 MB of the output. To return a larger result, use the [ClusterLogConf](https://docs.databricks.com/dev-tools/api/latest/clusters.html#clusterlogconf) field to configure log storage for the job cluster.

[`result`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#notebook_output-result)string

Example`"An arbitrary string passed by calling dbutils.notebook.exit(...)"`

The value passed to [dbutils.notebook.exit()](https://docs.databricks.com/notebooks/notebook-workflows.html#notebook-workflows-exit). Databricks restricts this API to return the first 5 MB of the value. For a larger result, your job can store the results in a cloud storage service. This field is absent if `dbutils.notebook.exit()` was never called.

[`truncated`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#notebook_output-truncated)boolean

Example`false`

Whether or not the result was truncated.

[`run_job_output`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#run_job_output)object

The output of a run job task, if available

[`run_id`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#run_job_output-run_id)int64

The run id of the triggered job run

[`sql_output`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#sql_output)object

The output of a SQL task, if available.

[`alert_output`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#sql_output-alert_output)object

The output of a SQL alert task, if available.

[`dashboard_output`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#sql_output-dashboard_output)object

The output of a SQL dashboard task, if available.

[`query_output`](https://docs.databricks.com/api/workspace/jobs/getrunoutput#sql_output-query_output)object

The output of a SQL query task, if available.

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

"alert_output":{

"alert_state":"UNKNOWN"

},

"clean_rooms_notebook_output":{

"clean_room_job_run_state":{

"life_cycle_state":"RUN_LIFE_CYCLE_STATE_UN SPECIFIED",

"result_state":"RUN_RESULT_STATE_UNSPECIFIE D"

},

"notebook_output":{

"result":"An arbitrary string passed by cal ling dbutils.notebook.exit(...)",

"truncated":false

},

"output_schema_info":{

"catalog_name":"string",

"expiration_time":0,

"schema_name":"string"

}

},

"dashboard_output":{

"page_snapshots":[

{

"page_display_name":"Page 1",

"widget_error_details":[

{

"message":"You do not have permission to use the SQL Warehouse."

}

]

}

]

},

"dbt_output":{

"artifacts_headers":{

"property1":"string",

"property2":"string"

},

"artifacts_link":"string"

},

"error":"ZeroDivisionError:integer division or modulo by zero",

"error_trace":"string",

"info":"string",

"logs":"Hello World!",

"logs_truncated":true,

"metadata":{

"attempt_number":0,

"cleanup_duration":0,

"cluster_instance":{

"cluster_id":"0923-164208-meows279",

"spark_context_id":"string"

},

"cluster_spec":{

"existing_cluster_id":"0923-164208-meows279",

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

"ebs_volume_type":"GENERAL_PURPOSE_SSD",

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

"creator_user_name":"user.name@databricks.com",

"description":"string",

"effective_performance_target":"PERFORMANCE_O PTIMIZED",

"end_time":1625060863413,

"execution_duration":0,

"git_source":{

"git_branch":"main",

"git_provider":"gitHub",

"git_url":"https://github.com/databricks/da tabricks-cli"

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

"next_page_token":"CAAos-uriYcxMN7_rt_v7B4=",

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

"effective_performance_target":"PERFORMAN CE_OPTIMIZED",

"end_time":1625060863413,

"id":734650698524280,

"start_time":1625060460483,

"state":{

"life_cycle_state":"PENDING",

"queue_reason":"Queued due to reaching maximum concurrent runs of 1.",

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

"run_page_url":"https://my-workspace.cloud.da tabricks.com/#job/11223344/run/123",

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

"queue_reason":"Queued due to reaching maxi mum concurrent runs of 1.",

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

"spark_context_id":"4348585301701786933"

},

"description":"Ingests order data",

"end_time":1629989930171,

"execution_duration":0,

"job_cluster_key":"auto_scaling_cluster",

"libraries":[

{

"jar":"dbfs:/mnt/databricks/OrderInge st.jar"

}

],

"run_id":2112892,

"run_if":"ALL_SUCCESS",

"run_page_url":"https://my-workspace.clou d.databricks.com/#job/39832/run/20",

"setup_duration":0,

"spark_jar_task":{

"main_class_name":"com.databricks.Order sIngest"

},

"start_time":1629989929660,

"state":{

"life_cycle_state":"INTERNAL_ERROR",

"result_state":"FAILED",

"state_message":"Library installation f ailed for library due to user error.Error message s:\n'Manage'permissions are required to install l ibraries on a cluster",

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

"description":"Matches orders with user s essions",

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

"notebook_path":"/Users/user.name@datab ricks.com/Match",

"source":"WORKSPACE"

},

"run_id":2112897,

"run_if":"ALL_SUCCESS",

"run_page_url":"https://my-workspace.clou d.databricks.com/#job/39832/run/21",

"setup_duration":0,

"start_time":0,

"state":{

"life_cycle_state":"SKIPPED",

"state_message":"An upstream task faile d.",

"user_cancelled_or_timedout":false

},

"task_key":"Match"

},

{

"attempt_number":0,

"cleanup_duration":0,

"cluster_instance":{

"cluster_id":"0923-164208-meows279",

"spark_context_id":"4348585301701786933"

},

"description":"Extracts session data from events",

"end_time":1629989930144,

"execution_duration":0,

"existing_cluster_id":"0923-164208-meows2 79",

"libraries":[

{

"jar":"dbfs:/mnt/databricks/Sessioniz e.jar"

}

],

"run_id":2112902,

"run_if":"ALL_SUCCESS",

"run_page_url":"https://my-workspace.clou d.databricks.com/#job/39832/run/22",

"setup_duration":0,

"spark_jar_task":{

"main_class_name":"com.databricks.Sessi onize"

},

"start_time":1629989929668,

"state":{

"life_cycle_state":"INTERNAL_ERROR",

"result_state":"FAILED",

"state_message":"Library installation f ailed for library due to user error.Error message s:\n'Manage'permissions are required to install l ibraries on a cluster",

"user_cancelled_or_timedout":false

},

"task_key":"Sessionize"

}

],

"trigger":"PERIODIC",

"trigger_info":{

"run_id":0

}

},

"notebook_output":{

"result":"An arbitrary string passed by calli ng dbutils.notebook.exit(...)",

"truncated":false

},

"run_job_output":{

"run_id":0

},

"sql_output":{

"alert_output":{

"alert_state":"UNKNOWN",

"output_link":"string",

"query_text":"string",

"sql_statements":[

{

"lookup_key":"string"

}

],

"warehouse_id":"string"

},

"dashboard_output":{

"warehouse_id":"string",

"widgets":[

{

"end_time":0,

"error":{

"message":"string"

},

"output_link":"string",

"start_time":0,

"status":"PENDING",

"widget_id":"string",

"widget_title":"string"

}

]

},

"query_output":{

"endpoint_id":"string",

"output_link":"string",

"query_text":"string",

"sql_statements":[

{

"lookup_key":"string"

}

],

"warehouse_id":"string"

}

}

}
