Title: Get Access Request Destinations | Request for Access API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/rfa/getaccessrequestdestinations

Markdown Content:
## Get Access Request Destinations

Public preview

`GET/api/3.0/rfa/destinations/{securable_type}/{full_name}`

Gets an array of access request destinations for the specified securable. Any caller can see URL destinations or the destinations on the metastore. Otherwise, only those with BROWSE permissions on the securable can see destinations.

The supported securable types are: "metastore", "catalog", "schema", "table", "external_location", "connection", "credential", "function", "registered_model", and "volume".

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`securable_type`](https://docs.databricks.com/api/workspace/rfa/getaccessrequestdestinations#securable_type)required string

The type of the securable.

[`full_name`](https://docs.databricks.com/api/workspace/rfa/getaccessrequestdestinations#full_name)required string

The full name of the securable.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`are_any_destinations_hidden`](https://docs.databricks.com/api/workspace/rfa/getaccessrequestdestinations#are_any_destinations_hidden)boolean

Example`false`

Indicates whether any destinations are hidden from the caller due to a lack of permissions. This value is true if the caller does not have permission to see all destinations.

[`destination_source_securable`](https://docs.databricks.com/api/workspace/rfa/getaccessrequestdestinations#destination_source_securable)object

Example

The source securable from which the destinations are inherited. Either the same value as securable (if destination is set directly on the securable) or the nearest parent securable with destinations set.

[`full_name`](https://docs.databricks.com/api/workspace/rfa/getaccessrequestdestinations#destination_source_securable-full_name)string

Required. The full name of the catalog/schema/table. Optional if resource_name is present.

[`provider_share`](https://docs.databricks.com/api/workspace/rfa/getaccessrequestdestinations#destination_source_securable-provider_share)string

Optional. The name of the Share object that contains the securable when the securable is getting shared in D2D Delta Sharing.

[`type`](https://docs.databricks.com/api/workspace/rfa/getaccessrequestdestinations#destination_source_securable-type)string

Enum: `CATALOG | SCHEMA | TABLE | STORAGE_CREDENTIAL | EXTERNAL_LOCATION | FUNCTION | SHARE | PROVIDER | RECIPIENT | CLEAN_ROOM | METASTORE | PIPELINE | VOLUME | CONNECTION | CREDENTIAL | EXTERNAL_METADATA | STAGING_TABLE`

Required. The type of securable (catalog/schema/table). Optional if resource_name is present.

[`destinations`](https://docs.databricks.com/api/workspace/rfa/getaccessrequestdestinations#destinations)Array of object

Example

The access request destinations for the securable.

Array [

[`destination_id`](https://docs.databricks.com/api/workspace/rfa/getaccessrequestdestinations#destinations-destination_id)string

Example`"john.doe@databricks.com"`

The identifier for the destination. This is the email address for EMAIL destinations, the URL for URL destinations, or the unique Databricks notification destination ID for all other external destinations.

[`destination_type`](https://docs.databricks.com/api/workspace/rfa/getaccessrequestdestinations#destinations-destination_type)string

Enum: `EMAIL | SLACK | GENERIC_WEBHOOK | MICROSOFT_TEAMS | URL`

Example`"EMAIL"`

The type of the destination.

[`special_destination`](https://docs.databricks.com/api/workspace/rfa/getaccessrequestdestinations#destinations-special_destination)string

Enum: `SPECIAL_DESTINATION_CATALOG_OWNER | SPECIAL_DESTINATION_EXTERNAL_LOCATION_OWNER | SPECIAL_DESTINATION_CONNECTION_OWNER | SPECIAL_DESTINATION_CREDENTIAL_OWNER | SPECIAL_DESTINATION_METASTORE_OWNER`

Example`"SPECIAL_DESTINATION_CATALOG_OWNER"`

This field is used to denote whether the destination is the email of the owner of the securable object. The special destination cannot be assigned to a securable and only represents the default destination of the securable. The securable types that support default special destinations are: "catalog", "external_location", "connection", "credential", and "metastore". The destination_type of a special_destination is always EMAIL.

 ]

[`full_name`](https://docs.databricks.com/api/workspace/rfa/getaccessrequestdestinations#full_name)string

The full name of the securable. Redundant with the name in the securable object, but necessary for Terraform integration

[`securable`](https://docs.databricks.com/api/workspace/rfa/getaccessrequestdestinations#securable)object

Example

The securable for which the access request destinations are being modified or read.

[`full_name`](https://docs.databricks.com/api/workspace/rfa/getaccessrequestdestinations#securable-full_name)string

Required. The full name of the catalog/schema/table. Optional if resource_name is present.

[`provider_share`](https://docs.databricks.com/api/workspace/rfa/getaccessrequestdestinations#securable-provider_share)string

Optional. The name of the Share object that contains the securable when the securable is getting shared in D2D Delta Sharing.

[`type`](https://docs.databricks.com/api/workspace/rfa/getaccessrequestdestinations#securable-type)string

Enum: `CATALOG | SCHEMA | TABLE | STORAGE_CREDENTIAL | EXTERNAL_LOCATION | FUNCTION | SHARE | PROVIDER | RECIPIENT | CLEAN_ROOM | METASTORE | PIPELINE | VOLUME | CONNECTION | CREDENTIAL | EXTERNAL_METADATA | STAGING_TABLE`

Required. The type of securable (catalog/schema/table). Optional if resource_name is present.

[`securable_type`](https://docs.databricks.com/api/workspace/rfa/getaccessrequestdestinations#securable_type)string

The type of the securable. Redundant with the type in the securable object, but necessary for Terraform integration

# Response samples

200

{

"are_any_destinations_hidden":false,

"destination_source_securable":{

"full_name":"string",

"provider_share":"string",

"type":"CATALOG"

},

"destinations":[

{

"destination_id":"john.doe@databricks.com",

"destination_type":"EMAIL"

},

{

"destination_id":"https://www.databricks.co m/",

"destination_type":"URL"

},

{

"destination_id":"456e7890-e89b-12d3-a456-4 26614174001",

"destination_type":"SLACK"

},

{

"destination_id":"789e0123-e89b-12d3-a456-4 26614174002",

"destination_type":"MICROSOFT_TEAMS"

},

{

"destination_id":"abcde123-e89b-12d3-a456-4 26614174003",

"destination_type":"GENERIC_WEBHOOK"

}

],

"full_name":"string",

"securable":{

"full_name":"string",

"provider_share":"string",

"type":"CATALOG"

},

"securable_type":"string"

}
