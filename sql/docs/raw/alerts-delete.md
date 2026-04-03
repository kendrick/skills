Title: Delete an alert | Alerts API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/alerts/delete

Markdown Content:
## Delete an alert

`DELETE/api/2.0/sql/alerts/{id}`

Moves an alert to the trash. Trashed alerts immediately disappear from searches and list views, and can no longer trigger. You can restore a trashed alert through the UI. A trashed alert is permanently deleted after 30 days.

API scopes (preview):[`sql`](https://docs.databricks.com/api/workspace/api/scopes#sql)

### Path parameters

[`id`](https://docs.databricks.com/api/workspace/alerts/delete#id)required string

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

UNAUTHENTICATED

Request does not have valid authentication credentials for the operation.

403

PERMISSION_DENIED

Caller does not have permission to execute the specified operation.

404

NOT_FOUND

Operation was performed on a resource that does not exist.

500

INTERNAL_SERVER_ERROR

Internal error.

# Response samples

200

{}
