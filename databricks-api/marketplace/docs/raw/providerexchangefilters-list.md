Title: List exchange filters | Provider Exchange Filters API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/providerexchangefilters/list

Markdown Content:
## List exchange filters

Public preview

`GET/api/2.0/marketplace-exchange/filters`

`GET/api/2.1/marketplace-exchange/filters`

List exchange filter

API scopes:[`marketplace`](https://docs.databricks.com/api/workspace/api/scopes#marketplace)

### Query parameters

[`exchange_id`](https://docs.databricks.com/api/workspace/providerexchangefilters/list#exchange_id)required string

[`page_token`](https://docs.databricks.com/api/workspace/providerexchangefilters/list#page_token)string

[`page_size`](https://docs.databricks.com/api/workspace/providerexchangefilters/list#page_size)int32

### Responses

**200** Request completed successfully. The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

Request completed successfully.

 The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

[`filters`](https://docs.databricks.com/api/workspace/providerexchangefilters/list#filters)Array of object

Array [

[`created_at`](https://docs.databricks.com/api/workspace/providerexchangefilters/list#filters-created_at)int64

[`created_by`](https://docs.databricks.com/api/workspace/providerexchangefilters/list#filters-created_by)string

[`exchange_id`](https://docs.databricks.com/api/workspace/providerexchangefilters/list#filters-exchange_id)string

[`filter_type`](https://docs.databricks.com/api/workspace/providerexchangefilters/list#filters-filter_type)string

Enum: `GLOBAL_METASTORE_ID`

[`filter_value`](https://docs.databricks.com/api/workspace/providerexchangefilters/list#filters-filter_value)string

[`id`](https://docs.databricks.com/api/workspace/providerexchangefilters/list#filters-id)string

[`name`](https://docs.databricks.com/api/workspace/providerexchangefilters/list#filters-name)string

[`updated_at`](https://docs.databricks.com/api/workspace/providerexchangefilters/list#filters-updated_at)int64

[`updated_by`](https://docs.databricks.com/api/workspace/providerexchangefilters/list#filters-updated_by)string

 ]

[`next_page_token`](https://docs.databricks.com/api/workspace/providerexchangefilters/list#next_page_token)string

# Response samples

200

{

"filters":[

{

"created_at":0,

"created_by":"string",

"exchange_id":"string",

"filter_type":"GLOBAL_METASTORE_ID",

"filter_value":"string",

"id":"string",

"name":"string",

"updated_at":0,

"updated_by":"string"

}

],

"next_page_token":"string"

}
