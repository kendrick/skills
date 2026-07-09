Title: List exchanges for listing | Provider Exchanges API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/providerexchanges/listexchangesforlisting

Markdown Content:
## List exchanges for listing

Public preview

`GET/api/2.0/marketplace-exchange/exchanges-for-listing`

`GET/api/2.1/marketplace-exchange/exchanges-for-listing`

List exchanges associated with a listing

API scopes:[`marketplace`](https://docs.databricks.com/api/workspace/api/scopes#marketplace)

### Query parameters

[`listing_id`](https://docs.databricks.com/api/workspace/providerexchanges/listexchangesforlisting#listing_id)required string

[`page_token`](https://docs.databricks.com/api/workspace/providerexchanges/listexchangesforlisting#page_token)string

[`page_size`](https://docs.databricks.com/api/workspace/providerexchanges/listexchangesforlisting#page_size)int32

### Responses

**200** Request completed successfully. The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

Request completed successfully.

 The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

[`exchange_listing`](https://docs.databricks.com/api/workspace/providerexchanges/listexchangesforlisting#exchange_listing)Array of object

Array [

[`created_at`](https://docs.databricks.com/api/workspace/providerexchanges/listexchangesforlisting#exchange_listing-created_at)int64

[`created_by`](https://docs.databricks.com/api/workspace/providerexchanges/listexchangesforlisting#exchange_listing-created_by)string

[`exchange_id`](https://docs.databricks.com/api/workspace/providerexchanges/listexchangesforlisting#exchange_listing-exchange_id)string

[`exchange_name`](https://docs.databricks.com/api/workspace/providerexchanges/listexchangesforlisting#exchange_listing-exchange_name)string

[`id`](https://docs.databricks.com/api/workspace/providerexchanges/listexchangesforlisting#exchange_listing-id)string

[`listing_id`](https://docs.databricks.com/api/workspace/providerexchanges/listexchangesforlisting#exchange_listing-listing_id)string

[`listing_name`](https://docs.databricks.com/api/workspace/providerexchanges/listexchangesforlisting#exchange_listing-listing_name)string

 ]

[`next_page_token`](https://docs.databricks.com/api/workspace/providerexchanges/listexchangesforlisting#next_page_token)string

# Response samples

200

{

"exchange_listing":[

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

"next_page_token":"string"

}
