Title: Update a schema | Schemas API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/schemas/update

Markdown Content:
## Update a schema

`PATCH/api/2.1/unity-catalog/schemas/{full_name}`

Updates a schema for a catalog. The caller must be the owner of the schema or a metastore admin. If the caller is a metastore admin, only the owner field can be changed in the update. If the name field must be updated, the caller must be a metastore admin or have the CREATE_SCHEMA privilege on the parent catalog.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`full_name`](https://docs.databricks.com/api/workspace/schemas/update#full_name)required string

Full name of the schema.

### Request body

[`comment`](https://docs.databricks.com/api/workspace/schemas/update#comment)string

User-provided free-form text description.

[`enable_predictive_optimization`](https://docs.databricks.com/api/workspace/schemas/update#enable_predictive_optimization)string

Enum: `DISABLE | ENABLE | INHERIT`

Whether predictive optimization should be enabled for this object and objects under it.

[`new_name`](https://docs.databricks.com/api/workspace/schemas/update#new_name)string

New name for the schema.

[`owner`](https://docs.databricks.com/api/workspace/schemas/update#owner)string

Username of current owner of schema.

[`properties`](https://docs.databricks.com/api/workspace/schemas/update#properties)object

A map of key-value properties attached to the securable.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`browse_only`](https://docs.databricks.com/api/workspace/schemas/update#browse_only)boolean

Indicates whether the principal is limited to retrieving metadata for the associated object through the BROWSE privilege when include_browse is enabled in the request.

[`catalog_name`](https://docs.databricks.com/api/workspace/schemas/update#catalog_name)string

Name of parent catalog.

[`catalog_type`](https://docs.databricks.com/api/workspace/schemas/update#catalog_type)string

Enum: `MANAGED_CATALOG | DELTASHARING_CATALOG | SYSTEM_CATALOG | INTERNAL_CATALOG | FOREIGN_CATALOG | MANAGED_ONLINE_CATALOG`

The type of the parent catalog.

[`comment`](https://docs.databricks.com/api/workspace/schemas/update#comment)string

User-provided free-form text description.

[`created_at`](https://docs.databricks.com/api/workspace/schemas/update#created_at)int64

Time at which this schema was created, in epoch milliseconds.

[`created_by`](https://docs.databricks.com/api/workspace/schemas/update#created_by)string

Username of schema creator.

[`effective_predictive_optimization_flag`](https://docs.databricks.com/api/workspace/schemas/update#effective_predictive_optimization_flag)object

[`inherited_from_name`](https://docs.databricks.com/api/workspace/schemas/update#effective_predictive_optimization_flag-inherited_from_name)string

The name of the object from which the flag was inherited. If there was no inheritance, this field is left blank.

[`inherited_from_type`](https://docs.databricks.com/api/workspace/schemas/update#effective_predictive_optimization_flag-inherited_from_type)string

Enum: `CATALOG | SCHEMA`

The type of the object from which the flag was inherited. If there was no inheritance, this field is left blank.

[`value`](https://docs.databricks.com/api/workspace/schemas/update#effective_predictive_optimization_flag-value)string

Enum: `DISABLE | ENABLE | INHERIT`

Whether predictive optimization should be enabled for this object and objects under it.

[`enable_predictive_optimization`](https://docs.databricks.com/api/workspace/schemas/update#enable_predictive_optimization)string

Enum: `DISABLE | ENABLE | INHERIT`

Whether predictive optimization should be enabled for this object and objects under it.

[`full_name`](https://docs.databricks.com/api/workspace/schemas/update#full_name)string

Full name of schema, in form of catalog_name.schema_name.

[`metastore_id`](https://docs.databricks.com/api/workspace/schemas/update#metastore_id)string

Unique identifier of parent metastore.

[`name`](https://docs.databricks.com/api/workspace/schemas/update#name)string

Name of schema, relative to parent catalog.

[`owner`](https://docs.databricks.com/api/workspace/schemas/update#owner)string

Username of current owner of schema.

[`properties`](https://docs.databricks.com/api/workspace/schemas/update#properties)object

A map of key-value properties attached to the securable.

[`schema_id`](https://docs.databricks.com/api/workspace/schemas/update#schema_id)string

The unique identifier of the schema.

[`storage_location`](https://docs.databricks.com/api/workspace/schemas/update#storage_location)string

Storage location for managed tables within schema.

[`storage_root`](https://docs.databricks.com/api/workspace/schemas/update#storage_root)string

Storage root URL for managed tables within schema.

[`updated_at`](https://docs.databricks.com/api/workspace/schemas/update#updated_at)int64

Time at which this schema was created, in epoch milliseconds.

[`updated_by`](https://docs.databricks.com/api/workspace/schemas/update#updated_by)string

Username of user who last modified schema.

# Request samples

JSON

{

"comment":"string",

"enable_predictive_optimization":"DISABLE",

"new_name":"string",

"owner":"string",

"properties":{

"property1":"string",

"property2":"string"

}

}

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
