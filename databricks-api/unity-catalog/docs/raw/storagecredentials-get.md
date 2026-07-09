Title: Get a credential | Storage Credentials API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/storagecredentials/get

Markdown Content:
## Get a credential

`GET/api/2.1/unity-catalog/storage-credentials/{name}`

Gets a storage credential from the metastore. The caller must be a metastore admin, the owner of the storage credential, or have some permission on the storage credential.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`name`](https://docs.databricks.com/api/workspace/storagecredentials/get#name)required string

Name of the storage credential.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`aws_iam_role`](https://docs.databricks.com/api/workspace/storagecredentials/get#aws_iam_role)object

The AWS IAM role configuration.

[`external_id`](https://docs.databricks.com/api/workspace/storagecredentials/get#aws_iam_role-external_id)string

The external ID used in role assumption to prevent the confused deputy problem.

[`role_arn`](https://docs.databricks.com/api/workspace/storagecredentials/get#aws_iam_role-role_arn)string

The Amazon Resource Name (ARN) of the AWS IAM role used to vend temporary credentials.

[`unity_catalog_iam_arn`](https://docs.databricks.com/api/workspace/storagecredentials/get#aws_iam_role-unity_catalog_iam_arn)string

The Amazon Resource Name (ARN) of the AWS IAM user managed by Databricks. This is the identity that is going to assume the AWS IAM role.

[`comment`](https://docs.databricks.com/api/workspace/storagecredentials/get#comment)string

Comment associated with the credential.

[`created_at`](https://docs.databricks.com/api/workspace/storagecredentials/get#created_at)int64

Time at which this credential was created, in epoch milliseconds.

[`created_by`](https://docs.databricks.com/api/workspace/storagecredentials/get#created_by)string

Username of credential creator.

[`full_name`](https://docs.databricks.com/api/workspace/storagecredentials/get#full_name)string

The full name of the credential.

[`id`](https://docs.databricks.com/api/workspace/storagecredentials/get#id)string

The unique identifier of the credential.

[`isolation_mode`](https://docs.databricks.com/api/workspace/storagecredentials/get#isolation_mode)string

Enum: `ISOLATION_MODE_OPEN | ISOLATION_MODE_ISOLATED`

Whether the current securable is accessible from all workspaces or a specific set of workspaces.

[`metastore_id`](https://docs.databricks.com/api/workspace/storagecredentials/get#metastore_id)string

Unique identifier of the parent metastore.

[`name`](https://docs.databricks.com/api/workspace/storagecredentials/get#name)string

The credential name. The name must be unique among storage and service credentials within the metastore.

[`owner`](https://docs.databricks.com/api/workspace/storagecredentials/get#owner)string

Username of current owner of credential.

[`read_only`](https://docs.databricks.com/api/workspace/storagecredentials/get#read_only)boolean

Whether the credential is usable only for read operations. Only applicable when purpose is STORAGE.

[`updated_at`](https://docs.databricks.com/api/workspace/storagecredentials/get#updated_at)int64

Time at which this credential was last modified, in epoch milliseconds.

[`updated_by`](https://docs.databricks.com/api/workspace/storagecredentials/get#updated_by)string

Username of user who last modified the credential.

[`used_for_managed_storage`](https://docs.databricks.com/api/workspace/storagecredentials/get#used_for_managed_storage)boolean

Whether this credential is the current metastore's root storage credential. Only applicable when purpose is STORAGE.

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

"read_only":true,

"updated_at":0,

"updated_by":"string",

"used_for_managed_storage":true

}
