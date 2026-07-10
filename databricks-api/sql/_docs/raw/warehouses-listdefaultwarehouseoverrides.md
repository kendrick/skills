Title: List default warehouse overrides | SQL Warehouses API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/warehouses/listdefaultwarehouseoverrides

Markdown Content:
## List default warehouse overrides

Beta

`GET/api/warehouses/v1/default-warehouse-overrides`

Lists all default warehouse overrides in the workspace. Only workspace administrators can list all overrides.

API scopes (preview):[`sql`](https://docs.databricks.com/api/workspace/api/scopes#sql)

### Query parameters

[`page_size`](https://docs.databricks.com/api/workspace/warehouses/listdefaultwarehouseoverrides#page_size)int32 Optional

The maximum number of overrides to return. The service may return fewer than this value. If unspecified, at most 100 overrides will be returned. The maximum value is 1000; values above 1000 will be coerced to 1000.

[`page_token`](https://docs.databricks.com/api/workspace/warehouses/listdefaultwarehouseoverrides#page_token)string Optional

A page token, received from a previous `ListDefaultWarehouseOverrides` call. Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to `ListDefaultWarehouseOverrides` must match the call that provided the page token.

### Responses

**200** Request completed successfully. The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

Request completed successfully.

 The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

[`default_warehouse_overrides`](https://docs.databricks.com/api/workspace/warehouses/listdefaultwarehouseoverrides#default_warehouse_overrides)Array of object

The default warehouse overrides in the workspace.

Array [

[`default_warehouse_override_id`](https://docs.databricks.com/api/workspace/warehouses/listdefaultwarehouseoverrides#default_warehouse_overrides-default_warehouse_override_id)string

The ID component of the resource name (user ID).

[`name`](https://docs.databricks.com/api/workspace/warehouses/listdefaultwarehouseoverrides#default_warehouse_overrides-name)string ID Immutable

The resource name of the default warehouse override. Format: default-warehouse-overrides/{default_warehouse_override_id}

[`type`](https://docs.databricks.com/api/workspace/warehouses/listdefaultwarehouseoverrides#default_warehouse_overrides-type)string

Enum: `LAST_SELECTED | CUSTOM`

The type of override behavior.

[`warehouse_id`](https://docs.databricks.com/api/workspace/warehouses/listdefaultwarehouseoverrides#default_warehouse_overrides-warehouse_id)string

The specific warehouse ID when type is CUSTOM. Not set for LAST_SELECTED type.

 ]

[`next_page_token`](https://docs.databricks.com/api/workspace/warehouses/listdefaultwarehouseoverrides#next_page_token)string

A token, which can be sent as `page_token` to retrieve the next page. If this field is omitted, there are no subsequent pages.

# Response samples

200

{

"default_warehouse_overrides":[

{

"default_warehouse_override_id":"string",

"name":"string",

"type":"LAST_SELECTED",

"warehouse_id":"string"

}

],

"next_page_token":"string"

}
