Title: Update default warehouse override | SQL Warehouses API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/warehouses/updatedefaultwarehouseoverride

Markdown Content:
## Update default warehouse override

Beta

`PATCH/api/warehouses/v1/{default_warehouse_override.name=default-warehouse-overrides/*}`

Updates an existing default warehouse override for a user. Users can update their own override. Admins can update overrides for any user.

API scopes (preview):[`sql`](https://docs.databricks.com/api/workspace/api/scopes#sql)

### Path parameters

[`name`](https://docs.databricks.com/api/workspace/warehouses/updatedefaultwarehouseoverride#name)required string

The resource name of the default warehouse override. Format: default-warehouse-overrides/{default_warehouse_override_id}

### Query parameters

[`update_mask`](https://docs.databricks.com/api/workspace/warehouses/updatedefaultwarehouseoverride#update_mask)string Required

Required. Field mask specifying which fields to update. Only the fields specified in the mask will be updated. Use "*" to update all fields. When allow_missing is true, this field is ignored and all fields are applied.

[`allow_missing`](https://docs.databricks.com/api/workspace/warehouses/updatedefaultwarehouseoverride#allow_missing)boolean Optional

If set to true, and the override is not found, a new override will be created. In this situation, `update_mask` is ignored and all fields are applied. Defaults to false.

### Request body

Represents a per-user default warehouse override configuration. This resource allows users or administrators to customize how a user's default warehouse is selected for SQL operations. If no override exists for a user, the workspace default warehouse will be used.

[`type`](https://docs.databricks.com/api/workspace/warehouses/updatedefaultwarehouseoverride#type)string Required

Enum: `LAST_SELECTED | CUSTOM`

The type of override behavior.

[`warehouse_id`](https://docs.databricks.com/api/workspace/warehouses/updatedefaultwarehouseoverride#warehouse_id)string Optional

The specific warehouse ID when type is CUSTOM. Not set for LAST_SELECTED type.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`default_warehouse_override_id`](https://docs.databricks.com/api/workspace/warehouses/updatedefaultwarehouseoverride#default_warehouse_override_id)string

The ID component of the resource name (user ID).

[`name`](https://docs.databricks.com/api/workspace/warehouses/updatedefaultwarehouseoverride#name)string ID Immutable

The resource name of the default warehouse override. Format: default-warehouse-overrides/{default_warehouse_override_id}

[`type`](https://docs.databricks.com/api/workspace/warehouses/updatedefaultwarehouseoverride#type)string

Enum: `LAST_SELECTED | CUSTOM`

The type of override behavior.

[`warehouse_id`](https://docs.databricks.com/api/workspace/warehouses/updatedefaultwarehouseoverride#warehouse_id)string

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
