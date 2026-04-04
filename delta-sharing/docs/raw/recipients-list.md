Title: List share recipients | Recipients API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/recipients/list

Markdown Content:
## List share recipients

`GET/api/2.1/unity-catalog/recipients`

Gets an array of all share recipients within the current metastore where:

*   the caller is a metastore admin, or
*   the caller is the owner. There is no guarantee of a specific ordering of the elements in the array.

API scopes (preview):[`sharing`](https://docs.databricks.com/api/workspace/api/scopes#sharing)

### Query parameters

[`data_recipient_global_metastore_id`](https://docs.databricks.com/api/workspace/recipients/list#data_recipient_global_metastore_id)string

If not provided, all recipients will be returned. If no recipients exist with this ID, no results will be returned.

[`max_results`](https://docs.databricks.com/api/workspace/recipients/list#max_results)int32

<= 1000 

Maximum number of recipients to return.

*   when set to 0, the page length is set to a server configured value (recommended);
*   when set to a value greater than 0, the page length is the minimum of this value and a server configured value;
*   when set to a value less than 0, an invalid parameter error is returned;
*   If not set, all valid recipients are returned (not recommended).
*   Note: The number of returned recipients might be less than the specified max_results size, even zero. The only definitive indication that no further recipients can be fetched is when the next_page_token is unset from the response.

[`page_token`](https://docs.databricks.com/api/workspace/recipients/list#page_token)string

Opaque pagination token to go to next page based on previous query.

### Responses

**200** Request completed successfully. The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

Request completed successfully.

 The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

[`next_page_token`](https://docs.databricks.com/api/workspace/recipients/list#next_page_token)string

Opaque token to retrieve the next page of results. Absent if there are no more pages. page_token should be set to this value for the next request (for the next page of results).

[`recipients`](https://docs.databricks.com/api/workspace/recipients/list#recipients)Array of object

An array of recipient information objects.

Array [

[`activated`](https://docs.databricks.com/api/workspace/recipients/list#recipients-activated)boolean

Deprecated

A boolean status field showing whether the Recipient's activation URL has been exercised or not.

[`activation_url`](https://docs.databricks.com/api/workspace/recipients/list#recipients-activation_url)string

Deprecated

Full activation url to retrieve the access token. It will be empty if the token is already retrieved.

[`authentication_type`](https://docs.databricks.com/api/workspace/recipients/list#recipients-authentication_type)string

Enum: `TOKEN | DATABRICKS | OIDC_FEDERATION | OAUTH_CLIENT_CREDENTIALS`

The delta sharing authentication type.

[`cloud`](https://docs.databricks.com/api/workspace/recipients/list#recipients-cloud)string

Cloud vendor of the recipient's Unity Catalog Metastore. This field is only present when the authentication_type is DATABRICKS.

[`comment`](https://docs.databricks.com/api/workspace/recipients/list#recipients-comment)string

Description about the recipient.

[`created_at`](https://docs.databricks.com/api/workspace/recipients/list#recipients-created_at)int64

Time at which this recipient was created, in epoch milliseconds.

[`created_by`](https://docs.databricks.com/api/workspace/recipients/list#recipients-created_by)string

Username of recipient creator.

[`data_recipient_global_metastore_id`](https://docs.databricks.com/api/workspace/recipients/list#recipients-data_recipient_global_metastore_id)string

The global Unity Catalog metastore id provided by the data recipient. This field is only present when the authentication_type is DATABRICKS. The identifier is of format cloud:region:metastore-uuid.

[`expiration_time`](https://docs.databricks.com/api/workspace/recipients/list#recipients-expiration_time)int64

Expiration timestamp of the token, in epoch milliseconds.

[`id`](https://docs.databricks.com/api/workspace/recipients/list#recipients-id)string

[Create,Update:IGN] common - id of the recipient

[`ip_access_list`](https://docs.databricks.com/api/workspace/recipients/list#recipients-ip_access_list)object

IP Access List

[`metastore_id`](https://docs.databricks.com/api/workspace/recipients/list#recipients-metastore_id)string

Unique identifier of recipient's Unity Catalog Metastore. This field is only present when the authentication_type is DATABRICKS.

[`name`](https://docs.databricks.com/api/workspace/recipients/list#recipients-name)string

Name of Recipient.

[`owner`](https://docs.databricks.com/api/workspace/recipients/list#recipients-owner)string

Username of the recipient owner.

[`properties_kvpairs`](https://docs.databricks.com/api/workspace/recipients/list#recipients-properties_kvpairs)object

Recipient properties as map of string key-value pairs. When provided in update request, the specified properties will override the existing properties. To add and remove properties, one would need to perform a read-modify-write.

[`region`](https://docs.databricks.com/api/workspace/recipients/list#recipients-region)string

Cloud region of the recipient's Unity Catalog Metastore. This field is only present when the authentication_type is DATABRICKS.

[`sharing_code`](https://docs.databricks.com/api/workspace/recipients/list#recipients-sharing_code)string

The one-time sharing code provided by the data recipient. This field is only present when the authentication_type is DATABRICKS.

[`tokens`](https://docs.databricks.com/api/workspace/recipients/list#recipients-tokens)Array of object

This field is only present when the authentication_type is TOKEN.

[`updated_at`](https://docs.databricks.com/api/workspace/recipients/list#recipients-updated_at)int64

Time at which the recipient was updated, in epoch milliseconds.

[`updated_by`](https://docs.databricks.com/api/workspace/recipients/list#recipients-updated_by)string

Username of recipient updater.

 ]

# Response samples

200

{

"next_page_token":"string",

"recipients":[

{

"activated":true,

"activation_url":"string",

"authentication_type":"TOKEN",

"cloud":"string",

"comment":"string",

"created_at":0,

"created_by":"string",

"data_recipient_global_metastore_id":"strin g",

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

]

}
