Title: Create a file | Provider Files API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/providerfiles/create

Markdown Content:
## Create a file

Public preview

`POST/api/2.0/marketplace-provider/files`

`POST/api/2.1/marketplace-provider/files`

Create a file. Currently, only provider icons and attached notebooks are supported.

API scopes:[`marketplace`](https://docs.databricks.com/api/workspace/api/scopes#marketplace)

### Request body

[`display_name`](https://docs.databricks.com/api/workspace/providerfiles/create#display_name)string

[`file_parent`](https://docs.databricks.com/api/workspace/providerfiles/create#file_parent)required object

[`file_parent_type`](https://docs.databricks.com/api/workspace/providerfiles/create#file_parent-file_parent_type)string

Enum: `PROVIDER | LISTING | LISTING_RESOURCE`

[`parent_id`](https://docs.databricks.com/api/workspace/providerfiles/create#file_parent-parent_id)string

TODO make the following fields required

[`marketplace_file_type`](https://docs.databricks.com/api/workspace/providerfiles/create#marketplace_file_type)required string

Enum: `PROVIDER_ICON | EMBEDDED_NOTEBOOK | APP`

[`mime_type`](https://docs.databricks.com/api/workspace/providerfiles/create#mime_type)required string

### Responses

**200** Request completed successfully.

Request completed successfully.

[`file_info`](https://docs.databricks.com/api/workspace/providerfiles/create#file_info)object

[`created_at`](https://docs.databricks.com/api/workspace/providerfiles/create#file_info-created_at)int64

[`display_name`](https://docs.databricks.com/api/workspace/providerfiles/create#file_info-display_name)string

Name displayed to users for applicable files, e.g. embedded notebooks

[`download_link`](https://docs.databricks.com/api/workspace/providerfiles/create#file_info-download_link)string

[`file_parent`](https://docs.databricks.com/api/workspace/providerfiles/create#file_info-file_parent)object

[`id`](https://docs.databricks.com/api/workspace/providerfiles/create#file_info-id)string

[`marketplace_file_type`](https://docs.databricks.com/api/workspace/providerfiles/create#file_info-marketplace_file_type)string

Enum: `PROVIDER_ICON | EMBEDDED_NOTEBOOK | APP`

[`mime_type`](https://docs.databricks.com/api/workspace/providerfiles/create#file_info-mime_type)string

[`status`](https://docs.databricks.com/api/workspace/providerfiles/create#file_info-status)string

Enum: `FILE_STATUS_PUBLISHED | FILE_STATUS_STAGING | FILE_STATUS_SANITIZING | FILE_STATUS_SANITIZATION_FAILED`

[`status_message`](https://docs.databricks.com/api/workspace/providerfiles/create#file_info-status_message)string

Populated if status is in a failed state with more information on reason for the failure.

[`updated_at`](https://docs.databricks.com/api/workspace/providerfiles/create#file_info-updated_at)int64

[`upload_url`](https://docs.databricks.com/api/workspace/providerfiles/create#upload_url)string

Pre-signed POST URL to blob storage

# Request samples

JSON

{

"display_name":"string",

"file_parent":{

"file_parent_type":"PROVIDER",

"parent_id":"string"

},

"marketplace_file_type":"PROVIDER_ICON",

"mime_type":"string"

}

# Response samples

200

{

"file_info":{

"created_at":0,

"display_name":"string",

"download_link":"string",

"file_parent":{

"file_parent_type":"PROVIDER",

"parent_id":"string"

},

"id":"string",

"marketplace_file_type":"PROVIDER_ICON",

"mime_type":"string",

"status":"FILE_STATUS_PUBLISHED",

"status_message":"string",

"updated_at":0

},

"upload_url":"string"

}
