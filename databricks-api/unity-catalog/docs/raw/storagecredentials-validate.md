Title: Validate a storage credential | Storage Credentials API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/storagecredentials/validate

Markdown Content:
## Validate a storage credential

`POST/api/2.1/unity-catalog/validate-storage-credentials`

Validates a storage credential. At least one of external_location_name and url need to be provided. If only one of them is provided, it will be used for validation. And if both are provided, the url will be used for validation, and external_location_name will be ignored when checking overlapping urls.

Either the storage_credential_name or the cloud-specific credential must be provided.

The caller must be a metastore admin or the storage credential owner or have the CREATE_EXTERNAL_LOCATION privilege on the metastore and the storage credential.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Request body

[`aws_iam_role`](https://docs.databricks.com/api/workspace/storagecredentials/validate#aws_iam_role)object

The AWS IAM role configuration.

[`role_arn`](https://docs.databricks.com/api/workspace/storagecredentials/validate#aws_iam_role-role_arn)required string

The Amazon Resource Name (ARN) of the AWS IAM role used to vend temporary credentials.

[`external_location_name`](https://docs.databricks.com/api/workspace/storagecredentials/validate#external_location_name)string

The name of an existing external location to validate.

[`read_only`](https://docs.databricks.com/api/workspace/storagecredentials/validate#read_only)boolean

Whether the storage credential is only usable for read operations.

[`storage_credential_name`](https://docs.databricks.com/api/workspace/storagecredentials/validate#storage_credential_name)string

Required. The name of an existing credential or long-lived cloud credential to validate.

[`url`](https://docs.databricks.com/api/workspace/storagecredentials/validate#url)string

The external location url to validate.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`isDir`](https://docs.databricks.com/api/workspace/storagecredentials/validate#isDir)boolean

Whether the tested location is a directory in cloud storage.

[`results`](https://docs.databricks.com/api/workspace/storagecredentials/validate#results)Array of object

The results of the validation check.

Array [

[`message`](https://docs.databricks.com/api/workspace/storagecredentials/validate#results-message)string

Error message would exist when the result does not equal to PASS.

[`operation`](https://docs.databricks.com/api/workspace/storagecredentials/validate#results-operation)string

Enum: `LIST | READ | WRITE | DELETE | PATH_EXISTS`

The operation tested.

[`result`](https://docs.databricks.com/api/workspace/storagecredentials/validate#results-result)string

Enum: `PASS | FAIL | SKIP`

The results of the tested operation.

 ]

# Request samples

JSON

{

"aws_iam_role":{

"role_arn":"string"

},

"external_location_name":"string",

"read_only":true,

"storage_credential_name":"string",

"url":"string"

}

# Response samples

200

{

"isDir":true,

"results":[

{

"message":"string",

"operation":"LIST",

"result":"PASS"

}

]

}
