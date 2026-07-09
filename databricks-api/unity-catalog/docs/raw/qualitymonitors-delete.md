Title: Delete a table monitor | Quality Monitors API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/qualitymonitors/delete

Markdown Content:
## Delete a table monitor

Deprecated

`DELETE/api/2.1/unity-catalog/tables/{table_name}/monitor`

Deprecated: Use Data Quality Monitors API instead (/api/data-quality/v1/monitors). Deletes a monitor for the specified table.

The caller must either:

1.   be an owner of the table's parent catalog
2.   have USE_CATALOG on the table's parent catalog and be an owner of the table's parent schema
3.   have the following permissions:

*   USE_CATALOG on the table's parent catalog
*   USE_SCHEMA on the table's parent schema
*   be an owner of the table.

Additionally, the call must be made from the workspace where the monitor was created.

Note that the metric tables and dashboard will not be deleted as part of this call; those assets must be manually cleaned up (if desired).

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`table_name`](https://docs.databricks.com/api/workspace/qualitymonitors/delete#table_name)required string

UC table name in format `catalog.schema.table_name`. This field corresponds to the {full_table_name_arg} arg in the endpoint path.

### Responses

**200** Request completed successfully.

Request completed successfully.

# Response samples

200

{}
