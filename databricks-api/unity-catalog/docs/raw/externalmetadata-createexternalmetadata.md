Title: Create an external metadata object | External Metadata API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/externalmetadata/createexternalmetadata

Markdown Content:
## Create an external metadata object

Public preview

`POST/api/2.0/lineage-tracking/external-metadata`

Creates a new external metadata object in the parent metastore if the caller is a metastore admin or has the CREATE_EXTERNAL_METADATA privilege. Grants BROWSE to all account users upon creation by default.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Request body

[`columns`](https://docs.databricks.com/api/workspace/externalmetadata/createexternalmetadata#columns)Array of string Optional

Example

List of columns associated with the external metadata object.

[`description`](https://docs.databricks.com/api/workspace/externalmetadata/createexternalmetadata#description)string Optional

Example`"A stream of security related events in the critical services."`

User-provided free-form text description.

[`entity_type`](https://docs.databricks.com/api/workspace/externalmetadata/createexternalmetadata#entity_type)string Required

Example`"Topic"`

Type of entity within the external system.

[`name`](https://docs.databricks.com/api/workspace/externalmetadata/createexternalmetadata#name)string Required

Example`"security_events_stream"`

Name of the external metadata object.

[`owner`](https://docs.databricks.com/api/workspace/externalmetadata/createexternalmetadata#owner)string Optional

Example`"data-team@company.com"`

Owner of the external metadata object.

[`properties`](https://docs.databricks.com/api/workspace/externalmetadata/createexternalmetadata#properties)object Optional

Example

A map of key-value properties attached to the external metadata object.

[`system_type`](https://docs.databricks.com/api/workspace/externalmetadata/createexternalmetadata#system_type)string Required

Enum: `OTHER | TABLEAU | POWER_BI | LOOKER | KAFKA | SAP | ORACLE | SALESFORCE | WORKDAY | MYSQL | POSTGRESQL | MICROSOFT_SQL_SERVER | SERVICENOW | AMAZON_REDSHIFT | AZURE_SYNAPSE | SNOWFLAKE | GOOGLE_BIGQUERY | MICROSOFT_FABRIC | MONGODB | TERADATA | CONFLUENT | DATABRICKS | STREAM_NATIVE`

Type of external system.

[`url`](https://docs.databricks.com/api/workspace/externalmetadata/createexternalmetadata#url)string Optional

Example`"https://kafka.com/12345"`

URL associated with the external metadata object.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`columns`](https://docs.databricks.com/api/workspace/externalmetadata/createexternalmetadata#columns)Array of string

Example

List of columns associated with the external metadata object.

[`create_time`](https://docs.databricks.com/api/workspace/externalmetadata/createexternalmetadata#create_time)date-time

Time at which this external metadata object was created.

[`created_by`](https://docs.databricks.com/api/workspace/externalmetadata/createexternalmetadata#created_by)string

Username of external metadata object creator.

[`description`](https://docs.databricks.com/api/workspace/externalmetadata/createexternalmetadata#description)string

Example`"A stream of security related events in the critical services."`

User-provided free-form text description.

[`entity_type`](https://docs.databricks.com/api/workspace/externalmetadata/createexternalmetadata#entity_type)string

Example`"Topic"`

Type of entity within the external system.

[`id`](https://docs.databricks.com/api/workspace/externalmetadata/createexternalmetadata#id)string

Example`"12345678-abcd-4ef5-9012-3456789abcdf"`

Unique identifier of the external metadata object.

[`metastore_id`](https://docs.databricks.com/api/workspace/externalmetadata/createexternalmetadata#metastore_id)string

Unique identifier of parent metastore.

[`name`](https://docs.databricks.com/api/workspace/externalmetadata/createexternalmetadata#name)string

Example`"security_events_stream"`

Name of the external metadata object.

[`owner`](https://docs.databricks.com/api/workspace/externalmetadata/createexternalmetadata#owner)string

Example`"data-team@company.com"`

Owner of the external metadata object.

[`properties`](https://docs.databricks.com/api/workspace/externalmetadata/createexternalmetadata#properties)object

Example

A map of key-value properties attached to the external metadata object.

[`system_type`](https://docs.databricks.com/api/workspace/externalmetadata/createexternalmetadata#system_type)string

Enum: `OTHER | TABLEAU | POWER_BI | LOOKER | KAFKA | SAP | ORACLE | SALESFORCE | WORKDAY | MYSQL | POSTGRESQL | MICROSOFT_SQL_SERVER | SERVICENOW | AMAZON_REDSHIFT | AZURE_SYNAPSE | SNOWFLAKE | GOOGLE_BIGQUERY | MICROSOFT_FABRIC | MONGODB | TERADATA | CONFLUENT | DATABRICKS | STREAM_NATIVE`

Type of external system.

[`update_time`](https://docs.databricks.com/api/workspace/externalmetadata/createexternalmetadata#update_time)date-time

Time at which this external metadata object was last modified.

[`updated_by`](https://docs.databricks.com/api/workspace/externalmetadata/createexternalmetadata#updated_by)string

Username of user who last modified external metadata object.

[`url`](https://docs.databricks.com/api/workspace/externalmetadata/createexternalmetadata#url)string

Example`"https://kafka.com/12345"`

URL associated with the external metadata object.

# Request samples

JSON

{

"columns":[

"type",

"message",

"details",

"date",

"time"

],

"description":"A stream of security related eve nts in the critical services.",

"entity_type":"Topic",

"name":"security_events_stream",

"properties":{

"compression.enabled":"true",

"compression.format":"zstd",

"topic":"prod.security.events.raw"

},

"system_type":"KAFKA",

"url":"https://kafka.com/12345"

}

# Response samples

200

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

"description":"A stream of security related eve nts in the critical services.",

"entity_type":"Topic",

"id":"12345678-abcd-4ef5-9012-3456789abcdf",

"metastore_id":"12345678-abcd-4ef5-9012-3456789 abcde",

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

}
