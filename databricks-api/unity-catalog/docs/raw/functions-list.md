Title: List functions | Functions API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/functions/list

Markdown Content:
## List functions

`GET/api/2.1/unity-catalog/functions`

List functions within the specified parent catalog and schema. If the user is a metastore admin, all functions are returned in the output list. Otherwise, the user must have the USE_CATALOG privilege on the catalog and the USE_SCHEMA privilege on the schema, and the output list contains only functions for which either the user has the EXECUTE privilege or the user is the owner. There is no guarantee of a specific ordering of the elements in the array.

NOTE: we recommend using max_results=0 to use the paginated version of this API. Unpaginated calls will be deprecated soon.

PAGINATION BEHAVIOR: When using pagination (max_results >= 0), a page may contain zero results while still providing a next_page_token. Clients must continue reading pages until next_page_token is absent, which is the only indication that the end of results has been reached.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Query parameters

[`catalog_name`](https://docs.databricks.com/api/workspace/functions/list#catalog_name)required string

Name of parent catalog for functions of interest.

[`schema_name`](https://docs.databricks.com/api/workspace/functions/list#schema_name)required string

Parent schema of functions.

[`include_browse`](https://docs.databricks.com/api/workspace/functions/list#include_browse)boolean

Whether to include functions in the response for which the principal can only access selective metadata for

[`max_results`](https://docs.databricks.com/api/workspace/functions/list#max_results)int32

<= 1000 

Maximum number of functions to return. If not set, all the functions are returned (not recommended).

*   when set to a value greater than 0, the page length is the minimum of this value and a server configured value;
*   when set to 0, the page length is set to a server configured value (recommended);
*   when set to a value less than 0, an invalid parameter error is returned;

[`page_token`](https://docs.databricks.com/api/workspace/functions/list#page_token)string

Opaque pagination token to go to next page based on previous query.

### Responses

**200** Request completed successfully. The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

Request completed successfully.

 The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

[`functions`](https://docs.databricks.com/api/workspace/functions/list#functions)Array of object

An array of function information objects.

Array [

[`browse_only`](https://docs.databricks.com/api/workspace/functions/list#functions-browse_only)boolean

Indicates whether the principal is limited to retrieving metadata for the associated object through the BROWSE privilege when include_browse is enabled in the request.

[`catalog_name`](https://docs.databricks.com/api/workspace/functions/list#functions-catalog_name)string

Name of parent Catalog.

[`comment`](https://docs.databricks.com/api/workspace/functions/list#functions-comment)string

User-provided free-form text description.

[`created_at`](https://docs.databricks.com/api/workspace/functions/list#functions-created_at)int64

Time at which this function was created, in epoch milliseconds.

[`created_by`](https://docs.databricks.com/api/workspace/functions/list#functions-created_by)string

Username of function creator.

[`data_type`](https://docs.databricks.com/api/workspace/functions/list#functions-data_type)string

Enum: `BOOLEAN | BYTE | SHORT | INT | LONG | FLOAT | DOUBLE | DATE | TIMESTAMP | STRING | BINARY | DECIMAL | INTERVAL | ARRAY | STRUCT | MAP | CHAR | NULL | USER_DEFINED_TYPE | TIMESTAMP_NTZ | VARIANT | GEOMETRY | GEOGRAPHY | TABLE_TYPE`

Scalar function return data type.

[`external_language`](https://docs.databricks.com/api/workspace/functions/list#functions-external_language)string

External function language.

[`external_name`](https://docs.databricks.com/api/workspace/functions/list#functions-external_name)string

External function name.

[`full_data_type`](https://docs.databricks.com/api/workspace/functions/list#functions-full_data_type)string

Pretty printed function data type.

[`full_name`](https://docs.databricks.com/api/workspace/functions/list#functions-full_name)string

Full name of Function, in form of catalog_name.schema_name.function_name

[`function_id`](https://docs.databricks.com/api/workspace/functions/list#functions-function_id)string

Id of Function, relative to parent schema.

[`input_params`](https://docs.databricks.com/api/workspace/functions/list#functions-input_params)object

Function input parameters.

[`is_deterministic`](https://docs.databricks.com/api/workspace/functions/list#functions-is_deterministic)boolean

Whether the function is deterministic.

[`is_null_call`](https://docs.databricks.com/api/workspace/functions/list#functions-is_null_call)boolean

Function null call.

[`metastore_id`](https://docs.databricks.com/api/workspace/functions/list#functions-metastore_id)string

Unique identifier of parent metastore.

[`name`](https://docs.databricks.com/api/workspace/functions/list#functions-name)string

Name of function, relative to parent schema.

[`owner`](https://docs.databricks.com/api/workspace/functions/list#functions-owner)string

Username of current owner of the function.

[`parameter_style`](https://docs.databricks.com/api/workspace/functions/list#functions-parameter_style)string

Enum: `S`

Function parameter style. S is the value for SQL.

[`properties`](https://docs.databricks.com/api/workspace/functions/list#functions-properties)string

JSON-serialized key-value pair map, encoded (escaped) as a string.

[`return_params`](https://docs.databricks.com/api/workspace/functions/list#functions-return_params)object

Table function return parameters.

[`routine_body`](https://docs.databricks.com/api/workspace/functions/list#functions-routine_body)string

Enum: `SQL | EXTERNAL`

Function language. When EXTERNAL is used, the language of the routine function should be specified in the external_language field, and the return_params of the function cannot be used (as TABLE return type is not supported), and the sql_data_access field must be NO_SQL.

[`routine_definition`](https://docs.databricks.com/api/workspace/functions/list#functions-routine_definition)string

Function body.

[`routine_dependencies`](https://docs.databricks.com/api/workspace/functions/list#functions-routine_dependencies)object

function dependencies.

[`schema_name`](https://docs.databricks.com/api/workspace/functions/list#functions-schema_name)string

Name of parent Schema relative to its parent Catalog.

[`security_type`](https://docs.databricks.com/api/workspace/functions/list#functions-security_type)string

Enum: `DEFINER`

Function security type.

[`specific_name`](https://docs.databricks.com/api/workspace/functions/list#functions-specific_name)string

Specific name of the function; Reserved for future use.

[`sql_data_access`](https://docs.databricks.com/api/workspace/functions/list#functions-sql_data_access)string

Enum: `CONTAINS_SQL | READS_SQL_DATA | NO_SQL`

Function SQL data access.

[`sql_path`](https://docs.databricks.com/api/workspace/functions/list#functions-sql_path)string

List of schemes whose objects can be referenced without qualification.

[`updated_at`](https://docs.databricks.com/api/workspace/functions/list#functions-updated_at)int64

Time at which this function was last modified, in epoch milliseconds.

[`updated_by`](https://docs.databricks.com/api/workspace/functions/list#functions-updated_by)string

Username of user who last modified the function.

 ]

[`next_page_token`](https://docs.databricks.com/api/workspace/functions/list#next_page_token)string

Opaque token to retrieve the next page of results. Absent if there are no more pages. page_token should be set to this value for the next request (for the next page of results).

# Response samples

200

{

"functions":[

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

],

"next_page_token":"string"

}
