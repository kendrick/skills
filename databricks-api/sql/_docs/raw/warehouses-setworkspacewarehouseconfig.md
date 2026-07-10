Title: Set the workspace configuration | SQL Warehouses API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/warehouses/setworkspacewarehouseconfig

Markdown Content:
## Set the workspace configuration

`PUT/api/2.0/sql/config/warehouses`

Sets the workspace level configuration that is shared by all SQL warehouses in a workspace.

API scopes (preview):[`sql`](https://docs.databricks.com/api/workspace/api/scopes#sql)

### Request body

Sets the workspace level warehouse configuration that is shared by all SQL warehouses in this workspace.

This is idempotent.

[`channel`](https://docs.databricks.com/api/workspace/warehouses/setworkspacewarehouseconfig#channel)object

Optional: Channel selection details

[`dbsql_version`](https://docs.databricks.com/api/workspace/warehouses/setworkspacewarehouseconfig#channel-dbsql_version)string

[`name`](https://docs.databricks.com/api/workspace/warehouses/setworkspacewarehouseconfig#channel-name)string

Enum: `CHANNEL_NAME_PREVIEW | CHANNEL_NAME_CURRENT | CHANNEL_NAME_PREVIOUS | CHANNEL_NAME_CUSTOM`

[`config_param`](https://docs.databricks.com/api/workspace/warehouses/setworkspacewarehouseconfig#config_param)object

Deprecated

Deprecated: Use sql_configuration_parameters

[`config_pair`](https://docs.databricks.com/api/workspace/warehouses/setworkspacewarehouseconfig#config_param-config_pair)Array of object

Deprecated

Deprecated: Use configuration_pairs

[`configuration_pairs`](https://docs.databricks.com/api/workspace/warehouses/setworkspacewarehouseconfig#config_param-configuration_pairs)Array of object

[`data_access_config`](https://docs.databricks.com/api/workspace/warehouses/setworkspacewarehouseconfig#data_access_config)Array of object

Spark confs for external hive metastore configuration JSON serialized size must be less than <= 512K

Array [

[`key`](https://docs.databricks.com/api/workspace/warehouses/setworkspacewarehouseconfig#data_access_config-key)string

[`value`](https://docs.databricks.com/api/workspace/warehouses/setworkspacewarehouseconfig#data_access_config-value)string

 ]

[`enable_serverless_compute`](https://docs.databricks.com/api/workspace/warehouses/setworkspacewarehouseconfig#enable_serverless_compute)boolean

Deprecated

Deprecated: only setting this to true is allowed.

[`enabled_warehouse_types`](https://docs.databricks.com/api/workspace/warehouses/setworkspacewarehouseconfig#enabled_warehouse_types)Array of object

List of Warehouse Types allowed in this workspace (limits allowed value of the type field in CreateWarehouse and EditWarehouse). Note: Some types cannot be disabled, they don't need to be specified in SetWorkspaceWarehouseConfig. Note: Disabling a type may cause existing warehouses to be converted to another type. Used by frontend to save specific type availability in the warehouse create and edit form UI.

Array [

[`enabled`](https://docs.databricks.com/api/workspace/warehouses/setworkspacewarehouseconfig#enabled_warehouse_types-enabled)boolean

If set to false the specific warehouse type will not be be allowed as a value for warehouse_type in CreateWarehouse and EditWarehouse

[`warehouse_type`](https://docs.databricks.com/api/workspace/warehouses/setworkspacewarehouseconfig#enabled_warehouse_types-warehouse_type)string

Enum: `TYPE_UNSPECIFIED | CLASSIC | PRO`

 ]

[`global_param`](https://docs.databricks.com/api/workspace/warehouses/setworkspacewarehouseconfig#global_param)object

Deprecated

Deprecated: Use sql_configuration_parameters

[`config_pair`](https://docs.databricks.com/api/workspace/warehouses/setworkspacewarehouseconfig#global_param-config_pair)Array of object

Deprecated

Deprecated: Use configuration_pairs

[`configuration_pairs`](https://docs.databricks.com/api/workspace/warehouses/setworkspacewarehouseconfig#global_param-configuration_pairs)Array of object

[`google_service_account`](https://docs.databricks.com/api/workspace/warehouses/setworkspacewarehouseconfig#google_service_account)string

GCP only: Google Service Account used to pass to cluster to access Google Cloud Storage

[`instance_profile_arn`](https://docs.databricks.com/api/workspace/warehouses/setworkspacewarehouseconfig#instance_profile_arn)string

Deprecated

AWS Only: The instance profile used to pass an IAM role to the SQL warehouses. This configuration is also applied to the workspace's serverless compute for notebooks and jobs.

[`security_policy`](https://docs.databricks.com/api/workspace/warehouses/setworkspacewarehouseconfig#security_policy)string

Enum: `NONE | DATA_ACCESS_CONTROL | PASSTHROUGH`

Security policy for warehouses

[`sql_configuration_parameters`](https://docs.databricks.com/api/workspace/warehouses/setworkspacewarehouseconfig#sql_configuration_parameters)object

SQL configuration parameters

[`config_pair`](https://docs.databricks.com/api/workspace/warehouses/setworkspacewarehouseconfig#sql_configuration_parameters-config_pair)Array of object

Deprecated

Deprecated: Use configuration_pairs

[`configuration_pairs`](https://docs.databricks.com/api/workspace/warehouses/setworkspacewarehouseconfig#sql_configuration_parameters-configuration_pairs)Array of object

### Responses

**200** Request completed successfully.

Request completed successfully.

# Request samples

JSON

{

"channel":{

"dbsql_version":"string",

"name":"CHANNEL_NAME_PREVIEW"

},

"config_param":{

"config_pair":[

{

"key":"string",

"value":"string"

}

],

"configuration_pairs":[

{

"key":"string",

"value":"string"

}

]

},

"data_access_config":[

{

"key":"string",

"value":"string"

}

],

"enable_serverless_compute":true,

"enabled_warehouse_types":[

{

"enabled":true,

"warehouse_type":"TYPE_UNSPECIFIED"

}

],

"global_param":{

"config_pair":[

{

"key":"string",

"value":"string"

}

],

"configuration_pairs":[

{

"key":"string",

"value":"string"

}

]

},

"google_service_account":"string",

"instance_profile_arn":"string",

"security_policy":"NONE",

"sql_configuration_parameters":{

"config_pair":[

{

"key":"string",

"value":"string"

}

],

"configuration_pairs":[

{

"key":"string",

"value":"string"

}

]

}

}

# Response samples

200

{}
