Title: Update an alert | Alerts API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/alerts/update

Markdown Content:
## Update an alert

`PATCH/api/2.0/sql/alerts/{id}`

Updates an alert.

API scopes (preview):[`sql`](https://docs.databricks.com/api/workspace/api/scopes#sql)

### Path parameters

[`id`](https://docs.databricks.com/api/workspace/alerts/update#id)required string

### Request body

[`alert`](https://docs.databricks.com/api/workspace/alerts/update#alert)object

[`condition`](https://docs.databricks.com/api/workspace/alerts/update#alert-condition)object

Trigger conditions of the alert.

[`custom_body`](https://docs.databricks.com/api/workspace/alerts/update#alert-custom_body)string

Example`"custom body"`

Custom body of alert notification, if it exists. See [here](https://docs.databricks.com/sql/user/alerts/index.html) for custom templating instructions.

[`custom_subject`](https://docs.databricks.com/api/workspace/alerts/update#alert-custom_subject)string

Example`"custom subject"`

Custom subject of alert notification, if it exists. This can include email subject entries and Slack notification headers, for example. See [here](https://docs.databricks.com/sql/user/alerts/index.html) for custom templating instructions.

[`display_name`](https://docs.databricks.com/api/workspace/alerts/update#alert-display_name)string

Example`"Example alert"`

The display name of the alert.

[`notify_on_ok`](https://docs.databricks.com/api/workspace/alerts/update#alert-notify_on_ok)boolean

Whether to notify alert subscribers when alert returns back to normal.

[`owner_user_name`](https://docs.databricks.com/api/workspace/alerts/update#alert-owner_user_name)string

Example`"user@acme.com"`

The owner's username. This field is set to "Unavailable" if the user has been deleted.

[`query_id`](https://docs.databricks.com/api/workspace/alerts/update#alert-query_id)string

Example`"dee5cca8-1c79-4b5e-a711-e7f9d241bdf6"`

UUID of the query attached to the alert.

[`seconds_to_retrigger`](https://docs.databricks.com/api/workspace/alerts/update#alert-seconds_to_retrigger)int32

Example`0`

Number of seconds an alert must wait after being triggered to rearm itself. After rearming, it can be triggered again. If 0 or not specified, the alert will not be triggered again.

[`auto_resolve_display_name`](https://docs.databricks.com/api/workspace/alerts/update#auto_resolve_display_name)boolean

Default`true`

If true, automatically resolve alert display name conflicts. Otherwise, fail the request if the alert's display name conflicts with an existing alert's display name.

[`update_mask`](https://docs.databricks.com/api/workspace/alerts/update#update_mask)required string

The field mask must be a single string, with multiple fields separated by commas (no spaces). The field path is relative to the resource object, using a dot (`.`) to navigate sub-fields (e.g., `author.given_name`). Specification of elements in sequence or map fields is not allowed, as only the entire collection field can be specified. Field names must exactly match the resource field names.

A field mask of `*` indicates full replacement. It’s recommended to always explicitly list the fields being updated and avoid using `*` wildcards, as it can lead to unintended results if the API changes in the future.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`condition`](https://docs.databricks.com/api/workspace/alerts/update#condition)object

Trigger conditions of the alert.

[`empty_result_state`](https://docs.databricks.com/api/workspace/alerts/update#condition-empty_result_state)string

Enum: `UNKNOWN | OK | TRIGGERED`

Alert state if result is empty.

[`op`](https://docs.databricks.com/api/workspace/alerts/update#condition-op)string

Enum: `GREATER_THAN | GREATER_THAN_OR_EQUAL | LESS_THAN | LESS_THAN_OR_EQUAL | EQUAL | NOT_EQUAL | IS_NULL`

Operator used for comparison in alert evaluation.

[`operand`](https://docs.databricks.com/api/workspace/alerts/update#condition-operand)object

Name of the column from the query result to use for comparison in alert evaluation.

[`threshold`](https://docs.databricks.com/api/workspace/alerts/update#condition-threshold)object

Threshold value used for comparison in alert evaluation.

[`create_time`](https://docs.databricks.com/api/workspace/alerts/update#create_time)date-time

The timestamp indicating when the alert was created.

[`custom_body`](https://docs.databricks.com/api/workspace/alerts/update#custom_body)string

Example`"custom body"`

Custom body of alert notification, if it exists. See [here](https://docs.databricks.com/sql/user/alerts/index.html) for custom templating instructions.

[`custom_subject`](https://docs.databricks.com/api/workspace/alerts/update#custom_subject)string

Example`"custom subject"`

Custom subject of alert notification, if it exists. This can include email subject entries and Slack notification headers, for example. See [here](https://docs.databricks.com/sql/user/alerts/index.html) for custom templating instructions.

[`display_name`](https://docs.databricks.com/api/workspace/alerts/update#display_name)string

Example`"Example alert"`

The display name of the alert.

[`id`](https://docs.databricks.com/api/workspace/alerts/update#id)string

Example`"fe25e731-92f2-4838-9fb2-1ca364320a3d"`

UUID identifying the alert.

[`lifecycle_state`](https://docs.databricks.com/api/workspace/alerts/update#lifecycle_state)string

Enum: `ACTIVE | TRASHED`

Example`"ACTIVE"`

The workspace state of the alert. Used for tracking trashed status.

[`notify_on_ok`](https://docs.databricks.com/api/workspace/alerts/update#notify_on_ok)boolean

Whether to notify alert subscribers when alert returns back to normal.

[`owner_user_name`](https://docs.databricks.com/api/workspace/alerts/update#owner_user_name)string

Example`"user@acme.com"`

The owner's username. This field is set to "Unavailable" if the user has been deleted.

[`parent_path`](https://docs.databricks.com/api/workspace/alerts/update#parent_path)string

Example`"/Users/user@acme.com"`

The workspace path of the folder containing the alert.

[`query_id`](https://docs.databricks.com/api/workspace/alerts/update#query_id)string

Example`"dee5cca8-1c79-4b5e-a711-e7f9d241bdf6"`

UUID of the query attached to the alert.

[`seconds_to_retrigger`](https://docs.databricks.com/api/workspace/alerts/update#seconds_to_retrigger)int32

Example`0`

Number of seconds an alert must wait after being triggered to rearm itself. After rearming, it can be triggered again. If 0 or not specified, the alert will not be triggered again.

[`state`](https://docs.databricks.com/api/workspace/alerts/update#state)string

Enum: `UNKNOWN | OK | TRIGGERED`

Example`"UNKNOWN"`

Current state of the alert's trigger status. This field is set to UNKNOWN if the alert has not yet been evaluated or ran into an error during the last evaluation.

[`trigger_time`](https://docs.databricks.com/api/workspace/alerts/update#trigger_time)date-time

Timestamp when the alert was last triggered, if the alert has been triggered before.

[`update_time`](https://docs.databricks.com/api/workspace/alerts/update#update_time)date-time

The timestamp indicating when the alert was updated.

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

# Request samples

JSON

{

"alert":{

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

"display_name":"Renamed alert"

},

"update_mask":"display_name,condition"

}

# Response samples

200

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

"display_name":"Renamed alert",

"id":"fe25e731-92f2-4838-9fb2-1ca364320a3d",

"lifecycle_state":"ACTIVE",

"owner_user_name":"user.name@acme.com",

"parent_path":"/Workspace/Users/user.name@acme.com",

"query_id":"dee5cca8-1c79-4b5e-a711-e7f9d241bdf 6",

"seconds_to_retrigger":0,

"state":"OK",

"update_time":"2019-08-24T14:15:22Z"

}
