Title: Delete conversation message | Genie API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/genie/deleteconversationmessage

Markdown Content:
## Delete conversation message

`DELETE/api/2.0/genie/spaces/{space_id}/conversations/{conversation_id}/messages/{message_id}`

Delete a conversation message.

API scopes:[`genie`](https://docs.databricks.com/api/workspace/api/scopes#genie)

### Path parameters

[`space_id`](https://docs.databricks.com/api/workspace/genie/deleteconversationmessage#space_id)required uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

The ID associated with the Genie space where the message is located.

[`conversation_id`](https://docs.databricks.com/api/workspace/genie/deleteconversationmessage#conversation_id)required uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

The ID associated with the conversation.

[`message_id`](https://docs.databricks.com/api/workspace/genie/deleteconversationmessage#message_id)required uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

The ID associated with the message to delete.

### Responses

**200** Request completed successfully.

Request completed successfully.

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

{}
