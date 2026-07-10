Title: Get warehouse info | SQL Warehouses API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/warehouses/get

Markdown Content:
## Get warehouse info

`GET/api/2.0/sql/warehouses/{id}`

Gets the information for a single SQL warehouse.

API scopes (preview):[`sql`](https://docs.databricks.com/api/workspace/api/scopes#sql)

### Path parameters

[`id`](https://docs.databricks.com/api/workspace/warehouses/get#id)required string

Required. Id of the SQL warehouse.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`auto_stop_mins`](https://docs.databricks.com/api/workspace/warehouses/get#auto_stop_mins)int32

Default`120`

The amount of time in minutes that a SQL warehouse must be idle (i.e., no RUNNING queries) before it is automatically stopped.

Supported values:

*   Must be == 0 or >= 10 mins
*   0 indicates no autostop.

Defaults to 120 mins

[`channel`](https://docs.databricks.com/api/workspace/warehouses/get#channel)object

Channel Details

[`dbsql_version`](https://docs.databricks.com/api/workspace/warehouses/get#channel-dbsql_version)string

[`name`](https://docs.databricks.com/api/workspace/warehouses/get#channel-name)string

Enum: `CHANNEL_NAME_PREVIEW | CHANNEL_NAME_CURRENT | CHANNEL_NAME_PREVIOUS | CHANNEL_NAME_CUSTOM`

[`cluster_size`](https://docs.databricks.com/api/workspace/warehouses/get#cluster_size)string

Size of the clusters allocated for this warehouse. Increasing the size of a spark cluster allows you to run larger queries on it. If you want to increase the number of concurrent queries, please tune max_num_clusters.

Supported values:

*   2X-Small
*   X-Small
*   Small
*   Medium
*   Large
*   X-Large
*   2X-Large
*   3X-Large
*   4X-Large
*   5X-Large

[`creator_name`](https://docs.databricks.com/api/workspace/warehouses/get#creator_name)string

warehouse creator name

[`enable_photon`](https://docs.databricks.com/api/workspace/warehouses/get#enable_photon)boolean

Configures whether the warehouse should use Photon optimized clusters.

Defaults to true.

[`enable_serverless_compute`](https://docs.databricks.com/api/workspace/warehouses/get#enable_serverless_compute)boolean

Configures whether the warehouse should use serverless compute

[`health`](https://docs.databricks.com/api/workspace/warehouses/get#health)object

Optional health status. Assume the warehouse is healthy if this field is not set.

[`details`](https://docs.databricks.com/api/workspace/warehouses/get#health-details)string

Details about errors that are causing current degraded/failed status.

[`failure_reason`](https://docs.databricks.com/api/workspace/warehouses/get#health-failure_reason)object

The reason for failure to bring up clusters for this warehouse. This is available when status is 'FAILED' and sometimes when it is DEGRADED.

[`message`](https://docs.databricks.com/api/workspace/warehouses/get#health-message)string

Deprecated

Deprecated. split into summary and details for security

[`status`](https://docs.databricks.com/api/workspace/warehouses/get#health-status)string

Enum: `HEALTHY | DEGRADED | FAILED`

Health status of the endpoint.

[`summary`](https://docs.databricks.com/api/workspace/warehouses/get#health-summary)string

A short summary of the health status in case of degraded/failed warehouses.

[`id`](https://docs.databricks.com/api/workspace/warehouses/get#id)string

unique identifier for warehouse

[`instance_profile_arn`](https://docs.databricks.com/api/workspace/warehouses/get#instance_profile_arn)string

Deprecated

Deprecated. Instance profile used to pass IAM role to the cluster

[`jdbc_url`](https://docs.databricks.com/api/workspace/warehouses/get#jdbc_url)string

the jdbc connection string for this warehouse

[`max_num_clusters`](https://docs.databricks.com/api/workspace/warehouses/get#max_num_clusters)int32

Maximum number of clusters that the autoscaler will create to handle concurrent queries.

Supported values:

*   Must be >= min_num_clusters
*   Must be <= 40.

Defaults to min_clusters if unset.

[`min_num_clusters`](https://docs.databricks.com/api/workspace/warehouses/get#min_num_clusters)int32

Default`1`

Minimum number of available clusters that will be maintained for this SQL warehouse. Increasing this will ensure that a larger number of clusters are always running and therefore may reduce the cold start time for new queries. This is similar to reserved vs. revocable cores in a resource manager.

Supported values:

*   Must be > 0
*   Must be <= min(max_num_clusters, 30)

Defaults to 1

[`name`](https://docs.databricks.com/api/workspace/warehouses/get#name)string

Logical name for the cluster.

Supported values:

*   Must be unique within an org.
*   Must be less than 100 characters.

[`num_active_sessions`](https://docs.databricks.com/api/workspace/warehouses/get#num_active_sessions)int64

Deprecated

Deprecated. current number of active sessions for the warehouse

[`num_clusters`](https://docs.databricks.com/api/workspace/warehouses/get#num_clusters)int32

current number of clusters running for the service

[`odbc_params`](https://docs.databricks.com/api/workspace/warehouses/get#odbc_params)object

ODBC parameters for the SQL warehouse

[`hostname`](https://docs.databricks.com/api/workspace/warehouses/get#odbc_params-hostname)string

[`path`](https://docs.databricks.com/api/workspace/warehouses/get#odbc_params-path)string

[`port`](https://docs.databricks.com/api/workspace/warehouses/get#odbc_params-port)int32

[`protocol`](https://docs.databricks.com/api/workspace/warehouses/get#odbc_params-protocol)string

[`spot_instance_policy`](https://docs.databricks.com/api/workspace/warehouses/get#spot_instance_policy)string

Enum: `POLICY_UNSPECIFIED | COST_OPTIMIZED | RELIABILITY_OPTIMIZED`

Default`"COST_OPTIMIZED"`

Configurations whether the endpoint should use spot instances.

[`state`](https://docs.databricks.com/api/workspace/warehouses/get#state)string

Enum: `STARTING | RUNNING | STOPPING | STOPPED | DELETING | DELETED`

state of the endpoint

[`tags`](https://docs.databricks.com/api/workspace/warehouses/get#tags)object

A set of key-value pairs that will be tagged on all resources (e.g., AWS instances and EBS volumes) associated with this SQL warehouse.

Supported values:

*   Number of tags < 45.

[`custom_tags`](https://docs.databricks.com/api/workspace/warehouses/get#tags-custom_tags)Array of object

[`warehouse_type`](https://docs.databricks.com/api/workspace/warehouses/get#warehouse_type)string

Enum: `TYPE_UNSPECIFIED | CLASSIC | PRO`

Warehouse type: `PRO` or `CLASSIC`. If you want to use serverless compute, you must set to `PRO` and also set the field `enable_serverless_compute` to `true`.

# Response samples

200

{ "auto_stop_mins": 120, "channel": { "dbsql_version": "string", "name": "CHANNEL_NAME_PREVIEW" }, "cluster_size": "string", "creator_name": "string", "enable_photon": true, "enable_serverless_compute": true, "health": { "details": "string", "failure_reason": { "code": "UNKNOWN", "parameters": { "property1": "string", "property2": "string" }, "type": "SUCCESS" }, "message": "string", "status": "HEALTHY", "summary": "string" }, "id": "string", "instance_profile_arn": "string", "jdbc_url": "string", "max_num_clusters": 0, "min_num_clusters": 1, "name": "string", "num_active_sessions": 0, "num_clusters": 0, "odbc_params": { "hostname": "string", "path": "string", "port": 0, "protocol": "string" }, "spot_instance_policy": "POLICY_UNSPECIFIED", "state": "STARTING", "tags": { "custom_tags": [ { "key": "string", "value": "string" } ] }, "warehouse_type": "TYPE_UNSPECIFIED" }
