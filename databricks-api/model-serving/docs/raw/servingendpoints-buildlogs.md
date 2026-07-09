Title: Get build logs for a served model | Serving endpoints API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/servingendpoints/buildlogs

Markdown Content:
## Get build logs for a served model

`GET/api/2.0/serving-endpoints/{name}/served-models/{served_model_name}/build-logs`

Retrieves the build logs associated with the provided served model.

API scopes (preview):[`model-serving`](https://docs.databricks.com/api/workspace/api/scopes#model-serving)

### Path parameters

[`name`](https://docs.databricks.com/api/workspace/servingendpoints/buildlogs#name)required string

[ 1 .. 63 ] characters 

The name of the serving endpoint that the served model belongs to. This field is required.

[`served_model_name`](https://docs.databricks.com/api/workspace/servingendpoints/buildlogs#served_model_name)required string

[ 1 .. 63 ] characters 

The name of the served model that build logs will be retrieved for. This field is required.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`logs`](https://docs.databricks.com/api/workspace/servingendpoints/buildlogs#logs)string

Example`"- conda-forge\ndependencies:\n- python=3.9.5\n- pip<=21.2.4\n- pip:\n- mlflow\n- cloudpickle==2.2.0\nname: mlflow-env\nCollecting package metadata (repodata.json): ...working... done\nSolving environment: ...working... done\nPreparing transaction: ...working... done\nVerifying transaction: ...working... done\nExecuting transaction: ...working... done\nInstalling pip dependencies: ...working... done\n"`

The logs associated with building the served entity's environment.

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

# Response samples

200

{

"logs":"-conda-forge\ndependencies:\n-python=3.9.5\n-pip<=21.2.4\n-pip:\n-mlflow\n-cloudpic kle==2.2.0\nname:mlflow-env\nCollecting package m etadata(repodata.json):...working...done\nSolvi ng environment:...working...done\nPreparing tran saction:...working...done\nVerifying transaction:...working...done\nExecuting transaction:...wo rking...done\nInstalling pip dependencies:...wor king...done\n"

}
