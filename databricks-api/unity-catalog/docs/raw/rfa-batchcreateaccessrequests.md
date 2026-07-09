Title: Create Access Requests | Request for Access API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/rfa/batchcreateaccessrequests

Markdown Content:
## Create Access Requests

Public preview

`POST/api/3.0/rfa/requests`

Creates access requests for Unity Catalog permissions for a specified principal on a securable object. This Batch API can take in multiple principals, securable objects, and permissions as the input and returns the access request destinations for each. Principals must be unique across the API call.

The supported securable types are: "metastore", "catalog", "schema", "table", "external_location", "connection", "credential", "function", "registered_model", and "volume".

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Request body

[`requests`](https://docs.databricks.com/api/workspace/rfa/batchcreateaccessrequests#requests)Array of object

Example

A list of individual access requests, where each request corresponds to a set of permissions being requested on a list of securables for a specified principal.

At most 30 requests per API call.

Array [

[`behalf_of`](https://docs.databricks.com/api/workspace/rfa/batchcreateaccessrequests#requests-behalf_of)object

Optional. The principal this request is for. Empty `behalf_of` defaults to the requester's identity.

Principals must be unique across the API call.

[`comment`](https://docs.databricks.com/api/workspace/rfa/batchcreateaccessrequests#requests-comment)string

Optional. Comment associated with the request.

At most 200 characters, can only contain lowercase/uppercase letters (a-z, A-Z), numbers (0-9), punctuation, and spaces.

[`securable_permissions`](https://docs.databricks.com/api/workspace/rfa/batchcreateaccessrequests#requests-securable_permissions)Array of object

List of securables and their corresponding requested UC privileges.

At most 30 securables can be requested for a principal per batched call. Each securable can only be requested once per principal.

 ]

### Responses

**200** Request completed successfully.

Request completed successfully.

[`responses`](https://docs.databricks.com/api/workspace/rfa/batchcreateaccessrequests#responses)Array of object

Example

The access request destinations for each securable object the principal requested.

Array [

[`behalf_of`](https://docs.databricks.com/api/workspace/rfa/batchcreateaccessrequests#responses-behalf_of)object

The principal the request was made on behalf of.

[`request_destinations`](https://docs.databricks.com/api/workspace/rfa/batchcreateaccessrequests#responses-request_destinations)Array of object

The access request destinations for all the securables the principal requested.

 ]

# Request samples

JSON

{

"requests":[

{

"behalf_of":{

"id":"5617094356186623",

"principal_type":"USER_PRINCIPAL"

},

"comment":"Requesting SELECT on main.custom ers.information table",

"securable_permissions":[

{

"permissions":[

"USE_CATALOG"

],

"securable":{

"full_name":"main",

"type":"CATALOG"

}

},

{

"permissions":[

"USE_SCHEMA"

],

"securable":{

"full_name":"main.customers",

"type":"SCHEMA"

}

},

{

"permissions":[

"SELECT",

"MODIFY"

],

"securable":{

"full_name":"main.customers.informati on",

"type":"TABLE"

}

}

]

},

{

"securable_permissions":[

{

"permissions":[

"USE_SCHEMA"

],

"securable":{

"full_name":"main.orders",

"type":"SCHEMA"

}

}

]

}

]

}

# Response samples

200

{

"responses":[

{

"behalf_of":{

"id":"5617094356186623",

"principal_type":"USER_PRINCIPAL"

},

"request_destinations":[

{

"are_any_destinations_hidden":false,

"destination_source_securable":{

"full_name":"main",

"type":"CATALOG"

},

"destinations":[

{

"destination_id":"john.doe@databric ks.com",

"destination_type":"EMAIL"

}

],

"securable":{

"full_name":"main",

"type":"CATALOG"

}

},

{

"are_any_destinations_hidden":false,

"destination_source_securable":{

"full_name":"main.customers",

"type":"SCHEMA"

},

"destinations":[

{

"destination_id":"456e7890-e89b-12d 3-a456-426614174001",

"destination_type":"SLACK"

}

],

"securable":{

"full_name":"main.customers",

"type":"SCHEMA"

}

},

{

"are_any_destinations_hidden":false,

"destination_source_securable":{

"full_name":"main.customers",

"type":"SCHEMA"

},

"destinations":[

{

"destination_id":"abcde123-e89b-12d 3-a456-426614174003",

"destination_type":"GENERIC_WEBHOOK"

}

],

"securable":{

"full_name":"main.customers.informati on",

"type":"TABLE"

}

}

]

},

{

"behalf_of":{

"id":"7246801356408068",

"principal_type":"USER_PRINCIPAL"

}

}

]

}
