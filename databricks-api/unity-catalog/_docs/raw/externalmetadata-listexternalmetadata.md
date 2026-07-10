Title: List external metadata objects | External Metadata API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/externalmetadata/listexternalmetadata

Markdown Content:
## List external metadata objects

Public preview

`GET/api/2.0/lineage-tracking/external-metadata`

Gets an array of external metadata objects in the metastore. If the caller is the metastore admin, all external metadata objects will be retrieved. Otherwise, only external metadata objects that the caller has BROWSE on will be retrieved. There is no guarantee of a specific ordering of the elements in the array.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Query parameters

[`page_size`](https://docs.databricks.com/api/workspace/externalmetadata/listexternalmetadata#page_size)int32 Optional

Specifies the maximum number of external metadata objects to return in a single response. The value must be less than or equal to 1000.

[`page_token`](https://docs.databricks.com/api/workspace/externalmetadata/listexternalmetadata#page_token)string Optional

Opaque pagination token to go to next page based on previous query.

### Responses

**200** Request completed successfully. The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

Request completed successfully.

 The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

[`external_metadata`](https://docs.databricks.com/api/workspace/externalmetadata/listexternalmetadata#external_metadata)Array of object

Array [

[`columns`](https://docs.databricks.com/api/workspace/externalmetadata/listexternalmetadata#external_metadata-columns)Array of string

Example

List of columns associated with the external metadata object.

[`create_time`](https://docs.databricks.com/api/workspace/externalmetadata/listexternalmetadata#external_metadata-create_time)date-time

Time at which this external metadata object was created.

[`created_by`](https://docs.databricks.com/api/workspace/externalmetadata/listexternalmetadata#external_metadata-created_by)string

Username of external metadata object creator.

[`description`](https://docs.databricks.com/api/workspace/externalmetadata/listexternalmetadata#external_metadata-description)string

Example`"A stream of security related events in the critical services."`

User-provided free-form text description.

[`entity_type`](https://docs.databricks.com/api/workspace/externalmetadata/listexternalmetadata#external_metadata-entity_type)string

Example`"Topic"`

Type of entity within the external system.

[`id`](https://docs.databricks.com/api/workspace/externalmetadata/listexternalmetadata#external_metadata-id)string

Example`"12345678-abcd-4ef5-9012-3456789abcdf"`

Unique identifier of the external metadata object.

[`metastore_id`](https://docs.databricks.com/api/workspace/externalmetadata/listexternalmetadata#external_metadata-metastore_id)string

Unique identifier of parent metastore.

[`name`](https://docs.databricks.com/api/workspace/externalmetadata/listexternalmetadata#external_metadata-name)string

Example`"security_events_stream"`

Name of the external metadata object.

[`owner`](https://docs.databricks.com/api/workspace/externalmetadata/listexternalmetadata#external_metadata-owner)string

Example`"data-team@company.com"`

Owner of the external metadata object.

[`properties`](https://docs.databricks.com/api/workspace/externalmetadata/listexternalmetadata#external_metadata-properties)object

Example

A map of key-value properties attached to the external metadata object.

[`system_type`](https://docs.databricks.com/api/workspace/externalmetadata/listexternalmetadata#external_metadata-system_type)string

Enum: `OTHER | TABLEAU | POWER_BI | LOOKER | KAFKA | SAP | ORACLE | SALESFORCE | WORKDAY | MYSQL | POSTGRESQL | MICROSOFT_SQL_SERVER | SERVICENOW | AMAZON_REDSHIFT | AZURE_SYNAPSE | SNOWFLAKE | GOOGLE_BIGQUERY | MICROSOFT_FABRIC | MONGODB | TERADATA | CONFLUENT | DATABRICKS | STREAM_NATIVE`

Type of external system.

[`update_time`](https://docs.databricks.com/api/workspace/externalmetadata/listexternalmetadata#external_metadata-update_time)date-time

Time at which this external metadata object was last modified.

[`updated_by`](https://docs.databricks.com/api/workspace/externalmetadata/listexternalmetadata#external_metadata-updated_by)string

Username of user who last modified external metadata object.

[`url`](https://docs.databricks.com/api/workspace/externalmetadata/listexternalmetadata#external_metadata-url)string

Example`"https://kafka.com/12345"`

URL associated with the external metadata object.

 ]

[`next_page_token`](https://docs.databricks.com/api/workspace/externalmetadata/listexternalmetadata#next_page_token)string

# Response samples

200

{

"external_metadata":[

{

"columns":[

"type",

"message",

"details",

"date",

"time"

],

"create_time":1715802661000,

"created_by":"john.doe@company.com",

"description":"A stream of security related events in the critical services.",

"entity_type":"Topic",

"id":"12345678-abcd-4ef5-9012-3456789abcdf",

"metastore_id":"12345678-abcd-4ef5-9012-345 6789abcde",

"name":"security_events_stream",

"owner":"data-team@company.com",

"properties":{

"compression.enabled":"true",

"compression.format":"zstd",

"topic":"prod.security.events.raw"

},

"system_type":"KAFKA",

"update_time":1715802661000,

"updated_by":"john.doe@company.com",

"url":"https://kafka.com/12345"

},

{

"columns":[

"customer_id",

"age_group",

"location",

"segment"

],

"create_time":1715889061000,

"created_by":"alice.johnson@company.com",

"description":"Customer analysis report wit h demographics",

"entity_type":"Report",

"id":"87654321-dcba-4ef5-9012-3456789abcde",

"metastore_id":"12345678-abcd-4ef5-9012-345 6789abcde",

"name":"customer_report",

"owner":"analytics-team@company.com",

"properties":{

"data_source":"warehouse",

"refresh_enabled":"false"

},

"system_type":"TABLEAU",

"update_time":1716148261000,

"updated_by":"bob.wilson@company.com",

"url":"https://tableau.company.com/reports/customer-analysis"

},

{

"columns":[

"product_id",

"quantity",

"location",

"last_updated"

],

"create_time":1716234661000,

"created_by":"charlie.brown@company.com",

"description":"Inventory tracking model for warehouse management",

"entity_type":"Model",

"id":"abcdef12-3456-7890-abcd-ef1234567890",

"metastore_id":"12345678-abcd-4ef5-9012-345 6789abcde",

"name":"inventory_model",

"owner":"operations-team@company.com",

"properties":{

"model_type":"dimensional",

"refresh_enabled":"true",

"refresh_frequency":"real-time"

},

"system_type":"LOOKER",

"update_time":1716234661000,

"updated_by":"charlie.brown@company.com",

"url":"https://looker.company.com/models/in ventory"

}

],

"next_page_token":"eyJwYWdlX251bWJlciI6Mn0="

}
