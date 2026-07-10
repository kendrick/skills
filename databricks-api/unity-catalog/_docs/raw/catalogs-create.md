Title: Create a catalog | Catalogs API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/catalogs/create

Markdown Content:
## Create a catalog

`POST/api/2.1/unity-catalog/catalogs`

Creates a new catalog instance in the parent metastore if the caller is a metastore admin or has the CREATE_CATALOG privilege.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Request body

[`comment`](https://docs.databricks.com/api/workspace/catalogs/create#comment)string

User-provided free-form text description.

[`connection_name`](https://docs.databricks.com/api/workspace/catalogs/create#connection_name)string

The name of the connection to an external data source.

[`name`](https://docs.databricks.com/api/workspace/catalogs/create#name)required string

Name of catalog.

[`options`](https://docs.databricks.com/api/workspace/catalogs/create#options)object

A map of key-value properties attached to the securable.

[`properties`](https://docs.databricks.com/api/workspace/catalogs/create#properties)object

A map of key-value properties attached to the securable.

[`provider_name`](https://docs.databricks.com/api/workspace/catalogs/create#provider_name)string

The name of delta sharing provider.

A Delta Sharing catalog is a catalog that is based on a Delta share on a remote sharing server.

[`share_name`](https://docs.databricks.com/api/workspace/catalogs/create#share_name)string

The name of the share under the share provider.

[`storage_root`](https://docs.databricks.com/api/workspace/catalogs/create#storage_root)string

Storage root URL for managed tables within catalog.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`browse_only`](https://docs.databricks.com/api/workspace/catalogs/create#browse_only)boolean

Indicates whether the principal is limited to retrieving metadata for the associated object through the BROWSE privilege when include_browse is enabled in the request.

[`catalog_type`](https://docs.databricks.com/api/workspace/catalogs/create#catalog_type)string

Enum: `MANAGED_CATALOG | DELTASHARING_CATALOG | SYSTEM_CATALOG | INTERNAL_CATALOG | FOREIGN_CATALOG | MANAGED_ONLINE_CATALOG`

The type of the catalog.

[`comment`](https://docs.databricks.com/api/workspace/catalogs/create#comment)string

User-provided free-form text description.

[`connection_name`](https://docs.databricks.com/api/workspace/catalogs/create#connection_name)string

The name of the connection to an external data source.

[`created_at`](https://docs.databricks.com/api/workspace/catalogs/create#created_at)int64

Time at which this catalog was created, in epoch milliseconds.

[`created_by`](https://docs.databricks.com/api/workspace/catalogs/create#created_by)string

Username of catalog creator.

[`effective_predictive_optimization_flag`](https://docs.databricks.com/api/workspace/catalogs/create#effective_predictive_optimization_flag)object

[`inherited_from_name`](https://docs.databricks.com/api/workspace/catalogs/create#effective_predictive_optimization_flag-inherited_from_name)string

The name of the object from which the flag was inherited. If there was no inheritance, this field is left blank.

[`inherited_from_type`](https://docs.databricks.com/api/workspace/catalogs/create#effective_predictive_optimization_flag-inherited_from_type)string

Enum: `CATALOG | SCHEMA`

The type of the object from which the flag was inherited. If there was no inheritance, this field is left blank.

[`value`](https://docs.databricks.com/api/workspace/catalogs/create#effective_predictive_optimization_flag-value)string

Enum: `DISABLE | ENABLE | INHERIT`

Whether predictive optimization should be enabled for this object and objects under it.

[`enable_predictive_optimization`](https://docs.databricks.com/api/workspace/catalogs/create#enable_predictive_optimization)string

Enum: `DISABLE | ENABLE | INHERIT`

Whether predictive optimization should be enabled for this object and objects under it.

[`full_name`](https://docs.databricks.com/api/workspace/catalogs/create#full_name)string

The full name of the catalog. Corresponds with the name field.

[`isolation_mode`](https://docs.databricks.com/api/workspace/catalogs/create#isolation_mode)string

Enum: `OPEN | ISOLATED`

Whether the current securable is accessible from all workspaces or a specific set of workspaces.

[`metastore_id`](https://docs.databricks.com/api/workspace/catalogs/create#metastore_id)string

Unique identifier of parent metastore.

[`name`](https://docs.databricks.com/api/workspace/catalogs/create#name)string

Name of catalog.

[`options`](https://docs.databricks.com/api/workspace/catalogs/create#options)object

A map of key-value properties attached to the securable.

[`owner`](https://docs.databricks.com/api/workspace/catalogs/create#owner)string

Username of current owner of catalog.

[`properties`](https://docs.databricks.com/api/workspace/catalogs/create#properties)object

A map of key-value properties attached to the securable.

[`provider_name`](https://docs.databricks.com/api/workspace/catalogs/create#provider_name)string

The name of delta sharing provider.

A Delta Sharing catalog is a catalog that is based on a Delta share on a remote sharing server.

[`provisioning_info`](https://docs.databricks.com/api/workspace/catalogs/create#provisioning_info)object

Status of an asynchronously provisioned resource.

[`state`](https://docs.databricks.com/api/workspace/catalogs/create#provisioning_info-state)string

Enum: `PROVISIONING | ACTIVE | FAILED | DELETING | UPDATING | DEGRADED`

The provisioning state of the resource.

[`securable_type`](https://docs.databricks.com/api/workspace/catalogs/create#securable_type)string

Enum: `CATALOG | SCHEMA | TABLE | STORAGE_CREDENTIAL | EXTERNAL_LOCATION | FUNCTION | SHARE | PROVIDER | RECIPIENT | CLEAN_ROOM | METASTORE | PIPELINE | VOLUME | CONNECTION | CREDENTIAL | EXTERNAL_METADATA | STAGING_TABLE`

Default`"CATALOG"`

The type of Unity Catalog securable.

[`share_name`](https://docs.databricks.com/api/workspace/catalogs/create#share_name)string

The name of the share under the share provider.

[`storage_location`](https://docs.databricks.com/api/workspace/catalogs/create#storage_location)string

Storage Location URL (full path) for managed tables within catalog.

[`storage_root`](https://docs.databricks.com/api/workspace/catalogs/create#storage_root)string

Storage root URL for managed tables within catalog.

[`updated_at`](https://docs.databricks.com/api/workspace/catalogs/create#updated_at)int64

Time at which this catalog was last modified, in epoch milliseconds.

[`updated_by`](https://docs.databricks.com/api/workspace/catalogs/create#updated_by)string

Username of user who last modified catalog.

# Request samples

JSON

{

"comment":"string",

"connection_name":"string",

"name":"string",

"options":{

"property1":"string",

"property2":"string"

},

"properties":{

"property1":"string",

"property2":"string"

},

"provider_name":"string",

"share_name":"string",

"storage_root":"string"

}

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
