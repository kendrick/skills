Title: List warehouses | SQL Warehouses API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/warehouses/list

Markdown Content:
## List warehouses

`GET/api/2.0/sql/warehouses`

Lists all SQL warehouses that a user has access to.

API scopes (preview):[`sql`](https://docs.databricks.com/api/workspace/api/scopes#sql)

### Query parameters

[`run_as_user_id`](https://docs.databricks.com/api/workspace/warehouses/list#run_as_user_id)int32

Deprecated

Deprecated: this field is ignored by the server. Service Principal which will be used to fetch the list of endpoints. If not specified, SQL Gateway will use the user from the session header.

[`page_size`](https://docs.databricks.com/api/workspace/warehouses/list#page_size)int32

The max number of warehouses to return.

[`page_token`](https://docs.databricks.com/api/workspace/warehouses/list#page_token)string

A page token, received from a previous `ListWarehouses` call. Provide this to retrieve the subsequent page; otherwise the first will be retrieved.

When paginating, all other parameters provided to `ListWarehouses` must match the call that provided the page token.

### Responses

**200** Request completed successfully. The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

Request completed successfully.

 The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

[`next_page_token`](https://docs.databricks.com/api/workspace/warehouses/list#next_page_token)string

A token, which can be sent as `page_token` to retrieve the next page. If this field is omitted, there are no subsequent pages.

[`warehouses`](https://docs.databricks.com/api/workspace/warehouses/list#warehouses)Array of object

A list of warehouses and their configurations.

Array [

[`auto_stop_mins`](https://docs.databricks.com/api/workspace/warehouses/list#warehouses-auto_stop_mins)int32

Default`120`

The amount of time in minutes that a SQL warehouse must be idle (i.e., no RUNNING queries) before it is automatically stopped.

Supported values:

*   Must be == 0 or >= 10 mins
*   0 indicates no autostop.

Defaults to 120 mins

[`channel`](https://docs.databricks.com/api/workspace/warehouses/list#warehouses-channel)object

Channel Details

[`cluster_size`](https://docs.databricks.com/api/workspace/warehouses/list#warehouses-cluster_size)string

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

[`creator_name`](https://docs.databricks.com/api/workspace/warehouses/list#warehouses-creator_name)string

warehouse creator name

[`enable_photon`](https://docs.databricks.com/api/workspace/warehouses/list#warehouses-enable_photon)boolean

Configures whether the warehouse should use Photon optimized clusters.

Defaults to true.

[`enable_serverless_compute`](https://docs.databricks.com/api/workspace/warehouses/list#warehouses-enable_serverless_compute)boolean

Configures whether the warehouse should use serverless compute

[`health`](https://docs.databricks.com/api/workspace/warehouses/list#warehouses-health)object

Optional health status. Assume the warehouse is healthy if this field is not set.

[`id`](https://docs.databricks.com/api/workspace/warehouses/list#warehouses-id)string

unique identifier for warehouse

[`instance_profile_arn`](https://docs.databricks.com/api/workspace/warehouses/list#warehouses-instance_profile_arn)string

Deprecated

Deprecated. Instance profile used to pass IAM role to the cluster

[`jdbc_url`](https://docs.databricks.com/api/workspace/warehouses/list#warehouses-jdbc_url)string

the jdbc connection string for this warehouse

[`max_num_clusters`](https://docs.databricks.com/api/workspace/warehouses/list#warehouses-max_num_clusters)int32

Maximum number of clusters that the autoscaler will create to handle concurrent queries.

Supported values:

*   Must be >= min_num_clusters
*   Must be <= 40.

Defaults to min_clusters if unset.

[`min_num_clusters`](https://docs.databricks.com/api/workspace/warehouses/list#warehouses-min_num_clusters)int32

Default`1`

Minimum number of available clusters that will be maintained for this SQL warehouse. Increasing this will ensure that a larger number of clusters are always running and therefore may reduce the cold start time for new queries. This is similar to reserved vs. revocable cores in a resource manager.

Supported values:

*   Must be > 0
*   Must be <= min(max_num_clusters, 30)

Defaults to 1

[`name`](https://docs.databricks.com/api/workspace/warehouses/list#warehouses-name)string

Logical name for the cluster.

Supported values:

*   Must be unique within an org.
*   Must be less than 100 characters.

[`num_active_sessions`](https://docs.databricks.com/api/workspace/warehouses/list#warehouses-num_active_sessions)int64

Deprecated

Deprecated. current number of active sessions for the warehouse

[`num_clusters`](https://docs.databricks.com/api/workspace/warehouses/list#warehouses-num_clusters)int32

current number of clusters running for the service

[`odbc_params`](https://docs.databricks.com/api/workspace/warehouses/list#warehouses-odbc_params)object

ODBC parameters for the SQL warehouse

[`spot_instance_policy`](https://docs.databricks.com/api/workspace/warehouses/list#warehouses-spot_instance_policy)string

Enum: `POLICY_UNSPECIFIED | COST_OPTIMIZED | RELIABILITY_OPTIMIZED`

Default`"COST_OPTIMIZED"`

Configurations whether the endpoint should use spot instances.

[`state`](https://docs.databricks.com/api/workspace/warehouses/list#warehouses-state)string

Enum: `STARTING | RUNNING | STOPPING | STOPPED | DELETING | DELETED`

state of the endpoint

[`tags`](https://docs.databricks.com/api/workspace/warehouses/list#warehouses-tags)object

A set of key-value pairs that will be tagged on all resources (e.g., AWS instances and EBS volumes) associated with this SQL warehouse.

Supported values:

*   Number of tags < 45.

[`warehouse_type`](https://docs.databricks.com/api/workspace/warehouses/list#warehouses-warehouse_type)string

Enum: `TYPE_UNSPECIFIED | CLASSIC | PRO`

Warehouse type: `PRO` or `CLASSIC`. If you want to use serverless compute, you must set to `PRO` and also set the field `enable_serverless_compute` to `true`.

 ]

# Response samples

200

{

"next_page_token":"string",

"warehouses":[

{

"auto_stop_mins":120,

"channel":{

"dbsql_version":"string",

"name":"CHANNEL_NAME_PREVIEW"

},

"cluster_size":"string",

"creator_name":"string",

"enable_photon":true,

"enable_serverless_compute":true,

"health":{

"details":"string",

"failure_reason":{

"code":"UNKNOWN",

"parameters":{

"property1":"string",

"property2":"string"

},

"type":"SUCCESS"

},

"message":"string",

"status":"HEALTHY",

"summary":"string"

},

"id":"string",

"instance_profile_arn":"string",

"jdbc_url":"string",

"max_num_clusters":0,

"min_num_clusters":1,

"name":"string",

"num_active_sessions":0,

"num_clusters":0,

"odbc_params":{

"hostname":"string",

"path":"string",

"port":0,

"protocol":"string"

},

"spot_instance_policy":"POLICY_UNSPECIFIED",

"state":"STARTING",

"tags":{

"custom_tags":[

{

"key":"string",

"value":"string"

}

]

},

"warehouse_type":"TYPE_UNSPECIFIED"

}

]

}
