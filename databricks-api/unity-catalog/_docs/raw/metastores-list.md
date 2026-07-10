Title: List metastores | Metastores API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/metastores/list

Markdown Content:
## List metastores

`GET/api/2.1/unity-catalog/metastores`

Gets an array of the available metastores (as MetastoreInfo objects). The caller must be an admin to retrieve this info. There is no guarantee of a specific ordering of the elements in the array.

NOTE: we recommend using max_results=0 to use the paginated version of this API. Unpaginated calls will be deprecated soon.

PAGINATION BEHAVIOR: When using pagination (max_results >= 0), a page may contain zero results while still providing a next_page_token. Clients must continue reading pages until next_page_token is absent, which is the only indication that the end of results has been reached.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Query parameters

[`max_results`](https://docs.databricks.com/api/workspace/metastores/list#max_results)int32

Maximum number of metastores to return.

*   when set to a value greater than 0, the page length is the minimum of this value and a server configured value;
*   when set to 0, the page length is set to a server configured value (recommended);
*   when set to a value less than 0, an invalid parameter error is returned;
*   If not set, all the metastores are returned (not recommended).
*   Note: The number of returned metastores might be less than the specified max_results size, even zero. The only definitive indication that no further metastores can be fetched is when the next_page_token is unset from the response.

[`page_token`](https://docs.databricks.com/api/workspace/metastores/list#page_token)string

Opaque pagination token to go to next page based on previous query.

### Responses

**200** Request completed successfully. The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

Request completed successfully.

 The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

[`metastores`](https://docs.databricks.com/api/workspace/metastores/list#metastores)Array of object

An array of metastore information objects.

Array [

[`cloud`](https://docs.databricks.com/api/workspace/metastores/list#metastores-cloud)string

Cloud vendor of the metastore home shard (e.g., `aws`, `azure`, `gcp`).

[`created_at`](https://docs.databricks.com/api/workspace/metastores/list#metastores-created_at)int64

Time at which this metastore was created, in epoch milliseconds.

[`created_by`](https://docs.databricks.com/api/workspace/metastores/list#metastores-created_by)string

Username of metastore creator.

[`default_data_access_config_id`](https://docs.databricks.com/api/workspace/metastores/list#metastores-default_data_access_config_id)string

Deprecated

Unique identifier of the metastore's (Default) Data Access Configuration.

[`delta_sharing_organization_name`](https://docs.databricks.com/api/workspace/metastores/list#metastores-delta_sharing_organization_name)string

The organization name of a Delta Sharing entity, to be used in Databricks-to-Databricks Delta Sharing as the official name.

[`delta_sharing_recipient_token_lifetime_in_seconds`](https://docs.databricks.com/api/workspace/metastores/list#metastores-delta_sharing_recipient_token_lifetime_in_seconds)int64

The lifetime of delta sharing recipient token in seconds.

[`delta_sharing_scope`](https://docs.databricks.com/api/workspace/metastores/list#metastores-delta_sharing_scope)string

Enum: `INTERNAL | INTERNAL_AND_EXTERNAL`

The scope of Delta Sharing enabled for the metastore.

[`external_access_enabled`](https://docs.databricks.com/api/workspace/metastores/list#metastores-external_access_enabled)boolean

Whether to allow non-DBR clients to directly access entities under the metastore.

[`global_metastore_id`](https://docs.databricks.com/api/workspace/metastores/list#metastores-global_metastore_id)string

Globally unique metastore ID across clouds and regions, of the form `cloud:region:metastore_id`.

[`metastore_id`](https://docs.databricks.com/api/workspace/metastores/list#metastores-metastore_id)string

Unique identifier of metastore.

[`name`](https://docs.databricks.com/api/workspace/metastores/list#metastores-name)string

The user-specified name of the metastore.

[`owner`](https://docs.databricks.com/api/workspace/metastores/list#metastores-owner)string

The owner of the metastore.

[`privilege_model_version`](https://docs.databricks.com/api/workspace/metastores/list#metastores-privilege_model_version)string

Privilege model version of the metastore, of the form `major.minor` (e.g., `1.0`).

[`region`](https://docs.databricks.com/api/workspace/metastores/list#metastores-region)string

Cloud region which the metastore serves (e.g., `us-west-2`, `westus`).

[`storage_root`](https://docs.databricks.com/api/workspace/metastores/list#metastores-storage_root)string

The storage root URL for metastore

[`storage_root_credential_id`](https://docs.databricks.com/api/workspace/metastores/list#metastores-storage_root_credential_id)string

UUID of storage credential to access the metastore storage_root.

[`storage_root_credential_name`](https://docs.databricks.com/api/workspace/metastores/list#metastores-storage_root_credential_name)string

Name of the storage credential to access the metastore storage_root.

[`updated_at`](https://docs.databricks.com/api/workspace/metastores/list#metastores-updated_at)int64

Time at which the metastore was last modified, in epoch milliseconds.

[`updated_by`](https://docs.databricks.com/api/workspace/metastores/list#metastores-updated_by)string

Username of user who last modified the metastore.

 ]

[`next_page_token`](https://docs.databricks.com/api/workspace/metastores/list#next_page_token)string

Opaque token to retrieve the next page of results. Absent if there are no more pages. page_token should be set to this value for the next request (for the next page of results).

# Response samples

200

{

"metastores":[

{

"cloud":"string",

"created_at":0,

"created_by":"string",

"default_data_access_config_id":"string",

"delta_sharing_organization_name":"string",

"delta_sharing_recipient_token_lifetime_in_s econds":0,

"delta_sharing_scope":"INTERNAL",

"external_access_enabled":true,

"global_metastore_id":"string",

"metastore_id":"string",

"name":"string",

"owner":"string",

"privilege_model_version":"string",

"region":"string",

"storage_root":"string",

"storage_root_credential_id":"string",

"storage_root_credential_name":"string",

"updated_at":0,

"updated_by":"string"

}

],

"next_page_token":"string"

}
