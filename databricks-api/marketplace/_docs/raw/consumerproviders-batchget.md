Title: Get one batch of providers. One may specify up to 50 IDs per request. | Consumer Providers API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/consumerproviders/batchget

Markdown Content:
## Get one batch of providers. One may specify up to 50 IDs per request.

Public preview

`GET/api/2.1/marketplace-consumer/providers:batchGet`

Batch get a provider in the Databricks Marketplace with at least one visible listing.

API scopes:[`marketplace`](https://docs.databricks.com/api/workspace/api/scopes#marketplace)

### Query parameters

[`ids`](https://docs.databricks.com/api/workspace/consumerproviders/batchget#ids)Array of string

### Responses

**200** Request completed successfully.

Request completed successfully.

[`providers`](https://docs.databricks.com/api/workspace/consumerproviders/batchget#providers)Array of object

Array [

[`business_contact_email`](https://docs.databricks.com/api/workspace/consumerproviders/batchget#providers-business_contact_email)string

[`company_website_link`](https://docs.databricks.com/api/workspace/consumerproviders/batchget#providers-company_website_link)string

[`dark_mode_icon_file_id`](https://docs.databricks.com/api/workspace/consumerproviders/batchget#providers-dark_mode_icon_file_id)string

[`dark_mode_icon_file_path`](https://docs.databricks.com/api/workspace/consumerproviders/batchget#providers-dark_mode_icon_file_path)string

[`description`](https://docs.databricks.com/api/workspace/consumerproviders/batchget#providers-description)string

[`icon_file_id`](https://docs.databricks.com/api/workspace/consumerproviders/batchget#providers-icon_file_id)string

[`icon_file_path`](https://docs.databricks.com/api/workspace/consumerproviders/batchget#providers-icon_file_path)string

[`id`](https://docs.databricks.com/api/workspace/consumerproviders/batchget#providers-id)string

[`is_featured`](https://docs.databricks.com/api/workspace/consumerproviders/batchget#providers-is_featured)boolean

is_featured is accessible by consumers only

[`name`](https://docs.databricks.com/api/workspace/consumerproviders/batchget#providers-name)string

[`privacy_policy_link`](https://docs.databricks.com/api/workspace/consumerproviders/batchget#providers-privacy_policy_link)string

[`published_by`](https://docs.databricks.com/api/workspace/consumerproviders/batchget#providers-published_by)string

published_by is only applicable to data aggregators (e.g. Crux)

[`support_contact_email`](https://docs.databricks.com/api/workspace/consumerproviders/batchget#providers-support_contact_email)string

[`term_of_service_link`](https://docs.databricks.com/api/workspace/consumerproviders/batchget#providers-term_of_service_link)string

 ]

# Response samples

200

{

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
