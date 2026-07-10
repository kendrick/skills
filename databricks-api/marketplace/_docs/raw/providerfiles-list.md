Title: List files | Provider Files API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/providerfiles/list

Markdown Content:
## List files

Public preview

`GET/api/2.0/marketplace-provider/files`

`GET/api/2.1/marketplace-provider/files`

List files attached to a parent entity.

API scopes:[`marketplace`](https://docs.databricks.com/api/workspace/api/scopes#marketplace)

### Query parameters

[`file_parent`](https://docs.databricks.com/api/workspace/providerfiles/list#file_parent)required object

[`file_parent_type`](https://docs.databricks.com/api/workspace/providerfiles/list#file_parent-file_parent_type)string

Enum: `PROVIDER | LISTING | LISTING_RESOURCE`

[`parent_id`](https://docs.databricks.com/api/workspace/providerfiles/list#file_parent-parent_id)string

TODO make the following fields required

[`page_token`](https://docs.databricks.com/api/workspace/providerfiles/list#page_token)string

[`page_size`](https://docs.databricks.com/api/workspace/providerfiles/list#page_size)int32

### Responses

**200** Request completed successfully. The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

Request completed successfully.

 The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

[`file_infos`](https://docs.databricks.com/api/workspace/providerfiles/list#file_infos)Array of object

Array [

[`created_at`](https://docs.databricks.com/api/workspace/providerfiles/list#file_infos-created_at)int64

[`display_name`](https://docs.databricks.com/api/workspace/providerfiles/list#file_infos-display_name)string

Name displayed to users for applicable files, e.g. embedded notebooks

[`download_link`](https://docs.databricks.com/api/workspace/providerfiles/list#file_infos-download_link)string

[`file_parent`](https://docs.databricks.com/api/workspace/providerfiles/list#file_infos-file_parent)object

[`id`](https://docs.databricks.com/api/workspace/providerfiles/list#file_infos-id)string

[`marketplace_file_type`](https://docs.databricks.com/api/workspace/providerfiles/list#file_infos-marketplace_file_type)string

Enum: `PROVIDER_ICON | EMBEDDED_NOTEBOOK | APP`

[`mime_type`](https://docs.databricks.com/api/workspace/providerfiles/list#file_infos-mime_type)string

[`status`](https://docs.databricks.com/api/workspace/providerfiles/list#file_infos-status)string

Enum: `FILE_STATUS_PUBLISHED | FILE_STATUS_STAGING | FILE_STATUS_SANITIZING | FILE_STATUS_SANITIZATION_FAILED`

[`status_message`](https://docs.databricks.com/api/workspace/providerfiles/list#file_infos-status_message)string

Populated if status is in a failed state with more information on reason for the failure.

[`updated_at`](https://docs.databricks.com/api/workspace/providerfiles/list#file_infos-updated_at)int64

 ]

[`next_page_token`](https://docs.databricks.com/api/workspace/providerfiles/list#next_page_token)string

# Response samples

200

{

"file_infos":[

{

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

}

],

"next_page_token":"string"

}
