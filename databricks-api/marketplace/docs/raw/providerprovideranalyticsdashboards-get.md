Title: Get provider analytics dashboard | Provider Providers Analytics Dashboards API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/providerprovideranalyticsdashboards/get

Markdown Content:
## Get provider analytics dashboard

Public preview

`GET/api/2.0/marketplace-provider/analytics_dashboard`

`GET/api/2.1/marketplace-provider/analytics_dashboard`

Get provider analytics dashboard.

API scopes:[`marketplace`](https://docs.databricks.com/api/workspace/api/scopes#marketplace)

### Responses

**200** Request completed successfully.

Request completed successfully.

[`dashboard_id`](https://docs.databricks.com/api/workspace/providerprovideranalyticsdashboards/get#dashboard_id)string

dashboard_id will be used to open Lakeview dashboard.

[`id`](https://docs.databricks.com/api/workspace/providerprovideranalyticsdashboards/get#id)string

[`version`](https://docs.databricks.com/api/workspace/providerprovideranalyticsdashboards/get#version)int64

# Response samples

200

{

"dashboard_id":"string",

"id":"string",

"version":0

}
