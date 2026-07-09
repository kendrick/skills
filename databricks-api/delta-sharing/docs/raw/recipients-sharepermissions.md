Title: Get recipient share permissions | Recipients API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/recipients/sharepermissions

Markdown Content:
## Get recipient share permissions

`GET/api/2.1/unity-catalog/recipients/{name}/share-permissions`

Gets the share permissions for the specified Recipient. The caller must have the USE_RECIPIENT privilege on the metastore or be the owner of the Recipient.

API scopes (preview):[`sharing`](https://docs.databricks.com/api/workspace/api/scopes#sharing)

### Path parameters

[`name`](https://docs.databricks.com/api/workspace/recipients/sharepermissions#name)required string

The name of the Recipient.

### Query parameters

[`max_results`](https://docs.databricks.com/api/workspace/recipients/sharepermissions#max_results)int32

<= 1000 

Maximum number of permissions to return.

*   when set to 0, the page length is set to a server configured value (recommended);
*   when set to a value greater than 0, the page length is the minimum of this value and a server configured value;
*   when set to a value less than 0, an invalid parameter error is returned;
*   If not set, all valid permissions are returned (not recommended).
*   Note: The number of returned permissions might be less than the specified max_results size, even zero. The only definitive indication that no further permissions can be fetched is when the next_page_token is unset from the response.

[`page_token`](https://docs.databricks.com/api/workspace/recipients/sharepermissions#page_token)string

Opaque pagination token to go to next page based on previous query.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`next_page_token`](https://docs.databricks.com/api/workspace/recipients/sharepermissions#next_page_token)string

Opaque token to retrieve the next page of results. Absent if there are no more pages. page_token should be set to this value for the next request (for the next page of results).

[`permissions_out`](https://docs.databricks.com/api/workspace/recipients/sharepermissions#permissions_out)Array of object

An array of data share permissions for a recipient.

Array [

[`privilege_assignments`](https://docs.databricks.com/api/workspace/recipients/sharepermissions#permissions_out-privilege_assignments)Array of object

The privileges assigned to the principal.

[`share_name`](https://docs.databricks.com/api/workspace/recipients/sharepermissions#permissions_out-share_name)string

The share name.

 ]

# Response samples

200

{

"next_page_token":"string",

"permissions_out":[

{

"privilege_assignments":[

{

"principal":"string",

"privileges":[

"SELECT"

]

}

],

"share_name":"string"

}

]

}
