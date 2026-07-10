Title: List catalogs | Catalogs API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/catalogs/list

Markdown Content:
## List catalogs

`GET/api/2.1/unity-catalog/catalogs`

Gets an array of catalogs in the metastore. If the caller is the metastore admin, all catalogs will be retrieved. Otherwise, only catalogs owned by the caller (or for which the caller has the USE_CATALOG privilege) will be retrieved. There is no guarantee of a specific ordering of the elements in the array.

NOTE: we recommend using max_results=0 to use the paginated version of this API. Unpaginated calls will be deprecated soon.

PAGINATION BEHAVIOR: When using pagination (max_results >= 0), a page may contain zero results while still providing a next_page_token. Clients must continue reading pages until next_page_token is absent, which is the only indication that the end of results has been reached.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Query parameters

[`include_browse`](https://docs.databricks.com/api/workspace/catalogs/list#include_browse)boolean

Whether to include catalogs in the response for which the principal can only access selective metadata for

[`max_results`](https://docs.databricks.com/api/workspace/catalogs/list#max_results)int32

<= 1000 

Maximum number of catalogs to return.

*   when set to 0, the page length is set to a server configured value (recommended);
*   when set to a value greater than 0, the page length is the minimum of this value and a server configured value;
*   when set to a value less than 0, an invalid parameter error is returned;
*   If not set, all valid catalogs are returned (not recommended).
*   Note: The number of returned catalogs might be less than the specified max_results size, even zero. The only definitive indication that no further catalogs can be fetched is when the next_page_token is unset from the response.

[`page_token`](https://docs.databricks.com/api/workspace/catalogs/list#page_token)string

Opaque pagination token to go to next page based on previous query.

[`include_unbound`](https://docs.databricks.com/api/workspace/catalogs/list#include_unbound)boolean

Whether to include catalogs not bound to the workspace. Effective only if the user has permission to update the catalog–workspace binding.

### Responses

**200** Request completed successfully. The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

Request completed successfully.

 The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

[`catalogs`](https://docs.databricks.com/api/workspace/catalogs/list#catalogs)Array of object

An array of catalog information objects.

Array [

[`browse_only`](https://docs.databricks.com/api/workspace/catalogs/list#catalogs-browse_only)boolean

Indicates whether the principal is limited to retrieving metadata for the associated object through the BROWSE privilege when include_browse is enabled in the request.

[`catalog_type`](https://docs.databricks.com/api/workspace/catalogs/list#catalogs-catalog_type)string

Enum: `MANAGED_CATALOG | DELTASHARING_CATALOG | SYSTEM_CATALOG | INTERNAL_CATALOG | FOREIGN_CATALOG | MANAGED_ONLINE_CATALOG`

The type of the catalog.

[`comment`](https://docs.databricks.com/api/workspace/catalogs/list#catalogs-comment)string

User-provided free-form text description.

[`connection_name`](https://docs.databricks.com/api/workspace/catalogs/list#catalogs-connection_name)string

The name of the connection to an external data source.

[`created_at`](https://docs.databricks.com/api/workspace/catalogs/list#catalogs-created_at)int64

Time at which this catalog was created, in epoch milliseconds.

[`created_by`](https://docs.databricks.com/api/workspace/catalogs/list#catalogs-created_by)string

Username of catalog creator.

[`effective_predictive_optimization_flag`](https://docs.databricks.com/api/workspace/catalogs/list#catalogs-effective_predictive_optimization_flag)object

[`enable_predictive_optimization`](https://docs.databricks.com/api/workspace/catalogs/list#catalogs-enable_predictive_optimization)string

Enum: `DISABLE | ENABLE | INHERIT`

Whether predictive optimization should be enabled for this object and objects under it.

[`full_name`](https://docs.databricks.com/api/workspace/catalogs/list#catalogs-full_name)string

The full name of the catalog. Corresponds with the name field.

[`isolation_mode`](https://docs.databricks.com/api/workspace/catalogs/list#catalogs-isolation_mode)string

Enum: `OPEN | ISOLATED`

Whether the current securable is accessible from all workspaces or a specific set of workspaces.

[`metastore_id`](https://docs.databricks.com/api/workspace/catalogs/list#catalogs-metastore_id)string

Unique identifier of parent metastore.

[`name`](https://docs.databricks.com/api/workspace/catalogs/list#catalogs-name)string

Name of catalog.

[`options`](https://docs.databricks.com/api/workspace/catalogs/list#catalogs-options)object

A map of key-value properties attached to the securable.

[`owner`](https://docs.databricks.com/api/workspace/catalogs/list#catalogs-owner)string

Username of current owner of catalog.

[`properties`](https://docs.databricks.com/api/workspace/catalogs/list#catalogs-properties)object

A map of key-value properties attached to the securable.

[`provider_name`](https://docs.databricks.com/api/workspace/catalogs/list#catalogs-provider_name)string

The name of delta sharing provider.

A Delta Sharing catalog is a catalog that is based on a Delta share on a remote sharing server.

[`provisioning_info`](https://docs.databricks.com/api/workspace/catalogs/list#catalogs-provisioning_info)object

Status of an asynchronously provisioned resource.

[`securable_type`](https://docs.databricks.com/api/workspace/catalogs/list#catalogs-securable_type)string

Enum: `CATALOG | SCHEMA | TABLE | STORAGE_CREDENTIAL | EXTERNAL_LOCATION | FUNCTION | SHARE | PROVIDER | RECIPIENT | CLEAN_ROOM | METASTORE | PIPELINE | VOLUME | CONNECTION | CREDENTIAL | EXTERNAL_METADATA | STAGING_TABLE`

Default`"CATALOG"`

The type of Unity Catalog securable.

[`share_name`](https://docs.databricks.com/api/workspace/catalogs/list#catalogs-share_name)string

The name of the share under the share provider.

[`storage_location`](https://docs.databricks.com/api/workspace/catalogs/list#catalogs-storage_location)string

Storage Location URL (full path) for managed tables within catalog.

[`storage_root`](https://docs.databricks.com/api/workspace/catalogs/list#catalogs-storage_root)string

Storage root URL for managed tables within catalog.

[`updated_at`](https://docs.databricks.com/api/workspace/catalogs/list#catalogs-updated_at)int64

Time at which this catalog was last modified, in epoch milliseconds.

[`updated_by`](https://docs.databricks.com/api/workspace/catalogs/list#catalogs-updated_by)string

Username of user who last modified catalog.

 ]

[`next_page_token`](https://docs.databricks.com/api/workspace/catalogs/list#next_page_token)string

Opaque token to retrieve the next page of results. Absent if there are no more pages. page_token should be set to this value for the next request (for the next page of results).

# Response samples

200

{

"catalogs":[

{

"browse_only":true,

"catalog_type":"MANAGED_CATALOG",

"comment":"string",

"connection_name":"string",

"created_at":0,

"created_by":"string",

"effective_predictive_optimization_flag":{

"inherited_from_name":"string",

"inherited_from_type":"CATALOG",

"value":"DISABLE"

},

"enable_predictive_optimization":"DISABLE",

"full_name":"string",

"isolation_mode":"OPEN",

"metastore_id":"string",

"name":"string",

"options":{

"property1":"string",

"property2":"string"

},

"owner":"string",

"properties":{

"property1":"string",

"property2":"string"

},

"provider_name":"string",

"provisioning_info":{

"state":"PROVISIONING"

},

"securable_type":"CATALOG",

"share_name":"string",

"storage_location":"string",

"storage_root":"string",

"updated_at":0,

"updated_by":"string"

}

],

"next_page_token":"string"

}
