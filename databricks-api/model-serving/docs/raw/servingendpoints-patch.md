Title: Update tags of a serving endpoint | Serving endpoints API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/servingendpoints/patch

Markdown Content:
## Update tags of a serving endpoint

`PATCH/api/2.0/serving-endpoints/{name}/tags`

Used to batch add and delete tags from a serving endpoint with a single API call.

API scopes (preview):[`model-serving`](https://docs.databricks.com/api/workspace/api/scopes#model-serving)

### Path parameters

[`name`](https://docs.databricks.com/api/workspace/servingendpoints/patch#name)required string

[ 1 .. 63 ] characters 

Example`"feed-ads"`

The name of the serving endpoint who's tags to patch. This field is required.

### Request body

[`add_tags`](https://docs.databricks.com/api/workspace/servingendpoints/patch#add_tags)Array of object

List of endpoint tags to add

Array [

[`key`](https://docs.databricks.com/api/workspace/servingendpoints/patch#add_tags-key)required string

Example`"team"`

Key field for a serving endpoint tag.

[`value`](https://docs.databricks.com/api/workspace/servingendpoints/patch#add_tags-value)string

Example`"data science"`

Optional value field for a serving endpoint tag.

 ]

[`delete_tags`](https://docs.databricks.com/api/workspace/servingendpoints/patch#delete_tags)Array of string

List of tag keys to delete

### Responses

**200** Request completed successfully.

Request completed successfully.

[`tags`](https://docs.databricks.com/api/workspace/servingendpoints/patch#tags)Array of object

Array [

[`key`](https://docs.databricks.com/api/workspace/servingendpoints/patch#tags-key)string

Example`"team"`

Key field for a serving endpoint tag.

[`value`](https://docs.databricks.com/api/workspace/servingendpoints/patch#tags-value)string

Example`"data science"`

Optional value field for a serving endpoint tag.

 ]

 This method might return the following HTTP codes: 401, 404, 500

Error responses are returned in the following format:

{

"error_code":"Error code",

"message":"Human-readable error message."

}

# Possible error codes:

HTTP code

error_code

Description

401

UNAUTHORIZED

The request does not have valid authentication credentials for the operation.

404

NOT_FOUND

Operation was performed on a resource that does not exist.

500

INTERNAL_ERROR

Internal error.

# Request samples

JSON

{

"add_tags":[

{

"key":"team",

"value":"data science"

}

],

"delete_tags":[

"string"

]

}

# Response samples

200

{

"tags":[

{

"key":"team",

"value":"data science"

}

]

}
