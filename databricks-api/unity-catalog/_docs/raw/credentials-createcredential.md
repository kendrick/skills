Title: Create a credential | Credentials API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/credentials/createcredential

Markdown Content:
## Create a credential

`POST/api/2.1/unity-catalog/credentials`

Creates a new credential. The type of credential to be created is determined by the purpose field, which should be either SERVICE or STORAGE.

The caller must be a metastore admin or have the metastore privilege CREATE_STORAGE_CREDENTIAL for storage credentials, or CREATE_SERVICE_CREDENTIAL for service credentials.

The request object must contain an AwsIamRole with the `arn` of the IAM role. To prevent [the confused deputy problem](https://docs.aws.amazon.com/IAM/latest/UserGuide/confused-deputy.html), this role must specify an external ID in its trust policy.

To enable this credential, the external ID specified in the external_id field of the response object must be added to the IAM role's trust policy.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Request body

[`aws_iam_role`](https://docs.databricks.com/api/workspace/credentials/createcredential#aws_iam_role)object

The AWS IAM role configuration.

[`role_arn`](https://docs.databricks.com/api/workspace/credentials/createcredential#aws_iam_role-role_arn)string

The Amazon Resource Name (ARN) of the AWS IAM role used to vend temporary credentials.

[`comment`](https://docs.databricks.com/api/workspace/credentials/createcredential#comment)string

Comment associated with the credential.

[`name`](https://docs.databricks.com/api/workspace/credentials/createcredential#name)required string

The credential name. The name must be unique among storage and service credentials within the metastore.

[`purpose`](https://docs.databricks.com/api/workspace/credentials/createcredential#purpose)string

Enum: `STORAGE | SERVICE`

Indicates the purpose of the credential.

[`read_only`](https://docs.databricks.com/api/workspace/credentials/createcredential#read_only)boolean

Whether the credential is usable only for read operations. Only applicable when purpose is STORAGE.

[`skip_validation`](https://docs.databricks.com/api/workspace/credentials/createcredential#skip_validation)boolean

Default`false`

Optional. Supplying true to this argument skips validation of the created set of credentials.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`aws_iam_role`](https://docs.databricks.com/api/workspace/credentials/createcredential#aws_iam_role)object

The AWS IAM role configuration.

[`external_id`](https://docs.databricks.com/api/workspace/credentials/createcredential#aws_iam_role-external_id)string

The external ID used in role assumption to prevent the confused deputy problem.

[`role_arn`](https://docs.databricks.com/api/workspace/credentials/createcredential#aws_iam_role-role_arn)string

The Amazon Resource Name (ARN) of the AWS IAM role used to vend temporary credentials.

[`unity_catalog_iam_arn`](https://docs.databricks.com/api/workspace/credentials/createcredential#aws_iam_role-unity_catalog_iam_arn)string

The Amazon Resource Name (ARN) of the AWS IAM user managed by Databricks. This is the identity that is going to assume the AWS IAM role.

[`comment`](https://docs.databricks.com/api/workspace/credentials/createcredential#comment)string

Comment associated with the credential.

[`created_at`](https://docs.databricks.com/api/workspace/credentials/createcredential#created_at)int64

Time at which this credential was created, in epoch milliseconds.

[`created_by`](https://docs.databricks.com/api/workspace/credentials/createcredential#created_by)string

Username of credential creator.

[`full_name`](https://docs.databricks.com/api/workspace/credentials/createcredential#full_name)string

The full name of the credential.

[`id`](https://docs.databricks.com/api/workspace/credentials/createcredential#id)string

The unique identifier of the credential.

[`isolation_mode`](https://docs.databricks.com/api/workspace/credentials/createcredential#isolation_mode)string

Enum: `ISOLATION_MODE_OPEN | ISOLATION_MODE_ISOLATED`

Whether the current securable is accessible from all workspaces or a specific set of workspaces.

[`metastore_id`](https://docs.databricks.com/api/workspace/credentials/createcredential#metastore_id)string

Unique identifier of the parent metastore.

[`name`](https://docs.databricks.com/api/workspace/credentials/createcredential#name)string

The credential name. The name must be unique among storage and service credentials within the metastore.

[`owner`](https://docs.databricks.com/api/workspace/credentials/createcredential#owner)string

Username of current owner of credential.

[`purpose`](https://docs.databricks.com/api/workspace/credentials/createcredential#purpose)string

Enum: `STORAGE | SERVICE`

Indicates the purpose of the credential.

[`read_only`](https://docs.databricks.com/api/workspace/credentials/createcredential#read_only)boolean

Whether the credential is usable only for read operations. Only applicable when purpose is STORAGE.

[`updated_at`](https://docs.databricks.com/api/workspace/credentials/createcredential#updated_at)int64

Time at which this credential was last modified, in epoch milliseconds.

[`updated_by`](https://docs.databricks.com/api/workspace/credentials/createcredential#updated_by)string

Username of user who last modified the credential.

[`used_for_managed_storage`](https://docs.databricks.com/api/workspace/credentials/createcredential#used_for_managed_storage)boolean

Whether this credential is the current metastore's root storage credential. Only applicable when purpose is STORAGE.

# Request samples

JSON

{

"aws_iam_role":{

"external_id":"string",

"role_arn":"string",

"unity_catalog_iam_arn":"string"

},

"comment":"string",

"name":"string",

"purpose":"STORAGE",

"read_only":true,

"skip_validation":false

}

# Response samples

200

{

"aws_iam_role":{

"external_id":"string",

"role_arn":"string",

"unity_catalog_iam_arn":"string"

},

"comment":"string",

"created_at":0,

"created_by":"string",

"full_name":"string",

"id":"string",

"isolation_mode":"ISOLATION_MODE_OPEN",

"metastore_id":"string",

"name":"string",

"owner":"string",

"purpose":"STORAGE",

"read_only":true,

"updated_at":0,

"updated_by":"string",

"used_for_managed_storage":true

}
