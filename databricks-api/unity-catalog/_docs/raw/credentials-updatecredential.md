Title: Update a credential | Credentials API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/credentials/updatecredential

Markdown Content:
## Update a credential

`PATCH/api/2.1/unity-catalog/credentials/{name_arg}`

Updates a service or storage credential on the metastore.

The caller must be the owner of the credential or a metastore admin or have the `MANAGE` permission. If the caller is a metastore admin, only the owner field can be changed.

To prevent [the confused deputy problem](https://docs.aws.amazon.com/IAM/latest/UserGuide/confused-deputy.html), this role must specify an external ID in its trust policy.

To enable this credential, the external ID specified in the external_id field of the response object must be added to the new IAM role's trust policy.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`name_arg`](https://docs.databricks.com/api/workspace/credentials/updatecredential#name_arg)required string

Name of the credential.

### Request body

[`aws_iam_role`](https://docs.databricks.com/api/workspace/credentials/updatecredential#aws_iam_role)object

The AWS IAM role configuration.

[`role_arn`](https://docs.databricks.com/api/workspace/credentials/updatecredential#aws_iam_role-role_arn)string

The Amazon Resource Name (ARN) of the AWS IAM role used to vend temporary credentials.

[`comment`](https://docs.databricks.com/api/workspace/credentials/updatecredential#comment)string

Comment associated with the credential.

[`force`](https://docs.databricks.com/api/workspace/credentials/updatecredential#force)boolean

Force an update even if there are dependent services (when purpose is SERVICE) or dependent external locations and external tables (when purpose is STORAGE).

[`isolation_mode`](https://docs.databricks.com/api/workspace/credentials/updatecredential#isolation_mode)string

Enum: `ISOLATION_MODE_OPEN | ISOLATION_MODE_ISOLATED`

Whether the current securable is accessible from all workspaces or a specific set of workspaces.

[`new_name`](https://docs.databricks.com/api/workspace/credentials/updatecredential#new_name)string

New name of credential.

[`owner`](https://docs.databricks.com/api/workspace/credentials/updatecredential#owner)string

Username of current owner of credential.

[`read_only`](https://docs.databricks.com/api/workspace/credentials/updatecredential#read_only)boolean

Whether the credential is usable only for read operations. Only applicable when purpose is STORAGE.

[`skip_validation`](https://docs.databricks.com/api/workspace/credentials/updatecredential#skip_validation)boolean

Supply true to this argument to skip validation of the updated credential.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`aws_iam_role`](https://docs.databricks.com/api/workspace/credentials/updatecredential#aws_iam_role)object

The AWS IAM role configuration.

[`external_id`](https://docs.databricks.com/api/workspace/credentials/updatecredential#aws_iam_role-external_id)string

The external ID used in role assumption to prevent the confused deputy problem.

[`role_arn`](https://docs.databricks.com/api/workspace/credentials/updatecredential#aws_iam_role-role_arn)string

The Amazon Resource Name (ARN) of the AWS IAM role used to vend temporary credentials.

[`unity_catalog_iam_arn`](https://docs.databricks.com/api/workspace/credentials/updatecredential#aws_iam_role-unity_catalog_iam_arn)string

The Amazon Resource Name (ARN) of the AWS IAM user managed by Databricks. This is the identity that is going to assume the AWS IAM role.

[`comment`](https://docs.databricks.com/api/workspace/credentials/updatecredential#comment)string

Comment associated with the credential.

[`created_at`](https://docs.databricks.com/api/workspace/credentials/updatecredential#created_at)int64

Time at which this credential was created, in epoch milliseconds.

[`created_by`](https://docs.databricks.com/api/workspace/credentials/updatecredential#created_by)string

Username of credential creator.

[`full_name`](https://docs.databricks.com/api/workspace/credentials/updatecredential#full_name)string

The full name of the credential.

[`id`](https://docs.databricks.com/api/workspace/credentials/updatecredential#id)string

The unique identifier of the credential.

[`isolation_mode`](https://docs.databricks.com/api/workspace/credentials/updatecredential#isolation_mode)string

Enum: `ISOLATION_MODE_OPEN | ISOLATION_MODE_ISOLATED`

Whether the current securable is accessible from all workspaces or a specific set of workspaces.

[`metastore_id`](https://docs.databricks.com/api/workspace/credentials/updatecredential#metastore_id)string

Unique identifier of the parent metastore.

[`name`](https://docs.databricks.com/api/workspace/credentials/updatecredential#name)string

The credential name. The name must be unique among storage and service credentials within the metastore.

[`owner`](https://docs.databricks.com/api/workspace/credentials/updatecredential#owner)string

Username of current owner of credential.

[`purpose`](https://docs.databricks.com/api/workspace/credentials/updatecredential#purpose)string

Enum: `STORAGE | SERVICE`

Indicates the purpose of the credential.

[`read_only`](https://docs.databricks.com/api/workspace/credentials/updatecredential#read_only)boolean

Whether the credential is usable only for read operations. Only applicable when purpose is STORAGE.

[`updated_at`](https://docs.databricks.com/api/workspace/credentials/updatecredential#updated_at)int64

Time at which this credential was last modified, in epoch milliseconds.

[`updated_by`](https://docs.databricks.com/api/workspace/credentials/updatecredential#updated_by)string

Username of user who last modified the credential.

[`used_for_managed_storage`](https://docs.databricks.com/api/workspace/credentials/updatecredential#used_for_managed_storage)boolean

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

"force":true,

"isolation_mode":"ISOLATION_MODE_OPEN",

"new_name":"string",

"owner":"string",

"read_only":true,

"skip_validation":true

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
