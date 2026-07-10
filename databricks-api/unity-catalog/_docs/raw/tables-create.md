Title: Create a table | Tables API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/tables/create

Markdown Content:
## Create a table

Public preview

`POST/api/2.1/unity-catalog/tables`

Creates a new table in the specified catalog and schema.

To create an external delta table, the caller must have the EXTERNAL_USE_SCHEMA privilege on the parent schema and the EXTERNAL_USE_LOCATION privilege on the external location. These privileges must always be granted explicitly, and cannot be inherited through ownership or ALL_PRIVILEGES.

Standard UC permissions needed to create tables still apply: USE_CATALOG on the parent catalog (or ownership of the parent catalog), CREATE_TABLE and USE_SCHEMA on the parent schema (or ownership of the parent schema), and CREATE_EXTERNAL_TABLE on external location.

The columns field needs to be in a Spark compatible format, so we recommend you use Spark to create these tables. The API itself does not validate the correctness of the column spec. If the spec is not Spark compatible, the tables may not be readable by Databricks Runtime.

For additional details, see [here](https://docs.databricks.com/aws/en/external-access/create-external-tables).

NOTE: The Create Table API for external clients only supports creating external delta tables. The values shown in the respective enums are all values supported by Databricks, however for this specific Create Table API, only table_type EXTERNAL and data_source_format DELTA are supported. Additionally, column masks are not supported when creating tables through this API.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Request body

[`catalog_name`](https://docs.databricks.com/api/workspace/tables/create#catalog_name)required string

Name of parent catalog.

[`columns`](https://docs.databricks.com/api/workspace/tables/create#columns)Array of object

The array of ColumnInfo definitions of the table's columns.

Array [

[`comment`](https://docs.databricks.com/api/workspace/tables/create#columns-comment)string

User-provided free-form text description.

[`mask`](https://docs.databricks.com/api/workspace/tables/create#columns-mask)object

[`name`](https://docs.databricks.com/api/workspace/tables/create#columns-name)string

Name of Column.

[`nullable`](https://docs.databricks.com/api/workspace/tables/create#columns-nullable)boolean

Default`true`

Whether field may be Null (default: true).

[`partition_index`](https://docs.databricks.com/api/workspace/tables/create#columns-partition_index)int32

Partition index for column.

[`position`](https://docs.databricks.com/api/workspace/tables/create#columns-position)int32

Ordinal position of column (starting at position 0).

[`type_interval_type`](https://docs.databricks.com/api/workspace/tables/create#columns-type_interval_type)string

Format of IntervalType.

[`type_json`](https://docs.databricks.com/api/workspace/tables/create#columns-type_json)string

Full data type specification, JSON-serialized.

[`type_name`](https://docs.databricks.com/api/workspace/tables/create#columns-type_name)string

Enum: `BOOLEAN | BYTE | SHORT | INT | LONG | FLOAT | DOUBLE | DATE | TIMESTAMP | STRING | BINARY | DECIMAL | INTERVAL | ARRAY | STRUCT | MAP | CHAR | NULL | USER_DEFINED_TYPE | TIMESTAMP_NTZ | VARIANT | GEOMETRY | GEOGRAPHY | TABLE_TYPE`

[`type_precision`](https://docs.databricks.com/api/workspace/tables/create#columns-type_precision)int32

Digits of precision; required for DecimalTypes.

[`type_scale`](https://docs.databricks.com/api/workspace/tables/create#columns-type_scale)int32

Digits to right of decimal; Required for DecimalTypes.

[`type_text`](https://docs.databricks.com/api/workspace/tables/create#columns-type_text)string

Full data type specification as SQL/catalogString text.

 ]

[`data_source_format`](https://docs.databricks.com/api/workspace/tables/create#data_source_format)required string

Enum: `DELTA | CSV | JSON | AVRO | PARQUET | ORC | TEXT | UNITY_CATALOG | DELTASHARING | DATABRICKS_FORMAT | MYSQL_FORMAT | ORACLE_FORMAT | POSTGRESQL_FORMAT | REDSHIFT_FORMAT | SNOWFLAKE_FORMAT | SQLDW_FORMAT | SQLSERVER_FORMAT | SALESFORCE_FORMAT | SALESFORCE_DATA_CLOUD_FORMAT | TERADATA_FORMAT | BIGQUERY_FORMAT | NETSUITE_FORMAT | WORKDAY_RAAS_FORMAT | MONGODB_FORMAT | HIVE | VECTOR_INDEX_FORMAT | DATABRICKS_ROW_STORE_FORMAT | DELTA_UNIFORM_HUDI | DELTA_UNIFORM_ICEBERG | ICEBERG`

Data source format

[`name`](https://docs.databricks.com/api/workspace/tables/create#name)required string

Name of table, relative to parent schema.

[`properties`](https://docs.databricks.com/api/workspace/tables/create#properties)object

A map of key-value properties attached to the securable.

[`schema_name`](https://docs.databricks.com/api/workspace/tables/create#schema_name)required string

Name of parent schema relative to its parent catalog.

[`storage_location`](https://docs.databricks.com/api/workspace/tables/create#storage_location)required string

Storage root URL for table (for MANAGED, EXTERNAL tables).

[`table_type`](https://docs.databricks.com/api/workspace/tables/create#table_type)required string

Enum: `MANAGED | EXTERNAL | VIEW | MATERIALIZED_VIEW | STREAMING_TABLE | MANAGED_SHALLOW_CLONE | FOREIGN | EXTERNAL_SHALLOW_CLONE | METRIC_VIEW`

### Responses

**200** Request completed successfully.

Request completed successfully.

[`access_point`](https://docs.databricks.com/api/workspace/tables/create#access_point)string

The AWS access point to use when accesing s3 for this external location.

[`browse_only`](https://docs.databricks.com/api/workspace/tables/create#browse_only)boolean

Indicates whether the principal is limited to retrieving metadata for the associated object through the BROWSE privilege when include_browse is enabled in the request.

[`catalog_name`](https://docs.databricks.com/api/workspace/tables/create#catalog_name)string

Name of parent catalog.

[`columns`](https://docs.databricks.com/api/workspace/tables/create#columns)Array of object

The array of ColumnInfo definitions of the table's columns.

Array [

[`comment`](https://docs.databricks.com/api/workspace/tables/create#columns-comment)string

User-provided free-form text description.

[`mask`](https://docs.databricks.com/api/workspace/tables/create#columns-mask)object

[`name`](https://docs.databricks.com/api/workspace/tables/create#columns-name)string

Name of Column.

[`nullable`](https://docs.databricks.com/api/workspace/tables/create#columns-nullable)boolean

Default`true`

Whether field may be Null (default: true).

[`partition_index`](https://docs.databricks.com/api/workspace/tables/create#columns-partition_index)int32

Partition index for column.

[`position`](https://docs.databricks.com/api/workspace/tables/create#columns-position)int32

Ordinal position of column (starting at position 0).

[`type_interval_type`](https://docs.databricks.com/api/workspace/tables/create#columns-type_interval_type)string

Format of IntervalType.

[`type_json`](https://docs.databricks.com/api/workspace/tables/create#columns-type_json)string

Full data type specification, JSON-serialized.

[`type_name`](https://docs.databricks.com/api/workspace/tables/create#columns-type_name)string

Enum: `BOOLEAN | BYTE | SHORT | INT | LONG | FLOAT | DOUBLE | DATE | TIMESTAMP | STRING | BINARY | DECIMAL | INTERVAL | ARRAY | STRUCT | MAP | CHAR | NULL | USER_DEFINED_TYPE | TIMESTAMP_NTZ | VARIANT | GEOMETRY | GEOGRAPHY | TABLE_TYPE`

[`type_precision`](https://docs.databricks.com/api/workspace/tables/create#columns-type_precision)int32

Digits of precision; required for DecimalTypes.

[`type_scale`](https://docs.databricks.com/api/workspace/tables/create#columns-type_scale)int32

Digits to right of decimal; Required for DecimalTypes.

[`type_text`](https://docs.databricks.com/api/workspace/tables/create#columns-type_text)string

Full data type specification as SQL/catalogString text.

 ]

[`comment`](https://docs.databricks.com/api/workspace/tables/create#comment)string

User-provided free-form text description.

[`created_at`](https://docs.databricks.com/api/workspace/tables/create#created_at)int64

Time at which this table was created, in epoch milliseconds.

[`created_by`](https://docs.databricks.com/api/workspace/tables/create#created_by)string

Username of table creator.

[`data_access_configuration_id`](https://docs.databricks.com/api/workspace/tables/create#data_access_configuration_id)string

Deprecated

Unique ID of the Data Access Configuration to use with the table data.

[`data_source_format`](https://docs.databricks.com/api/workspace/tables/create#data_source_format)string

Enum: `DELTA | CSV | JSON | AVRO | PARQUET | ORC | TEXT | UNITY_CATALOG | DELTASHARING | DATABRICKS_FORMAT | MYSQL_FORMAT | ORACLE_FORMAT | POSTGRESQL_FORMAT | REDSHIFT_FORMAT | SNOWFLAKE_FORMAT | SQLDW_FORMAT | SQLSERVER_FORMAT | SALESFORCE_FORMAT | SALESFORCE_DATA_CLOUD_FORMAT | TERADATA_FORMAT | BIGQUERY_FORMAT | NETSUITE_FORMAT | WORKDAY_RAAS_FORMAT | MONGODB_FORMAT | HIVE | VECTOR_INDEX_FORMAT | DATABRICKS_ROW_STORE_FORMAT | DELTA_UNIFORM_HUDI | DELTA_UNIFORM_ICEBERG | ICEBERG`

Data source format

[`deleted_at`](https://docs.databricks.com/api/workspace/tables/create#deleted_at)int64

Time at which this table was deleted, in epoch milliseconds. Field is omitted if table is not deleted.

[`delta_runtime_properties_kvpairs`](https://docs.databricks.com/api/workspace/tables/create#delta_runtime_properties_kvpairs)object

Information pertaining to current state of the delta table.

[`delta_runtime_properties`](https://docs.databricks.com/api/workspace/tables/create#delta_runtime_properties_kvpairs-delta_runtime_properties)object

A map of key-value properties attached to the securable.

[`effective_predictive_optimization_flag`](https://docs.databricks.com/api/workspace/tables/create#effective_predictive_optimization_flag)object

[`inherited_from_name`](https://docs.databricks.com/api/workspace/tables/create#effective_predictive_optimization_flag-inherited_from_name)string

The name of the object from which the flag was inherited. If there was no inheritance, this field is left blank.

[`inherited_from_type`](https://docs.databricks.com/api/workspace/tables/create#effective_predictive_optimization_flag-inherited_from_type)string

Enum: `CATALOG | SCHEMA`

The type of the object from which the flag was inherited. If there was no inheritance, this field is left blank.

[`value`](https://docs.databricks.com/api/workspace/tables/create#effective_predictive_optimization_flag-value)string

Enum: `DISABLE | ENABLE | INHERIT`

Whether predictive optimization should be enabled for this object and objects under it.

[`enable_predictive_optimization`](https://docs.databricks.com/api/workspace/tables/create#enable_predictive_optimization)string

Enum: `DISABLE | ENABLE | INHERIT`

[`full_name`](https://docs.databricks.com/api/workspace/tables/create#full_name)string

Full name of table, in form of catalog_name.schema_name.table_name

[`metastore_id`](https://docs.databricks.com/api/workspace/tables/create#metastore_id)string

Unique identifier of parent metastore.

[`name`](https://docs.databricks.com/api/workspace/tables/create#name)string

Name of table, relative to parent schema.

[`owner`](https://docs.databricks.com/api/workspace/tables/create#owner)string

Username of current owner of table.

[`pipeline_id`](https://docs.databricks.com/api/workspace/tables/create#pipeline_id)string

The pipeline ID of the table. Applicable for tables created by pipelines (Materialized View, Streaming Table, etc.).

[`properties`](https://docs.databricks.com/api/workspace/tables/create#properties)object

A map of key-value properties attached to the securable.

[`row_filter`](https://docs.databricks.com/api/workspace/tables/create#row_filter)object

[`function_name`](https://docs.databricks.com/api/workspace/tables/create#row_filter-function_name)string

The full name of the row filter SQL UDF.

[`input_arguments`](https://docs.databricks.com/api/workspace/tables/create#row_filter-input_arguments)Array of object

The list of additional table columns or literals to be passed as additional arguments to a row filter function. This is the replacement of the deprecated input_column_names field and carries information about the types (alias or constant) of the arguments to the filter function.

[`input_column_names`](https://docs.databricks.com/api/workspace/tables/create#row_filter-input_column_names)Array of string

Deprecated

The list of table columns to be passed as input to the row filter function. The column types should match the types of the filter function arguments.

[`schema_name`](https://docs.databricks.com/api/workspace/tables/create#schema_name)string

Name of parent schema relative to its parent catalog.

[`securable_kind_manifest`](https://docs.databricks.com/api/workspace/tables/create#securable_kind_manifest)object

SecurableKindManifest of table, including capabilities the table has.

[`assignable_privileges`](https://docs.databricks.com/api/workspace/tables/create#securable_kind_manifest-assignable_privileges)Array of string

Privileges that can be assigned to the securable.

[`capabilities`](https://docs.databricks.com/api/workspace/tables/create#securable_kind_manifest-capabilities)Array of string

A list of capabilities in the securable kind.

[`options`](https://docs.databricks.com/api/workspace/tables/create#securable_kind_manifest-options)Array of object

Detailed specs of allowed options.

[`securable_kind`](https://docs.databricks.com/api/workspace/tables/create#securable_kind_manifest-securable_kind)string

Enum: `TABLE_STANDARD | TABLE_EXTERNAL | TABLE_DELTA | TABLE_DELTA_EXTERNAL | TABLE_VIEW | TABLE_METRIC_VIEW | TABLE_DELTASHARING | TABLE_DELTASHARING_MUTABLE | TABLE_VIEW_DELTASHARING | TABLE_METRIC_VIEW_DELTASHARING | TABLE_MATERIALIZED_VIEW_DELTASHARING | TABLE_STREAMING_LIVE_TABLE_DELTASHARING | TABLE_FOREIGN_DELTASHARING | TABLE_DELTA_ICEBERG_DELTASHARING | TABLE_DELTASHARING_OPEN_DIR_BASED | TABLE_FEATURE_STORE | TABLE_FEATURE_STORE_EXTERNAL | TABLE_STREAMING_LIVE_TABLE | TABLE_SYSTEM | TABLE_SYSTEM_DELTASHARING | TABLE_MATERIALIZED_VIEW | TABLE_INTERNAL | TABLE_FOREIGN_BIGQUERY | TABLE_FOREIGN_MYSQL | TABLE_FOREIGN_ORACLE | TABLE_FOREIGN_POSTGRESQL | TABLE_FOREIGN_SQLDW | TABLE_FOREIGN_REDSHIFT | TABLE_FOREIGN_SNOWFLAKE | TABLE_FOREIGN_SQLSERVER | TABLE_FOREIGN_SALESFORCE | TABLE_FOREIGN_SALESFORCE_DATA_CLOUD | TABLE_FOREIGN_SALESFORCE_DATA_CLOUD_FILE_SHARING | TABLE_FOREIGN_SALESFORCE_DATA_CLOUD_FILE_SHARING_VIEW | TABLE_FOREIGN_TERADATA | TABLE_FOREIGN_NETSUITE | TABLE_FOREIGN_DATABRICKS | TABLE_FOREIGN_WORKDAY_RAAS | TABLE_FOREIGN_HIVE_METASTORE | TABLE_FOREIGN_HIVE_METASTORE_MANAGED | TABLE_FOREIGN_HIVE_METASTORE_DBFS_MANAGED | TABLE_FOREIGN_HIVE_METASTORE_EXTERNAL | TABLE_FOREIGN_HIVE_METASTORE_DBFS_EXTERNAL | TABLE_FOREIGN_HIVE_METASTORE_VIEW | TABLE_FOREIGN_HIVE_METASTORE_DBFS_VIEW | TABLE_FOREIGN_HIVE_METASTORE_SHALLOW_CLONE_MANAGED | TABLE_FOREIGN_HIVE_METASTORE_DBFS_SHALLOW_CLONE_MANAGED | TABLE_FOREIGN_HIVE_METASTORE_SHALLOW_CLONE_EXTERNAL | TABLE_FOREIGN_HIVE_METASTORE_DBFS_SHALLOW_CLONE_EXTERNAL | TABLE_FOREIGN_MONGODB | TABLE_DELTA_UNIFORM_HUDI_EXTERNAL | TABLE_DELTA_UNIFORM_ICEBERG_EXTERNAL | TABLE_DELTA_UNIFORM_ICEBERG_FOREIGN_HIVE_METASTORE_EXTERNAL | TABLE_DELTA_UNIFORM_ICEBERG_FOREIGN_HIVE_METASTORE_MANAGED | TABLE_DELTA_UNIFORM_ICEBERG_FOREIGN_SNOWFLAKE | TABLE_DELTA_UNIFORM_ICEBERG_FOREIGN_DELTASHARING | TABLE_DELTA_UNIFORM_ICEBERG_EXTERNAL_DELTASHARING | TABLE_ICEBERG_UNIFORM_MANAGED | TABLE_DELTA_ICEBERG_MANAGED | TABLE_ONLINE_VECTOR_INDEX_REPLICA | TABLE_ONLINE_VECTOR_INDEX_DIRECT | TABLE_ONLINE_VIEW | TABLE_DB_STORAGE | TABLE_MANAGED_POSTGRESQL`

Securable kind to get manifest of.

[`securable_type`](https://docs.databricks.com/api/workspace/tables/create#securable_kind_manifest-securable_type)string

Enum: `CATALOG | SCHEMA | TABLE | STORAGE_CREDENTIAL | EXTERNAL_LOCATION | FUNCTION | SHARE | PROVIDER | RECIPIENT | CLEAN_ROOM | METASTORE | PIPELINE | VOLUME | CONNECTION | CREDENTIAL | EXTERNAL_METADATA | STAGING_TABLE`

Securable Type of the kind.

[`sql_path`](https://docs.databricks.com/api/workspace/tables/create#sql_path)string

List of schemes whose objects can be referenced without qualification.

[`storage_credential_name`](https://docs.databricks.com/api/workspace/tables/create#storage_credential_name)string

Name of the storage credential, when a storage credential is configured for use with this table.

[`storage_location`](https://docs.databricks.com/api/workspace/tables/create#storage_location)string

Storage root URL for table (for MANAGED, EXTERNAL tables).

[`table_constraints`](https://docs.databricks.com/api/workspace/tables/create#table_constraints)Array of object

List of table constraints. Note: this field is not set in the output of the listTables API.

Array [

[`foreign_key_constraint`](https://docs.databricks.com/api/workspace/tables/create#table_constraints-foreign_key_constraint)object

[`named_table_constraint`](https://docs.databricks.com/api/workspace/tables/create#table_constraints-named_table_constraint)object

[`primary_key_constraint`](https://docs.databricks.com/api/workspace/tables/create#table_constraints-primary_key_constraint)object

 ]

[`table_id`](https://docs.databricks.com/api/workspace/tables/create#table_id)string

The unique identifier of the table.

[`table_type`](https://docs.databricks.com/api/workspace/tables/create#table_type)string

Enum: `MANAGED | EXTERNAL | VIEW | MATERIALIZED_VIEW | STREAMING_TABLE | MANAGED_SHALLOW_CLONE | FOREIGN | EXTERNAL_SHALLOW_CLONE | METRIC_VIEW`

[`updated_at`](https://docs.databricks.com/api/workspace/tables/create#updated_at)int64

Time at which this table was last modified, in epoch milliseconds.

[`updated_by`](https://docs.databricks.com/api/workspace/tables/create#updated_by)string

Username of user who last modified the table.

[`view_definition`](https://docs.databricks.com/api/workspace/tables/create#view_definition)string

View definition SQL (when table_type is VIEW, MATERIALIZED_VIEW, or STREAMING_TABLE)

[`view_dependencies`](https://docs.databricks.com/api/workspace/tables/create#view_dependencies)object

View dependencies (when table_type == VIEW or MATERIALIZED_VIEW, STREAMING_TABLE)

*   when DependencyList is None, the dependency is not provided;
*   when DependencyList is an empty list, the dependency is provided but is empty;
*   when DependencyList is not an empty list, dependencies are provided and recorded. Note: this field is not set in the output of the listTables API.

[`dependencies`](https://docs.databricks.com/api/workspace/tables/create#view_dependencies-dependencies)Array of object

Array of dependencies.

# Request samples

JSON

{

"catalog_name":"string",

"columns":[

{

"comment":"string",

"mask":{

"function_name":"string",

"using_arguments":[

{

"column":"string",

"constant":"string"

}

],

"using_column_names":[

"string"

]

},

"name":"string",

"nullable":true,

"partition_index":0,

"position":0,

"type_interval_type":"string",

"type_json":"string",

"type_name":"BOOLEAN",

"type_precision":0,

"type_scale":0,

"type_text":"string"

}

],

"data_source_format":"DELTA",

"name":"string",

"properties":{

"property1":"string",

"property2":"string"

},

"schema_name":"string",

"storage_location":"string",

"table_type":"MANAGED"

}

# Response samples

200

{

"access_point":"string",

"browse_only":true,

"catalog_name":"string",

"columns":[

{

"comment":"string",

"mask":{

"function_name":"string",

"using_arguments":[

{

"column":"string",

"constant":"string"

}

],

"using_column_names":[

"string"

]

},

"name":"string",

"nullable":true,

"partition_index":0,

"position":0,

"type_interval_type":"string",

"type_json":"string",

"type_name":"BOOLEAN",

"type_precision":0,

"type_scale":0,

"type_text":"string"

}

],

"comment":"string",

"created_at":0,

"created_by":"string",

"data_access_configuration_id":"string",

"data_source_format":"DELTA",

"deleted_at":0,

"delta_runtime_properties_kvpairs":{

"delta_runtime_properties":{

"property1":"string",

"property2":"string"

}

},

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

"pipeline_id":"string",

"properties":{

"property1":"string",

"property2":"string"

},

"row_filter":{

"function_name":"string",

"input_arguments":[

{

"column":"string",

"constant":"string"

}

],

"input_column_names":[

"string"

]

},

"schema_name":"string",

"securable_kind_manifest":{

"assignable_privileges":[

"string"

],

"capabilities":[

"string"

],

"options":[

{

"allowed_values":[

"string"

],

"default_value":"string",

"description":"string",

"hint":"string",

"is_copiable":true,

"is_creatable":true,

"is_hidden":true,

"is_loggable":true,

"is_required":true,

"is_secret":true,

"is_updatable":true,

"name":"string",

"oauth_stage":"BEFORE_AUTHORIZATION_CODE",

"type":"OPTION_BOOLEAN"

}

],

"securable_kind":"TABLE_STANDARD",

"securable_type":"CATALOG"

},

"sql_path":"string",

"storage_credential_name":"string",

"storage_location":"string",

"table_constraints":[

{

"foreign_key_constraint":{

"child_columns":[

"string"

],

"name":"string",

"parent_columns":[

"string"

],

"parent_table":"string",

"rely":true

},

"named_table_constraint":{

"name":"string"

},

"primary_key_constraint":{

"child_columns":[

"string"

],

"name":"string",

"rely":true,

"timeseries_columns":[

"string"

]

}

}

],

"table_id":"string",

"table_type":"MANAGED",

"updated_at":0,

"updated_by":"string",

"view_definition":"string",

"view_dependencies":{

"dependencies":[

{

"connection":{

"connection_name":"string"

},

"credential":{

"credential_name":"string"

},

"function":{

"function_full_name":"string"

},

"table":{

"table_full_name":"string"

}

}

]

}

}
