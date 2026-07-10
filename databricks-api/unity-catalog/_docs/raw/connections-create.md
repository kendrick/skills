Title: Create a connection | Connections API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/connections/create

Markdown Content:
## Create a connection

`POST/api/2.1/unity-catalog/connections`

Creates a new connection

Creates a new connection to an external data source. It allows users to specify connection details and configurations for interaction with the external server.

Supported data sources for connections are listed [here](https://docs.databricks.com/aws/en/query-federation/#supported-data-sources).

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Request body

[`comment`](https://docs.databricks.com/api/workspace/connections/create#comment)string

User-provided free-form text description.

[`connection_type`](https://docs.databricks.com/api/workspace/connections/create#connection_type)required string

Enum: `UNKNOWN_CONNECTION_TYPE | MYSQL | POSTGRESQL | SNOWFLAKE | REDSHIFT | SQLDW | SQLSERVER | DATABRICKS | SALESFORCE | BIGQUERY | WORKDAY_RAAS | HIVE_METASTORE | GA4_RAW_DATA | SERVICENOW | SALESFORCE_DATA_CLOUD | GLUE | ORACLE | TERADATA | HTTP | POWER_BI`

The type of connection.

[`name`](https://docs.databricks.com/api/workspace/connections/create#name)required string

Name of the connection.

[`options`](https://docs.databricks.com/api/workspace/connections/create#options)required object

A map of key-value properties attached to the securable.

[`properties`](https://docs.databricks.com/api/workspace/connections/create#properties)object

A map of key-value properties attached to the securable.

[`read_only`](https://docs.databricks.com/api/workspace/connections/create#read_only)boolean

If the connection is read only.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`comment`](https://docs.databricks.com/api/workspace/connections/create#comment)string

User-provided free-form text description.

[`connection_id`](https://docs.databricks.com/api/workspace/connections/create#connection_id)string

Unique identifier of the Connection.

[`connection_type`](https://docs.databricks.com/api/workspace/connections/create#connection_type)string

Enum: `UNKNOWN_CONNECTION_TYPE | MYSQL | POSTGRESQL | SNOWFLAKE | REDSHIFT | SQLDW | SQLSERVER | DATABRICKS | SALESFORCE | BIGQUERY | WORKDAY_RAAS | HIVE_METASTORE | GA4_RAW_DATA | SERVICENOW | SALESFORCE_DATA_CLOUD | GLUE | ORACLE | TERADATA | HTTP | POWER_BI`

The type of connection.

[`created_at`](https://docs.databricks.com/api/workspace/connections/create#created_at)int64

Time at which this connection was created, in epoch milliseconds.

[`created_by`](https://docs.databricks.com/api/workspace/connections/create#created_by)string

Username of connection creator.

[`credential_type`](https://docs.databricks.com/api/workspace/connections/create#credential_type)string

Enum: `UNKNOWN_CREDENTIAL_TYPE | USERNAME_PASSWORD | OAUTH_U2M | OAUTH_M2M | OAUTH_REFRESH_TOKEN | OAUTH_ACCESS_TOKEN | OAUTH_RESOURCE_OWNER_PASSWORD | SERVICE_CREDENTIAL | BEARER_TOKEN | OIDC_TOKEN | PEM_PRIVATE_KEY | OAUTH_U2M_MAPPING | ANY_STATIC_CREDENTIAL | OAUTH_MTLS | SSWS_TOKEN | EDGEGRID_AKAMAI`

The type of credential.

[`full_name`](https://docs.databricks.com/api/workspace/connections/create#full_name)string

Full name of connection.

[`metastore_id`](https://docs.databricks.com/api/workspace/connections/create#metastore_id)string

Unique identifier of parent metastore.

[`name`](https://docs.databricks.com/api/workspace/connections/create#name)string

Name of the connection.

[`options`](https://docs.databricks.com/api/workspace/connections/create#options)object

A map of key-value properties attached to the securable.

[`owner`](https://docs.databricks.com/api/workspace/connections/create#owner)string

Username of current owner of the connection.

[`properties`](https://docs.databricks.com/api/workspace/connections/create#properties)object

A map of key-value properties attached to the securable.

[`provisioning_info`](https://docs.databricks.com/api/workspace/connections/create#provisioning_info)object

Status of an asynchronously provisioned resource.

[`state`](https://docs.databricks.com/api/workspace/connections/create#provisioning_info-state)string

Enum: `PROVISIONING | ACTIVE | FAILED | DELETING | UPDATING | DEGRADED`

The provisioning state of the resource.

[`read_only`](https://docs.databricks.com/api/workspace/connections/create#read_only)boolean

If the connection is read only.

[`securable_type`](https://docs.databricks.com/api/workspace/connections/create#securable_type)string

Enum: `CATALOG | SCHEMA | TABLE | STORAGE_CREDENTIAL | EXTERNAL_LOCATION | FUNCTION | SHARE | PROVIDER | RECIPIENT | CLEAN_ROOM | METASTORE | PIPELINE | VOLUME | CONNECTION | CREDENTIAL | EXTERNAL_METADATA | STAGING_TABLE`

Default`"CONNECTION"`

The type of Unity Catalog securable.

[`updated_at`](https://docs.databricks.com/api/workspace/connections/create#updated_at)int64

Time at which this connection was updated, in epoch milliseconds.

[`updated_by`](https://docs.databricks.com/api/workspace/connections/create#updated_by)string

Username of user who last modified connection.

[`url`](https://docs.databricks.com/api/workspace/connections/create#url)string

URL of the remote data source, extracted from options.

# Request samples

JSON

{

"comment":"string",

"connection_type":"UNKNOWN_CONNECTION_TYPE",

"name":"string",

"options":{

"property1":"string",

"property2":"string"

},

"properties":{

"property1":"string",

"property2":"string"

},

"read_only":true

}

# Response samples

200

{

"comment":"string",

"connection_id":"string",

"connection_type":"UNKNOWN_CONNECTION_TYPE",

"created_at":0,

"created_by":"string",

"credential_type":"UNKNOWN_CREDENTIAL_TYPE",

"full_name":"string",

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

"provisioning_info":{

"state":"PROVISIONING"

},

"read_only":true,

"securable_type":"CATALOG",

"updated_at":0,

"updated_by":"string",

"url":"string"

}
