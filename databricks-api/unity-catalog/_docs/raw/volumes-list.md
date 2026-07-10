Title: List Volumes | Volumes API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/volumes/list

Markdown Content:
## List Volumes

`GET/api/2.1/unity-catalog/volumes`

Gets an array of volumes for the current metastore under the parent catalog and schema.

The returned volumes are filtered based on the privileges of the calling user. For example, the metastore admin is able to list all the volumes. A regular user needs to be the owner or have the READ VOLUME privilege on the volume to receive the volumes in the response. For the latter case, the caller must also be the owner or have the USE_CATALOG privilege on the parent catalog and the USE_SCHEMA privilege on the parent schema.

There is no guarantee of a specific ordering of the elements in the array.

PAGINATION BEHAVIOR: The API is by default paginated, a page may contain zero results while still providing a next_page_token. Clients must continue reading pages until next_page_token is absent, which is the only indication that the end of results has been reached.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Query parameters

[`catalog_name`](https://docs.databricks.com/api/workspace/volumes/list#catalog_name)required string

The identifier of the catalog

[`schema_name`](https://docs.databricks.com/api/workspace/volumes/list#schema_name)required string

The identifier of the schema

[`include_browse`](https://docs.databricks.com/api/workspace/volumes/list#include_browse)boolean

Whether to include volumes in the response for which the principal can only access selective metadata for

[`max_results`](https://docs.databricks.com/api/workspace/volumes/list#max_results)int32

<= 10000 

Maximum number of volumes to return (page length).

If not set, the page length is set to a server configured value (10000, as of 1/29/2024).

*   when set to a value greater than 0, the page length is the minimum of this value and a server configured value (10000, as of 1/29/2024);
*   when set to 0, the page length is set to a server configured value (10000, as of 1/29/2024) (recommended);
*   when set to a value less than 0, an invalid parameter error is returned;

Note: this parameter controls only the maximum number of volumes to return. The actual number of volumes returned in a page may be smaller than this value, including 0, even if there are more pages.

[`page_token`](https://docs.databricks.com/api/workspace/volumes/list#page_token)string

Opaque token returned by a previous request. It must be included in the request to retrieve the next page of results (pagination).

### Responses

**200** Request completed successfully. The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

Request completed successfully.

 The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

[`next_page_token`](https://docs.databricks.com/api/workspace/volumes/list#next_page_token)string

Opaque token to retrieve the next page of results. Absent if there are no more pages. page_token should be set to this value for the next request to retrieve the next page of results.

[`volumes`](https://docs.databricks.com/api/workspace/volumes/list#volumes)Array of object

Array [

[`access_point`](https://docs.databricks.com/api/workspace/volumes/list#volumes-access_point)string

The AWS access point to use when accesing s3 for this external location.

[`browse_only`](https://docs.databricks.com/api/workspace/volumes/list#volumes-browse_only)boolean

Indicates whether the principal is limited to retrieving metadata for the associated object through the BROWSE privilege when include_browse is enabled in the request.

[`catalog_name`](https://docs.databricks.com/api/workspace/volumes/list#volumes-catalog_name)string

The name of the catalog where the schema and the volume are

[`comment`](https://docs.databricks.com/api/workspace/volumes/list#volumes-comment)string

[ 1 .. 65536 ] characters 

The comment attached to the volume

[`created_at`](https://docs.databricks.com/api/workspace/volumes/list#volumes-created_at)int64

[`created_by`](https://docs.databricks.com/api/workspace/volumes/list#volumes-created_by)string

The identifier of the user who created the volume

[`full_name`](https://docs.databricks.com/api/workspace/volumes/list#volumes-full_name)string

The three-level (fully qualified) name of the volume

[`metastore_id`](https://docs.databricks.com/api/workspace/volumes/list#volumes-metastore_id)string

The unique identifier of the metastore

[`name`](https://docs.databricks.com/api/workspace/volumes/list#volumes-name)string

The name of the volume

[`owner`](https://docs.databricks.com/api/workspace/volumes/list#volumes-owner)string

The identifier of the user who owns the volume

[`schema_name`](https://docs.databricks.com/api/workspace/volumes/list#volumes-schema_name)string

The name of the schema where the volume is

[`storage_location`](https://docs.databricks.com/api/workspace/volumes/list#volumes-storage_location)string

The storage location on the cloud

[`updated_at`](https://docs.databricks.com/api/workspace/volumes/list#volumes-updated_at)int64

[`updated_by`](https://docs.databricks.com/api/workspace/volumes/list#volumes-updated_by)string

The identifier of the user who updated the volume last time

[`volume_id`](https://docs.databricks.com/api/workspace/volumes/list#volumes-volume_id)string

The unique identifier of the volume

[`volume_type`](https://docs.databricks.com/api/workspace/volumes/list#volumes-volume_type)string

Enum: `MANAGED | EXTERNAL`

The type of the volume. An external volume is located in the specified external location. A managed volume is located in the default location which is specified by the parent schema, or the parent catalog, or the Metastore. [Learn more](https://docs.databricks.com/aws/en/volumes/managed-vs-external)

 ]

# Response samples

200

{

"next_page_token":"string",

"volumes":[

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

]

}
