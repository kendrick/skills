Title: Create a provider | Provider Providers API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/providerproviders/create

Markdown Content:
## Create a provider

Public preview

`POST/api/2.0/marketplace-provider/provider`

`POST/api/2.1/marketplace-provider/provider`

Create a provider

API scopes:[`marketplace`](https://docs.databricks.com/api/workspace/api/scopes#marketplace)

### Request body

[`provider`](https://docs.databricks.com/api/workspace/providerproviders/create#provider)object

[`business_contact_email`](https://docs.databricks.com/api/workspace/providerproviders/create#provider-business_contact_email)required string

[`company_website_link`](https://docs.databricks.com/api/workspace/providerproviders/create#provider-company_website_link)string

[`dark_mode_icon_file_id`](https://docs.databricks.com/api/workspace/providerproviders/create#provider-dark_mode_icon_file_id)string

[`dark_mode_icon_file_path`](https://docs.databricks.com/api/workspace/providerproviders/create#provider-dark_mode_icon_file_path)string

[`description`](https://docs.databricks.com/api/workspace/providerproviders/create#provider-description)string

[`icon_file_id`](https://docs.databricks.com/api/workspace/providerproviders/create#provider-icon_file_id)string

[`icon_file_path`](https://docs.databricks.com/api/workspace/providerproviders/create#provider-icon_file_path)string

[`id`](https://docs.databricks.com/api/workspace/providerproviders/create#provider-id)string

[`is_featured`](https://docs.databricks.com/api/workspace/providerproviders/create#provider-is_featured)boolean

is_featured is accessible by consumers only

[`name`](https://docs.databricks.com/api/workspace/providerproviders/create#provider-name)required string

[`privacy_policy_link`](https://docs.databricks.com/api/workspace/providerproviders/create#provider-privacy_policy_link)required string

[`published_by`](https://docs.databricks.com/api/workspace/providerproviders/create#provider-published_by)string

published_by is only applicable to data aggregators (e.g. Crux)

[`support_contact_email`](https://docs.databricks.com/api/workspace/providerproviders/create#provider-support_contact_email)string

[`term_of_service_link`](https://docs.databricks.com/api/workspace/providerproviders/create#provider-term_of_service_link)required string

### Responses

**200** Request completed successfully.

Request completed successfully.

[`id`](https://docs.databricks.com/api/workspace/providerproviders/create#id)string

# Request samples

JSON

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

# Response samples

200

{

"id":"string"

}
