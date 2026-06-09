Title: Get Genie Space | Genie API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/genie/getspace

Markdown Content:
## Get Genie Space

`GET/api/2.0/genie/spaces/{space_id}`

Get details of a Genie Space.

API scopes:[`genie`](https://docs.databricks.com/api/workspace/api/scopes#genie)

### Path parameters

[`space_id`](https://docs.databricks.com/api/workspace/genie/getspace#space_id)required uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

The ID associated with the Genie space

### Query parameters

[`include_serialized_space`](https://docs.databricks.com/api/workspace/genie/getspace#include_serialized_space)boolean

Default`false`

Whether to include the serialized space export in the response. Requires at least CAN EDIT permission on the space.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`description`](https://docs.databricks.com/api/workspace/genie/getspace#description)string

Description of the Genie Space

[`etag`](https://docs.databricks.com/api/workspace/genie/getspace#etag)string

Public preview

ETag for this space. Pass this value back in the update request to prevent overwriting concurrent changes.

[`parent_path`](https://docs.databricks.com/api/workspace/genie/getspace#parent_path)string

Public preview

Parent folder path of the Genie Space

[`serialized_space`](https://docs.databricks.com/api/workspace/genie/getspace#serialized_space)string

Example`"{  \"version\": 2,  \"config\": {    \"sample_questions\": [      { \"id\": \"a1b2c3d4e5f60000000000000000000a\", \"question\": [\"What were total sales last month?\"] },      { \"id\": \"b2c3d4e5f6a70000000000000000000b\", \"question\": [\"Show top 10 customers by revenue\"] }    ]  },  \"data_sources\": {    \"tables\": [      { \"identifier\": \"sales.analytics.customers\", \"description\": [\"Customer master data\"] },      { \"identifier\": \"sales.analytics.orders\", \"description\": [\"Order transactions\"] },      { \"identifier\": \"sales.analytics.products\" }    ],    \"metric_views\": [      { \"identifier\": \"sales.analytics.revenue_metrics\", \"description\": [\"Revenue metrics\"] }    ]  },  \"instructions\": {    \"text_instructions\": [      { \"id\": \"01f0b37c378e1c9100000000000000a1\", \"content\": [\"General instructions for the space.\"] }    ],    \"example_question_sqls\": [      { \"id\": \"01f0821116d912db00000000000000b1\", \"question\": [\"Show top 10 customers\"], \"sql\": [\"SELECT ...\"] }    ],    \"sql_functions\": [      { \"id\": \"01f0c0b4e815100000000000000000f1\", \"identifier\": \"sales.analytics.fiscal_quarter\" }    ],    \"join_specs\": [      { \"id\": \"01f0c0b4e815100000000000000000c1\", \"left\": { \"identifier\": \"sales.analytics.orders\" }, \"right\": { \"identifier\": \"sales.analytics.customers\" }, \"sql\": [\"orders.customer_id = customers.customer_id\"] }    ],    \"sql_snippets\": {      \"filters\": [{ \"id\": \"01f09972e66d100000000000000000d1\", \"sql\": [\"amount > 1000\"], \"display_name\": \"high value\" }],      \"expressions\": [{ \"id\": \"01f09974563a100000000000000000e1\", \"alias\": \"order_year\", \"sql\": [\"YEAR(order_date)\"] }],      \"measures\": [{ \"id\": \"01f09972611f100000000000000000f1\", \"alias\": \"total_revenue\", \"sql\": [\"SUM(amount)\"] }]    }  },  \"benchmarks\": {    \"questions\": [      { \"id\": \"01f0d0b4e815100000000000000000g1\", \"question\": [\"What is average order value?\"], \"answer\": [{ \"format\": \"SQL\", \"content\": [\"SELECT AVG(amount)...\"] }] }    ]  }}"`

The contents of the Genie Space in serialized string form. This field is excluded in List Genie spaces responses. Use the [Get Genie Space](https://docs.databricks.com/api/workspace/genie/getspace) API to retrieve an example response, which includes the `serialized_space` field. This field provides the structure of the JSON string that represents the space's layout and components.

[`space_id`](https://docs.databricks.com/api/workspace/genie/getspace#space_id)uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

Genie space ID

[`title`](https://docs.databricks.com/api/workspace/genie/getspace#title)string

Title of the Genie Space

[`warehouse_id`](https://docs.databricks.com/api/workspace/genie/getspace#warehouse_id)string

Warehouse associated with the Genie Space

 This method might return the following HTTP codes: 400, 401, 403, 404, 500

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

403

PERMISSION_DENIED

Caller does not have permission to execute the specified operation.

404

NOT_FOUND, FEATURE_DISABLED

NOT_FOUND - Operation was performed on a resource that does not exist. FEATURE_DISABLED - If a given user/entity is trying to use a feature which has been disabled.

500

INTERNAL_ERROR

Internal error.

# Response samples

200

{

"description":"string",

"etag":"string",

"parent_path":"string",

"serialized_space":"{\"version\":2,\"confi g\":{\"sample_questions\":[{\"id\":\"a1b2c3d4e5f60000000000000000000a\",\"question\":[\"What were total sales last month?\"]},{\"id\":\"b2c3d4e5f6a70000000000000000000b\",\"q uestion\":[\"Show top 10 customers by revenue\"]}]},\"data_sources\":{\"tables\":[{\"identifier\":\"sales.analytics.customers\",\"description\":[\"Customer master data\"]},{\"identifier\":\"sales.analytics.orders\",\"description\":[\"Order transactions\"]},{\"identifier\":\"sales.analytics.products\"}],\"metric_views\":[{\"identifier\":\"sales.analytics.revenue_metrics\",\"descripti on\":[\"Revenue metrics\"]}]},\"instruct ions\":{\"text_instructions\":[{\"id\":\"01f0b37c378e1c9100000000000000a1\",\"content\":[\"General instructions for the space.\"]}],\"example_question_sqls\":[{\"id\":\"01f0821116d912db00000000000000b1\",\"question\":[\"Show top 10 customers\"],\"sql\":[\"SELECT...\"]}],\"sql_functions\":[{\"i d\":\"01f0c0b4e815100000000000000000f1\",\"ident ifier\":\"sales.analytics.fiscal_quarter\"}],\"join_specs\":[{\"id\":\"01f0c0b4e8 15100000000000000000c1\",\"left\":{\"identifier\":\"sales.analytics.orders\"},\"right\":{\"i dentifier\":\"sales.analytics.customers\"},\"sq l\":[\"orders.customer_id=customers.customer_id\"]}],\"sql_snippets\":{\"filters\":[{\"id\":\"01f09972e66d100000000000000000d1\",\"sql\":[\"amount>1000\"],\"display_name\":\"high value\"}],\"expressions\":[{\"id\":\"01f09974563a100000000000000000e1\",\"alias\":\"order_year\",\"sql\":[\"YEAR(order_date)\"]}],\"measures\":[{\"id\":\"01f09972611f100 000000000000000f1\",\"alias\":\"total_revenue\",\"sql\":[\"SUM(amount)\"]}]}},\"benchma rks\":{\"questions\":[{\"id\":\"01f0 d0b4e815100000000000000000g1\",\"question\":[\"W hat is average order value?\"],\"answer\":[{\"f ormat\":\"SQL\",\"content\":[\"SELECT AVG(amoun t)...\"]}]}]}}",

"space_id":"e1ef34712a29169db030324fd0e1df5f",

"title":"string",

"warehouse_id":"string"

}
