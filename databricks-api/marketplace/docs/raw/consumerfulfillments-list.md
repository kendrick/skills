Title: List all listing fulfillments | Consumer Fulfillments API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/consumerfulfillments/list

Markdown Content:
## List all listing fulfillments

Public preview

`GET/api/2.1/marketplace-consumer/listings/{listing_id}/fulfillments`

Get all listings fulfillments associated with a listing. A _fulfillment_ is a potential installation. Standard installations contain metadata about the attached share or git repo. Only one of these fields will be present. Personalized installations contain metadata about the attached share or git repo, as well as the Delta Sharing recipient type.

API scopes:[`marketplace`](https://docs.databricks.com/api/workspace/api/scopes#marketplace)

### Path parameters

[`listing_id`](https://docs.databricks.com/api/workspace/consumerfulfillments/list#listing_id)required string

### Query parameters

[`page_token`](https://docs.databricks.com/api/workspace/consumerfulfillments/list#page_token)string

[`page_size`](https://docs.databricks.com/api/workspace/consumerfulfillments/list#page_size)int32

### Responses

**200** Request completed successfully. The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

Request completed successfully.

 The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

[`fulfillments`](https://docs.databricks.com/api/workspace/consumerfulfillments/list#fulfillments)Array of object

Array [

[`fulfillment_type`](https://docs.databricks.com/api/workspace/consumerfulfillments/list#fulfillments-fulfillment_type)string

Enum: `REQUEST_ACCESS | INSTALL`

[`listing_id`](https://docs.databricks.com/api/workspace/consumerfulfillments/list#fulfillments-listing_id)string

[`recipient_type`](https://docs.databricks.com/api/workspace/consumerfulfillments/list#fulfillments-recipient_type)string

Enum: `DELTA_SHARING_RECIPIENT_TYPE_DATABRICKS | DELTA_SHARING_RECIPIENT_TYPE_OPEN`

[`repo_info`](https://docs.databricks.com/api/workspace/consumerfulfillments/list#fulfillments-repo_info)object

[`share_info`](https://docs.databricks.com/api/workspace/consumerfulfillments/list#fulfillments-share_info)object

 ]

[`next_page_token`](https://docs.databricks.com/api/workspace/consumerfulfillments/list#next_page_token)string

# Response samples

200

{

"fulfillments":[

{

"fulfillment_type":"REQUEST_ACCESS",

"listing_id":"string",

"recipient_type":"DELTA_SHARING_RECIPIENT_T YPE_DATABRICKS",

"repo_info":{

"git_repo_url":"string"

},

"share_info":{

"name":"string",

"type":"SAMPLE"

}

}

],

"next_page_token":"string"

}
