Title: List schemas | Schemas API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/schemas/list

Markdown Content:
## List schemas

`GET/api/2.1/unity-catalog/schemas`

Gets an array of schemas for a catalog in the metastore. If the caller is the metastore admin or the owner of the parent catalog, all schemas for the catalog will be retrieved. Otherwise, only schemas owned by the caller (or for which the caller has the USE_SCHEMA privilege) will be retrieved. There is no guarantee of a specific ordering of the elements in the array.

NOTE: we recommend using max_results=0 to use the paginated version of this API. Unpaginated calls will be deprecated soon.

PAGINATION BEHAVIOR: When using pagination (max_results >= 0), a page may contain zero results while still providing a next_page_token. Clients must continue reading pages until next_page_token is absent, which is the only indication that the end of results has been reached.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Query parameters

[`catalog_name`](https://docs.databricks.com/api/workspace/schemas/list#catalog_name)required string

Parent catalog for schemas of interest.

[`max_results`](https://docs.databricks.com/api/workspace/schemas/list#max_results)int32

<= 1000 

Maximum number of schemas to return. If not set, all the schemas are returned (not recommended).

*   when set to a value greater than 0, the page length is the minimum of this value and a server configured value;
*   when set to 0, the page length is set to a server configured value (recommended);
*   when set to a value less than 0, an invalid parameter error is returned;

[`page_token`](https://docs.databricks.com/api/workspace/schemas/list#page_token)string

Opaque pagination token to go to next page based on previous query.

[`include_browse`](https://docs.databricks.com/api/workspace/schemas/list#include_browse)boolean

Whether to include schemas in the response for which the principal can only access selective metadata for

### Responses

**200** Request completed successfully. The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

Request completed successfully.

 The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

[`next_page_token`](https://docs.databricks.com/api/workspace/schemas/list#next_page_token)string

Opaque token to retrieve the next page of results. Absent if there are no more pages. page_token should be set to this value for the next request (for the next page of results).

[`schemas`](https://docs.databricks.com/api/workspace/schemas/list#schemas)Array of object

An array of schema information objects.

Array [

[`browse_only`](https://docs.databricks.com/api/workspace/schemas/list#schemas-browse_only)boolean

Indicates whether the principal is limited to retrieving metadata for the associated object through the BROWSE privilege when include_browse is enabled in the request.

[`catalog_name`](https://docs.databricks.com/api/workspace/schemas/list#schemas-catalog_name)string

Name of parent catalog.

[`catalog_type`](https://docs.databricks.com/api/workspace/schemas/list#schemas-catalog_type)string

Enum: `MANAGED_CATALOG | DELTASHARING_CATALOG | SYSTEM_CATALOG | INTERNAL_CATALOG | FOREIGN_CATALOG | MANAGED_ONLINE_CATALOG`

The type of the parent catalog.

[`comment`](https://docs.databricks.com/api/workspace/schemas/list#schemas-comment)string

User-provided free-form text description.

[`created_at`](https://docs.databricks.com/api/workspace/schemas/list#schemas-created_at)int64

Time at which this schema was created, in epoch milliseconds.

[`created_by`](https://docs.databricks.com/api/workspace/schemas/list#schemas-created_by)string

Username of schema creator.

[`effective_predictive_optimization_flag`](https://docs.databricks.com/api/workspace/schemas/list#schemas-effective_predictive_optimization_flag)object

[`enable_predictive_optimization`](https://docs.databricks.com/api/workspace/schemas/list#schemas-enable_predictive_optimization)string

Enum: `DISABLE | ENABLE | INHERIT`

Whether predictive optimization should be enabled for this object and objects under it.

[`full_name`](https://docs.databricks.com/api/workspace/schemas/list#schemas-full_name)string

Full name of schema, in form of catalog_name.schema_name.

[`metastore_id`](https://docs.databricks.com/api/workspace/schemas/list#schemas-metastore_id)string

Unique identifier of parent metastore.

[`name`](https://docs.databricks.com/api/workspace/schemas/list#schemas-name)string

Name of schema, relative to parent catalog.

[`owner`](https://docs.databricks.com/api/workspace/schemas/list#schemas-owner)string

Username of current owner of schema.

[`properties`](https://docs.databricks.com/api/workspace/schemas/list#schemas-properties)object

A map of key-value properties attached to the securable.

[`schema_id`](https://docs.databricks.com/api/workspace/schemas/list#schemas-schema_id)string

The unique identifier of the schema.

[`storage_location`](https://docs.databricks.com/api/workspace/schemas/list#schemas-storage_location)string

Storage location for managed tables within schema.

[`storage_root`](https://docs.databricks.com/api/workspace/schemas/list#schemas-storage_root)string

Storage root URL for managed tables within schema.

[`updated_at`](https://docs.databricks.com/api/workspace/schemas/list#schemas-updated_at)int64

Time at which this schema was created, in epoch milliseconds.

[`updated_by`](https://docs.databricks.com/api/workspace/schemas/list#schemas-updated_by)string

Username of user who last modified schema.

 ]

# Response samples

200

{

"next_page_token":"string",

"schemas":[

{

"browse_only":true,

"catalog_name":"string",

"catalog_type":"MANAGED_CATALOG",

"comment":"string",

"created_at":0,

"created_by":"string",

"effective_predictive_optimization_flag":{

"inherited_from_name":"string",

"inherited_from_type":"CATALOG",

"value":"DISABLE"

},

"enable_predictive_optimization":"DISABLE",

"full_name":"string",

"metastore_id":"string",

"name":"string",

"owner":"string",

"properties":{

"property1":"string",

"property2":"string"

},

"schema_id":"string",

"storage_location":"string",

"storage_root":"string",

"updated_at":0,

"updated_by":"string"

}

]

}
