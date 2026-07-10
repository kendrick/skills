Title: Get job policy compliance | Policy compliance for jobs API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/policycomplianceforjobs/getcompliance

Markdown Content:
## Get job policy compliance

`GET/api/2.0/policies/jobs/get-compliance`

Returns the policy compliance status of a job. Jobs could be out of compliance if a cluster policy they use was updated after the job was last edited and some of its job clusters no longer comply with their updated policies.

API scopes (preview):[`jobs`](https://docs.databricks.com/api/workspace/api/scopes#jobs)

### Query parameters

[`job_id`](https://docs.databricks.com/api/workspace/policycomplianceforjobs/getcompliance#job_id)required int64

The ID of the job whose compliance status you are requesting.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`is_compliant`](https://docs.databricks.com/api/workspace/policycomplianceforjobs/getcompliance#is_compliant)boolean

Whether the job is compliant with its policies or not. Jobs could be out of compliance if a policy they are using was updated after the job was last edited and some of its job clusters no longer comply with their updated policies.

[`violations`](https://docs.databricks.com/api/workspace/policycomplianceforjobs/getcompliance#violations)object

Example

An object containing key-value mappings representing the first 200 policy validation errors. The keys indicate the path where the policy validation error is occurring. An identifier for the job cluster is prepended to the path. The values indicate an error message describing the policy validation error.

 This method might return the following HTTP codes: 400, 401, 404, 429, 500

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

BAD_REQUEST, INVALID_PARAMETER_VALUE

BAD_REQUEST - Request is invalid. INVALID_PARAMETER_VALUE - Supplied value for a parameter was invalid.

401

UNAUTHORIZED

The request does not have valid authentication credentials for the operation.

404

NOT_FOUND

Operation was performed on a resource that does not exist.

429

REQUEST_LIMIT_EXCEEDED

Request is rejected due to throttling.

500

INTERNAL_SERVER_ERROR

Internal error.

# Response samples

200

{

"is_compliant":true,

"violations":{

"job_clusters[job_cluster_key].new_cluster.cus tom_tags.test_tag":"Validation failed for custom_ tags.test_tag,the value cannot be present"

}

}
