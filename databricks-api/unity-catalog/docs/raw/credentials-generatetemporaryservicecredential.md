Title: Generate a temporary service credential | Credentials API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/credentials/generatetemporaryservicecredential

Markdown Content:
## Generate a temporary service credential

`POST/api/2.1/unity-catalog/temporary-service-credentials`

Returns a set of temporary credentials generated using the specified service credential. The caller must be a metastore admin or have the metastore privilege ACCESS on the service credential.

The temporary credentials consist of an access key ID, a secret access key, and a security token.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Request body

[`credential_name`](https://docs.databricks.com/api/workspace/credentials/generatetemporaryservicecredential#credential_name)required string

The name of the service credential used to generate a temporary credential

### Responses

**200** Request completed successfully.

Request completed successfully.

[`aws_temp_credentials`](https://docs.databricks.com/api/workspace/credentials/generatetemporaryservicecredential#aws_temp_credentials)object

AWS temporary credentials for API authentication. Read more at [https://docs.aws.amazon.com/STS/latest/APIReference/API_Credentials.html](https://docs.aws.amazon.com/STS/latest/APIReference/API_Credentials.html).

[`access_key_id`](https://docs.databricks.com/api/workspace/credentials/generatetemporaryservicecredential#aws_temp_credentials-access_key_id)string

The access key ID that identifies the temporary credentials.

[`access_point`](https://docs.databricks.com/api/workspace/credentials/generatetemporaryservicecredential#aws_temp_credentials-access_point)string

The Amazon Resource Name (ARN) of the S3 access point for temporary credentials related the external location.

[`secret_access_key`](https://docs.databricks.com/api/workspace/credentials/generatetemporaryservicecredential#aws_temp_credentials-secret_access_key)string

The secret access key that can be used to sign AWS API requests.

[`session_token`](https://docs.databricks.com/api/workspace/credentials/generatetemporaryservicecredential#aws_temp_credentials-session_token)string

The token that users must pass to AWS API to use the temporary credentials.

[`expiration_time`](https://docs.databricks.com/api/workspace/credentials/generatetemporaryservicecredential#expiration_time)int64

Server time when the credential will expire, in epoch milliseconds. The API client is advised to cache the credential given this expiration time.

# Request samples

JSON

{

"credential_name":"string"

}

# Response samples

200

{

"aws_temp_credentials":{

"access_key_id":"string",

"access_point":"string",

"secret_access_key":"string",

"session_token":"string"

},

"expiration_time":0

}
