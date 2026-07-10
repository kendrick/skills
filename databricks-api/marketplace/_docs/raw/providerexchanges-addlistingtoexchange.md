Title: Add an exchange for listing | Provider Exchanges API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/providerexchanges/addlistingtoexchange

Markdown Content:
## Add an exchange for listing

Public preview

`POST/api/2.0/marketplace-exchange/exchanges-for-listing`

`POST/api/2.1/marketplace-exchange/exchanges-for-listing`

Associate an exchange with a listing

API scopes:[`marketplace`](https://docs.databricks.com/api/workspace/api/scopes#marketplace)

### Request body

[`exchange_id`](https://docs.databricks.com/api/workspace/providerexchanges/addlistingtoexchange#exchange_id)required string

[`listing_id`](https://docs.databricks.com/api/workspace/providerexchanges/addlistingtoexchange#listing_id)required string

### Responses

**200** Request completed successfully.

Request completed successfully.

[`exchange_for_listing`](https://docs.databricks.com/api/workspace/providerexchanges/addlistingtoexchange#exchange_for_listing)object

[`created_at`](https://docs.databricks.com/api/workspace/providerexchanges/addlistingtoexchange#exchange_for_listing-created_at)int64

[`created_by`](https://docs.databricks.com/api/workspace/providerexchanges/addlistingtoexchange#exchange_for_listing-created_by)string

[`exchange_id`](https://docs.databricks.com/api/workspace/providerexchanges/addlistingtoexchange#exchange_for_listing-exchange_id)string

[`exchange_name`](https://docs.databricks.com/api/workspace/providerexchanges/addlistingtoexchange#exchange_for_listing-exchange_name)string

[`id`](https://docs.databricks.com/api/workspace/providerexchanges/addlistingtoexchange#exchange_for_listing-id)string

[`listing_id`](https://docs.databricks.com/api/workspace/providerexchanges/addlistingtoexchange#exchange_for_listing-listing_id)string

[`listing_name`](https://docs.databricks.com/api/workspace/providerexchanges/addlistingtoexchange#exchange_for_listing-listing_name)string

# Request samples

JSON

{

"exchange_id":"string",

"listing_id":"string"

}

# Response samples

200

{

"exchange_for_listing":{

"created_at":0,

"created_by":"string",

"exchange_id":"string",

"exchange_name":"string",

"id":"string",

"listing_id":"string",

"listing_name":"string"

}

}
