Title: Create a listing | Provider Listings API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/providerlistings/create

Markdown Content:
## Create a listing

Public preview

`POST/api/2.0/marketplace-provider/listing`

`POST/api/2.1/marketplace-provider/listing`

Create a new listing

API scopes:[`marketplace`](https://docs.databricks.com/api/workspace/api/scopes#marketplace)

### Request body

[`listing`](https://docs.databricks.com/api/workspace/providerlistings/create#listing)object

[`detail`](https://docs.databricks.com/api/workspace/providerlistings/create#listing-detail)object

[`id`](https://docs.databricks.com/api/workspace/providerlistings/create#listing-id)string

[`summary`](https://docs.databricks.com/api/workspace/providerlistings/create#listing-summary)object

### Responses

**200** Request completed successfully.

Request completed successfully.

[`listing_id`](https://docs.databricks.com/api/workspace/providerlistings/create#listing_id)string

# Request samples

JSON

{

"listing":{

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

"marketplace_file_type":"PROVIDER_ICON",

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

}

# Response samples

200

{

"listing_id":"string"

}
