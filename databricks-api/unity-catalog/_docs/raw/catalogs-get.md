Title: Get a catalog | Catalogs API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/catalogs/get

Markdown Content:
## Get a catalog

`GET/api/2.1/unity-catalog/catalogs/{name}`

Gets the specified catalog in a metastore. The caller must be a metastore admin, the owner of the catalog, or a user that has the USE_CATALOG privilege set for their account.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`name`](https://docs.databricks.com/api/workspace/catalogs/get#name)required string

The name of the catalog.

### Query parameters

[`include_browse`](https://docs.databricks.com/api/workspace/catalogs/get#include_browse)boolean

Whether to include catalogs in the response for which the principal can only access selective metadata for

### Responses

**200** Request completed successfully.

Request completed successfully.

[`browse_only`](https://docs.databricks.com/api/workspace/catalogs/get#browse_only)boolean

Indicates whether the principal is limited to retrieving metadata for the associated object through the BROWSE privilege when include_browse is enabled in the request.

[`catalog_type`](https://docs.databricks.com/api/workspace/catalogs/get#catalog_type)string

Enum: `MANAGED_CATALOG | DELTASHARING_CATALOG | SYSTEM_CATALOG | INTERNAL_CATALOG | FOREIGN_CATALOG | MANAGED_ONLINE_CATALOG`

The type of the catalog.

[`comment`](https://docs.databricks.com/api/workspace/catalogs/get#comment)string

User-provided free-form text description.

[`connection_name`](https://docs.databricks.com/api/workspace/catalogs/get#connection_name)string

The name of the connection to an external data source.

[`created_at`](https://docs.databricks.com/api/workspace/catalogs/get#created_at)int64

Time at which this catalog was created, in epoch milliseconds.

[`created_by`](https://docs.databricks.com/api/workspace/catalogs/get#created_by)string

Username of catalog creator.

[`effective_predictive_optimization_flag`](https://docs.databricks.com/api/workspace/catalogs/get#effective_predictive_optimization_flag)object

[`inherited_from_name`](https://docs.databricks.com/api/workspace/catalogs/get#effective_predictive_optimization_flag-inherited_from_name)string

The name of the object from which the flag was inherited. If there was no inheritance, this field is left blank.

[`inherited_from_type`](https://docs.databricks.com/api/workspace/catalogs/get#effective_predictive_optimization_flag-inherited_from_type)string

Enum: `CATALOG | SCHEMA`

The type of the object from which the flag was inherited. If there was no inheritance, this field is left blank.

[`value`](https://docs.databricks.com/api/workspace/catalogs/get#effective_predictive_optimization_flag-value)string

Enum: `DISABLE | ENABLE | INHERIT`

Whether predictive optimization should be enabled for this object and objects under it.

[`enable_predictive_optimization`](https://docs.databricks.com/api/workspace/catalogs/get#enable_predictive_optimization)string

Enum: `DISABLE | ENABLE | INHERIT`

Whether predictive optimization should be enabled for this object and objects under it.

[`full_name`](https://docs.databricks.com/api/workspace/catalogs/get#full_name)string

The full name of the catalog. Corresponds with the name field.

[`isolation_mode`](https://docs.databricks.com/api/workspace/catalogs/get#isolation_mode)string

Enum: `OPEN | ISOLATED`

Whether the current securable is accessible from all workspaces or a specific set of workspaces.

[`metastore_id`](https://docs.databricks.com/api/workspace/catalogs/get#metastore_id)string

Unique identifier of parent metastore.

[`name`](https://docs.databricks.com/api/workspace/catalogs/get#name)string

Name of catalog.

[`options`](https://docs.databricks.com/api/workspace/catalogs/get#options)object

A map of key-value properties attached to the securable.

[`owner`](https://docs.databricks.com/api/workspace/catalogs/get#owner)string

Username of current owner of catalog.

[`properties`](https://docs.databricks.com/api/workspace/catalogs/get#properties)object

A map of key-value properties attached to the securable.

[`provider_name`](https://docs.databricks.com/api/workspace/catalogs/get#provider_name)string

The name of delta sharing provider.

A Delta Sharing catalog is a catalog that is based on a Delta share on a remote sharing server.

[`provisioning_info`](https://docs.databricks.com/api/workspace/catalogs/get#provisioning_info)object

Status of an asynchronously provisioned resource.

[`state`](https://docs.databricks.com/api/workspace/catalogs/get#provisioning_info-state)string

Enum: `PROVISIONING | ACTIVE | FAILED | DELETING | UPDATING | DEGRADED`

The provisioning state of the resource.

[`securable_type`](https://docs.databricks.com/api/workspace/catalogs/get#securable_type)string

Enum: `CATALOG | SCHEMA | TABLE | STORAGE_CREDENTIAL | EXTERNAL_LOCATION | FUNCTION | SHARE | PROVIDER | RECIPIENT | CLEAN_ROOM | METASTORE | PIPELINE | VOLUME | CONNECTION | CREDENTIAL | EXTERNAL_METADATA | STAGING_TABLE`

Default`"CATALOG"`

The type of Unity Catalog securable.

[`share_name`](https://docs.databricks.com/api/workspace/catalogs/get#share_name)string

The name of the share under the share provider.

[`storage_location`](https://docs.databricks.com/api/workspace/catalogs/get#storage_location)string

Storage Location URL (full path) for managed tables within catalog.

[`storage_root`](https://docs.databricks.com/api/workspace/catalogs/get#storage_root)string

Storage root URL for managed tables within catalog.

[`updated_at`](https://docs.databricks.com/api/workspace/catalogs/get#updated_at)int64

Time at which this catalog was last modified, in epoch milliseconds.

[`updated_by`](https://docs.databricks.com/api/workspace/catalogs/get#updated_by)string

Username of user who last modified catalog.

# Response samples

200

{

"browse_only":true,

"catalog_type":"MANAGED_CATALOG",

"comment":"string",

"connection_name":"string",

"created_at":0,

"created_by":"string",

"effective_predictive_optimization_flag":{

"inherited_from_name":"string",

"inherited_from_type":"CATALOG",

"value":"DISABLE"

},

"enable_predictive_optimization":"DISABLE",

"full_name":"string",

"isolation_mode":"OPEN",

"metastore_id":"string",

"name":"string",

"options":{

"property1":"string",

"property2":"string"

},

"owner":"string",

"properties":{

"property1":"string",

"property2":"string"

},

"provider_name":"string",

"provisioning_info":{

"state":"PROVISIONING"

},

"securable_type":"CATALOG",

"share_name":"string",

"storage_location":"string",

"storage_root":"string",

"updated_at":0,

"updated_by":"string"

}
