Title: Delete default warehouse override | SQL Warehouses API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/warehouses/deletedefaultwarehouseoverride

Markdown Content:
## Delete default warehouse override

Beta

`DELETE/api/warehouses/v1/{name=default-warehouse-overrides/*}`

Deletes the default warehouse override for a user. Users can delete their own override. Admins can delete overrides for any user. After deletion, the workspace default warehouse will be used.

API scopes (preview):[`sql`](https://docs.databricks.com/api/workspace/api/scopes#sql)

### Path parameters

[`name`](https://docs.databricks.com/api/workspace/warehouses/deletedefaultwarehouseoverride#name)required string

Required. The resource name of the default warehouse override to delete. Format: default-warehouse-overrides/{default_warehouse_override_id} The default_warehouse_override_id can be a numeric user ID or the literal string "me" for the current user.

### Responses

**200** Request completed successfully.

Request completed successfully.

# Response samples

200

{}
