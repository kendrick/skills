Title: List alerts | Alerts API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/alerts/list

Markdown Content:
## List alerts

`GET/api/2.0/sql/alerts`

Gets a list of alerts accessible to the user, ordered by creation time. Warning: Calling this API concurrently 10 or more times could result in throttling, service degradation, or a temporary ban.

API scopes (preview):[`sql`](https://docs.databricks.com/api/workspace/api/scopes#sql)

### Query parameters

[`page_token`](https://docs.databricks.com/api/workspace/alerts/list#page_token)string

[`page_size`](https://docs.databricks.com/api/workspace/alerts/list#page_size)int32

<= 100 

Default`20`

### Responses

**200** Request completed successfully. The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

Request completed successfully.

 The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

[`next_page_token`](https://docs.databricks.com/api/workspace/alerts/list#next_page_token)string

[`results`](https://docs.databricks.com/api/workspace/alerts/list#results)Array of object

Array [

[`condition`](https://docs.databricks.com/api/workspace/alerts/list#results-condition)object

Trigger conditions of the alert.

[`create_time`](https://docs.databricks.com/api/workspace/alerts/list#results-create_time)date-time

The timestamp indicating when the alert was created.

[`custom_body`](https://docs.databricks.com/api/workspace/alerts/list#results-custom_body)string

Example`"custom body"`

Custom body of alert notification, if it exists. See [here](https://docs.databricks.com/sql/user/alerts/index.html) for custom templating instructions.

[`custom_subject`](https://docs.databricks.com/api/workspace/alerts/list#results-custom_subject)string

Example`"custom subject"`

Custom subject of alert notification, if it exists. This can include email subject entries and Slack notification headers, for example. See [here](https://docs.databricks.com/sql/user/alerts/index.html) for custom templating instructions.

[`display_name`](https://docs.databricks.com/api/workspace/alerts/list#results-display_name)string

Example`"Example alert"`

The display name of the alert.

[`id`](https://docs.databricks.com/api/workspace/alerts/list#results-id)string

Example`"fe25e731-92f2-4838-9fb2-1ca364320a3d"`

UUID identifying the alert.

[`lifecycle_state`](https://docs.databricks.com/api/workspace/alerts/list#results-lifecycle_state)string

Enum: `ACTIVE | TRASHED`

Example`"ACTIVE"`

The workspace state of the alert. Used for tracking trashed status.

[`notify_on_ok`](https://docs.databricks.com/api/workspace/alerts/list#results-notify_on_ok)boolean

Whether to notify alert subscribers when alert returns back to normal.

[`owner_user_name`](https://docs.databricks.com/api/workspace/alerts/list#results-owner_user_name)string

Example`"user@acme.com"`

The owner's username. This field is set to "Unavailable" if the user has been deleted.

[`query_id`](https://docs.databricks.com/api/workspace/alerts/list#results-query_id)string

Example`"dee5cca8-1c79-4b5e-a711-e7f9d241bdf6"`

UUID of the query attached to the alert.

[`seconds_to_retrigger`](https://docs.databricks.com/api/workspace/alerts/list#results-seconds_to_retrigger)int32

Example`0`

Number of seconds an alert must wait after being triggered to rearm itself. After rearming, it can be triggered again. If 0 or not specified, the alert will not be triggered again.

[`state`](https://docs.databricks.com/api/workspace/alerts/list#results-state)string

Enum: `UNKNOWN | OK | TRIGGERED`

Example`"UNKNOWN"`

Current state of the alert's trigger status. This field is set to UNKNOWN if the alert has not yet been evaluated or ran into an error during the last evaluation.

[`trigger_time`](https://docs.databricks.com/api/workspace/alerts/list#results-trigger_time)date-time

Timestamp when the alert was last triggered, if the alert has been triggered before.

[`update_time`](https://docs.databricks.com/api/workspace/alerts/list#results-update_time)date-time

The timestamp indicating when the alert was updated.

 ]

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

INTERNAL_SERVER_ERROR

Internal error.

# Response samples

200

{

"next_page_token":"eDg",

"results":[

{

"condition":{

"op":"GREATER_THAN",

"operand":{

"column":{

"name":"foo"

}

},

"threshold":{

"value":{

"double_value":1

}

}

},

"create_time":"2019-08-24T14:15:22Z",

"display_name":"Test alert 1",

"id":"fe25e731-92f2-4838-9fb2-1ca364320a3d",

"lifecycle_state":"ACTIVE",

"owner_user_name":"user.name@acme.com",

"query_id":"dee5cca8-1c79-4b5e-a711-e7f9d24 1bdf6",

"seconds_to_retrigger":0,

"state":"OK",

"update_time":"2019-08-24T14:15:22Z"

},

{

"condition":{

"op":"EQUAL",

"operand":{

"column":{

"name":"bar"

}

},

"threshold":{

"value":{

"bool_value":true

}

}

},

"create_time":"2019-08-24T14:15:22Z",

"display_name":"Test alert 2",

"id":"2cca1687-60ff-4886-a445-0230578c864d",

"lifecycle_state":"ACTIVE",

"owner_user_name":"user.name@acme.com",

"query_id":"0c205e24-5db2-4940-adb1-fb13c7c e960b",

"seconds_to_retrigger":0,

"state":"OK",

"update_time":"2019-08-24T14:15:22Z"

}

]

}
