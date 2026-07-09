Title: Get the latest logs for a served model | Serving endpoints API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/servingendpoints/logs

Markdown Content:
## Get the latest logs for a served model

`GET/api/2.0/serving-endpoints/{name}/served-models/{served_model_name}/logs`

Retrieves the service logs associated with the provided served model.

API scopes (preview):[`model-serving`](https://docs.databricks.com/api/workspace/api/scopes#model-serving)

### Path parameters

[`name`](https://docs.databricks.com/api/workspace/servingendpoints/logs#name)required string

[ 1 .. 63 ] characters 

The name of the serving endpoint that the served model belongs to. This field is required.

[`served_model_name`](https://docs.databricks.com/api/workspace/servingendpoints/logs#served_model_name)required string

[ 1 .. 63 ] characters 

The name of the served model that logs will be retrieved for. This field is required.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`logs`](https://docs.databricks.com/api/workspace/servingendpoints/logs#logs)string

Example`"[hc4q8] [2023-01-10 19:12:58 +0000] [2] [INFO] Starting gunicorn 20.1.0\n[hc4q8] [2023-01-10 19:12:58 +0000] [2] [INFO] Listening at: http://0.0.0.0:8080 (2)\n[hc4q8] [2023-01-10 19:12:58 +0000] [2] [INFO] Using worker: sync\n[hc4q8] [2023-01-10 19:12:58 +0000] [3] [INFO] Booting worker with pid: 3\n[hc4q8] [2023-01-10 19:12:58 +0000] [4] [INFO] Booting worker with pid: 4\n[hc4q8] [2023-01-10 19:12:58 +0000] [5] [INFO] Booting worker with pid: 5\n[hc4q8] [2023-01-10 19:12:58 +0000] [6] [INFO] Booting worker with pid: 6\n"`

The most recent log lines of the model server processing invocation requests.

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

UNAUTHORIZED

The request does not have valid authentication credentials for the operation.

404

NOT_FOUND

Operation was performed on a resource that does not exist.

500

INTERNAL_ERROR

Internal error.

# Response samples

200

{

"logs":"[hc4q8][2023-01-10 19:12:58+0000][2][INFO]Starting gunicorn 20.1.0\n[hc4q8][2023-01-10 19:12:58+0000][2][INFO]Listening at:http://0.0.0.0:8080(2)\n[hc4q8][2023-01-10 19:12:58+0000][2][INFO]Using worker:sync\n[hc4q8][2023-01-10 19:12:58+0000][3][INFO]Booting worker w ith pid:3\n[hc4q8][2023-01-10 19:12:58+0000][4][INFO]Booting worker with pid:4\n[hc4q8][2023-01-10 19:12:58+0000][5][INFO]Booting worker w ith pid:5\n[hc4q8][2023-01-10 19:12:58+0000][6][INFO]Booting worker with pid:6\n"

}
