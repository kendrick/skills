Title: Update AI Gateway of a serving endpoint | Serving endpoints API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/servingendpoints/putaigateway

Markdown Content:
## Update AI Gateway of a serving endpoint

`PUT/api/2.0/serving-endpoints/{name}/ai-gateway`

Used to update the AI Gateway of a serving endpoint. NOTE: External model, provisioned throughput, and pay-per-token endpoints are fully supported; agent endpoints currently only support inference tables.

API scopes (preview):[`model-serving`](https://docs.databricks.com/api/workspace/api/scopes#model-serving)

### Path parameters

[`name`](https://docs.databricks.com/api/workspace/servingendpoints/putaigateway#name)required string

[ 1 .. 63 ] characters 

Example`"feed-ads"`

The name of the serving endpoint whose AI Gateway is being updated. This field is required.

### Request body

[`fallback_config`](https://docs.databricks.com/api/workspace/servingendpoints/putaigateway#fallback_config)object

Configuration for traffic fallback which auto fallbacks to other served entities if the request to a served entity fails with certain error codes, to increase availability.

[`enabled`](https://docs.databricks.com/api/workspace/servingendpoints/putaigateway#fallback_config-enabled)required boolean

Example`true`

Whether to enable traffic fallback. When a served entity in the serving endpoint returns specific error codes (e.g. 500), the request will automatically be round-robin attempted with other served entities in the same endpoint, following the order of served entity list, until a successful response is returned. If all attempts fail, return the last response with the error code.

[`guardrails`](https://docs.databricks.com/api/workspace/servingendpoints/putaigateway#guardrails)object

Public preview

Configuration for AI Guardrails to prevent unwanted data and unsafe data in requests and responses.

[`input`](https://docs.databricks.com/api/workspace/servingendpoints/putaigateway#guardrails-input)object

Configuration for input guardrail filters.

[`output`](https://docs.databricks.com/api/workspace/servingendpoints/putaigateway#guardrails-output)object

Configuration for output guardrail filters.

[`inference_table_config`](https://docs.databricks.com/api/workspace/servingendpoints/putaigateway#inference_table_config)object

Configuration for payload logging using inference tables. Use these tables to monitor and audit data being sent to and received from model APIs and to improve model quality.

[`catalog_name`](https://docs.databricks.com/api/workspace/servingendpoints/putaigateway#inference_table_config-catalog_name)string

Example`"my-catalog"`

The name of the catalog in Unity Catalog. Required when enabling inference tables. NOTE: On update, you have to disable inference table first in order to change the catalog name.

[`enabled`](https://docs.databricks.com/api/workspace/servingendpoints/putaigateway#inference_table_config-enabled)boolean

Example`true`

Indicates whether the inference table is enabled.

[`schema_name`](https://docs.databricks.com/api/workspace/servingendpoints/putaigateway#inference_table_config-schema_name)string

Example`"my-schema"`

The name of the schema in Unity Catalog. Required when enabling inference tables. NOTE: On update, you have to disable inference table first in order to change the schema name.

[`table_name_prefix`](https://docs.databricks.com/api/workspace/servingendpoints/putaigateway#inference_table_config-table_name_prefix)string

Example`"my-prefix"`

The prefix of the table in Unity Catalog. NOTE: On update, you have to disable inference table first in order to change the prefix name.

[`rate_limits`](https://docs.databricks.com/api/workspace/servingendpoints/putaigateway#rate_limits)Array of object

Configuration for rate limits which can be set to limit endpoint traffic.

Array [

[`calls`](https://docs.databricks.com/api/workspace/servingendpoints/putaigateway#rate_limits-calls)int64

Example`15`

Used to specify how many calls are allowed for a key within the renewal_period.

[`key`](https://docs.databricks.com/api/workspace/servingendpoints/putaigateway#rate_limits-key)string

Enum:

`user`

Public preview

`endpoint`

Public preview

`user_group`

Public preview

`service_principal`

Public preview

Key field for a rate limit. Currently, 'user', 'user_group, 'service_principal', and 'endpoint' are supported, with 'endpoint' being the default if not specified.

[`principal`](https://docs.databricks.com/api/workspace/servingendpoints/putaigateway#rate_limits-principal)string

Example`"user@test.com"`

Principal field for a user, user group, or service principal to apply rate limiting to. Accepts a user email, group name, or service principal application ID.

[`renewal_period`](https://docs.databricks.com/api/workspace/servingendpoints/putaigateway#rate_limits-renewal_period)required string

Enum:

`minute`

Public preview

Renewal period field for a rate limit. Currently, only 'minute' is supported.

[`tokens`](https://docs.databricks.com/api/workspace/servingendpoints/putaigateway#rate_limits-tokens)int64

Example`10000`

Used to specify how many tokens are allowed for a key within the renewal_period.

 ]

[`usage_tracking_config`](https://docs.databricks.com/api/workspace/servingendpoints/putaigateway#usage_tracking_config)object

Configuration to enable usage tracking using system tables. These tables allow you to monitor operational usage on endpoints and their associated costs.

[`enabled`](https://docs.databricks.com/api/workspace/servingendpoints/putaigateway#usage_tracking_config-enabled)boolean

Example`true`

Whether to enable usage tracking.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`fallback_config`](https://docs.databricks.com/api/workspace/servingendpoints/putaigateway#fallback_config)object

Configuration for traffic fallback which auto fallbacks to other served entities if the request to a served entity fails with certain error codes, to increase availability.

[`enabled`](https://docs.databricks.com/api/workspace/servingendpoints/putaigateway#fallback_config-enabled)boolean

Example`true`

Whether to enable traffic fallback. When a served entity in the serving endpoint returns specific error codes (e.g. 500), the request will automatically be round-robin attempted with other served entities in the same endpoint, following the order of served entity list, until a successful response is returned. If all attempts fail, return the last response with the error code.

[`guardrails`](https://docs.databricks.com/api/workspace/servingendpoints/putaigateway#guardrails)object

Public preview

Configuration for AI Guardrails to prevent unwanted data and unsafe data in requests and responses.

[`input`](https://docs.databricks.com/api/workspace/servingendpoints/putaigateway#guardrails-input)object

Configuration for input guardrail filters.

[`output`](https://docs.databricks.com/api/workspace/servingendpoints/putaigateway#guardrails-output)object

Configuration for output guardrail filters.

[`inference_table_config`](https://docs.databricks.com/api/workspace/servingendpoints/putaigateway#inference_table_config)object

Configuration for payload logging using inference tables. Use these tables to monitor and audit data being sent to and received from model APIs and to improve model quality.

[`catalog_name`](https://docs.databricks.com/api/workspace/servingendpoints/putaigateway#inference_table_config-catalog_name)string

Example`"my-catalog"`

The name of the catalog in Unity Catalog. Required when enabling inference tables. NOTE: On update, you have to disable inference table first in order to change the catalog name.

[`enabled`](https://docs.databricks.com/api/workspace/servingendpoints/putaigateway#inference_table_config-enabled)boolean

Example`true`

Indicates whether the inference table is enabled.

[`schema_name`](https://docs.databricks.com/api/workspace/servingendpoints/putaigateway#inference_table_config-schema_name)string

Example`"my-schema"`

The name of the schema in Unity Catalog. Required when enabling inference tables. NOTE: On update, you have to disable inference table first in order to change the schema name.

[`table_name_prefix`](https://docs.databricks.com/api/workspace/servingendpoints/putaigateway#inference_table_config-table_name_prefix)string

Example`"my-prefix"`

The prefix of the table in Unity Catalog. NOTE: On update, you have to disable inference table first in order to change the prefix name.

[`rate_limits`](https://docs.databricks.com/api/workspace/servingendpoints/putaigateway#rate_limits)Array of object

Configuration for rate limits which can be set to limit endpoint traffic.

Array [

[`calls`](https://docs.databricks.com/api/workspace/servingendpoints/putaigateway#rate_limits-calls)int64

Example`15`

Used to specify how many calls are allowed for a key within the renewal_period.

[`key`](https://docs.databricks.com/api/workspace/servingendpoints/putaigateway#rate_limits-key)string

Enum:

`user`

Public preview

`endpoint`

Public preview

`user_group`

Public preview

`service_principal`

Public preview

Key field for a rate limit. Currently, 'user', 'user_group, 'service_principal', and 'endpoint' are supported, with 'endpoint' being the default if not specified.

[`principal`](https://docs.databricks.com/api/workspace/servingendpoints/putaigateway#rate_limits-principal)string

Example`"user@test.com"`

Principal field for a user, user group, or service principal to apply rate limiting to. Accepts a user email, group name, or service principal application ID.

[`renewal_period`](https://docs.databricks.com/api/workspace/servingendpoints/putaigateway#rate_limits-renewal_period)string

Enum:

`minute`

Public preview

Renewal period field for a rate limit. Currently, only 'minute' is supported.

[`tokens`](https://docs.databricks.com/api/workspace/servingendpoints/putaigateway#rate_limits-tokens)int64

Example`10000`

Used to specify how many tokens are allowed for a key within the renewal_period.

 ]

[`usage_tracking_config`](https://docs.databricks.com/api/workspace/servingendpoints/putaigateway#usage_tracking_config)object

Configuration to enable usage tracking using system tables. These tables allow you to monitor operational usage on endpoints and their associated costs.

[`enabled`](https://docs.databricks.com/api/workspace/servingendpoints/putaigateway#usage_tracking_config-enabled)boolean

Example`true`

Whether to enable usage tracking.

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

UNAUTHORIZED

The request does not have valid authentication credentials for the operation.

500

INTERNAL_ERROR

Internal error.

# Request samples

JSON

{

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

}

# Response samples

200

{

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

}
