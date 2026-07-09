Title: List credentials | Storage Credentials API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/storagecredentials/list

Markdown Content:
## List credentials

`GET/api/2.1/unity-catalog/storage-credentials`

Gets an array of storage credentials (as StorageCredentialInfo objects). The array is limited to only those storage credentials the caller has permission to access. If the caller is a metastore admin, retrieval of credentials is unrestricted. There is no guarantee of a specific ordering of the elements in the array.

NOTE: we recommend using max_results=0 to use the paginated version of this API. Unpaginated calls will be deprecated soon.

PAGINATION BEHAVIOR: When using pagination (max_results >= 0), a page may contain zero results while still providing a next_page_token. Clients must continue reading pages until next_page_token is absent, which is the only indication that the end of results has been reached.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Query parameters

[`include_unbound`](https://docs.databricks.com/api/workspace/storagecredentials/list#include_unbound)boolean

Whether to include credentials not bound to the workspace. Effective only if the user has permission to update the credential–workspace binding.

[`max_results`](https://docs.databricks.com/api/workspace/storagecredentials/list#max_results)int32

<= 1000 

Maximum number of storage credentials to return. If not set, all the storage credentials are returned (not recommended).

*   when set to a value greater than 0, the page length is the minimum of this value and a server configured value;
*   when set to 0, the page length is set to a server configured value (recommended);
*   when set to a value less than 0, an invalid parameter error is returned;

[`page_token`](https://docs.databricks.com/api/workspace/storagecredentials/list#page_token)string

Opaque pagination token to go to next page based on previous query.

### Responses

**200** Request completed successfully. The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

Request completed successfully.

 The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

[`next_page_token`](https://docs.databricks.com/api/workspace/storagecredentials/list#next_page_token)string

Opaque token to retrieve the next page of results. Absent if there are no more pages. page_token should be set to this value for the next request (for the next page of results).

[`storage_credentials`](https://docs.databricks.com/api/workspace/storagecredentials/list#storage_credentials)Array of object

Array [

[`aws_iam_role`](https://docs.databricks.com/api/workspace/storagecredentials/list#storage_credentials-aws_iam_role)object

The AWS IAM role configuration.

[`comment`](https://docs.databricks.com/api/workspace/storagecredentials/list#storage_credentials-comment)string

Comment associated with the credential.

[`created_at`](https://docs.databricks.com/api/workspace/storagecredentials/list#storage_credentials-created_at)int64

Time at which this credential was created, in epoch milliseconds.

[`created_by`](https://docs.databricks.com/api/workspace/storagecredentials/list#storage_credentials-created_by)string

Username of credential creator.

[`full_name`](https://docs.databricks.com/api/workspace/storagecredentials/list#storage_credentials-full_name)string

The full name of the credential.

[`id`](https://docs.databricks.com/api/workspace/storagecredentials/list#storage_credentials-id)string

The unique identifier of the credential.

[`isolation_mode`](https://docs.databricks.com/api/workspace/storagecredentials/list#storage_credentials-isolation_mode)string

Enum: `ISOLATION_MODE_OPEN | ISOLATION_MODE_ISOLATED`

Whether the current securable is accessible from all workspaces or a specific set of workspaces.

[`metastore_id`](https://docs.databricks.com/api/workspace/storagecredentials/list#storage_credentials-metastore_id)string

Unique identifier of the parent metastore.

[`name`](https://docs.databricks.com/api/workspace/storagecredentials/list#storage_credentials-name)string

The credential name. The name must be unique among storage and service credentials within the metastore.

[`owner`](https://docs.databricks.com/api/workspace/storagecredentials/list#storage_credentials-owner)string

Username of current owner of credential.

[`read_only`](https://docs.databricks.com/api/workspace/storagecredentials/list#storage_credentials-read_only)boolean

Whether the credential is usable only for read operations. Only applicable when purpose is STORAGE.

[`updated_at`](https://docs.databricks.com/api/workspace/storagecredentials/list#storage_credentials-updated_at)int64

Time at which this credential was last modified, in epoch milliseconds.

[`updated_by`](https://docs.databricks.com/api/workspace/storagecredentials/list#storage_credentials-updated_by)string

Username of user who last modified the credential.

[`used_for_managed_storage`](https://docs.databricks.com/api/workspace/storagecredentials/list#storage_credentials-used_for_managed_storage)boolean

Whether this credential is the current metastore's root storage credential. Only applicable when purpose is STORAGE.

 ]

# Response samples

200

{

"next_page_token":"string",

"storage_credentials":[

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

]

}
