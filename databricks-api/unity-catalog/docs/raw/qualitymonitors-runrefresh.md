Title: Run refresh | Quality Monitors API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/qualitymonitors/runrefresh

Markdown Content:
## Run refresh

Deprecated

`POST/api/2.1/unity-catalog/tables/{table_name}/monitor/refreshes`

Deprecated: Use Data Quality Monitors API instead (/api/data-quality/v1/monitors). Queues a metric refresh on the monitor for the specified table. The refresh will execute in the background.

The caller must either:

1.   be an owner of the table's parent catalog
2.   have USE_CATALOG on the table's parent catalog and be an owner of the table's parent schema
3.   have the following permissions:

*   USE_CATALOG on the table's parent catalog
*   USE_SCHEMA on the table's parent schema
*   be an owner of the table

Additionally, the call must be made from the workspace where the monitor was created.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`table_name`](https://docs.databricks.com/api/workspace/qualitymonitors/runrefresh#table_name)required string

UC table name in format `catalog.schema.table_name`. table_name is case insensitive and spaces are disallowed.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`end_time_ms`](https://docs.databricks.com/api/workspace/qualitymonitors/runrefresh#end_time_ms)int64

Time at which refresh operation completed (milliseconds since 1/1/1970 UTC).

[`message`](https://docs.databricks.com/api/workspace/qualitymonitors/runrefresh#message)string

An optional message to give insight into the current state of the job (e.g. FAILURE messages).

[`refresh_id`](https://docs.databricks.com/api/workspace/qualitymonitors/runrefresh#refresh_id)int64

Unique id of the refresh operation.

[`start_time_ms`](https://docs.databricks.com/api/workspace/qualitymonitors/runrefresh#start_time_ms)int64

Time at which refresh operation was initiated (milliseconds since 1/1/1970 UTC).

[`state`](https://docs.databricks.com/api/workspace/qualitymonitors/runrefresh#state)string

Enum: `UNKNOWN | PENDING | RUNNING | SUCCESS | FAILED | CANCELED`

The current state of the refresh.

[`trigger`](https://docs.databricks.com/api/workspace/qualitymonitors/runrefresh#trigger)string

Enum: `UNKNOWN_TRIGGER | SCHEDULE | MANUAL`

The method by which the refresh was triggered.

# Response samples

200

{

"end_time_ms":0,

"message":"string",

"refresh_id":0,

"start_time_ms":0,

"state":"UNKNOWN",

"trigger":"UNKNOWN_TRIGGER"

}
