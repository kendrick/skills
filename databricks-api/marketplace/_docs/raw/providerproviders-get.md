Title: Get provider | Provider Providers API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/providerproviders/get

Markdown Content:
## Get provider

Public preview

`GET/api/2.0/marketplace-provider/providers/{id}`

`GET/api/2.1/marketplace-provider/providers/{id}`

Get provider profile

API scopes:[`marketplace`](https://docs.databricks.com/api/workspace/api/scopes#marketplace)

### Path parameters

[`id`](https://docs.databricks.com/api/workspace/providerproviders/get#id)required string

### Responses

**200** Request completed successfully.

Request completed successfully.

[`provider`](https://docs.databricks.com/api/workspace/providerproviders/get#provider)object

[`business_contact_email`](https://docs.databricks.com/api/workspace/providerproviders/get#provider-business_contact_email)string

[`company_website_link`](https://docs.databricks.com/api/workspace/providerproviders/get#provider-company_website_link)string

[`dark_mode_icon_file_id`](https://docs.databricks.com/api/workspace/providerproviders/get#provider-dark_mode_icon_file_id)string

[`dark_mode_icon_file_path`](https://docs.databricks.com/api/workspace/providerproviders/get#provider-dark_mode_icon_file_path)string

[`description`](https://docs.databricks.com/api/workspace/providerproviders/get#provider-description)string

[`icon_file_id`](https://docs.databricks.com/api/workspace/providerproviders/get#provider-icon_file_id)string

[`icon_file_path`](https://docs.databricks.com/api/workspace/providerproviders/get#provider-icon_file_path)string

[`id`](https://docs.databricks.com/api/workspace/providerproviders/get#provider-id)string

[`is_featured`](https://docs.databricks.com/api/workspace/providerproviders/get#provider-is_featured)boolean

is_featured is accessible by consumers only

[`name`](https://docs.databricks.com/api/workspace/providerproviders/get#provider-name)string

[`privacy_policy_link`](https://docs.databricks.com/api/workspace/providerproviders/get#provider-privacy_policy_link)string

[`published_by`](https://docs.databricks.com/api/workspace/providerproviders/get#provider-published_by)string

published_by is only applicable to data aggregators (e.g. Crux)

[`support_contact_email`](https://docs.databricks.com/api/workspace/providerproviders/get#provider-support_contact_email)string

[`term_of_service_link`](https://docs.databricks.com/api/workspace/providerproviders/get#provider-term_of_service_link)string

# Response samples

200

{

"provider":{

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

}
