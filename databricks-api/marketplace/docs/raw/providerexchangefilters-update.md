Title: Update exchange filter | Provider Exchange Filters API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/providerexchangefilters/update

Markdown Content:
## Update exchange filter

Public preview

`PUT/api/2.0/marketplace-exchange/filters/{id}`

`PUT/api/2.1/marketplace-exchange/filters/{id}`

Update an exchange filter.

API scopes:[`marketplace`](https://docs.databricks.com/api/workspace/api/scopes#marketplace)

### Path parameters

[`id`](https://docs.databricks.com/api/workspace/providerexchangefilters/update#id)required string

### Request body

[`filter`](https://docs.databricks.com/api/workspace/providerexchangefilters/update#filter)object

[`created_at`](https://docs.databricks.com/api/workspace/providerexchangefilters/update#filter-created_at)int64

[`created_by`](https://docs.databricks.com/api/workspace/providerexchangefilters/update#filter-created_by)string

[`exchange_id`](https://docs.databricks.com/api/workspace/providerexchangefilters/update#filter-exchange_id)required string

[`filter_type`](https://docs.databricks.com/api/workspace/providerexchangefilters/update#filter-filter_type)required string

Enum: `GLOBAL_METASTORE_ID`

[`filter_value`](https://docs.databricks.com/api/workspace/providerexchangefilters/update#filter-filter_value)required string

[`id`](https://docs.databricks.com/api/workspace/providerexchangefilters/update#filter-id)string

[`name`](https://docs.databricks.com/api/workspace/providerexchangefilters/update#filter-name)string

[`updated_at`](https://docs.databricks.com/api/workspace/providerexchangefilters/update#filter-updated_at)int64

[`updated_by`](https://docs.databricks.com/api/workspace/providerexchangefilters/update#filter-updated_by)string

### Responses

**200** Request completed successfully.

Request completed successfully.

[`filter`](https://docs.databricks.com/api/workspace/providerexchangefilters/update#filter)object

[`created_at`](https://docs.databricks.com/api/workspace/providerexchangefilters/update#filter-created_at)int64

[`created_by`](https://docs.databricks.com/api/workspace/providerexchangefilters/update#filter-created_by)string

[`exchange_id`](https://docs.databricks.com/api/workspace/providerexchangefilters/update#filter-exchange_id)string

[`filter_type`](https://docs.databricks.com/api/workspace/providerexchangefilters/update#filter-filter_type)string

Enum: `GLOBAL_METASTORE_ID`

[`filter_value`](https://docs.databricks.com/api/workspace/providerexchangefilters/update#filter-filter_value)string

[`id`](https://docs.databricks.com/api/workspace/providerexchangefilters/update#filter-id)string

[`name`](https://docs.databricks.com/api/workspace/providerexchangefilters/update#filter-name)string

[`updated_at`](https://docs.databricks.com/api/workspace/providerexchangefilters/update#filter-updated_at)int64

[`updated_by`](https://docs.databricks.com/api/workspace/providerexchangefilters/update#filter-updated_by)string

# Request samples

JSON

{

"filter":{

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

}

# Response samples

200

{

"filter":{

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

}
