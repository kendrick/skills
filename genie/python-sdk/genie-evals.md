# Genie Evaluations — Databricks Python SDK

> Raw docs: ../docs/raw/ — for full endpoint details, read genie-{operation}.md
> Package: `databricks-sdk`

**Beta API** -- benchmark evaluation runs and results for Genie spaces.

## Setup

```python
from databricks.sdk import WorkspaceClient
w = WorkspaceClient()  # uses DATABRICKS_HOST + auth from env/profile
```

## SDK Client Map

All eval operations live under `w.genie`:

| SDK Method | REST Equivalent |
|-----------|----------------|
| `w.genie.genie_create_eval_run()` | POST `.../eval-runs` |
| `w.genie.genie_get_eval_run()` | GET `.../eval-runs/{eval_run_id}` |
| `w.genie.genie_list_eval_runs()` | GET `.../eval-runs` |
| `w.genie.genie_list_eval_results()` | GET `.../eval-runs/{eval_run_id}/results` |
| `w.genie.genie_get_eval_result_details()` | GET `.../eval-runs/{eval_run_id}/results/{result_id}` |

---

## 1. Eval Runs

### Create Eval Run

```python
run = w.genie.genie_create_eval_run(
    space_id="<space-uuid>",
    benchmark_question_ids=["q1-uuid", "q2-uuid"]  # optional; omit for all questions
)
print(run.eval_run_id, run.eval_run_status)
```

### Get Eval Run

```python
run = w.genie.genie_get_eval_run(
    space_id="<space-uuid>",
    eval_run_id="<run-uuid>"
)
```

### List Eval Runs

```python
for page in w.genie.genie_list_eval_runs(space_id="<space-uuid>"):
    for run in page.eval_runs:
        print(run.eval_run_id, run.eval_run_status)
```

---

## 2. Eval Results

### List Results for a Run

```python
for page in w.genie.genie_list_eval_results(
    space_id="<space-uuid>",
    eval_run_id="<run-uuid>"
):
    for r in page.eval_results:
        print(r.result_id, r.question, r.status)
```

### Get Result Details

```python
details = w.genie.genie_get_eval_result_details(
    space_id="<space-uuid>",
    eval_run_id="<run-uuid>",
    result_id="<result-uuid>"
)
print(details.assessment)           # GOOD | BAD | NEEDS_REVIEW
print(details.assessment_reasons)   # e.g. ["RESULT_MISSING_ROWS"]
print(details.actual_response)      # list of {response, response_type, sql_execution_result}
print(details.expected_response)    # benchmark ground truth
```

---

## Common Patterns

### Poll for Eval Run Completion

```python
import time

run = w.genie.genie_create_eval_run(space_id="<space-uuid>")
terminal = {"DONE", "EVALUATION_FAILED", "EVALUATION_CANCELLED", "EVALUATION_TIMEOUT"}

while run.eval_run_status not in terminal:
    time.sleep(10)
    run = w.genie.genie_get_eval_run(
        space_id="<space-uuid>",
        eval_run_id=run.eval_run_id
    )

print(f"Finished: {run.eval_run_status} -- {run.num_correct}/{run.num_questions} correct")
```

### Collect All BAD Results

```python
for page in w.genie.genie_list_eval_results(space_id=sid, eval_run_id=rid):
    for r in page.eval_results:
        d = w.genie.genie_get_eval_result_details(
            space_id=sid, eval_run_id=rid, result_id=r.result_id
        )
        if d.assessment == "BAD":
            print(r.question, d.assessment_reasons)
```

---

## Gotchas

- **Beta API**: Methods/fields may change in future SDK versions.
- **Async execution**: `genie_create_eval_run` returns immediately with status RUNNING. You must poll.
- **Omit `benchmark_question_ids`** (or pass `None`) to evaluate all benchmark questions. Empty list is not equivalent.
- **FEATURE_DISABLED**: Raises `NotFound` (404) if evals are not enabled on the workspace -- not `PermissionDenied`.
- **Pagination**: List methods return paginated responses. Default page size is 20, max 100.
- **Assessment reasons**: Only populated for BAD results. Includes both deterministic (RESULT_MISSING_ROWS, etc.) and LLM judge reasons (LLM_JUDGE_MISSING_OR_INCORRECT_FILTER, LLM_JUDGE_INCORRECT_METRIC_CALCULATION, LLM_JUDGE_FORMATTING_ERROR, etc.). Older names like `LLM_JUDGE_WRONG_FILTER` / `LLM_JUDGE_WRONG_AGGREGATION` / `LLM_JUDGE_WRONG_COLUMNS` are deprecated but still emitted for back-compat.
