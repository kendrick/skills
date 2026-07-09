Title: Get a Registered Model | Registered Models API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/registeredmodels/get

Markdown Content:
## Get a Registered Model

`GET/api/2.1/unity-catalog/models/{full_name}`

Get a registered model.

The caller must be a metastore admin or an owner of (or have the EXECUTE privilege on) the registered model. For the latter case, the caller must also be the owner or have the USE_CATALOG privilege on the parent catalog and the USE_SCHEMA privilege on the parent schema.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`full_name`](https://docs.databricks.com/api/workspace/registeredmodels/get#full_name)required string

The three-level (fully qualified) name of the registered model

### Query parameters

[`include_aliases`](https://docs.databricks.com/api/workspace/registeredmodels/get#include_aliases)boolean

Whether to include registered model aliases in the response

[`include_browse`](https://docs.databricks.com/api/workspace/registeredmodels/get#include_browse)boolean

Whether to include registered models in the response for which the principal can only access selective metadata for

### Responses

**200** Request completed successfully.

Request completed successfully.

[`aliases`](https://docs.databricks.com/api/workspace/registeredmodels/get#aliases)Array of object

List of aliases associated with the registered model

Array [

[`alias_name`](https://docs.databricks.com/api/workspace/registeredmodels/get#aliases-alias_name)string

Name of the alias, e.g. 'champion' or 'latest_stable'

[`catalog_name`](https://docs.databricks.com/api/workspace/registeredmodels/get#aliases-catalog_name)string

The name of the catalog containing the model version

[`id`](https://docs.databricks.com/api/workspace/registeredmodels/get#aliases-id)string

The unique identifier of the alias

[`model_name`](https://docs.databricks.com/api/workspace/registeredmodels/get#aliases-model_name)string

The name of the parent registered model of the model version, relative to parent schema

[`schema_name`](https://docs.databricks.com/api/workspace/registeredmodels/get#aliases-schema_name)string

The name of the schema containing the model version, relative to parent catalog

[`version_num`](https://docs.databricks.com/api/workspace/registeredmodels/get#aliases-version_num)int32

Integer version number of the model version to which this alias points.

 ]

[`browse_only`](https://docs.databricks.com/api/workspace/registeredmodels/get#browse_only)boolean

Indicates whether the principal is limited to retrieving metadata for the associated object through the BROWSE privilege when include_browse is enabled in the request.

[`catalog_name`](https://docs.databricks.com/api/workspace/registeredmodels/get#catalog_name)string

The name of the catalog where the schema and the registered model reside

[`comment`](https://docs.databricks.com/api/workspace/registeredmodels/get#comment)string

[ 1 .. 65536 ] characters 

The comment attached to the registered model

[`created_at`](https://docs.databricks.com/api/workspace/registeredmodels/get#created_at)int64

Creation timestamp of the registered model in milliseconds since the Unix epoch

[`created_by`](https://docs.databricks.com/api/workspace/registeredmodels/get#created_by)string

The identifier of the user who created the registered model

[`full_name`](https://docs.databricks.com/api/workspace/registeredmodels/get#full_name)string

The three-level (fully qualified) name of the registered model

[`metastore_id`](https://docs.databricks.com/api/workspace/registeredmodels/get#metastore_id)string

The unique identifier of the metastore

[`name`](https://docs.databricks.com/api/workspace/registeredmodels/get#name)string

The name of the registered model

[`owner`](https://docs.databricks.com/api/workspace/registeredmodels/get#owner)string

The identifier of the user who owns the registered model

[`schema_name`](https://docs.databricks.com/api/workspace/registeredmodels/get#schema_name)string

The name of the schema where the registered model resides

[`storage_location`](https://docs.databricks.com/api/workspace/registeredmodels/get#storage_location)string

The storage location on the cloud under which model version data files are stored

[`updated_at`](https://docs.databricks.com/api/workspace/registeredmodels/get#updated_at)int64

Last-update timestamp of the registered model in milliseconds since the Unix epoch

[`updated_by`](https://docs.databricks.com/api/workspace/registeredmodels/get#updated_by)string

The identifier of the user who updated the registered model last time

# Response samples

200

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
