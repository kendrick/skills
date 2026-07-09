Title: Create an exchange | Provider Exchanges API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/providerexchanges/create

Markdown Content:
## Create an exchange

Public preview

`POST/api/2.0/marketplace-exchange/exchanges`

`POST/api/2.1/marketplace-exchange/exchanges`

Create an exchange

API scopes:[`marketplace`](https://docs.databricks.com/api/workspace/api/scopes#marketplace)

### Request body

[`exchange`](https://docs.databricks.com/api/workspace/providerexchanges/create#exchange)object

[`comment`](https://docs.databricks.com/api/workspace/providerexchanges/create#exchange-comment)string

[`created_at`](https://docs.databricks.com/api/workspace/providerexchanges/create#exchange-created_at)int64

[`created_by`](https://docs.databricks.com/api/workspace/providerexchanges/create#exchange-created_by)string

[`filters`](https://docs.databricks.com/api/workspace/providerexchanges/create#exchange-filters)Array of object

[`id`](https://docs.databricks.com/api/workspace/providerexchanges/create#exchange-id)string

[`linked_listings`](https://docs.databricks.com/api/workspace/providerexchanges/create#exchange-linked_listings)Array of object

[`name`](https://docs.databricks.com/api/workspace/providerexchanges/create#exchange-name)required string

[`updated_at`](https://docs.databricks.com/api/workspace/providerexchanges/create#exchange-updated_at)int64

[`updated_by`](https://docs.databricks.com/api/workspace/providerexchanges/create#exchange-updated_by)string

### Responses

**200** Request completed successfully.

Request completed successfully.

[`exchange_id`](https://docs.databricks.com/api/workspace/providerexchanges/create#exchange_id)string

# Request samples

JSON

{

"exchange":{

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

}

# Response samples

200

{

"exchange_id":"string"

}
