Title: Get the personalization request for a listing | Consumer Personalization Requests API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/get

Markdown Content:
## Get the personalization request for a listing

Public preview

`GET/api/2.1/marketplace-consumer/listings/{listing_id}/personalization-requests`

Get the personalization request for a listing. Each consumer can make at _most_ one personalization request for a listing.

API scopes:[`marketplace`](https://docs.databricks.com/api/workspace/api/scopes#marketplace)

### Path parameters

[`listing_id`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/get#listing_id)required string

### Responses

**200** Request completed successfully.

Request completed successfully.

[`personalization_requests`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/get#personalization_requests)Array of object

Array [

[`comment`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/get#personalization_requests-comment)string

[`consumer_region`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/get#personalization_requests-consumer_region)object

[`contact_info`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/get#personalization_requests-contact_info)object

contact info for the consumer requesting data or performing a listing installation

[`created_at`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/get#personalization_requests-created_at)int64

[`id`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/get#personalization_requests-id)string

[`intended_use`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/get#personalization_requests-intended_use)string

[`is_from_lighthouse`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/get#personalization_requests-is_from_lighthouse)boolean

[`listing_id`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/get#personalization_requests-listing_id)string

[`listing_name`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/get#personalization_requests-listing_name)string

[`metastore_id`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/get#personalization_requests-metastore_id)string

[`provider_id`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/get#personalization_requests-provider_id)string

[`recipient_type`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/get#personalization_requests-recipient_type)string

Enum: `DELTA_SHARING_RECIPIENT_TYPE_DATABRICKS | DELTA_SHARING_RECIPIENT_TYPE_OPEN`

[`share`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/get#personalization_requests-share)object

Share information is required for data listings but should be empty/ignored for non-data listings (MCP and App).

[`status`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/get#personalization_requests-status)string

Enum: `NEW | REQUEST_PENDING | FULFILLED | DENIED`

[`status_message`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/get#personalization_requests-status_message)string

[`updated_at`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/get#personalization_requests-updated_at)int64

 ]

# Response samples

200

{

"personalization_requests":[

{

"comment":"string",

"consumer_region":{

"cloud":"string",

"region":"string"

},

"contact_info":{

"company":"string",

"email":"string",

"first_name":"string",

"last_name":"string"

},

"created_at":0,

"id":"string",

"intended_use":"string",

"is_from_lighthouse":true,

"listing_id":"string",

"listing_name":"string",

"metastore_id":"string",

"provider_id":"string",

"recipient_type":"DELTA_SHARING_RECIPIENT_T YPE_DATABRICKS",

"share":{

"name":"string",

"type":"SAMPLE"

},

"status":"NEW",

"status_message":"string",

"updated_at":0

}

]

}
