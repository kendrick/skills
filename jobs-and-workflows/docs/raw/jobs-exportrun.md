Title: Export and retrieve a job run | Jobs API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/jobs/exportrun

Markdown Content:
## Export and retrieve a job run

`GET/api/2.2/jobs/runs/export`

Export and retrieve the job run task.

API scopes (preview):[`jobs`](https://docs.databricks.com/api/workspace/api/scopes#jobs)

### Query parameters

[`run_id`](https://docs.databricks.com/api/workspace/jobs/exportrun#run_id)required int64

Example`run_id=455644833`

The canonical identifier for the run. This field is required.

[`views_to_export`](https://docs.databricks.com/api/workspace/jobs/exportrun#views_to_export)string

Enum: `CODE | DASHBOARDS | ALL`

Default`"CODE"`

Which views to export (CODE, DASHBOARDS, or ALL). Defaults to CODE.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`views`](https://docs.databricks.com/api/workspace/jobs/exportrun#views)Array of object

The exported content in HTML format (one for every view item). To extract the HTML notebook from the JSON response, download and run this [Python script](https://docs.databricks.com/_static/examples/extract.py).

Array [

[`content`](https://docs.databricks.com/api/workspace/jobs/exportrun#views-content)string

Content of the view.

[`name`](https://docs.databricks.com/api/workspace/jobs/exportrun#views-name)string

Name of the view item. In the case of code view, it would be the notebook’s name. In the case of dashboard view, it would be the dashboard’s name.

[`type`](https://docs.databricks.com/api/workspace/jobs/exportrun#views-type)string

Enum: `NOTEBOOK | DASHBOARD`

Type of the view item.

 ]

 This method might return the following HTTP codes: 400, 401, 403, 429, 500

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

INVALID_PARAMETER_VALUE

Supplied value for a parameter was invalid.

401

UNAUTHORIZED

The request does not have valid authentication credentials for the operation.

403

PERMISSION_DENIED

Caller does not have permission to execute the specified operation.

429

REQUEST_LIMIT_EXCEEDED

Request is rejected due to throttling.

500

INTERNAL_SERVER_ERROR

Internal error.

# Response samples

200

{

"views":[

{

"content":"string",

"name":"string",

"type":"NOTEBOOK"

}

]

}
