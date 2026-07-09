Title: Update a Volume | Volumes API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/volumes/update

Markdown Content:
## Update a Volume

`PATCH/api/2.1/unity-catalog/volumes/{name}`

Updates the specified volume under the specified parent catalog and schema.

The caller must be a metastore admin or an owner of the volume. For the latter case, the caller must also be the owner or have the USE_CATALOG privilege on the parent catalog and the USE_SCHEMA privilege on the parent schema.

Currently only the name, the owner or the comment of the volume could be updated.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`name`](https://docs.databricks.com/api/workspace/volumes/update#name)required string

The three-level (fully qualified) name of the volume

### Request body

[`comment`](https://docs.databricks.com/api/workspace/volumes/update#comment)string

[ 1 .. 65536 ] characters 

The comment attached to the volume

[`new_name`](https://docs.databricks.com/api/workspace/volumes/update#new_name)string

New name for the volume.

[`owner`](https://docs.databricks.com/api/workspace/volumes/update#owner)string

The identifier of the user who owns the volume

### Responses

**200** Request completed successfully.

Request completed successfully.

[`access_point`](https://docs.databricks.com/api/workspace/volumes/update#access_point)string

The AWS access point to use when accesing s3 for this external location.

[`browse_only`](https://docs.databricks.com/api/workspace/volumes/update#browse_only)boolean

Indicates whether the principal is limited to retrieving metadata for the associated object through the BROWSE privilege when include_browse is enabled in the request.

[`catalog_name`](https://docs.databricks.com/api/workspace/volumes/update#catalog_name)string

The name of the catalog where the schema and the volume are

[`comment`](https://docs.databricks.com/api/workspace/volumes/update#comment)string

[ 1 .. 65536 ] characters 

The comment attached to the volume

[`created_at`](https://docs.databricks.com/api/workspace/volumes/update#created_at)int64

[`created_by`](https://docs.databricks.com/api/workspace/volumes/update#created_by)string

The identifier of the user who created the volume

[`full_name`](https://docs.databricks.com/api/workspace/volumes/update#full_name)string

The three-level (fully qualified) name of the volume

[`metastore_id`](https://docs.databricks.com/api/workspace/volumes/update#metastore_id)string

The unique identifier of the metastore

[`name`](https://docs.databricks.com/api/workspace/volumes/update#name)string

The name of the volume

[`owner`](https://docs.databricks.com/api/workspace/volumes/update#owner)string

The identifier of the user who owns the volume

[`schema_name`](https://docs.databricks.com/api/workspace/volumes/update#schema_name)string

The name of the schema where the volume is

[`storage_location`](https://docs.databricks.com/api/workspace/volumes/update#storage_location)string

The storage location on the cloud

[`updated_at`](https://docs.databricks.com/api/workspace/volumes/update#updated_at)int64

[`updated_by`](https://docs.databricks.com/api/workspace/volumes/update#updated_by)string

The identifier of the user who updated the volume last time

[`volume_id`](https://docs.databricks.com/api/workspace/volumes/update#volume_id)string

The unique identifier of the volume

[`volume_type`](https://docs.databricks.com/api/workspace/volumes/update#volume_type)string

Enum: `MANAGED | EXTERNAL`

The type of the volume. An external volume is located in the specified external location. A managed volume is located in the default location which is specified by the parent schema, or the parent catalog, or the Metastore. [Learn more](https://docs.databricks.com/aws/en/volumes/managed-vs-external)

# Request samples

JSON

{

"comment":"string",

"new_name":"string",

"owner":"string"

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
