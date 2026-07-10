Title: Update personalization request status | Provider Personalization Requests API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/providerpersonalizationrequests/update

Markdown Content:
## Update personalization request status

Public preview

`PUT/api/2.0/marketplace-provider/listings/{listing_id}/personalization-requests/{request_id}/request-status`

`PUT/api/2.1/marketplace-provider/listings/{listing_id}/personalization-requests/{request_id}/request-status`

Update personalization request. This method only permits updating the status of the request.

API scopes:[`marketplace`](https://docs.databricks.com/api/workspace/api/scopes#marketplace)

### Path parameters

[`listing_id`](https://docs.databricks.com/api/workspace/providerpersonalizationrequests/update#listing_id)required string

[`request_id`](https://docs.databricks.com/api/workspace/providerpersonalizationrequests/update#request_id)required string

### Request body

[`reason`](https://docs.databricks.com/api/workspace/providerpersonalizationrequests/update#reason)string

[`share`](https://docs.databricks.com/api/workspace/providerpersonalizationrequests/update#share)object

[`name`](https://docs.databricks.com/api/workspace/providerpersonalizationrequests/update#share-name)required string

[`type`](https://docs.databricks.com/api/workspace/providerpersonalizationrequests/update#share-type)required string

Enum: `SAMPLE | FULL`

[`status`](https://docs.databricks.com/api/workspace/providerpersonalizationrequests/update#status)required string

Enum: `NEW | REQUEST_PENDING | FULFILLED | DENIED`

### Responses

**200** Request completed successfully.

Request completed successfully.

[`request`](https://docs.databricks.com/api/workspace/providerpersonalizationrequests/update#request)object

[`comment`](https://docs.databricks.com/api/workspace/providerpersonalizationrequests/update#request-comment)string

[`consumer_region`](https://docs.databricks.com/api/workspace/providerpersonalizationrequests/update#request-consumer_region)object

[`contact_info`](https://docs.databricks.com/api/workspace/providerpersonalizationrequests/update#request-contact_info)object

contact info for the consumer requesting data or performing a listing installation

[`created_at`](https://docs.databricks.com/api/workspace/providerpersonalizationrequests/update#request-created_at)int64

[`id`](https://docs.databricks.com/api/workspace/providerpersonalizationrequests/update#request-id)string

[`intended_use`](https://docs.databricks.com/api/workspace/providerpersonalizationrequests/update#request-intended_use)string

[`is_from_lighthouse`](https://docs.databricks.com/api/workspace/providerpersonalizationrequests/update#request-is_from_lighthouse)boolean

[`listing_id`](https://docs.databricks.com/api/workspace/providerpersonalizationrequests/update#request-listing_id)string

[`listing_name`](https://docs.databricks.com/api/workspace/providerpersonalizationrequests/update#request-listing_name)string

[`metastore_id`](https://docs.databricks.com/api/workspace/providerpersonalizationrequests/update#request-metastore_id)string

[`provider_id`](https://docs.databricks.com/api/workspace/providerpersonalizationrequests/update#request-provider_id)string

[`recipient_type`](https://docs.databricks.com/api/workspace/providerpersonalizationrequests/update#request-recipient_type)string

Enum: `DELTA_SHARING_RECIPIENT_TYPE_DATABRICKS | DELTA_SHARING_RECIPIENT_TYPE_OPEN`

[`share`](https://docs.databricks.com/api/workspace/providerpersonalizationrequests/update#request-share)object

Share information is required for data listings but should be empty/ignored for non-data listings (MCP and App).

[`status`](https://docs.databricks.com/api/workspace/providerpersonalizationrequests/update#request-status)string

Enum: `NEW | REQUEST_PENDING | FULFILLED | DENIED`

[`status_message`](https://docs.databricks.com/api/workspace/providerpersonalizationrequests/update#request-status_message)string

[`updated_at`](https://docs.databricks.com/api/workspace/providerpersonalizationrequests/update#request-updated_at)int64

# Request samples

JSON

{

"reason":"string",

"share":{

"name":"string",

"type":"SAMPLE"

},

"status":"NEW"

}

# Response samples

200

{

"request":{

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

"recipient_type":"DELTA_SHARING_RECIPIENT_TYP E_DATABRICKS",

"share":{

"name":"string",

"type":"SAMPLE"

},

"status":"NEW",

"status_message":"string",

"updated_at":0

}

}
