Title: List tables | Tables API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/tables/list

Markdown Content:
## List tables

`GET/api/2.1/unity-catalog/tables`

Gets an array of all tables for the current metastore under the parent catalog and schema. The caller must be a metastore admin or an owner of (or have the SELECT privilege on) the table. For the latter case, the caller must also be the owner or have the USE_CATALOG privilege on the parent catalog and the USE_SCHEMA privilege on the parent schema. There is no guarantee of a specific ordering of the elements in the array.

NOTE: view_dependencies and table_constraints are not returned by ListTables queries.

NOTE: we recommend using max_results=0 to use the paginated version of this API. Unpaginated calls will be deprecated soon.

PAGINATION BEHAVIOR: When using pagination (max_results >= 0), a page may contain zero results while still providing a next_page_token. Clients must continue reading pages until next_page_token is absent, which is the only indication that the end of results has been reached.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Query parameters

[`catalog_name`](https://docs.databricks.com/api/workspace/tables/list#catalog_name)required string

Name of parent catalog for tables of interest.

[`schema_name`](https://docs.databricks.com/api/workspace/tables/list#schema_name)required string

Parent schema of tables.

[`max_results`](https://docs.databricks.com/api/workspace/tables/list#max_results)int32

<= 50 

Maximum number of tables to return. If not set, all the tables are returned (not recommended).

*   when set to a value greater than 0, the page length is the minimum of this value and a server configured value;
*   when set to 0, the page length is set to a server configured value (recommended);
*   when set to a value less than 0, an invalid parameter error is returned;

[`page_token`](https://docs.databricks.com/api/workspace/tables/list#page_token)string

Opaque token to send for the next page of results (pagination).

[`omit_columns`](https://docs.databricks.com/api/workspace/tables/list#omit_columns)boolean

Whether to omit the columns of the table from the response or not.

[`omit_properties`](https://docs.databricks.com/api/workspace/tables/list#omit_properties)boolean

Whether to omit the properties of the table from the response or not.

[`omit_username`](https://docs.databricks.com/api/workspace/tables/list#omit_username)boolean

Whether to omit the username of the table (e.g. owner, updated_by, created_by) from the response or not.

[`include_browse`](https://docs.databricks.com/api/workspace/tables/list#include_browse)boolean

Whether to include tables in the response for which the principal can only access selective metadata for.

[`include_manifest_capabilities`](https://docs.databricks.com/api/workspace/tables/list#include_manifest_capabilities)boolean

Whether to include a manifest containing table capabilities in the response.

### Responses

**200** Request completed successfully. The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

Request completed successfully.

 The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

[`next_page_token`](https://docs.databricks.com/api/workspace/tables/list#next_page_token)string

Opaque token to retrieve the next page of results. Absent if there are no more pages. page_token should be set to this value for the next request (for the next page of results).

[`tables`](https://docs.databricks.com/api/workspace/tables/list#tables)Array of object

An array of table information objects.

Array [

[`access_point`](https://docs.databricks.com/api/workspace/tables/list#tables-access_point)string

The AWS access point to use when accesing s3 for this external location.

[`browse_only`](https://docs.databricks.com/api/workspace/tables/list#tables-browse_only)boolean

Indicates whether the principal is limited to retrieving metadata for the associated object through the BROWSE privilege when include_browse is enabled in the request.

[`catalog_name`](https://docs.databricks.com/api/workspace/tables/list#tables-catalog_name)string

Name of parent catalog.

[`columns`](https://docs.databricks.com/api/workspace/tables/list#tables-columns)Array of object

The array of ColumnInfo definitions of the table's columns.

[`comment`](https://docs.databricks.com/api/workspace/tables/list#tables-comment)string

User-provided free-form text description.

[`created_at`](https://docs.databricks.com/api/workspace/tables/list#tables-created_at)int64

Time at which this table was created, in epoch milliseconds.

[`created_by`](https://docs.databricks.com/api/workspace/tables/list#tables-created_by)string

Username of table creator.

[`data_access_configuration_id`](https://docs.databricks.com/api/workspace/tables/list#tables-data_access_configuration_id)string

Deprecated

Unique ID of the Data Access Configuration to use with the table data.

[`data_source_format`](https://docs.databricks.com/api/workspace/tables/list#tables-data_source_format)string

Enum: `DELTA | CSV | JSON | AVRO | PARQUET | ORC | TEXT | UNITY_CATALOG | DELTASHARING | DATABRICKS_FORMAT | MYSQL_FORMAT | ORACLE_FORMAT | POSTGRESQL_FORMAT | REDSHIFT_FORMAT | SNOWFLAKE_FORMAT | SQLDW_FORMAT | SQLSERVER_FORMAT | SALESFORCE_FORMAT | SALESFORCE_DATA_CLOUD_FORMAT | TERADATA_FORMAT | BIGQUERY_FORMAT | NETSUITE_FORMAT | WORKDAY_RAAS_FORMAT | MONGODB_FORMAT | HIVE | VECTOR_INDEX_FORMAT | DATABRICKS_ROW_STORE_FORMAT | DELTA_UNIFORM_HUDI | DELTA_UNIFORM_ICEBERG | ICEBERG`

Data source format

[`deleted_at`](https://docs.databricks.com/api/workspace/tables/list#tables-deleted_at)int64

Time at which this table was deleted, in epoch milliseconds. Field is omitted if table is not deleted.

[`delta_runtime_properties_kvpairs`](https://docs.databricks.com/api/workspace/tables/list#tables-delta_runtime_properties_kvpairs)object

Information pertaining to current state of the delta table.

[`effective_predictive_optimization_flag`](https://docs.databricks.com/api/workspace/tables/list#tables-effective_predictive_optimization_flag)object

[`enable_predictive_optimization`](https://docs.databricks.com/api/workspace/tables/list#tables-enable_predictive_optimization)string

Enum: `DISABLE | ENABLE | INHERIT`

[`full_name`](https://docs.databricks.com/api/workspace/tables/list#tables-full_name)string

Full name of table, in form of catalog_name.schema_name.table_name

[`metastore_id`](https://docs.databricks.com/api/workspace/tables/list#tables-metastore_id)string

Unique identifier of parent metastore.

[`name`](https://docs.databricks.com/api/workspace/tables/list#tables-name)string

Name of table, relative to parent schema.

[`owner`](https://docs.databricks.com/api/workspace/tables/list#tables-owner)string

Username of current owner of table.

[`pipeline_id`](https://docs.databricks.com/api/workspace/tables/list#tables-pipeline_id)string

The pipeline ID of the table. Applicable for tables created by pipelines (Materialized View, Streaming Table, etc.).

[`properties`](https://docs.databricks.com/api/workspace/tables/list#tables-properties)object

A map of key-value properties attached to the securable.

[`row_filter`](https://docs.databricks.com/api/workspace/tables/list#tables-row_filter)object

[`schema_name`](https://docs.databricks.com/api/workspace/tables/list#tables-schema_name)string

Name of parent schema relative to its parent catalog.

[`securable_kind_manifest`](https://docs.databricks.com/api/workspace/tables/list#tables-securable_kind_manifest)object

SecurableKindManifest of table, including capabilities the table has.

[`sql_path`](https://docs.databricks.com/api/workspace/tables/list#tables-sql_path)string

List of schemes whose objects can be referenced without qualification.

[`storage_credential_name`](https://docs.databricks.com/api/workspace/tables/list#tables-storage_credential_name)string

Name of the storage credential, when a storage credential is configured for use with this table.

[`storage_location`](https://docs.databricks.com/api/workspace/tables/list#tables-storage_location)string

Storage root URL for table (for MANAGED, EXTERNAL tables).

[`table_constraints`](https://docs.databricks.com/api/workspace/tables/list#tables-table_constraints)Array of object

List of table constraints. Note: this field is not set in the output of the listTables API.

[`table_id`](https://docs.databricks.com/api/workspace/tables/list#tables-table_id)string

The unique identifier of the table.

[`table_type`](https://docs.databricks.com/api/workspace/tables/list#tables-table_type)string

Enum: `MANAGED | EXTERNAL | VIEW | MATERIALIZED_VIEW | STREAMING_TABLE | MANAGED_SHALLOW_CLONE | FOREIGN | EXTERNAL_SHALLOW_CLONE | METRIC_VIEW`

[`updated_at`](https://docs.databricks.com/api/workspace/tables/list#tables-updated_at)int64

Time at which this table was last modified, in epoch milliseconds.

[`updated_by`](https://docs.databricks.com/api/workspace/tables/list#tables-updated_by)string

Username of user who last modified the table.

[`view_definition`](https://docs.databricks.com/api/workspace/tables/list#tables-view_definition)string

View definition SQL (when table_type is VIEW, MATERIALIZED_VIEW, or STREAMING_TABLE)

[`view_dependencies`](https://docs.databricks.com/api/workspace/tables/list#tables-view_dependencies)object

View dependencies (when table_type == VIEW or MATERIALIZED_VIEW, STREAMING_TABLE)

*   when DependencyList is None, the dependency is not provided;
*   when DependencyList is an empty list, the dependency is provided but is empty;
*   when DependencyList is not an empty list, dependencies are provided and recorded. Note: this field is not set in the output of the listTables API.

 ]

# Response samples

200

{ "next_page_token": "string", "tables": [ { "access_point": "string", "browse_only": true, "catalog_name": "string", "columns": [ { "comment": "string", "mask": { "function_name": "string", "using_arguments": [ { "column": "string", "constant": "string" } ], "using_column_names": [ "string" ] }, "name": "string", "nullable": true, "partition_index": 0, "position": 0, "type_interval_type": "string", "type_json": "string", "type_name": "BOOLEAN", "type_precision": 0, "type_scale": 0, "type_text": "string" } ], "comment": "string", "created_at": 0, "created_by": "string", "data_access_configuration_id": "string", "data_source_format": "DELTA", "deleted_at": 0, "delta_runtime_properties_kvpairs": { "delta_runtime_properties": { "property1": "string", "property2": "string" } }, "effective_predictive_optimization_flag": { "inherited_from_name": "string", "inherited_from_type": "CATALOG", "value": "DISABLE" }, "enable_predictive_optimization": "DISABLE", "full_name": "string", "metastore_id": "string", "name": "string", "owner": "string", "pipeline_id": "string", "properties": { "property1": "string", "property2": "string" }, "row_filter": { "function_name": "string", "input_arguments": [ { "column": "string", "constant": "string" } ], "input_column_names": [ "string" ] }, "schema_name": "string", "securable_kind_manifest": { "assignable_privileges": [ "string" ], "capabilities": [ "string" ], "options": [ { "allowed_values": [ "string" ], "default_value": "string", "description": "string", "hint": "string", "is_copiable": true, "is_creatable": true, "is_hidden": true, "is_loggable": true, "is_required": true, "is_secret": true, "is_updatable": true, "name": "string", "oauth_stage": "BEFORE_AUTHORIZATION_CODE", "type": "OPTION_BOOLEAN" } ], "securable_kind": "TABLE_STANDARD", "securable_type": "CATALOG" }, "sql_path": "string", "storage_credential_name": "string", "storage_location": "string", "table_constraints": [ { "foreign_key_constraint": { "child_columns": [ "string" ], "name": "string", "parent_columns": [ "string" ], "parent_table": "string", "rely": true }, "named_table_constraint": { "name": "string" }, "primary_key_constraint": { "child_columns": [ "string" ], "name": "string", "rely": true, "timeseries_columns": [ "string" ] } } ], "table_id": "string", "table_type": "MANAGED", "updated_at": 0, "updated_by": "string", "view_definition": "string", "view_dependencies": { "dependencies": [ { "connection": { "connection_name": "string" }, "credential": { "credential_name": "string" }, "function": { "function_full_name": "string" }, "table": { "table_full_name": "string" } } ] } } ] }
