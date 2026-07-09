# Serving Endpoints — Databricks Model Serving REST API

Create, configure, query, and manage model serving endpoints — including AI Gateway, provisioned throughput, permissions, logs, and metrics.

> Raw docs: ../docs/raw/ — for full endpoint details, read servingendpoints-{operation}.md

## Auth

All endpoints require Bearer token auth and API scope `model-serving`.

```
Authorization: Bearer <token>
Host: <workspace>.cloud.databricks.com
```

## Endpoint Summary

| Method | Path | Purpose |
|--------|------|---------|
| POST | /api/2.0/serving-endpoints | Create endpoint |
| GET | /api/2.0/serving-endpoints | List all endpoints |
| GET | /api/2.0/serving-endpoints/{name} | Get endpoint |
| DELETE | /api/2.0/serving-endpoints/{name} | Delete endpoint |
| PUT | /api/2.0/serving-endpoints/{name}/config | Update served entities/traffic config |
| PUT | /api/2.0/serving-endpoints/{name}/rate-limits | Update rate limits (DEPRECATED) |
| PUT | /api/2.0/serving-endpoints/{name}/ai-gateway | Update AI Gateway config |
| PATCH | /api/2.0/serving-endpoints/{name}/tags | Add/delete tags |
| PATCH | /api/2.0/serving-endpoints/{name}/notifications | Update email notifications |
| POST | /api/2.0/serving-endpoints/pt | Create provisioned throughput endpoint |
| PUT | /api/2.0/serving-endpoints/pt/{name}/config | Update PT endpoint config |
| POST | /serving-endpoints/{name}/invocations | Query endpoint |
| GET | /api/2.0/serving-endpoints/{name}/openapi | Get OpenAPI schema |
| GET | /api/2.0/serving-endpoints/{name}/metrics | Export Prometheus metrics |
| GET | /api/2.0/serving-endpoints/{name}/served-models/{model}/build-logs | Build logs |
| GET | /api/2.0/serving-endpoints/{name}/served-models/{model}/logs | Service logs |
| GET | /api/2.0/permissions/serving-endpoints/{id} | Get permissions |
| PUT | /api/2.0/permissions/serving-endpoints/{id} | Set permissions (replace) |
| PATCH | /api/2.0/permissions/serving-endpoints/{id} | Update permissions (merge) |
| GET | /api/2.0/permissions/serving-endpoints/{id}/permissionLevels | Get permission levels |

---

## 1. Endpoint CRUD

### Create Endpoint
```
POST /api/2.0/serving-endpoints
```
```json
{
  "name": "my-endpoint",
  "config": {
    "served_entities": [{
      "entity_name": "catalog.schema.model",
      "entity_version": "1",
      "scale_to_zero_enabled": true,
      "workload_size": "Small"
    }]
  }
}
```
- **Required**: `name` (string, unique, alphanumeric/dash/underscore)
- **Optional**: `config.served_entities[]`, `config.traffic_config`, `ai_gateway`, `tags[]`, `description`, `email_notifications`, `route_optimized`, `budget_policy_id`
- **Response**: Full endpoint object with `state.ready` (READY|NOT_READY), `state.config_update`
- **Permission**: Workspace user
- **Errors**: 400 BAD_REQUEST, 401 UNAUTHENTICATED, 500

### List Endpoints
```
GET /api/2.0/serving-endpoints
```
Response: `{"endpoints": [...]}` -- returns summary objects (no full config detail).

### Get Endpoint
```
GET /api/2.0/serving-endpoints/{name}
```
Returns full endpoint object including `config`, `pending_config`, `state`, `ai_gateway`.

### Delete Endpoint
```
DELETE /api/2.0/serving-endpoints/{name}
```
Permission: CAN_MANAGE. Errors: 401, 404 NOT_FOUND, 500.

---

## 2. Configuration

### Update Config
```
PUT /api/2.0/serving-endpoints/{name}/config
```
```json
{
  "served_entities": [{
    "entity_name": "catalog.schema.model",
    "entity_version": "2",
    "scale_to_zero_enabled": true,
    "workload_size": "Small"
  }],
  "traffic_config": {
    "routes": [{"served_entity_name": "catalog.schema.model-2", "traffic_percentage": 100}]
  }
}
```
- **Optional fields per entity**: `entity_name`, `entity_version`, `environment_vars`, `external_model`, `workload_size` (Small/Medium/Large), `workload_type` (CPU/GPU_SMALL/etc), `scale_to_zero_enabled`, `min/max_provisioned_throughput`, `burst_scaling_enabled`
- Cannot update while another update is IN_PROGRESS. Errors: 400, 401, 409 RESOURCE_CONFLICT, 500.

### Update AI Gateway
```
PUT /api/2.0/serving-endpoints/{name}/ai-gateway
```
```json
{
  "rate_limits": [{"calls": 100, "renewal_period": "minute", "key": "user"}],
  "usage_tracking_config": {"enabled": true},
  "inference_table_config": {"catalog_name": "cat", "schema_name": "sch", "enabled": true},
  "guardrails": {"input": {"safety": true}, "output": {"safety": true}},
  "fallback_config": {"enabled": true}
}
```
- Rate limit keys: `user`, `endpoint`, `user_group`, `service_principal`. Period: `minute` only.
- Supports `tokens` and `calls` limits; `principal` field for per-user/group targeting.
- Fully supported for external model, PT, and pay-per-token endpoints; agents only support inference tables.

### Update Rate Limits (DEPRECATED -- use AI Gateway)
```
PUT /api/2.0/serving-endpoints/{name}/rate-limits
```
```json
{"rate_limits": [{"calls": 15, "key": "user", "renewal_period": "minute"}]}
```

### Update Tags
```
PATCH /api/2.0/serving-endpoints/{name}/tags
```
```json
{"add_tags": [{"key": "team", "value": "ml"}], "delete_tags": ["old-key"]}
```

### Update Notifications
```
PATCH /api/2.0/serving-endpoints/{name}/notifications
```
```json
{"email_notifications": {"on_update_failure": ["user@co.com"], "on_update_success": ["user@co.com"]}}
```

---

## 3. Provisioned Throughput

### Create PT Endpoint
```
POST /api/2.0/serving-endpoints/pt
```
Same shape as standard create but with `provisioned_model_units` on served entities.

### Update PT Config
```
PUT /api/2.0/serving-endpoints/pt/{name}/config
```
```json
{
  "config": {
    "served_entities": [{"entity_name": "model", "entity_version": "3", "provisioned_model_units": 1000}],
    "traffic_config": {"routes": [{"served_entity_name": "model-3", "traffic_percentage": 100}]}
  }
}
```
Updates are instantaneous (no rollout delay). Errors: 400, 404, 409 RESOURCE_CONFLICT.

---

## 4. Query

```
POST /serving-endpoints/{name}/invocations
```

**Chat/completions** (external/foundation models):
```json
{"messages": [{"role": "user", "content": "Hello"}], "max_tokens": 100, "temperature": 0.5}
```

**Dataframe input** (custom models):
```json
{"dataframe_split": {"columns": ["col1", "col2"], "data": [[1, 2]]}}
```

**Embeddings**: `{"input": "text to embed"}`

- Optional: `stream` (bool), `stop` (array), `n`, `extra_params`, `client_request_id`, `usage_context`
- Response header `served-model-name` indicates which model handled the request.
- Permission: CAN_QUERY. Errors: 401, 403 PERMISSION_DENIED, 404 RESOURCE_DOES_NOT_EXIST, 500.

---

## 5. Observability

### Export Metrics
```
GET /api/2.0/serving-endpoints/{name}/metrics
```
Returns Prometheus/OpenMetrics format. Errors: 400, 404.

### Get OpenAPI Schema
```
GET /api/2.0/serving-endpoints/{name}/openapi
```
Returns OpenAPI spec for the endpoint's query schema.

### Build Logs
```
GET /api/2.0/serving-endpoints/{name}/served-models/{served_model_name}/build-logs
```
Returns `{"logs": "..."}` -- environment build output.

### Service Logs
```
GET /api/2.0/serving-endpoints/{name}/served-models/{served_model_name}/logs
```
Returns `{"logs": "..."}` -- recent inference server logs.

---

## 6. Permissions

Permission levels: `CAN_MANAGE`, `CAN_QUERY`, `CAN_VIEW`. Uses endpoint **id** (not name).

### Get Permissions
```
GET /api/2.0/permissions/serving-endpoints/{serving_endpoint_id}
```

### Set Permissions (replace all)
```
PUT /api/2.0/permissions/serving-endpoints/{serving_endpoint_id}
```
```json
{"access_control_list": [{"user_name": "user@co.com", "permission_level": "CAN_QUERY"}]}
```

### Update Permissions (merge)
```
PATCH /api/2.0/permissions/serving-endpoints/{serving_endpoint_id}
```
Same body as set; merges with existing rather than replacing.

### Get Permission Levels
```
GET /api/2.0/permissions/serving-endpoints/{serving_endpoint_id}/permissionLevels
```
Returns available levels: CAN_MANAGE, CAN_QUERY, CAN_VIEW.

ACL entries accept one of: `user_name`, `group_name`, `service_principal_name`.

---

## Common Errors

| Code | Error | Meaning |
|------|-------|---------|
| 400 | BAD_REQUEST | Invalid payload or param |
| 401 | UNAUTHENTICATED | Missing/bad credentials |
| 403 | PERMISSION_DENIED | Insufficient permissions (query needs CAN_QUERY) |
| 404 | NOT_FOUND | Endpoint or model does not exist |
| 409 | RESOURCE_CONFLICT | Config update already in progress |
| 500 | INTERNAL_ERROR | Server-side failure |

## Gotchas

- **Async creation**: POST create returns immediately; endpoint is NOT_READY until entities deploy. Poll GET until `state.ready == "READY"`.
- **Config update blocking**: Cannot issue a new config update while `state.config_update == "IN_PROGRESS"`. Wait for completion or failure first.
- **Served entity states**: Each entity has `state.deployment` (DEPLOYMENT_CREATING, DEPLOYMENT_READY, etc). Endpoint is READY only when all active entities are ready.
- **`served_models` is deprecated** -- use `served_entities` everywhere.
- **`auto_capture_config` is deprecated** for PT endpoints -- use AI Gateway `inference_table_config` instead.
- **Rate limits at top level are deprecated** -- use `ai_gateway.rate_limits`.
- **Query path differs**: Query uses `/serving-endpoints/` (no `/api/2.0/` prefix).
- **Permissions use endpoint ID** (UUID from `id` field), not the endpoint name.
- **AI Gateway on agents**: Only inference tables are supported for agent endpoints; guardrails and rate limits are not.
- **Inference table catalog/schema change**: Must disable inference table first, then re-enable with new catalog/schema.
- **PT config updates are instant**; standard endpoint config updates roll out gradually.
