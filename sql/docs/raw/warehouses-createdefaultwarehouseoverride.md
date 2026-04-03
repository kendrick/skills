Title: Create default warehouse override | SQL Warehouses API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/warehouses/createdefaultwarehouseoverride

Markdown Content:
## Create default warehouse override

Beta

`POST/api/warehouses/v1/default-warehouse-overrides`

Creates a new default warehouse override for a user. Users can create their own override. Admins can create overrides for any user.

API scopes (preview):[`sql`](https://docs.databricks.com/api/workspace/api/scopes#sql)

### Query parameters

[`default_warehouse_override_id`](https://docs.databricks.com/api/workspace/warehouses/createdefaultwarehouseoverride#default_warehouse_override_id)string Required

Required. The ID to use for the override, which will become the final component of the override's resource name. Can be a numeric user ID or the literal string "me" for the current user.

### Request body

Represents a per-user default warehouse override configuration. This resource allows users or administrators to customize how a user's default warehouse is selected for SQL operations. If no override exists for a user, the workspace default warehouse will be used.

[`type`](https://docs.databricks.com/api/workspace/warehouses/createdefaultwarehouseoverride#type)string Required

Enum: `LAST_SELECTED | CUSTOM`

The type of override behavior.

[`warehouse_id`](https://docs.databricks.com/api/workspace/warehouses/createdefaultwarehouseoverride#warehouse_id)string Optional

The specific warehouse ID when type is CUSTOM. Not set for LAST_SELECTED type.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`default_warehouse_override_id`](https://docs.databricks.com/api/workspace/warehouses/createdefaultwarehouseoverride#default_warehouse_override_id)string

The ID component of the resource name (user ID).

[`name`](https://docs.databricks.com/api/workspace/warehouses/createdefaultwarehouseoverride#name)string ID Immutable

The resource name of the default warehouse override. Format: default-warehouse-overrides/{default_warehouse_override_id}

[`type`](https://docs.databricks.com/api/workspace/warehouses/createdefaultwarehouseoverride#type)string

Enum: `LAST_SELECTED | CUSTOM`

The type of override behavior.

[`warehouse_id`](https://docs.databricks.com/api/workspace/warehouses/createdefaultwarehouseoverride#warehouse_id)string

The specific warehouse ID when type is CUSTOM. Not set for LAST_SELECTED type.

# Request samples

JSON

{

"type":"LAST_SELECTED",

"warehouse_id":"string"

}

# Response samples

200

{

"default_warehouse_override_id":"string",

"name":"string",

"type":"LAST_SELECTED",

"warehouse_id":"string"

}
