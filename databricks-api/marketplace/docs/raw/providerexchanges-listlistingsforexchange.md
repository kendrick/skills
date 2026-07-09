Title: List listings for exchange | Provider Exchanges API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/providerexchanges/listlistingsforexchange

Markdown Content:
## List listings for exchange

Public preview

`GET/api/2.0/marketplace-exchange/listings-for-exchange`

`GET/api/2.1/marketplace-exchange/listings-for-exchange`

List listings associated with an exchange

API scopes:[`marketplace`](https://docs.databricks.com/api/workspace/api/scopes#marketplace)

### Query parameters

[`exchange_id`](https://docs.databricks.com/api/workspace/providerexchanges/listlistingsforexchange#exchange_id)required string

[`page_token`](https://docs.databricks.com/api/workspace/providerexchanges/listlistingsforexchange#page_token)string

[`page_size`](https://docs.databricks.com/api/workspace/providerexchanges/listlistingsforexchange#page_size)int32

### Responses

**200** Request completed successfully. The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

Request completed successfully.

 The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

[`exchange_listings`](https://docs.databricks.com/api/workspace/providerexchanges/listlistingsforexchange#exchange_listings)Array of object

Array [

[`created_at`](https://docs.databricks.com/api/workspace/providerexchanges/listlistingsforexchange#exchange_listings-created_at)int64

[`created_by`](https://docs.databricks.com/api/workspace/providerexchanges/listlistingsforexchange#exchange_listings-created_by)string

[`exchange_id`](https://docs.databricks.com/api/workspace/providerexchanges/listlistingsforexchange#exchange_listings-exchange_id)string

[`exchange_name`](https://docs.databricks.com/api/workspace/providerexchanges/listlistingsforexchange#exchange_listings-exchange_name)string

[`id`](https://docs.databricks.com/api/workspace/providerexchanges/listlistingsforexchange#exchange_listings-id)string

[`listing_id`](https://docs.databricks.com/api/workspace/providerexchanges/listlistingsforexchange#exchange_listings-listing_id)string

[`listing_name`](https://docs.databricks.com/api/workspace/providerexchanges/listlistingsforexchange#exchange_listings-listing_name)string

 ]

[`next_page_token`](https://docs.databricks.com/api/workspace/providerexchanges/listlistingsforexchange#next_page_token)string

# Response samples

200

{

"exchange_listings":[

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
