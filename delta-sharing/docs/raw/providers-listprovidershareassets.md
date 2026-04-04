Title: List assets by provider share | Providers API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/providers/listprovidershareassets

Markdown Content:
## List assets by provider share

`GET/api/2.1/data-sharing/providers/{provider_name}/shares/{share_name}`

Get arrays of assets associated with a specified provider's share. The caller is the recipient of the share.

API scopes (preview):[`sharing`](https://docs.databricks.com/api/workspace/api/scopes#sharing)

### Path parameters

[`provider_name`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#provider_name)required string

The name of the provider who owns the share.

[`share_name`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#share_name)required string

The name of the share.

### Query parameters

[`table_max_results`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#table_max_results)int32

<= 1000 

Default`500`

Maximum number of tables to return.

[`function_max_results`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#function_max_results)int32

<= 1000 

Default`500`

Maximum number of functions to return.

[`volume_max_results`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#volume_max_results)int32

<= 1000 

Default`500`

Maximum number of volumes to return.

[`notebook_max_results`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#notebook_max_results)int32

<= 100 

Default`100`

Maximum number of notebooks to return.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`functions`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#functions)Array of object

The list of functions in the share.

Array [

[`aliases`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#functions-aliases)Array of object

The aliass of registered model.

[`comment`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#functions-comment)string

The comment of the function.

[`data_type`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#functions-data_type)string

Enum: `BOOLEAN | BYTE | SHORT | INT | LONG | FLOAT | DOUBLE | DATE | TIMESTAMP | STRING | BINARY | DECIMAL | INTERVAL | ARRAY | STRUCT | MAP | CHAR | NULL | USER_DEFINED_TYPE | TIMESTAMP_NTZ | VARIANT | TABLE_TYPE`

The data type of the function.

[`dependency_list`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#functions-dependency_list)object

The dependency list of the function.

[`full_data_type`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#functions-full_data_type)string

The full data type of the function.

[`id`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#functions-id)string

The id of the function.

[`input_params`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#functions-input_params)object

The function parameter information.

[`name`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#functions-name)string

The name of the function.

[`properties`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#functions-properties)string

The properties of the function.

[`routine_definition`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#functions-routine_definition)string

The routine definition of the function.

[`schema`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#functions-schema)string

The name of the schema that the function belongs to.

[`securable_kind`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#functions-securable_kind)string

Enum: `FUNCTION_STANDARD | FUNCTION_REGISTERED_MODEL | FUNCTION_FEATURE_SPEC`

The securable kind of the function.

[`share`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#functions-share)string

The name of the share that the function belongs to.

[`share_id`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#functions-share_id)string

The id of the share that the function belongs to.

[`storage_location`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#functions-storage_location)string

The storage location of the function.

[`tags`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#functions-tags)Array of object

The tags of the function.

 ]

[`notebooks`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#notebooks)Array of object

The list of notebooks in the share.

Array [

[`comment`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#notebooks-comment)string

The comment of the notebook file.

[`id`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#notebooks-id)string

The id of the notebook file.

[`name`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#notebooks-name)string

Name of the notebook file.

[`share`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#notebooks-share)string

The name of the share that the notebook file belongs to.

[`share_id`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#notebooks-share_id)string

The id of the share that the notebook file belongs to.

[`tags`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#notebooks-tags)Array of object

The tags of the notebook file.

 ]

[`share`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#share)object

The metadata of the share.

[`id`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#share-id)string

[`name`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#share-name)string

[`tables`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#tables)Array of object

The list of tables in the share.

Array [

[`comment`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#tables-comment)string

The comment of the table.

[`id`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#tables-id)string

The id of the table.

[`materialization_namespace`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#tables-materialization_namespace)string

The catalog and schema of the materialized table

[`materialized_table_name`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#tables-materialized_table_name)string

The name of a materialized table.

[`name`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#tables-name)string

The name of the table.

[`schema`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#tables-schema)string

The name of the schema that the table belongs to.

[`share`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#tables-share)string

The name of the share that the table belongs to.

[`share_id`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#tables-share_id)string

The id of the share that the table belongs to.

[`tags`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#tables-tags)Array of object

The Tags of the table.

 ]

[`volumes`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#volumes)Array of object

The list of volumes in the share.

Array [

[`comment`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#volumes-comment)string

The comment of the volume.

[`id`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#volumes-id)string

This id maps to the shared_volume_id in database Recipient needs shared_volume_id for recon to check if this volume is already in recipient's DB or not.

[`name`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#volumes-name)string

The name of the volume.

[`schema`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#volumes-schema)string

The name of the schema that the volume belongs to.

[`share`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#volumes-share)string

The name of the share that the volume belongs to.

[`share_id`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#volumes-share_id)string

/ The id of the share that the volume belongs to.

[`tags`](https://docs.databricks.com/api/workspace/providers/listprovidershareassets#volumes-tags)Array of object

The tags of the volume.

 ]

# Response samples

200

{

"functions":[

{

"aliases":[

{

"alias_name":"string",

"version_num":0

}

],

"comment":"string",

"data_type":"BOOLEAN",

"dependency_list":{

"dependencies":[

{

"function":{

"function_name":"string",

"schema_name":"string"

},

"table":{

"schema_name":"string",

"table_name":"string"

}

}

]

},

"full_data_type":"string",

"id":"string",

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

"name":"string",

"properties":"string",

"routine_definition":"string",

"schema":"string",

"securable_kind":"FUNCTION_STANDARD",

"share":"string",

"share_id":"string",

"storage_location":"string",

"tags":[

{

"key":"string",

"value":"string"

}

]

}

],

"notebooks":[

{

"comment":"string",

"id":"string",

"name":"string",

"share":"string",

"share_id":"string",

"tags":[

{

"key":"string",

"value":"string"

}

]

}

],

"share":{

"id":"string",

"name":"string"

},

"tables":[

{

"comment":"string",

"id":"string",

"materialization_namespace":"string",

"materialized_table_name":"string",

"name":"string",

"schema":"string",

"share":"string",

"share_id":"string",

"tags":[

{

"key":"string",

"value":"string"

}

]

}

],

"volumes":[

{

"comment":"string",

"id":"string",

"name":"string",

"schema":"string",

"share":"string",

"share_id":"string",

"tags":[

{

"key":"string",

"value":"string"

}

]

}

]

}
