Title: Get a schema | Schemas API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/schemas/get

Markdown Content:
## Get a schema

`GET/api/2.1/unity-catalog/schemas/{full_name}`

Gets the specified schema within the metastore. The caller must be a metastore admin, the owner of the schema, or a user that has the USE_SCHEMA privilege on the schema.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`full_name`](https://docs.databricks.com/api/workspace/schemas/get#full_name)required string

Full name of the schema.

### Query parameters

[`include_browse`](https://docs.databricks.com/api/workspace/schemas/get#include_browse)boolean

Whether to include schemas in the response for which the principal can only access selective metadata for

### Responses

**200** Request completed successfully.

Request completed successfully.

[`browse_only`](https://docs.databricks.com/api/workspace/schemas/get#browse_only)boolean

Indicates whether the principal is limited to retrieving metadata for the associated object through the BROWSE privilege when include_browse is enabled in the request.

[`catalog_name`](https://docs.databricks.com/api/workspace/schemas/get#catalog_name)string

Name of parent catalog.

[`catalog_type`](https://docs.databricks.com/api/workspace/schemas/get#catalog_type)string

Enum: `MANAGED_CATALOG | DELTASHARING_CATALOG | SYSTEM_CATALOG | INTERNAL_CATALOG | FOREIGN_CATALOG | MANAGED_ONLINE_CATALOG`

The type of the parent catalog.

[`comment`](https://docs.databricks.com/api/workspace/schemas/get#comment)string

User-provided free-form text description.

[`created_at`](https://docs.databricks.com/api/workspace/schemas/get#created_at)int64

Time at which this schema was created, in epoch milliseconds.

[`created_by`](https://docs.databricks.com/api/workspace/schemas/get#created_by)string

Username of schema creator.

[`effective_predictive_optimization_flag`](https://docs.databricks.com/api/workspace/schemas/get#effective_predictive_optimization_flag)object

[`inherited_from_name`](https://docs.databricks.com/api/workspace/schemas/get#effective_predictive_optimization_flag-inherited_from_name)string

The name of the object from which the flag was inherited. If there was no inheritance, this field is left blank.

[`inherited_from_type`](https://docs.databricks.com/api/workspace/schemas/get#effective_predictive_optimization_flag-inherited_from_type)string

Enum: `CATALOG | SCHEMA`

The type of the object from which the flag was inherited. If there was no inheritance, this field is left blank.

[`value`](https://docs.databricks.com/api/workspace/schemas/get#effective_predictive_optimization_flag-value)string

Enum: `DISABLE | ENABLE | INHERIT`

Whether predictive optimization should be enabled for this object and objects under it.

[`enable_predictive_optimization`](https://docs.databricks.com/api/workspace/schemas/get#enable_predictive_optimization)string

Enum: `DISABLE | ENABLE | INHERIT`

Whether predictive optimization should be enabled for this object and objects under it.

[`full_name`](https://docs.databricks.com/api/workspace/schemas/get#full_name)string

Full name of schema, in form of catalog_name.schema_name.

[`metastore_id`](https://docs.databricks.com/api/workspace/schemas/get#metastore_id)string

Unique identifier of parent metastore.

[`name`](https://docs.databricks.com/api/workspace/schemas/get#name)string

Name of schema, relative to parent catalog.

[`owner`](https://docs.databricks.com/api/workspace/schemas/get#owner)string

Username of current owner of schema.

[`properties`](https://docs.databricks.com/api/workspace/schemas/get#properties)object

A map of key-value properties attached to the securable.

[`schema_id`](https://docs.databricks.com/api/workspace/schemas/get#schema_id)string

The unique identifier of the schema.

[`storage_location`](https://docs.databricks.com/api/workspace/schemas/get#storage_location)string

Storage location for managed tables within schema.

[`storage_root`](https://docs.databricks.com/api/workspace/schemas/get#storage_root)string

Storage root URL for managed tables within schema.

[`updated_at`](https://docs.databricks.com/api/workspace/schemas/get#updated_at)int64

Time at which this schema was created, in epoch milliseconds.

[`updated_by`](https://docs.databricks.com/api/workspace/schemas/get#updated_by)string

Username of user who last modified schema.

# Response samples

200

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
