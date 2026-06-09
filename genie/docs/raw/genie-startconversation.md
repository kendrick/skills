Title: Start conversation | Genie API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/genie/startconversation

Markdown Content:
## Start conversation

`POST/api/2.0/genie/spaces/{space_id}/start-conversation`

Start a new conversation.

API scopes:[`genie`](https://docs.databricks.com/api/workspace/api/scopes#genie)

### Path parameters

[`space_id`](https://docs.databricks.com/api/workspace/genie/startconversation#space_id)required uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

The ID associated with the Genie space where you want to start a conversation.

### Request body

[`content`](https://docs.databricks.com/api/workspace/genie/startconversation#content)required string

Example`"Biggest open opportunities"`

The text of the message that starts the conversation.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`conversation`](https://docs.databricks.com/api/workspace/genie/startconversation#conversation)object

[`conversation_id`](https://docs.databricks.com/api/workspace/genie/startconversation#conversation-conversation_id)uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

Conversation ID

[`created_timestamp`](https://docs.databricks.com/api/workspace/genie/startconversation#conversation-created_timestamp)int64

Timestamp when the message was created

[`id`](https://docs.databricks.com/api/workspace/genie/startconversation#conversation-id)uuid

Deprecated

Example`"e1ef34712a29169db030324fd0e1df5f"`

Conversation ID. Legacy identifier, use conversation_id instead

[`last_updated_timestamp`](https://docs.databricks.com/api/workspace/genie/startconversation#conversation-last_updated_timestamp)int64

Timestamp when the message was last updated

[`space_id`](https://docs.databricks.com/api/workspace/genie/startconversation#conversation-space_id)uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

Genie space ID

[`title`](https://docs.databricks.com/api/workspace/genie/startconversation#conversation-title)string

Conversation title

[`user_id`](https://docs.databricks.com/api/workspace/genie/startconversation#conversation-user_id)uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

ID of the user who created the conversation

[`conversation_id`](https://docs.databricks.com/api/workspace/genie/startconversation#conversation_id)uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

Conversation ID

[`message`](https://docs.databricks.com/api/workspace/genie/startconversation#message)object

[`attachments`](https://docs.databricks.com/api/workspace/genie/startconversation#message-attachments)Array of object

AI-generated response to the message

[`content`](https://docs.databricks.com/api/workspace/genie/startconversation#message-content)string

Example`"Biggest open opportunities"`

User message content

[`conversation_id`](https://docs.databricks.com/api/workspace/genie/startconversation#message-conversation_id)uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

Conversation ID

[`created_timestamp`](https://docs.databricks.com/api/workspace/genie/startconversation#message-created_timestamp)int64

Timestamp when the message was created

[`error`](https://docs.databricks.com/api/workspace/genie/startconversation#message-error)object

Error message if Genie failed to respond to the message

[`feedback`](https://docs.databricks.com/api/workspace/genie/startconversation#message-feedback)object

User feedback for the message if provided

[`id`](https://docs.databricks.com/api/workspace/genie/startconversation#message-id)uuid

Deprecated

Example`"e1ef34712a29169db030324fd0e1df5f"`

Message ID. Legacy identifier, use message_id instead

[`last_updated_timestamp`](https://docs.databricks.com/api/workspace/genie/startconversation#message-last_updated_timestamp)int64

Timestamp when the message was last updated

[`message_id`](https://docs.databricks.com/api/workspace/genie/startconversation#message-message_id)uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

Message ID

[`query_result`](https://docs.databricks.com/api/workspace/genie/startconversation#message-query_result)object

Deprecated

The result of SQL query if the message includes a query attachment. Deprecated. Use `query_result_metadata` in `GenieQueryAttachment` instead.

[`space_id`](https://docs.databricks.com/api/workspace/genie/startconversation#message-space_id)uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

Genie space ID

[`status`](https://docs.databricks.com/api/workspace/genie/startconversation#message-status)string

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

[`user_id`](https://docs.databricks.com/api/workspace/genie/startconversation#message-user_id)int64

ID of the user who created the message

[`message_id`](https://docs.databricks.com/api/workspace/genie/startconversation#message_id)uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

Message ID

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

FEATURE_DISABLED

If a given user/entity is trying to use a feature which has been disabled.

500

INTERNAL_ERROR

Internal error.

# Request samples

JSON

{

"content":"Give me top sales for last month"

}

# Response samples

200

{

"conversation":{

"created_timestamp":1719769718,

"id":"6a64adad2e664ee58de08488f986af3e",

"last_updated_timestamp":1719769718,

"space_id":"3c409c00b54a44c79f79da06b82460e2",

"title":"Give me top sales for last month",

"user_id":12345

},

"message":{

"attachments":null,

"content":"Give me top sales for last month",

"conversation_id":"6a64adad2e664ee58de08488f9 86af3e",

"created_timestamp":1719769718,

"error":null,

"last_updated_timestamp":1719769718,

"message_id":"e1ef34712a29169db030324fd0e1df5 f",

"space_id":"3c409c00b54a44c79f79da06b82460e2",

"status":"IN_PROGRESS",

"user_id":12345

}

}
