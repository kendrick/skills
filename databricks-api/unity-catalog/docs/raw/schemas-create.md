Title: Create a schema | Schemas API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/schemas/create

Markdown Content:
## Create a schema

`POST/api/2.1/unity-catalog/schemas`

Creates a new schema for catalog in the Metastore. The caller must be a metastore admin, or have the CREATE_SCHEMA privilege in the parent catalog.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Request body

[`catalog_name`](https://docs.databricks.com/api/workspace/schemas/create#catalog_name)required string

Name of parent catalog.

[`comment`](https://docs.databricks.com/api/workspace/schemas/create#comment)string

User-provided free-form text description.

[`name`](https://docs.databricks.com/api/workspace/schemas/create#name)required string

Name of schema, relative to parent catalog.

[`properties`](https://docs.databricks.com/api/workspace/schemas/create#properties)object

A map of key-value properties attached to the securable.

[`storage_root`](https://docs.databricks.com/api/workspace/schemas/create#storage_root)string

Storage root URL for managed tables within schema.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`browse_only`](https://docs.databricks.com/api/workspace/schemas/create#browse_only)boolean

Indicates whether the principal is limited to retrieving metadata for the associated object through the BROWSE privilege when include_browse is enabled in the request.

[`catalog_name`](https://docs.databricks.com/api/workspace/schemas/create#catalog_name)string

Name of parent catalog.

[`catalog_type`](https://docs.databricks.com/api/workspace/schemas/create#catalog_type)string

Enum: `MANAGED_CATALOG | DELTASHARING_CATALOG | SYSTEM_CATALOG | INTERNAL_CATALOG | FOREIGN_CATALOG | MANAGED_ONLINE_CATALOG`

The type of the parent catalog.

[`comment`](https://docs.databricks.com/api/workspace/schemas/create#comment)string

User-provided free-form text description.

[`created_at`](https://docs.databricks.com/api/workspace/schemas/create#created_at)int64

Time at which this schema was created, in epoch milliseconds.

[`created_by`](https://docs.databricks.com/api/workspace/schemas/create#created_by)string

Username of schema creator.

[`effective_predictive_optimization_flag`](https://docs.databricks.com/api/workspace/schemas/create#effective_predictive_optimization_flag)object

[`inherited_from_name`](https://docs.databricks.com/api/workspace/schemas/create#effective_predictive_optimization_flag-inherited_from_name)string

The name of the object from which the flag was inherited. If there was no inheritance, this field is left blank.

[`inherited_from_type`](https://docs.databricks.com/api/workspace/schemas/create#effective_predictive_optimization_flag-inherited_from_type)string

Enum: `CATALOG | SCHEMA`

The type of the object from which the flag was inherited. If there was no inheritance, this field is left blank.

[`value`](https://docs.databricks.com/api/workspace/schemas/create#effective_predictive_optimization_flag-value)string

Enum: `DISABLE | ENABLE | INHERIT`

Whether predictive optimization should be enabled for this object and objects under it.

[`enable_predictive_optimization`](https://docs.databricks.com/api/workspace/schemas/create#enable_predictive_optimization)string

Enum: `DISABLE | ENABLE | INHERIT`

Whether predictive optimization should be enabled for this object and objects under it.

[`full_name`](https://docs.databricks.com/api/workspace/schemas/create#full_name)string

Full name of schema, in form of catalog_name.schema_name.

[`metastore_id`](https://docs.databricks.com/api/workspace/schemas/create#metastore_id)string

Unique identifier of parent metastore.

[`name`](https://docs.databricks.com/api/workspace/schemas/create#name)string

Name of schema, relative to parent catalog.

[`owner`](https://docs.databricks.com/api/workspace/schemas/create#owner)string

Username of current owner of schema.

[`properties`](https://docs.databricks.com/api/workspace/schemas/create#properties)object

A map of key-value properties attached to the securable.

[`schema_id`](https://docs.databricks.com/api/workspace/schemas/create#schema_id)string

The unique identifier of the schema.

[`storage_location`](https://docs.databricks.com/api/workspace/schemas/create#storage_location)string

Storage location for managed tables within schema.

[`storage_root`](https://docs.databricks.com/api/workspace/schemas/create#storage_root)string

Storage root URL for managed tables within schema.

[`updated_at`](https://docs.databricks.com/api/workspace/schemas/create#updated_at)int64

Time at which this schema was created, in epoch milliseconds.

[`updated_by`](https://docs.databricks.com/api/workspace/schemas/create#updated_by)string

Username of user who last modified schema.

# Request samples

JSON

{ "catalog_name": "string", "comment": "string", "name": "string", "properties": { "property1": "string", "property2": "string" }, "storage_root": "string" }

# Response samples

200

{ "browse_only": true, "catalog_name": "string", "catalog_type": "MANAGED_CATALOG", "comment": "string", "created_at": 0, "created_by": "string", "effective_predictive_optimization_flag": { "inherited_from_name": "string", "inherited_from_type": "CATALOG", "value": "DISABLE" }, "enable_predictive_optimization": "DISABLE", "full_name": "string", "metastore_id": "string", "name": "string", "owner": "string", "properties": { "property1": "string", "property2": "string" }, "schema_id": "string", "storage_location": "string", "storage_root": "string", "updated_at": 0, "updated_by": "string" }
