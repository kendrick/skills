Title: Get the schema for a serving endpoint | Serving endpoints API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/servingendpoints/getopenapi

Markdown Content:
## Get the schema for a serving endpoint

Public preview

`GET/api/2.0/serving-endpoints/{name}/openapi`

Get the query schema of the serving endpoint in OpenAPI format. The schema contains information for the supported paths, input and output format and datatypes.

API scopes (preview):[`model-serving`](https://docs.databricks.com/api/workspace/api/scopes#model-serving)

### Path parameters

[`name`](https://docs.databricks.com/api/workspace/servingendpoints/getopenapi#name)required string

[ 1 .. 63 ] characters 

Example`"feed-ads"`

The name of the serving endpoint that the served model belongs to. This field is required.

### Responses

**200** Request completed successfully.

Request completed successfully.

 This method might return the following HTTP codes: 401, 500

Error responses are returned in the following format:

{ "error_code": "Error code", "message": "Human-readable error message." }

# Possible error codes:

HTTP code

error_code

Description

401

UNAUTHORIZED

The request does not have valid authentication credentials for the operation.

500

INTERNAL_ERROR

Internal error.
