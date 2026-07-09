Title: Update rate limits of a serving endpoint | Serving endpoints API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/servingendpoints/put

Markdown Content:
## Update rate limits of a serving endpoint

Public preview

Deprecated

`PUT/api/2.0/serving-endpoints/{name}/rate-limits`

Deprecated: Please use AI Gateway to manage rate limits instead.

API scopes (preview):[`model-serving`](https://docs.databricks.com/api/workspace/api/scopes#model-serving)

### Path parameters

[`name`](https://docs.databricks.com/api/workspace/servingendpoints/put#name)required string

[ 1 .. 63 ] characters 

The name of the serving endpoint whose rate limits are being updated. This field is required.

### Request body

[`rate_limits`](https://docs.databricks.com/api/workspace/servingendpoints/put#rate_limits)Array of object

Public preview

The list of endpoint rate limits.

Array [

[`calls`](https://docs.databricks.com/api/workspace/servingendpoints/put#rate_limits-calls)required int64

Example`15`

Used to specify how many calls are allowed for a key within the renewal_period.

[`key`](https://docs.databricks.com/api/workspace/servingendpoints/put#rate_limits-key)string

Enum:

`user`

Public preview

`endpoint`

Public preview

Key field for a serving endpoint rate limit. Currently, only 'user' and 'endpoint' are supported, with 'endpoint' being the default if not specified.

[`renewal_period`](https://docs.databricks.com/api/workspace/servingendpoints/put#rate_limits-renewal_period)required string

Enum:

`minute`

Public preview

Renewal period field for a serving endpoint rate limit. Currently, only 'minute' is supported.

 ]

### Responses

**200** Request completed successfully.

Request completed successfully.

[`rate_limits`](https://docs.databricks.com/api/workspace/servingendpoints/put#rate_limits)Array of object

Public preview

The list of endpoint rate limits.

Array [

[`calls`](https://docs.databricks.com/api/workspace/servingendpoints/put#rate_limits-calls)int64

Example`15`

Used to specify how many calls are allowed for a key within the renewal_period.

[`key`](https://docs.databricks.com/api/workspace/servingendpoints/put#rate_limits-key)string

Enum:

`user`

Public preview

`endpoint`

Public preview

Key field for a serving endpoint rate limit. Currently, only 'user' and 'endpoint' are supported, with 'endpoint' being the default if not specified.

[`renewal_period`](https://docs.databricks.com/api/workspace/servingendpoints/put#rate_limits-renewal_period)string

Enum:

`minute`

Public preview

Renewal period field for a serving endpoint rate limit. Currently, only 'minute' is supported.

 ]

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

# Request samples

JSON

{

"rate_limits":[

{

"calls":15,

"key":"user",

"renewal_period":"minute"

}

]

}

# Response samples

200

{

"rate_limits":[

{

"calls":15,

"key":"user",

"renewal_period":"minute"

}

]

}
