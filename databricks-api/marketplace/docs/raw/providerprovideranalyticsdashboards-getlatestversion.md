Title: Get latest version of provider analytics dashboard | Provider Providers Analytics Dashboards API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/providerprovideranalyticsdashboards/getlatestversion

Markdown Content:
## Get latest version of provider analytics dashboard

Public preview

`GET/api/2.0/marketplace-provider/analytics_dashboard/latest`

`GET/api/2.1/marketplace-provider/analytics_dashboard/latest`

Get latest version of provider analytics dashboard.

API scopes:[`marketplace`](https://docs.databricks.com/api/workspace/api/scopes#marketplace)

### Responses

**200** Request completed successfully.

Request completed successfully.

[`version`](https://docs.databricks.com/api/workspace/providerprovideranalyticsdashboards/getlatestversion#version)int64

version here is latest logical version of the dashboard template

# Response samples

200

{

"version":0

}
