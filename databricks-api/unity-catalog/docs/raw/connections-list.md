Title: List connections | Connections API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/connections/list

Markdown Content:
## List connections

`GET/api/2.1/unity-catalog/connections`

List all connections.

NOTE: we recommend using max_results=0 to use the paginated version of this API. Unpaginated calls will be deprecated soon.

PAGINATION BEHAVIOR: When using pagination (max_results >= 0), a page may contain zero results while still providing a next_page_token. Clients must continue reading pages until next_page_token is absent, which is the only indication that the end of results has been reached.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Query parameters

[`max_results`](https://docs.databricks.com/api/workspace/connections/list#max_results)int32

<= 1000 

Maximum number of connections to return.

*   If not set, all connections are returned (not recommended).
*   when set to a value greater than 0, the page length is the minimum of this value and a server configured value;
*   when set to 0, the page length is set to a server configured value (recommended);
*   when set to a value less than 0, an invalid parameter error is returned;

[`page_token`](https://docs.databricks.com/api/workspace/connections/list#page_token)string

Opaque pagination token to go to next page based on previous query.

### Responses

**200** Request completed successfully. The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

Request completed successfully.

 The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

[`connections`](https://docs.databricks.com/api/workspace/connections/list#connections)Array of object

An array of connection information objects.

Array [

[`comment`](https://docs.databricks.com/api/workspace/connections/list#connections-comment)string

User-provided free-form text description.

[`connection_id`](https://docs.databricks.com/api/workspace/connections/list#connections-connection_id)string

Unique identifier of the Connection.

[`connection_type`](https://docs.databricks.com/api/workspace/connections/list#connections-connection_type)string

Enum: `UNKNOWN_CONNECTION_TYPE | MYSQL | POSTGRESQL | SNOWFLAKE | REDSHIFT | SQLDW | SQLSERVER | DATABRICKS | SALESFORCE | BIGQUERY | WORKDAY_RAAS | HIVE_METASTORE | GA4_RAW_DATA | SERVICENOW | SALESFORCE_DATA_CLOUD | GLUE | ORACLE | TERADATA | HTTP | POWER_BI`

The type of connection.

[`created_at`](https://docs.databricks.com/api/workspace/connections/list#connections-created_at)int64

Time at which this connection was created, in epoch milliseconds.

[`created_by`](https://docs.databricks.com/api/workspace/connections/list#connections-created_by)string

Username of connection creator.

[`credential_type`](https://docs.databricks.com/api/workspace/connections/list#connections-credential_type)string

Enum: `UNKNOWN_CREDENTIAL_TYPE | USERNAME_PASSWORD | OAUTH_U2M | OAUTH_M2M | OAUTH_REFRESH_TOKEN | OAUTH_ACCESS_TOKEN | OAUTH_RESOURCE_OWNER_PASSWORD | SERVICE_CREDENTIAL | BEARER_TOKEN | OIDC_TOKEN | PEM_PRIVATE_KEY | OAUTH_U2M_MAPPING | ANY_STATIC_CREDENTIAL | OAUTH_MTLS | SSWS_TOKEN | EDGEGRID_AKAMAI`

The type of credential.

[`full_name`](https://docs.databricks.com/api/workspace/connections/list#connections-full_name)string

Full name of connection.

[`metastore_id`](https://docs.databricks.com/api/workspace/connections/list#connections-metastore_id)string

Unique identifier of parent metastore.

[`name`](https://docs.databricks.com/api/workspace/connections/list#connections-name)string

Name of the connection.

[`options`](https://docs.databricks.com/api/workspace/connections/list#connections-options)object

A map of key-value properties attached to the securable.

[`owner`](https://docs.databricks.com/api/workspace/connections/list#connections-owner)string

Username of current owner of the connection.

[`properties`](https://docs.databricks.com/api/workspace/connections/list#connections-properties)object

A map of key-value properties attached to the securable.

[`provisioning_info`](https://docs.databricks.com/api/workspace/connections/list#connections-provisioning_info)object

Status of an asynchronously provisioned resource.

[`read_only`](https://docs.databricks.com/api/workspace/connections/list#connections-read_only)boolean

If the connection is read only.

[`securable_type`](https://docs.databricks.com/api/workspace/connections/list#connections-securable_type)string

Enum: `CATALOG | SCHEMA | TABLE | STORAGE_CREDENTIAL | EXTERNAL_LOCATION | FUNCTION | SHARE | PROVIDER | RECIPIENT | CLEAN_ROOM | METASTORE | PIPELINE | VOLUME | CONNECTION | CREDENTIAL | EXTERNAL_METADATA | STAGING_TABLE`

Default`"CONNECTION"`

The type of Unity Catalog securable.

[`updated_at`](https://docs.databricks.com/api/workspace/connections/list#connections-updated_at)int64

Time at which this connection was updated, in epoch milliseconds.

[`updated_by`](https://docs.databricks.com/api/workspace/connections/list#connections-updated_by)string

Username of user who last modified connection.

[`url`](https://docs.databricks.com/api/workspace/connections/list#connections-url)string

URL of the remote data source, extracted from options.

 ]

[`next_page_token`](https://docs.databricks.com/api/workspace/connections/list#next_page_token)string

Opaque token to retrieve the next page of results. Absent if there are no more pages. page_token should be set to this value for the next request (for the next page of results).

# Response samples

200

{

"connections":[

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

],

"next_page_token":"string"

}
