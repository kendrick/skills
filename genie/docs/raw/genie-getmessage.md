Title: Get conversation message | Genie API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/genie/getmessage

Markdown Content:
## Get conversation message

`GET/api/2.0/genie/spaces/{space_id}/conversations/{conversation_id}/messages/{message_id}`

Get message from conversation.

API scopes:[`genie`](https://docs.databricks.com/api/workspace/api/scopes#genie)

### Path parameters

[`space_id`](https://docs.databricks.com/api/workspace/genie/getmessage#space_id)required uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

The ID associated with the Genie space where the target conversation is located.

[`conversation_id`](https://docs.databricks.com/api/workspace/genie/getmessage#conversation_id)required uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

The ID associated with the target conversation.

[`message_id`](https://docs.databricks.com/api/workspace/genie/getmessage#message_id)required uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

The ID associated with the target message from the identified conversation.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`attachments`](https://docs.databricks.com/api/workspace/genie/getmessage#attachments)Array of object

AI-generated response to the message

Array [

[`attachment_id`](https://docs.databricks.com/api/workspace/genie/getmessage#attachments-attachment_id)string

Attachment ID

[`query`](https://docs.databricks.com/api/workspace/genie/getmessage#attachments-query)object

Query Attachment if Genie responds with a SQL query

[`suggested_questions`](https://docs.databricks.com/api/workspace/genie/getmessage#attachments-suggested_questions)object

Follow-up questions suggested by Genie

[`text`](https://docs.databricks.com/api/workspace/genie/getmessage#attachments-text)object

Text Attachment if Genie responds with text This also contains the final summary when available.

 ]

[`content`](https://docs.databricks.com/api/workspace/genie/getmessage#content)string

Example`"Biggest open opportunities"`

User message content

[`conversation_id`](https://docs.databricks.com/api/workspace/genie/getmessage#conversation_id)uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

Conversation ID

[`created_timestamp`](https://docs.databricks.com/api/workspace/genie/getmessage#created_timestamp)int64

Timestamp when the message was created

[`error`](https://docs.databricks.com/api/workspace/genie/getmessage#error)object

Error message if Genie failed to respond to the message

[`error`](https://docs.databricks.com/api/workspace/genie/getmessage#error-error)string

[`type`](https://docs.databricks.com/api/workspace/genie/getmessage#error-type)string

Enum: `UNEXPECTED_REPLY_PROCESS_EXCEPTION | GENERIC_CHAT_COMPLETION_EXCEPTION | CONTEXT_EXCEEDED_EXCEPTION | DEPLOYMENT_NOT_FOUND_EXCEPTION | FUNCTIONS_NOT_AVAILABLE_EXCEPTION | INVALID_COMPLETION_REQUEST_EXCEPTION | CONTENT_FILTER_EXCEPTION | FUNCTION_ARGUMENTS_INVALID_JSON_EXCEPTION | RETRYABLE_PROCESSING_EXCEPTION | INVALID_FUNCTION_CALL_EXCEPTION | LOCAL_CONTEXT_EXCEEDED_EXCEPTION | CHAT_COMPLETION_NETWORK_EXCEPTION | INVALID_CHAT_COMPLETION_JSON_EXCEPTION | GENERIC_CHAT_COMPLETION_SERVICE_EXCEPTION | WAREHOUSE_ACCESS_MISSING_EXCEPTION | WAREHOUSE_NOT_FOUND_EXCEPTION | NO_TABLES_TO_QUERY_EXCEPTION | SQL_EXECUTION_EXCEPTION | REPLY_PROCESS_TIMEOUT_EXCEPTION | COULD_NOT_GET_UC_SCHEMA_EXCEPTION | INVALID_TABLE_IDENTIFIER_EXCEPTION | TOO_MANY_TABLES_EXCEPTION | FUNCTION_ARGUMENTS_INVALID_EXCEPTION | GENERIC_SQL_EXEC_API_CALL_EXCEPTION | CHAT_COMPLETION_CLIENT_EXCEPTION | CHAT_COMPLETION_CLIENT_TIMEOUT_EXCEPTION | UNKNOWN_AI_MODEL | TABLES_MISSING_EXCEPTION | MESSAGE_DELETED_WHILE_EXECUTING_EXCEPTION | MESSAGE_UPDATED_WHILE_EXECUTING_EXCEPTION | BLOCK_MULTIPLE_EXECUTIONS_EXCEPTION | INVALID_CERTIFIED_ANSWER_IDENTIFIER_EXCEPTION | TOO_MANY_CERTIFIED_ANSWERS_EXCEPTION | RATE_LIMIT_EXCEEDED_GENERIC_EXCEPTION | RATE_LIMIT_EXCEEDED_SPECIFIED_WAIT_EXCEPTION | FUNCTION_CALL_MISSING_PARAMETER_EXCEPTION | INVALID_CERTIFIED_ANSWER_FUNCTION_EXCEPTION | ILLEGAL_PARAMETER_DEFINITION_EXCEPTION | NO_QUERY_TO_VISUALIZE_EXCEPTION | NO_DEPLOYMENTS_AVAILABLE_TO_WORKSPACE | STOP_PROCESS_DUE_TO_AUTO_REGENERATE | FUNCTION_ARGUMENTS_INVALID_TYPE_EXCEPTION | MESSAGE_CANCELLED_WHILE_EXECUTING_EXCEPTION | COULD_NOT_GET_MODEL_DEPLOYMENTS_EXCEPTION | GENERATED_SQL_QUERY_TOO_LONG_EXCEPTION | MISSING_SQL_QUERY_EXCEPTION | DESCRIBE_QUERY_UNEXPECTED_FAILURE | DESCRIBE_QUERY_TIMEOUT | DESCRIBE_QUERY_INVALID_SQL_ERROR | INVALID_SQL_UNKNOWN_TABLE_EXCEPTION | INVALID_SQL_MULTIPLE_STATEMENTS_EXCEPTION | INVALID_SQL_MULTIPLE_DATASET_REFERENCES_EXCEPTION | MESSAGE_ATTACHMENT_TOO_LONG_ERROR | INTERNAL_CATALOG_PATH_OVERLAP_EXCEPTION | INTERNAL_CATALOG_MISSING_UC_PATH_EXCEPTION | EXCEEDED_MAX_TOKEN_LENGTH_EXCEPTION | INTERNAL_CATALOG_ASSET_CREATION_ONGOING_EXCEPTION | INTERNAL_CATALOG_ASSET_CREATION_FAILED_EXCEPTION | INTERNAL_CATALOG_ASSET_CREATION_UNSUPPORTED_EXCEPTION | UNSUPPORTED_CONVERSATION_TYPE_EXCEPTION | COULD_NOT_GET_DASHBOARD_SCHEMA_EXCEPTION`

[`feedback`](https://docs.databricks.com/api/workspace/genie/getmessage#feedback)object

User feedback for the message if provided

[`comment`](https://docs.databricks.com/api/workspace/genie/getmessage#feedback-comment)string

Public preview

Optional feedback comment text

[`rating`](https://docs.databricks.com/api/workspace/genie/getmessage#feedback-rating)string

Enum: `POSITIVE | NEGATIVE | NONE`

The feedback rating

[`id`](https://docs.databricks.com/api/workspace/genie/getmessage#id)uuid

Deprecated

Example`"e1ef34712a29169db030324fd0e1df5f"`

Message ID. Legacy identifier, use message_id instead

[`last_updated_timestamp`](https://docs.databricks.com/api/workspace/genie/getmessage#last_updated_timestamp)int64

Timestamp when the message was last updated

[`message_id`](https://docs.databricks.com/api/workspace/genie/getmessage#message_id)uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

Message ID

[`query_result`](https://docs.databricks.com/api/workspace/genie/getmessage#query_result)object

Deprecated

The result of SQL query if the message includes a query attachment. Deprecated. Use `query_result_metadata` in `GenieQueryAttachment` instead.

[`is_truncated`](https://docs.databricks.com/api/workspace/genie/getmessage#query_result-is_truncated)boolean

If result is truncated

[`row_count`](https://docs.databricks.com/api/workspace/genie/getmessage#query_result-row_count)int64

Row count of the result

[`statement_id`](https://docs.databricks.com/api/workspace/genie/getmessage#query_result-statement_id)string

Statement Execution API statement id. Use [Get status, manifest, and result first chunk](https://docs.databricks.com/api/workspace/statementexecution/getstatement) to get the full result data.

[`statement_id_signature`](https://docs.databricks.com/api/workspace/genie/getmessage#query_result-statement_id_signature)string

JWT corresponding to the statement contained in this result

[`space_id`](https://docs.databricks.com/api/workspace/genie/getmessage#space_id)uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

Genie space ID

[`status`](https://docs.databricks.com/api/workspace/genie/getmessage#status)string

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

[`user_id`](https://docs.databricks.com/api/workspace/genie/getmessage#user_id)int64

ID of the user who created the message

 This method might return the following HTTP codes: 401, 403, 404, 500

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

Message created

{

"attachments":null,

"content":"Give me top sales for last month",

"conversation_id":"6a64adad2e664ee58de08488f986 af3e",

"created_timestamp":1719769718,

"error":null,

"last_updated_timestamp":1719769718,

"message_id":"e1ef34712a29169db030324fd0e1df5f",

"space_id":"3c409c00b54a44c79f79da06b82460e2",

"status":"IN_PROGRESS",

"user_id":12345

}
