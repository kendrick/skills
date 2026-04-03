# Jobs & Workflows -- Databricks Python SDK

> Raw docs: ../docs/raw/ -- for full endpoint details, read {service}-{operation}.md
> Package: `databricks-sdk`

## Setup

```python
from databricks.sdk import WorkspaceClient
from databricks.sdk.service.jobs import *
from databricks.sdk.service.compute import ClusterSpec, AutoScale

w = WorkspaceClient()  # uses DATABRICKS_HOST + DATABRICKS_TOKEN env vars
# SDK client map:
#   w.jobs              -- job CRUD, runs, permissions
#   w.policy_compliance_for_jobs  -- policy compliance
```

---

## 1. Job CRUD

### Create Job
```python
job = w.jobs.create(
    name="my-etl-pipeline",
    tasks=[
        Task(
            task_key="extract",
            notebook_task=NotebookTask(notebook_path="/etl/extract"),
            existing_cluster_id="0923-164208-meows279",
        ),
        Task(
            task_key="transform",
            depends_on=[TaskDependency(task_key="extract")],
            notebook_task=NotebookTask(notebook_path="/etl/transform"),
            job_cluster_key="shared_cluster",
        ),
    ],
    job_clusters=[JobCluster(
        job_cluster_key="shared_cluster",
        new_cluster=ClusterSpec(spark_version="14.3.x-scala2.12", num_workers=4, node_type_id="i3.xlarge"),
    )],
    schedule=CronSchedule(quartz_cron_expression="0 0 8 * * ?", timezone_id="US/Eastern"),
    max_concurrent_runs=1,
    tags={"team": "data-eng"},
)
print(job.job_id)
```
Key params: `name`, `tasks` (list[Task]), `job_clusters`, `schedule`/`continuous` (mutually exclusive), `trigger`, `tags` (max 25), `run_as`, `queue`, `timeout_seconds`, `email_notifications`, `health`, `parameters`, `environments` (serverless), `git_source`, `budget_policy_id`, `performance_target`.
Task types: `notebook_task`, `spark_jar_task`, `spark_python_task`, `python_wheel_task`, `sql_task`, `dbt_task`, `pipeline_task`, `run_job_task`, `condition_task`, `for_each_task`, `dashboard_task`, `alert_task`.

### Get Job
```python
job = w.jobs.get(job_id=11223344)
# Paginated: arrays >100 items. Use page_token for more.
```

### List Jobs
```python
for job in w.jobs.list(name="etl", expand_tasks=False):
    print(job.job_id, job.settings.name)
```
SDK auto-paginates. Filter params: `name`, `expand_tasks`.

### Update (Partial)
```python
w.jobs.update(
    job_id=11223344,
    new_settings=JobSettings(name="renamed-job"),
    fields_to_remove=["schedule"],
)
```
Top-level fields replaced; arrays merged by key. Use `fields_to_remove` for deletions.

### Reset (Full Replace)
```python
w.jobs.reset(
    job_id=11223344,
    new_settings=JobSettings(
        name="fully-reset-job",
        tasks=[Task(task_key="t1", notebook_task=NotebookTask(notebook_path="/new"))],
    ),
)
```
Overwrites ALL settings. Unspecified fields revert to defaults.

### Delete
```python
w.jobs.delete(job_id=11223344)
```

---

## 2. Triggering Runs

### Run Now (existing job)
```python
run = w.jobs.run_now(
    job_id=11223344,
    job_parameters={"env": "prod"},
    idempotency_token="unique-uuid",
)
print(run.run_id)
```
Optional: `only` (task keys subset), `queue`, `pipeline_params`, `performance_target`.

### Submit (one-time, no saved job)
```python
run = w.jobs.submit(
    run_name="one-off-etl",
    tasks=[SubmitTask(
        task_key="t1",
        notebook_task=NotebookTask(notebook_path="/adhoc"),
        new_cluster=ClusterSpec(spark_version="14.3.x-scala2.12", num_workers=2, node_type_id="i3.xlarge"),
    )],
)
print(run.run_id)
```
**Warning**: Submit runs do NOT show in Jobs UI, do NOT retry, and lack serverless auto-optimization.

---

## 3. Run Management

### Get Run
```python
run = w.jobs.get_run(run_id=455644833, include_history=True, include_resolved_values=True)
print(run.status.state)           # QUEUED, RUNNING, TERMINATED, etc.
print(run.status.termination_details)  # code, message, type
print(run.run_page_url)           # link to run in UI
print(run.run_type)               # JOB_RUN, WORKFLOW_RUN, SUBMIT_RUN
# Paginate tasks >100: pass page_token from run.next_page_token
```

### List Runs
```python
for run in w.jobs.list_runs(job_id=11223344, active_only=True):
    print(run.run_id, run.status.state)
```
SDK auto-paginates. Filters: `active_only`, `completed_only`, `run_type`, `start_time_from`, `start_time_to`.

### Get Run Output
```python
output = w.jobs.get_run_output(run_id=455644833)
print(output.notebook_output.result)  # from dbutils.notebook.exit()
print(output.logs)  # stdout/stderr for jar/python tasks
print(output.error)  # error message if failed
```
Limit: 5 MB. Runs expire after 60 days.

### Export Run
```python
export = w.jobs.export_run(run_id=455644833, views_to_export=ViewsToExport.CODE)
for view in export.views:
    print(view.name, view.type)
```

### Cancel Run
```python
w.jobs.cancel_run(run_id=455644833)
# Async: run may still be executing after call returns
```

### Cancel All Runs
```python
w.jobs.cancel_all_runs(job_id=11223344)
```

### Delete Run
```python
w.jobs.delete_run(run_id=455644833)
# Must be non-active. Cancel first if needed.
```

### Repair Run
```python
repair = w.jobs.repair_run(
    run_id=455644833,
    rerun_all_failed_tasks=True,
    latest_repair_id=734650698524280,  # required for 2nd+ repair
)
print(repair.repair_id)  # pass as latest_repair_id for next repair
```
Options: `rerun_tasks` (list of task keys), `rerun_all_failed_tasks`, `rerun_dependent_tasks`, `job_parameters`. Only one of `rerun_tasks` or `rerun_all_failed_tasks`.

---

## 4. Permissions

Levels: `CAN_VIEW`, `CAN_MANAGE_RUN`, `CAN_MANAGE`, `IS_OWNER`

```python
# Get
perms = w.jobs.get_permissions(job_id="11223344")

# Set (full replace)
w.jobs.set_permissions(
    job_id="11223344",
    access_control_list=[JobAccessControlRequest(
        user_name="user@co.com", permission_level=JobPermissionLevel.CAN_MANAGE,
    )],
)

# Update (additive merge)
w.jobs.update_permissions(
    job_id="11223344",
    access_control_list=[JobAccessControlRequest(
        group_name="data-eng", permission_level=JobPermissionLevel.CAN_MANAGE_RUN,
    )],
)

# Get available levels
levels = w.jobs.get_permission_levels(job_id="11223344")
```

---

## 5. Policy Compliance

```python
# Check compliance
status = w.policy_compliance_for_jobs.get_compliance(job_id=11223344)
print(status.is_compliant, status.violations)

# Enforce (dry-run)
result = w.policy_compliance_for_jobs.enforce_compliance(job_id=11223344, validate_only=True)
print(result.has_changes, result.job_cluster_changes)

# Enforce (apply)
result = w.policy_compliance_for_jobs.enforce_compliance(job_id=11223344)

# List compliance for a policy
for item in w.policy_compliance_for_jobs.list_compliance(policy_id="policy-id"):
    print(item.job_id, item.is_compliant)
```

---

## Common Patterns

### Create job and trigger immediately
```python
job = w.jobs.create(name="etl-pipeline", tasks=[...])
run = w.jobs.run_now(job_id=job.job_id)
```

### Wait for run completion
```python
run = w.jobs.run_now(job_id=job.job_id).result()  # blocks until done
# OR poll:
import time
while True:
    r = w.jobs.get_run(run_id=run.run_id)
    if r.status.state in (RunState.TERMINATED, RunState.SKIPPED, RunState.INTERNAL_ERROR):
        break
    time.sleep(10)
```

### Repair failed tasks
```python
run = w.jobs.get_run(run_id=run_id)
repair = w.jobs.repair_run(run_id=run_id, rerun_all_failed_tasks=True)
# For subsequent repairs, chain repair_id:
repair2 = w.jobs.repair_run(run_id=run_id, rerun_all_failed_tasks=True, latest_repair_id=repair.repair_id)
```

### Run subset of tasks
```python
w.jobs.run_now(job_id=11223344, only=["task_a", "task_b"])
```

### Idempotent run trigger
```python
run = w.jobs.run_now(job_id=11223344, idempotency_token="batch-2024-01-15")
# If a run with this token already exists, returns existing run_id (no duplicate created)
```

### Check run output after completion
```python
run = w.jobs.run_now(job_id=11223344).result()  # wait for completion
for task in run.tasks:
    output = w.jobs.get_run_output(run_id=task.run_id)
    if output.error:
        print(f"Task {task.task_key} failed: {output.error}")
    elif output.notebook_output:
        print(f"Task {task.task_key} result: {output.notebook_output.result}")
```

### Enforce policy compliance with dry-run
```python
preview = w.policy_compliance_for_jobs.enforce_compliance(job_id=11223344, validate_only=True)
if preview.has_changes:
    for change in preview.job_cluster_changes:
        print(f"  {change.field}: {change.previous_value} -> {change.new_value}")
    # Apply if changes look good
    w.policy_compliance_for_jobs.enforce_compliance(job_id=11223344)
```

---

## Run Lifecycle States

State flow: `BLOCKED -> QUEUED -> PENDING -> RUNNING -> TERMINATING -> TERMINATED`
Terminal states: `TERMINATED`, `SKIPPED`, `INTERNAL_ERROR`
`status.termination_details.type`: SUCCESS | FAILED | TIMED_OUT | CANCELED
`status.termination_details.code`: SUCCESS | CANCELED | SKIPPED | INTERNAL_ERROR | LIBRARY_INSTALLATION_ERROR | ...

Note: The `state` field (deprecated) uses `life_cycle_state` + `result_state`. Prefer `status` which has a unified `state` enum.

## Common Errors

| Code | error_code | Meaning |
|------|-----------|---------|
| 400 | INVALID_PARAMETER_VALUE | Bad input (wrong type, missing required field) |
| 401 | UNAUTHORIZED | Invalid or expired credentials |
| 403 | PERMISSION_DENIED | Insufficient permissions for operation |
| 404 | RESOURCE_DOES_NOT_EXIST | Job or run not found |
| 429 | REQUEST_LIMIT_EXCEEDED | Rate limited -- back off and retry |
| 500 | INTERNAL_SERVER_ERROR | Server-side error |

## Gotchas

- **reset vs update**: `reset()` replaces ALL settings (unset fields revert to defaults); `update()` merges top-level fields and merges array entries by key (`task_key`, `job_cluster_key`). Use `fields_to_remove` in update to delete specific fields (supports `tasks/task_key`, `job_clusters/key`).
- **run_now vs submit**: `run_now` = saved job (visible in UI, retries work, serverless auto-optimization). `submit` = one-time run (no UI, no retries, no auto-optimization). For production workloads, prefer create + run_now.
- **repair semantics**: Re-runs tasks within the ORIGINAL run using CURRENT job settings (not the settings at original run time). Must pass `latest_repair_id` from the previous repair for sequential repairs. Run must not be in progress. Only one of `rerun_tasks` or `rerun_all_failed_tasks` can be set.
- **cancel is async**: The run may still be executing after `cancel_run()` returns. Poll `get_run()` to confirm terminal state.
- **delete_run**: Only works for non-active runs. Cancel first, wait for termination, then delete.
- **pagination**: SDK auto-paginates `list()` and `list_runs()`. For `get()`/`get_run()`, arrays with >100 items require manual `page_token` handling.
- **output limits**: `get_run_output()` returns max 5 MB of output. For larger results, use cloud storage.
- **run expiry**: Runs are auto-deleted after 60 days. Save results before expiry.
- **permissions job_id is string**: Permissions methods take `job_id` as string, not int.
- **timeout_seconds**: Changes apply to active runs immediately. All other setting changes apply only to future runs.
- **SDK client paths**: Jobs = `w.jobs`, Policy compliance = `w.policy_compliance_for_jobs`.
- **max_concurrent_runs**: Setting to 0 causes all new runs to be skipped. Default is 1. Max is 1000.
- **idempotency_token**: Max 64 chars. If a run with the same token exists, returns existing run_id. If the token's run was deleted, returns an error.
