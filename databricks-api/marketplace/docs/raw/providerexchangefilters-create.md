Title: Create a new exchange filter | Provider Exchange Filters API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/providerexchangefilters/create

Markdown Content:
## Create a new exchange filter

Public preview

`POST/api/2.0/marketplace-exchange/filters`

`POST/api/2.1/marketplace-exchange/filters`

Add an exchange filter.

API scopes:[`marketplace`](https://docs.databricks.com/api/workspace/api/scopes#marketplace)

### Request body

[`filter`](https://docs.databricks.com/api/workspace/providerexchangefilters/create#filter)object

[`created_at`](https://docs.databricks.com/api/workspace/providerexchangefilters/create#filter-created_at)int64

[`created_by`](https://docs.databricks.com/api/workspace/providerexchangefilters/create#filter-created_by)string

[`exchange_id`](https://docs.databricks.com/api/workspace/providerexchangefilters/create#filter-exchange_id)required string

[`filter_type`](https://docs.databricks.com/api/workspace/providerexchangefilters/create#filter-filter_type)required string

Enum: `GLOBAL_METASTORE_ID`

[`filter_value`](https://docs.databricks.com/api/workspace/providerexchangefilters/create#filter-filter_value)required string

[`id`](https://docs.databricks.com/api/workspace/providerexchangefilters/create#filter-id)string

[`name`](https://docs.databricks.com/api/workspace/providerexchangefilters/create#filter-name)string

[`updated_at`](https://docs.databricks.com/api/workspace/providerexchangefilters/create#filter-updated_at)int64

[`updated_by`](https://docs.databricks.com/api/workspace/providerexchangefilters/create#filter-updated_by)string

### Responses

**200** Request completed successfully.

Request completed successfully.

[`filter_id`](https://docs.databricks.com/api/workspace/providerexchangefilters/create#filter_id)string

# Request samples

JSON

{ "filter": { "created_at": 0, "created_by": "string", "exchange_id": "string", "filter_type": "GLOBAL_METASTORE_ID", "filter_value": "string", "id": "string", "name": "string", "updated_at": 0, "updated_by": "string" } }

# Response samples

200

{ "filter_id": "string" }
