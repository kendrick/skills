Title: Update a share | Shares API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/shares/update

Markdown Content:
## Update a share

`PATCH/api/2.1/unity-catalog/shares/{name}`

Updates the share with the changes and data objects in the request. The caller must be the owner of the share or a metastore admin.

When the caller is a metastore admin, only the owner field can be updated.

In the case the share name is changed, updateShare requires that the caller is the owner of the share and has the CREATE_SHARE privilege.

If there are notebook files in the share, the storage_root field cannot be updated.

For each table that is added through this method, the share owner must also have SELECT privilege on the table. This privilege must be maintained indefinitely for recipients to be able to access the table. Typically, you should use a group as the share owner.

Table removals through update do not require additional privileges.

API scopes (preview):[`sharing`](https://docs.databricks.com/api/workspace/api/scopes#sharing)

### Path parameters

[`name`](https://docs.databricks.com/api/workspace/shares/update#name)required string

The name of the share.

### Request body

[`comment`](https://docs.databricks.com/api/workspace/shares/update#comment)string

User-provided free-form text description.

[`new_name`](https://docs.databricks.com/api/workspace/shares/update#new_name)string

New name for the share.

[`owner`](https://docs.databricks.com/api/workspace/shares/update#owner)string

Username of current owner of share.

[`storage_root`](https://docs.databricks.com/api/workspace/shares/update#storage_root)string

Storage root URL for the share.

[`updates`](https://docs.databricks.com/api/workspace/shares/update#updates)Array of object

Array of shared data object updates.

Array [

[`action`](https://docs.databricks.com/api/workspace/shares/update#updates-action)string

Enum: `ADD | REMOVE | UPDATE`

One of: ADD, REMOVE, UPDATE.

[`data_object`](https://docs.databricks.com/api/workspace/shares/update#updates-data_object)object

The data object that is being added, removed, or updated. The maximum number update data objects allowed is a 100.

 ]

### Responses

**200** Request completed successfully.

Request completed successfully.

[`comment`](https://docs.databricks.com/api/workspace/shares/update#comment)string

User-provided free-form text description.

[`created_at`](https://docs.databricks.com/api/workspace/shares/update#created_at)int64

Time at which this share was created, in epoch milliseconds.

[`created_by`](https://docs.databricks.com/api/workspace/shares/update#created_by)string

Username of share creator.

[`name`](https://docs.databricks.com/api/workspace/shares/update#name)string

Name of the share.

[`objects`](https://docs.databricks.com/api/workspace/shares/update#objects)Array of object

A list of shared data objects within the share.

Array [

[`added_at`](https://docs.databricks.com/api/workspace/shares/update#objects-added_at)int64

The time when this data object is added to the share, in epoch milliseconds.

[`added_by`](https://docs.databricks.com/api/workspace/shares/update#objects-added_by)string

Username of the sharer.

[`cdf_enabled`](https://docs.databricks.com/api/workspace/shares/update#objects-cdf_enabled)boolean

Whether to enable cdf or indicate if cdf is enabled on the shared object.

[`comment`](https://docs.databricks.com/api/workspace/shares/update#objects-comment)string

A user-provided comment when adding the data object to the share.

[`content`](https://docs.databricks.com/api/workspace/shares/update#objects-content)string

The content of the notebook file when the data object type is NOTEBOOK_FILE. This should be base64 encoded. Required for adding a NOTEBOOK_FILE, optional for updating, ignored for other types.

[`data_object_type`](https://docs.databricks.com/api/workspace/shares/update#objects-data_object_type)string

Enum: `TABLE | FOREIGN_TABLE | SCHEMA | VIEW | MATERIALIZED_VIEW | STREAMING_TABLE | MODEL | NOTEBOOK_FILE | FUNCTION | FEATURE_SPEC | VOLUME`

The type of the data object.

[`history_data_sharing_status`](https://docs.databricks.com/api/workspace/shares/update#objects-history_data_sharing_status)string

Enum: `DISABLED | ENABLED`

Whether to enable or disable sharing of data history. If not specified, the default is DISABLED.

[`name`](https://docs.databricks.com/api/workspace/shares/update#objects-name)string

A fully qualified name that uniquely identifies a data object. For example, a table's fully qualified name is in the format of `<catalog>.<schema>.<table>`,

[`partitions`](https://docs.databricks.com/api/workspace/shares/update#objects-partitions)Array of object

Array of partitions for the shared data.

[`shared_as`](https://docs.databricks.com/api/workspace/shares/update#objects-shared_as)string

A user-provided alias name for table-like data objects within the share.

Use this field for table-like objects (for example: TABLE, VIEW, MATERIALIZED_VIEW, STREAMING_TABLE, FOREIGN_TABLE). For non-table objects (for example: VOLUME, MODEL, NOTEBOOK_FILE, FUNCTION), use `string_shared_as` instead.

Important: For non-table objects, this field must be omitted entirely.

Format: Must be a 2-part name `<schema_name>.<table_name>` (e.g., "sales_schema.orders_table")

*   Both schema and table names must contain only alphanumeric characters and underscores
*   No periods, spaces, forward slashes, or control characters are allowed within each part
*   Do not include the catalog name (use 2 parts, not 3)

Behavior:

*   If not provided, the service automatically generates the alias as `<schema>.<table>` from the object's original name
*   If you don't want to specify this field, omit it entirely from the request (do not pass an empty string)
*   The `shared_as` name must be unique within the share

Examples:

*   Valid: "analytics_schema.customer_view"
*   Invalid: "catalog.analytics_schema.customer_view" (3 parts not allowed)
*   Invalid: "analytics-schema.customer-view" (hyphens not allowed)

[`start_version`](https://docs.databricks.com/api/workspace/shares/update#objects-start_version)int64

The start version associated with the object. This allows data providers to control the lowest object version that is accessible by clients. If specified, clients can query snapshots or changes for versions >= start_version. If not specified, clients can only query starting from the version of the object at the time it was added to the share.

NOTE: The start_version should be <= the `current` version of the object.

[`status`](https://docs.databricks.com/api/workspace/shares/update#objects-status)string

Enum: `ACTIVE | PERMISSION_DENIED`

One of: ACTIVE, PERMISSION_DENIED.

[`string_shared_as`](https://docs.databricks.com/api/workspace/shares/update#objects-string_shared_as)string

A user-provided alias name for non-table data objects within the share.

Use this field for non-table objects (for example: VOLUME, MODEL, NOTEBOOK_FILE, FUNCTION). For table-like objects (for example: TABLE, VIEW, MATERIALIZED_VIEW, STREAMING_TABLE, FOREIGN_TABLE), use `shared_as` instead.

Important: For table-like objects, this field must be omitted entirely.

Format:

*   For VOLUME: Must be a 2-part name `<schema_name>.<volume_name>` (e.g., "data_schema.ml_models")
*   For FUNCTION: Must be a 2-part name `<schema_name>.<function_name>` (e.g., "udf_schema.calculate_tax")
*   For MODEL: Must be a 2-part name `<schema_name>.<model_name>` (e.g., "models.prediction_model")
*   For NOTEBOOK_FILE: Should be the notebook file name (e.g., "analysis_notebook.py")
*   All names must contain only alphanumeric characters and underscores
*   No periods, spaces, forward slashes, or control characters are allowed within each part

Behavior:

*   If not provided, the service automatically generates the alias from the object's original name
*   If you don't want to specify this field, omit it entirely from the request (do not pass an empty string)
*   The `string_shared_as` name must be unique for objects of the same type within the share

Examples:

*   Valid for VOLUME: "data_schema.training_data"
*   Valid for FUNCTION: "analytics.calculate_revenue"
*   Invalid: "catalog.data_schema.training_data" (3 parts not allowed for volumes)
*   Invalid: "data-schema.training-data" (hyphens not allowed)

 ]

[`owner`](https://docs.databricks.com/api/workspace/shares/update#owner)string

Username of current owner of share.

[`storage_location`](https://docs.databricks.com/api/workspace/shares/update#storage_location)string

Storage Location URL (full path) for the share.

[`storage_root`](https://docs.databricks.com/api/workspace/shares/update#storage_root)string

Storage root URL for the share.

[`updated_at`](https://docs.databricks.com/api/workspace/shares/update#updated_at)int64

Time at which this share was updated, in epoch milliseconds.

[`updated_by`](https://docs.databricks.com/api/workspace/shares/update#updated_by)string

Username of share updater.

# Request samples

JSON

{

"comment":"string",

"new_name":"string",

"owner":"string",

"storage_root":"string",

"updates":[

{

"action":"ADD",

"data_object":{

"added_at":0,

"added_by":"string",

"cdf_enabled":true,

"comment":"string",

"content":"string",

"data_object_type":"TABLE",

"history_data_sharing_status":"DISABLED",

"name":"string",

"partitions":[

{

"values":[

{

"name":"string",

"op":"EQUAL",

"recipient_property_key":"string",

"value":"string"

}

]

}

],

"shared_as":"string",

"start_version":0,

"status":"ACTIVE",

"string_shared_as":"string"

}

}

]

}

# Response samples

200

{

"comment":"string",

"created_at":0,

"created_by":"string",

"name":"string",

"objects":[

{

"added_at":0,

"added_by":"string",

"cdf_enabled":true,

"comment":"string",

"content":"string",

"data_object_type":"TABLE",

"history_data_sharing_status":"DISABLED",

"name":"string",

"partitions":[

{

"values":[

{

"name":"string",

"op":"EQUAL",

"recipient_property_key":"string",

"value":"string"

}

]

}

],

"shared_as":"string",

"start_version":0,

"status":"ACTIVE",

"string_shared_as":"string"

}

],

"owner":"string",

"storage_location":"string",

"storage_root":"string",

"updated_at":0,

"updated_by":"string"

}
