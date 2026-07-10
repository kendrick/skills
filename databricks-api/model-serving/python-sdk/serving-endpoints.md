# Serving Endpoints — Databricks Python SDK

Create, configure, query, and manage model serving endpoints — including AI Gateway, provisioned throughput, permissions, logs, and metrics.

> Raw docs: ../_docs/raw/ — for full endpoint details, read servingendpoints-{operation}.md
> Package: databricks-sdk

## Contents

- [Setup](#setup)
- [SDK Client Map](#sdk-client-map)
- [1. Endpoint CRUD](#1-endpoint-crud) — create, list, get, delete
- [2. Configuration](#2-configuration) — update config, AI Gateway, tags, notifications
- [3. Provisioned Throughput](#3-provisioned-throughput)
- [4. Query](#4-query) — chat/completions, dataframe, embeddings
- [5. Observability](#5-observability) — metrics, OpenAPI schema, logs
- [6. Permissions](#6-permissions)
- [Common Patterns](#common-patterns) — poll-until-ready, external models
- [Gotchas](#gotchas)

## Setup

```python
from databricks.sdk import WorkspaceClient
from databricks.sdk.service.serving import *

w = WorkspaceClient()  # uses DATABRICKS_HOST + DATABRICKS_TOKEN env vars
# All methods: w.serving_endpoints.<method>()
```

## SDK Client Map

| REST Operation | SDK Method |
|---------------|------------|
| POST /serving-endpoints | `w.serving_endpoints.create()` |
| GET /serving-endpoints | `w.serving_endpoints.list()` |
| GET /serving-endpoints/{name} | `w.serving_endpoints.get(name)` |
| DELETE /serving-endpoints/{name} | `w.serving_endpoints.delete(name)` |
| PUT .../config | `w.serving_endpoints.update_config(name, ...)` |
| PUT .../rate-limits | `w.serving_endpoints.put(name, ...)` (deprecated) |
| PUT .../ai-gateway | `w.serving_endpoints.put_ai_gateway(name, ...)` |
| PATCH .../tags | `w.serving_endpoints.patch(name, ...)` |
| PATCH .../notifications | `w.serving_endpoints.update_notifications(name, ...)` |
| POST /serving-endpoints/pt | `w.serving_endpoints.create_provisioned_throughput_endpoint(...)` |
| PUT .../pt/{name}/config | `w.serving_endpoints.update_provisioned_throughput_endpoint_config(name, ...)` |
| POST .../invocations | `w.serving_endpoints.query(name, ...)` |
| GET .../openapi | `w.serving_endpoints.get_open_api(name)` |
| GET .../metrics | `w.serving_endpoints.export_metrics(name)` |
| GET .../build-logs | `w.serving_endpoints.build_logs(name, served_model_name)` |
| GET .../logs | `w.serving_endpoints.logs(name, served_model_name)` |
| GET permissions | `w.serving_endpoints.get_permissions(serving_endpoint_id)` |
| PUT permissions | `w.serving_endpoints.set_permissions(serving_endpoint_id, ...)` |
| PATCH permissions | `w.serving_endpoints.update_permissions(serving_endpoint_id, ...)` |
| GET permissionLevels | `w.serving_endpoints.get_permission_levels(serving_endpoint_id)` |

---

## 1. Endpoint CRUD

### Create and Wait for Ready
```python
from databricks.sdk.service.serving import EndpointCoreConfigInput, ServedEntityInput

endpoint = w.serving_endpoints.create_and_wait(
    name="my-endpoint",
    config=EndpointCoreConfigInput(
        served_entities=[ServedEntityInput(
            entity_name="catalog.schema.model",
            entity_version="1",
            scale_to_zero_enabled=True,
            workload_size="Small",
        )]
    ),
)
print(endpoint.state.ready)  # READY
```

`create()` alone is async -- it returns immediately while the endpoint provisions; `create_and_wait()` blocks until READY.

### List
```python
endpoints = w.serving_endpoints.list()
for ep in endpoints:
    print(ep.name, ep.state.ready)
```

### Get
```python
ep = w.serving_endpoints.get(name="my-endpoint")
print(ep.state.config_update)  # NOT_UPDATING | IN_PROGRESS | UPDATE_FAILED
```

### Delete
```python
w.serving_endpoints.delete(name="my-endpoint")
```

---

## 2. Configuration

### Update Config and Wait
```python
updated = w.serving_endpoints.update_config_and_wait(
    name="my-endpoint",
    served_entities=[ServedEntityInput(
        entity_name="catalog.schema.model",
        entity_version="2",
        scale_to_zero_enabled=True,
        workload_size="Small",
    )],
    traffic_config=TrafficConfig(
        routes=[Route(served_entity_name="catalog.schema.model-2", traffic_percentage=100)]
    ),
)
```

`update_config()` alone is async -- use `update_config_and_wait()` to block. Cannot update while `state.config_update` is IN_PROGRESS (409) -- check it first.

### Update AI Gateway
```python
from databricks.sdk.service.serving import AiGatewayConfig, AiGatewayRateLimit, AiGatewayUsageTrackingConfig, AiGatewayInferenceTableConfig, AiGatewayGuardrails, AiGatewayGuardrailParameters

gw = w.serving_endpoints.put_ai_gateway(
    name="my-endpoint",
    rate_limits=[AiGatewayRateLimit(calls=100, renewal_period="minute", key="user")],
    usage_tracking_config=AiGatewayUsageTrackingConfig(enabled=True),
    inference_table_config=AiGatewayInferenceTableConfig(
        catalog_name="my_catalog", schema_name="my_schema", enabled=True
    ),
)
```

Agent endpoints support only inference tables; guardrails and rate limits are not available. To change the inference table catalog/schema, disable it first, then re-enable with the new values.

### Update Tags
```python
from databricks.sdk.service.serving import EndpointTag

result = w.serving_endpoints.patch(
    name="my-endpoint",
    add_tags=[EndpointTag(key="team", value="ml")],
    delete_tags=["old-key"],
)
```

### Update Notifications
```python
w.serving_endpoints.update_notifications(
    name="my-endpoint",
    email_notifications=EmailNotifications(
        on_update_failure=["alert@co.com"],
        on_update_success=["alert@co.com"],
    ),
)
```

---

## 3. Provisioned Throughput

```python
# Create PT endpoint
pt_ep = w.serving_endpoints.create_provisioned_throughput_endpoint(
    name="my-pt-endpoint",
    config=EndpointCoreConfigInput(
        served_entities=[ServedEntityInput(
            entity_name="catalog.schema.model",
            entity_version="1",
            provisioned_model_units=500,
        )]
    ),
)

# Update PT config -- instantaneous, unlike standard config updates which roll out gradually
w.serving_endpoints.update_provisioned_throughput_endpoint_config(
    name="my-pt-endpoint",
    config=PtEndpointCoreConfigInput(
        served_entities=[ServedEntityInput(
            entity_name="catalog.schema.model",
            entity_version="2",
            provisioned_model_units=1000,
        )]
    ),
)
```

---

## 4. Query

Input formats are mutually exclusive: `messages` for chat, `dataframe_split`/`dataframe_records` for custom models, `input` for embeddings, `prompt` for completions.

### Chat/Completions (external/foundation models)
```python
response = w.serving_endpoints.query(
    name="my-endpoint",
    messages=[ChatMessage(role="user", content="What is MLflow?")],
    max_tokens=100,
    temperature=0.5,
)
print(response.choices[0].message.content)
```

### Dataframe Input (custom models)
```python
response = w.serving_endpoints.query(
    name="my-endpoint",
    dataframe_split=DataframeSplitInput(
        columns=["feature1", "feature2"],
        data=[[1.0, 2.0], [3.0, 4.0]],
    ),
)
print(response.predictions)
```

### Embeddings
```python
response = w.serving_endpoints.query(name="my-endpoint", input="text to embed")
print(response.data[0].embedding)
```

---

## 5. Observability

```python
# Prometheus metrics (returns text)
metrics = w.serving_endpoints.export_metrics(name="my-endpoint")

# OpenAPI schema
schema = w.serving_endpoints.get_open_api(name="my-endpoint")

# Build logs for a served model
build = w.serving_endpoints.build_logs(name="my-endpoint", served_model_name="model-1")
print(build.logs)

# Service logs
svc = w.serving_endpoints.logs(name="my-endpoint", served_model_name="model-1")
print(svc.logs)
```

---

## 6. Permissions

Permission levels: `CAN_MANAGE`, `CAN_QUERY`, `CAN_VIEW`. Uses endpoint **id** (UUID), not the endpoint name string.

```python
from databricks.sdk.service.iam import ServingEndpointAccessControlRequest, ServingEndpointPermissionLevel

# Get endpoint ID
ep = w.serving_endpoints.get(name="my-endpoint")

# Get current permissions
perms = w.serving_endpoints.get_permissions(serving_endpoint_id=ep.id)

# Set permissions (replaces all)
w.serving_endpoints.set_permissions(
    serving_endpoint_id=ep.id,
    access_control_list=[ServingEndpointAccessControlRequest(
        user_name="user@co.com",
        permission_level=ServingEndpointPermissionLevel.CAN_QUERY,
    )],
)

# Update permissions (merges)
w.serving_endpoints.update_permissions(
    serving_endpoint_id=ep.id,
    access_control_list=[ServingEndpointAccessControlRequest(
        group_name="data-scientists",
        permission_level=ServingEndpointPermissionLevel.CAN_QUERY,
    )],
)

# List available permission levels
levels = w.serving_endpoints.get_permission_levels(serving_endpoint_id=ep.id)
```

---

## Common Patterns

### Create and Poll Until Ready
```python
# Option 1: use _and_wait (blocks)
ep = w.serving_endpoints.create_and_wait(name="ep", config=config)

# Option 2: manual polling
ep = w.serving_endpoints.create(name="ep", config=config)
import time
while True:
    status = w.serving_endpoints.get(name="ep")
    if status.state.ready == "READY":
        break
    if status.state.config_update == "UPDATE_FAILED":
        raise RuntimeError("Endpoint update failed")
    time.sleep(30)
```

### External Model (OpenAI via Gateway)
```python
ep = w.serving_endpoints.create_and_wait(
    name="openai-proxy",
    config=EndpointCoreConfigInput(
        served_entities=[ServedEntityInput(
            entity_name="gpt-4",
            external_model=ExternalModel(
                name="gpt-4",
                provider="openai",
                task="llm/v1/chat",
                openai_config=OpenAiConfig(
                    openai_api_key="{{secrets/scope/key}}",
                ),
            ),
        )]
    ),
)
```

---

## Gotchas

- **`served_models` is deprecated** -- always use `served_entities`.
- **`auto_capture_config` is deprecated** for PT endpoints -- use AI Gateway inference tables.
