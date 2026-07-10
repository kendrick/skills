Title: List shares | Shares API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/shares/listshares

Markdown Content:
## List shares

`GET/api/2.1/unity-catalog/shares`

Gets an array of data object shares from the metastore. If the caller has the USE_SHARE privilege on the metastore, all shares are returned. Otherwise, only shares owned by the caller are returned. There is no guarantee of a specific ordering of the elements in the array.

API scopes (preview):[`sharing`](https://docs.databricks.com/api/workspace/api/scopes#sharing)

### Query parameters

[`max_results`](https://docs.databricks.com/api/workspace/shares/listshares#max_results)int32

<= 1000 

Maximum number of shares to return.

*   when set to 0, the page length is set to a server configured value (recommended);
*   when set to a value greater than 0, the page length is the minimum of this value and a server configured value;
*   when set to a value less than 0, an invalid parameter error is returned;
*   If not set, all valid shares are returned (not recommended).
*   Note: The number of returned shares might be less than the specified max_results size, even zero. The only definitive indication that no further shares can be fetched is when the next_page_token is unset from the response.

[`page_token`](https://docs.databricks.com/api/workspace/shares/listshares#page_token)string

Opaque pagination token to go to next page based on previous query.

### Responses

**200** Request completed successfully. The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

Request completed successfully.

 The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

[`next_page_token`](https://docs.databricks.com/api/workspace/shares/listshares#next_page_token)string

Opaque token to retrieve the next page of results. Absent if there are no more pages. page_token should be set to this value for the next request (for the next page of results).

[`shares`](https://docs.databricks.com/api/workspace/shares/listshares#shares)Array of object

An array of data share information objects.

Array [

[`comment`](https://docs.databricks.com/api/workspace/shares/listshares#shares-comment)string

User-provided free-form text description.

[`created_at`](https://docs.databricks.com/api/workspace/shares/listshares#shares-created_at)int64

Time at which this share was created, in epoch milliseconds.

[`created_by`](https://docs.databricks.com/api/workspace/shares/listshares#shares-created_by)string

Username of share creator.

[`name`](https://docs.databricks.com/api/workspace/shares/listshares#shares-name)string

Name of the share.

[`objects`](https://docs.databricks.com/api/workspace/shares/listshares#shares-objects)Array of object

A list of shared data objects within the share.

[`owner`](https://docs.databricks.com/api/workspace/shares/listshares#shares-owner)string

Username of current owner of share.

[`storage_location`](https://docs.databricks.com/api/workspace/shares/listshares#shares-storage_location)string

Storage Location URL (full path) for the share.

[`storage_root`](https://docs.databricks.com/api/workspace/shares/listshares#shares-storage_root)string

Storage root URL for the share.

[`updated_at`](https://docs.databricks.com/api/workspace/shares/listshares#shares-updated_at)int64

Time at which this share was updated, in epoch milliseconds.

[`updated_by`](https://docs.databricks.com/api/workspace/shares/listshares#shares-updated_by)string

Username of share updater.

 ]

# Response samples

200

{

"next_page_token":"string",

"shares":[

{

"comment":"string",

"created_at":0,

"created_by":"string",

"name":"string",

"objects":[

{

"added_at":0,

"added_by":"string",

"cdf_enabled":true,

"comment":"string",

"content":"string",

"data_object_type":"TABLE",

"history_data_sharing_status":"DISABLED",

"name":"string",

"partitions":[

{

"values":[

{

"name":"string",

"op":"EQUAL",

"recipient_property_key":"strin g",

"value":"string"

}

]

}

],

"shared_as":"string",

"start_version":0,

"status":"ACTIVE",

"string_shared_as":"string"

}

],

"owner":"string",

"storage_location":"string",

"storage_root":"string",

"updated_at":0,

"updated_by":"string"

}

]

}
