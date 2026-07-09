Title: Get all serving endpoints | Serving endpoints API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/servingendpoints/list

Markdown Content:
## Get all serving endpoints

`GET/api/2.0/serving-endpoints`

Get all serving endpoints.

API scopes (preview):[`model-serving`](https://docs.databricks.com/api/workspace/api/scopes#model-serving)

### Responses

**200** Request completed successfully.

Request completed successfully.

[`endpoints`](https://docs.databricks.com/api/workspace/servingendpoints/list#endpoints)Array of object

The list of endpoints.

Array [

[`ai_gateway`](https://docs.databricks.com/api/workspace/servingendpoints/list#endpoints-ai_gateway)object

The AI Gateway configuration for the serving endpoint. NOTE: External model, provisioned throughput, and pay-per-token endpoints are fully supported; agent endpoints currently only support inference tables.

[`budget_policy_id`](https://docs.databricks.com/api/workspace/servingendpoints/list#endpoints-budget_policy_id)string

The budget policy associated with the endpoint.

[`config`](https://docs.databricks.com/api/workspace/servingendpoints/list#endpoints-config)object

The config that is currently being served by the endpoint.

[`creation_timestamp`](https://docs.databricks.com/api/workspace/servingendpoints/list#endpoints-creation_timestamp)int64

The timestamp when the endpoint was created in Unix time.

[`creator`](https://docs.databricks.com/api/workspace/servingendpoints/list#endpoints-creator)string

Example`"alice@company.com"`

The email of the user who created the serving endpoint.

[`description`](https://docs.databricks.com/api/workspace/servingendpoints/list#endpoints-description)string

Description of the endpoint

[`id`](https://docs.databricks.com/api/workspace/servingendpoints/list#endpoints-id)string

Example`"88fd3f75a0d24b0380ddc40484d7a31b"`

System-generated ID of the endpoint, included to be used by the Permissions API.

[`last_updated_timestamp`](https://docs.databricks.com/api/workspace/servingendpoints/list#endpoints-last_updated_timestamp)int64

The timestamp when the endpoint was last updated by a user in Unix time.

[`name`](https://docs.databricks.com/api/workspace/servingendpoints/list#endpoints-name)string

Example`"feed-ads"`

The name of the serving endpoint.

[`state`](https://docs.databricks.com/api/workspace/servingendpoints/list#endpoints-state)object

Information corresponding to the state of the serving endpoint.

[`tags`](https://docs.databricks.com/api/workspace/servingendpoints/list#endpoints-tags)Array of object

Tags attached to the serving endpoint.

[`task`](https://docs.databricks.com/api/workspace/servingendpoints/list#endpoints-task)string

Example`"model-serving-task"`

The task type of the serving endpoint.

[`usage_policy_id`](https://docs.databricks.com/api/workspace/servingendpoints/list#endpoints-usage_policy_id)string

The usage policy associated with serving endpoint.

 ]

 This method might return the following HTTP codes: 401, 500

Error responses are returned in the following format:

{

"error_code":"Error code",

"message":"Human-readable error message."

}

# Possible error codes:

HTTP code

error_code

Description

401

UNAUTHENTICATED

Request does not have valid authentication credentials for the operation.

500

INTERNAL_SERVER_ERROR

Internal error.

# Response samples

200

{

"endpoints":[

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

"served_entities":[

{

"entity_name":"string",

"entity_version":"string",

"external_model":{

"ai21labs_config":{

"ai21labs_api_key":"{{secrets/my_ scope/my_ai21labs_api_key}}",

"ai21labs_api_key_plaintext":"You r API Key"

},

"amazon_bedrock_config":{

"aws_access_key_id":"{{secrets/my _scope/my_aws_access_key_id}}",

"aws_access_key_id_plaintext":"Yo ur AWS Access Key ID",

"aws_region":"myAwsRegion",

"aws_secret_access_key":"{{secret s/my_scope/my_aws_secret_access_key}}",

"aws_secret_access_key_plaintext":"Your AWS Secret Access Key",

"bedrock_provider":"anthropic",

"instance_profile_arn":"arn:aws:i am::123456789012:instance-profile/my-instance-prof ile"

},

"anthropic_config":{

"anthropic_api_key":"{{secrets/my _scope/my_anthropic_api_key}}",

"anthropic_api_key_plaintext":"Yo ur API Key"

},

"cohere_config":{

"cohere_api_base":"https://api.co here.ai/v1",

"cohere_api_key":"{{secrets/my_sc ope/my_cohere_api_key}}",

"cohere_api_key_plaintext":"Your API Key"

},

"custom_provider_config":{

"api_key_auth":{

"key":"api-key",

"value":"{{secrets/my_scope/my_ api_key}}",

"value_plaintext":"Your API Key"

},

"bearer_token_auth":{

"token":"{{secrets/my_scope/my_ openai_api_key}}",

"token_plaintext":"Your API Key"

},

"custom_provider_url":"https://cu stom-provider.com"

},

"databricks_model_serving_config":{

"databricks_api_token":"{{secrets/my_scope/my_databricks_api_token}}",

"databricks_api_token_plaintext":"Your Databricks API Token",

"databricks_workspace_url":"https://my-databricks-workspace.com"

},

"google_cloud_vertex_ai_config":{

"private_key":"{{secrets/my_scope/my_google_cloud_vertex_ai_api_key}}",

"private_key_plaintext":"Your API Key",

"project_id":"your-project-id",

"region":"us-central1"

},

"name":"gpt-4",

"openai_config":{

"microsoft_entra_client_id":"1234 5678-abcd-1234-5678-12345678abcd",

"microsoft_entra_client_secret":"{{secrets/my_scope/my_microsoft_entra_client_secre t}}",

"microsoft_entra_client_secret_pla intext":"Your Microsoft Entra Client Secret",

"microsoft_entra_tenant_id":"1234 5678-abcd-1234-5678-12345678abcd",

"openai_api_base":"https://api.op enai.com/v1",

"openai_api_key":"{{secrets/my_sc ope/my_openai_api_key}}",

"openai_api_key_plaintext":"Your API Key",

"openai_api_type":"azure",

"openai_api_version":"2023-11-01",

"openai_deployment_name":"my_depl oyment_resource",

"openai_organization":"Databricks"

},

"palm_config":{

"palm_api_key":"{{secrets/my_scop e/my_palm_api_key}}",

"palm_api_key_plaintext":"Your AP I Key"

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

"name":"string"

}

],

"served_models":[

{

"model_name":"string",

"model_version":"string",

"name":"string"

}

]

},

"creation_timestamp":0,

"creator":"alice@company.com",

"description":"string",

"id":"88fd3f75a0d24b0380ddc40484d7a31b",

"last_updated_timestamp":0,

"name":"feed-ads",

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

"task":"model-serving-task",

"usage_policy_id":"string"

}

]

}
