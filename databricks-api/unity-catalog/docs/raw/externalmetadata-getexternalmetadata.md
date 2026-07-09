Title: Get an external metadata object | External Metadata API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/externalmetadata/getexternalmetadata

Markdown Content:
## Get an external metadata object

Public preview

`GET/api/2.0/lineage-tracking/external-metadata/{name}`

Gets the specified external metadata object in a metastore. The caller must be a metastore admin, the owner of the external metadata object, or a user that has the BROWSE privilege.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`name`](https://docs.databricks.com/api/workspace/externalmetadata/getexternalmetadata#name)required string

### Responses

**200** Request completed successfully.

Request completed successfully.

[`columns`](https://docs.databricks.com/api/workspace/externalmetadata/getexternalmetadata#columns)Array of string

Example

List of columns associated with the external metadata object.

[`create_time`](https://docs.databricks.com/api/workspace/externalmetadata/getexternalmetadata#create_time)date-time

Time at which this external metadata object was created.

[`created_by`](https://docs.databricks.com/api/workspace/externalmetadata/getexternalmetadata#created_by)string

Username of external metadata object creator.

[`description`](https://docs.databricks.com/api/workspace/externalmetadata/getexternalmetadata#description)string

Example`"A stream of security related events in the critical services."`

User-provided free-form text description.

[`entity_type`](https://docs.databricks.com/api/workspace/externalmetadata/getexternalmetadata#entity_type)string

Example`"Topic"`

Type of entity within the external system.

[`id`](https://docs.databricks.com/api/workspace/externalmetadata/getexternalmetadata#id)string

Example`"12345678-abcd-4ef5-9012-3456789abcdf"`

Unique identifier of the external metadata object.

[`metastore_id`](https://docs.databricks.com/api/workspace/externalmetadata/getexternalmetadata#metastore_id)string

Unique identifier of parent metastore.

[`name`](https://docs.databricks.com/api/workspace/externalmetadata/getexternalmetadata#name)string

Example`"security_events_stream"`

Name of the external metadata object.

[`owner`](https://docs.databricks.com/api/workspace/externalmetadata/getexternalmetadata#owner)string

Example`"data-team@company.com"`

Owner of the external metadata object.

[`properties`](https://docs.databricks.com/api/workspace/externalmetadata/getexternalmetadata#properties)object

Example

A map of key-value properties attached to the external metadata object.

[`system_type`](https://docs.databricks.com/api/workspace/externalmetadata/getexternalmetadata#system_type)string

Enum: `OTHER | TABLEAU | POWER_BI | LOOKER | KAFKA | SAP | ORACLE | SALESFORCE | WORKDAY | MYSQL | POSTGRESQL | MICROSOFT_SQL_SERVER | SERVICENOW | AMAZON_REDSHIFT | AZURE_SYNAPSE | SNOWFLAKE | GOOGLE_BIGQUERY | MICROSOFT_FABRIC | MONGODB | TERADATA | CONFLUENT | DATABRICKS | STREAM_NATIVE`

Type of external system.

[`update_time`](https://docs.databricks.com/api/workspace/externalmetadata/getexternalmetadata#update_time)date-time

Time at which this external metadata object was last modified.

[`updated_by`](https://docs.databricks.com/api/workspace/externalmetadata/getexternalmetadata#updated_by)string

Username of user who last modified external metadata object.

[`url`](https://docs.databricks.com/api/workspace/externalmetadata/getexternalmetadata#url)string

Example`"https://kafka.com/12345"`

URL associated with the external metadata object.

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
