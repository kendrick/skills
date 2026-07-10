Title: Get metrics of a serving endpoint | Serving endpoints API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/servingendpoints/exportmetrics

Markdown Content:
## Get metrics of a serving endpoint

`GET/api/2.0/serving-endpoints/{name}/metrics`

Retrieves the metrics associated with the provided serving endpoint in either Prometheus or OpenMetrics exposition format.

API scopes (preview):[`model-serving`](https://docs.databricks.com/api/workspace/api/scopes#model-serving)

### Path parameters

[`name`](https://docs.databricks.com/api/workspace/servingendpoints/exportmetrics#name)required string

[ 1 .. 63 ] characters 

The name of the serving endpoint to retrieve metrics for. This field is required.

### Responses

**200** Request completed successfully.

Request completed successfully.

 This method might return the following HTTP codes: 400, 401, 404, 500

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

404

NOT_FOUND

Operation was performed on a resource that does not exist.

500

INTERNAL_ERROR

Internal error.
