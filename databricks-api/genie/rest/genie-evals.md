# Genie Evaluations — Databricks Genie REST API

Benchmark evaluation runs, results, and result details for Genie spaces. **Beta API.**

> See also: genie-spaces-conversations (for the spaces/conversations these evals test)
> Raw docs: ../_docs/raw/ — for full endpoint details, read genie-{operation}.md

## Auth

All endpoints require OAuth scope `genie`. Standard bearer-token auth via `Authorization: Bearer <token>`.

## Endpoint Summary

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/api/2.0/genie/spaces/{space_id}/eval-runs` | Create eval run |
| GET | `/api/2.0/genie/spaces/{space_id}/eval-runs/{eval_run_id}` | Get eval run |
| GET | `/api/2.0/genie/spaces/{space_id}/eval-runs` | List eval runs |
| GET | `/api/2.0/genie/spaces/{space_id}/eval-runs/{eval_run_id}/results` | List eval results |
| GET | `/api/2.0/genie/spaces/{space_id}/eval-runs/{eval_run_id}/results/{result_id}` | Get result details |

---

## 1. Eval Runs

### Create Eval Run

`POST /api/2.0/genie/spaces/{space_id}/eval-runs`

- **Path**: `space_id` (uuid, required)
- **Body**: `benchmark_question_ids` (string[], optional -- omit to evaluate all benchmark questions; passing an empty array is not the same)

```json
POST /api/2.0/genie/spaces/abc123/eval-runs
{"benchmark_question_ids": ["q1-uuid", "q2-uuid"]}
```

**Response 200**: `eval_run_id`, `eval_run_status` (RUNNING|DONE|NOT_STARTED|EVALUATION_FAILED|EVALUATION_CANCELLED|EVALUATION_TIMEOUT), `num_questions`, `num_done`, `num_correct`, `num_needs_review`, `created_timestamp`, `last_updated_timestamp`, `run_by_user`.

### Get Eval Run

`GET /api/2.0/genie/spaces/{space_id}/eval-runs/{eval_run_id}`

- **Path**: `space_id` (uuid, required), `eval_run_id` (uuid, required)

**Response 200**: Same shape as create response.

### List Eval Runs

`GET /api/2.0/genie/spaces/{space_id}/eval-runs`

- **Path**: `space_id` (uuid, required)
- **Query**: `page_size` (int32, optional, default 20, max 100), `page_token` (string, optional)

**Response 200**: `eval_runs[]` (same run objects), `next_page_token`.

---

## 2. Eval Results

### List Eval Results

`GET /api/2.0/genie/spaces/{space_id}/eval-runs/{eval_run_id}/results`

- **Path**: `space_id` (uuid, required), `eval_run_id` (uuid, required)
- **Query**: `page_size` (int32, optional, default 20, max 100), `page_token` (string, optional)

**Response 200**: `eval_results[]` with `result_id`, `benchmark_question_id`, `question`, `benchmark_answer`, `status`, `created_by_user`, `space_id`. Plus `next_page_token`.

### Get Eval Result Details

`GET /api/2.0/genie/spaces/{space_id}/eval-runs/{eval_run_id}/results/{result_id}`

- **Path**: `space_id`, `eval_run_id`, `result_id` (all uuid, required)

**Response 200**: `actual_response[]` (response, response_type TEXT|SQL, sql_execution_result), `expected_response[]` (same shape), `assessment` (GOOD|BAD|NEEDS_REVIEW), `assessment_reasons[]`, `manual_assessment` (bool), `eval_run_status`, `benchmark_question_id`, `result_id`, `space_id`.

Assessment reasons include deterministic checks (EMPTY_RESULT, RESULT_MISSING_ROWS, RESULT_EXTRA_ROWS, RESULT_MISSING_COLUMNS, RESULT_EXTRA_COLUMNS, SINGLE_CELL_DIFFERENCE, EMPTY_GOOD_SQL, COLUMN_TYPE_DIFFERENCE) and LLM judge reasons (LLM_JUDGE_MISSING_OR_INCORRECT_FILTER, LLM_JUDGE_MISSING_OR_INCORRECT_JOIN, LLM_JUDGE_MISSING_OR_INCORRECT_AGGREGATION, LLM_JUDGE_INCORRECT_METRIC_CALCULATION, LLM_JUDGE_INCORRECT_TABLE_OR_FIELD_USAGE, LLM_JUDGE_FORMATTING_ERROR, LLM_JUDGE_OTHER, etc.). Older reasons like `LLM_JUDGE_WRONG_FILTER`, `LLM_JUDGE_WRONG_AGGREGATION`, `LLM_JUDGE_WRONG_COLUMNS`, `LLM_JUDGE_MISSING_JOIN`, `LLM_JUDGE_SYNTAX_ERROR`, and `LLM_JUDGE_SEMANTIC_ERROR` are deprecated -- still emitted for backward compatibility, don't use in new code.

---

## Common Errors

| HTTP | error_code | Cause |
|------|------------|-------|
| 400 | BAD_REQUEST | Invalid request (bad UUIDs, invalid params) |
| 401 | UNAUTHORIZED | Missing/invalid auth credentials |
| 403 | PERMISSION_DENIED | Caller lacks permission on the space |
| 404 | NOT_FOUND | Space, run, or result does not exist |
| 404 | FEATURE_DISABLED | Evals feature not enabled for this workspace |
| 500 | INTERNAL_ERROR | Server-side error |

## Gotchas

- **Beta API**: Endpoints may change without notice.
- **Eval runs are async**: After POST create, poll GET eval-run until `eval_run_status` is `DONE` (or a terminal state).
- **Terminal statuses**: DONE, EVALUATION_FAILED, EVALUATION_CANCELLED, EVALUATION_TIMEOUT. Only RUNNING and NOT_STARTED are non-terminal.
- **404 FEATURE_DISABLED**: If evals are not enabled on your workspace, you get 404 with FEATURE_DISABLED, not 403.
