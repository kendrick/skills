Title: Update an external metadata object | External Metadata API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/externalmetadata/updateexternalmetadata

Markdown Content:
## Update an external metadata object

Public preview

`PATCH/api/2.0/lineage-tracking/external-metadata/{name}`

Updates the external metadata object that matches the supplied name. The caller can only update either the owner or other metadata fields in one request. The caller must be a metastore admin, the owner of the external metadata object, or a user that has the MODIFY privilege. If the caller is updating the owner, they must also have the MANAGE privilege.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`name`](https://docs.databricks.com/api/workspace/externalmetadata/updateexternalmetadata#name)string Required

Example`"security_events_stream"`

Name of the external metadata object.

### Query parameters

[`update_mask`](https://docs.databricks.com/api/workspace/externalmetadata/updateexternalmetadata#update_mask)required string

The field mask must be a single string, with multiple fields separated by commas (no spaces). The field path is relative to the resource object, using a dot (`.`) to navigate sub-fields (e.g., `author.given_name`). Specification of elements in sequence or map fields is not allowed, as only the entire collection field can be specified. Field names must exactly match the resource field names.

A field mask of `*` indicates full replacement. It’s recommended to always explicitly list the fields being updated and avoid using `*` wildcards, as it can lead to unintended results if the API changes in the future.

### Request body

[`columns`](https://docs.databricks.com/api/workspace/externalmetadata/updateexternalmetadata#columns)Array of string Optional

Example

List of columns associated with the external metadata object.

[`description`](https://docs.databricks.com/api/workspace/externalmetadata/updateexternalmetadata#description)string Optional

Example`"A stream of security related events in the critical services."`

User-provided free-form text description.

[`entity_type`](https://docs.databricks.com/api/workspace/externalmetadata/updateexternalmetadata#entity_type)string Required

Example`"Topic"`

Type of entity within the external system.

[`owner`](https://docs.databricks.com/api/workspace/externalmetadata/updateexternalmetadata#owner)string Optional

Example`"data-team@company.com"`

Owner of the external metadata object.

[`properties`](https://docs.databricks.com/api/workspace/externalmetadata/updateexternalmetadata#properties)object Optional

Example

A map of key-value properties attached to the external metadata object.

[`system_type`](https://docs.databricks.com/api/workspace/externalmetadata/updateexternalmetadata#system_type)string Required

Enum: `OTHER | TABLEAU | POWER_BI | LOOKER | KAFKA | SAP | ORACLE | SALESFORCE | WORKDAY | MYSQL | POSTGRESQL | MICROSOFT_SQL_SERVER | SERVICENOW | AMAZON_REDSHIFT | AZURE_SYNAPSE | SNOWFLAKE | GOOGLE_BIGQUERY | MICROSOFT_FABRIC | MONGODB | TERADATA | CONFLUENT | DATABRICKS | STREAM_NATIVE`

Type of external system.

[`url`](https://docs.databricks.com/api/workspace/externalmetadata/updateexternalmetadata#url)string Optional

Example`"https://kafka.com/12345"`

URL associated with the external metadata object.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`columns`](https://docs.databricks.com/api/workspace/externalmetadata/updateexternalmetadata#columns)Array of string

Example

List of columns associated with the external metadata object.

[`create_time`](https://docs.databricks.com/api/workspace/externalmetadata/updateexternalmetadata#create_time)date-time

Time at which this external metadata object was created.

[`created_by`](https://docs.databricks.com/api/workspace/externalmetadata/updateexternalmetadata#created_by)string

Username of external metadata object creator.

[`description`](https://docs.databricks.com/api/workspace/externalmetadata/updateexternalmetadata#description)string

Example`"A stream of security related events in the critical services."`

User-provided free-form text description.

[`entity_type`](https://docs.databricks.com/api/workspace/externalmetadata/updateexternalmetadata#entity_type)string

Example`"Topic"`

Type of entity within the external system.

[`id`](https://docs.databricks.com/api/workspace/externalmetadata/updateexternalmetadata#id)string

Example`"12345678-abcd-4ef5-9012-3456789abcdf"`

Unique identifier of the external metadata object.

[`metastore_id`](https://docs.databricks.com/api/workspace/externalmetadata/updateexternalmetadata#metastore_id)string

Unique identifier of parent metastore.

[`name`](https://docs.databricks.com/api/workspace/externalmetadata/updateexternalmetadata#name)string

Example`"security_events_stream"`

Name of the external metadata object.

[`owner`](https://docs.databricks.com/api/workspace/externalmetadata/updateexternalmetadata#owner)string

Example`"data-team@company.com"`

Owner of the external metadata object.

[`properties`](https://docs.databricks.com/api/workspace/externalmetadata/updateexternalmetadata#properties)object

Example

A map of key-value properties attached to the external metadata object.

[`system_type`](https://docs.databricks.com/api/workspace/externalmetadata/updateexternalmetadata#system_type)string

Enum: `OTHER | TABLEAU | POWER_BI | LOOKER | KAFKA | SAP | ORACLE | SALESFORCE | WORKDAY | MYSQL | POSTGRESQL | MICROSOFT_SQL_SERVER | SERVICENOW | AMAZON_REDSHIFT | AZURE_SYNAPSE | SNOWFLAKE | GOOGLE_BIGQUERY | MICROSOFT_FABRIC | MONGODB | TERADATA | CONFLUENT | DATABRICKS | STREAM_NATIVE`

Type of external system.

[`update_time`](https://docs.databricks.com/api/workspace/externalmetadata/updateexternalmetadata#update_time)date-time

Time at which this external metadata object was last modified.

[`updated_by`](https://docs.databricks.com/api/workspace/externalmetadata/updateexternalmetadata#updated_by)string

Username of user who last modified external metadata object.

[`url`](https://docs.databricks.com/api/workspace/externalmetadata/updateexternalmetadata#url)string

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

"time",

"severity"

],

"description":"Updated stream of security relat ed events in the critical services.",

"entity_type":"Topic",

"properties":{

"compression.enabled":"true",

"compression.format":"lz4",

"topic":"prod.security.events.raw"

},

"system_type":"KAFKA",

"update_mask":"url,description,columns,properti es",

"url":"https://kafka.com/12345-updated"

}

# Response samples

200

{

"columns":[

"type",

"message",

"details",

"date",

"time",

"severity"

],

"create_time":1715802661000,

"created_by":"john.doe@company.com",

"description":"Updated stream of security relat ed events in the critical services.",

"entity_type":"Topic",

"id":"12345678-abcd-4ef5-9012-3456789abcdf",

"metastore_id":"12345678-abcd-4ef5-9012-3456789 abcde",

"name":"security_events_stream",

"owner":"data-team@company.com",

"properties":{

"compression.enabled":"true",

"compression.format":"lz4",

"topic":"prod.security.events.raw"

},

"system_type":"KAFKA",

"update_time":1717394661000,

"updated_by":"jane.smith@company.com",

"url":"https://kafka.com/12345-updated"

}
