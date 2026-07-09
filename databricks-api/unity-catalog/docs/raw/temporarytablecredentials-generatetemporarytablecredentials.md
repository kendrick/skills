Title: Generate a temporary table credential | Temporary Table Credentials API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/temporarytablecredentials/generatetemporarytablecredentials

Markdown Content:
## Generate a temporary table credential

Public preview

`POST/api/2.0/unity-catalog/temporary-table-credentials`

Get a short-lived credential for directly accessing the table data on cloud storage. The metastore must have external_access_enabled flag set to true (default false). The caller must have the EXTERNAL_USE_SCHEMA privilege on the parent schema and this privilege can only be granted by catalog owners.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Request body

[`operation`](https://docs.databricks.com/api/workspace/temporarytablecredentials/generatetemporarytablecredentials#operation)string

Enum: `READ | READ_WRITE`

The operation performed against the table data, either READ or READ_WRITE. If READ_WRITE is specified, the credentials returned will have write permissions, otherwise, it will be read only.

[`table_id`](https://docs.databricks.com/api/workspace/temporarytablecredentials/generatetemporarytablecredentials#table_id)string

UUID of the table to read or write.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`aws_temp_credentials`](https://docs.databricks.com/api/workspace/temporarytablecredentials/generatetemporarytablecredentials#aws_temp_credentials)object

AWS temporary credentials for API authentication. Read more at [https://docs.aws.amazon.com/STS/latest/APIReference/API_Credentials.html](https://docs.aws.amazon.com/STS/latest/APIReference/API_Credentials.html).

[`access_key_id`](https://docs.databricks.com/api/workspace/temporarytablecredentials/generatetemporarytablecredentials#aws_temp_credentials-access_key_id)string

The access key ID that identifies the temporary credentials.

[`access_point`](https://docs.databricks.com/api/workspace/temporarytablecredentials/generatetemporarytablecredentials#aws_temp_credentials-access_point)string

The Amazon Resource Name (ARN) of the S3 access point for temporary credentials related the external location.

[`secret_access_key`](https://docs.databricks.com/api/workspace/temporarytablecredentials/generatetemporarytablecredentials#aws_temp_credentials-secret_access_key)string

The secret access key that can be used to sign AWS API requests.

[`session_token`](https://docs.databricks.com/api/workspace/temporarytablecredentials/generatetemporarytablecredentials#aws_temp_credentials-session_token)string

The token that users must pass to AWS API to use the temporary credentials.

[`azure_user_delegation_sas`](https://docs.databricks.com/api/workspace/temporarytablecredentials/generatetemporarytablecredentials#azure_user_delegation_sas)object

Azure temporary credentials for API authentication. Read more at [https://docs.microsoft.com/en-us/rest/api/storageservices/create-user-delegation-sas](https://docs.microsoft.com/en-us/rest/api/storageservices/create-user-delegation-sas)

[`sas_token`](https://docs.databricks.com/api/workspace/temporarytablecredentials/generatetemporarytablecredentials#azure_user_delegation_sas-sas_token)string

The signed URI (SAS Token) used to access blob services for a given path

[`expiration_time`](https://docs.databricks.com/api/workspace/temporarytablecredentials/generatetemporarytablecredentials#expiration_time)int64

Server time when the credential will expire, in epoch milliseconds. The API client is advised to cache the credential given this expiration time.

[`r2_temp_credentials`](https://docs.databricks.com/api/workspace/temporarytablecredentials/generatetemporarytablecredentials#r2_temp_credentials)object

R2 temporary credentials for API authentication. Read more at [https://developers.cloudflare.com/r2/api/s3/tokens/](https://developers.cloudflare.com/r2/api/s3/tokens/).

[`access_key_id`](https://docs.databricks.com/api/workspace/temporarytablecredentials/generatetemporarytablecredentials#r2_temp_credentials-access_key_id)string

The access key ID that identifies the temporary credentials.

[`secret_access_key`](https://docs.databricks.com/api/workspace/temporarytablecredentials/generatetemporarytablecredentials#r2_temp_credentials-secret_access_key)string

The secret access key associated with the access key.

[`session_token`](https://docs.databricks.com/api/workspace/temporarytablecredentials/generatetemporarytablecredentials#r2_temp_credentials-session_token)string

The generated JWT that users must pass to use the temporary credentials.

[`url`](https://docs.databricks.com/api/workspace/temporarytablecredentials/generatetemporarytablecredentials#url)string

The URL of the storage path accessible by the temporary credential.

# Request samples

JSON

{

"operation":"READ",

"table_id":"string"

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

"azure_user_delegation_sas":{

"sas_token":"string"

},

"expiration_time":0,

"r2_temp_credentials":{

"access_key_id":"string",

"secret_access_key":"string",

"session_token":"string"

},

"url":"string"

}
