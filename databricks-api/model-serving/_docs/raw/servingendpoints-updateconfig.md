Title: Update config of a serving endpoint | Serving endpoints API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/servingendpoints/updateconfig

Markdown Content:
## Update config of a serving endpoint

`PUT/api/2.0/serving-endpoints/{name}/config`

Updates any combination of the serving endpoint's served entities, the compute configuration of those served entities, and the endpoint's traffic config. An endpoint that already has an update in progress can not be updated until the current update completes or fails.

API scopes (preview):[`model-serving`](https://docs.databricks.com/api/workspace/api/scopes#model-serving)

### Path parameters

[`name`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#name)required string

[ 1 .. 63 ] characters 

Example`"feed-ads"`

The name of the serving endpoint to update. This field is required.

### Request body

[`auto_capture_config`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#auto_capture_config)object

Configuration for Inference Tables which automatically logs requests and responses to Unity Catalog. Note: this field is deprecated for creating new provisioned throughput endpoints, or updating existing provisioned throughput endpoints that never have inference table configured; in these cases please use AI Gateway to manage inference tables.

[`catalog_name`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#auto_capture_config-catalog_name)string

Example`"my-catalog"`

The name of the catalog in Unity Catalog. NOTE: On update, you cannot change the catalog name if the inference table is already enabled.

[`enabled`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#auto_capture_config-enabled)boolean

Example`true`

Indicates whether the inference table is enabled.

[`schema_name`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#auto_capture_config-schema_name)string

Example`"my-schema"`

The name of the schema in Unity Catalog. NOTE: On update, you cannot change the schema name if the inference table is already enabled.

[`table_name_prefix`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#auto_capture_config-table_name_prefix)string

Example`"my-prefix-"`

The prefix of the table in Unity Catalog. NOTE: On update, you cannot change the prefix name if the inference table is already enabled.

[`served_entities`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#served_entities)Array of object

The list of served entities under the serving endpoint config.

Array [

[`burst_scaling_enabled`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#served_entities-burst_scaling_enabled)boolean

Public preview

Example`true`

Whether burst scaling is enabled. When enabled (default), the endpoint can automatically scale up beyond provisioned capacity to handle traffic spikes. When disabled, the endpoint maintains fixed capacity at provisioned_model_units.

[`entity_name`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#served_entities-entity_name)string

Example`"ads-model"`

The name of the entity to be served. The entity may be a model in the Databricks Model Registry, a model in the Unity Catalog (UC), or a function of type FEATURE_SPEC in the UC. If it is a UC object, the full name of the object should be given in the form of catalog_name.schema_name.model_name.

[`entity_version`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#served_entities-entity_version)string

Example`"3"`

[`environment_vars`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#served_entities-environment_vars)object

An object containing a set of optional, user-specified environment variable key-value pairs used for serving this entity. Note: this is an experimental feature and subject to change. Example entity environment variables that refer to Databricks secrets: `{"OPENAI_API_KEY": "{{secrets/my_scope/my_key}}", "DATABRICKS_TOKEN": "{{secrets/my_scope2/my_key2}}"}`

[`external_model`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#served_entities-external_model)object

The external model to be served. NOTE: Only one of external_model and (entity_name, entity_version, workload_size, workload_type, and scale_to_zero_enabled) can be specified with the latter set being used for custom model serving for a Databricks registered model. For an existing endpoint with external_model, it cannot be updated to an endpoint without external_model. If the endpoint is created without external_model, users cannot update it to add external_model later. The task type of all external models within an endpoint must be the same.

[`instance_profile_arn`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#served_entities-instance_profile_arn)string

Public preview

ARN of the instance profile that the served entity uses to access AWS resources.

[`max_provisioned_concurrency`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#served_entities-max_provisioned_concurrency)int32

Example`32`

The maximum provisioned concurrency that the endpoint can scale up to. Do not use if workload_size is specified.

[`max_provisioned_throughput`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#served_entities-max_provisioned_throughput)int32

Example`1960`

The maximum tokens per second that the endpoint can scale up to.

[`min_provisioned_concurrency`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#served_entities-min_provisioned_concurrency)int32

Example`8`

The minimum provisioned concurrency that the endpoint can scale down to. Do not use if workload_size is specified.

[`min_provisioned_throughput`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#served_entities-min_provisioned_throughput)int32

Example`970`

The minimum tokens per second that the endpoint can scale down to.

[`name`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#served_entities-name)string

Example`"ads-model-3"`

The name of a served entity. It must be unique across an endpoint. A served entity name can consist of alphanumeric characters, dashes, and underscores. If not specified for an external model, this field defaults to external_model.name, with '.' and ':' replaced with '-', and if not specified for other entities, it defaults to entity_name-entity_version.

[`provisioned_model_units`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#served_entities-provisioned_model_units)int64

Public preview

Example`100`

The number of model units provisioned.

[`scale_to_zero_enabled`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#served_entities-scale_to_zero_enabled)boolean

Example`"false"`

Whether the compute resources for the served entity should scale down to zero.

[`workload_size`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#served_entities-workload_size)string

The workload size of the served entity. The workload size corresponds to a range of provisioned concurrency that the compute autoscales between. A single unit of provisioned concurrency can process one request at a time. Valid workload sizes are "Small" (4 - 4 provisioned concurrency), "Medium" (8 - 16 provisioned concurrency), and "Large" (16 - 64 provisioned concurrency). Additional custom workload sizes can also be used when available in the workspace. If scale-to-zero is enabled, the lower bound of the provisioned concurrency for each workload size is 0. Do not use if min_provisioned_concurrency and max_provisioned_concurrency are specified.

[`workload_type`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#served_entities-workload_type)string

Enum: `CPU | GPU_MEDIUM | GPU_SMALL | GPU_LARGE | MULTIGPU_MEDIUM`

Example`"GPU_SMALL"`

The workload type of the served entity. The workload type selects which type of compute to use in the endpoint. The default value for this parameter is "CPU". For deep learning workloads, GPU acceleration is available by selecting workload types like GPU_SMALL and others. See the available [GPU types](https://docs.databricks.com/en/machine-learning/model-serving/create-manage-serving-endpoints.html#gpu-workload-types).

 ]

[`served_models`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#served_models)Array of object

(Deprecated, use served_entities instead) The list of served models under the serving endpoint config.

Array [

[`burst_scaling_enabled`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#served_models-burst_scaling_enabled)boolean

Public preview

Example`true`

Whether burst scaling is enabled. When enabled (default), the endpoint can automatically scale up beyond provisioned capacity to handle traffic spikes. When disabled, the endpoint maintains fixed capacity at provisioned_model_units.

[`environment_vars`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#served_models-environment_vars)object

An object containing a set of optional, user-specified environment variable key-value pairs used for serving this entity. Note: this is an experimental feature and subject to change. Example entity environment variables that refer to Databricks secrets: `{"OPENAI_API_KEY": "{{secrets/my_scope/my_key}}", "DATABRICKS_TOKEN": "{{secrets/my_scope2/my_key2}}"}`

[`instance_profile_arn`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#served_models-instance_profile_arn)string

Public preview

ARN of the instance profile that the served entity uses to access AWS resources.

[`max_provisioned_concurrency`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#served_models-max_provisioned_concurrency)int32

Example`32`

The maximum provisioned concurrency that the endpoint can scale up to. Do not use if workload_size is specified.

[`max_provisioned_throughput`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#served_models-max_provisioned_throughput)int32

Example`1960`

The maximum tokens per second that the endpoint can scale up to.

[`min_provisioned_concurrency`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#served_models-min_provisioned_concurrency)int32

Example`8`

The minimum provisioned concurrency that the endpoint can scale down to. Do not use if workload_size is specified.

[`min_provisioned_throughput`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#served_models-min_provisioned_throughput)int32

Example`970`

The minimum tokens per second that the endpoint can scale down to.

[`model_name`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#served_models-model_name)required string

[`model_version`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#served_models-model_version)required string

[`name`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#served_models-name)string

Example`"ads-model-3"`

The name of a served entity. It must be unique across an endpoint. A served entity name can consist of alphanumeric characters, dashes, and underscores. If not specified for an external model, this field defaults to external_model.name, with '.' and ':' replaced with '-', and if not specified for other entities, it defaults to entity_name-entity_version.

[`provisioned_model_units`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#served_models-provisioned_model_units)int64

Public preview

Example`100`

The number of model units provisioned.

[`scale_to_zero_enabled`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#served_models-scale_to_zero_enabled)required boolean

Example`"false"`

Whether the compute resources for the served entity should scale down to zero.

[`workload_size`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#served_models-workload_size)string

The workload size of the served entity. The workload size corresponds to a range of provisioned concurrency that the compute autoscales between. A single unit of provisioned concurrency can process one request at a time. Valid workload sizes are "Small" (4 - 4 provisioned concurrency), "Medium" (8 - 16 provisioned concurrency), and "Large" (16 - 64 provisioned concurrency). Additional custom workload sizes can also be used when available in the workspace. If scale-to-zero is enabled, the lower bound of the provisioned concurrency for each workload size is 0. Do not use if min_provisioned_concurrency and max_provisioned_concurrency are specified.

[`workload_type`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#served_models-workload_type)string

Enum: `CPU | GPU_MEDIUM | GPU_SMALL | GPU_LARGE | MULTIGPU_MEDIUM`

Example`"GPU_SMALL"`

The workload type of the served entity. The workload type selects which type of compute to use in the endpoint. The default value for this parameter is "CPU". For deep learning workloads, GPU acceleration is available by selecting workload types like GPU_SMALL and others. See the available [GPU types](https://docs.databricks.com/en/machine-learning/model-serving/create-manage-serving-endpoints.html#gpu-workload-types).

 ]

[`traffic_config`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#traffic_config)object

The traffic configuration associated with the serving endpoint config.

[`routes`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#traffic_config-routes)Array of object

The list of routes that define traffic to each served entity.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`ai_gateway`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#ai_gateway)object

The AI Gateway configuration for the serving endpoint. NOTE: External model, provisioned throughput, and pay-per-token endpoints are fully supported; agent endpoints currently only support inference tables.

[`fallback_config`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#ai_gateway-fallback_config)object

Configuration for traffic fallback which auto fallbacks to other served entities if the request to a served entity fails with certain error codes, to increase availability.

[`guardrails`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#ai_gateway-guardrails)object

Public preview

Configuration for AI Guardrails to prevent unwanted data and unsafe data in requests and responses.

[`inference_table_config`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#ai_gateway-inference_table_config)object

Configuration for payload logging using inference tables. Use these tables to monitor and audit data being sent to and received from model APIs and to improve model quality.

[`rate_limits`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#ai_gateway-rate_limits)Array of object

Configuration for rate limits which can be set to limit endpoint traffic.

[`usage_tracking_config`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#ai_gateway-usage_tracking_config)object

Configuration to enable usage tracking using system tables. These tables allow you to monitor operational usage on endpoints and their associated costs.

[`budget_policy_id`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#budget_policy_id)string

The budget policy associated with the endpoint.

[`config`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#config)object

The config that is currently being served by the endpoint.

[`auto_capture_config`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#config-auto_capture_config)object

Configuration for Inference Tables which automatically logs requests and responses to Unity Catalog. Note: this field is deprecated for creating new provisioned throughput endpoints, or updating existing provisioned throughput endpoints that never have inference table configured; in these cases please use AI Gateway to manage inference tables.

[`config_version`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#config-config_version)int64

The config version that the serving endpoint is currently serving.

[`served_entities`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#config-served_entities)Array of object

The list of served entities under the serving endpoint config.

[`served_models`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#config-served_models)Array of object

(Deprecated, use served_entities instead) The list of served models under the serving endpoint config.

[`traffic_config`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#config-traffic_config)object

The traffic configuration associated with the serving endpoint config.

[`creation_timestamp`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#creation_timestamp)int64

The timestamp when the endpoint was created in Unix time.

[`creator`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#creator)string

Example`"alice@company.com"`

The email of the user who created the serving endpoint.

[`data_plane_info`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#data_plane_info)object

Information required to query DataPlane APIs.

[`query_info`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#data_plane_info-query_info)object

Information required to query DataPlane API 'query' endpoint.

[`description`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#description)string

Description of the serving model

[`email_notifications`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#email_notifications)object

Email notification settings.

[`on_update_failure`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#email_notifications-on_update_failure)Array of string

A list of email addresses to be notified when an endpoint fails to update its configuration or state.

[`on_update_success`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#email_notifications-on_update_success)Array of string

A list of email addresses to be notified when an endpoint successfully updates its configuration or state.

[`endpoint_url`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#endpoint_url)string

Endpoint invocation url if route optimization is enabled for endpoint

[`id`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#id)string

Example`"88fd3f75a0d24b0380ddc40484d7a31b"`

System-generated ID of the endpoint. This is used to refer to the endpoint in the Permissions API

[`last_updated_timestamp`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#last_updated_timestamp)int64

The timestamp when the endpoint was last updated by a user in Unix time.

[`name`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#name)string

Example`"feed-ads"`

The name of the serving endpoint.

[`pending_config`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#pending_config)object

The config that the endpoint is attempting to update to.

[`auto_capture_config`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#pending_config-auto_capture_config)object

Configuration for Inference Tables which automatically logs requests and responses to Unity Catalog. Note: this field is deprecated for creating new provisioned throughput endpoints, or updating existing provisioned throughput endpoints that never have inference table configured; in these cases please use AI Gateway to manage inference tables.

[`config_version`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#pending_config-config_version)int32

The config version that the serving endpoint is currently serving.

[`served_entities`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#pending_config-served_entities)Array of object

The list of served entities belonging to the last issued update to the serving endpoint.

[`served_models`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#pending_config-served_models)Array of object

(Deprecated, use served_entities instead) The list of served models belonging to the last issued update to the serving endpoint.

[`start_time`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#pending_config-start_time)int64

The timestamp when the update to the pending config started.

[`traffic_config`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#pending_config-traffic_config)object

The traffic config defining how invocations to the serving endpoint should be routed.

[`permission_level`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#permission_level)string

Enum: `CAN_MANAGE | CAN_QUERY | CAN_VIEW`

Example`"CAN_MANAGE"`

The permission level of the principal making the request.

[`route_optimized`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#route_optimized)boolean

Example`true`

Boolean representing if route optimization has been enabled for the endpoint

[`state`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#state)object

Information corresponding to the state of the serving endpoint.

[`config_update`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#state-config_update)string

Enum: `NOT_UPDATING | IN_PROGRESS | UPDATE_FAILED | UPDATE_CANCELED`

The state of an endpoint's config update. This informs the user if the pending_config is in progress, if the update failed, or if there is no update in progress. Note that if the endpoint's config_update state value is IN_PROGRESS, another update can not be made until the update completes or fails.

[`ready`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#state-ready)string

Enum: `READY | NOT_READY`

The state of an endpoint, indicating whether or not the endpoint is queryable. An endpoint is READY if all of the served entities in its active configuration are ready. If any of the actively served entities are in a non-ready state, the endpoint state will be NOT_READY.

[`tags`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#tags)Array of object

Tags attached to the serving endpoint.

Array [

[`key`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#tags-key)string

Example`"team"`

Key field for a serving endpoint tag.

[`value`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#tags-value)string

Example`"data science"`

Optional value field for a serving endpoint tag.

 ]

[`task`](https://docs.databricks.com/api/workspace/servingendpoints/updateconfig#task)string

Example`"model-serving-task"`

The task type of the serving endpoint.

 This method might return the following HTTP codes: 400, 401, 404, 409, 500

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

BAD_REQUEST

Request is invalid.

401

UNAUTHORIZED

The request does not have valid authentication credentials for the operation.

404

NOT_FOUND

Operation was performed on a resource that does not exist.

409

RESOURCE_CONFLICT

Request was rejected due a conflict with an existing resource.

500

INTERNAL_ERROR

Internal error.

# Request samples

JSON

{

"auto_capture_config":{

"catalog_name":"my-catalog",

"enabled":true,

"schema_name":"my-schema",

"table_name_prefix":"my-prefix-"

},

"served_entities":[

{

"burst_scaling_enabled":true,

"entity_name":"ads-model",

"entity_version":"3",

"environment_vars":{

"property1":"string",

"property2":"string"

},

"external_model":{

"ai21labs_config":{

"ai21labs_api_key":"{{secrets/my_scope/my_ai21labs_api_key}}",

"ai21labs_api_key_plaintext":"Your API Key"

},

"amazon_bedrock_config":{

"aws_access_key_id":"{{secrets/my_scope/my_aws_access_key_id}}",

"aws_access_key_id_plaintext":"Your AWS Access Key ID",

"aws_region":"myAwsRegion",

"aws_secret_access_key":"{{secrets/my_s cope/my_aws_secret_access_key}}",

"aws_secret_access_key_plaintext":"Your AWS Secret Access Key",

"bedrock_provider":"anthropic",

"instance_profile_arn":"arn:aws:iam::12 3456789012:instance-profile/my-instance-profile"

},

"anthropic_config":{

"anthropic_api_key":"{{secrets/my_scope/my_anthropic_api_key}}",

"anthropic_api_key_plaintext":"Your API Key"

},

"cohere_config":{

"cohere_api_base":"https://api.cohere.a i/v1",

"cohere_api_key":"{{secrets/my_scope/my _cohere_api_key}}",

"cohere_api_key_plaintext":"Your API Ke y"

},

"custom_provider_config":{

"api_key_auth":{

"key":"api-key",

"value":"{{secrets/my_scope/my_api_ke y}}",

"value_plaintext":"Your API Key"

},

"bearer_token_auth":{

"token":"{{secrets/my_scope/my_openai _api_key}}",

"token_plaintext":"Your API Key"

},

"custom_provider_url":"https://custom-p rovider.com"

},

"databricks_model_serving_config":{

"databricks_api_token":"{{secrets/my_sc ope/my_databricks_api_token}}",

"databricks_api_token_plaintext":"Your Databricks API Token",

"databricks_workspace_url":"https://my-databricks-workspace.com"

},

"google_cloud_vertex_ai_config":{

"private_key":"{{secrets/my_scope/my_go ogle_cloud_vertex_ai_api_key}}",

"private_key_plaintext":"Your API Key",

"project_id":"your-project-id",

"region":"us-central1"

},

"name":"gpt-4",

"openai_config":{

"microsoft_entra_client_id":"12345678-a bcd-1234-5678-12345678abcd",

"microsoft_entra_client_secret":"{{secr ets/my_scope/my_microsoft_entra_client_secret}}",

"microsoft_entra_client_secret_plaintext":"Your Microsoft Entra Client Secret",

"microsoft_entra_tenant_id":"12345678-a bcd-1234-5678-12345678abcd",

"openai_api_base":"https://api.openai.c om/v1",

"openai_api_key":"{{secrets/my_scope/my _openai_api_key}}",

"openai_api_key_plaintext":"Your API Ke y",

"openai_api_type":"azure",

"openai_api_version":"2023-11-01",

"openai_deployment_name":"my_deployment _resource",

"openai_organization":"Databricks"

},

"palm_config":{

"palm_api_key":"{{secrets/my_scope/my_p alm_api_key}}",

"palm_api_key_plaintext":"Your API Key"

},

"provider":"ai21labs",

"task":"llm/v1/chat"

},

"instance_profile_arn":"string",

"max_provisioned_concurrency":32,

"max_provisioned_throughput":1960,

"min_provisioned_concurrency":8,

"min_provisioned_throughput":970,

"name":"ads-model-3",

"provisioned_model_units":100,

"scale_to_zero_enabled":"false",

"workload_size":"string",

"workload_type":"CPU"

}

],

"served_models":[

{

"burst_scaling_enabled":true,

"environment_vars":{

"property1":"string",

"property2":"string"

},

"instance_profile_arn":"string",

"max_provisioned_concurrency":32,

"max_provisioned_throughput":1960,

"min_provisioned_concurrency":8,

"min_provisioned_throughput":970,

"model_name":"string",

"model_version":"string",

"name":"ads-model-3",

"provisioned_model_units":100,

"scale_to_zero_enabled":"false",

"workload_size":"string",

"workload_type":"CPU"

}

],

"traffic_config":{

"routes":[

{

"served_entity_name":"ads-model-3",

"served_model_name":"ads-model-3",

"traffic_percentage":"100"

}

]

}

}

# Response samples

200

{

"ai_gateway":{

"fallback_config":{

"enabled":true

},

"guardrails":{

"input":{

"invalid_keywords":[

"string"

],

"pii":{

"behavior":"NONE"

},

"safety":true,

"valid_topics":[

"string"

]

},

"output":{

"invalid_keywords":[

"string"

],

"pii":{

"behavior":"NONE"

},

"safety":true,

"valid_topics":[

"string"

]

}

},

"inference_table_config":{

"catalog_name":"my-catalog",

"enabled":true,

"schema_name":"my-schema",

"table_name_prefix":"my-prefix"

},

"rate_limits":[

{

"calls":15,

"key":"user",

"principal":"user@test.com",

"renewal_period":"minute",

"tokens":10000

}

],

"usage_tracking_config":{

"enabled":true

}

},

"budget_policy_id":"string",

"config":{

"auto_capture_config":{

"catalog_name":"my-catalog",

"enabled":true,

"schema_name":"my-schema",

"state":{

"payload_table":{

"name":"string",

"status":"string",

"status_message":"string"

}

},

"table_name_prefix":"my-prefix-"

},

"config_version":0,

"served_entities":[

{

"burst_scaling_enabled":true,

"creation_timestamp":0,

"creator":"string",

"entity_name":"ads-model",

"entity_version":"3",

"environment_vars":{

"property1":"string",

"property2":"string"

},

"external_model":{

"ai21labs_config":{

"ai21labs_api_key":"{{secrets/my_scop e/my_ai21labs_api_key}}",

"ai21labs_api_key_plaintext":"Your AP I Key"

},

"amazon_bedrock_config":{

"aws_access_key_id":"{{secrets/my_sco pe/my_aws_access_key_id}}",

"aws_access_key_id_plaintext":"Your A WS Access Key ID",

"aws_region":"myAwsRegion",

"aws_secret_access_key":"{{secrets/my _scope/my_aws_secret_access_key}}",

"aws_secret_access_key_plaintext":"Yo ur AWS Secret Access Key",

"bedrock_provider":"anthropic",

"instance_profile_arn":"arn:aws:iam::123456789012:instance-profile/my-instance-profile"

},

"anthropic_config":{

"anthropic_api_key":"{{secrets/my_sco pe/my_anthropic_api_key}}",

"anthropic_api_key_plaintext":"Your A PI Key"

},

"cohere_config":{

"cohere_api_base":"https://api.cohere.ai/v1",

"cohere_api_key":"{{secrets/my_scope/my_cohere_api_key}}",

"cohere_api_key_plaintext":"Your API Key"

},

"custom_provider_config":{

"api_key_auth":{

"key":"api-key",

"value":"{{secrets/my_scope/my_api_ key}}",

"value_plaintext":"Your API Key"

},

"bearer_token_auth":{

"token":"{{secrets/my_scope/my_open ai_api_key}}",

"token_plaintext":"Your API Key"

},

"custom_provider_url":"https://custom-provider.com"

},

"databricks_model_serving_config":{

"databricks_api_token":"{{secrets/my_ scope/my_databricks_api_token}}",

"databricks_api_token_plaintext":"You r Databricks API Token",

"databricks_workspace_url":"https://m y-databricks-workspace.com"

},

"google_cloud_vertex_ai_config":{

"private_key":"{{secrets/my_scope/my_ google_cloud_vertex_ai_api_key}}",

"private_key_plaintext":"Your API Key",

"project_id":"your-project-id",

"region":"us-central1"

},

"name":"gpt-4",

"openai_config":{

"microsoft_entra_client_id":"12345678-abcd-1234-5678-12345678abcd",

"microsoft_entra_client_secret":"{{se crets/my_scope/my_microsoft_entra_client_secret}}",

"microsoft_entra_client_secret_plainte xt":"Your Microsoft Entra Client Secret",

"microsoft_entra_tenant_id":"12345678-abcd-1234-5678-12345678abcd",

"openai_api_base":"https://api.openai.com/v1",

"openai_api_key":"{{secrets/my_scope/my_openai_api_key}}",

"openai_api_key_plaintext":"Your API Key",

"openai_api_type":"azure",

"openai_api_version":"2023-11-01",

"openai_deployment_name":"my_deployme nt_resource",

"openai_organization":"Databricks"

},

"palm_config":{

"palm_api_key":"{{secrets/my_scope/my _palm_api_key}}",

"palm_api_key_plaintext":"Your API Ke y"

},

"provider":"ai21labs",

"task":"llm/v1/chat"

},

"foundation_model":{

"description":"string",

"display_name":"string",

"docs":"string",

"name":"string"

},

"instance_profile_arn":"string",

"max_provisioned_concurrency":32,

"max_provisioned_throughput":1960,

"min_provisioned_concurrency":8,

"min_provisioned_throughput":970,

"name":"ads-model-3",

"provisioned_model_units":100,

"scale_to_zero_enabled":"false",

"state":{

"deployment":"DEPLOYMENT_CREATING",

"deployment_state_message":"string"

},

"workload_size":"string",

"workload_type":"CPU"

}

],

"served_models":[

{

"burst_scaling_enabled":true,

"creation_timestamp":0,

"creator":"string",

"environment_vars":{

"property1":"string",

"property2":"string"

},

"instance_profile_arn":"string",

"max_provisioned_concurrency":32,

"min_provisioned_concurrency":8,

"model_name":"string",

"model_version":"string",

"name":"ads-model-3",

"provisioned_model_units":100,

"scale_to_zero_enabled":"false",

"state":{

"deployment":"DEPLOYMENT_CREATING",

"deployment_state_message":"string"

},

"workload_size":"string",

"workload_type":"CPU"

}

],

"traffic_config":{

"routes":[

{

"served_entity_name":"ads-model-3",

"served_model_name":"ads-model-3",

"traffic_percentage":"100"

}

]

}

},

"creation_timestamp":0,

"creator":"alice@company.com",

"data_plane_info":{

"query_info":{

"authorization_details":"string",

"endpoint_url":"string"

}

},

"description":"string",

"email_notifications":{

"on_update_failure":[

"user.name@databricks.com"

],

"on_update_success":[

"user.name@databricks.com"

]

},

"endpoint_url":"string",

"id":"88fd3f75a0d24b0380ddc40484d7a31b",

"last_updated_timestamp":0,

"name":"feed-ads",

"pending_config":{

"auto_capture_config":{

"catalog_name":"my-catalog",

"enabled":true,

"schema_name":"my-schema",

"state":{

"payload_table":{

"name":"string",

"status":"string",

"status_message":"string"

}

},

"table_name_prefix":"my-prefix-"

},

"config_version":0,

"served_entities":[

{

"burst_scaling_enabled":true,

"creation_timestamp":0,

"creator":"string",

"entity_name":"ads-model",

"entity_version":"3",

"environment_vars":{

"property1":"string",

"property2":"string"

},

"external_model":{

"ai21labs_config":{

"ai21labs_api_key":"{{secrets/my_scop e/my_ai21labs_api_key}}",

"ai21labs_api_key_plaintext":"Your AP I Key"

},

"amazon_bedrock_config":{

"aws_access_key_id":"{{secrets/my_sco pe/my_aws_access_key_id}}",

"aws_access_key_id_plaintext":"Your A WS Access Key ID",

"aws_region":"myAwsRegion",

"aws_secret_access_key":"{{secrets/my _scope/my_aws_secret_access_key}}",

"aws_secret_access_key_plaintext":"Yo ur AWS Secret Access Key",

"bedrock_provider":"anthropic",

"instance_profile_arn":"arn:aws:iam::123456789012:instance-profile/my-instance-profile"

},

"anthropic_config":{

"anthropic_api_key":"{{secrets/my_sco pe/my_anthropic_api_key}}",

"anthropic_api_key_plaintext":"Your A PI Key"

},

"cohere_config":{

"cohere_api_base":"https://api.cohere.ai/v1",

"cohere_api_key":"{{secrets/my_scope/my_cohere_api_key}}",

"cohere_api_key_plaintext":"Your API Key"

},

"custom_provider_config":{

"api_key_auth":{

"key":"api-key",

"value":"{{secrets/my_scope/my_api_ key}}",

"value_plaintext":"Your API Key"

},

"bearer_token_auth":{

"token":"{{secrets/my_scope/my_open ai_api_key}}",

"token_plaintext":"Your API Key"

},

"custom_provider_url":"https://custom-provider.com"

},

"databricks_model_serving_config":{

"databricks_api_token":"{{secrets/my_ scope/my_databricks_api_token}}",

"databricks_api_token_plaintext":"You r Databricks API Token",

"databricks_workspace_url":"https://m y-databricks-workspace.com"

},

"google_cloud_vertex_ai_config":{

"private_key":"{{secrets/my_scope/my_ google_cloud_vertex_ai_api_key}}",

"private_key_plaintext":"Your API Key",

"project_id":"your-project-id",

"region":"us-central1"

},

"name":"gpt-4",

"openai_config":{

"microsoft_entra_client_id":"12345678-abcd-1234-5678-12345678abcd",

"microsoft_entra_client_secret":"{{se crets/my_scope/my_microsoft_entra_client_secret}}",

"microsoft_entra_client_secret_plainte xt":"Your Microsoft Entra Client Secret",

"microsoft_entra_tenant_id":"12345678-abcd-1234-5678-12345678abcd",

"openai_api_base":"https://api.openai.com/v1",

"openai_api_key":"{{secrets/my_scope/my_openai_api_key}}",

"openai_api_key_plaintext":"Your API Key",

"openai_api_type":"azure",

"openai_api_version":"2023-11-01",

"openai_deployment_name":"my_deployme nt_resource",

"openai_organization":"Databricks"

},

"palm_config":{

"palm_api_key":"{{secrets/my_scope/my _palm_api_key}}",

"palm_api_key_plaintext":"Your API Ke y"

},

"provider":"ai21labs",

"task":"llm/v1/chat"

},

"foundation_model":{

"description":"string",

"display_name":"string",

"docs":"string",

"name":"string"

},

"instance_profile_arn":"string",

"max_provisioned_concurrency":32,

"max_provisioned_throughput":1960,

"min_provisioned_concurrency":8,

"min_provisioned_throughput":970,

"name":"ads-model-3",

"provisioned_model_units":100,

"scale_to_zero_enabled":"false",

"state":{

"deployment":"DEPLOYMENT_CREATING",

"deployment_state_message":"string"

},

"workload_size":"string",

"workload_type":"CPU"

}

],

"served_models":[

{

"burst_scaling_enabled":true,

"creation_timestamp":0,

"creator":"string",

"environment_vars":{

"property1":"string",

"property2":"string"

},

"instance_profile_arn":"string",

"max_provisioned_concurrency":32,

"min_provisioned_concurrency":8,

"model_name":"string",

"model_version":"string",

"name":"ads-model-3",

"provisioned_model_units":100,

"scale_to_zero_enabled":"false",

"state":{

"deployment":"DEPLOYMENT_CREATING",

"deployment_state_message":"string"

},

"workload_size":"string",

"workload_type":"CPU"

}

],

"start_time":0,

"traffic_config":{

"routes":[

{

"served_entity_name":"ads-model-3",

"served_model_name":"ads-model-3",

"traffic_percentage":"100"

}

]

}

},

"permission_level":"CAN_MANAGE",

"route_optimized":true,

"state":{

"config_update":"NOT_UPDATING",

"ready":"READY"

},

"tags":[

{

"key":"team",

"value":"data science"

}

],

"task":"model-serving-task"

}
