Title: Create a new serving endpoint | Serving endpoints API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/servingendpoints/create

Markdown Content:
## Create a new serving endpoint

`POST/api/2.0/serving-endpoints`

Create a new serving endpoint.

API scopes (preview):[`model-serving`](https://docs.databricks.com/api/workspace/api/scopes#model-serving)

### Request body

[`ai_gateway`](https://docs.databricks.com/api/workspace/servingendpoints/create#ai_gateway)object

The AI Gateway configuration for the serving endpoint. NOTE: External model, provisioned throughput, and pay-per-token endpoints are fully supported; agent endpoints currently only support inference tables.

[`fallback_config`](https://docs.databricks.com/api/workspace/servingendpoints/create#ai_gateway-fallback_config)object

Configuration for traffic fallback which auto fallbacks to other served entities if the request to a served entity fails with certain error codes, to increase availability.

[`guardrails`](https://docs.databricks.com/api/workspace/servingendpoints/create#ai_gateway-guardrails)object

Public preview

Configuration for AI Guardrails to prevent unwanted data and unsafe data in requests and responses.

[`inference_table_config`](https://docs.databricks.com/api/workspace/servingendpoints/create#ai_gateway-inference_table_config)object

Configuration for payload logging using inference tables. Use these tables to monitor and audit data being sent to and received from model APIs and to improve model quality.

[`rate_limits`](https://docs.databricks.com/api/workspace/servingendpoints/create#ai_gateway-rate_limits)Array of object

Configuration for rate limits which can be set to limit endpoint traffic.

[`usage_tracking_config`](https://docs.databricks.com/api/workspace/servingendpoints/create#ai_gateway-usage_tracking_config)object

Configuration to enable usage tracking using system tables. These tables allow you to monitor operational usage on endpoints and their associated costs.

[`budget_policy_id`](https://docs.databricks.com/api/workspace/servingendpoints/create#budget_policy_id)string

The budget policy to be applied to the serving endpoint.

[`config`](https://docs.databricks.com/api/workspace/servingendpoints/create#config)object

The core config of the serving endpoint.

[`auto_capture_config`](https://docs.databricks.com/api/workspace/servingendpoints/create#config-auto_capture_config)object

Configuration for Inference Tables which automatically logs requests and responses to Unity Catalog. Note: this field is deprecated for creating new provisioned throughput endpoints, or updating existing provisioned throughput endpoints that never have inference table configured; in these cases please use AI Gateway to manage inference tables.

[`served_entities`](https://docs.databricks.com/api/workspace/servingendpoints/create#config-served_entities)Array of object

The list of served entities under the serving endpoint config.

[`served_models`](https://docs.databricks.com/api/workspace/servingendpoints/create#config-served_models)Array of object

(Deprecated, use served_entities instead) The list of served models under the serving endpoint config.

[`traffic_config`](https://docs.databricks.com/api/workspace/servingendpoints/create#config-traffic_config)object

The traffic configuration associated with the serving endpoint config.

[`description`](https://docs.databricks.com/api/workspace/servingendpoints/create#description)string

<= 1000 characters 

[`email_notifications`](https://docs.databricks.com/api/workspace/servingendpoints/create#email_notifications)object

Email notification settings.

[`on_update_failure`](https://docs.databricks.com/api/workspace/servingendpoints/create#email_notifications-on_update_failure)Array of string

A list of email addresses to be notified when an endpoint fails to update its configuration or state.

[`on_update_success`](https://docs.databricks.com/api/workspace/servingendpoints/create#email_notifications-on_update_success)Array of string

A list of email addresses to be notified when an endpoint successfully updates its configuration or state.

[`name`](https://docs.databricks.com/api/workspace/servingendpoints/create#name)required string

Example`"feed-ads"`

The name of the serving endpoint. This field is required and must be unique across a Databricks workspace. An endpoint name can consist of alphanumeric characters, dashes, and underscores.

[`rate_limits`](https://docs.databricks.com/api/workspace/servingendpoints/create#rate_limits)Array of object

Deprecated

Rate limits to be applied to the serving endpoint. NOTE: this field is deprecated, please use AI Gateway to manage rate limits.

Array [

[`calls`](https://docs.databricks.com/api/workspace/servingendpoints/create#rate_limits-calls)required int64

Example`15`

Used to specify how many calls are allowed for a key within the renewal_period.

[`key`](https://docs.databricks.com/api/workspace/servingendpoints/create#rate_limits-key)string

Enum:

`user`

Public preview

`endpoint`

Public preview

Key field for a serving endpoint rate limit. Currently, only 'user' and 'endpoint' are supported, with 'endpoint' being the default if not specified.

[`renewal_period`](https://docs.databricks.com/api/workspace/servingendpoints/create#rate_limits-renewal_period)required string

Enum:

`minute`

Public preview

Renewal period field for a serving endpoint rate limit. Currently, only 'minute' is supported.

 ]

[`route_optimized`](https://docs.databricks.com/api/workspace/servingendpoints/create#route_optimized)boolean

Example`true`

Enable route optimization for the serving endpoint.

[`tags`](https://docs.databricks.com/api/workspace/servingendpoints/create#tags)Array of object

Tags to be attached to the serving endpoint and automatically propagated to billing logs.

Array [

[`key`](https://docs.databricks.com/api/workspace/servingendpoints/create#tags-key)required string

Example`"team"`

Key field for a serving endpoint tag.

[`value`](https://docs.databricks.com/api/workspace/servingendpoints/create#tags-value)string

Example`"data science"`

Optional value field for a serving endpoint tag.

 ]

### Responses

**200** Request completed successfully.

Request completed successfully.

[`ai_gateway`](https://docs.databricks.com/api/workspace/servingendpoints/create#ai_gateway)object

The AI Gateway configuration for the serving endpoint. NOTE: External model, provisioned throughput, and pay-per-token endpoints are fully supported; agent endpoints currently only support inference tables.

[`fallback_config`](https://docs.databricks.com/api/workspace/servingendpoints/create#ai_gateway-fallback_config)object

Configuration for traffic fallback which auto fallbacks to other served entities if the request to a served entity fails with certain error codes, to increase availability.

[`guardrails`](https://docs.databricks.com/api/workspace/servingendpoints/create#ai_gateway-guardrails)object

Public preview

Configuration for AI Guardrails to prevent unwanted data and unsafe data in requests and responses.

[`inference_table_config`](https://docs.databricks.com/api/workspace/servingendpoints/create#ai_gateway-inference_table_config)object

Configuration for payload logging using inference tables. Use these tables to monitor and audit data being sent to and received from model APIs and to improve model quality.

[`rate_limits`](https://docs.databricks.com/api/workspace/servingendpoints/create#ai_gateway-rate_limits)Array of object

Configuration for rate limits which can be set to limit endpoint traffic.

[`usage_tracking_config`](https://docs.databricks.com/api/workspace/servingendpoints/create#ai_gateway-usage_tracking_config)object

Configuration to enable usage tracking using system tables. These tables allow you to monitor operational usage on endpoints and their associated costs.

[`budget_policy_id`](https://docs.databricks.com/api/workspace/servingendpoints/create#budget_policy_id)string

The budget policy associated with the endpoint.

[`config`](https://docs.databricks.com/api/workspace/servingendpoints/create#config)object

The config that is currently being served by the endpoint.

[`auto_capture_config`](https://docs.databricks.com/api/workspace/servingendpoints/create#config-auto_capture_config)object

Configuration for Inference Tables which automatically logs requests and responses to Unity Catalog. Note: this field is deprecated for creating new provisioned throughput endpoints, or updating existing provisioned throughput endpoints that never have inference table configured; in these cases please use AI Gateway to manage inference tables.

[`config_version`](https://docs.databricks.com/api/workspace/servingendpoints/create#config-config_version)int64

The config version that the serving endpoint is currently serving.

[`served_entities`](https://docs.databricks.com/api/workspace/servingendpoints/create#config-served_entities)Array of object

The list of served entities under the serving endpoint config.

[`served_models`](https://docs.databricks.com/api/workspace/servingendpoints/create#config-served_models)Array of object

(Deprecated, use served_entities instead) The list of served models under the serving endpoint config.

[`traffic_config`](https://docs.databricks.com/api/workspace/servingendpoints/create#config-traffic_config)object

The traffic configuration associated with the serving endpoint config.

[`creation_timestamp`](https://docs.databricks.com/api/workspace/servingendpoints/create#creation_timestamp)int64

The timestamp when the endpoint was created in Unix time.

[`creator`](https://docs.databricks.com/api/workspace/servingendpoints/create#creator)string

Example`"alice@company.com"`

The email of the user who created the serving endpoint.

[`data_plane_info`](https://docs.databricks.com/api/workspace/servingendpoints/create#data_plane_info)object

Information required to query DataPlane APIs.

[`query_info`](https://docs.databricks.com/api/workspace/servingendpoints/create#data_plane_info-query_info)object

Information required to query DataPlane API 'query' endpoint.

[`description`](https://docs.databricks.com/api/workspace/servingendpoints/create#description)string

Description of the serving model

[`email_notifications`](https://docs.databricks.com/api/workspace/servingendpoints/create#email_notifications)object

Email notification settings.

[`on_update_failure`](https://docs.databricks.com/api/workspace/servingendpoints/create#email_notifications-on_update_failure)Array of string

A list of email addresses to be notified when an endpoint fails to update its configuration or state.

[`on_update_success`](https://docs.databricks.com/api/workspace/servingendpoints/create#email_notifications-on_update_success)Array of string

A list of email addresses to be notified when an endpoint successfully updates its configuration or state.

[`endpoint_url`](https://docs.databricks.com/api/workspace/servingendpoints/create#endpoint_url)string

Endpoint invocation url if route optimization is enabled for endpoint

[`id`](https://docs.databricks.com/api/workspace/servingendpoints/create#id)string

Example`"88fd3f75a0d24b0380ddc40484d7a31b"`

System-generated ID of the endpoint. This is used to refer to the endpoint in the Permissions API

[`last_updated_timestamp`](https://docs.databricks.com/api/workspace/servingendpoints/create#last_updated_timestamp)int64

The timestamp when the endpoint was last updated by a user in Unix time.

[`name`](https://docs.databricks.com/api/workspace/servingendpoints/create#name)string

Example`"feed-ads"`

The name of the serving endpoint.

[`pending_config`](https://docs.databricks.com/api/workspace/servingendpoints/create#pending_config)object

The config that the endpoint is attempting to update to.

[`auto_capture_config`](https://docs.databricks.com/api/workspace/servingendpoints/create#pending_config-auto_capture_config)object

Configuration for Inference Tables which automatically logs requests and responses to Unity Catalog. Note: this field is deprecated for creating new provisioned throughput endpoints, or updating existing provisioned throughput endpoints that never have inference table configured; in these cases please use AI Gateway to manage inference tables.

[`config_version`](https://docs.databricks.com/api/workspace/servingendpoints/create#pending_config-config_version)int32

The config version that the serving endpoint is currently serving.

[`served_entities`](https://docs.databricks.com/api/workspace/servingendpoints/create#pending_config-served_entities)Array of object

The list of served entities belonging to the last issued update to the serving endpoint.

[`served_models`](https://docs.databricks.com/api/workspace/servingendpoints/create#pending_config-served_models)Array of object

(Deprecated, use served_entities instead) The list of served models belonging to the last issued update to the serving endpoint.

[`start_time`](https://docs.databricks.com/api/workspace/servingendpoints/create#pending_config-start_time)int64

The timestamp when the update to the pending config started.

[`traffic_config`](https://docs.databricks.com/api/workspace/servingendpoints/create#pending_config-traffic_config)object

The traffic config defining how invocations to the serving endpoint should be routed.

[`permission_level`](https://docs.databricks.com/api/workspace/servingendpoints/create#permission_level)string

Enum: `CAN_MANAGE | CAN_QUERY | CAN_VIEW`

Example`"CAN_MANAGE"`

The permission level of the principal making the request.

[`route_optimized`](https://docs.databricks.com/api/workspace/servingendpoints/create#route_optimized)boolean

Example`true`

Boolean representing if route optimization has been enabled for the endpoint

[`state`](https://docs.databricks.com/api/workspace/servingendpoints/create#state)object

Information corresponding to the state of the serving endpoint.

[`config_update`](https://docs.databricks.com/api/workspace/servingendpoints/create#state-config_update)string

Enum: `NOT_UPDATING | IN_PROGRESS | UPDATE_FAILED | UPDATE_CANCELED`

The state of an endpoint's config update. This informs the user if the pending_config is in progress, if the update failed, or if there is no update in progress. Note that if the endpoint's config_update state value is IN_PROGRESS, another update can not be made until the update completes or fails.

[`ready`](https://docs.databricks.com/api/workspace/servingendpoints/create#state-ready)string

Enum: `READY | NOT_READY`

The state of an endpoint, indicating whether or not the endpoint is queryable. An endpoint is READY if all of the served entities in its active configuration are ready. If any of the actively served entities are in a non-ready state, the endpoint state will be NOT_READY.

[`tags`](https://docs.databricks.com/api/workspace/servingendpoints/create#tags)Array of object

Tags attached to the serving endpoint.

Array [

[`key`](https://docs.databricks.com/api/workspace/servingendpoints/create#tags-key)string

Example`"team"`

Key field for a serving endpoint tag.

[`value`](https://docs.databricks.com/api/workspace/servingendpoints/create#tags-value)string

Example`"data science"`

Optional value field for a serving endpoint tag.

 ]

[`task`](https://docs.databricks.com/api/workspace/servingendpoints/create#task)string

Example`"model-serving-task"`

The task type of the serving endpoint.

 This method might return the following HTTP codes: 400, 401, 500

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

UNAUTHENTICATED

Request does not have valid authentication credentials for the operation.

500

INTERNAL_ERROR

Internal error.

# Request samples

JSON

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

"name":"feed-ads",

"rate_limits":[

{

"calls":15,

"key":"user",

"renewal_period":"minute"

}

],

"route_optimized":true,

"tags":[

{

"key":"team",

"value":"data science"

}

]

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
