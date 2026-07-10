Title: Create a personalization request | Consumer Personalization Requests API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/create

Markdown Content:
## Create a personalization request

Public preview

`POST/api/2.1/marketplace-consumer/listings/{listing_id}/personalization-requests`

Create a personalization request for a listing.

API scopes:[`marketplace`](https://docs.databricks.com/api/workspace/api/scopes#marketplace)

### Path parameters

[`listing_id`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/create#listing_id)required string

### Request body

Data request messages also creates a lead (maybe)

[`accepted_consumer_terms`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/create#accepted_consumer_terms)object

[`version`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/create#accepted_consumer_terms-version)required string

[`comment`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/create#comment)string

[`company`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/create#company)string

[`first_name`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/create#first_name)string

[`intended_use`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/create#intended_use)required string

[`is_from_lighthouse`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/create#is_from_lighthouse)boolean

[`last_name`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/create#last_name)string

[`recipient_type`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/create#recipient_type)string

Enum: `DELTA_SHARING_RECIPIENT_TYPE_DATABRICKS | DELTA_SHARING_RECIPIENT_TYPE_OPEN`

### Responses

**200** Request completed successfully.

Request completed successfully.

[`id`](https://docs.databricks.com/api/workspace/consumerpersonalizationrequests/create#id)string

# Request samples

JSON

{

"accepted_consumer_terms":{

"version":"string"

},

"comment":"string",

"company":"string",

"first_name":"string",

"intended_use":"string",

"is_from_lighthouse":true,

"last_name":"string",

"recipient_type":"DELTA_SHARING_RECIPIENT_TYPE_ DATABRICKS"

}

# Response samples

200

{

"id":"string"

}
