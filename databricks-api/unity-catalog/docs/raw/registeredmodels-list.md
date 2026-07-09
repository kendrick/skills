Title: List Registered Models | Registered Models API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/registeredmodels/list

Markdown Content:
## List Registered Models

`GET/api/2.1/unity-catalog/models`

List registered models. You can list registered models under a particular schema, or list all registered models in the current metastore.

The returned models are filtered based on the privileges of the calling user. For example, the metastore admin is able to list all the registered models. A regular user needs to be the owner or have the EXECUTE privilege on the registered model to recieve the registered models in the response. For the latter case, the caller must also be the owner or have the USE_CATALOG privilege on the parent catalog and the USE_SCHEMA privilege on the parent schema.

There is no guarantee of a specific ordering of the elements in the response.

PAGINATION BEHAVIOR: The API is by default paginated, a page may contain zero results while still providing a next_page_token. Clients must continue reading pages until next_page_token is absent, which is the only indication that the end of results has been reached.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Query parameters

[`catalog_name`](https://docs.databricks.com/api/workspace/registeredmodels/list#catalog_name)string

The identifier of the catalog under which to list registered models. If specified, schema_name must be specified.

[`schema_name`](https://docs.databricks.com/api/workspace/registeredmodels/list#schema_name)string

The identifier of the schema under which to list registered models. If specified, catalog_name must be specified.

[`include_browse`](https://docs.databricks.com/api/workspace/registeredmodels/list#include_browse)boolean

Whether to include registered models in the response for which the principal can only access selective metadata for

[`max_results`](https://docs.databricks.com/api/workspace/registeredmodels/list#max_results)int32

<= 100 

Max number of registered models to return.

If both catalog and schema are specified:

*   when max_results is not specified, the page length is set to a server configured value (10000, as of 4/2/2024).
*   when set to a value greater than 0, the page length is the minimum of this value and a server configured value (10000, as of 4/2/2024);
*   when set to 0, the page length is set to a server configured value (10000, as of 4/2/2024);
*   when set to a value less than 0, an invalid parameter error is returned;

If neither schema nor catalog is specified:

*   when max_results is not specified, the page length is set to a server configured value (100, as of 4/2/2024).
*   when set to a value greater than 0, the page length is the minimum of this value and a server configured value (1000, as of 4/2/2024);
*   when set to 0, the page length is set to a server configured value (100, as of 4/2/2024);
*   when set to a value less than 0, an invalid parameter error is returned;

[`page_token`](https://docs.databricks.com/api/workspace/registeredmodels/list#page_token)string

Opaque token to send for the next page of results (pagination).

### Responses

**200** Request completed successfully. The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

Request completed successfully.

 The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

[`next_page_token`](https://docs.databricks.com/api/workspace/registeredmodels/list#next_page_token)string

Opaque token for pagination. Omitted if there are no more results. page_token should be set to this value for fetching the next page.

[`registered_models`](https://docs.databricks.com/api/workspace/registeredmodels/list#registered_models)Array of object

Array [

[`aliases`](https://docs.databricks.com/api/workspace/registeredmodels/list#registered_models-aliases)Array of object

List of aliases associated with the registered model

[`browse_only`](https://docs.databricks.com/api/workspace/registeredmodels/list#registered_models-browse_only)boolean

Indicates whether the principal is limited to retrieving metadata for the associated object through the BROWSE privilege when include_browse is enabled in the request.

[`catalog_name`](https://docs.databricks.com/api/workspace/registeredmodels/list#registered_models-catalog_name)string

The name of the catalog where the schema and the registered model reside

[`comment`](https://docs.databricks.com/api/workspace/registeredmodels/list#registered_models-comment)string

[ 1 .. 65536 ] characters 

The comment attached to the registered model

[`created_at`](https://docs.databricks.com/api/workspace/registeredmodels/list#registered_models-created_at)int64

Creation timestamp of the registered model in milliseconds since the Unix epoch

[`created_by`](https://docs.databricks.com/api/workspace/registeredmodels/list#registered_models-created_by)string

The identifier of the user who created the registered model

[`full_name`](https://docs.databricks.com/api/workspace/registeredmodels/list#registered_models-full_name)string

The three-level (fully qualified) name of the registered model

[`metastore_id`](https://docs.databricks.com/api/workspace/registeredmodels/list#registered_models-metastore_id)string

The unique identifier of the metastore

[`name`](https://docs.databricks.com/api/workspace/registeredmodels/list#registered_models-name)string

The name of the registered model

[`owner`](https://docs.databricks.com/api/workspace/registeredmodels/list#registered_models-owner)string

The identifier of the user who owns the registered model

[`schema_name`](https://docs.databricks.com/api/workspace/registeredmodels/list#registered_models-schema_name)string

The name of the schema where the registered model resides

[`storage_location`](https://docs.databricks.com/api/workspace/registeredmodels/list#registered_models-storage_location)string

The storage location on the cloud under which model version data files are stored

[`updated_at`](https://docs.databricks.com/api/workspace/registeredmodels/list#registered_models-updated_at)int64

Last-update timestamp of the registered model in milliseconds since the Unix epoch

[`updated_by`](https://docs.databricks.com/api/workspace/registeredmodels/list#registered_models-updated_by)string

The identifier of the user who updated the registered model last time

 ]

# Response samples

200

{

"next_page_token":"string",

"registered_models":[

{

"aliases":[

{

"alias_name":"string",

"catalog_name":"string",

"id":"string",

"model_name":"string",

"schema_name":"string",

"version_num":0

}

],

"browse_only":true,

"catalog_name":"string",

"comment":"string",

"created_at":0,

"created_by":"string",

"full_name":"string",

"metastore_id":"string",

"name":"string",

"owner":"string",

"schema_name":"string",

"storage_location":"string",

"updated_at":0,

"updated_by":"string"

}

]

}
