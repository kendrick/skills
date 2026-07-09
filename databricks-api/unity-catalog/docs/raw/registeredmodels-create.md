Title: Create a Registered Model | Registered Models API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/registeredmodels/create

Markdown Content:
## Create a Registered Model

`POST/api/2.1/unity-catalog/models`

Creates a new registered model in Unity Catalog.

File storage for model versions in the registered model will be located in the default location which is specified by the parent schema, or the parent catalog, or the Metastore.

For registered model creation to succeed, the user must satisfy the following conditions:

*   The caller must be a metastore admin, or be the owner of the parent catalog and schema, or have the USE_CATALOG privilege on the parent catalog and the USE_SCHEMA privilege on the parent schema.
*   The caller must have the CREATE MODEL or CREATE FUNCTION privilege on the parent schema.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Request body

[`aliases`](https://docs.databricks.com/api/workspace/registeredmodels/create#aliases)Array of object

List of aliases associated with the registered model

Array [

[`alias_name`](https://docs.databricks.com/api/workspace/registeredmodels/create#aliases-alias_name)string

Name of the alias, e.g. 'champion' or 'latest_stable'

[`catalog_name`](https://docs.databricks.com/api/workspace/registeredmodels/create#aliases-catalog_name)string

The name of the catalog containing the model version

[`id`](https://docs.databricks.com/api/workspace/registeredmodels/create#aliases-id)string

The unique identifier of the alias

[`model_name`](https://docs.databricks.com/api/workspace/registeredmodels/create#aliases-model_name)string

The name of the parent registered model of the model version, relative to parent schema

[`schema_name`](https://docs.databricks.com/api/workspace/registeredmodels/create#aliases-schema_name)string

The name of the schema containing the model version, relative to parent catalog

[`version_num`](https://docs.databricks.com/api/workspace/registeredmodels/create#aliases-version_num)int32

Integer version number of the model version to which this alias points.

 ]

[`browse_only`](https://docs.databricks.com/api/workspace/registeredmodels/create#browse_only)boolean

Indicates whether the principal is limited to retrieving metadata for the associated object through the BROWSE privilege when include_browse is enabled in the request.

[`catalog_name`](https://docs.databricks.com/api/workspace/registeredmodels/create#catalog_name)string

The name of the catalog where the schema and the registered model reside

[`comment`](https://docs.databricks.com/api/workspace/registeredmodels/create#comment)string

[ 1 .. 65536 ] characters 

The comment attached to the registered model

[`created_at`](https://docs.databricks.com/api/workspace/registeredmodels/create#created_at)int64

Creation timestamp of the registered model in milliseconds since the Unix epoch

[`created_by`](https://docs.databricks.com/api/workspace/registeredmodels/create#created_by)string

The identifier of the user who created the registered model

[`full_name`](https://docs.databricks.com/api/workspace/registeredmodels/create#full_name)string

The three-level (fully qualified) name of the registered model

[`metastore_id`](https://docs.databricks.com/api/workspace/registeredmodels/create#metastore_id)string

The unique identifier of the metastore

[`name`](https://docs.databricks.com/api/workspace/registeredmodels/create#name)string

The name of the registered model

[`owner`](https://docs.databricks.com/api/workspace/registeredmodels/create#owner)string

The identifier of the user who owns the registered model

[`schema_name`](https://docs.databricks.com/api/workspace/registeredmodels/create#schema_name)string

The name of the schema where the registered model resides

[`storage_location`](https://docs.databricks.com/api/workspace/registeredmodels/create#storage_location)string

The storage location on the cloud under which model version data files are stored

[`updated_at`](https://docs.databricks.com/api/workspace/registeredmodels/create#updated_at)int64

Last-update timestamp of the registered model in milliseconds since the Unix epoch

[`updated_by`](https://docs.databricks.com/api/workspace/registeredmodels/create#updated_by)string

The identifier of the user who updated the registered model last time

### Responses

**200** Request completed successfully.

Request completed successfully.

[`aliases`](https://docs.databricks.com/api/workspace/registeredmodels/create#aliases)Array of object

List of aliases associated with the registered model

Array [

[`alias_name`](https://docs.databricks.com/api/workspace/registeredmodels/create#aliases-alias_name)string

Name of the alias, e.g. 'champion' or 'latest_stable'

[`catalog_name`](https://docs.databricks.com/api/workspace/registeredmodels/create#aliases-catalog_name)string

The name of the catalog containing the model version

[`id`](https://docs.databricks.com/api/workspace/registeredmodels/create#aliases-id)string

The unique identifier of the alias

[`model_name`](https://docs.databricks.com/api/workspace/registeredmodels/create#aliases-model_name)string

The name of the parent registered model of the model version, relative to parent schema

[`schema_name`](https://docs.databricks.com/api/workspace/registeredmodels/create#aliases-schema_name)string

The name of the schema containing the model version, relative to parent catalog

[`version_num`](https://docs.databricks.com/api/workspace/registeredmodels/create#aliases-version_num)int32

Integer version number of the model version to which this alias points.

 ]

[`browse_only`](https://docs.databricks.com/api/workspace/registeredmodels/create#browse_only)boolean

Indicates whether the principal is limited to retrieving metadata for the associated object through the BROWSE privilege when include_browse is enabled in the request.

[`catalog_name`](https://docs.databricks.com/api/workspace/registeredmodels/create#catalog_name)string

The name of the catalog where the schema and the registered model reside

[`comment`](https://docs.databricks.com/api/workspace/registeredmodels/create#comment)string

[ 1 .. 65536 ] characters 

The comment attached to the registered model

[`created_at`](https://docs.databricks.com/api/workspace/registeredmodels/create#created_at)int64

Creation timestamp of the registered model in milliseconds since the Unix epoch

[`created_by`](https://docs.databricks.com/api/workspace/registeredmodels/create#created_by)string

The identifier of the user who created the registered model

[`full_name`](https://docs.databricks.com/api/workspace/registeredmodels/create#full_name)string

The three-level (fully qualified) name of the registered model

[`metastore_id`](https://docs.databricks.com/api/workspace/registeredmodels/create#metastore_id)string

The unique identifier of the metastore

[`name`](https://docs.databricks.com/api/workspace/registeredmodels/create#name)string

The name of the registered model

[`owner`](https://docs.databricks.com/api/workspace/registeredmodels/create#owner)string

The identifier of the user who owns the registered model

[`schema_name`](https://docs.databricks.com/api/workspace/registeredmodels/create#schema_name)string

The name of the schema where the registered model resides

[`storage_location`](https://docs.databricks.com/api/workspace/registeredmodels/create#storage_location)string

The storage location on the cloud under which model version data files are stored

[`updated_at`](https://docs.databricks.com/api/workspace/registeredmodels/create#updated_at)int64

Last-update timestamp of the registered model in milliseconds since the Unix epoch

[`updated_by`](https://docs.databricks.com/api/workspace/registeredmodels/create#updated_by)string

The identifier of the user who updated the registered model last time

# Request samples

JSON

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
