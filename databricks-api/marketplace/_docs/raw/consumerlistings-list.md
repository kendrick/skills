Title: List listings | Consumer Listings API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/consumerlistings/list

Markdown Content:
## List listings

Public preview

`GET/api/2.1/marketplace-consumer/listings`

List all published listings in the Databricks Marketplace that the consumer has access to.

API scopes:[`marketplace`](https://docs.databricks.com/api/workspace/api/scopes#marketplace)

### Query parameters

[`page_token`](https://docs.databricks.com/api/workspace/consumerlistings/list#page_token)string

[`page_size`](https://docs.databricks.com/api/workspace/consumerlistings/list#page_size)int32

[`assets`](https://docs.databricks.com/api/workspace/consumerlistings/list#assets)Array of string

Array [

Enum: `ASSET_TYPE_GIT_REPO | ASSET_TYPE_DATA_TABLE | ASSET_TYPE_MODEL | ASSET_TYPE_NOTEBOOK | ASSET_TYPE_MEDIA | ASSET_TYPE_PARTNER_INTEGRATION | ASSET_TYPE_APP | ASSET_TYPE_MCP`

]

Matches any of the following asset types

[`categories`](https://docs.databricks.com/api/workspace/consumerlistings/list#categories)Array of string

Array [

Enum: `ADVERTISING_AND_MARKETING | CLIMATE_AND_ENVIRONMENT | COMMERCE | DEMOGRAPHICS | ECONOMICS | EDUCATION | ENERGY | FINANCIAL | GAMING | GEOSPATIAL | HEALTH | LOOKUP_TABLES | MANUFACTURING | MEDIA | OTHER | PUBLIC_SECTOR | RETAIL | SECURITY | SCIENCE_AND_RESEARCH | SPORTS | TRANSPORTATION_AND_LOGISTICS | TRAVEL_AND_TOURISM`

]

Matches any of the following categories

[`tags`](https://docs.databricks.com/api/workspace/consumerlistings/list#tags)object

Matches listings with this tag

[`tag_name`](https://docs.databricks.com/api/workspace/consumerlistings/list#tags-tag_name)string

Enum: `LISTING_TAG_TYPE_LANGUAGE | LISTING_TAG_TYPE_TASK`

Tag name (enum)

[`tag_values`](https://docs.databricks.com/api/workspace/consumerlistings/list#tags-tag_values)Array of string

String representation of the tag value. Values should be string literals (no complex types)

[`is_free`](https://docs.databricks.com/api/workspace/consumerlistings/list#is_free)boolean

Filters each listing based on if it is free.

[`is_private_exchange`](https://docs.databricks.com/api/workspace/consumerlistings/list#is_private_exchange)boolean

Filters each listing based on if it is a private exchange.

[`is_staff_pick`](https://docs.databricks.com/api/workspace/consumerlistings/list#is_staff_pick)boolean

Filters each listing based on whether it is a staff pick.

[`provider_ids`](https://docs.databricks.com/api/workspace/consumerlistings/list#provider_ids)Array of string

Matches any of the following provider ids

### Responses

**200** Request completed successfully. The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

Request completed successfully.

 The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

[`listings`](https://docs.databricks.com/api/workspace/consumerlistings/list#listings)Array of object

Array [

[`detail`](https://docs.databricks.com/api/workspace/consumerlistings/list#listings-detail)object

[`id`](https://docs.databricks.com/api/workspace/consumerlistings/list#listings-id)string

[`summary`](https://docs.databricks.com/api/workspace/consumerlistings/list#listings-summary)object

 ]

[`next_page_token`](https://docs.databricks.com/api/workspace/consumerlistings/list#next_page_token)string

# Response samples

200

{

"listings":[

{

"detail":{

"assets":[

"ASSET_TYPE_GIT_REPO"

],

"collection_date_end":0,

"collection_date_start":0,

"collection_granularity":{

"interval":0,

"unit":"NONE"

},

"cost":"FREE",

"data_source":"string",

"description":"string",

"documentation_link":"string",

"embedded_notebook_file_infos":[

{

"created_at":0,

"display_name":"string",

"download_link":"string",

"file_parent":{

"file_parent_type":"PROVIDER",

"parent_id":"string"

},

"id":"string",

"marketplace_file_type":"PROVIDER_ICO N",

"mime_type":"string",

"status":"FILE_STATUS_PUBLISHED",

"status_message":"string",

"updated_at":0

}

],

"file_ids":[

"string"

],

"geographical_coverage":"string",

"license":"string",

"pricing_model":"string",

"privacy_policy_link":"string",

"size":0.1,

"support_link":"string",

"tags":[

{

"tag_name":"LISTING_TAG_TYPE_LANGUAGE",

"tag_values":[

"string"

]

}

],

"terms_of_service":"string",

"update_frequency":{

"interval":0,

"unit":"NONE"

}

},

"id":"string",

"summary":{

"categories":[

"ADVERTISING_AND_MARKETING"

],

"created_at":0,

"created_by":"string",

"created_by_id":0,

"exchange_ids":[

"string"

],

"git_repo":{

"git_repo_url":"string"

},

"listingType":"STANDARD",

"name":"string",

"provider_id":"string",

"provider_region":{

"cloud":"string",

"region":"string"

},

"published_at":0,

"published_by":"string",

"setting":{

"visibility":"PUBLIC"

},

"share":{

"name":"string",

"type":"SAMPLE"

},

"status":"DRAFT",

"subtitle":"string",

"updated_at":0,

"updated_by":"string",

"updated_by_id":0

}

}

],

"next_page_token":"string"

}
