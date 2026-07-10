Title: Get a single job | Jobs API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/jobs/get

Markdown Content:
## Get a single job

`GET/api/2.2/jobs/get`

Retrieves the details for a single job.

Large arrays in the results will be paginated when they exceed 100 elements. A request for a single job will return all properties for that job, and the first 100 elements of array properties (`tasks`, `job_clusters`, `environments` and `parameters`). Use the `next_page_token` field to check for more results and pass its value as the `page_token` in subsequent requests. If any array properties have more than 100 elements, additional results will be returned on subsequent requests. Arrays without additional results will be empty on later pages.

API scopes (preview):[`jobs`](https://docs.databricks.com/api/workspace/api/scopes#jobs)

### Query parameters

[`job_id`](https://docs.databricks.com/api/workspace/jobs/get#job_id)required int64

Example`job_id=11223344`

The canonical identifier of the job to retrieve information about. This field is required.

[`page_token`](https://docs.databricks.com/api/workspace/jobs/get#page_token)string

Example`page_token=CAAos-uriYcxMN7_rt_v7B4=`

Use `next_page_token` returned from the previous GetJob response to request the next page of the job's array properties.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`created_time`](https://docs.databricks.com/api/workspace/jobs/get#created_time)int64

Example`1601370337343`

The time at which this job was created in epoch milliseconds (milliseconds since 1/1/1970 UTC).

[`creator_user_name`](https://docs.databricks.com/api/workspace/jobs/get#creator_user_name)string

Example`"user.name@databricks.com"`

The creator user name. This field won’t be included in the response if the user has already been deleted.

[`effective_budget_policy_id`](https://docs.databricks.com/api/workspace/jobs/get#effective_budget_policy_id)uuid

Public preview

The id of the budget policy used by this job for cost attribution purposes. This may be set through (in order of precedence):

1.   Budget admins through the account or workspace console
2.   Jobs UI in the job details page and Jobs API using `budget_policy_id`
3.   Inferred default based on accessible budget policies of the run_as identity on job creation or modification.

[`has_more`](https://docs.databricks.com/api/workspace/jobs/get#has_more)boolean

Example`true`

Indicates if the job has more array properties (`tasks`, `job_clusters`) that are not shown. They can be accessed via [jobs/get](https://docs.databricks.com/api/workspace/jobs/get) endpoint. It is only relevant for API 2.2 [jobs/list](https://docs.databricks.com/api/workspace/jobs/list) requests with `expand_tasks=true`.

[`job_id`](https://docs.databricks.com/api/workspace/jobs/get#job_id)int64

Example`11223344`

The canonical identifier for this job.

[`next_page_token`](https://docs.databricks.com/api/workspace/jobs/get#next_page_token)string

Example`"CAAos-uriYcxMN7_rt_v7B4="`

A token that can be used to list the next page of array properties.

[`run_as_user_name`](https://docs.databricks.com/api/workspace/jobs/get#run_as_user_name)string

Example`"user.name@databricks.com"`

The email of an active workspace user or the application ID of a service principal that the job runs as. This value can be changed by setting the `run_as` field when creating or updating a job.

By default, `run_as_user_name` is based on the current job settings and is set to the creator of the job if job access control is disabled or to the user with the `is_owner` permission if job access control is enabled.

[`settings`](https://docs.databricks.com/api/workspace/jobs/get#settings)object

Settings for this job and all of its runs. These settings can be updated using the `resetJob` method.

[`budget_policy_id`](https://docs.databricks.com/api/workspace/jobs/get#settings-budget_policy_id)uuid

Public preview

Example`"550e8400-e29b-41d4-a716-446655440000"`

The id of the user specified budget policy to use for this job. If not specified, a default budget policy may be applied when creating or modifying the job. See `effective_budget_policy_id` for the budget policy used by this workload.

[`continuous`](https://docs.databricks.com/api/workspace/jobs/get#settings-continuous)object

An optional continuous property for this job. The continuous property will ensure that there is always one run executing. Only one of `schedule` and `continuous` can be used.

[`deployment`](https://docs.databricks.com/api/workspace/jobs/get#settings-deployment)object

Deployment information for jobs managed by external sources.

[`description`](https://docs.databricks.com/api/workspace/jobs/get#settings-description)string

<= 27700 characters 

Example`"This job contain multiple tasks that are required to produce the weekly shark sightings report."`

An optional description for the job. The maximum length is 27700 characters in UTF-8 encoding.

[`edit_mode`](https://docs.databricks.com/api/workspace/jobs/get#settings-edit_mode)string

Enum: `UI_LOCKED | EDITABLE`

Edit mode of the job.

*   `UI_LOCKED`: The job is in a locked UI state and cannot be modified.
*   `EDITABLE`: The job is in an editable state and can be modified.

[`email_notifications`](https://docs.databricks.com/api/workspace/jobs/get#settings-email_notifications)object

Default`{}`

An optional set of email addresses that is notified when runs of this job begin or complete as well as when this job is deleted.

[`environments`](https://docs.databricks.com/api/workspace/jobs/get#settings-environments)Array of object

<= 10 items 

A list of task execution environment specifications that can be referenced by serverless tasks of this job. For serverless notebook tasks, if the environment_key is not specified, the notebook environment will be used if present. If a jobs environment is specified, it will override the notebook environment. For other serverless tasks, the task environment is required to be specified using environment_key in the task settings.

[`format`](https://docs.databricks.com/api/workspace/jobs/get#settings-format)string

Deprecated

Enum: `SINGLE_TASK | MULTI_TASK`

Example`"MULTI_TASK"`

Used to tell what is the format of the job. This field is ignored in Create/Update/Reset calls. When using the Jobs API 2.1 this value is always set to `"MULTI_TASK"`.

[`git_source`](https://docs.databricks.com/api/workspace/jobs/get#settings-git_source)object

Example

An optional specification for a remote Git repository containing the source code used by tasks. Version-controlled source code is supported by notebook, dbt, Python script, and SQL File tasks.

If `git_source` is set, these tasks retrieve the file from the remote repository by default. However, this behavior can be overridden by setting `source` to `WORKSPACE` on the task.

Note: dbt and SQL File tasks support only version-controlled sources. If dbt or SQL File tasks are used, `git_source` must be defined on the job.

[`health`](https://docs.databricks.com/api/workspace/jobs/get#settings-health)object

An optional set of health rules that can be defined for this job.

[`job_clusters`](https://docs.databricks.com/api/workspace/jobs/get#settings-job_clusters)Array of object

<= 100 items 

Example

A list of job cluster specifications that can be shared and reused by tasks of this job. Libraries cannot be declared in a shared job cluster. You must declare dependent libraries in task settings.

[`max_concurrent_runs`](https://docs.databricks.com/api/workspace/jobs/get#settings-max_concurrent_runs)int32

Default`1`

Example`10`

An optional maximum allowed number of concurrent runs of the job. Set this value if you want to be able to execute multiple runs of the same job concurrently. This is useful for example if you trigger your job on a frequent schedule and want to allow consecutive runs to overlap with each other, or if you want to trigger multiple runs which differ by their input parameters. This setting affects only new runs. For example, suppose the job’s concurrency is 4 and there are 4 concurrent active runs. Then setting the concurrency to 3 won’t kill any of the active runs. However, from then on, new runs are skipped unless there are fewer than 3 active runs. This value cannot exceed 1000. Setting this value to `0` causes all new runs to be skipped.

[`name`](https://docs.databricks.com/api/workspace/jobs/get#settings-name)string

<= 4096 characters 

Default`"Untitled"`

Example`"A multitask job"`

An optional name for the job. The maximum length is 4096 bytes in UTF-8 encoding.

[`notification_settings`](https://docs.databricks.com/api/workspace/jobs/get#settings-notification_settings)object

Default`{}`

Optional notification settings that are used when sending notifications to each of the `email_notifications` and `webhook_notifications` for this job.

[`parameters`](https://docs.databricks.com/api/workspace/jobs/get#settings-parameters)Array of object

Job-level parameter definitions

[`performance_target`](https://docs.databricks.com/api/workspace/jobs/get#settings-performance_target)string

Enum: `PERFORMANCE_OPTIMIZED | STANDARD`

Default`"PERFORMANCE_OPTIMIZED"`

The performance mode on a serverless job. This field determines the level of compute performance or cost-efficiency for the run. The performance target does not apply to tasks that run on Serverless GPU compute.

*   `STANDARD`: Enables cost-efficient execution of serverless workloads.
*   `PERFORMANCE_OPTIMIZED`: Prioritizes fast startup and execution times through rapid scaling and optimized cluster performance.

[`queue`](https://docs.databricks.com/api/workspace/jobs/get#settings-queue)object

The queue settings of the job.

[`run_as`](https://docs.databricks.com/api/workspace/jobs/get#settings-run_as)object

The user or service principal that the job runs as, if specified in the request. This field indicates the explicit configuration of `run_as` for the job. To find the value in all cases, explicit or implicit, use `run_as_user_name`.

[`schedule`](https://docs.databricks.com/api/workspace/jobs/get#settings-schedule)object

An optional periodic schedule for this job. The default behavior is that the job only runs when triggered by clicking “Run Now” in the Jobs UI or sending an API request to `runNow`.

[`tags`](https://docs.databricks.com/api/workspace/jobs/get#settings-tags)object

Default`{}`

Example

A map of tags associated with the job. These are forwarded to the cluster as cluster tags for jobs clusters, and are subject to the same limitations as cluster tags. A maximum of 25 tags can be added to the job.

[`tasks`](https://docs.databricks.com/api/workspace/jobs/get#settings-tasks)Array of object

Example

A list of task specifications to be executed by this job. It supports up to 1000 elements in write endpoints ([jobs/create](https://docs.databricks.com/api/workspace/jobs/create), [jobs/reset](https://docs.databricks.com/api/workspace/jobs/reset), [jobs/update](https://docs.databricks.com/api/workspace/jobs/update), [jobs/submit](https://docs.databricks.com/api/workspace/jobs/submit)). Read endpoints return only 100 tasks. If more than 100 tasks are available, you can paginate through them using [jobs/get](https://docs.databricks.com/api/workspace/jobs/get). Use the `next_page_token` field at the object root to determine if more results are available.

[`timeout_seconds`](https://docs.databricks.com/api/workspace/jobs/get#settings-timeout_seconds)int32

Default`0`

Example`86400`

An optional timeout applied to each run of this job. A value of `0` means no timeout.

[`trigger`](https://docs.databricks.com/api/workspace/jobs/get#settings-trigger)object

A configuration to trigger a run when certain conditions are met. The default behavior is that the job runs only when triggered by clicking “Run Now” in the Jobs UI or sending an API request to `runNow`.

[`webhook_notifications`](https://docs.databricks.com/api/workspace/jobs/get#settings-webhook_notifications)object

Default`{}`

A collection of system notification IDs to notify when runs of this job begin or complete.

[`trigger_state`](https://docs.databricks.com/api/workspace/jobs/get#trigger_state)object

State of the trigger associated with the job.

[`file_arrival`](https://docs.databricks.com/api/workspace/jobs/get#trigger_state-file_arrival)object

[`table`](https://docs.databricks.com/api/workspace/jobs/get#trigger_state-table)object

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

"created_time":1601370337343,

"creator_user_name":"user.name@databricks.com",

"effective_budget_policy_id":"febd7e62-ab77-486 9-bab1-dd8ac8ffab85",

"has_more":true,

"job_id":11223344,

"next_page_token":"CAAos-uriYcxMN7_rt_v7B4=",

"run_as_user_name":"user.name@databricks.com",

"settings":{

"budget_policy_id":"550e8400-e29b-41d4-a716-4 46655440000",

"continuous":{

"pause_status":"UNPAUSED",

"task_retry_mode":"NEVER"

},

"deployment":{

"kind":"BUNDLE",

"metadata_file_path":"string"

},

"description":"This job contain multiple task s that are required to produce the weekly shark si ghtings report.",

"edit_mode":"UI_LOCKED",

"email_notifications":{

"no_alert_for_skipped_runs":false,

"on_duration_warning_threshold_exceeded":[

"user.name@databricks.com"

],

"on_failure":[

"user.name@databricks.com"

],

"on_start":[

"user.name@databricks.com"

],

"on_streaming_backlog_exceeded":[

"user.name@databricks.com"

],

"on_success":[

"user.name@databricks.com"

]

},

"environments":[

{

"environment_key":"string",

"spec":{

"base_environment":"string",

"client":"1",

"dependencies":[

"string"

],

"environment_version":"5",

"java_dependencies":[

"string"

]

}

}

],

"format":"SINGLE_TASK",

"git_source":{

"git_branch":"main",

"git_provider":"gitHub",

"git_url":"https://github.com/databricks/da tabricks-cli"

},

"health":{

"rules":[

{

"metric":"RUN_DURATION_SECONDS",

"op":"GREATER_THAN",

"value":10

}

]

},

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

"max_concurrent_runs":10,

"name":"A multitask job",

"notification_settings":{

"no_alert_for_canceled_runs":false,

"no_alert_for_skipped_runs":false

},

"parameters":[

{

"default":"users",

"name":"table"

}

],

"performance_target":"PERFORMANCE_OPTIMIZED",

"queue":{

"enabled":true

},

"run_as":{

"service_principal_name":"692bc6d0-ffa3-11e d-be56-0242ac120002",

"user_name":"user@databricks.com"

},

"schedule":{

"pause_status":"UNPAUSED",

"quartz_cron_expression":"20 30***?",

"timezone_id":"Europe/London"

},

"tags":{

"cost-center":"engineering",

"team":"jobs"

},

"tasks":[

{

"depends_on":[],

"description":"Extracts session data from events",

"existing_cluster_id":"0923-164208-meows2 79",

"libraries":[

{

"jar":"dbfs:/mnt/databricks/Sessioniz e.jar"

}

],

"max_retries":3,

"min_retry_interval_millis":2000,

"retry_on_timeout":false,

"spark_jar_task":{

"main_class_name":"com.databricks.Sessi onize",

"parameters":[

"--data",

"dbfs:/path/to/data.json"

]

},

"task_key":"Sessionize",

"timeout_seconds":86400

},

{

"depends_on":[],

"description":"Ingests order data",

"job_cluster_key":"auto_scaling_cluster",

"libraries":[

{

"jar":"dbfs:/mnt/databricks/OrderInge st.jar"

}

],

"max_retries":3,

"min_retry_interval_millis":2000,

"retry_on_timeout":false,

"spark_jar_task":{

"main_class_name":"com.databricks.Order sIngest",

"parameters":[

"--data",

"dbfs:/path/to/order-data.json"

]

},

"task_key":"Orders_Ingest",

"timeout_seconds":86400

},

{

"depends_on":[

{

"task_key":"Orders_Ingest"

},

{

"task_key":"Sessionize"

}

],

"description":"Matches orders with user s essions",

"max_retries":3,

"min_retry_interval_millis":2000,

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

"base_parameters":{

"age":"35",

"name":"John Doe"

},

"notebook_path":"/Users/user.name@datab ricks.com/Match"

},

"retry_on_timeout":false,

"run_if":"ALL_SUCCESS",

"task_key":"Match",

"timeout_seconds":86400

}

],

"timeout_seconds":86400,

"trigger":{

"file_arrival":{

"min_time_between_triggers_seconds":0,

"url":"string",

"wait_after_last_change_seconds":0

},

"pause_status":"UNPAUSED",

"periodic":{

"interval":0,

"unit":"HOURS"

},

"table_update":{

"condition":"ANY_UPDATED",

"min_time_between_triggers_seconds":0,

"table_names":[

"catalog_name.schema_name.table_name",

"catalog_name_2.schema_name_2.table_name _2"

],

"wait_after_last_change_seconds":0

}

},

"webhook_notifications":{

"on_duration_warning_threshold_exceeded":[

[

{

"id":"0481e838-0a59-4eff-9541-a4ca6f1 49574"

}

]

],

"on_failure":[

[

{

"id":"0481e838-0a59-4eff-9541-a4ca6f1 49574"

}

]

],

"on_start":[

[

{

"id":"0481e838-0a59-4eff-9541-a4ca6f1 49574"

}

]

],

"on_streaming_backlog_exceeded":[

[

{

"id":"0481e838-0a59-4eff-9541-a4ca6f1 49574"

}

]

],

"on_success":[

[

{

"id":"0481e838-0a59-4eff-9541-a4ca6f1 49574"

}

]

]

}

},

"trigger_state":{

"file_arrival":{

"using_file_events":true

},

"table":{

"last_seen_table_states":[

{

"has_seen_updates":true,

"table_name":"string"

}

],

"using_scalable_monitoring":true

}

}

}
