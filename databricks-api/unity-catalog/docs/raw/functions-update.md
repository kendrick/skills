Title: Update a function | Functions API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/functions/update

Markdown Content:
## Update a function

`PATCH/api/2.1/unity-catalog/functions/{name}`

Updates the function that matches the supplied name. Only the owner of the function can be updated. If the user is not a metastore admin, the user must be a member of the group that is the new function owner.

*   Is a metastore admin
*   Is the owner of the function's parent catalog
*   Is the owner of the function's parent schema and has the USE_CATALOG privilege on its parent catalog
*   Is the owner of the function itself and has the USE_CATALOG privilege on its parent catalog as well as the USE_SCHEMA privilege on the function's parent schema.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`name`](https://docs.databricks.com/api/workspace/functions/update#name)required string

The fully-qualified name of the function (of the form catalog_name.schema_name.function__name).

### Request body

[`owner`](https://docs.databricks.com/api/workspace/functions/update#owner)string

Username of current owner of the function.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`browse_only`](https://docs.databricks.com/api/workspace/functions/update#browse_only)boolean

Indicates whether the principal is limited to retrieving metadata for the associated object through the BROWSE privilege when include_browse is enabled in the request.

[`catalog_name`](https://docs.databricks.com/api/workspace/functions/update#catalog_name)string

Name of parent Catalog.

[`comment`](https://docs.databricks.com/api/workspace/functions/update#comment)string

User-provided free-form text description.

[`created_at`](https://docs.databricks.com/api/workspace/functions/update#created_at)int64

Time at which this function was created, in epoch milliseconds.

[`created_by`](https://docs.databricks.com/api/workspace/functions/update#created_by)string

Username of function creator.

[`data_type`](https://docs.databricks.com/api/workspace/functions/update#data_type)string

Enum: `BOOLEAN | BYTE | SHORT | INT | LONG | FLOAT | DOUBLE | DATE | TIMESTAMP | STRING | BINARY | DECIMAL | INTERVAL | ARRAY | STRUCT | MAP | CHAR | NULL | USER_DEFINED_TYPE | TIMESTAMP_NTZ | VARIANT | GEOMETRY | GEOGRAPHY | TABLE_TYPE`

Scalar function return data type.

[`external_language`](https://docs.databricks.com/api/workspace/functions/update#external_language)string

External function language.

[`external_name`](https://docs.databricks.com/api/workspace/functions/update#external_name)string

External function name.

[`full_data_type`](https://docs.databricks.com/api/workspace/functions/update#full_data_type)string

Pretty printed function data type.

[`full_name`](https://docs.databricks.com/api/workspace/functions/update#full_name)string

Full name of Function, in form of catalog_name.schema_name.function_name

[`function_id`](https://docs.databricks.com/api/workspace/functions/update#function_id)string

Id of Function, relative to parent schema.

[`input_params`](https://docs.databricks.com/api/workspace/functions/update#input_params)object

Function input parameters.

[`parameters`](https://docs.databricks.com/api/workspace/functions/update#input_params-parameters)Array of object

[`is_deterministic`](https://docs.databricks.com/api/workspace/functions/update#is_deterministic)boolean

Whether the function is deterministic.

[`is_null_call`](https://docs.databricks.com/api/workspace/functions/update#is_null_call)boolean

Function null call.

[`metastore_id`](https://docs.databricks.com/api/workspace/functions/update#metastore_id)string

Unique identifier of parent metastore.

[`name`](https://docs.databricks.com/api/workspace/functions/update#name)string

Name of function, relative to parent schema.

[`owner`](https://docs.databricks.com/api/workspace/functions/update#owner)string

Username of current owner of the function.

[`parameter_style`](https://docs.databricks.com/api/workspace/functions/update#parameter_style)string

Enum: `S`

Function parameter style. S is the value for SQL.

[`properties`](https://docs.databricks.com/api/workspace/functions/update#properties)string

JSON-serialized key-value pair map, encoded (escaped) as a string.

[`return_params`](https://docs.databricks.com/api/workspace/functions/update#return_params)object

Table function return parameters.

[`parameters`](https://docs.databricks.com/api/workspace/functions/update#return_params-parameters)Array of object

[`routine_body`](https://docs.databricks.com/api/workspace/functions/update#routine_body)string

Enum: `SQL | EXTERNAL`

Function language. When EXTERNAL is used, the language of the routine function should be specified in the external_language field, and the return_params of the function cannot be used (as TABLE return type is not supported), and the sql_data_access field must be NO_SQL.

[`routine_definition`](https://docs.databricks.com/api/workspace/functions/update#routine_definition)string

Function body.

[`routine_dependencies`](https://docs.databricks.com/api/workspace/functions/update#routine_dependencies)object

function dependencies.

[`dependencies`](https://docs.databricks.com/api/workspace/functions/update#routine_dependencies-dependencies)Array of object

Array of dependencies.

[`schema_name`](https://docs.databricks.com/api/workspace/functions/update#schema_name)string

Name of parent Schema relative to its parent Catalog.

[`security_type`](https://docs.databricks.com/api/workspace/functions/update#security_type)string

Enum: `DEFINER`

Function security type.

[`specific_name`](https://docs.databricks.com/api/workspace/functions/update#specific_name)string

Specific name of the function; Reserved for future use.

[`sql_data_access`](https://docs.databricks.com/api/workspace/functions/update#sql_data_access)string

Enum: `CONTAINS_SQL | READS_SQL_DATA | NO_SQL`

Function SQL data access.

[`sql_path`](https://docs.databricks.com/api/workspace/functions/update#sql_path)string

List of schemes whose objects can be referenced without qualification.

[`updated_at`](https://docs.databricks.com/api/workspace/functions/update#updated_at)int64

Time at which this function was last modified, in epoch milliseconds.

[`updated_by`](https://docs.databricks.com/api/workspace/functions/update#updated_by)string

Username of user who last modified the function.

# Request samples

JSON

{

"owner":"string"

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
