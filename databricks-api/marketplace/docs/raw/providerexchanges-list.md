Title: List exchanges | Provider Exchanges API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/providerexchanges/list

Markdown Content:
## List exchanges

Public preview

`GET/api/2.0/marketplace-exchange/exchanges`

`GET/api/2.1/marketplace-exchange/exchanges`

List exchanges visible to provider

API scopes:[`marketplace`](https://docs.databricks.com/api/workspace/api/scopes#marketplace)

### Query parameters

[`page_token`](https://docs.databricks.com/api/workspace/providerexchanges/list#page_token)string

[`page_size`](https://docs.databricks.com/api/workspace/providerexchanges/list#page_size)int32

### Responses

**200** Request completed successfully. The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

Request completed successfully.

 The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

[`exchanges`](https://docs.databricks.com/api/workspace/providerexchanges/list#exchanges)Array of object

Array [

[`comment`](https://docs.databricks.com/api/workspace/providerexchanges/list#exchanges-comment)string

[`created_at`](https://docs.databricks.com/api/workspace/providerexchanges/list#exchanges-created_at)int64

[`created_by`](https://docs.databricks.com/api/workspace/providerexchanges/list#exchanges-created_by)string

[`filters`](https://docs.databricks.com/api/workspace/providerexchanges/list#exchanges-filters)Array of object

[`id`](https://docs.databricks.com/api/workspace/providerexchanges/list#exchanges-id)string

[`linked_listings`](https://docs.databricks.com/api/workspace/providerexchanges/list#exchanges-linked_listings)Array of object

[`name`](https://docs.databricks.com/api/workspace/providerexchanges/list#exchanges-name)string

[`updated_at`](https://docs.databricks.com/api/workspace/providerexchanges/list#exchanges-updated_at)int64

[`updated_by`](https://docs.databricks.com/api/workspace/providerexchanges/list#exchanges-updated_by)string

 ]

[`next_page_token`](https://docs.databricks.com/api/workspace/providerexchanges/list#next_page_token)string

# Response samples

200

{

"exchanges":[

{

"comment":"string",

"created_at":0,

"created_by":"string",

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

"id":"string",

"linked_listings":[

{

"created_at":0,

"created_by":"string",

"exchange_id":"string",

"exchange_name":"string",

"id":"string",

"listing_id":"string",

"listing_name":"string"

}

],

"name":"string",

"updated_at":0,

"updated_by":"string"

}

],

"next_page_token":"string"

}
