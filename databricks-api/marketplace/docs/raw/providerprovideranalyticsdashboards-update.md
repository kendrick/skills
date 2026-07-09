Title: Update provider analytics dashboard | Provider Providers Analytics Dashboards API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/providerprovideranalyticsdashboards/update

Markdown Content:
## Update provider analytics dashboard

Public preview

`PUT/api/2.0/marketplace-provider/analytics_dashboard/{id}`

`PUT/api/2.1/marketplace-provider/analytics_dashboard/{id}`

Update provider analytics dashboard.

API scopes:[`marketplace`](https://docs.databricks.com/api/workspace/api/scopes#marketplace)

### Path parameters

[`id`](https://docs.databricks.com/api/workspace/providerprovideranalyticsdashboards/update#id)required string

id is immutable property and can't be updated.

### Request body

[`version`](https://docs.databricks.com/api/workspace/providerprovideranalyticsdashboards/update#version)int64

this is the version of the dashboard template we want to update our user to current expectation is that it should be equal to latest version of the dashboard template

### Responses

**200** Request completed successfully.

Request completed successfully.

[`dashboard_id`](https://docs.databricks.com/api/workspace/providerprovideranalyticsdashboards/update#dashboard_id)string

this is newly created Lakeview dashboard for the user

[`id`](https://docs.databricks.com/api/workspace/providerprovideranalyticsdashboards/update#id)string

id & version should be the same as the request

[`version`](https://docs.databricks.com/api/workspace/providerprovideranalyticsdashboards/update#version)int64

# Request samples

JSON

{

"version":0

}

# Response samples

200

{

"dashboard_id":"string",

"id":"string",

"version":0

}
