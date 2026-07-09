Title: Create an external lineage relationship | External Lineage API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/externallineage/createexternallineagerelationship

Markdown Content:
## Create an external lineage relationship

Public preview

`POST/api/2.0/lineage-tracking/external-lineage`

Creates an external lineage relationship between a Databricks or external metadata object and another external metadata object.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Request body

[`columns`](https://docs.databricks.com/api/workspace/externallineage/createexternallineagerelationship#columns)Array of object Optional

List of column relationships between source and target objects.

Array [

[`source`](https://docs.databricks.com/api/workspace/externallineage/createexternallineagerelationship#columns-source)string

[`target`](https://docs.databricks.com/api/workspace/externallineage/createexternallineagerelationship#columns-target)string

 ]

[`properties`](https://docs.databricks.com/api/workspace/externallineage/createexternallineagerelationship#properties)object Optional

Key-value properties associated with the external lineage relationship.

[`source`](https://docs.databricks.com/api/workspace/externallineage/createexternallineagerelationship#source)object Required

Source object of the external lineage relationship.

[`external_metadata`](https://docs.databricks.com/api/workspace/externallineage/createexternallineagerelationship#source-external_metadata)object

[`model_version`](https://docs.databricks.com/api/workspace/externallineage/createexternallineagerelationship#source-model_version)object

[`path`](https://docs.databricks.com/api/workspace/externallineage/createexternallineagerelationship#source-path)object

[`table`](https://docs.databricks.com/api/workspace/externallineage/createexternallineagerelationship#source-table)object

[`target`](https://docs.databricks.com/api/workspace/externallineage/createexternallineagerelationship#target)object Required

Target object of the external lineage relationship.

[`external_metadata`](https://docs.databricks.com/api/workspace/externallineage/createexternallineagerelationship#target-external_metadata)object

[`model_version`](https://docs.databricks.com/api/workspace/externallineage/createexternallineagerelationship#target-model_version)object

[`path`](https://docs.databricks.com/api/workspace/externallineage/createexternallineagerelationship#target-path)object

[`table`](https://docs.databricks.com/api/workspace/externallineage/createexternallineagerelationship#target-table)object

### Responses

**200** Request completed successfully.

Request completed successfully.

[`columns`](https://docs.databricks.com/api/workspace/externallineage/createexternallineagerelationship#columns)Array of object

List of column relationships between source and target objects.

Array [

[`source`](https://docs.databricks.com/api/workspace/externallineage/createexternallineagerelationship#columns-source)string

[`target`](https://docs.databricks.com/api/workspace/externallineage/createexternallineagerelationship#columns-target)string

 ]

[`id`](https://docs.databricks.com/api/workspace/externallineage/createexternallineagerelationship#id)string

Example`"12345678-abcd-4ef5-9012-3456789abcdf"`

Unique identifier of the external lineage relationship.

[`properties`](https://docs.databricks.com/api/workspace/externallineage/createexternallineagerelationship#properties)object

Key-value properties associated with the external lineage relationship.

[`source`](https://docs.databricks.com/api/workspace/externallineage/createexternallineagerelationship#source)object

Source object of the external lineage relationship.

[`external_metadata`](https://docs.databricks.com/api/workspace/externallineage/createexternallineagerelationship#source-external_metadata)object

[`model_version`](https://docs.databricks.com/api/workspace/externallineage/createexternallineagerelationship#source-model_version)object

[`path`](https://docs.databricks.com/api/workspace/externallineage/createexternallineagerelationship#source-path)object

[`table`](https://docs.databricks.com/api/workspace/externallineage/createexternallineagerelationship#source-table)object

[`target`](https://docs.databricks.com/api/workspace/externallineage/createexternallineagerelationship#target)object

Target object of the external lineage relationship.

[`external_metadata`](https://docs.databricks.com/api/workspace/externallineage/createexternallineagerelationship#target-external_metadata)object

[`model_version`](https://docs.databricks.com/api/workspace/externallineage/createexternallineagerelationship#target-model_version)object

[`path`](https://docs.databricks.com/api/workspace/externallineage/createexternallineagerelationship#target-path)object

[`table`](https://docs.databricks.com/api/workspace/externallineage/createexternallineagerelationship#target-table)object

# Request samples

JSON

{

"columns":[

{

"source":"transaction_id",

"target":"id"

},

{

"source":"amount",

"target":"revenue"

}

],

"properties":{

"refresh_enabled":"true",

"refresh_frequency":"daily"

},

"source":{

"table":{

"name":"main.sales.transactions"

}

},

"target":{

"external_metadata":{

"name":"sales_dashboard"

}

}

}

# Response samples

200

{

"columns":[

{

"source":"transaction_id",

"target":"id"

},

{

"source":"amount",

"target":"revenue"

}

],

"id":"12345678-abcd-4ef5-9012-3456789abcdf",

"properties":{

"refresh_enabled":"true",

"refresh_frequency":"daily"

},

"source":{

"table":{

"name":"main.sales.transactions"

}

},

"target":{

"external_metadata":{

"name":"sales_dashboard"

}

}

}
