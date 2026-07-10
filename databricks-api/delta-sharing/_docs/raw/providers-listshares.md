Title: List shares by Provider | Providers API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/providers/listshares

Markdown Content:
## List shares by Provider

`GET/api/2.1/unity-catalog/providers/{name}/shares`

Gets an array of a specified provider's shares within the metastore where:

*   the caller is a metastore admin, or
*   the caller is the owner.

API scopes (preview):[`sharing`](https://docs.databricks.com/api/workspace/api/scopes#sharing)

### Path parameters

[`name`](https://docs.databricks.com/api/workspace/providers/listshares#name)required string

Name of the provider in which to list shares.

### Query parameters

[`max_results`](https://docs.databricks.com/api/workspace/providers/listshares#max_results)int32

<= 1000 

Maximum number of shares to return.

*   when set to 0, the page length is set to a server configured value (recommended);
*   when set to a value greater than 0, the page length is the minimum of this value and a server configured value;
*   when set to a value less than 0, an invalid parameter error is returned;
*   If not set, all valid shares are returned (not recommended).
*   Note: The number of returned shares might be less than the specified max_results size, even zero. The only definitive indication that no further shares can be fetched is when the next_page_token is unset from the response.

[`page_token`](https://docs.databricks.com/api/workspace/providers/listshares#page_token)string

Opaque pagination token to go to next page based on previous query.

### Responses

**200** Request completed successfully. The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

Request completed successfully.

 The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

[`next_page_token`](https://docs.databricks.com/api/workspace/providers/listshares#next_page_token)string

Opaque token to retrieve the next page of results. Absent if there are no more pages. page_token should be set to this value for the next request (for the next page of results).

[`shares`](https://docs.databricks.com/api/workspace/providers/listshares#shares)Array of object

An array of provider shares.

Array [

[`name`](https://docs.databricks.com/api/workspace/providers/listshares#shares-name)string

The name of the Provider Share.

 ]

# Response samples

200

{

"next_page_token":"string",

"shares":[

{

"name":"string"

}

]

}
