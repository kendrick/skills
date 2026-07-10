Title: Update an external lineage relationship | External Lineage API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/externallineage/updateexternallineagerelationship

Markdown Content:
## Update an external lineage relationship

Public preview

`PATCH/api/2.0/lineage-tracking/external-lineage`

Updates an external lineage relationship between a Databricks or external metadata object and another external metadata object.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Query parameters

[`update_mask`](https://docs.databricks.com/api/workspace/externallineage/updateexternallineagerelationship#update_mask)required string

The field mask must be a single string, with multiple fields separated by commas (no spaces). The field path is relative to the resource object, using a dot (`.`) to navigate sub-fields (e.g., `author.given_name`). Specification of elements in sequence or map fields is not allowed, as only the entire collection field can be specified. Field names must exactly match the resource field names.

A field mask of `*` indicates full replacement. It’s recommended to always explicitly list the fields being updated and avoid using `*` wildcards, as it can lead to unintended results if the API changes in the future.

### Request body

[`columns`](https://docs.databricks.com/api/workspace/externallineage/updateexternallineagerelationship#columns)Array of object Optional

List of column relationships between source and target objects.

Array [

[`source`](https://docs.databricks.com/api/workspace/externallineage/updateexternallineagerelationship#columns-source)string

[`target`](https://docs.databricks.com/api/workspace/externallineage/updateexternallineagerelationship#columns-target)string

 ]

[`properties`](https://docs.databricks.com/api/workspace/externallineage/updateexternallineagerelationship#properties)object Optional

Key-value properties associated with the external lineage relationship.

[`source`](https://docs.databricks.com/api/workspace/externallineage/updateexternallineagerelationship#source)object Required

Source object of the external lineage relationship.

[`external_metadata`](https://docs.databricks.com/api/workspace/externallineage/updateexternallineagerelationship#source-external_metadata)object

[`model_version`](https://docs.databricks.com/api/workspace/externallineage/updateexternallineagerelationship#source-model_version)object

[`path`](https://docs.databricks.com/api/workspace/externallineage/updateexternallineagerelationship#source-path)object

[`table`](https://docs.databricks.com/api/workspace/externallineage/updateexternallineagerelationship#source-table)object

[`target`](https://docs.databricks.com/api/workspace/externallineage/updateexternallineagerelationship#target)object Required

Target object of the external lineage relationship.

[`external_metadata`](https://docs.databricks.com/api/workspace/externallineage/updateexternallineagerelationship#target-external_metadata)object

[`model_version`](https://docs.databricks.com/api/workspace/externallineage/updateexternallineagerelationship#target-model_version)object

[`path`](https://docs.databricks.com/api/workspace/externallineage/updateexternallineagerelationship#target-path)object

[`table`](https://docs.databricks.com/api/workspace/externallineage/updateexternallineagerelationship#target-table)object

### Responses

**200** Request completed successfully.

Request completed successfully.

[`columns`](https://docs.databricks.com/api/workspace/externallineage/updateexternallineagerelationship#columns)Array of object

List of column relationships between source and target objects.

Array [

[`source`](https://docs.databricks.com/api/workspace/externallineage/updateexternallineagerelationship#columns-source)string

[`target`](https://docs.databricks.com/api/workspace/externallineage/updateexternallineagerelationship#columns-target)string

 ]

[`id`](https://docs.databricks.com/api/workspace/externallineage/updateexternallineagerelationship#id)string

Example`"12345678-abcd-4ef5-9012-3456789abcdf"`

Unique identifier of the external lineage relationship.

[`properties`](https://docs.databricks.com/api/workspace/externallineage/updateexternallineagerelationship#properties)object

Key-value properties associated with the external lineage relationship.

[`source`](https://docs.databricks.com/api/workspace/externallineage/updateexternallineagerelationship#source)object

Source object of the external lineage relationship.

[`external_metadata`](https://docs.databricks.com/api/workspace/externallineage/updateexternallineagerelationship#source-external_metadata)object

[`model_version`](https://docs.databricks.com/api/workspace/externallineage/updateexternallineagerelationship#source-model_version)object

[`path`](https://docs.databricks.com/api/workspace/externallineage/updateexternallineagerelationship#source-path)object

[`table`](https://docs.databricks.com/api/workspace/externallineage/updateexternallineagerelationship#source-table)object

[`target`](https://docs.databricks.com/api/workspace/externallineage/updateexternallineagerelationship#target)object

Target object of the external lineage relationship.

[`external_metadata`](https://docs.databricks.com/api/workspace/externallineage/updateexternallineagerelationship#target-external_metadata)object

[`model_version`](https://docs.databricks.com/api/workspace/externallineage/updateexternallineagerelationship#target-model_version)object

[`path`](https://docs.databricks.com/api/workspace/externallineage/updateexternallineagerelationship#target-path)object

[`table`](https://docs.databricks.com/api/workspace/externallineage/updateexternallineagerelationship#target-table)object

# Request samples

JSON

{

"columns":[

{

"source":"transaction_id",

"target":"id"

},

{

"source":"amount2",

"target":"revenue2"

}

],

"properties":{

"refresh_enabled":"false",

"refresh_frequency":"daily"

},

"source":{

"model_version":{

"name":"main.sales.transactions",

"version":"1"

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

"source":"amount2",

"target":"revenue2"

}

],

"id":"12345678-abcd-4ef5-9012-3456789abcdf",

"properties":{

"refresh_enabled":"false",

"refresh_frequency":"daily"

},

"source":{

"model_version":{

"name":"main.sales.transactions",

"version":"1"

}

},

"target":{

"external_metadata":{

"name":"sales_dashboard"

}

}

}
