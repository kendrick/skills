Title: Update Access Request Destinations | Request for Access API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/rfa/updateaccessrequestdestinations

Markdown Content:
## Update Access Request Destinations

Public preview

`PATCH/api/3.0/rfa/destinations`

Updates the access request destinations for the given securable. The caller must be a metastore admin, the owner of the securable, or a user that has the MANAGE privilege on the securable in order to assign destinations. Destinations cannot be updated for securables underneath schemas (tables, volumes, functions, and models). For these securable types, destinations are inherited from the parent securable. A maximum of 5 emails and 5 external notification destinations (Slack, Microsoft Teams, and Generic Webhook destinations) can be assigned to a securable. If a URL destination is assigned, no other destinations can be set.

The supported securable types are: "metastore", "catalog", "schema", "table", "external_location", "connection", "credential", "function", "registered_model", and "volume".

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Query parameters

[`update_mask`](https://docs.databricks.com/api/workspace/rfa/updateaccessrequestdestinations#update_mask)required string

The field mask must be a single string, with multiple fields separated by commas (no spaces). The field path is relative to the resource object, using a dot (`.`) to navigate sub-fields (e.g., `author.given_name`). Specification of elements in sequence or map fields is not allowed, as only the entire collection field can be specified. Field names must exactly match the resource field names.

A field mask of `*` indicates full replacement. It’s recommended to always explicitly list the fields being updated and avoid using `*` wildcards, as it can lead to unintended results if the API changes in the future.

### Request body

[`destinations`](https://docs.databricks.com/api/workspace/rfa/updateaccessrequestdestinations#destinations)Array of object Optional

Example

The access request destinations for the securable.

Array [

[`destination_id`](https://docs.databricks.com/api/workspace/rfa/updateaccessrequestdestinations#destinations-destination_id)string Optional

Example`"john.doe@databricks.com"`

The identifier for the destination. This is the email address for EMAIL destinations, the URL for URL destinations, or the unique Databricks notification destination ID for all other external destinations.

[`destination_type`](https://docs.databricks.com/api/workspace/rfa/updateaccessrequestdestinations#destinations-destination_type)string Optional

Enum: `EMAIL | SLACK | GENERIC_WEBHOOK | MICROSOFT_TEAMS | URL`

Example`"EMAIL"`

The type of the destination.

[`special_destination`](https://docs.databricks.com/api/workspace/rfa/updateaccessrequestdestinations#destinations-special_destination)string Optional

Enum: `SPECIAL_DESTINATION_CATALOG_OWNER | SPECIAL_DESTINATION_EXTERNAL_LOCATION_OWNER | SPECIAL_DESTINATION_CONNECTION_OWNER | SPECIAL_DESTINATION_CREDENTIAL_OWNER | SPECIAL_DESTINATION_METASTORE_OWNER`

Example`"SPECIAL_DESTINATION_CATALOG_OWNER"`

This field is used to denote whether the destination is the email of the owner of the securable object. The special destination cannot be assigned to a securable and only represents the default destination of the securable. The securable types that support default special destinations are: "catalog", "external_location", "connection", "credential", and "metastore". The destination_type of a special_destination is always EMAIL.

 ]

[`securable`](https://docs.databricks.com/api/workspace/rfa/updateaccessrequestdestinations#securable)object Required

Example

The securable for which the access request destinations are being modified or read.

[`full_name`](https://docs.databricks.com/api/workspace/rfa/updateaccessrequestdestinations#securable-full_name)string Optional

Required. The full name of the catalog/schema/table. Optional if resource_name is present.

[`provider_share`](https://docs.databricks.com/api/workspace/rfa/updateaccessrequestdestinations#securable-provider_share)string Optional

Optional. The name of the Share object that contains the securable when the securable is getting shared in D2D Delta Sharing.

[`type`](https://docs.databricks.com/api/workspace/rfa/updateaccessrequestdestinations#securable-type)string Optional

Enum: `CATALOG | SCHEMA | TABLE | STORAGE_CREDENTIAL | EXTERNAL_LOCATION | FUNCTION | SHARE | PROVIDER | RECIPIENT | CLEAN_ROOM | METASTORE | PIPELINE | VOLUME | CONNECTION | CREDENTIAL | EXTERNAL_METADATA | STAGING_TABLE`

Required. The type of securable (catalog/schema/table). Optional if resource_name is present.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`are_any_destinations_hidden`](https://docs.databricks.com/api/workspace/rfa/updateaccessrequestdestinations#are_any_destinations_hidden)boolean

Example`false`

Indicates whether any destinations are hidden from the caller due to a lack of permissions. This value is true if the caller does not have permission to see all destinations.

[`destination_source_securable`](https://docs.databricks.com/api/workspace/rfa/updateaccessrequestdestinations#destination_source_securable)object

Example

The source securable from which the destinations are inherited. Either the same value as securable (if destination is set directly on the securable) or the nearest parent securable with destinations set.

[`full_name`](https://docs.databricks.com/api/workspace/rfa/updateaccessrequestdestinations#destination_source_securable-full_name)string

Required. The full name of the catalog/schema/table. Optional if resource_name is present.

[`provider_share`](https://docs.databricks.com/api/workspace/rfa/updateaccessrequestdestinations#destination_source_securable-provider_share)string

Optional. The name of the Share object that contains the securable when the securable is getting shared in D2D Delta Sharing.

[`type`](https://docs.databricks.com/api/workspace/rfa/updateaccessrequestdestinations#destination_source_securable-type)string

Enum: `CATALOG | SCHEMA | TABLE | STORAGE_CREDENTIAL | EXTERNAL_LOCATION | FUNCTION | SHARE | PROVIDER | RECIPIENT | CLEAN_ROOM | METASTORE | PIPELINE | VOLUME | CONNECTION | CREDENTIAL | EXTERNAL_METADATA | STAGING_TABLE`

Required. The type of securable (catalog/schema/table). Optional if resource_name is present.

[`destinations`](https://docs.databricks.com/api/workspace/rfa/updateaccessrequestdestinations#destinations)Array of object

Example

The access request destinations for the securable.

Array [

[`destination_id`](https://docs.databricks.com/api/workspace/rfa/updateaccessrequestdestinations#destinations-destination_id)string

Example`"john.doe@databricks.com"`

The identifier for the destination. This is the email address for EMAIL destinations, the URL for URL destinations, or the unique Databricks notification destination ID for all other external destinations.

[`destination_type`](https://docs.databricks.com/api/workspace/rfa/updateaccessrequestdestinations#destinations-destination_type)string

Enum: `EMAIL | SLACK | GENERIC_WEBHOOK | MICROSOFT_TEAMS | URL`

Example`"EMAIL"`

The type of the destination.

[`special_destination`](https://docs.databricks.com/api/workspace/rfa/updateaccessrequestdestinations#destinations-special_destination)string

Enum: `SPECIAL_DESTINATION_CATALOG_OWNER | SPECIAL_DESTINATION_EXTERNAL_LOCATION_OWNER | SPECIAL_DESTINATION_CONNECTION_OWNER | SPECIAL_DESTINATION_CREDENTIAL_OWNER | SPECIAL_DESTINATION_METASTORE_OWNER`

Example`"SPECIAL_DESTINATION_CATALOG_OWNER"`

This field is used to denote whether the destination is the email of the owner of the securable object. The special destination cannot be assigned to a securable and only represents the default destination of the securable. The securable types that support default special destinations are: "catalog", "external_location", "connection", "credential", and "metastore". The destination_type of a special_destination is always EMAIL.

 ]

[`full_name`](https://docs.databricks.com/api/workspace/rfa/updateaccessrequestdestinations#full_name)string

The full name of the securable. Redundant with the name in the securable object, but necessary for Terraform integration

[`securable`](https://docs.databricks.com/api/workspace/rfa/updateaccessrequestdestinations#securable)object

Example

The securable for which the access request destinations are being modified or read.

[`full_name`](https://docs.databricks.com/api/workspace/rfa/updateaccessrequestdestinations#securable-full_name)string

Required. The full name of the catalog/schema/table. Optional if resource_name is present.

[`provider_share`](https://docs.databricks.com/api/workspace/rfa/updateaccessrequestdestinations#securable-provider_share)string

Optional. The name of the Share object that contains the securable when the securable is getting shared in D2D Delta Sharing.

[`type`](https://docs.databricks.com/api/workspace/rfa/updateaccessrequestdestinations#securable-type)string

Enum: `CATALOG | SCHEMA | TABLE | STORAGE_CREDENTIAL | EXTERNAL_LOCATION | FUNCTION | SHARE | PROVIDER | RECIPIENT | CLEAN_ROOM | METASTORE | PIPELINE | VOLUME | CONNECTION | CREDENTIAL | EXTERNAL_METADATA | STAGING_TABLE`

Required. The type of securable (catalog/schema/table). Optional if resource_name is present.

[`securable_type`](https://docs.databricks.com/api/workspace/rfa/updateaccessrequestdestinations#securable_type)string

The type of the securable. Redundant with the type in the securable object, but necessary for Terraform integration

# Request samples

JSON

{

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

"securable":{

"full_name":"string",

"provider_share":"string",

"type":"CATALOG"

}

}

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
