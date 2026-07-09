Title: Get a share recipient | Recipients API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/recipients/get

Markdown Content:
## Get a share recipient

`GET/api/2.1/unity-catalog/recipients/{name}`

Gets a share recipient from the metastore. The caller must be one of:

*   A user with USE_RECIPIENT privilege on the metastore
*   The owner of the share recipient
*   A metastore admin

API scopes (preview):[`sharing`](https://docs.databricks.com/api/workspace/api/scopes#sharing)

### Path parameters

[`name`](https://docs.databricks.com/api/workspace/recipients/get#name)required string

Name of the recipient.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`activated`](https://docs.databricks.com/api/workspace/recipients/get#activated)boolean

Deprecated

A boolean status field showing whether the Recipient's activation URL has been exercised or not.

[`activation_url`](https://docs.databricks.com/api/workspace/recipients/get#activation_url)string

Deprecated

Full activation url to retrieve the access token. It will be empty if the token is already retrieved.

[`authentication_type`](https://docs.databricks.com/api/workspace/recipients/get#authentication_type)string

Enum: `TOKEN | DATABRICKS | OIDC_FEDERATION | OAUTH_CLIENT_CREDENTIALS`

The delta sharing authentication type.

[`cloud`](https://docs.databricks.com/api/workspace/recipients/get#cloud)string

Cloud vendor of the recipient's Unity Catalog Metastore. This field is only present when the authentication_type is DATABRICKS.

[`comment`](https://docs.databricks.com/api/workspace/recipients/get#comment)string

Description about the recipient.

[`created_at`](https://docs.databricks.com/api/workspace/recipients/get#created_at)int64

Time at which this recipient was created, in epoch milliseconds.

[`created_by`](https://docs.databricks.com/api/workspace/recipients/get#created_by)string

Username of recipient creator.

[`data_recipient_global_metastore_id`](https://docs.databricks.com/api/workspace/recipients/get#data_recipient_global_metastore_id)string

The global Unity Catalog metastore id provided by the data recipient. This field is only present when the authentication_type is DATABRICKS. The identifier is of format cloud:region:metastore-uuid.

[`expiration_time`](https://docs.databricks.com/api/workspace/recipients/get#expiration_time)int64

Expiration timestamp of the token, in epoch milliseconds.

[`id`](https://docs.databricks.com/api/workspace/recipients/get#id)string

[Create,Update:IGN] common - id of the recipient

[`ip_access_list`](https://docs.databricks.com/api/workspace/recipients/get#ip_access_list)object

IP Access List

[`allowed_ip_addresses`](https://docs.databricks.com/api/workspace/recipients/get#ip_access_list-allowed_ip_addresses)Array of string

Allowed IP Addresses in CIDR notation. Limit of 100.

[`metastore_id`](https://docs.databricks.com/api/workspace/recipients/get#metastore_id)string

Unique identifier of recipient's Unity Catalog Metastore. This field is only present when the authentication_type is DATABRICKS.

[`name`](https://docs.databricks.com/api/workspace/recipients/get#name)string

Name of Recipient.

[`owner`](https://docs.databricks.com/api/workspace/recipients/get#owner)string

Username of the recipient owner.

[`properties_kvpairs`](https://docs.databricks.com/api/workspace/recipients/get#properties_kvpairs)object

Recipient properties as map of string key-value pairs. When provided in update request, the specified properties will override the existing properties. To add and remove properties, one would need to perform a read-modify-write.

[`properties`](https://docs.databricks.com/api/workspace/recipients/get#properties_kvpairs-properties)object

A map of key-value properties attached to the securable.

[`region`](https://docs.databricks.com/api/workspace/recipients/get#region)string

Cloud region of the recipient's Unity Catalog Metastore. This field is only present when the authentication_type is DATABRICKS.

[`sharing_code`](https://docs.databricks.com/api/workspace/recipients/get#sharing_code)string

The one-time sharing code provided by the data recipient. This field is only present when the authentication_type is DATABRICKS.

[`tokens`](https://docs.databricks.com/api/workspace/recipients/get#tokens)Array of object

This field is only present when the authentication_type is TOKEN.

Array [

[`activation_url`](https://docs.databricks.com/api/workspace/recipients/get#tokens-activation_url)string

Full activation URL to retrieve the access token. It will be empty if the token is already retrieved.

[`created_at`](https://docs.databricks.com/api/workspace/recipients/get#tokens-created_at)int64

Time at which this recipient token was created, in epoch milliseconds.

[`created_by`](https://docs.databricks.com/api/workspace/recipients/get#tokens-created_by)string

Username of recipient token creator.

[`expiration_time`](https://docs.databricks.com/api/workspace/recipients/get#tokens-expiration_time)int64

Expiration timestamp of the token in epoch milliseconds.

[`id`](https://docs.databricks.com/api/workspace/recipients/get#tokens-id)string

Unique ID of the recipient token.

[`updated_at`](https://docs.databricks.com/api/workspace/recipients/get#tokens-updated_at)int64

Time at which this recipient token was updated, in epoch milliseconds.

[`updated_by`](https://docs.databricks.com/api/workspace/recipients/get#tokens-updated_by)string

Username of recipient token updater.

 ]

[`updated_at`](https://docs.databricks.com/api/workspace/recipients/get#updated_at)int64

Time at which the recipient was updated, in epoch milliseconds.

[`updated_by`](https://docs.databricks.com/api/workspace/recipients/get#updated_by)string

Username of recipient updater.

# Response samples

200

{

"activated":true,

"activation_url":"string",

"authentication_type":"TOKEN",

"cloud":"string",

"comment":"string",

"created_at":0,

"created_by":"string",

"data_recipient_global_metastore_id":"string",

"expiration_time":0,

"id":"string",

"ip_access_list":{

"allowed_ip_addresses":[

"string"

]

},

"metastore_id":"string",

"name":"string",

"owner":"string",

"properties_kvpairs":{

"properties":{

"property1":"string",

"property2":"string"

}

},

"region":"string",

"sharing_code":"string",

"tokens":[

{

"activation_url":"string",

"created_at":0,

"created_by":"string",

"expiration_time":0,

"id":"string",

"updated_at":0,

"updated_by":"string"

}

],

"updated_at":0,

"updated_by":"string"

}
