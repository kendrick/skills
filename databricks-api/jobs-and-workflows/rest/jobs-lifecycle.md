# Jobs & Workflows -- Databricks Jobs REST API

Job CRUD, trigger runs, manage run lifecycle, permissions, and policy compliance.

> Raw docs: ../docs/raw/ -- for full endpoint details, read {service}-{operation}.md

## Auth

All endpoints require Bearer token or Databricks PAT.
Header: `Authorization: Bearer <token>`
Base URL: `https://<workspace>.cloud.databricks.com`
API scope: `jobs`
Content-Type: `application/json` for POST/PUT/PATCH requests

## Endpoint Summary

| Method | Path | Purpose |
|--------|------|---------|
| POST | /api/2.2/jobs/create | Create a new job |
| GET | /api/2.2/jobs/get | Get single job by ID |
| GET | /api/2.2/jobs/list | List all jobs (paginated) |
| POST | /api/2.2/jobs/update | Partial update of job settings |
| POST | /api/2.2/jobs/reset | Full replace of job settings |
| POST | /api/2.2/jobs/delete | Delete a job |
| POST | /api/2.2/jobs/run-now | Trigger run of existing job |
| POST | /api/2.2/jobs/runs/submit | One-time run (no saved job) |
| GET | /api/2.2/jobs/runs/get | Get run metadata |
| GET | /api/2.2/jobs/runs/list | List runs (paginated) |
| GET | /api/2.2/jobs/runs/get-output | Get task run output |
| GET | /api/2.2/jobs/runs/export | Export run as HTML |
| POST | /api/2.2/jobs/runs/cancel | Cancel a run (async) |
| POST | /api/2.2/jobs/runs/cancel-all | Cancel all runs of a job |
| POST | /api/2.2/jobs/runs/delete | Delete a non-active run |
| POST | /api/2.2/jobs/runs/repair | Re-run failed/specific tasks |
| GET | /api/2.0/permissions/jobs/{job_id} | Get job permissions |
| PUT | /api/2.0/permissions/jobs/{job_id} | Set (replace) permissions |
| PATCH | /api/2.0/permissions/jobs/{job_id} | Update (merge) permissions |
| GET | /api/2.0/permissions/jobs/{job_id}/permissionLevels | Get available permission levels |
| POST | /api/2.0/policies/jobs/enforce-compliance | Enforce policy compliance |
| GET | /api/2.0/policies/jobs/get-compliance | Get compliance status |
| GET | /api/2.0/policies/jobs/list-compliance | List compliance for multiple jobs |

---

## 1. Job CRUD

### Create Job
```
POST /api/2.2/jobs/create
{
  "name": "my-etl-pipeline",
  "tasks": [{
    "task_key": "extract",
    "notebook_task": {"notebook_path": "/etl/extract"},
    "existing_cluster_id": "0923-164208-meows279"
  }, {
    "task_key": "transform",
    "depends_on": [{"task_key": "extract"}],
    "notebook_task": {"notebook_path": "/etl/transform"},
    "job_cluster_key": "shared_cluster"
  }],
  "job_clusters": [{"job_cluster_key": "shared_cluster", "new_cluster": {
    "spark_version": "14.3.x-scala2.12", "num_workers": 4, "node_type_id": "i3.xlarge"
  }}],
  "schedule": {"quartz_cron_expression": "0 0 8 * * ?", "timezone_id": "US/Eastern"},
  "max_concurrent_runs": 1,
  "tags": {"team": "data-eng"}
}
```
Required: `tasks` (each needs `task_key` + one task type). Task types: `notebook_task`, `spark_jar_task`, `spark_python_task`, `python_wheel_task`, `sql_task`, `dbt_task`, `pipeline_task`, `run_job_task`, `condition_task`, `for_each_task`, `dashboard_task`, `alert_task`.
Optional: `name` (max 4096 chars), `schedule`, `continuous` (mutually exclusive with schedule), `trigger` (file_arrival, table_update, periodic), `job_clusters` (max 100), `tags` (max 25), `max_concurrent_runs` (default 1, max 1000, 0=skip all), `run_as`, `health`, `queue`, `timeout_seconds` (0=none), `email_notifications`, `webhook_notifications`, `environments` (max 10, for serverless), `git_source`, `parameters`, `budget_policy_id`, `performance_target` (PERFORMANCE_OPTIMIZED|STANDARD).
Response: `{"job_id": 11223344}`. Permission: CAN_MANAGE on workspace or IS_OWNER.

### Get Job
```
GET /api/2.2/jobs/get?job_id=11223344
```
Required: `job_id` (int64). Optional: `page_token` (arrays >100 items are paginated). Permission: CAN_VIEW.

### List Jobs
```
GET /api/2.2/jobs/list?limit=25&name=etl&expand_tasks=false
```
Optional: `limit` (default 20, max 25), `name` (substring filter), `page_token`, `expand_tasks` (default false; when true, only first 100 tasks returned -- use get for pagination). Returns `jobs[]` with `job_id`, `settings`, `created_time`, `creator_user_name`; plus `next_page_token`, `has_more`.

### Update Job (Partial)
```
POST /api/2.2/jobs/update
{"job_id": 11223344, "new_settings": {"name": "new-name"}, "fields_to_remove": ["schedule"]}
```
Required: `job_id`. Top-level fields in `new_settings` are replaced; arrays (tasks, job_clusters) are merged by key. Use `fields_to_remove` to delete fields (supports `tasks/task_key`, `job_clusters/key`). Permission: CAN_MANAGE.

### Reset Job (Full Replace)
```
POST /api/2.2/jobs/reset
{"job_id": 11223344, "new_settings": {<complete settings>}}
```
Required: `job_id`, `new_settings`. Overwrites ALL settings. Unspecified fields revert to defaults. Permission: CAN_MANAGE.

### Delete Job
```
POST /api/2.2/jobs/delete
{"job_id": 11223344}
```
Required: `job_id`. Permission: CAN_MANAGE.

---

## 2. Triggering Runs

### Run Now (existing job)
```
POST /api/2.2/jobs/run-now
{"job_id": 11223344, "job_parameters": {"key": "val"}, "idempotency_token": "uuid"}
```
Required: `job_id`. Optional: `job_parameters`, `idempotency_token` (<=64 chars), `only` (task keys subset), `queue`, `pipeline_params`, `performance_target`. Response: `{"run_id": 455644833}`. Permission: CAN_MANAGE_RUN.

### Submit (one-time, no saved job)
```
POST /api/2.2/jobs/runs/submit
{"run_name": "one-off", "tasks": [{"task_key": "t1", "notebook_task": {"notebook_path": "/path"}, "new_cluster": {...}}]}
```
Required: `tasks`. Optional: `run_name`, `idempotency_token`, `run_as`, `access_control_list`, `git_source`, `queue`, `timeout_seconds`. Response: `{"run_id": 455644833}`.
**Warning**: Submit runs do NOT appear in Jobs UI, do NOT retry on failure, and cannot be auto-optimized for serverless.

---

## 3. Run Management

### Get Run
```
GET /api/2.2/jobs/runs/get?run_id=455644833&include_history=true&include_resolved_values=true
```
Required: `run_id` (int64). Optional: `include_history` (default false, includes repair_history), `include_resolved_values` (default false), `page_token`. Arrays >100 elements paginated.
Response includes: `run_id`, `job_id`, `status` (state, termination_details), `tasks[]`, `start_time`, `end_time`, `run_duration`, `run_type` (JOB_RUN|WORKFLOW_RUN|SUBMIT_RUN), `trigger` (PERIODIC|ONE_TIME|RETRY|FILE_ARRIVAL|TABLE|CONTINUOUS), `repair_history[]`, `run_page_url`.

### List Runs
```
GET /api/2.2/jobs/runs/list?job_id=11223344&active_only=true&limit=25
```
Optional: `job_id` (omit to list all jobs' runs), `active_only` (QUEUED/PENDING/RUNNING/TERMINATING), `completed_only` (mutually exclusive with active_only), `run_type` (JOB_RUN|WORKFLOW_RUN|SUBMIT_RUN), `limit` (1-25, default 20), `expand_tasks`, `start_time_from`/`start_time_to` (epoch ms), `page_token`. Returns `runs[]` sorted by start_time desc, `next_page_token`, `prev_page_token`.

### Get Run Output
```
GET /api/2.2/jobs/runs/get-output?run_id=455644833
```
Required: `run_id`. Returns `notebook_output.result` (from `dbutils.notebook.exit()`), `logs`, `error`, `error_trace`. **Limit**: first 5 MB of output. Runs expire after 60 days.

### Export Run
```
GET /api/2.2/jobs/runs/export?run_id=455644833&views_to_export=CODE
```
Required: `run_id`. Optional: `views_to_export` (CODE|DASHBOARDS|ALL, default CODE). Returns HTML views.

### Cancel Run
```
POST /api/2.2/jobs/runs/cancel
{"run_id": 455644833}
```
Async -- run may still be executing when response returns. Permission: CAN_MANAGE_RUN.

### Cancel All Runs
```
POST /api/2.2/jobs/runs/cancel-all
{"job_id": 11223344}
```
Required: `job_id`. Cancels all active runs for the job. Permission: CAN_MANAGE.

### Delete Run
```
POST /api/2.2/jobs/runs/delete
{"run_id": 455644833}
```
Run must be non-active (completed/cancelled). Returns error if run is still active.

### Repair Run
```
POST /api/2.2/jobs/runs/repair
{"run_id": 455644833, "rerun_all_failed_tasks": true, "latest_repair_id": 734650698524280}
```
Required: `run_id`. Optional: `rerun_tasks` (task key list), `rerun_all_failed_tasks`, `rerun_dependent_tasks`, `latest_repair_id` (required for 2nd+ repair), `job_parameters`. Response: `{"repair_id": 734650698524280}`.
Tasks re-run as part of the original run with CURRENT job settings. Only one of `rerun_tasks` or `rerun_all_failed_tasks`.

---

## 4. Permissions

Levels: `CAN_VIEW`, `CAN_MANAGE_RUN`, `CAN_MANAGE`, `IS_OWNER`

### Get Permissions
```
GET /api/2.0/permissions/jobs/{job_id}
```
Returns `access_control_list[]` with `user_name`/`group_name`/`service_principal_name`, `all_permissions[]` (includes `inherited`, `inherited_from_object[]`, `permission_level`), plus `object_id` and `object_type`.

### Set Permissions (full replace)
```
PUT /api/2.0/permissions/jobs/{job_id}
{"access_control_list": [
  {"user_name": "user@co.com", "permission_level": "CAN_MANAGE"},
  {"group_name": "readers", "permission_level": "CAN_VIEW"},
  {"service_principal_name": "692bc6d0-...", "permission_level": "IS_OWNER"}
]}
```
Replaces all direct permissions. Omitting ACL deletes all direct permissions. Jobs can still inherit permissions from root object.

### Update Permissions (additive)
```
PATCH /api/2.0/permissions/jobs/{job_id}
{"access_control_list": [{"group_name": "data-eng", "permission_level": "CAN_MANAGE_RUN"}]}
```
Adds/updates listed entries without affecting other existing permissions.

### Get Permission Levels
```
GET /api/2.0/permissions/jobs/{job_id}/permissionLevels
```
Returns `permission_levels[]` with `permission_level` and `description`. Available levels: CAN_VIEW, CAN_MANAGE_RUN, CAN_MANAGE, IS_OWNER.

---

## 5. Policy Compliance

### Enforce Compliance
```
POST /api/2.0/policies/jobs/enforce-compliance
{"job_id": 11223344, "validate_only": true}
```
Updates job clusters' `new_cluster` to match current cluster policies. Set `validate_only: true` to preview changes. Response includes `has_changes`, `job_cluster_changes[]`, and updated `settings`.

### Get Compliance
```
GET /api/2.0/policies/jobs/get-compliance?job_id=11223344
```
Response: `{"is_compliant": true, "violations": {...}}`. Violations map paths to error messages.

### List Compliance
```
GET /api/2.0/policies/jobs/list-compliance?policy_id=<id>&page_token=...
```
Required: `policy_id`. Returns compliance status for all jobs using that policy. Paginated with `page_token`/`next_page_token`. Each item includes `job_id`, `is_compliant`, `violations`.

---

## Run Lifecycle States

State flow: `BLOCKED -> QUEUED -> PENDING -> RUNNING -> TERMINATING -> TERMINATED`
Terminal states: `TERMINATED`, `SKIPPED`, `INTERNAL_ERROR`
`status.termination_details.type`: SUCCESS | FAILED | TIMED_OUT | CANCELED
`status.termination_details.code`: SUCCESS | CANCELED | SKIPPED | INTERNAL_ERROR | LIBRARY_INSTALLATION_ERROR | ...
`status.queue_details.code`: ACTIVE_RUNS_LIMIT_REACHED | ...

Note: The `state` field (deprecated) uses `life_cycle_state` + `result_state`. Prefer `status` field which uses a unified `state` enum.

## Common Errors

| Code | error_code | Meaning |
|------|-----------|---------|
| 400 | INVALID_PARAMETER_VALUE | Bad input |
| 401 | UNAUTHORIZED | Invalid credentials |
| 403 | PERMISSION_DENIED | Insufficient permissions |
| 404 | RESOURCE_DOES_NOT_EXIST | Job/run not found |
| 429 | REQUEST_LIMIT_EXCEEDED | Rate limited |
| 500 | INTERNAL_SERVER_ERROR | Server error |

## Gotchas

- **reset vs update**: `reset` replaces ALL settings (unset fields revert to defaults); `update` merges top-level fields and merges array entries by key. Use `fields_to_remove` in update to delete specific fields.
- **run-now vs submit**: `run-now` triggers a saved job (appears in UI, retries work); `submit` creates a one-time run (no UI, no retries, no serverless auto-optimization).
- **repair semantics**: Repair re-runs tasks within the ORIGINAL run using CURRENT job settings. Must pass `latest_repair_id` from previous repair for sequential repairs. Run must not be in progress.
- **cancel is async**: The run may still be executing after cancel returns.
- **delete run**: Only works on non-active runs. Cancel first, then delete.
- **pagination**: Read endpoints (get, list) return max 100 array items (tasks, job_clusters). Use `page_token`/`next_page_token` for more. Write endpoints accept up to 1000 tasks.
- **output limits**: `get-output` returns max 5 MB. Store large results in cloud storage.
- **run expiry**: Runs are auto-deleted after 60 days.
- **idempotency_token**: Max 64 chars. If a run with the same token exists, returns existing run_id instead of creating a new one.
- **timeout_seconds changes**: Applied to active runs immediately. Other setting changes apply to future runs only.
- **permissions API version**: Permissions endpoints use `/api/2.0/`, not `/api/2.2/`.
