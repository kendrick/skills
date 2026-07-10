Title: Create a warehouse | SQL Warehouses API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/warehouses/create

Markdown Content:
## Create a warehouse

`POST/api/2.0/sql/warehouses`

Creates a new SQL warehouse.

API scopes:[`sql`](https://docs.databricks.com/api/workspace/api/scopes#sql)

### Request body

Creates a new SQL warehouse.

[`auto_stop_mins`](https://docs.databricks.com/api/workspace/warehouses/create#auto_stop_mins)int32

Default`120`

The amount of time in minutes that a SQL warehouse must be idle (i.e., no RUNNING queries) before it is automatically stopped.

Supported values:

*   Must be == 0 or >= 10 mins
*   0 indicates no autostop.

Defaults to 120 mins

[`channel`](https://docs.databricks.com/api/workspace/warehouses/create#channel)object

Channel Details

[`dbsql_version`](https://docs.databricks.com/api/workspace/warehouses/create#channel-dbsql_version)string

[`name`](https://docs.databricks.com/api/workspace/warehouses/create#channel-name)string

Enum: `CHANNEL_NAME_PREVIEW | CHANNEL_NAME_CURRENT | CHANNEL_NAME_PREVIOUS | CHANNEL_NAME_CUSTOM`

[`cluster_size`](https://docs.databricks.com/api/workspace/warehouses/create#cluster_size)string

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

[`creator_name`](https://docs.databricks.com/api/workspace/warehouses/create#creator_name)string

warehouse creator name

[`enable_photon`](https://docs.databricks.com/api/workspace/warehouses/create#enable_photon)boolean

Configures whether the warehouse should use Photon optimized clusters.

Defaults to true.

[`enable_serverless_compute`](https://docs.databricks.com/api/workspace/warehouses/create#enable_serverless_compute)boolean

Configures whether the warehouse should use serverless compute

[`instance_profile_arn`](https://docs.databricks.com/api/workspace/warehouses/create#instance_profile_arn)string

Deprecated

Deprecated. Instance profile used to pass IAM role to the cluster

[`max_num_clusters`](https://docs.databricks.com/api/workspace/warehouses/create#max_num_clusters)int32

Maximum number of clusters that the autoscaler will create to handle concurrent queries.

Supported values:

*   Must be >= min_num_clusters
*   Must be <= 40.

Defaults to min_clusters if unset.

[`min_num_clusters`](https://docs.databricks.com/api/workspace/warehouses/create#min_num_clusters)int32

Default`1`

Minimum number of available clusters that will be maintained for this SQL warehouse. Increasing this will ensure that a larger number of clusters are always running and therefore may reduce the cold start time for new queries. This is similar to reserved vs. revocable cores in a resource manager.

Supported values:

*   Must be > 0
*   Must be <= min(max_num_clusters, 30)

Defaults to 1

[`name`](https://docs.databricks.com/api/workspace/warehouses/create#name)string

Logical name for the cluster.

Supported values:

*   Must be unique within an org.
*   Must be less than 100 characters.

[`spot_instance_policy`](https://docs.databricks.com/api/workspace/warehouses/create#spot_instance_policy)string

Enum: `POLICY_UNSPECIFIED | COST_OPTIMIZED | RELIABILITY_OPTIMIZED`

Default`"COST_OPTIMIZED"`

Configurations whether the endpoint should use spot instances.

[`tags`](https://docs.databricks.com/api/workspace/warehouses/create#tags)object

A set of key-value pairs that will be tagged on all resources (e.g., AWS instances and EBS volumes) associated with this SQL warehouse.

Supported values:

*   Number of tags < 45.

[`custom_tags`](https://docs.databricks.com/api/workspace/warehouses/create#tags-custom_tags)Array of object

[`warehouse_type`](https://docs.databricks.com/api/workspace/warehouses/create#warehouse_type)string

Enum: `TYPE_UNSPECIFIED | CLASSIC | PRO`

Warehouse type: `PRO` or `CLASSIC`. If you want to use serverless compute, you must set to `PRO` and also set the field `enable_serverless_compute` to `true`.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`id`](https://docs.databricks.com/api/workspace/warehouses/create#id)string

Id for the SQL warehouse. This value is unique across all SQL warehouses.

# Request samples

JSON

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

"instance_profile_arn":"string",

"max_num_clusters":0,

"min_num_clusters":1,

"name":"string",

"spot_instance_policy":"POLICY_UNSPECIFIED",

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

# Response samples

200

{

"id":"string"

}
