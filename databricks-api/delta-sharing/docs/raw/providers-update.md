Title: Update a provider | Providers API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/providers/update

Markdown Content:
## Update a provider

`PATCH/api/2.1/unity-catalog/providers/{name}`

Updates the information for an authentication provider, if the caller is a metastore admin or is the owner of the provider. If the update changes the provider name, the caller must be both a metastore admin and the owner of the provider.

API scopes (preview):[`sharing`](https://docs.databricks.com/api/workspace/api/scopes#sharing)

### Path parameters

[`name`](https://docs.databricks.com/api/workspace/providers/update#name)required string

Name of the provider.

### Request body

[`comment`](https://docs.databricks.com/api/workspace/providers/update#comment)string

Description about the provider.

[`new_name`](https://docs.databricks.com/api/workspace/providers/update#new_name)string

New name for the provider.

[`owner`](https://docs.databricks.com/api/workspace/providers/update#owner)string

Username of Provider owner.

[`recipient_profile_str`](https://docs.databricks.com/api/workspace/providers/update#recipient_profile_str)string

This field is required when the authentication_type is TOKEN, OAUTH_CLIENT_CREDENTIALS or not provided.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`authentication_type`](https://docs.databricks.com/api/workspace/providers/update#authentication_type)string

Enum: `TOKEN | DATABRICKS | OIDC_FEDERATION | OAUTH_CLIENT_CREDENTIALS`

The delta sharing authentication type.

[`cloud`](https://docs.databricks.com/api/workspace/providers/update#cloud)string

Cloud vendor of the provider's UC metastore. This field is only present when the authentication_type is DATABRICKS.

[`comment`](https://docs.databricks.com/api/workspace/providers/update#comment)string

Description about the provider.

[`created_at`](https://docs.databricks.com/api/workspace/providers/update#created_at)int64

Time at which this Provider was created, in epoch milliseconds.

[`created_by`](https://docs.databricks.com/api/workspace/providers/update#created_by)string

Username of Provider creator.

[`data_provider_global_metastore_id`](https://docs.databricks.com/api/workspace/providers/update#data_provider_global_metastore_id)string

The global UC metastore id of the data provider. This field is only present when the authentication_type is DATABRICKS. The identifier is of format cloud:region:metastore-uuid.

[`metastore_id`](https://docs.databricks.com/api/workspace/providers/update#metastore_id)string

UUID of the provider's UC metastore. This field is only present when the authentication_type is DATABRICKS.

[`name`](https://docs.databricks.com/api/workspace/providers/update#name)string

The name of the Provider.

[`owner`](https://docs.databricks.com/api/workspace/providers/update#owner)string

Username of Provider owner.

[`recipient_profile`](https://docs.databricks.com/api/workspace/providers/update#recipient_profile)object

The recipient profile. This field is only present when the authentication_type is `TOKEN` or `OAUTH_CLIENT_CREDENTIALS`.

[`bearer_token`](https://docs.databricks.com/api/workspace/providers/update#recipient_profile-bearer_token)string

The token used to authorize the recipient.

[`endpoint`](https://docs.databricks.com/api/workspace/providers/update#recipient_profile-endpoint)string

The endpoint for the share to be used by the recipient.

[`share_credentials_version`](https://docs.databricks.com/api/workspace/providers/update#recipient_profile-share_credentials_version)int32

The version number of the recipient's credentials on a share.

[`recipient_profile_str`](https://docs.databricks.com/api/workspace/providers/update#recipient_profile_str)string

This field is required when the authentication_type is TOKEN, OAUTH_CLIENT_CREDENTIALS or not provided.

[`region`](https://docs.databricks.com/api/workspace/providers/update#region)string

Cloud region of the provider's UC metastore. This field is only present when the authentication_type is DATABRICKS.

[`updated_at`](https://docs.databricks.com/api/workspace/providers/update#updated_at)int64

Time at which this Provider was created, in epoch milliseconds.

[`updated_by`](https://docs.databricks.com/api/workspace/providers/update#updated_by)string

Username of user who last modified Provider.

# Request samples

JSON

{

"comment":"string",

"new_name":"string",

"owner":"string",

"recipient_profile_str":"string"

}

# Response samples

200

{

"authentication_type":"TOKEN",

"cloud":"string",

"comment":"string",

"created_at":0,

"created_by":"string",

"data_provider_global_metastore_id":"string",

"metastore_id":"string",

"name":"string",

"owner":"string",

"recipient_profile":{

"bearer_token":"string",

"endpoint":"string",

"share_credentials_version":0

},

"recipient_profile_str":"string",

"region":"string",

"updated_at":0,

"updated_by":"string"

}
