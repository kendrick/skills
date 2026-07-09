Title: List all resource quotas under a metastore. | Resource Quotas API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/resourcequotas/listquotas

Markdown Content:
## List all resource quotas under a metastore.

`GET/api/2.1/unity-catalog/resource-quotas/all-resource-quotas`

ListQuotas returns all quota values under the metastore. There are no SLAs on the freshness of the counts returned. This API does not trigger a refresh of quota counts.

PAGINATION BEHAVIOR: The API is by default paginated, a page may contain zero results while still providing a next_page_token. Clients must continue reading pages until next_page_token is absent, which is the only indication that the end of results has been reached.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Query parameters

[`max_results`](https://docs.databricks.com/api/workspace/resourcequotas/listquotas#max_results)int32

The number of quotas to return.

[`page_token`](https://docs.databricks.com/api/workspace/resourcequotas/listquotas#page_token)string

Opaque token for the next page of results.

### Responses

**200** Request completed successfully. The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

Request completed successfully.

 The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

[`next_page_token`](https://docs.databricks.com/api/workspace/resourcequotas/listquotas#next_page_token)string

Opaque token to retrieve the next page of results. Absent if there are no more pages. page_token should be set to this value for the next request.

[`quotas`](https://docs.databricks.com/api/workspace/resourcequotas/listquotas#quotas)Array of object

An array of returned QuotaInfos.

Array [

[`last_refreshed_at`](https://docs.databricks.com/api/workspace/resourcequotas/listquotas#quotas-last_refreshed_at)int64

Example`1723750401`

The timestamp that indicates when the quota count was last updated.

[`parent_full_name`](https://docs.databricks.com/api/workspace/resourcequotas/listquotas#quotas-parent_full_name)string

Example`"main.default"`

Name of the parent resource. Returns metastore ID if the parent is a metastore.

[`parent_securable_type`](https://docs.databricks.com/api/workspace/resourcequotas/listquotas#quotas-parent_securable_type)string

Enum: `CATALOG | SCHEMA | TABLE | STORAGE_CREDENTIAL | EXTERNAL_LOCATION | FUNCTION | SHARE | PROVIDER | RECIPIENT | CLEAN_ROOM | METASTORE | PIPELINE | VOLUME | CONNECTION | CREDENTIAL | EXTERNAL_METADATA | STAGING_TABLE`

Example`"schema"`

The quota parent securable type.

[`quota_count`](https://docs.databricks.com/api/workspace/resourcequotas/listquotas#quotas-quota_count)int32

Example`1234`

The current usage of the resource quota.

[`quota_limit`](https://docs.databricks.com/api/workspace/resourcequotas/listquotas#quotas-quota_limit)int32

Example`10000`

The current limit of the resource quota.

[`quota_name`](https://docs.databricks.com/api/workspace/resourcequotas/listquotas#quotas-quota_name)string

Example`"table-quota"`

The name of the quota.

 ]

# Response samples

200

{

"next_page_token":"string",

"quotas":[

{

"last_refreshed_at":1723750401,

"parent_full_name":"main.default",

"parent_securable_type":"CATALOG",

"quota_count":1234,

"quota_limit":10000,

"quota_name":"table-quota"

}

]

}
