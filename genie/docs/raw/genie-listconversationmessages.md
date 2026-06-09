Title: List conversation messages | Genie API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/genie/listconversationmessages

Markdown Content:
## List conversation messages

`GET/api/2.0/genie/spaces/{space_id}/conversations/{conversation_id}/messages`

List messages in a conversation

API scopes:[`genie`](https://docs.databricks.com/api/workspace/api/scopes#genie)

### Path parameters

[`space_id`](https://docs.databricks.com/api/workspace/genie/listconversationmessages#space_id)required uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

The ID associated with the Genie space where the conversation is located

[`conversation_id`](https://docs.databricks.com/api/workspace/genie/listconversationmessages#conversation_id)required uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

The ID of the conversation to list messages from

### Query parameters

[`page_size`](https://docs.databricks.com/api/workspace/genie/listconversationmessages#page_size)int32

<= 100 

Optional

Default`20`

Maximum number of messages to return per page

[`page_token`](https://docs.databricks.com/api/workspace/genie/listconversationmessages#page_token)string Optional

Token to get the next page of results

### Responses

**200** Request completed successfully.

Request completed successfully.

[`messages`](https://docs.databricks.com/api/workspace/genie/listconversationmessages#messages)Array of object

List of messages in the conversation.

Array [

[`attachments`](https://docs.databricks.com/api/workspace/genie/listconversationmessages#messages-attachments)Array of object

AI-generated response to the message

[`content`](https://docs.databricks.com/api/workspace/genie/listconversationmessages#messages-content)string

Example`"Biggest open opportunities"`

User message content

[`conversation_id`](https://docs.databricks.com/api/workspace/genie/listconversationmessages#messages-conversation_id)uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

Conversation ID

[`created_timestamp`](https://docs.databricks.com/api/workspace/genie/listconversationmessages#messages-created_timestamp)int64

Timestamp when the message was created

[`error`](https://docs.databricks.com/api/workspace/genie/listconversationmessages#messages-error)object

Error message if Genie failed to respond to the message

[`feedback`](https://docs.databricks.com/api/workspace/genie/listconversationmessages#messages-feedback)object

User feedback for the message if provided

[`id`](https://docs.databricks.com/api/workspace/genie/listconversationmessages#messages-id)uuid

Deprecated

Example`"e1ef34712a29169db030324fd0e1df5f"`

Message ID. Legacy identifier, use message_id instead

[`last_updated_timestamp`](https://docs.databricks.com/api/workspace/genie/listconversationmessages#messages-last_updated_timestamp)int64

Timestamp when the message was last updated

[`message_id`](https://docs.databricks.com/api/workspace/genie/listconversationmessages#messages-message_id)uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

Message ID

[`query_result`](https://docs.databricks.com/api/workspace/genie/listconversationmessages#messages-query_result)object

Deprecated

The result of SQL query if the message includes a query attachment. Deprecated. Use `query_result_metadata` in `GenieQueryAttachment` instead.

[`space_id`](https://docs.databricks.com/api/workspace/genie/listconversationmessages#messages-space_id)uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

Genie space ID

[`status`](https://docs.databricks.com/api/workspace/genie/listconversationmessages#messages-status)string

Enum: `FETCHING_METADATA | FILTERING_CONTEXT | ASKING_AI | PENDING_WAREHOUSE | EXECUTING_QUERY | FAILED | COMPLETED | SUBMITTED | QUERY_RESULT_EXPIRED | CANCELLED`

Example`"ASKING_AI"`

MessageStatus. The possible values are:

*   `FETCHING_METADATA`: Fetching metadata from the data sources.
*   `FILTERING_CONTEXT`: Running smart context step to determine relevant context.
*   `ASKING_AI`: Waiting for the LLM to respond to the user's question.
*   `PENDING_WAREHOUSE`: Waiting for warehouse before the SQL query can start executing.
*   `EXECUTING_QUERY`: Executing a generated SQL query. Get the SQL query result by calling [getMessageAttachmentQueryResult](https://docs.databricks.com/api/workspace/genie/getmessageattachmentqueryresult) API.
*   `FAILED`: The response generation or query execution failed. See `error` field.
*   `COMPLETED`: Message processing is completed. Results are in the `attachments` field. Get the SQL query result by calling [getMessageAttachmentQueryResult](https://docs.databricks.com/api/workspace/genie/getmessageattachmentqueryresult) API.
*   `SUBMITTED`: Message has been submitted.
*   `QUERY_RESULT_EXPIRED`: SQL result is not available anymore. The user needs to rerun the query. Rerun the SQL query result by calling [executeMessageAttachmentQuery](https://docs.databricks.com/api/workspace/genie/executemessageattachmentquery) API.
*   `CANCELLED`: Message has been cancelled.

[`user_id`](https://docs.databricks.com/api/workspace/genie/listconversationmessages#messages-user_id)int64

ID of the user who created the message

 ]

[`next_page_token`](https://docs.databricks.com/api/workspace/genie/listconversationmessages#next_page_token)string

The token to use for retrieving the next page of results.

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

NOT_FOUND, FEATURE_DISABLED

NOT_FOUND - Operation was performed on a resource that does not exist. FEATURE_DISABLED - If a given user/entity is trying to use a feature which has been disabled.

500

INTERNAL_ERROR

Internal error.

# Response samples

200

{

"messages":[

{

"attachments":[

{

"attachment_id":"string",

"query":{

"description":"string",

"id":"string",

"last_updated_timestamp":0,

"parameters":[

{

"keyword":"string",

"sql_type":"string",

"value":"string"

}

],

"query":"string",

"query_result_metadata":{

"is_truncated":true,

"row_count":0

},

"statement_id":"string",

"thoughts":[

{

"content":"string",

"thought_type":"THOUGHT_TYPE_DESC RIPTION"

}

],

"title":"string"

},

"suggested_questions":{

"questions":[

"string"

]

},

"text":{

"content":"string",

"id":"string",

"purpose":"FOLLOW_UP_QUESTION"

}

}

],

"content":"Biggest open opportunities",

"conversation_id":"e1ef34712a29169db030324f d0e1df5f",

"created_timestamp":0,

"error":{

"error":"string",

"type":"UNEXPECTED_REPLY_PROCESS_EXCEPTIO N"

},

"feedback":{

"comment":"string",

"rating":"POSITIVE"

},

"id":"e1ef34712a29169db030324fd0e1df5f",

"last_updated_timestamp":0,

"message_id":"e1ef34712a29169db030324fd0e1d f5f",

"query_result":{

"is_truncated":true,

"row_count":0,

"statement_id":"string",

"statement_id_signature":"string"

},

"space_id":"e1ef34712a29169db030324fd0e1df5 f",

"status":"FETCHING_METADATA",

"user_id":0

}

],

"next_page_token":"string"

}
