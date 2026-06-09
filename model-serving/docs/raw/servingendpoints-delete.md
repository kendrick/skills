Title: Delete a serving endpoint | Serving endpoints API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/servingendpoints/delete

Markdown Content:
## Delete a serving endpoint

`DELETE/api/2.0/serving-endpoints/{name}`

Delete a serving endpoint.

API scopes:[`model-serving`](https://docs.databricks.com/api/workspace/api/scopes#model-serving)

### Path parameters

[`name`](https://docs.databricks.com/api/workspace/servingendpoints/delete#name)required string

### Responses

**200** Request completed successfully.

Request completed successfully.

 This method might return the following HTTP codes: 401, 404, 500

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

UNAUTHENTICATED

Request does not have valid authentication credentials for the operation.

404

NOT_FOUND

Operation was performed on a resource that does not exist.

500

INTERNAL_ERROR

Internal error.
