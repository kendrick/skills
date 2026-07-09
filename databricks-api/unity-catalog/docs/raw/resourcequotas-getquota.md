Title: Get information for a single resource quota. | Resource Quotas API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/resourcequotas/getquota

Markdown Content:
## Get information for a single resource quota.

`GET/api/2.1/unity-catalog/resource-quotas/{parent_securable_type}/{parent_full_name}/{quota_name}`

The GetQuota API returns usage information for a single resource quota, defined as a child-parent pair. This API also refreshes the quota count if it is out of date. Refreshes are triggered asynchronously. The updated count might not be returned in the first call.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`parent_securable_type`](https://docs.databricks.com/api/workspace/resourcequotas/getquota#parent_securable_type)required string

Securable type of the quota parent.

[`parent_full_name`](https://docs.databricks.com/api/workspace/resourcequotas/getquota#parent_full_name)required string

Full name of the parent resource. Provide the metastore ID if the parent is a metastore.

[`quota_name`](https://docs.databricks.com/api/workspace/resourcequotas/getquota#quota_name)required string

Name of the quota. Follows the pattern of the quota type, with "-quota" added as a suffix.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`quota_info`](https://docs.databricks.com/api/workspace/resourcequotas/getquota#quota_info)object

The returned QuotaInfo.

[`last_refreshed_at`](https://docs.databricks.com/api/workspace/resourcequotas/getquota#quota_info-last_refreshed_at)int64

Example`1723750401`

The timestamp that indicates when the quota count was last updated.

[`parent_full_name`](https://docs.databricks.com/api/workspace/resourcequotas/getquota#quota_info-parent_full_name)string

Example`"main.default"`

Name of the parent resource. Returns metastore ID if the parent is a metastore.

[`parent_securable_type`](https://docs.databricks.com/api/workspace/resourcequotas/getquota#quota_info-parent_securable_type)string

Enum: `CATALOG | SCHEMA | TABLE | STORAGE_CREDENTIAL | EXTERNAL_LOCATION | FUNCTION | SHARE | PROVIDER | RECIPIENT | CLEAN_ROOM | METASTORE | PIPELINE | VOLUME | CONNECTION | CREDENTIAL | EXTERNAL_METADATA | STAGING_TABLE`

Example`"schema"`

The quota parent securable type.

[`quota_count`](https://docs.databricks.com/api/workspace/resourcequotas/getquota#quota_info-quota_count)int32

Example`1234`

The current usage of the resource quota.

[`quota_limit`](https://docs.databricks.com/api/workspace/resourcequotas/getquota#quota_info-quota_limit)int32

Example`10000`

The current limit of the resource quota.

[`quota_name`](https://docs.databricks.com/api/workspace/resourcequotas/getquota#quota_info-quota_name)string

Example`"table-quota"`

The name of the quota.

# Response samples

200

{

"quota_info":{

"last_refreshed_at":1723750401,

"parent_full_name":"main.default",

"parent_securable_type":"CATALOG",

"quota_count":1234,

"quota_limit":10000,

"quota_name":"table-quota"

}

}
