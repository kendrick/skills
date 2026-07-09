Title: Get a single job run | Jobs API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/jobs/getrun

Markdown Content:
## Get a single job run

`GET/api/2.2/jobs/runs/get`

Retrieves the metadata of a run.

Large arrays in the results will be paginated when they exceed 100 elements. A request for a single run will return all properties for that run, and the first 100 elements of array properties (`tasks`, `job_clusters`, `job_parameters` and `repair_history`). Use the next_page_token field to check for more results and pass its value as the page_token in subsequent requests. If any array properties have more than 100 elements, additional results will be returned on subsequent requests. Arrays without additional results will be empty on later pages.

API scopes (preview):[`jobs`](https://docs.databricks.com/api/workspace/api/scopes#jobs)

### Query parameters

[`run_id`](https://docs.databricks.com/api/workspace/jobs/getrun#run_id)required int64

Example`run_id=455644833`

The canonical identifier of the run for which to retrieve the metadata. This field is required.

[`include_history`](https://docs.databricks.com/api/workspace/jobs/getrun#include_history)boolean

Default`false`

Example`include_history=true`

Whether to include the repair history in the response.

[`include_resolved_values`](https://docs.databricks.com/api/workspace/jobs/getrun#include_resolved_values)boolean

Default`false`

Whether to include resolved parameter values in the response.

[`page_token`](https://docs.databricks.com/api/workspace/jobs/getrun#page_token)string

Example`page_token=CAAos-uriYcxMN7_rt_v7B4=`

Use `next_page_token` returned from the previous GetRun response to request the next page of the run's array properties.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`attempt_number`](https://docs.databricks.com/api/workspace/jobs/getrun#attempt_number)int32

Example`0`

The sequence number of this run attempt for a triggered job run. The initial attempt of a run has an attempt_number of 0. If the initial run attempt fails, and the job has a retry policy (`max_retries`> 0), subsequent runs are created with an `original_attempt_run_id` of the original attempt’s ID and an incrementing `attempt_number`. Runs are retried only until they succeed, and the maximum `attempt_number` is the same as the `max_retries` value for the job.

[`cleanup_duration`](https://docs.databricks.com/api/workspace/jobs/getrun#cleanup_duration)int64

Example`0`

The time in milliseconds it took to terminate the cluster and clean up any associated artifacts. The duration of a task run is the sum of the `setup_duration`, `execution_duration`, and the `cleanup_duration`. The `cleanup_duration` field is set to 0 for multitask job runs. The total duration of a multitask job run is the value of the `run_duration` field.

[`cluster_instance`](https://docs.databricks.com/api/workspace/jobs/getrun#cluster_instance)object

The cluster used for this run. If the run is specified to use a new cluster, this field is set once the Jobs service has requested a cluster for the run.

[`cluster_id`](https://docs.databricks.com/api/workspace/jobs/getrun#cluster_instance-cluster_id)string

Example`"0923-164208-meows279"`

The canonical identifier for the cluster used by a run. This field is always available for runs on existing clusters. For runs on new clusters, it becomes available once the cluster is created. This value can be used to view logs by browsing to `/#setting/sparkui/$cluster_id/driver-logs`. The logs continue to be available after the run completes.

The response won’t include this field if the identifier is not available yet.

[`spark_context_id`](https://docs.databricks.com/api/workspace/jobs/getrun#cluster_instance-spark_context_id)string

The canonical identifier for the Spark context used by a run. This field is filled in once the run begins execution. This value can be used to view the Spark UI by browsing to `/#setting/sparkui/$cluster_id/$spark_context_id`. The Spark UI continues to be available after the run has completed.

The response won’t include this field if the identifier is not available yet.

[`cluster_spec`](https://docs.databricks.com/api/workspace/jobs/getrun#cluster_spec)object

A snapshot of the job’s cluster specification when this run was created.

[`existing_cluster_id`](https://docs.databricks.com/api/workspace/jobs/getrun#cluster_spec-existing_cluster_id)string

Example`"0923-164208-meows279"`

If existing_cluster_id, the ID of an existing cluster that is used for all runs. When running jobs or tasks on an existing cluster, you may need to manually restart the cluster if it stops responding. We suggest running jobs and tasks on new clusters for greater reliability

[`job_cluster_key`](https://docs.databricks.com/api/workspace/jobs/getrun#cluster_spec-job_cluster_key)string

[ 1 .. 100 ] characters ^[\w\-\_]+$

If job_cluster_key, this task is executed reusing the cluster specified in `job.settings.job_clusters`.

[`libraries`](https://docs.databricks.com/api/workspace/jobs/getrun#cluster_spec-libraries)Array of object

An optional list of libraries to be installed on the cluster. The default value is an empty list.

[`new_cluster`](https://docs.databricks.com/api/workspace/jobs/getrun#cluster_spec-new_cluster)object

If new_cluster, a description of a new cluster that is created for each run.

[`creator_user_name`](https://docs.databricks.com/api/workspace/jobs/getrun#creator_user_name)string

Example`"user.name@databricks.com"`

The creator user name. This field won’t be included in the response if the user has already been deleted.

[`description`](https://docs.databricks.com/api/workspace/jobs/getrun#description)string

Description of the run

[`effective_performance_target`](https://docs.databricks.com/api/workspace/jobs/getrun#effective_performance_target)string

Enum: `PERFORMANCE_OPTIMIZED | STANDARD`

The actual performance target used by the serverless run during execution. This can differ from the client-set performance target on the request depending on whether the performance mode is supported by the job type.

*   `STANDARD`: Enables cost-efficient execution of serverless workloads.
*   `PERFORMANCE_OPTIMIZED`: Prioritizes fast startup and execution times through rapid scaling and optimized cluster performance.

[`end_time`](https://docs.databricks.com/api/workspace/jobs/getrun#end_time)int64

Example`1625060863413`

The time at which this run ended in epoch milliseconds (milliseconds since 1/1/1970 UTC). This field is set to 0 if the job is still running.

[`execution_duration`](https://docs.databricks.com/api/workspace/jobs/getrun#execution_duration)int64

Example`0`

The time in milliseconds it took to execute the commands in the JAR or notebook until they completed, failed, timed out, were cancelled, or encountered an unexpected error. The duration of a task run is the sum of the `setup_duration`, `execution_duration`, and the `cleanup_duration`. The `execution_duration` field is set to 0 for multitask job runs. The total duration of a multitask job run is the value of the `run_duration` field.

[`git_source`](https://docs.databricks.com/api/workspace/jobs/getrun#git_source)object

Example

An optional specification for a remote Git repository containing the source code used by tasks. Version-controlled source code is supported by notebook, dbt, Python script, and SQL File tasks.

If `git_source` is set, these tasks retrieve the file from the remote repository by default. However, this behavior can be overridden by setting `source` to `WORKSPACE` on the task.

Note: dbt and SQL File tasks support only version-controlled sources. If dbt or SQL File tasks are used, `git_source` must be defined on the job.

[`git_branch`](https://docs.databricks.com/api/workspace/jobs/getrun#git_source-git_branch)string

<= 255 characters 

Example`"main"`

Name of the branch to be checked out and used by this job. This field cannot be specified in conjunction with git_tag or git_commit.

[`git_commit`](https://docs.databricks.com/api/workspace/jobs/getrun#git_source-git_commit)string

<= 64 characters 

Example`"e0056d01"`

Commit to be checked out and used by this job. This field cannot be specified in conjunction with git_branch or git_tag.

[`git_provider`](https://docs.databricks.com/api/workspace/jobs/getrun#git_source-git_provider)string

Enum: `gitHub | bitbucketCloud | azureDevOpsServices | gitHubEnterprise | bitbucketServer | gitLab | gitLabEnterpriseEdition | awsCodeCommit`

Unique identifier of the service used to host the Git repository. The value is case insensitive.

[`git_snapshot`](https://docs.databricks.com/api/workspace/jobs/getrun#git_source-git_snapshot)object

Read-only state of the remote repository at the time the job was run. This field is only included on job runs.

[`git_tag`](https://docs.databricks.com/api/workspace/jobs/getrun#git_source-git_tag)string

<= 255 characters 

Example`"release-1.0.0"`

Name of the tag to be checked out and used by this job. This field cannot be specified in conjunction with git_branch or git_commit.

[`git_url`](https://docs.databricks.com/api/workspace/jobs/getrun#git_source-git_url)string

<= 300 characters 

Example`"https://github.com/databricks/databricks-cli"`

URL of the repository to be cloned by this job.

[`sparse_checkout`](https://docs.databricks.com/api/workspace/jobs/getrun#git_source-sparse_checkout)object

Beta

[`has_more`](https://docs.databricks.com/api/workspace/jobs/getrun#has_more)boolean

Example`true`

Indicates if the run has more array properties (`tasks`, `job_clusters`) that are not shown. They can be accessed via [jobs/getrun](https://docs.databricks.com/api/workspace/jobs/getrun) endpoint. It is only relevant for API 2.2 [jobs/listruns](https://docs.databricks.com/api/workspace/jobs/listruns) requests with `expand_tasks=true`.

[`job_clusters`](https://docs.databricks.com/api/workspace/jobs/getrun#job_clusters)Array of object

<= 100 items 

Example

A list of job cluster specifications that can be shared and reused by tasks of this job. Libraries cannot be declared in a shared job cluster. You must declare dependent libraries in task settings. If more than 100 job clusters are available, you can paginate through them using [jobs/getrun](https://docs.databricks.com/api/workspace/jobs/getrun).

Array [

[`job_cluster_key`](https://docs.databricks.com/api/workspace/jobs/getrun#job_clusters-job_cluster_key)string

[ 1 .. 100 ] characters ^[\w\-\_]+$

Example`"auto_scaling_cluster"`

A unique name for the job cluster. This field is required and must be unique within the job. `JobTaskSettings` may refer to this field to determine which cluster to launch for the task execution.

[`new_cluster`](https://docs.databricks.com/api/workspace/jobs/getrun#job_clusters-new_cluster)object

If new_cluster, a description of a cluster that is created for each task.

 ]

[`job_id`](https://docs.databricks.com/api/workspace/jobs/getrun#job_id)int64

Example`11223344`

The canonical identifier of the job that contains this run.

[`job_parameters`](https://docs.databricks.com/api/workspace/jobs/getrun#job_parameters)Array of object

Job-level parameters used in the run

Array [

[`default`](https://docs.databricks.com/api/workspace/jobs/getrun#job_parameters-default)string

Example`"users"`

The optional default value of the parameter

[`name`](https://docs.databricks.com/api/workspace/jobs/getrun#job_parameters-name)string

Example`"table"`

The name of the parameter

[`value`](https://docs.databricks.com/api/workspace/jobs/getrun#job_parameters-value)string

Example`"customers"`

The value used in the run

 ]

[`job_run_id`](https://docs.databricks.com/api/workspace/jobs/getrun#job_run_id)int64

ID of the job run that this run belongs to. For legacy and single-task job runs the field is populated with the job run ID. For task runs, the field is populated with the ID of the job run that the task run belongs to.

[`next_page_token`](https://docs.databricks.com/api/workspace/jobs/getrun#next_page_token)string

Example`"CAAos-uriYcxMN7_rt_v7B4="`

A token that can be used to list the next page of array properties.

[`number_in_job`](https://docs.databricks.com/api/workspace/jobs/getrun#number_in_job)int64

Deprecated

Example`455644833`

A unique identifier for this job run. This is set to the same value as `run_id`.

[`original_attempt_run_id`](https://docs.databricks.com/api/workspace/jobs/getrun#original_attempt_run_id)int64

Example`455644833`

If this run is a retry of a prior run attempt, this field contains the run_id of the original attempt; otherwise, it is the same as the run_id.

[`overriding_parameters`](https://docs.databricks.com/api/workspace/jobs/getrun#overriding_parameters)object

The parameters used for this run.

[`pipeline_params`](https://docs.databricks.com/api/workspace/jobs/getrun#overriding_parameters-pipeline_params)object

Controls whether the pipeline should perform a full refresh

[`queue_duration`](https://docs.databricks.com/api/workspace/jobs/getrun#queue_duration)int64

Example`1625060863413`

The time in milliseconds that the run has spent in the queue.

[`repair_history`](https://docs.databricks.com/api/workspace/jobs/getrun#repair_history)Array of object

The repair history of the run.

Array [

[`effective_performance_target`](https://docs.databricks.com/api/workspace/jobs/getrun#repair_history-effective_performance_target)string

Enum: `PERFORMANCE_OPTIMIZED | STANDARD`

The actual performance target used by the serverless run during execution. This can differ from the client-set performance target on the request depending on whether the performance mode is supported by the job type.

*   `STANDARD`: Enables cost-efficient execution of serverless workloads.
*   `PERFORMANCE_OPTIMIZED`: Prioritizes fast startup and execution times through rapid scaling and optimized cluster performance.

[`end_time`](https://docs.databricks.com/api/workspace/jobs/getrun#repair_history-end_time)int64

Example`1625060863413`

The end time of the (repaired) run.

[`id`](https://docs.databricks.com/api/workspace/jobs/getrun#repair_history-id)int64

Example`734650698524280`

The ID of the repair. Only returned for the items that represent a repair in `repair_history`.

[`start_time`](https://docs.databricks.com/api/workspace/jobs/getrun#repair_history-start_time)int64

Example`1625060460483`

The start time of the (repaired) run.

[`state`](https://docs.databricks.com/api/workspace/jobs/getrun#repair_history-state)object

Deprecated

Deprecated. Please use the `status` field instead.

[`status`](https://docs.databricks.com/api/workspace/jobs/getrun#repair_history-status)object

The current status of the run

[`task_run_ids`](https://docs.databricks.com/api/workspace/jobs/getrun#repair_history-task_run_ids)Array of int64

Example

The run IDs of the task runs that ran as part of this repair history item.

[`type`](https://docs.databricks.com/api/workspace/jobs/getrun#repair_history-type)string

Enum: `ORIGINAL | REPAIR`

The repair history item type. Indicates whether a run is the original run or a repair run.

 ]

[`run_duration`](https://docs.databricks.com/api/workspace/jobs/getrun#run_duration)int64

Example`110183`

The time in milliseconds it took the job run and all of its repairs to finish.

[`run_id`](https://docs.databricks.com/api/workspace/jobs/getrun#run_id)int64

Example`455644833`

The canonical identifier of the run. This ID is unique across all runs of all jobs.

[`run_name`](https://docs.databricks.com/api/workspace/jobs/getrun#run_name)string

<= 4096 characters 

Default`"Untitled"`

Example`"A multitask job run"`

An optional name for the run. The maximum length is 4096 bytes in UTF-8 encoding.

[`run_page_url`](https://docs.databricks.com/api/workspace/jobs/getrun#run_page_url)string

Example`"https://my-workspace.cloud.databricks.com/#job/11223344/run/123"`

The URL to the detail page of the run.

[`run_type`](https://docs.databricks.com/api/workspace/jobs/getrun#run_type)string

Enum: `JOB_RUN | WORKFLOW_RUN | SUBMIT_RUN`

The type of a run.

*   `JOB_RUN`: Normal job run. A run created with [jobs/runnow](https://docs.databricks.com/api/workspace/jobs/runnow).
*   `WORKFLOW_RUN`: Workflow run. A run created with [dbutils.notebook.run](https://docs.databricks.com/dev-tools/databricks-utils.html#dbutils-workflow).
*   `SUBMIT_RUN`: Submit run. A run created with [jobs/submit](https://docs.databricks.com/api/workspace/jobs/submit).

[`schedule`](https://docs.databricks.com/api/workspace/jobs/getrun#schedule)object

The cron schedule that triggered this run if it was triggered by the periodic scheduler.

[`pause_status`](https://docs.databricks.com/api/workspace/jobs/getrun#schedule-pause_status)string

Enum: `UNPAUSED | PAUSED`

Default`"UNPAUSED"`

Indicate whether this schedule is paused or not.

[`quartz_cron_expression`](https://docs.databricks.com/api/workspace/jobs/getrun#schedule-quartz_cron_expression)string

Example`"20 30 * * * ?"`

A Cron expression using Quartz syntax that describes the schedule for a job. See [Cron Trigger](http://www.quartz-scheduler.org/documentation/quartz-2.3.0/tutorials/crontrigger.html) for details. This field is required.

[`timezone_id`](https://docs.databricks.com/api/workspace/jobs/getrun#schedule-timezone_id)string

Example`"Europe/London"`

A Java timezone ID. The schedule for a job is resolved with respect to this timezone. See [Java TimeZone](https://docs.oracle.com/javase/7/docs/api/java/util/TimeZone.html) for details. This field is required.

[`setup_duration`](https://docs.databricks.com/api/workspace/jobs/getrun#setup_duration)int64

Example`0`

The time in milliseconds it took to set up the cluster. For runs that run on new clusters this is the cluster creation time, for runs that run on existing clusters this time should be very short. The duration of a task run is the sum of the `setup_duration`, `execution_duration`, and the `cleanup_duration`. The `setup_duration` field is set to 0 for multitask job runs. The total duration of a multitask job run is the value of the `run_duration` field.

[`start_time`](https://docs.databricks.com/api/workspace/jobs/getrun#start_time)int64

Example`1625060460483`

The time at which this run was started in epoch milliseconds (milliseconds since 1/1/1970 UTC). This may not be the time when the job task starts executing, for example, if the job is scheduled to run on a new cluster, this is the time the cluster creation call is issued.

[`state`](https://docs.databricks.com/api/workspace/jobs/getrun#state)object

Deprecated

Deprecated. Please use the `status` field instead.

[`life_cycle_state`](https://docs.databricks.com/api/workspace/jobs/getrun#state-life_cycle_state)string

Enum: `PENDING | RUNNING | TERMINATING | TERMINATED | SKIPPED | INTERNAL_ERROR | BLOCKED | WAITING_FOR_RETRY | QUEUED`

A value indicating the run's current lifecycle state. This field is always available in the response. Note: Additional states might be introduced in future releases.

[`queue_reason`](https://docs.databricks.com/api/workspace/jobs/getrun#state-queue_reason)string

Example`"Queued due to reaching maximum concurrent runs of 1."`

The reason indicating why the run was queued.

[`result_state`](https://docs.databricks.com/api/workspace/jobs/getrun#state-result_state)string

Enum: `SUCCESS | FAILED | TIMEDOUT | CANCELED | MAXIMUM_CONCURRENT_RUNS_REACHED | UPSTREAM_CANCELED | UPSTREAM_FAILED | EXCLUDED | SUCCESS_WITH_FAILURES | DISABLED`

A value indicating the run's result. This field is only available for terminal lifecycle states. Note: Additional states might be introduced in future releases.

[`state_message`](https://docs.databricks.com/api/workspace/jobs/getrun#state-state_message)string

A descriptive message for the current state. This field is unstructured, and its exact format is subject to change.

[`user_cancelled_or_timedout`](https://docs.databricks.com/api/workspace/jobs/getrun#state-user_cancelled_or_timedout)boolean

Default`false`

A value indicating whether a run was canceled manually by a user or by the scheduler because the run timed out.

[`status`](https://docs.databricks.com/api/workspace/jobs/getrun#status)object

The current status of the run

[`queue_details`](https://docs.databricks.com/api/workspace/jobs/getrun#status-queue_details)object

If the run was queued, details about the reason for queuing the run.

[`state`](https://docs.databricks.com/api/workspace/jobs/getrun#status-state)string

Enum: `BLOCKED | PENDING | QUEUED | RUNNING | TERMINATING | TERMINATED | WAITING`

The current state of the run.

[`termination_details`](https://docs.databricks.com/api/workspace/jobs/getrun#status-termination_details)object

If the run is in a TERMINATING or TERMINATED state, details about the reason for terminating the run.

[`tasks`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks)Array of object

<= 100 items 

Example

The list of tasks performed by the run. Each task has its own `run_id` which you can use to call `JobsGetOutput` to retrieve the run resutls. If more than 100 tasks are available, you can paginate through them using [jobs/getrun](https://docs.databricks.com/api/workspace/jobs/getrun). Use the `next_page_token` field at the object root to determine if more results are available.

Array [

[`alert_task`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-alert_task)object

Beta

The task evaluates a Databricks alert and sends notifications to subscribers when the `alert_task` field is present.

[`attempt_number`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-attempt_number)int32

Example`0`

The sequence number of this run attempt for a triggered job run. The initial attempt of a run has an attempt_number of 0. If the initial run attempt fails, and the job has a retry policy (`max_retries`> 0), subsequent runs are created with an `original_attempt_run_id` of the original attempt’s ID and an incrementing `attempt_number`. Runs are retried only until they succeed, and the maximum `attempt_number` is the same as the `max_retries` value for the job.

[`clean_rooms_notebook_task`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-clean_rooms_notebook_task)object

The task runs a [clean rooms](https://docs.databricks.com/clean-rooms/index.html) notebook when the `clean_rooms_notebook_task` field is present.

[`cleanup_duration`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-cleanup_duration)int64

Example`0`

The time in milliseconds it took to terminate the cluster and clean up any associated artifacts. The duration of a task run is the sum of the `setup_duration`, `execution_duration`, and the `cleanup_duration`. The `cleanup_duration` field is set to 0 for multitask job runs. The total duration of a multitask job run is the value of the `run_duration` field.

[`cluster_instance`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-cluster_instance)object

The cluster used for this run. If the run is specified to use a new cluster, this field is set once the Jobs service has requested a cluster for the run.

[`condition_task`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-condition_task)object

The task evaluates a condition that can be used to control the execution of other tasks when the `condition_task` field is present. The condition task does not require a cluster to execute and does not support retries or notifications.

[`dashboard_task`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-dashboard_task)object

The task refreshes a dashboard and sends a snapshot to subscribers.

[`dbt_task`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-dbt_task)object

The task runs one or more dbt commands when the `dbt_task` field is present. The dbt task requires both Databricks SQL and the ability to use a serverless or a pro SQL warehouse.

[`depends_on`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-depends_on)Array of object

An optional array of objects specifying the dependency graph of the task. All tasks specified in this field must complete successfully before executing this task. The key is `task_key`, and the value is the name assigned to the dependent task.

[`description`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-description)string

<= 1000 characters 

Example`"This is the description for this task."`

An optional description for this task.

[`disable_auto_optimization`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-disable_auto_optimization)boolean

Default`false`

Example`true`

An option to disable auto optimization in serverless

[`effective_performance_target`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-effective_performance_target)string

Enum: `PERFORMANCE_OPTIMIZED | STANDARD`

The actual performance target used by the serverless run during execution. This can differ from the client-set performance target on the request depending on whether the performance mode is supported by the job type.

*   `STANDARD`: Enables cost-efficient execution of serverless workloads.
*   `PERFORMANCE_OPTIMIZED`: Prioritizes fast startup and execution times through rapid scaling and optimized cluster performance.

[`email_notifications`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-email_notifications)object

Default`{}`

An optional set of email addresses notified when the task run begins or completes. The default behavior is to not send any emails.

[`end_time`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-end_time)int64

Example`1625060863413`

The time at which this run ended in epoch milliseconds (milliseconds since 1/1/1970 UTC). This field is set to 0 if the job is still running.

[`environment_key`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-environment_key)string

[ 1 .. 100 ] characters ^[\w\-\_]+$

The key that references an environment spec in a job. This field is required for Python script, Python wheel and dbt tasks when using serverless compute.

[`execution_duration`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-execution_duration)int64

Example`0`

The time in milliseconds it took to execute the commands in the JAR or notebook until they completed, failed, timed out, were cancelled, or encountered an unexpected error. The duration of a task run is the sum of the `setup_duration`, `execution_duration`, and the `cleanup_duration`. The `execution_duration` field is set to 0 for multitask job runs. The total duration of a multitask job run is the value of the `run_duration` field.

[`existing_cluster_id`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-existing_cluster_id)string

Example`"0923-164208-meows279"`

If existing_cluster_id, the ID of an existing cluster that is used for all runs. When running jobs or tasks on an existing cluster, you may need to manually restart the cluster if it stops responding. We suggest running jobs and tasks on new clusters for greater reliability

[`for_each_task`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-for_each_task)object

The task executes a nested task for every input provided when the `for_each_task` field is present.

[`git_source`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-git_source)object

Example

An optional specification for a remote Git repository containing the source code used by tasks. Version-controlled source code is supported by notebook, dbt, Python script, and SQL File tasks. If `git_source` is set, these tasks retrieve the file from the remote repository by default. However, this behavior can be overridden by setting `source` to `WORKSPACE` on the task. Note: dbt and SQL File tasks support only version-controlled sources. If dbt or SQL File tasks are used, `git_source` must be defined on the job.

[`job_cluster_key`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-job_cluster_key)string

[ 1 .. 100 ] characters ^[\w\-\_]+$

If job_cluster_key, this task is executed reusing the cluster specified in `job.settings.job_clusters`.

[`libraries`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-libraries)Array of object

An optional list of libraries to be installed on the cluster. The default value is an empty list.

[`max_retries`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-max_retries)int32

Default`0`

Example`10`

An optional maximum number of times to retry an unsuccessful run. A run is considered to be unsuccessful if it completes with the `FAILED` result_state or `INTERNAL_ERROR``life_cycle_state`. The value `-1` means to retry indefinitely and the value `0` means to never retry.

[`min_retry_interval_millis`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-min_retry_interval_millis)int32

Example`2000`

An optional minimal interval in milliseconds between the start of the failed run and the subsequent retry run. The default behavior is that unsuccessful runs are immediately retried.

[`new_cluster`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-new_cluster)object

If new_cluster, a description of a new cluster that is created for each run.

[`notebook_task`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-notebook_task)object

The task runs a notebook when the `notebook_task` field is present.

[`notification_settings`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-notification_settings)object

Default`{}`

Optional notification settings that are used when sending notifications to each of the `email_notifications` and `webhook_notifications` for this task run.

[`pipeline_task`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-pipeline_task)object

The task triggers a pipeline update when the `pipeline_task` field is present. Only pipelines configured to use triggered more are supported.

[`power_bi_task`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-power_bi_task)object

Public preview

The task triggers a Power BI semantic model update when the `power_bi_task` field is present.

[`python_wheel_task`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-python_wheel_task)object

The task runs a Python wheel when the `python_wheel_task` field is present.

[`queue_duration`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-queue_duration)int64

Example`1625060863413`

The time in milliseconds that the run has spent in the queue.

[`resolved_values`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-resolved_values)object

Parameter values including resolved references

[`retry_on_timeout`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-retry_on_timeout)boolean

Default`false`

Example`true`

An optional policy to specify whether to retry a job when it times out. The default behavior is to not retry on timeout.

[`run_duration`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-run_duration)int64

Example`110183`

The time in milliseconds it took the job run and all of its repairs to finish.

[`run_id`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-run_id)int64

Example`99887766`

The ID of the task run.

[`run_if`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-run_if)string

Enum: `ALL_SUCCESS | ALL_DONE | NONE_FAILED | AT_LEAST_ONE_SUCCESS | ALL_FAILED | AT_LEAST_ONE_FAILED`

Example`"ALL_SUCCESS"`

An optional value indicating the condition that determines whether the task should be run once its dependencies have been completed. When omitted, defaults to `ALL_SUCCESS`. See [jobs/create](https://docs.databricks.com/api/workspace/jobs/create) for a list of possible values.

[`run_job_task`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-run_job_task)object

The task triggers another job when the `run_job_task` field is present.

[`run_page_url`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-run_page_url)string

[`setup_duration`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-setup_duration)int64

Example`0`

The time in milliseconds it took to set up the cluster. For runs that run on new clusters this is the cluster creation time, for runs that run on existing clusters this time should be very short. The duration of a task run is the sum of the `setup_duration`, `execution_duration`, and the `cleanup_duration`. The `setup_duration` field is set to 0 for multitask job runs. The total duration of a multitask job run is the value of the `run_duration` field.

[`spark_jar_task`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-spark_jar_task)object

The task runs a JAR when the `spark_jar_task` field is present.

[`spark_python_task`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-spark_python_task)object

The task runs a Python file when the `spark_python_task` field is present.

[`spark_submit_task`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-spark_submit_task)object

Deprecated

(Legacy) The task runs the spark-submit script when the spark_submit_task field is present. Databricks recommends using the spark_jar_task instead; see [Spark Submit task for jobs](https://docs.databricks.com/jobs/spark-submit).

[`sql_task`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-sql_task)object

The task runs a SQL query or file, or it refreshes a SQL alert or a legacy SQL dashboard when the `sql_task` field is present.

[`start_time`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-start_time)int64

Example`1625060460483`

The time at which this run was started in epoch milliseconds (milliseconds since 1/1/1970 UTC). This may not be the time when the job task starts executing, for example, if the job is scheduled to run on a new cluster, this is the time the cluster creation call is issued.

[`state`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-state)object

Deprecated

Deprecated. Please use the `status` field instead.

[`status`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-status)object

The current status of the run

[`task_key`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-task_key)string

[ 1 .. 100 ] characters ^[\w\-\_]+$

Example`"Task_Key"`

A unique name for the task. This field is used to refer to this task from other tasks. This field is required and must be unique within its parent job. On Update or Reset, this field is used to reference the tasks to be updated or reset.

[`timeout_seconds`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-timeout_seconds)int32

Default`0`

Example`86400`

An optional timeout applied to each run of this job task. A value of `0` means no timeout.

[`webhook_notifications`](https://docs.databricks.com/api/workspace/jobs/getrun#tasks-webhook_notifications)object

Default`{}`

A collection of system notification IDs to notify when the run begins or completes. The default behavior is to not send any system notifications. Task webhooks respect the task notification settings.

 ]

[`trigger`](https://docs.databricks.com/api/workspace/jobs/getrun#trigger)string

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

[`trigger_info`](https://docs.databricks.com/api/workspace/jobs/getrun#trigger_info)object

Additional details about what triggered the run

[`run_id`](https://docs.databricks.com/api/workspace/jobs/getrun#trigger_info-run_id)int64

The run id of the Run Job task run

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

"effective_performance_target":"PERFORMANCE_OPT IMIZED",

"end_time":1625060863413,

"execution_duration":0,

"git_source":{

"git_branch":"main",

"git_provider":"gitHub",

"git_url":"https://github.com/databricks/data bricks-cli"

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

"effective_performance_target":"PERFORMANCE _OPTIMIZED",

"end_time":1625060863413,

"id":734650698524280,

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

"run_page_url":"https://my-workspace.cloud.data bricks.com/#job/11223344/run/123",

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

"queue_reason":"Queued due to reaching maximu m concurrent runs of 1.",

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

"jar":"dbfs:/mnt/databricks/OrderIngest.jar"

}

],

"run_id":2112892,

"run_if":"ALL_SUCCESS",

"run_page_url":"https://my-workspace.cloud.databricks.com/#job/39832/run/20",

"setup_duration":0,

"spark_jar_task":{

"main_class_name":"com.databricks.OrdersI ngest"

},

"start_time":1629989929660,

"state":{

"life_cycle_state":"INTERNAL_ERROR",

"result_state":"FAILED",

"state_message":"Library installation fai led for library due to user error.Error messages:\n'Manage'permissions are required to install lib raries on a cluster",

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

"description":"Matches orders with user ses sions",

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

"notebook_path":"/Users/user.name@databri cks.com/Match",

"source":"WORKSPACE"

},

"run_id":2112897,

"run_if":"ALL_SUCCESS",

"run_page_url":"https://my-workspace.cloud.databricks.com/#job/39832/run/21",

"setup_duration":0,

"start_time":0,

"state":{

"life_cycle_state":"SKIPPED",

"state_message":"An upstream task failed.",

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

"description":"Extracts session data from e vents",

"end_time":1629989930144,

"execution_duration":0,

"existing_cluster_id":"0923-164208-meows279",

"libraries":[

{

"jar":"dbfs:/mnt/databricks/Sessionize.jar"

}

],

"run_id":2112902,

"run_if":"ALL_SUCCESS",

"run_page_url":"https://my-workspace.cloud.databricks.com/#job/39832/run/22",

"setup_duration":0,

"spark_jar_task":{

"main_class_name":"com.databricks.Session ize"

},

"start_time":1629989929668,

"state":{

"life_cycle_state":"INTERNAL_ERROR",

"result_state":"FAILED",

"state_message":"Library installation fai led for library due to user error.Error messages:\n'Manage'permissions are required to install lib raries on a cluster",

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
