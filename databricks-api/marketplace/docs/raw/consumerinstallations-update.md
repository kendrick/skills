Title: Update an installation | Consumer Installations API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/consumerinstallations/update

Markdown Content:
## Update an installation

Public preview

`PUT/api/2.1/marketplace-consumer/listings/{listing_id}/installations/{installation_id}`

This is a update API that will update the part of the fields defined in the installation table as well as interact with external services according to the fields not included in the installation table

1.   the token will be rotate if the rotateToken flag is true
2.   the token will be forcibly rotate if the rotateToken flag is true and the tokenInfo field is empty

### Request body

### Responses

**200** Request completed successfully.

Request completed successfully.

## Request samples

{

"installation":{

"catalog_name":"string",

"error_message":"string",

"id":"string",

"installed_on":0,

"listing_id":"string",

"listing_name":"string",

"recipient_type":"DELTA_SHARING_RECIPIENT_TYP E_DATABRICKS",

"repo_name":"string",

"repo_path":"string",

"share_name":"string",

"status":"INSTALLED",

"token_detail":{

"bearerToken":"string",

"endpoint":"string",

"expirationTime":"string",

"shareCredentialsVersion":0

},

"tokens":[

{

"activation_url":"string",

"created_at":0,

"created_by":"string",

"expiration_time":0,

"id":"string",

"updated_at":0,

"updated_by":"string"

}

]

},

"rotate_token":true

}

## Response samples

{

"installation":{

"catalog_name":"string",

"error_message":"string",

"id":"string",

"installed_on":0,

"listing_id":"string",

"listing_name":"string",

"recipient_type":"DELTA_SHARING_RECIPIENT_TYP E_DATABRICKS",

"repo_name":"string",

"repo_path":"string",

"share_name":"string",

"status":"INSTALLED",

"token_detail":{

"bearerToken":"string",

"endpoint":"string",

"expirationTime":"string",

"shareCredentialsVersion":0

},

"tokens":[

{

"activation_url":"string",

"created_at":0,

"created_by":"string",

"expiration_time":0,

"id":"string",

"updated_at":0,

"updated_by":"string"

}

]

}

}
