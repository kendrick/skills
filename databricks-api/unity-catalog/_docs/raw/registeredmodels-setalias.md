Title: Set a Registered Model Alias | Registered Models API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/registeredmodels/setalias

Markdown Content:
## Set a Registered Model Alias

`PUT/api/2.1/unity-catalog/models/{full_name}/aliases/{alias}`

Set an alias on the specified registered model.

The caller must be a metastore admin or an owner of the registered model. For the latter case, the caller must also be the owner or have the USE_CATALOG privilege on the parent catalog and the USE_SCHEMA privilege on the parent schema.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`full_name`](https://docs.databricks.com/api/workspace/registeredmodels/setalias#full_name)required string

The three-level (fully qualified) name of the registered model

[`alias`](https://docs.databricks.com/api/workspace/registeredmodels/setalias#alias)required string

The name of the alias

### Request body

[`version_num`](https://docs.databricks.com/api/workspace/registeredmodels/setalias#version_num)required int32

The version number of the model version to which the alias points

### Responses

**200** Request completed successfully.

Request completed successfully.

[`alias_name`](https://docs.databricks.com/api/workspace/registeredmodels/setalias#alias_name)string

Name of the alias, e.g. 'champion' or 'latest_stable'

[`catalog_name`](https://docs.databricks.com/api/workspace/registeredmodels/setalias#catalog_name)string

The name of the catalog containing the model version

[`id`](https://docs.databricks.com/api/workspace/registeredmodels/setalias#id)string

The unique identifier of the alias

[`model_name`](https://docs.databricks.com/api/workspace/registeredmodels/setalias#model_name)string

The name of the parent registered model of the model version, relative to parent schema

[`schema_name`](https://docs.databricks.com/api/workspace/registeredmodels/setalias#schema_name)string

The name of the schema containing the model version, relative to parent catalog

[`version_num`](https://docs.databricks.com/api/workspace/registeredmodels/setalias#version_num)int32

Integer version number of the model version to which this alias points.

# Request samples

JSON

{

"version_num":0

}

# Response samples

200

{

"alias_name":"string",

"catalog_name":"string",

"id":"string",

"model_name":"string",

"schema_name":"string",

"version_num":0

}
