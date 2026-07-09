Title: Install from a listing | Consumer Installations API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/consumerinstallations/create

Markdown Content:
## Install from a listing

Public preview

`POST/api/2.1/marketplace-consumer/listings/{listing_id}/installations`

Install payload associated with a Databricks Marketplace listing.

API scopes:[`marketplace`](https://docs.databricks.com/api/workspace/api/scopes#marketplace)

### Path parameters

[`listing_id`](https://docs.databricks.com/api/workspace/consumerinstallations/create#listing_id)required string

### Request body

[`accepted_consumer_terms`](https://docs.databricks.com/api/workspace/consumerinstallations/create#accepted_consumer_terms)object

[`version`](https://docs.databricks.com/api/workspace/consumerinstallations/create#accepted_consumer_terms-version)required string

[`catalog_name`](https://docs.databricks.com/api/workspace/consumerinstallations/create#catalog_name)string

[`recipient_type`](https://docs.databricks.com/api/workspace/consumerinstallations/create#recipient_type)string

Enum: `DELTA_SHARING_RECIPIENT_TYPE_DATABRICKS | DELTA_SHARING_RECIPIENT_TYPE_OPEN`

[`repo_detail`](https://docs.databricks.com/api/workspace/consumerinstallations/create#repo_detail)object

for git repo installations

[`repo_name`](https://docs.databricks.com/api/workspace/consumerinstallations/create#repo_detail-repo_name)required string

the user-specified repo name for their installed git repo listing

[`repo_path`](https://docs.databricks.com/api/workspace/consumerinstallations/create#repo_detail-repo_path)required string

refers to the full url file path that navigates the user to the repo's entrypoint (e.g. a README.md file, or the repo file view in the unified UI) should just be a relative path

[`share_name`](https://docs.databricks.com/api/workspace/consumerinstallations/create#share_name)string

### Responses

**200** Request completed successfully.

Request completed successfully.

[`installation`](https://docs.databricks.com/api/workspace/consumerinstallations/create#installation)object

[`catalog_name`](https://docs.databricks.com/api/workspace/consumerinstallations/create#installation-catalog_name)string

[`error_message`](https://docs.databricks.com/api/workspace/consumerinstallations/create#installation-error_message)string

[`id`](https://docs.databricks.com/api/workspace/consumerinstallations/create#installation-id)string

[`installed_on`](https://docs.databricks.com/api/workspace/consumerinstallations/create#installation-installed_on)int64

[`listing_id`](https://docs.databricks.com/api/workspace/consumerinstallations/create#installation-listing_id)string

[`listing_name`](https://docs.databricks.com/api/workspace/consumerinstallations/create#installation-listing_name)string

[`recipient_type`](https://docs.databricks.com/api/workspace/consumerinstallations/create#installation-recipient_type)string

Enum: `DELTA_SHARING_RECIPIENT_TYPE_DATABRICKS | DELTA_SHARING_RECIPIENT_TYPE_OPEN`

[`repo_name`](https://docs.databricks.com/api/workspace/consumerinstallations/create#installation-repo_name)string

[`repo_path`](https://docs.databricks.com/api/workspace/consumerinstallations/create#installation-repo_path)string

[`share_name`](https://docs.databricks.com/api/workspace/consumerinstallations/create#installation-share_name)string

[`status`](https://docs.databricks.com/api/workspace/consumerinstallations/create#installation-status)string

Enum: `INSTALLED | FAILED`

[`token_detail`](https://docs.databricks.com/api/workspace/consumerinstallations/create#installation-token_detail)object

[`tokens`](https://docs.databricks.com/api/workspace/consumerinstallations/create#installation-tokens)Array of object

# Request samples

JSON

{

"accepted_consumer_terms":{

"version":"string"

},

"catalog_name":"string",

"recipient_type":"DELTA_SHARING_RECIPIENT_TYPE_ DATABRICKS",

"repo_detail":{

"repo_name":"string",

"repo_path":"string"

},

"share_name":"string"

}

# Response samples

200

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
