Title: List providers | Providers API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/providers/list

Markdown Content:
## List providers

`GET/api/2.1/unity-catalog/providers`

Gets an array of available authentication providers. The caller must either be a metastore admin, have the USE_PROVIDER privilege on the providers, or be the owner of the providers. Providers not owned by the caller and for which the caller does not have the USE_PROVIDER privilege are not included in the response. There is no guarantee of a specific ordering of the elements in the array.

API scopes (preview):[`sharing`](https://docs.databricks.com/api/workspace/api/scopes#sharing)

### Query parameters

[`data_provider_global_metastore_id`](https://docs.databricks.com/api/workspace/providers/list#data_provider_global_metastore_id)string

If not provided, all providers will be returned. If no providers exist with this ID, no results will be returned.

[`max_results`](https://docs.databricks.com/api/workspace/providers/list#max_results)int32

<= 1000 

Maximum number of providers to return.

*   when set to 0, the page length is set to a server configured value (recommended);
*   when set to a value greater than 0, the page length is the minimum of this value and a server configured value;
*   when set to a value less than 0, an invalid parameter error is returned;
*   If not set, all valid providers are returned (not recommended).
*   Note: The number of returned providers might be less than the specified max_results size, even zero. The only definitive indication that no further providers can be fetched is when the next_page_token is unset from the response.

[`page_token`](https://docs.databricks.com/api/workspace/providers/list#page_token)string

Opaque pagination token to go to next page based on previous query.

### Responses

**200** Request completed successfully. The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

Request completed successfully.

 The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

[`next_page_token`](https://docs.databricks.com/api/workspace/providers/list#next_page_token)string

Opaque token to retrieve the next page of results. Absent if there are no more pages. page_token should be set to this value for the next request (for the next page of results).

[`providers`](https://docs.databricks.com/api/workspace/providers/list#providers)Array of object

An array of provider information objects.

Array [

[`authentication_type`](https://docs.databricks.com/api/workspace/providers/list#providers-authentication_type)string

Enum: `TOKEN | DATABRICKS | OIDC_FEDERATION | OAUTH_CLIENT_CREDENTIALS`

The delta sharing authentication type.

[`cloud`](https://docs.databricks.com/api/workspace/providers/list#providers-cloud)string

Cloud vendor of the provider's UC metastore. This field is only present when the authentication_type is DATABRICKS.

[`comment`](https://docs.databricks.com/api/workspace/providers/list#providers-comment)string

Description about the provider.

[`created_at`](https://docs.databricks.com/api/workspace/providers/list#providers-created_at)int64

Time at which this Provider was created, in epoch milliseconds.

[`created_by`](https://docs.databricks.com/api/workspace/providers/list#providers-created_by)string

Username of Provider creator.

[`data_provider_global_metastore_id`](https://docs.databricks.com/api/workspace/providers/list#providers-data_provider_global_metastore_id)string

The global UC metastore id of the data provider. This field is only present when the authentication_type is DATABRICKS. The identifier is of format cloud:region:metastore-uuid.

[`metastore_id`](https://docs.databricks.com/api/workspace/providers/list#providers-metastore_id)string

UUID of the provider's UC metastore. This field is only present when the authentication_type is DATABRICKS.

[`name`](https://docs.databricks.com/api/workspace/providers/list#providers-name)string

The name of the Provider.

[`owner`](https://docs.databricks.com/api/workspace/providers/list#providers-owner)string

Username of Provider owner.

[`recipient_profile`](https://docs.databricks.com/api/workspace/providers/list#providers-recipient_profile)object

The recipient profile. This field is only present when the authentication_type is `TOKEN` or `OAUTH_CLIENT_CREDENTIALS`.

[`recipient_profile_str`](https://docs.databricks.com/api/workspace/providers/list#providers-recipient_profile_str)string

This field is required when the authentication_type is TOKEN, OAUTH_CLIENT_CREDENTIALS or not provided.

[`region`](https://docs.databricks.com/api/workspace/providers/list#providers-region)string

Cloud region of the provider's UC metastore. This field is only present when the authentication_type is DATABRICKS.

[`updated_at`](https://docs.databricks.com/api/workspace/providers/list#providers-updated_at)int64

Time at which this Provider was created, in epoch milliseconds.

[`updated_by`](https://docs.databricks.com/api/workspace/providers/list#providers-updated_by)string

Username of user who last modified Provider.

 ]

# Response samples

200

{

"next_page_token":"string",

"providers":[

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

]

}
