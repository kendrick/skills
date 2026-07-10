Title: Update the email and webhook notification settings for an endpoint | Serving endpoints API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/servingendpoints/updatenotifications

Markdown Content:
## Update the email and webhook notification settings for an endpoint

`PATCH/api/2.0/serving-endpoints/{name}/notifications`

Updates the email and webhook notification settings for an endpoint.

API scopes (preview):[`model-serving`](https://docs.databricks.com/api/workspace/api/scopes#model-serving)

### Path parameters

[`name`](https://docs.databricks.com/api/workspace/servingendpoints/updatenotifications#name)required string

[ 1 .. 63 ] characters 

Example`"my-endpoint"`

The name of the serving endpoint whose notifications are being updated. This field is required.

### Request body

[`email_notifications`](https://docs.databricks.com/api/workspace/servingendpoints/updatenotifications#email_notifications)object

The email notification settings to update. Specify email addresses to notify when endpoint state changes occur.

[`on_update_failure`](https://docs.databricks.com/api/workspace/servingendpoints/updatenotifications#email_notifications-on_update_failure)Array of string

A list of email addresses to be notified when an endpoint fails to update its configuration or state.

[`on_update_success`](https://docs.databricks.com/api/workspace/servingendpoints/updatenotifications#email_notifications-on_update_success)Array of string

A list of email addresses to be notified when an endpoint successfully updates its configuration or state.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`email_notifications`](https://docs.databricks.com/api/workspace/servingendpoints/updatenotifications#email_notifications)object

[`on_update_failure`](https://docs.databricks.com/api/workspace/servingendpoints/updatenotifications#email_notifications-on_update_failure)Array of string

A list of email addresses to be notified when an endpoint fails to update its configuration or state.

[`on_update_success`](https://docs.databricks.com/api/workspace/servingendpoints/updatenotifications#email_notifications-on_update_success)Array of string

A list of email addresses to be notified when an endpoint successfully updates its configuration or state.

[`name`](https://docs.databricks.com/api/workspace/servingendpoints/updatenotifications#name)string

 This method might return the following HTTP codes: 400, 401, 500

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

500

INTERNAL_ERROR

Internal error.

# Request samples

JSON

{

"email_notifications":{

"on_update_failure":[

"user.name@databricks.com"

],

"on_update_success":[

"user.name@databricks.com"

]

}

}

# Response samples

200

{

"email_notifications":{

"on_update_failure":[

"user.name@databricks.com"

],

"on_update_success":[

"user.name@databricks.com"

]

},

"name":"string"

}
