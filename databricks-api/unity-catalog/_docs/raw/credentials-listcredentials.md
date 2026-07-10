Title: List credentials | Credentials API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/credentials/listcredentials

Markdown Content:
## List credentials

`GET/api/2.1/unity-catalog/credentials`

Gets an array of credentials (as CredentialInfo objects).

The array is limited to only the credentials that the caller has permission to access. If the caller is a metastore admin, retrieval of credentials is unrestricted. There is no guarantee of a specific ordering of the elements in the array.

PAGINATION BEHAVIOR: The API is by default paginated, a page may contain zero results while still providing a next_page_token. Clients must continue reading pages until next_page_token is absent, which is the only indication that the end of results has been reached.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Query parameters

[`include_unbound`](https://docs.databricks.com/api/workspace/credentials/listcredentials#include_unbound)boolean

Whether to include credentials not bound to the workspace. Effective only if the user has permission to update the credential–workspace binding.

[`max_results`](https://docs.databricks.com/api/workspace/credentials/listcredentials#max_results)int32

Maximum number of credentials to return.

*   If not set, the default max page size is used.
*   When set to a value greater than 0, the page length is the minimum of this value and a server-configured value.
*   When set to 0, the page length is set to a server-configured value (recommended).
*   When set to a value less than 0, an invalid parameter error is returned.

[`page_token`](https://docs.databricks.com/api/workspace/credentials/listcredentials#page_token)string

Opaque token to retrieve the next page of results.

[`purpose`](https://docs.databricks.com/api/workspace/credentials/listcredentials#purpose)string

Enum: `STORAGE | SERVICE`

Return only credentials for the specified purpose.

### Responses

**200** Request completed successfully. The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

Request completed successfully.

 The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

[`credentials`](https://docs.databricks.com/api/workspace/credentials/listcredentials#credentials)Array of object

Array [

[`aws_iam_role`](https://docs.databricks.com/api/workspace/credentials/listcredentials#credentials-aws_iam_role)object

The AWS IAM role configuration.

[`comment`](https://docs.databricks.com/api/workspace/credentials/listcredentials#credentials-comment)string

Comment associated with the credential.

[`created_at`](https://docs.databricks.com/api/workspace/credentials/listcredentials#credentials-created_at)int64

Time at which this credential was created, in epoch milliseconds.

[`created_by`](https://docs.databricks.com/api/workspace/credentials/listcredentials#credentials-created_by)string

Username of credential creator.

[`full_name`](https://docs.databricks.com/api/workspace/credentials/listcredentials#credentials-full_name)string

The full name of the credential.

[`id`](https://docs.databricks.com/api/workspace/credentials/listcredentials#credentials-id)string

The unique identifier of the credential.

[`isolation_mode`](https://docs.databricks.com/api/workspace/credentials/listcredentials#credentials-isolation_mode)string

Enum: `ISOLATION_MODE_OPEN | ISOLATION_MODE_ISOLATED`

Whether the current securable is accessible from all workspaces or a specific set of workspaces.

[`metastore_id`](https://docs.databricks.com/api/workspace/credentials/listcredentials#credentials-metastore_id)string

Unique identifier of the parent metastore.

[`name`](https://docs.databricks.com/api/workspace/credentials/listcredentials#credentials-name)string

The credential name. The name must be unique among storage and service credentials within the metastore.

[`owner`](https://docs.databricks.com/api/workspace/credentials/listcredentials#credentials-owner)string

Username of current owner of credential.

[`purpose`](https://docs.databricks.com/api/workspace/credentials/listcredentials#credentials-purpose)string

Enum: `STORAGE | SERVICE`

Indicates the purpose of the credential.

[`read_only`](https://docs.databricks.com/api/workspace/credentials/listcredentials#credentials-read_only)boolean

Whether the credential is usable only for read operations. Only applicable when purpose is STORAGE.

[`updated_at`](https://docs.databricks.com/api/workspace/credentials/listcredentials#credentials-updated_at)int64

Time at which this credential was last modified, in epoch milliseconds.

[`updated_by`](https://docs.databricks.com/api/workspace/credentials/listcredentials#credentials-updated_by)string

Username of user who last modified the credential.

[`used_for_managed_storage`](https://docs.databricks.com/api/workspace/credentials/listcredentials#credentials-used_for_managed_storage)boolean

Whether this credential is the current metastore's root storage credential. Only applicable when purpose is STORAGE.

 ]

[`next_page_token`](https://docs.databricks.com/api/workspace/credentials/listcredentials#next_page_token)string

Opaque token to retrieve the next page of results. Absent if there are no more pages. page_token should be set to this value for the next request (for the next page of results).

# Response samples

200

{

"credentials":[

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

],

"next_page_token":"string"

}
