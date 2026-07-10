Title: List conversations in a Genie Space | Genie API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/genie/listconversations

Markdown Content:
## List conversations in a Genie Space

`GET/api/2.0/genie/spaces/{space_id}/conversations`

Get a list of conversations in a Genie Space.

API scopes:[`genie`](https://docs.databricks.com/api/workspace/api/scopes#genie)

### Path parameters

[`space_id`](https://docs.databricks.com/api/workspace/genie/listconversations#space_id)required uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

The ID of the Genie space to retrieve conversations from.

### Query parameters

[`page_size`](https://docs.databricks.com/api/workspace/genie/listconversations#page_size)int32

<= 100 

Default`20`

Maximum number of conversations to return per page

[`page_token`](https://docs.databricks.com/api/workspace/genie/listconversations#page_token)string

Token to get the next page of results

[`include_all`](https://docs.databricks.com/api/workspace/genie/listconversations#include_all)boolean

Default`false`

Include all conversations in the space across all users. Requires at least CAN MANAGE permission on the space.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`conversations`](https://docs.databricks.com/api/workspace/genie/listconversations#conversations)Array of object

List of conversations in the Genie space

Array [

[`conversation_id`](https://docs.databricks.com/api/workspace/genie/listconversations#conversations-conversation_id)uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

[`created_timestamp`](https://docs.databricks.com/api/workspace/genie/listconversations#conversations-created_timestamp)int64

[`title`](https://docs.databricks.com/api/workspace/genie/listconversations#conversations-title)string

Example`"Biggest open opportunities"`

 ]

[`next_page_token`](https://docs.databricks.com/api/workspace/genie/listconversations#next_page_token)string

Token to get the next page of results

 This method might return the following HTTP codes: 400, 401, 403, 404, 500

Error responses are returned in the following format:

{

"error_code":"Error code",

"message":"Human-readable error message."

}

# Possible error codes:

HTTP code

error_code

Description

400

BAD_REQUEST

Request is invalid.

401

UNAUTHORIZED

The request does not have valid authentication credentials for the operation.

403

PERMISSION_DENIED

Caller does not have permission to execute the specified operation.

404

NOT_FOUND

Operation was performed on a resource that does not exist.

500

INTERNAL_ERROR

Internal error.

# Response samples

200

{

"conversations":[

{

"conversation_id":"e1ef34712a29169db030324f d0e1df5f",

"created_timestamp":0,

"title":"Biggest open opportunities"

}

],

"next_page_token":"string"

}
