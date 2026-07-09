Title: Get securable workspace bindings | Workspace Bindings API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/workspacebindings/getbindings

Markdown Content:
## Get securable workspace bindings

`GET/api/2.1/unity-catalog/bindings/{securable_type}/{securable_name}`

Gets workspace bindings of the securable. The caller must be a metastore admin or an owner of the securable.

NOTE: we recommend using max_results=0 to use the paginated version of this API. Unpaginated calls will be deprecated soon.

PAGINATION BEHAVIOR: When using pagination (max_results >= 0), a page may contain zero results while still providing a next_page_token. Clients must continue reading pages until next_page_token is absent, which is the only indication that the end of results has been reached.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`securable_type`](https://docs.databricks.com/api/workspace/workspacebindings/getbindings#securable_type)required string

The type of the securable to bind to a workspace (catalog, storage_credential, credential, or external_location).

[`securable_name`](https://docs.databricks.com/api/workspace/workspacebindings/getbindings#securable_name)required string

The name of the securable.

### Query parameters

[`max_results`](https://docs.databricks.com/api/workspace/workspacebindings/getbindings#max_results)int32

<= 1000 

Maximum number of workspace bindings to return.

*   When set to 0, the page length is set to a server configured value (recommended);
*   When set to a value greater than 0, the page length is the minimum of this value and a server configured value;
*   When set to a value less than 0, an invalid parameter error is returned;
*   If not set, all the workspace bindings are returned (not recommended).

[`page_token`](https://docs.databricks.com/api/workspace/workspacebindings/getbindings#page_token)string

Opaque pagination token to go to next page based on previous query.

### Responses

**200** Request completed successfully. The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

Request completed successfully.

 The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

[`bindings`](https://docs.databricks.com/api/workspace/workspacebindings/getbindings#bindings)Array of object

List of workspace bindings

Array [

[`binding_type`](https://docs.databricks.com/api/workspace/workspacebindings/getbindings#bindings-binding_type)string

Enum: `BINDING_TYPE_READ_WRITE | BINDING_TYPE_READ_ONLY`

One of READ_WRITE/READ_ONLY. Default is READ_WRITE.

[`workspace_id`](https://docs.databricks.com/api/workspace/workspacebindings/getbindings#bindings-workspace_id)int64

Required

 ]

[`next_page_token`](https://docs.databricks.com/api/workspace/workspacebindings/getbindings#next_page_token)string

Opaque token to retrieve the next page of results. Absent if there are no more pages. page_token should be set to this value for the next request (for the next page of results).

# Response samples

200

{

"bindings":[

{

"binding_type":"BINDING_TYPE_READ_WRITE",

"workspace_id":0

}

],

"next_page_token":"string"

}
