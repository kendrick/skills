Title: All personalization requests across all listings | Provider Personalization Requests API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/providerpersonalizationrequests/list

Markdown Content:
## All personalization requests across all listings

Public preview

`GET/api/2.0/marketplace-provider/personalization-requests`

`GET/api/2.1/marketplace-provider/personalization-requests`

List personalization requests to this provider. This will return all personalization requests, regardless of which listing they are for.

API scopes:[`marketplace`](https://docs.databricks.com/api/workspace/api/scopes#marketplace)

### Query parameters

[`page_token`](https://docs.databricks.com/api/workspace/providerpersonalizationrequests/list#page_token)string

[`page_size`](https://docs.databricks.com/api/workspace/providerpersonalizationrequests/list#page_size)int32

### Responses

**200** Request completed successfully. The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

Request completed successfully.

 The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

[`next_page_token`](https://docs.databricks.com/api/workspace/providerpersonalizationrequests/list#next_page_token)string

[`personalization_requests`](https://docs.databricks.com/api/workspace/providerpersonalizationrequests/list#personalization_requests)Array of object

Array [

[`comment`](https://docs.databricks.com/api/workspace/providerpersonalizationrequests/list#personalization_requests-comment)string

[`consumer_region`](https://docs.databricks.com/api/workspace/providerpersonalizationrequests/list#personalization_requests-consumer_region)object

[`contact_info`](https://docs.databricks.com/api/workspace/providerpersonalizationrequests/list#personalization_requests-contact_info)object

contact info for the consumer requesting data or performing a listing installation

[`created_at`](https://docs.databricks.com/api/workspace/providerpersonalizationrequests/list#personalization_requests-created_at)int64

[`id`](https://docs.databricks.com/api/workspace/providerpersonalizationrequests/list#personalization_requests-id)string

[`intended_use`](https://docs.databricks.com/api/workspace/providerpersonalizationrequests/list#personalization_requests-intended_use)string

[`is_from_lighthouse`](https://docs.databricks.com/api/workspace/providerpersonalizationrequests/list#personalization_requests-is_from_lighthouse)boolean

[`listing_id`](https://docs.databricks.com/api/workspace/providerpersonalizationrequests/list#personalization_requests-listing_id)string

[`listing_name`](https://docs.databricks.com/api/workspace/providerpersonalizationrequests/list#personalization_requests-listing_name)string

[`metastore_id`](https://docs.databricks.com/api/workspace/providerpersonalizationrequests/list#personalization_requests-metastore_id)string

[`provider_id`](https://docs.databricks.com/api/workspace/providerpersonalizationrequests/list#personalization_requests-provider_id)string

[`recipient_type`](https://docs.databricks.com/api/workspace/providerpersonalizationrequests/list#personalization_requests-recipient_type)string

Enum: `DELTA_SHARING_RECIPIENT_TYPE_DATABRICKS | DELTA_SHARING_RECIPIENT_TYPE_OPEN`

[`share`](https://docs.databricks.com/api/workspace/providerpersonalizationrequests/list#personalization_requests-share)object

Share information is required for data listings but should be empty/ignored for non-data listings (MCP and App).

[`status`](https://docs.databricks.com/api/workspace/providerpersonalizationrequests/list#personalization_requests-status)string

Enum: `NEW | REQUEST_PENDING | FULFILLED | DENIED`

[`status_message`](https://docs.databricks.com/api/workspace/providerpersonalizationrequests/list#personalization_requests-status_message)string

[`updated_at`](https://docs.databricks.com/api/workspace/providerpersonalizationrequests/list#personalization_requests-updated_at)int64

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
