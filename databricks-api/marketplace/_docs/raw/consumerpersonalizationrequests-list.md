Title: List all personalization requests | Consumer Personalization Requests API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/list

Markdown Content:
## List all personalization requests

Public preview

`GET/api/2.1/marketplace-consumer/personalization-requests`

List personalization requests for a consumer across all listings.

API scopes:[`marketplace`](https://docs.databricks.com/api/workspace/api/scopes#marketplace)

### Query parameters

[`page_token`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/list#page_token)string

[`page_size`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/list#page_size)int32

### Responses

**200** Request completed successfully. The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

Request completed successfully.

 The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

[`next_page_token`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/list#next_page_token)string

[`personalization_requests`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/list#personalization_requests)Array of object

Array [

[`comment`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/list#personalization_requests-comment)string

[`consumer_region`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/list#personalization_requests-consumer_region)object

[`contact_info`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/list#personalization_requests-contact_info)object

contact info for the consumer requesting data or performing a listing installation

[`created_at`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/list#personalization_requests-created_at)int64

[`id`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/list#personalization_requests-id)string

[`intended_use`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/list#personalization_requests-intended_use)string

[`is_from_lighthouse`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/list#personalization_requests-is_from_lighthouse)boolean

[`listing_id`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/list#personalization_requests-listing_id)string

[`listing_name`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/list#personalization_requests-listing_name)string

[`metastore_id`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/list#personalization_requests-metastore_id)string

[`provider_id`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/list#personalization_requests-provider_id)string

[`recipient_type`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/list#personalization_requests-recipient_type)string

Enum: `DELTA_SHARING_RECIPIENT_TYPE_DATABRICKS | DELTA_SHARING_RECIPIENT_TYPE_OPEN`

[`share`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/list#personalization_requests-share)object

Share information is required for data listings but should be empty/ignored for non-data listings (MCP and App).

[`status`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/list#personalization_requests-status)string

Enum: `NEW | REQUEST_PENDING | FULFILLED | DENIED`

[`status_message`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/list#personalization_requests-status_message)string

[`updated_at`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/list#personalization_requests-updated_at)int64

 ]

# Response samples

200

{

"next_page_token":"string",

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
