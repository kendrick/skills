Title: Update a metastore | Metastores API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/metastores/update

Markdown Content:
## Update a metastore

`PATCH/api/2.1/unity-catalog/metastores/{id}`

Updates information for a specific metastore. The caller must be a metastore admin. If the owner field is set to the empty string (""), the ownership is updated to the System User.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`id`](https://docs.databricks.com/api/workspace/metastores/update#id)required string

Unique ID of the metastore.

### Request body

[`delta_sharing_organization_name`](https://docs.databricks.com/api/workspace/metastores/update#delta_sharing_organization_name)string

The organization name of a Delta Sharing entity, to be used in Databricks-to-Databricks Delta Sharing as the official name.

[`delta_sharing_recipient_token_lifetime_in_seconds`](https://docs.databricks.com/api/workspace/metastores/update#delta_sharing_recipient_token_lifetime_in_seconds)int64

The lifetime of delta sharing recipient token in seconds.

[`delta_sharing_scope`](https://docs.databricks.com/api/workspace/metastores/update#delta_sharing_scope)string

Enum: `INTERNAL | INTERNAL_AND_EXTERNAL`

The scope of Delta Sharing enabled for the metastore.

[`external_access_enabled`](https://docs.databricks.com/api/workspace/metastores/update#external_access_enabled)boolean

Whether to allow non-DBR clients to directly access entities under the metastore.

[`new_name`](https://docs.databricks.com/api/workspace/metastores/update#new_name)string

New name for the metastore.

[`owner`](https://docs.databricks.com/api/workspace/metastores/update#owner)string

The owner of the metastore.

[`privilege_model_version`](https://docs.databricks.com/api/workspace/metastores/update#privilege_model_version)string

Privilege model version of the metastore, of the form `major.minor` (e.g., `1.0`).

[`storage_root_credential_id`](https://docs.databricks.com/api/workspace/metastores/update#storage_root_credential_id)string

UUID of storage credential to access the metastore storage_root.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`cloud`](https://docs.databricks.com/api/workspace/metastores/update#cloud)string

Cloud vendor of the metastore home shard (e.g., `aws`, `azure`, `gcp`).

[`created_at`](https://docs.databricks.com/api/workspace/metastores/update#created_at)int64

Time at which this metastore was created, in epoch milliseconds.

[`created_by`](https://docs.databricks.com/api/workspace/metastores/update#created_by)string

Username of metastore creator.

[`default_data_access_config_id`](https://docs.databricks.com/api/workspace/metastores/update#default_data_access_config_id)string

Deprecated

Unique identifier of the metastore's (Default) Data Access Configuration.

[`delta_sharing_organization_name`](https://docs.databricks.com/api/workspace/metastores/update#delta_sharing_organization_name)string

The organization name of a Delta Sharing entity, to be used in Databricks-to-Databricks Delta Sharing as the official name.

[`delta_sharing_recipient_token_lifetime_in_seconds`](https://docs.databricks.com/api/workspace/metastores/update#delta_sharing_recipient_token_lifetime_in_seconds)int64

The lifetime of delta sharing recipient token in seconds.

[`delta_sharing_scope`](https://docs.databricks.com/api/workspace/metastores/update#delta_sharing_scope)string

Enum: `INTERNAL | INTERNAL_AND_EXTERNAL`

The scope of Delta Sharing enabled for the metastore.

[`external_access_enabled`](https://docs.databricks.com/api/workspace/metastores/update#external_access_enabled)boolean

Whether to allow non-DBR clients to directly access entities under the metastore.

[`global_metastore_id`](https://docs.databricks.com/api/workspace/metastores/update#global_metastore_id)string

Globally unique metastore ID across clouds and regions, of the form `cloud:region:metastore_id`.

[`metastore_id`](https://docs.databricks.com/api/workspace/metastores/update#metastore_id)string

Unique identifier of metastore.

[`name`](https://docs.databricks.com/api/workspace/metastores/update#name)string

The user-specified name of the metastore.

[`owner`](https://docs.databricks.com/api/workspace/metastores/update#owner)string

The owner of the metastore.

[`privilege_model_version`](https://docs.databricks.com/api/workspace/metastores/update#privilege_model_version)string

Privilege model version of the metastore, of the form `major.minor` (e.g., `1.0`).

[`region`](https://docs.databricks.com/api/workspace/metastores/update#region)string

Cloud region which the metastore serves (e.g., `us-west-2`, `westus`).

[`storage_root`](https://docs.databricks.com/api/workspace/metastores/update#storage_root)string

The storage root URL for metastore

[`storage_root_credential_id`](https://docs.databricks.com/api/workspace/metastores/update#storage_root_credential_id)string

UUID of storage credential to access the metastore storage_root.

[`storage_root_credential_name`](https://docs.databricks.com/api/workspace/metastores/update#storage_root_credential_name)string

Name of the storage credential to access the metastore storage_root.

[`updated_at`](https://docs.databricks.com/api/workspace/metastores/update#updated_at)int64

Time at which the metastore was last modified, in epoch milliseconds.

[`updated_by`](https://docs.databricks.com/api/workspace/metastores/update#updated_by)string

Username of user who last modified the metastore.

# Request samples

JSON

{

"delta_sharing_organization_name":"string",

"delta_sharing_recipient_token_lifetime_in_secon ds":0,

"delta_sharing_scope":"INTERNAL",

"external_access_enabled":true,

"new_name":"string",

"owner":"string",

"privilege_model_version":"string",

"storage_root_credential_id":"string"

}

# Response samples

200

{

"cloud":"string",

"created_at":0,

"created_by":"string",

"default_data_access_config_id":"string",

"delta_sharing_organization_name":"string",

"delta_sharing_recipient_token_lifetime_in_secon ds":0,

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
