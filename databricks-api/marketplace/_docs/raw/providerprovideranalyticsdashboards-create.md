Title: Create provider analytics dashboard | Provider Providers Analytics Dashboards API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/providerprovideranalyticsdashboards/create

Markdown Content:
## Create provider analytics dashboard

Public preview

`POST/api/2.0/marketplace-provider/analytics_dashboard`

`POST/api/2.1/marketplace-provider/analytics_dashboard`

Create provider analytics dashboard. Returns Marketplace specific `id`. Not to be confused with the Lakeview dashboard id.

API scopes:[`marketplace`](https://docs.databricks.com/api/workspace/api/scopes#marketplace)

### Responses

**200** Request completed successfully.

Request completed successfully.

[`id`](https://docs.databricks.com/api/workspace/providerprovideranalyticsdashboards/create#id)string

# Request samples

JSON

{}

# Response samples

200

{

"id":"string"

}
