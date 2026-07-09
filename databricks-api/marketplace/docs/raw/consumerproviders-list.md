Title: List providers | Consumer Providers API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/consumerproviders/list

Markdown Content:
## List providers

Public preview

`GET/api/2.1/marketplace-consumer/providers`

List all providers in the Databricks Marketplace with at least one visible listing.

API scopes:[`marketplace`](https://docs.databricks.com/api/workspace/api/scopes#marketplace)

### Query parameters

[`page_token`](https://docs.databricks.com/api/workspace/consumerproviders/list#page_token)string

[`page_size`](https://docs.databricks.com/api/workspace/consumerproviders/list#page_size)int32

[`is_featured`](https://docs.databricks.com/api/workspace/consumerproviders/list#is_featured)boolean

### Responses

**200** Request completed successfully. The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

Request completed successfully.

 The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

[`next_page_token`](https://docs.databricks.com/api/workspace/consumerproviders/list#next_page_token)string

[`providers`](https://docs.databricks.com/api/workspace/consumerproviders/list#providers)Array of object

Array [

[`business_contact_email`](https://docs.databricks.com/api/workspace/consumerproviders/list#providers-business_contact_email)string

[`company_website_link`](https://docs.databricks.com/api/workspace/consumerproviders/list#providers-company_website_link)string

[`dark_mode_icon_file_id`](https://docs.databricks.com/api/workspace/consumerproviders/list#providers-dark_mode_icon_file_id)string

[`dark_mode_icon_file_path`](https://docs.databricks.com/api/workspace/consumerproviders/list#providers-dark_mode_icon_file_path)string

[`description`](https://docs.databricks.com/api/workspace/consumerproviders/list#providers-description)string

[`icon_file_id`](https://docs.databricks.com/api/workspace/consumerproviders/list#providers-icon_file_id)string

[`icon_file_path`](https://docs.databricks.com/api/workspace/consumerproviders/list#providers-icon_file_path)string

[`id`](https://docs.databricks.com/api/workspace/consumerproviders/list#providers-id)string

[`is_featured`](https://docs.databricks.com/api/workspace/consumerproviders/list#providers-is_featured)boolean

is_featured is accessible by consumers only

[`name`](https://docs.databricks.com/api/workspace/consumerproviders/list#providers-name)string

[`privacy_policy_link`](https://docs.databricks.com/api/workspace/consumerproviders/list#providers-privacy_policy_link)string

[`published_by`](https://docs.databricks.com/api/workspace/consumerproviders/list#providers-published_by)string

published_by is only applicable to data aggregators (e.g. Crux)

[`support_contact_email`](https://docs.databricks.com/api/workspace/consumerproviders/list#providers-support_contact_email)string

[`term_of_service_link`](https://docs.databricks.com/api/workspace/consumerproviders/list#providers-term_of_service_link)string

 ]

# Response samples

200

{

"next_page_token":"string",

"providers":[

{

"business_contact_email":"string",

"company_website_link":"string",

"dark_mode_icon_file_id":"string",

"dark_mode_icon_file_path":"string",

"description":"string",

"icon_file_id":"string",

"icon_file_path":"string",

"id":"string",

"is_featured":true,

"name":"string",

"privacy_policy_link":"string",

"published_by":"string",

"support_contact_email":"string",

"term_of_service_link":"string"

}

]

}
