Title: Create a function | Functions API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/functions/create

Markdown Content:
## Create a function

`POST/api/2.1/unity-catalog/functions`

WARNING: This API is experimental and will change in future versions

Creates a new function

The user must have the following permissions in order for the function to be created:

*   USE_CATALOG on the function's parent catalog
*   USE_SCHEMA and CREATE_FUNCTION on the function's parent schema

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Request body

[`function_info`](https://docs.databricks.com/api/workspace/functions/create#function_info)object

Partial FunctionInfo specifying the function to be created.

[`catalog_name`](https://docs.databricks.com/api/workspace/functions/create#function_info-catalog_name)required string

Name of parent Catalog.

[`comment`](https://docs.databricks.com/api/workspace/functions/create#function_info-comment)string

User-provided free-form text description.

[`data_type`](https://docs.databricks.com/api/workspace/functions/create#function_info-data_type)required string

Enum: `BOOLEAN | BYTE | SHORT | INT | LONG | FLOAT | DOUBLE | DATE | TIMESTAMP | STRING | BINARY | DECIMAL | INTERVAL | ARRAY | STRUCT | MAP | CHAR | NULL | USER_DEFINED_TYPE | TIMESTAMP_NTZ | VARIANT | GEOMETRY | GEOGRAPHY | TABLE_TYPE`

Scalar function return data type.

[`external_language`](https://docs.databricks.com/api/workspace/functions/create#function_info-external_language)string

External function language.

[`external_name`](https://docs.databricks.com/api/workspace/functions/create#function_info-external_name)string

External function name.

[`full_data_type`](https://docs.databricks.com/api/workspace/functions/create#function_info-full_data_type)required string

Pretty printed function data type.

[`input_params`](https://docs.databricks.com/api/workspace/functions/create#function_info-input_params)required object

Function input parameters.

[`is_deterministic`](https://docs.databricks.com/api/workspace/functions/create#function_info-is_deterministic)required boolean

Whether the function is deterministic.

[`is_null_call`](https://docs.databricks.com/api/workspace/functions/create#function_info-is_null_call)required boolean

Function null call.

[`name`](https://docs.databricks.com/api/workspace/functions/create#function_info-name)required string

Name of function, relative to parent schema.

[`parameter_style`](https://docs.databricks.com/api/workspace/functions/create#function_info-parameter_style)required string

Enum: `S`

Function parameter style. S is the value for SQL.

[`properties`](https://docs.databricks.com/api/workspace/functions/create#function_info-properties)string

JSON-serialized key-value pair map, encoded (escaped) as a string.

[`return_params`](https://docs.databricks.com/api/workspace/functions/create#function_info-return_params)object

Table function return parameters.

[`routine_body`](https://docs.databricks.com/api/workspace/functions/create#function_info-routine_body)required string

Enum: `SQL | EXTERNAL`

Function language. When EXTERNAL is used, the language of the routine function should be specified in the external_language field, and the return_params of the function cannot be used (as TABLE return type is not supported), and the sql_data_access field must be NO_SQL.

[`routine_definition`](https://docs.databricks.com/api/workspace/functions/create#function_info-routine_definition)required string

Function body.

[`routine_dependencies`](https://docs.databricks.com/api/workspace/functions/create#function_info-routine_dependencies)object

function dependencies.

[`schema_name`](https://docs.databricks.com/api/workspace/functions/create#function_info-schema_name)required string

Name of parent Schema relative to its parent Catalog.

[`security_type`](https://docs.databricks.com/api/workspace/functions/create#function_info-security_type)required string

Enum: `DEFINER`

Function security type.

[`specific_name`](https://docs.databricks.com/api/workspace/functions/create#function_info-specific_name)required string

Specific name of the function; Reserved for future use.

[`sql_data_access`](https://docs.databricks.com/api/workspace/functions/create#function_info-sql_data_access)required string

Enum: `CONTAINS_SQL | READS_SQL_DATA | NO_SQL`

Function SQL data access.

[`sql_path`](https://docs.databricks.com/api/workspace/functions/create#function_info-sql_path)string

List of schemes whose objects can be referenced without qualification.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`browse_only`](https://docs.databricks.com/api/workspace/functions/create#browse_only)boolean

Indicates whether the principal is limited to retrieving metadata for the associated object through the BROWSE privilege when include_browse is enabled in the request.

[`catalog_name`](https://docs.databricks.com/api/workspace/functions/create#catalog_name)string

Name of parent Catalog.

[`comment`](https://docs.databricks.com/api/workspace/functions/create#comment)string

User-provided free-form text description.

[`created_at`](https://docs.databricks.com/api/workspace/functions/create#created_at)int64

Time at which this function was created, in epoch milliseconds.

[`created_by`](https://docs.databricks.com/api/workspace/functions/create#created_by)string

Username of function creator.

[`data_type`](https://docs.databricks.com/api/workspace/functions/create#data_type)string

Enum: `BOOLEAN | BYTE | SHORT | INT | LONG | FLOAT | DOUBLE | DATE | TIMESTAMP | STRING | BINARY | DECIMAL | INTERVAL | ARRAY | STRUCT | MAP | CHAR | NULL | USER_DEFINED_TYPE | TIMESTAMP_NTZ | VARIANT | GEOMETRY | GEOGRAPHY | TABLE_TYPE`

Scalar function return data type.

[`external_language`](https://docs.databricks.com/api/workspace/functions/create#external_language)string

External function language.

[`external_name`](https://docs.databricks.com/api/workspace/functions/create#external_name)string

External function name.

[`full_data_type`](https://docs.databricks.com/api/workspace/functions/create#full_data_type)string

Pretty printed function data type.

[`full_name`](https://docs.databricks.com/api/workspace/functions/create#full_name)string

Full name of Function, in form of catalog_name.schema_name.function_name

[`function_id`](https://docs.databricks.com/api/workspace/functions/create#function_id)string

Id of Function, relative to parent schema.

[`input_params`](https://docs.databricks.com/api/workspace/functions/create#input_params)object

Function input parameters.

[`parameters`](https://docs.databricks.com/api/workspace/functions/create#input_params-parameters)Array of object

[`is_deterministic`](https://docs.databricks.com/api/workspace/functions/create#is_deterministic)boolean

Whether the function is deterministic.

[`is_null_call`](https://docs.databricks.com/api/workspace/functions/create#is_null_call)boolean

Function null call.

[`metastore_id`](https://docs.databricks.com/api/workspace/functions/create#metastore_id)string

Unique identifier of parent metastore.

[`name`](https://docs.databricks.com/api/workspace/functions/create#name)string

Name of function, relative to parent schema.

[`owner`](https://docs.databricks.com/api/workspace/functions/create#owner)string

Username of current owner of the function.

[`parameter_style`](https://docs.databricks.com/api/workspace/functions/create#parameter_style)string

Enum: `S`

Function parameter style. S is the value for SQL.

[`properties`](https://docs.databricks.com/api/workspace/functions/create#properties)string

JSON-serialized key-value pair map, encoded (escaped) as a string.

[`return_params`](https://docs.databricks.com/api/workspace/functions/create#return_params)object

Table function return parameters.

[`parameters`](https://docs.databricks.com/api/workspace/functions/create#return_params-parameters)Array of object

[`routine_body`](https://docs.databricks.com/api/workspace/functions/create#routine_body)string

Enum: `SQL | EXTERNAL`

Function language. When EXTERNAL is used, the language of the routine function should be specified in the external_language field, and the return_params of the function cannot be used (as TABLE return type is not supported), and the sql_data_access field must be NO_SQL.

[`routine_definition`](https://docs.databricks.com/api/workspace/functions/create#routine_definition)string

Function body.

[`routine_dependencies`](https://docs.databricks.com/api/workspace/functions/create#routine_dependencies)object

function dependencies.

[`dependencies`](https://docs.databricks.com/api/workspace/functions/create#routine_dependencies-dependencies)Array of object

Array of dependencies.

[`schema_name`](https://docs.databricks.com/api/workspace/functions/create#schema_name)string

Name of parent Schema relative to its parent Catalog.

[`security_type`](https://docs.databricks.com/api/workspace/functions/create#security_type)string

Enum: `DEFINER`

Function security type.

[`specific_name`](https://docs.databricks.com/api/workspace/functions/create#specific_name)string

Specific name of the function; Reserved for future use.

[`sql_data_access`](https://docs.databricks.com/api/workspace/functions/create#sql_data_access)string

Enum: `CONTAINS_SQL | READS_SQL_DATA | NO_SQL`

Function SQL data access.

[`sql_path`](https://docs.databricks.com/api/workspace/functions/create#sql_path)string

List of schemes whose objects can be referenced without qualification.

[`updated_at`](https://docs.databricks.com/api/workspace/functions/create#updated_at)int64

Time at which this function was last modified, in epoch milliseconds.

[`updated_by`](https://docs.databricks.com/api/workspace/functions/create#updated_by)string

Username of user who last modified the function.

# Request samples

JSON

{

"function_info":{

"catalog_name":"string",

"comment":"string",

"data_type":"BOOLEAN",

"external_language":"string",

"external_name":"string",

"full_data_type":"string",

"input_params":{

"parameters":[

{

"comment":"string",

"name":"string",

"parameter_default":"string",

"parameter_mode":"IN",

"parameter_type":"PARAM",

"position":0,

"type_interval_type":"string",

"type_json":"string",

"type_name":"BOOLEAN",

"type_precision":0,

"type_scale":0,

"type_text":"string"

}

]

},

"is_deterministic":true,

"is_null_call":true,

"name":"string",

"parameter_style":"S",

"properties":"string",

"return_params":{

"parameters":[

{

"comment":"string",

"name":"string",

"parameter_default":"string",

"parameter_mode":"IN",

"parameter_type":"PARAM",

"position":0,

"type_interval_type":"string",

"type_json":"string",

"type_name":"BOOLEAN",

"type_precision":0,

"type_scale":0,

"type_text":"string"

}

]

},

"routine_body":"SQL",

"routine_definition":"string",

"routine_dependencies":{

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

},

"schema_name":"string",

"security_type":"DEFINER",

"specific_name":"string",

"sql_data_access":"CONTAINS_SQL",

"sql_path":"string"

}

}

# Response samples

200

{

"browse_only":true,

"catalog_name":"string",

"comment":"string",

"created_at":0,

"created_by":"string",

"data_type":"BOOLEAN",

"external_language":"string",

"external_name":"string",

"full_data_type":"string",

"full_name":"string",

"function_id":"string",

"input_params":{

"parameters":[

{

"comment":"string",

"name":"string",

"parameter_default":"string",

"parameter_mode":"IN",

"parameter_type":"PARAM",

"position":0,

"type_interval_type":"string",

"type_json":"string",

"type_name":"BOOLEAN",

"type_precision":0,

"type_scale":0,

"type_text":"string"

}

]

},

"is_deterministic":true,

"is_null_call":true,

"metastore_id":"string",

"name":"string",

"owner":"string",

"parameter_style":"S",

"properties":"string",

"return_params":{

"parameters":[

{

"comment":"string",

"name":"string",

"parameter_default":"string",

"parameter_mode":"IN",

"parameter_type":"PARAM",

"position":0,

"type_interval_type":"string",

"type_json":"string",

"type_name":"BOOLEAN",

"type_precision":0,

"type_scale":0,

"type_text":"string"

}

]

},

"routine_body":"SQL",

"routine_definition":"string",

"routine_dependencies":{

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

},

"schema_name":"string",

"security_type":"DEFINER",

"specific_name":"string",

"sql_data_access":"CONTAINS_SQL",

"sql_path":"string",

"updated_at":0,

"updated_by":"string"

}
