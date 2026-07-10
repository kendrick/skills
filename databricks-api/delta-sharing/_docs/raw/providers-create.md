Title: Create an auth provider | Providers API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/providers/create

Markdown Content:
## Create an auth provider

`POST/api/2.1/unity-catalog/providers`

Creates a new authentication provider minimally based on a name and authentication type. The caller must be an admin on the metastore.

API scopes (preview):[`sharing`](https://docs.databricks.com/api/workspace/api/scopes#sharing)

### Request body

[`authentication_type`](https://docs.databricks.com/api/workspace/providers/create#authentication_type)required string

Enum: `TOKEN | DATABRICKS | OIDC_FEDERATION | OAUTH_CLIENT_CREDENTIALS`

The delta sharing authentication type.

[`comment`](https://docs.databricks.com/api/workspace/providers/create#comment)string

Description about the provider.

[`name`](https://docs.databricks.com/api/workspace/providers/create#name)required string

The name of the Provider.

[`recipient_profile_str`](https://docs.databricks.com/api/workspace/providers/create#recipient_profile_str)string

This field is required when the authentication_type is TOKEN, OAUTH_CLIENT_CREDENTIALS or not provided.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`authentication_type`](https://docs.databricks.com/api/workspace/providers/create#authentication_type)string

Enum: `TOKEN | DATABRICKS | OIDC_FEDERATION | OAUTH_CLIENT_CREDENTIALS`

The delta sharing authentication type.

[`cloud`](https://docs.databricks.com/api/workspace/providers/create#cloud)string

Cloud vendor of the provider's UC metastore. This field is only present when the authentication_type is DATABRICKS.

[`comment`](https://docs.databricks.com/api/workspace/providers/create#comment)string

Description about the provider.

[`created_at`](https://docs.databricks.com/api/workspace/providers/create#created_at)int64

Time at which this Provider was created, in epoch milliseconds.

[`created_by`](https://docs.databricks.com/api/workspace/providers/create#created_by)string

Username of Provider creator.

[`data_provider_global_metastore_id`](https://docs.databricks.com/api/workspace/providers/create#data_provider_global_metastore_id)string

The global UC metastore id of the data provider. This field is only present when the authentication_type is DATABRICKS. The identifier is of format cloud:region:metastore-uuid.

[`metastore_id`](https://docs.databricks.com/api/workspace/providers/create#metastore_id)string

UUID of the provider's UC metastore. This field is only present when the authentication_type is DATABRICKS.

[`name`](https://docs.databricks.com/api/workspace/providers/create#name)string

The name of the Provider.

[`owner`](https://docs.databricks.com/api/workspace/providers/create#owner)string

Username of Provider owner.

[`recipient_profile`](https://docs.databricks.com/api/workspace/providers/create#recipient_profile)object

The recipient profile. This field is only present when the authentication_type is `TOKEN` or `OAUTH_CLIENT_CREDENTIALS`.

[`bearer_token`](https://docs.databricks.com/api/workspace/providers/create#recipient_profile-bearer_token)string

The token used to authorize the recipient.

[`endpoint`](https://docs.databricks.com/api/workspace/providers/create#recipient_profile-endpoint)string

The endpoint for the share to be used by the recipient.

[`share_credentials_version`](https://docs.databricks.com/api/workspace/providers/create#recipient_profile-share_credentials_version)int32

The version number of the recipient's credentials on a share.

[`recipient_profile_str`](https://docs.databricks.com/api/workspace/providers/create#recipient_profile_str)string

This field is required when the authentication_type is TOKEN, OAUTH_CLIENT_CREDENTIALS or not provided.

[`region`](https://docs.databricks.com/api/workspace/providers/create#region)string

Cloud region of the provider's UC metastore. This field is only present when the authentication_type is DATABRICKS.

[`updated_at`](https://docs.databricks.com/api/workspace/providers/create#updated_at)int64

Time at which this Provider was created, in epoch milliseconds.

[`updated_by`](https://docs.databricks.com/api/workspace/providers/create#updated_by)string

Username of user who last modified Provider.

# Request samples

JSON

{

"authentication_type":"TOKEN",

"comment":"string",

"name":"string",

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
