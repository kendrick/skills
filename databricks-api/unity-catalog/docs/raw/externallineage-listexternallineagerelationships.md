Title: List external lineage relationships | External Lineage API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/externallineage/listexternallineagerelationships

Markdown Content:
## List external lineage relationships

Public preview

`GET/api/2.0/lineage-tracking/external-lineage`

Lists external lineage relationships of a Databricks object or external metadata given a supplied direction.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Query parameters

[`object_info`](https://docs.databricks.com/api/workspace/externallineage/listexternallineagerelationships#object_info)required object

The object to query external lineage relationships for. Since this field is a query parameter, please flatten the nested fields. For example, if the object is a table, the query parameter should look like: `object_info.table.name=main.sales.customers`

[`external_metadata`](https://docs.databricks.com/api/workspace/externallineage/listexternallineagerelationships#object_info-external_metadata)object

[`model_version`](https://docs.databricks.com/api/workspace/externallineage/listexternallineagerelationships#object_info-model_version)object

[`path`](https://docs.databricks.com/api/workspace/externallineage/listexternallineagerelationships#object_info-path)object

[`table`](https://docs.databricks.com/api/workspace/externallineage/listexternallineagerelationships#object_info-table)object

[`lineage_direction`](https://docs.databricks.com/api/workspace/externallineage/listexternallineagerelationships#lineage_direction)required string

Enum: `UPSTREAM | DOWNSTREAM`

Example`lineage_direction=DOWNSTREAM`

The lineage direction to filter on.

[`page_size`](https://docs.databricks.com/api/workspace/externallineage/listexternallineagerelationships#page_size)int32

Specifies the maximum number of external lineage relationships to return in a single response. The value must be less than or equal to 1000.

[`page_token`](https://docs.databricks.com/api/workspace/externallineage/listexternallineagerelationships#page_token)string

Opaque pagination token to go to next page based on previous query.

### Responses

**200** Request completed successfully. The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

Request completed successfully.

 The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

[`external_lineage_relationships`](https://docs.databricks.com/api/workspace/externallineage/listexternallineagerelationships#external_lineage_relationships)Array of object

Array [

[`external_lineage_info`](https://docs.databricks.com/api/workspace/externallineage/listexternallineagerelationships#external_lineage_relationships-external_lineage_info)object

Information about the edge metadata of the external lineage relationship.

[`external_metadata_info`](https://docs.databricks.com/api/workspace/externallineage/listexternallineagerelationships#external_lineage_relationships-external_metadata_info)object

Information about external metadata involved in the lineage relationship.

[`file_info`](https://docs.databricks.com/api/workspace/externallineage/listexternallineagerelationships#external_lineage_relationships-file_info)object

Information about the file involved in the lineage relationship.

[`model_info`](https://docs.databricks.com/api/workspace/externallineage/listexternallineagerelationships#external_lineage_relationships-model_info)object

Information about the model version involved in the lineage relationship.

[`table_info`](https://docs.databricks.com/api/workspace/externallineage/listexternallineagerelationships#external_lineage_relationships-table_info)object

Information about the table involved in the lineage relationship.

 ]

[`next_page_token`](https://docs.databricks.com/api/workspace/externallineage/listexternallineagerelationships#next_page_token)string

# Response samples

200

{

"external_lineage_relationships":[

{

"external_lineage_info":{

"columns":[

{

"source":"customer_id",

"target":"id"

}

],

"properties":{

"refresh_enabled":"true",

"refresh_frequency":"daily"

}

},

"table_info":{

"catalog_name":"main",

"event_time":"2025-05-14T15:22:33.102Z",

"name":"customers",

"schema_name":"sales"

}

},

{

"external_lineage_info":{

"columns":[

{

"source":"contact_id",

"target":"id"

}

]

},

"external_metadata_info":{

"entity_type":"CRM",

"event_time":"2025-05-13T15:22:33.102Z",

"name":"customer_crm",

"system_type":"SALESFORCE"

}

}

],

"next_page_token":"eyJfX3R2IjoiMCIsImV4dGVybmFs TWV0YWRhdGEiOiJleHRlcm5hbC1tZXRhZGF0YS0zIn0"

}
