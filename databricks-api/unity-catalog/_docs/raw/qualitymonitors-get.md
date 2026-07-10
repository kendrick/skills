Title: Get a table monitor | Quality Monitors API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/qualitymonitors/get

Markdown Content:
## Get a table monitor

Deprecated

`GET/api/2.1/unity-catalog/tables/{table_name}/monitor`

Deprecated: Use Data Quality Monitors API instead (/api/data-quality/v1/monitors). Gets a monitor for the specified table.

The caller must either:

1.   be an owner of the table's parent catalog
2.   have USE_CATALOG on the table's parent catalog and be an owner of the table's parent schema.
3.   have the following permissions:

*   USE_CATALOG on the table's parent catalog
*   USE_SCHEMA on the table's parent schema
*   SELECT privilege on the table.

The returned information includes configuration values, as well as information on assets created by the monitor. Some information (e.g., dashboard) may be filtered out if the caller is in a different workspace than where the monitor was created.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`table_name`](https://docs.databricks.com/api/workspace/qualitymonitors/get#table_name)required string

UC table name in format `catalog.schema.table_name`. This field corresponds to the {full_table_name_arg} arg in the endpoint path.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`assets_dir`](https://docs.databricks.com/api/workspace/qualitymonitors/get#assets_dir)string

[Create:REQ Update:IGN] Field for specifying the absolute path to a custom directory to store data-monitoring assets. Normally prepopulated to a default user location via UI and Python APIs.

[`baseline_table_name`](https://docs.databricks.com/api/workspace/qualitymonitors/get#baseline_table_name)string

[Create:OPT Update:OPT] Baseline table name. Baseline data is used to compute drift from the data in the monitored `table_name`. The baseline table and the monitored table shall have the same schema.

[`custom_metrics`](https://docs.databricks.com/api/workspace/qualitymonitors/get#custom_metrics)Array of object

[Create:OPT Update:OPT] Custom metrics.

Array [

[`definition`](https://docs.databricks.com/api/workspace/qualitymonitors/get#custom_metrics-definition)string

Jinja template for a SQL expression that specifies how to compute the metric. See [create metric definition](https://docs.databricks.com/en/lakehouse-monitoring/custom-metrics.html#create-definition).

[`input_columns`](https://docs.databricks.com/api/workspace/qualitymonitors/get#custom_metrics-input_columns)Array of string

A list of column names in the input table the metric should be computed for. Can use `":table"` to indicate that the metric needs information from multiple columns.

[`name`](https://docs.databricks.com/api/workspace/qualitymonitors/get#custom_metrics-name)string

Name of the metric in the output tables.

[`output_data_type`](https://docs.databricks.com/api/workspace/qualitymonitors/get#custom_metrics-output_data_type)string

The output type of the custom metric.

[`type`](https://docs.databricks.com/api/workspace/qualitymonitors/get#custom_metrics-type)string

Enum: `CUSTOM_METRIC_TYPE_AGGREGATE | CUSTOM_METRIC_TYPE_DERIVED | CUSTOM_METRIC_TYPE_DRIFT`

Can only be one of `"CUSTOM_METRIC_TYPE_AGGREGATE"`, `"CUSTOM_METRIC_TYPE_DERIVED"`, or `"CUSTOM_METRIC_TYPE_DRIFT"`. The `"CUSTOM_METRIC_TYPE_AGGREGATE"` and `"CUSTOM_METRIC_TYPE_DERIVED"` metrics are computed on a single table, whereas the `"CUSTOM_METRIC_TYPE_DRIFT"` compare metrics across baseline and input table, or across the two consecutive time windows.

*   CUSTOM_METRIC_TYPE_AGGREGATE: only depend on the existing columns in your table
*   CUSTOM_METRIC_TYPE_DERIVED: depend on previously computed aggregate metrics
*   CUSTOM_METRIC_TYPE_DRIFT: depend on previously computed aggregate or derived metrics

 ]

[`dashboard_id`](https://docs.databricks.com/api/workspace/qualitymonitors/get#dashboard_id)string

[Create:ERR Update:OPT] Id of dashboard that visualizes the computed metrics. This can be empty if the monitor is in PENDING state.

[`drift_metrics_table_name`](https://docs.databricks.com/api/workspace/qualitymonitors/get#drift_metrics_table_name)string

[Create:ERR Update:IGN] Table that stores drift metrics data. Format: `catalog.schema.table_name`.

[`inference_log`](https://docs.databricks.com/api/workspace/qualitymonitors/get#inference_log)object

[`granularities`](https://docs.databricks.com/api/workspace/qualitymonitors/get#inference_log-granularities)Array of string

List of granularities to use when aggregating data into time windows based on their timestamp.

[`label_col`](https://docs.databricks.com/api/workspace/qualitymonitors/get#inference_log-label_col)string

Column for the label.

[`model_id_col`](https://docs.databricks.com/api/workspace/qualitymonitors/get#inference_log-model_id_col)string

Column for the model identifier.

[`prediction_col`](https://docs.databricks.com/api/workspace/qualitymonitors/get#inference_log-prediction_col)string

Column for the prediction.

[`prediction_proba_col`](https://docs.databricks.com/api/workspace/qualitymonitors/get#inference_log-prediction_proba_col)string

Column for prediction probabilities

[`problem_type`](https://docs.databricks.com/api/workspace/qualitymonitors/get#inference_log-problem_type)string

Enum: `PROBLEM_TYPE_CLASSIFICATION | PROBLEM_TYPE_REGRESSION`

Problem type the model aims to solve.

[`timestamp_col`](https://docs.databricks.com/api/workspace/qualitymonitors/get#inference_log-timestamp_col)string

Column for the timestamp.

[`latest_monitor_failure_msg`](https://docs.databricks.com/api/workspace/qualitymonitors/get#latest_monitor_failure_msg)string

[Create:ERR Update:IGN] The latest error message for a monitor failure.

[`monitor_version`](https://docs.databricks.com/api/workspace/qualitymonitors/get#monitor_version)int64

[Create:ERR Update:IGN] Represents the current monitor configuration version in use. The version will be represented in a numeric fashion (1,2,3...). The field has flexibility to take on negative values, which can indicate corrupted monitor_version numbers.

[`notifications`](https://docs.databricks.com/api/workspace/qualitymonitors/get#notifications)object

[Create:OPT Update:OPT] Field for specifying notification settings.

[`on_failure`](https://docs.databricks.com/api/workspace/qualitymonitors/get#notifications-on_failure)object

Destinations to send notifications on failure/timeout.

[`output_schema_name`](https://docs.databricks.com/api/workspace/qualitymonitors/get#output_schema_name)string

[Create:REQ Update:REQ] Schema where output tables are created. Needs to be in 2-level format {catalog}.{schema}

[`profile_metrics_table_name`](https://docs.databricks.com/api/workspace/qualitymonitors/get#profile_metrics_table_name)string

[Create:ERR Update:IGN] Table that stores profile metrics data. Format: `catalog.schema.table_name`.

[`schedule`](https://docs.databricks.com/api/workspace/qualitymonitors/get#schedule)object

[Create:OPT Update:OPT] The monitor schedule.

[`pause_status`](https://docs.databricks.com/api/workspace/qualitymonitors/get#schedule-pause_status)string

Enum: `UNSPECIFIED | UNPAUSED | PAUSED`

Read only field that indicates whether a schedule is paused or not.

[`quartz_cron_expression`](https://docs.databricks.com/api/workspace/qualitymonitors/get#schedule-quartz_cron_expression)string

The expression that determines when to run the monitor. See [examples](https://www.quartz-scheduler.org/documentation/quartz-2.3.0/tutorials/crontrigger.html).

[`timezone_id`](https://docs.databricks.com/api/workspace/qualitymonitors/get#schedule-timezone_id)string

The timezone id (e.g., `PST`) in which to evaluate the quartz expression.

[`slicing_exprs`](https://docs.databricks.com/api/workspace/qualitymonitors/get#slicing_exprs)Array of string

[Create:OPT Update:OPT] List of column expressions to slice data with for targeted analysis. The data is grouped by each expression independently, resulting in a separate slice for each predicate and its complements. For example `slicing_exprs=[“col_1”, “col_2 > 10”]` will generate the following slices: two slices for `col_2 > 10` (True and False), and one slice per unique value in `col1`. For high-cardinality columns, only the top 100 unique values by frequency will generate slices.

[`snapshot`](https://docs.databricks.com/api/workspace/qualitymonitors/get#snapshot)object

Configuration for monitoring snapshot tables.

[`status`](https://docs.databricks.com/api/workspace/qualitymonitors/get#status)string

Enum: `MONITOR_STATUS_ACTIVE | MONITOR_STATUS_PENDING | MONITOR_STATUS_DELETE_PENDING | MONITOR_STATUS_ERROR | MONITOR_STATUS_FAILED`

[Create:ERR Update:IGN] The monitor status.

[`table_name`](https://docs.databricks.com/api/workspace/qualitymonitors/get#table_name)string

[Create:ERR Update:IGN] UC table to monitor. Format: `catalog.schema.table_name`

[`time_series`](https://docs.databricks.com/api/workspace/qualitymonitors/get#time_series)object

Configuration for monitoring time series tables.

[`granularities`](https://docs.databricks.com/api/workspace/qualitymonitors/get#time_series-granularities)Array of string

Granularities for aggregating data into time windows based on their timestamp. Currently the following static granularities are supported: {`\"5 minutes\"`, `\"30 minutes\"`, `\"1 hour\"`, `\"1 day\"`, `\"\u003cn\u003e week(s)\"`, `\"1 month\"`, `\"1 year\"`}.

[`timestamp_col`](https://docs.databricks.com/api/workspace/qualitymonitors/get#time_series-timestamp_col)string

Column for the timestamp.

# Response samples

200

{

"assets_dir":"string",

"baseline_table_name":"string",

"custom_metrics":[

{

"definition":"string",

"input_columns":[

"string"

],

"name":"string",

"output_data_type":"string",

"type":"CUSTOM_METRIC_TYPE_AGGREGATE"

}

],

"dashboard_id":"string",

"drift_metrics_table_name":"string",

"inference_log":{

"granularities":[

"string"

],

"label_col":"string",

"model_id_col":"string",

"prediction_col":"string",

"prediction_proba_col":"string",

"problem_type":"PROBLEM_TYPE_CLASSIFICATION",

"timestamp_col":"string"

},

"latest_monitor_failure_msg":"string",

"monitor_version":0,

"notifications":{

"on_failure":{

"email_addresses":[

"string"

]

}

},

"output_schema_name":"string",

"profile_metrics_table_name":"string",

"schedule":{

"pause_status":"UNSPECIFIED",

"quartz_cron_expression":"string",

"timezone_id":"string"

},

"slicing_exprs":[

"string"

],

"snapshot":{},

"status":"MONITOR_STATUS_ACTIVE",

"table_name":"string",

"time_series":{

"granularities":[

"string"

],

"timestamp_col":"string"

}

}
