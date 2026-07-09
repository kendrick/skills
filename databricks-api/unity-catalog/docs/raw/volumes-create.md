Title: Create a Volume | Volumes API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/volumes/create

Markdown Content:
## Create a Volume

`POST/api/2.1/unity-catalog/volumes`

Creates a new volume.

The user could create either an external volume or a managed volume. An external volume will be created in the specified external location, while a managed volume will be located in the default location which is specified by the parent schema, or the parent catalog, or the Metastore.

For the volume creation to succeed, the user must satisfy following conditions:

*   The caller must be a metastore admin, or be the owner of the parent catalog and schema, or have the USE_CATALOG privilege on the parent catalog and the USE_SCHEMA privilege on the parent schema.
*   The caller must have CREATE VOLUME privilege on the parent schema.

For an external volume, following conditions also need to satisfy

*   The caller must have CREATE EXTERNAL VOLUME privilege on the external location.
*   There are no other tables, nor volumes existing in the specified storage location.
*   The specified storage location is not under the location of other tables, nor volumes, or catalogs or schemas.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Request body

[`catalog_name`](https://docs.databricks.com/api/workspace/volumes/create#catalog_name)required string

The name of the catalog where the schema and the volume are

[`comment`](https://docs.databricks.com/api/workspace/volumes/create#comment)string

[ 1 .. 65536 ] characters 

The comment attached to the volume

[`name`](https://docs.databricks.com/api/workspace/volumes/create#name)required string

The name of the volume

[`schema_name`](https://docs.databricks.com/api/workspace/volumes/create#schema_name)required string

The name of the schema where the volume is

[`storage_location`](https://docs.databricks.com/api/workspace/volumes/create#storage_location)string

The storage location on the cloud

[`volume_type`](https://docs.databricks.com/api/workspace/volumes/create#volume_type)required string

Enum: `MANAGED | EXTERNAL`

The type of the volume. An external volume is located in the specified external location. A managed volume is located in the default location which is specified by the parent schema, or the parent catalog, or the Metastore. [Learn more](https://docs.databricks.com/aws/en/volumes/managed-vs-external)

### Responses

**200** Request completed successfully.

Request completed successfully.

[`access_point`](https://docs.databricks.com/api/workspace/volumes/create#access_point)string

The AWS access point to use when accesing s3 for this external location.

[`browse_only`](https://docs.databricks.com/api/workspace/volumes/create#browse_only)boolean

Indicates whether the principal is limited to retrieving metadata for the associated object through the BROWSE privilege when include_browse is enabled in the request.

[`catalog_name`](https://docs.databricks.com/api/workspace/volumes/create#catalog_name)string

The name of the catalog where the schema and the volume are

[`comment`](https://docs.databricks.com/api/workspace/volumes/create#comment)string

[ 1 .. 65536 ] characters 

The comment attached to the volume

[`created_at`](https://docs.databricks.com/api/workspace/volumes/create#created_at)int64

[`created_by`](https://docs.databricks.com/api/workspace/volumes/create#created_by)string

The identifier of the user who created the volume

[`full_name`](https://docs.databricks.com/api/workspace/volumes/create#full_name)string

The three-level (fully qualified) name of the volume

[`metastore_id`](https://docs.databricks.com/api/workspace/volumes/create#metastore_id)string

The unique identifier of the metastore

[`name`](https://docs.databricks.com/api/workspace/volumes/create#name)string

The name of the volume

[`owner`](https://docs.databricks.com/api/workspace/volumes/create#owner)string

The identifier of the user who owns the volume

[`schema_name`](https://docs.databricks.com/api/workspace/volumes/create#schema_name)string

The name of the schema where the volume is

[`storage_location`](https://docs.databricks.com/api/workspace/volumes/create#storage_location)string

The storage location on the cloud

[`updated_at`](https://docs.databricks.com/api/workspace/volumes/create#updated_at)int64

[`updated_by`](https://docs.databricks.com/api/workspace/volumes/create#updated_by)string

The identifier of the user who updated the volume last time

[`volume_id`](https://docs.databricks.com/api/workspace/volumes/create#volume_id)string

The unique identifier of the volume

[`volume_type`](https://docs.databricks.com/api/workspace/volumes/create#volume_type)string

Enum: `MANAGED | EXTERNAL`

The type of the volume. An external volume is located in the specified external location. A managed volume is located in the default location which is specified by the parent schema, or the parent catalog, or the Metastore. [Learn more](https://docs.databricks.com/aws/en/volumes/managed-vs-external)

# Request samples

JSON

{

"catalog_name":"string",

"comment":"string",

"name":"string",

"schema_name":"string",

"storage_location":"string",

"volume_type":"MANAGED"

}

# Response samples

200

{

"access_point":"string",

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

"updated_by":"string",

"volume_id":"string",

"volume_type":"MANAGED"

}
