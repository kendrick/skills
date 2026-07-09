Title: Create a new job | Jobs API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/jobs/create

Markdown Content:
## Create a new job

`POST/api/2.2/jobs/create`

Create a new job.

API scopes:[`jobs`](https://docs.databricks.com/api/workspace/api/scopes#jobs)

### Request body

[`access_control_list`](https://docs.databricks.com/api/workspace/jobs/create#access_control_list)Array of object

List of permissions to set on the job.

Array [

[`group_name`](https://docs.databricks.com/api/workspace/jobs/create#access_control_list-group_name)string

name of the group

[`permission_level`](https://docs.databricks.com/api/workspace/jobs/create#access_control_list-permission_level)string

Enum: `CAN_MANAGE | IS_OWNER | CAN_MANAGE_RUN | CAN_VIEW`

Permission level

[`service_principal_name`](https://docs.databricks.com/api/workspace/jobs/create#access_control_list-service_principal_name)string

application ID of a service principal

[`user_name`](https://docs.databricks.com/api/workspace/jobs/create#access_control_list-user_name)string

name of the user

 ]

[`budget_policy_id`](https://docs.databricks.com/api/workspace/jobs/create#budget_policy_id)uuid

Public preview

Example`"550e8400-e29b-41d4-a716-446655440000"`

The id of the user specified budget policy to use for this job. If not specified, a default budget policy may be applied when creating or modifying the job. See `effective_budget_policy_id` for the budget policy used by this workload.

[`continuous`](https://docs.databricks.com/api/workspace/jobs/create#continuous)object

An optional continuous property for this job. The continuous property will ensure that there is always one run executing. Only one of `schedule` and `continuous` can be used.

[`pause_status`](https://docs.databricks.com/api/workspace/jobs/create#continuous-pause_status)string

Enum: `UNPAUSED | PAUSED`

Default`"UNPAUSED"`

Indicate whether the continuous execution of the job is paused or not. Defaults to UNPAUSED.

[`task_retry_mode`](https://docs.databricks.com/api/workspace/jobs/create#continuous-task_retry_mode)string

Enum: `NEVER | ON_FAILURE`

Indicate whether the continuous job is applying task level retries or not. Defaults to NEVER.

[`deployment`](https://docs.databricks.com/api/workspace/jobs/create#deployment)object

Deployment information for jobs managed by external sources.

[`kind`](https://docs.databricks.com/api/workspace/jobs/create#deployment-kind)required string

Enum:

`BUNDLE`

`SYSTEM_MANAGED`

Beta

The kind of deployment that manages the job.

*   `BUNDLE`: The job is managed by Databricks Asset Bundle.
*   `SYSTEM_MANAGED`: The job is managed by Databricks and is read-only.

[`metadata_file_path`](https://docs.databricks.com/api/workspace/jobs/create#deployment-metadata_file_path)string

Path of the file that contains deployment metadata.

[`description`](https://docs.databricks.com/api/workspace/jobs/create#description)string

<= 27700 characters 

Example`"This job contain multiple tasks that are required to produce the weekly shark sightings report."`

An optional description for the job. The maximum length is 27700 characters in UTF-8 encoding.

[`edit_mode`](https://docs.databricks.com/api/workspace/jobs/create#edit_mode)string

Enum: `UI_LOCKED | EDITABLE`

Edit mode of the job.

*   `UI_LOCKED`: The job is in a locked UI state and cannot be modified.
*   `EDITABLE`: The job is in an editable state and can be modified.

[`email_notifications`](https://docs.databricks.com/api/workspace/jobs/create#email_notifications)object

Default`{}`

An optional set of email addresses that is notified when runs of this job begin or complete as well as when this job is deleted.

[`no_alert_for_skipped_runs`](https://docs.databricks.com/api/workspace/jobs/create#email_notifications-no_alert_for_skipped_runs)boolean

Deprecated

Default`false`

If true, do not send email to recipients specified in `on_failure` if the run is skipped. This field is `deprecated`. Please use the `notification_settings.no_alert_for_skipped_runs` field.

[`on_duration_warning_threshold_exceeded`](https://docs.databricks.com/api/workspace/jobs/create#email_notifications-on_duration_warning_threshold_exceeded)Array of string

A list of email addresses to be notified when the duration of a run exceeds the threshold specified for the `RUN_DURATION_SECONDS` metric in the `health` field. If no rule for the `RUN_DURATION_SECONDS` metric is specified in the `health` field for the job, notifications are not sent.

[`on_failure`](https://docs.databricks.com/api/workspace/jobs/create#email_notifications-on_failure)Array of string

A list of email addresses to be notified when a run unsuccessfully completes. A run is considered to have completed unsuccessfully if it ends with an `INTERNAL_ERROR``life_cycle_state` or a `FAILED`, or `TIMED_OUT` result_state. If this is not specified on job creation, reset, or update the list is empty, and notifications are not sent.

[`on_start`](https://docs.databricks.com/api/workspace/jobs/create#email_notifications-on_start)Array of string

A list of email addresses to be notified when a run begins. If not specified on job creation, reset, or update, the list is empty, and notifications are not sent.

[`on_streaming_backlog_exceeded`](https://docs.databricks.com/api/workspace/jobs/create#email_notifications-on_streaming_backlog_exceeded)Array of string

Public preview

A list of email addresses to notify when any streaming backlog thresholds are exceeded for any stream. Streaming backlog thresholds can be set in the `health` field using the following metrics: `STREAMING_BACKLOG_BYTES`, `STREAMING_BACKLOG_RECORDS`, `STREAMING_BACKLOG_SECONDS`, or `STREAMING_BACKLOG_FILES`. Alerting is based on the 10-minute average of these metrics. If the issue persists, notifications are resent every 30 minutes.

[`on_success`](https://docs.databricks.com/api/workspace/jobs/create#email_notifications-on_success)Array of string

A list of email addresses to be notified when a run successfully completes. A run is considered to have completed successfully if it ends with a `TERMINATED``life_cycle_state` and a `SUCCESS` result_state. If not specified on job creation, reset, or update, the list is empty, and notifications are not sent.

[`environments`](https://docs.databricks.com/api/workspace/jobs/create#environments)Array of object

<= 10 items 

A list of task execution environment specifications that can be referenced by serverless tasks of this job. For serverless notebook tasks, if the environment_key is not specified, the notebook environment will be used if present. If a jobs environment is specified, it will override the notebook environment. For other serverless tasks, the task environment is required to be specified using environment_key in the task settings.

Array [

[`environment_key`](https://docs.databricks.com/api/workspace/jobs/create#environments-environment_key)required string

The key of an environment. It has to be unique within a job.

[`spec`](https://docs.databricks.com/api/workspace/jobs/create#environments-spec)object

The environment entity used to preserve serverless environment side panel, jobs' environment for non-notebook task, and SDP's environment for classic and serverless pipelines. In this minimal environment spec, only pip and java dependencies are supported.

 ]

[`format`](https://docs.databricks.com/api/workspace/jobs/create#format)string

Deprecated

Enum: `SINGLE_TASK | MULTI_TASK`

Example`"MULTI_TASK"`

Used to tell what is the format of the job. This field is ignored in Create/Update/Reset calls. When using the Jobs API 2.1 this value is always set to `"MULTI_TASK"`.

[`git_source`](https://docs.databricks.com/api/workspace/jobs/create#git_source)object

Example

An optional specification for a remote Git repository containing the source code used by tasks. Version-controlled source code is supported by notebook, dbt, Python script, and SQL File tasks.

If `git_source` is set, these tasks retrieve the file from the remote repository by default. However, this behavior can be overridden by setting `source` to `WORKSPACE` on the task.

Note: dbt and SQL File tasks support only version-controlled sources. If dbt or SQL File tasks are used, `git_source` must be defined on the job.

[`git_branch`](https://docs.databricks.com/api/workspace/jobs/create#git_source-git_branch)string

<= 255 characters 

Example`"main"`

Name of the branch to be checked out and used by this job. This field cannot be specified in conjunction with git_tag or git_commit.

[`git_commit`](https://docs.databricks.com/api/workspace/jobs/create#git_source-git_commit)string

<= 64 characters 

Example`"e0056d01"`

Commit to be checked out and used by this job. This field cannot be specified in conjunction with git_branch or git_tag.

[`git_provider`](https://docs.databricks.com/api/workspace/jobs/create#git_source-git_provider)required string

Enum: `gitHub | bitbucketCloud | azureDevOpsServices | gitHubEnterprise | bitbucketServer | gitLab | gitLabEnterpriseEdition | awsCodeCommit`

Unique identifier of the service used to host the Git repository. The value is case insensitive.

[`git_snapshot`](https://docs.databricks.com/api/workspace/jobs/create#git_source-git_snapshot)object

Read-only state of the remote repository at the time the job was run. This field is only included on job runs.

[`git_tag`](https://docs.databricks.com/api/workspace/jobs/create#git_source-git_tag)string

<= 255 characters 

Example`"release-1.0.0"`

Name of the tag to be checked out and used by this job. This field cannot be specified in conjunction with git_branch or git_commit.

[`git_url`](https://docs.databricks.com/api/workspace/jobs/create#git_source-git_url)required string

<= 300 characters 

Example`"https://github.com/databricks/databricks-cli"`

URL of the repository to be cloned by this job.

[`sparse_checkout`](https://docs.databricks.com/api/workspace/jobs/create#git_source-sparse_checkout)object

[`health`](https://docs.databricks.com/api/workspace/jobs/create#health)object

An optional set of health rules that can be defined for this job.

[`rules`](https://docs.databricks.com/api/workspace/jobs/create#health-rules)Array of object

[`job_clusters`](https://docs.databricks.com/api/workspace/jobs/create#job_clusters)Array of object

<= 100 items 

Example

A list of job cluster specifications that can be shared and reused by tasks of this job. Libraries cannot be declared in a shared job cluster. You must declare dependent libraries in task settings.

Array [

[`job_cluster_key`](https://docs.databricks.com/api/workspace/jobs/create#job_clusters-job_cluster_key)required string

[ 1 .. 100 ] characters ^[\w\-\_]+$

Example`"auto_scaling_cluster"`

A unique name for the job cluster. This field is required and must be unique within the job. `JobTaskSettings` may refer to this field to determine which cluster to launch for the task execution.

[`new_cluster`](https://docs.databricks.com/api/workspace/jobs/create#job_clusters-new_cluster)required object

If new_cluster, a description of a cluster that is created for each task.

 ]

[`max_concurrent_runs`](https://docs.databricks.com/api/workspace/jobs/create#max_concurrent_runs)int32

Default`1`

Example`10`

An optional maximum allowed number of concurrent runs of the job. Set this value if you want to be able to execute multiple runs of the same job concurrently. This is useful for example if you trigger your job on a frequent schedule and want to allow consecutive runs to overlap with each other, or if you want to trigger multiple runs which differ by their input parameters. This setting affects only new runs. For example, suppose the job’s concurrency is 4 and there are 4 concurrent active runs. Then setting the concurrency to 3 won’t kill any of the active runs. However, from then on, new runs are skipped unless there are fewer than 3 active runs. This value cannot exceed 1000. Setting this value to `0` causes all new runs to be skipped.

[`name`](https://docs.databricks.com/api/workspace/jobs/create#name)string

<= 4096 characters 

Default`"Untitled"`

Example`"A multitask job"`

An optional name for the job. The maximum length is 4096 bytes in UTF-8 encoding.

[`notification_settings`](https://docs.databricks.com/api/workspace/jobs/create#notification_settings)object

Default`{}`

Optional notification settings that are used when sending notifications to each of the `email_notifications` and `webhook_notifications` for this job.

[`no_alert_for_canceled_runs`](https://docs.databricks.com/api/workspace/jobs/create#notification_settings-no_alert_for_canceled_runs)boolean

Default`false`

If true, do not send notifications to recipients specified in `on_failure` if the run is canceled.

[`no_alert_for_skipped_runs`](https://docs.databricks.com/api/workspace/jobs/create#notification_settings-no_alert_for_skipped_runs)boolean

Default`false`

If true, do not send notifications to recipients specified in `on_failure` if the run is skipped.

[`parameters`](https://docs.databricks.com/api/workspace/jobs/create#parameters)Array of object

Job-level parameter definitions

Array [

[`default`](https://docs.databricks.com/api/workspace/jobs/create#parameters-default)required string

Example`"users"`

Default value of the parameter.

[`name`](https://docs.databricks.com/api/workspace/jobs/create#parameters-name)required string

^[\w\-.]+$

Example`"table"`

The name of the defined parameter. May only contain alphanumeric characters, `_`, `-`, and `.`

 ]

[`performance_target`](https://docs.databricks.com/api/workspace/jobs/create#performance_target)string

Enum: `PERFORMANCE_OPTIMIZED | STANDARD`

Default`"PERFORMANCE_OPTIMIZED"`

The performance mode on a serverless job. This field determines the level of compute performance or cost-efficiency for the run. The performance target does not apply to tasks that run on Serverless GPU compute.

*   `STANDARD`: Enables cost-efficient execution of serverless workloads.
*   `PERFORMANCE_OPTIMIZED`: Prioritizes fast startup and execution times through rapid scaling and optimized cluster performance.

[`queue`](https://docs.databricks.com/api/workspace/jobs/create#queue)object

The queue settings of the job.

[`enabled`](https://docs.databricks.com/api/workspace/jobs/create#queue-enabled)required boolean

Default`true`

If true, enable queueing for the job. This is a required field.

[`run_as`](https://docs.databricks.com/api/workspace/jobs/create#run_as)object

The user or service principal that the job runs as, if specified in the request. This field indicates the explicit configuration of `run_as` for the job. To find the value in all cases, explicit or implicit, use `run_as_user_name`.

[`service_principal_name`](https://docs.databricks.com/api/workspace/jobs/create#run_as-service_principal_name)string

Example`"692bc6d0-ffa3-11ed-be56-0242ac120002"`

Application ID of an active service principal. Setting this field requires the `servicePrincipal/user` role.

[`user_name`](https://docs.databricks.com/api/workspace/jobs/create#run_as-user_name)string

Example`"user@databricks.com"`

The email of an active workspace user. Non-admin users can only set this field to their own email.

[`schedule`](https://docs.databricks.com/api/workspace/jobs/create#schedule)object

An optional periodic schedule for this job. The default behavior is that the job only runs when triggered by clicking “Run Now” in the Jobs UI or sending an API request to `runNow`.

[`pause_status`](https://docs.databricks.com/api/workspace/jobs/create#schedule-pause_status)string

Enum: `UNPAUSED | PAUSED`

Default`"UNPAUSED"`

Indicate whether this schedule is paused or not.

[`quartz_cron_expression`](https://docs.databricks.com/api/workspace/jobs/create#schedule-quartz_cron_expression)required string

Example`"20 30 * * * ?"`

A Cron expression using Quartz syntax that describes the schedule for a job. See [Cron Trigger](http://www.quartz-scheduler.org/documentation/quartz-2.3.0/tutorials/crontrigger.html) for details. This field is required.

[`timezone_id`](https://docs.databricks.com/api/workspace/jobs/create#schedule-timezone_id)required string

Example`"Europe/London"`

A Java timezone ID. The schedule for a job is resolved with respect to this timezone. See [Java TimeZone](https://docs.oracle.com/javase/7/docs/api/java/util/TimeZone.html) for details. This field is required.

[`tags`](https://docs.databricks.com/api/workspace/jobs/create#tags)object

Default`{}`

Example

A map of tags associated with the job. These are forwarded to the cluster as cluster tags for jobs clusters, and are subject to the same limitations as cluster tags. A maximum of 25 tags can be added to the job.

[`tasks`](https://docs.databricks.com/api/workspace/jobs/create#tasks)Array of object

Example

A list of task specifications to be executed by this job. It supports up to 1000 elements in write endpoints ([jobs/create](https://docs.databricks.com/api/workspace/jobs/create), [jobs/reset](https://docs.databricks.com/api/workspace/jobs/reset), [jobs/update](https://docs.databricks.com/api/workspace/jobs/update), [jobs/submit](https://docs.databricks.com/api/workspace/jobs/submit)). Read endpoints return only 100 tasks. If more than 100 tasks are available, you can paginate through them using [jobs/get](https://docs.databricks.com/api/workspace/jobs/get). Use the `next_page_token` field at the object root to determine if more results are available.

Array [

[`alert_task`](https://docs.databricks.com/api/workspace/jobs/create#tasks-alert_task)object

Public preview

The task evaluates a Databricks alert and sends notifications to subscribers when the `alert_task` field is present.

[`clean_rooms_notebook_task`](https://docs.databricks.com/api/workspace/jobs/create#tasks-clean_rooms_notebook_task)object

The task runs a [clean rooms](https://docs.databricks.com/clean-rooms/index.html) notebook when the `clean_rooms_notebook_task` field is present.

[`compute`](https://docs.databricks.com/api/workspace/jobs/create#tasks-compute)object

Beta

Task level compute configuration.

[`condition_task`](https://docs.databricks.com/api/workspace/jobs/create#tasks-condition_task)object

The task evaluates a condition that can be used to control the execution of other tasks when the `condition_task` field is present. The condition task does not require a cluster to execute and does not support retries or notifications.

[`dashboard_task`](https://docs.databricks.com/api/workspace/jobs/create#tasks-dashboard_task)object

The task refreshes a dashboard and sends a snapshot to subscribers.

[`dbt_task`](https://docs.databricks.com/api/workspace/jobs/create#tasks-dbt_task)object

The task runs one or more dbt commands when the `dbt_task` field is present. The dbt task requires both Databricks SQL and the ability to use a serverless or a pro SQL warehouse.

[`depends_on`](https://docs.databricks.com/api/workspace/jobs/create#tasks-depends_on)Array of object

Example

An optional array of objects specifying the dependency graph of the task. All tasks specified in this field must complete before executing this task. The task will run only if the `run_if` condition is true. The key is `task_key`, and the value is the name assigned to the dependent task.

[`description`](https://docs.databricks.com/api/workspace/jobs/create#tasks-description)string

<= 1000 characters 

Example`"This is the description for this task."`

An optional description for this task.

[`disable_auto_optimization`](https://docs.databricks.com/api/workspace/jobs/create#tasks-disable_auto_optimization)boolean

Default`false`

Example`true`

An option to disable auto optimization in serverless

[`disabled`](https://docs.databricks.com/api/workspace/jobs/create#tasks-disabled)boolean

Default`false`

An optional flag to disable the task. If set to true, the task will not run even if it is part of a job.

[`email_notifications`](https://docs.databricks.com/api/workspace/jobs/create#tasks-email_notifications)object

Default`{}`

An optional set of email addresses that is notified when runs of this task begin or complete as well as when this task is deleted. The default behavior is to not send any emails.

[`environment_key`](https://docs.databricks.com/api/workspace/jobs/create#tasks-environment_key)string

[ 1 .. 100 ] characters ^[\w\-\_]+$

The key that references an environment spec in a job. This field is required for Python script, Python wheel and dbt tasks when using serverless compute.

[`existing_cluster_id`](https://docs.databricks.com/api/workspace/jobs/create#tasks-existing_cluster_id)string

Example`"0923-164208-meows279"`

If existing_cluster_id, the ID of an existing cluster that is used for all runs. When running jobs or tasks on an existing cluster, you may need to manually restart the cluster if it stops responding. We suggest running jobs and tasks on new clusters for greater reliability

[`for_each_task`](https://docs.databricks.com/api/workspace/jobs/create#tasks-for_each_task)object

The task executes a nested task for every input provided when the `for_each_task` field is present.

[`health`](https://docs.databricks.com/api/workspace/jobs/create#tasks-health)object

An optional set of health rules that can be defined for this job.

[`job_cluster_key`](https://docs.databricks.com/api/workspace/jobs/create#tasks-job_cluster_key)string

[ 1 .. 100 ] characters ^[\w\-\_]+$

If job_cluster_key, this task is executed reusing the cluster specified in `job.settings.job_clusters`.

[`libraries`](https://docs.databricks.com/api/workspace/jobs/create#tasks-libraries)Array of object

An optional list of libraries to be installed on the cluster. The default value is an empty list.

[`max_retries`](https://docs.databricks.com/api/workspace/jobs/create#tasks-max_retries)int32

Default`0`

Example`10`

An optional maximum number of times to retry an unsuccessful run. A run is considered to be unsuccessful if it completes with the `FAILED` result_state or `INTERNAL_ERROR``life_cycle_state`. The value `-1` means to retry indefinitely and the value `0` means to never retry.

[`min_retry_interval_millis`](https://docs.databricks.com/api/workspace/jobs/create#tasks-min_retry_interval_millis)int32

Example`2000`

An optional minimal interval in milliseconds between the start of the failed run and the subsequent retry run. The default behavior is that unsuccessful runs are immediately retried.

[`new_cluster`](https://docs.databricks.com/api/workspace/jobs/create#tasks-new_cluster)object

If new_cluster, a description of a new cluster that is created for each run.

[`notebook_task`](https://docs.databricks.com/api/workspace/jobs/create#tasks-notebook_task)object

The task runs a notebook when the `notebook_task` field is present.

[`notification_settings`](https://docs.databricks.com/api/workspace/jobs/create#tasks-notification_settings)object

Default`{}`

Optional notification settings that are used when sending notifications to each of the `email_notifications` and `webhook_notifications` for this task.

[`pipeline_task`](https://docs.databricks.com/api/workspace/jobs/create#tasks-pipeline_task)object

The task triggers a pipeline update when the `pipeline_task` field is present. Only pipelines configured to use triggered more are supported.

[`power_bi_task`](https://docs.databricks.com/api/workspace/jobs/create#tasks-power_bi_task)object

Public preview

The task triggers a Power BI semantic model update when the `power_bi_task` field is present.

[`python_wheel_task`](https://docs.databricks.com/api/workspace/jobs/create#tasks-python_wheel_task)object

The task runs a Python wheel when the `python_wheel_task` field is present.

[`retry_on_timeout`](https://docs.databricks.com/api/workspace/jobs/create#tasks-retry_on_timeout)boolean

Default`false`

Example`true`

An optional policy to specify whether to retry a job when it times out. The default behavior is to not retry on timeout.

[`run_if`](https://docs.databricks.com/api/workspace/jobs/create#tasks-run_if)string

Enum: `ALL_SUCCESS | ALL_DONE | NONE_FAILED | AT_LEAST_ONE_SUCCESS | ALL_FAILED | AT_LEAST_ONE_FAILED`

Default`"ALL_SUCCESS"`

An optional value specifying the condition determining whether the task is run once its dependencies have been completed.

*   `ALL_SUCCESS`: All dependencies have executed and succeeded
*   `AT_LEAST_ONE_SUCCESS`: At least one dependency has succeeded
*   `NONE_FAILED`: None of the dependencies have failed and at least one was executed
*   `ALL_DONE`: All dependencies have been completed
*   `AT_LEAST_ONE_FAILED`: At least one dependency failed
*   `ALL_FAILED`: ALl dependencies have failed

[`run_job_task`](https://docs.databricks.com/api/workspace/jobs/create#tasks-run_job_task)object

The task triggers another job when the `run_job_task` field is present.

[`spark_jar_task`](https://docs.databricks.com/api/workspace/jobs/create#tasks-spark_jar_task)object

The task runs a JAR when the `spark_jar_task` field is present.

[`spark_python_task`](https://docs.databricks.com/api/workspace/jobs/create#tasks-spark_python_task)object

The task runs a Python file when the `spark_python_task` field is present.

[`spark_submit_task`](https://docs.databricks.com/api/workspace/jobs/create#tasks-spark_submit_task)object

Deprecated

(Legacy) The task runs the spark-submit script when the spark_submit_task field is present. Databricks recommends using the spark_jar_task instead; see [Spark Submit task for jobs](https://docs.databricks.com/jobs/spark-submit).

[`sql_task`](https://docs.databricks.com/api/workspace/jobs/create#tasks-sql_task)object

The task runs a SQL query or file, or it refreshes a SQL alert or a legacy SQL dashboard when the `sql_task` field is present.

[`task_key`](https://docs.databricks.com/api/workspace/jobs/create#tasks-task_key)required string

[ 1 .. 100 ] characters ^[\w\-\_]+$

Example`"Task_Key"`

A unique name for the task. This field is used to refer to this task from other tasks. This field is required and must be unique within its parent job. On Update or Reset, this field is used to reference the tasks to be updated or reset.

[`timeout_seconds`](https://docs.databricks.com/api/workspace/jobs/create#tasks-timeout_seconds)int32

Default`0`

Example`86400`

An optional timeout applied to each run of this job task. A value of `0` means no timeout.

[`webhook_notifications`](https://docs.databricks.com/api/workspace/jobs/create#tasks-webhook_notifications)object

Default`{}`

A collection of system notification IDs to notify when runs of this task begin or complete. The default behavior is to not send any system notifications.

 ]

[`timeout_seconds`](https://docs.databricks.com/api/workspace/jobs/create#timeout_seconds)int32

Default`0`

Example`86400`

An optional timeout applied to each run of this job. A value of `0` means no timeout.

[`trigger`](https://docs.databricks.com/api/workspace/jobs/create#trigger)object

A configuration to trigger a run when certain conditions are met. The default behavior is that the job runs only when triggered by clicking “Run Now” in the Jobs UI or sending an API request to `runNow`.

[`file_arrival`](https://docs.databricks.com/api/workspace/jobs/create#trigger-file_arrival)object

File arrival trigger settings.

[`pause_status`](https://docs.databricks.com/api/workspace/jobs/create#trigger-pause_status)string

Enum: `UNPAUSED | PAUSED`

Default`"UNPAUSED"`

Whether this trigger is paused or not.

[`periodic`](https://docs.databricks.com/api/workspace/jobs/create#trigger-periodic)object

Periodic trigger settings.

[`table_update`](https://docs.databricks.com/api/workspace/jobs/create#trigger-table_update)object

[`webhook_notifications`](https://docs.databricks.com/api/workspace/jobs/create#webhook_notifications)object

Default`{}`

A collection of system notification IDs to notify when runs of this job begin or complete.

[`on_duration_warning_threshold_exceeded`](https://docs.databricks.com/api/workspace/jobs/create#webhook_notifications-on_duration_warning_threshold_exceeded)Array of object

An optional list of system notification IDs to call when the duration of a run exceeds the threshold specified for the `RUN_DURATION_SECONDS` metric in the `health` field. A maximum of 3 destinations can be specified for the `on_duration_warning_threshold_exceeded` property.

[`on_failure`](https://docs.databricks.com/api/workspace/jobs/create#webhook_notifications-on_failure)Array of object

An optional list of system notification IDs to call when the run fails. A maximum of 3 destinations can be specified for the `on_failure` property.

[`on_start`](https://docs.databricks.com/api/workspace/jobs/create#webhook_notifications-on_start)Array of object

An optional list of system notification IDs to call when the run starts. A maximum of 3 destinations can be specified for the `on_start` property.

[`on_streaming_backlog_exceeded`](https://docs.databricks.com/api/workspace/jobs/create#webhook_notifications-on_streaming_backlog_exceeded)Array of object

Public preview

An optional list of system notification IDs to call when any streaming backlog thresholds are exceeded for any stream. Streaming backlog thresholds can be set in the `health` field using the following metrics: `STREAMING_BACKLOG_BYTES`, `STREAMING_BACKLOG_RECORDS`, `STREAMING_BACKLOG_SECONDS`, or `STREAMING_BACKLOG_FILES`. Alerting is based on the 10-minute average of these metrics. If the issue persists, notifications are resent every 30 minutes. A maximum of 3 destinations can be specified for the `on_streaming_backlog_exceeded` property.

[`on_success`](https://docs.databricks.com/api/workspace/jobs/create#webhook_notifications-on_success)Array of object

An optional list of system notification IDs to call when the run completes successfully. A maximum of 3 destinations can be specified for the `on_success` property.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`job_id`](https://docs.databricks.com/api/workspace/jobs/create#job_id)int64

Example`11223344`

The canonical identifier for the newly created job.

 This method might return the following HTTP codes: 400, 401, 403, 404, 429, 500

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

404

FEATURE_DISABLED

If a given user/entity is trying to use a feature which has been disabled.

429

REQUEST_LIMIT_EXCEEDED

Request is rejected due to throttling.

500

INTERNAL_SERVER_ERROR

Internal error.

# Request samples

JSON Terraform

Create a serverless job

{

"environments":[

{

"environment_key":"default_python",

"spec":{

"dependencies":[

"dbt-databricks>=1.0.0<2.0.0",

"/Workspace/Users/sharky@databricks.com/artifacts/reef_process-1.0-py32-none-any.whl",

"-r/Workspace/Shared/envs/requirements.txt"

],

"environment_version":"4"

}

},

{

"environment_key":"default_scala",

"spec":{

"environment_version":"4",

"java_dependencies":[

"/Volumes/catalog/schema/volume/path/to/file.jar",

"/Workspace/Users/sharky@databricks.com/artifacts/shark-jar-assembly-0.1.jar"

]

}

}

],

"format":"MULTI_TASK",

"max_concurrent_runs":1,

"name":"Shark Predictor",

"tasks":[

{

"notebook_task":{

"notebook_path":"/Workspace/Users/sharky@databricks.com/weather_ingest"

},

"task_key":"weather_ocean_data"

},

{

"environment_key":"default_python",

"notebook_task":{

"notebook_path":"/Workspace/Users/sharky@databricks.com/ocean_current_ingest"

},

"task_key":"ocean_current_data"

},

{

"environment_key":"default_python",

"spark_python_task":{

"python_file":"/Workspace/Users/sharky@da tabricks.com/shark_sightings.py"

},

"task_key":"shark_sightings"

},

{

"environment_key":"default_python",

"python_wheel_task":{

"entry_point":"main",

"package_name":"reef_data"

},

"task_key":"reef_data"

},

{

"environment_key":"default_scala",

"spark_jar_task":{

"main_class_name":"com.sharky.WaterTemper atureMain"

},

"task_key":"water_temperature_data"

},

{

"depends_on":[

{

"task_key":"reef_data"

},

{

"task_key":"shark_sightings"

},

{

"task_key":"weather_ocean_data"

},

{

"task_key":"ocean_current_data"

},

{

"task_key":"water_temperature_data"

}

],

"pipeline_task":{

"pipeline_id":"1165597e-f650-4bf3-9a4f-fc 2f2d40d2c3"

},

"run_if":"AT_LEAST_ONE_SUCCESS",

"task_key":"combine_shark_data"

},

{

"dbt_task":{

"catalog":"main",

"commands":"dbt run--models 123",

"profiles_directory":"/Workspace/Users/sh arky@databricks.com/dbt-profiles",

"project_directory":"/Workspace/Users/sha rky@databricks.com/check_drift",

"schema":"sharks",

"warehouse_id":"30dade0507d960d1"

},

"depends_on":[

{

"task_key":"combine_shark_data"

}

],

"environment_key":"default_python",

"run_if":"ALL_SUCCESS",

"task_key":"check_drift"

}

]

}

# Response samples

200

{

"job_id":11223344

}
