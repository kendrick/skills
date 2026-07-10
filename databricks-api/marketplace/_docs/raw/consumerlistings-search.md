Title: Search listings | Consumer Listings API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/consumerlistings/search

Markdown Content:
## Search listings

Public preview

`GET/api/2.1/marketplace-consumer/search-listings`

Search published listings in the Databricks Marketplace that the consumer has access to. This query supports a variety of different search parameters and performs fuzzy matching.

API scopes:[`marketplace`](https://docs.databricks.com/api/workspace/api/scopes#marketplace)

### Query parameters

[`query`](https://docs.databricks.com/api/workspace/consumerlistings/search#query)required string

Fuzzy matches query

[`is_free`](https://docs.databricks.com/api/workspace/consumerlistings/search#is_free)boolean

[`is_private_exchange`](https://docs.databricks.com/api/workspace/consumerlistings/search#is_private_exchange)boolean

[`provider_ids`](https://docs.databricks.com/api/workspace/consumerlistings/search#provider_ids)Array of string

Matches any of the following provider ids

[`categories`](https://docs.databricks.com/api/workspace/consumerlistings/search#categories)Array of string

Array [

Enum: `ADVERTISING_AND_MARKETING | CLIMATE_AND_ENVIRONMENT | COMMERCE | DEMOGRAPHICS | ECONOMICS | EDUCATION | ENERGY | FINANCIAL | GAMING | GEOSPATIAL | HEALTH | LOOKUP_TABLES | MANUFACTURING | MEDIA | OTHER | PUBLIC_SECTOR | RETAIL | SECURITY | SCIENCE_AND_RESEARCH | SPORTS | TRANSPORTATION_AND_LOGISTICS | TRAVEL_AND_TOURISM`

]

Matches any of the following categories

[`assets`](https://docs.databricks.com/api/workspace/consumerlistings/search#assets)Array of string

Array [

Enum: `ASSET_TYPE_GIT_REPO | ASSET_TYPE_DATA_TABLE | ASSET_TYPE_MODEL | ASSET_TYPE_NOTEBOOK | ASSET_TYPE_MEDIA | ASSET_TYPE_PARTNER_INTEGRATION | ASSET_TYPE_APP | ASSET_TYPE_MCP`

]

Matches any of the following asset types

[`page_token`](https://docs.databricks.com/api/workspace/consumerlistings/search#page_token)string

[`page_size`](https://docs.databricks.com/api/workspace/consumerlistings/search#page_size)int32

### Responses

**200** Request completed successfully. The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

Request completed successfully.

 The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

[`listings`](https://docs.databricks.com/api/workspace/consumerlistings/search#listings)Array of object

Array [

[`detail`](https://docs.databricks.com/api/workspace/consumerlistings/search#listings-detail)object

[`id`](https://docs.databricks.com/api/workspace/consumerlistings/search#listings-id)string

[`summary`](https://docs.databricks.com/api/workspace/consumerlistings/search#listings-summary)object

 ]

[`next_page_token`](https://docs.databricks.com/api/workspace/consumerlistings/search#next_page_token)string

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
