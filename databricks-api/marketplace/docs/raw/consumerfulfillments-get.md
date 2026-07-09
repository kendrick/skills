Title: Get listing content metadata | Consumer Fulfillments API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/consumerfulfillments/get

Markdown Content:
## Get listing content metadata

Public preview

`GET/api/2.1/marketplace-consumer/listings/{listing_id}/content`

Get a high level preview of the metadata of listing installable content.

API scopes:[`marketplace`](https://docs.databricks.com/api/workspace/api/scopes#marketplace)

### Path parameters

[`listing_id`](https://docs.databricks.com/api/workspace/consumerfulfillments/get#listing_id)required string

### Query parameters

[`page_token`](https://docs.databricks.com/api/workspace/consumerfulfillments/get#page_token)string

[`page_size`](https://docs.databricks.com/api/workspace/consumerfulfillments/get#page_size)int32

### Responses

**200** Request completed successfully. The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

Request completed successfully.

 The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

[`next_page_token`](https://docs.databricks.com/api/workspace/consumerfulfillments/get#next_page_token)string

[`shared_data_objects`](https://docs.databricks.com/api/workspace/consumerfulfillments/get#shared_data_objects)Array of object

Array [

[`data_object_type`](https://docs.databricks.com/api/workspace/consumerfulfillments/get#shared_data_objects-data_object_type)string

The type of the data object. Could be one of: TABLE, SCHEMA, NOTEBOOK_FILE, MODEL, VOLUME

[`name`](https://docs.databricks.com/api/workspace/consumerfulfillments/get#shared_data_objects-name)string

Name of the shared object

 ]

# Response samples

200

{

"next_page_token":"string",

"shared_data_objects":[

{

"data_object_type":"string",

"name":"string"

}

]

}
