Title: List Genie spaces | Genie API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/genie/listspaces

Markdown Content:
## List Genie spaces

`GET/api/2.0/genie/spaces`

Get list of Genie Spaces.

API scopes:[`genie`](https://docs.databricks.com/api/workspace/api/scopes#genie)

### Query parameters

[`page_size`](https://docs.databricks.com/api/workspace/genie/listspaces#page_size)int32

<= 100 

Default`20`

Maximum number of spaces to return per page

[`page_token`](https://docs.databricks.com/api/workspace/genie/listspaces#page_token)string

Pagination token for getting the next page of results

### Responses

**200** Request completed successfully.

Request completed successfully.

[`next_page_token`](https://docs.databricks.com/api/workspace/genie/listspaces#next_page_token)string

Token to get the next page of results

[`spaces`](https://docs.databricks.com/api/workspace/genie/listspaces#spaces)Array of object

List of Genie spaces

Array [

[`description`](https://docs.databricks.com/api/workspace/genie/listspaces#spaces-description)string

Description of the Genie Space

[`etag`](https://docs.databricks.com/api/workspace/genie/listspaces#spaces-etag)string

Public preview

ETag for this space. Pass this value back in the update request to prevent overwriting concurrent changes.

[`parent_path`](https://docs.databricks.com/api/workspace/genie/listspaces#spaces-parent_path)string

Public preview

Parent folder path of the Genie Space

[`serialized_space`](https://docs.databricks.com/api/workspace/genie/listspaces#spaces-serialized_space)string

Example`"{  \"version\": 2,  \"config\": {    \"sample_questions\": [      { \"id\": \"a1b2c3d4e5f60000000000000000000a\", \"question\": [\"What were total sales last month?\"] },      { \"id\": \"b2c3d4e5f6a70000000000000000000b\", \"question\": [\"Show top 10 customers by revenue\"] }    ]  },  \"data_sources\": {    \"tables\": [      { \"identifier\": \"sales.analytics.customers\", \"description\": [\"Customer master data\"] },      { \"identifier\": \"sales.analytics.orders\", \"description\": [\"Order transactions\"] },      { \"identifier\": \"sales.analytics.products\" }    ],    \"metric_views\": [      { \"identifier\": \"sales.analytics.revenue_metrics\", \"description\": [\"Revenue metrics\"] }    ]  },  \"instructions\": {    \"text_instructions\": [      { \"id\": \"01f0b37c378e1c9100000000000000a1\", \"content\": [\"General instructions for the space.\"] }    ],    \"example_question_sqls\": [      { \"id\": \"01f0821116d912db00000000000000b1\", \"question\": [\"Show top 10 customers\"], \"sql\": [\"SELECT ...\"] }    ],    \"sql_functions\": [      { \"id\": \"01f0c0b4e815100000000000000000f1\", \"identifier\": \"sales.analytics.fiscal_quarter\" }    ],    \"join_specs\": [      { \"id\": \"01f0c0b4e815100000000000000000c1\", \"left\": { \"identifier\": \"sales.analytics.orders\" }, \"right\": { \"identifier\": \"sales.analytics.customers\" }, \"sql\": [\"orders.customer_id = customers.customer_id\"] }    ],    \"sql_snippets\": {      \"filters\": [{ \"id\": \"01f09972e66d100000000000000000d1\", \"sql\": [\"amount > 1000\"], \"display_name\": \"high value\" }],      \"expressions\": [{ \"id\": \"01f09974563a100000000000000000e1\", \"alias\": \"order_year\", \"sql\": [\"YEAR(order_date)\"] }],      \"measures\": [{ \"id\": \"01f09972611f100000000000000000f1\", \"alias\": \"total_revenue\", \"sql\": [\"SUM(amount)\"] }]    }  },  \"benchmarks\": {    \"questions\": [      { \"id\": \"01f0d0b4e815100000000000000000g1\", \"question\": [\"What is average order value?\"], \"answer\": [{ \"format\": \"SQL\", \"content\": [\"SELECT AVG(amount)...\"] }] }    ]  }}"`

The contents of the Genie Space in serialized string form. This field is excluded in List Genie spaces responses. Use the [Get Genie Space](https://docs.databricks.com/api/workspace/genie/getspace) API to retrieve an example response, which includes the `serialized_space` field. This field provides the structure of the JSON string that represents the space's layout and components.

[`space_id`](https://docs.databricks.com/api/workspace/genie/listspaces#spaces-space_id)uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

Genie space ID

[`title`](https://docs.databricks.com/api/workspace/genie/listspaces#spaces-title)string

Title of the Genie Space

[`warehouse_id`](https://docs.databricks.com/api/workspace/genie/listspaces#spaces-warehouse_id)string

Warehouse associated with the Genie Space

 ]

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

NOT_FOUND

Operation was performed on a resource that does not exist.

500

INTERNAL_ERROR

Internal error.

# Response samples

200

{

"next_page_token":"string",

"spaces":[

{

"description":"string",

"etag":"string",

"parent_path":"string",

"serialized_space":"{\"version\":2,\"c onfig\":{\"sample_questions\":[{\"id\":\"a1b2c3d4e5f60000000000000000000a\",\"questio n\":[\"What were total sales last month?\"]},{\"id\":\"b2c3d4e5f6a70000000000000000000b\",\"question\":[\"Show top 10 customers by revenue\"]}]},\"data_sources\":{\"tables\":[{\"identifier\":\"sales.analytics.custom ers\",\"description\":[\"Customer master data\"]},{\"identifier\":\"sales.analytics.order s\",\"description\":[\"Order transactions\"]},{\"identifier\":\"sales.analytics.products\"}],\"metric_views\":[{\"identifi er\":\"sales.analytics.revenue_metrics\",\"descr iption\":[\"Revenue metrics\"]}]},\"inst ructions\":{\"text_instructions\":[{\"id\":\"01f0b37c378e1c9100000000000000a1\",\"con tent\":[\"General instructions for the space.\"]}],\"example_question_sqls\":[{\"i d\":\"01f0821116d912db00000000000000b1\",\"quest ion\":[\"Show top 10 customers\"],\"sql\":[\"SE LECT...\"]}],\"sql_functions\":[{\"id\":\"01f0c0b4e815100000000000000000f1\",\"i dentifier\":\"sales.analytics.fiscal_quarter\"}],\"join_specs\":[{\"id\":\"01f0c0 b4e815100000000000000000c1\",\"left\":{\"identi fier\":\"sales.analytics.orders\"},\"right\":{\"identifier\":\"sales.analytics.customers\"},\"sql\":[\"orders.customer_id=customers.custome r_id\"]}],\"sql_snippets\":{\"filt ers\":[{\"id\":\"01f09972e66d100000000000000000 d1\",\"sql\":[\"amount>1000\"],\"display_name\":\"high value\"}],\"expressions\":[{\"id\":\"01f09974563a100000000000000000e1\",\"alia s\":\"order_year\",\"sql\":[\"YEAR(order_date)\"]}],\"measures\":[{\"id\":\"01f09972611 f100000000000000000f1\",\"alias\":\"total_revenu e\",\"sql\":[\"SUM(amount)\"]}]}},\"ben chmarks\":{\"questions\":[{\"id\":\"01f0d0b4e815100000000000000000g1\",\"question\":[\"What is average order value?\"],\"answer\":[{\"format\":\"SQL\",\"content\":[\"SELECT AVG(a mount)...\"]}]}]}}",

"space_id":"e1ef34712a29169db030324fd0e1df5 f",

"title":"string",

"warehouse_id":"string"

}

]

}
