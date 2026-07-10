Title: Create an external location | External Locations API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/externallocations/create

Markdown Content:
## Create an external location

`POST/api/2.1/unity-catalog/external-locations`

Creates a new external location entry in the metastore. The caller must be a metastore admin or have the CREATE_EXTERNAL_LOCATION privilege on both the metastore and the associated storage credential.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Request body

[`comment`](https://docs.databricks.com/api/workspace/externallocations/create#comment)string

User-provided free-form text description.

[`credential_name`](https://docs.databricks.com/api/workspace/externallocations/create#credential_name)required string

Name of the storage credential used with this location.

[`enable_file_events`](https://docs.databricks.com/api/workspace/externallocations/create#enable_file_events)boolean

Whether to enable file events on this external location. Default to `true`. Set to `false` to disable file events. The actual applied value may differ due to server-side defaults; check `effective_enable_file_events` for the effective state.

[`encryption_details`](https://docs.databricks.com/api/workspace/externallocations/create#encryption_details)object

Encryption options that apply to clients connecting to cloud storage.

[`sse_encryption_details`](https://docs.databricks.com/api/workspace/externallocations/create#encryption_details-sse_encryption_details)object

Server-Side Encryption properties for clients communicating with AWS s3.

[`fallback`](https://docs.databricks.com/api/workspace/externallocations/create#fallback)boolean

Indicates whether fallback mode is enabled for this external location. When fallback mode is enabled, the access to the location falls back to cluster credentials if UC credentials are not sufficient.

[`file_event_queue`](https://docs.databricks.com/api/workspace/externallocations/create#file_event_queue)object

File event queue settings. If `enable_file_events` is not `false`, must be defined and have exactly one of the documented properties.

[`managed_aqs`](https://docs.databricks.com/api/workspace/externallocations/create#file_event_queue-managed_aqs)object

[`managed_pubsub`](https://docs.databricks.com/api/workspace/externallocations/create#file_event_queue-managed_pubsub)object

[`managed_sqs`](https://docs.databricks.com/api/workspace/externallocations/create#file_event_queue-managed_sqs)object

[`provided_aqs`](https://docs.databricks.com/api/workspace/externallocations/create#file_event_queue-provided_aqs)object

[`provided_pubsub`](https://docs.databricks.com/api/workspace/externallocations/create#file_event_queue-provided_pubsub)object

[`provided_sqs`](https://docs.databricks.com/api/workspace/externallocations/create#file_event_queue-provided_sqs)object

[`name`](https://docs.databricks.com/api/workspace/externallocations/create#name)required string

Name of the external location.

[`read_only`](https://docs.databricks.com/api/workspace/externallocations/create#read_only)boolean

Indicates whether the external location is read-only.

[`skip_validation`](https://docs.databricks.com/api/workspace/externallocations/create#skip_validation)boolean

Skips validation of the storage credential associated with the external location.

[`url`](https://docs.databricks.com/api/workspace/externallocations/create#url)required string

Path URL of the external location.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`browse_only`](https://docs.databricks.com/api/workspace/externallocations/create#browse_only)boolean

Indicates whether the principal is limited to retrieving metadata for the associated object through the BROWSE privilege when include_browse is enabled in the request.

[`comment`](https://docs.databricks.com/api/workspace/externallocations/create#comment)string

User-provided free-form text description.

[`created_at`](https://docs.databricks.com/api/workspace/externallocations/create#created_at)int64

Time at which this external location was created, in epoch milliseconds.

[`created_by`](https://docs.databricks.com/api/workspace/externallocations/create#created_by)string

Username of external location creator.

[`credential_id`](https://docs.databricks.com/api/workspace/externallocations/create#credential_id)string

Unique ID of the location's storage credential.

[`credential_name`](https://docs.databricks.com/api/workspace/externallocations/create#credential_name)string

Name of the storage credential used with this location.

[`effective_enable_file_events`](https://docs.databricks.com/api/workspace/externallocations/create#effective_enable_file_events)boolean

The effective value of `enable_file_events` after applying server-side defaults.

[`effective_file_event_queue`](https://docs.databricks.com/api/workspace/externallocations/create#effective_file_event_queue)object

The effective file event queue configuration after applying server-side defaults. Always populated when a queue is provisioned, regardless of whether the user explicitly set `enable_file_events`. Use this field instead of `file_event_queue` for reading the actual queue state.

[`managed_aqs`](https://docs.databricks.com/api/workspace/externallocations/create#effective_file_event_queue-managed_aqs)object

[`managed_pubsub`](https://docs.databricks.com/api/workspace/externallocations/create#effective_file_event_queue-managed_pubsub)object

[`managed_sqs`](https://docs.databricks.com/api/workspace/externallocations/create#effective_file_event_queue-managed_sqs)object

[`provided_aqs`](https://docs.databricks.com/api/workspace/externallocations/create#effective_file_event_queue-provided_aqs)object

[`provided_pubsub`](https://docs.databricks.com/api/workspace/externallocations/create#effective_file_event_queue-provided_pubsub)object

[`provided_sqs`](https://docs.databricks.com/api/workspace/externallocations/create#effective_file_event_queue-provided_sqs)object

[`enable_file_events`](https://docs.databricks.com/api/workspace/externallocations/create#enable_file_events)boolean

Whether to enable file events on this external location. Default to `true`. Set to `false` to disable file events. The actual applied value may differ due to server-side defaults; check `effective_enable_file_events` for the effective state.

[`encryption_details`](https://docs.databricks.com/api/workspace/externallocations/create#encryption_details)object

Encryption options that apply to clients connecting to cloud storage.

[`sse_encryption_details`](https://docs.databricks.com/api/workspace/externallocations/create#encryption_details-sse_encryption_details)object

Server-Side Encryption properties for clients communicating with AWS s3.

[`fallback`](https://docs.databricks.com/api/workspace/externallocations/create#fallback)boolean

Indicates whether fallback mode is enabled for this external location. When fallback mode is enabled, the access to the location falls back to cluster credentials if UC credentials are not sufficient.

[`file_event_queue`](https://docs.databricks.com/api/workspace/externallocations/create#file_event_queue)object

Example

File event queue settings. If `enable_file_events` is not `false`, must be defined and have exactly one of the documented properties.

[`managed_aqs`](https://docs.databricks.com/api/workspace/externallocations/create#file_event_queue-managed_aqs)object

[`managed_pubsub`](https://docs.databricks.com/api/workspace/externallocations/create#file_event_queue-managed_pubsub)object

[`managed_sqs`](https://docs.databricks.com/api/workspace/externallocations/create#file_event_queue-managed_sqs)object

[`provided_aqs`](https://docs.databricks.com/api/workspace/externallocations/create#file_event_queue-provided_aqs)object

[`provided_pubsub`](https://docs.databricks.com/api/workspace/externallocations/create#file_event_queue-provided_pubsub)object

[`provided_sqs`](https://docs.databricks.com/api/workspace/externallocations/create#file_event_queue-provided_sqs)object

[`isolation_mode`](https://docs.databricks.com/api/workspace/externallocations/create#isolation_mode)string

Enum: `ISOLATION_MODE_OPEN | ISOLATION_MODE_ISOLATED`

[`metastore_id`](https://docs.databricks.com/api/workspace/externallocations/create#metastore_id)string

Unique identifier of metastore hosting the external location.

[`name`](https://docs.databricks.com/api/workspace/externallocations/create#name)string

Name of the external location.

[`owner`](https://docs.databricks.com/api/workspace/externallocations/create#owner)string

The owner of the external location.

[`read_only`](https://docs.databricks.com/api/workspace/externallocations/create#read_only)boolean

Indicates whether the external location is read-only.

[`updated_at`](https://docs.databricks.com/api/workspace/externallocations/create#updated_at)int64

Time at which external location this was last modified, in epoch milliseconds.

[`updated_by`](https://docs.databricks.com/api/workspace/externallocations/create#updated_by)string

Username of user who last modified the external location.

[`url`](https://docs.databricks.com/api/workspace/externallocations/create#url)string

Path URL of the external location.

# Request samples

JSON

{

"comment":"string",

"credential_name":"string",

"enable_file_events":true,

"encryption_details":{

"sse_encryption_details":{

"algorithm":"AWS_SSE_S3",

"aws_kms_key_arn":"string"

}

},

"fallback":true,

"file_event_queue":{

"managed_aqs":{

"managed_resource_id":"string",

"queue_url":"string",

"resource_group":"string",

"subscription_id":"string"

},

"managed_pubsub":{

"managed_resource_id":"string",

"subscription_name":"string"

},

"managed_sqs":{

"managed_resource_id":"string",

"queue_url":"string"

},

"provided_aqs":{

"managed_resource_id":"string",

"queue_url":"string",

"resource_group":"string",

"subscription_id":"string"

},

"provided_pubsub":{

"managed_resource_id":"string",

"subscription_name":"string"

},

"provided_sqs":{

"managed_resource_id":"string",

"queue_url":"string"

}

},

"name":"string",

"read_only":true,

"skip_validation":true,

"url":"string"

}

# Response samples

200

{

"browse_only":true,

"comment":"string",

"created_at":0,

"created_by":"string",

"credential_id":"string",

"credential_name":"string",

"effective_enable_file_events":true,

"effective_file_event_queue":{

"managed_aqs":{

"managed_resource_id":"string",

"queue_url":"string",

"resource_group":"string",

"subscription_id":"string"

},

"managed_pubsub":{

"managed_resource_id":"string",

"subscription_name":"string"

},

"managed_sqs":{

"managed_resource_id":"string",

"queue_url":"string"

},

"provided_aqs":{

"managed_resource_id":"string",

"queue_url":"string",

"resource_group":"string",

"subscription_id":"string"

},

"provided_pubsub":{

"managed_resource_id":"string",

"subscription_name":"string"

},

"provided_sqs":{

"managed_resource_id":"string",

"queue_url":"string"

}

},

"enable_file_events":true,

"encryption_details":{

"sse_encryption_details":{

"algorithm":"AWS_SSE_S3",

"aws_kms_key_arn":"string"

}

},

"fallback":true,

"file_event_queue":{

"managed_aqs":{

"managed_resource_id":"string",

"queue_url":"string",

"resource_group":"string",

"subscription_id":"string"

},

"managed_pubsub":{

"managed_resource_id":"string",

"subscription_name":"string"

},

"managed_sqs":{

"managed_resource_id":"string",

"queue_url":"string"

},

"provided_aqs":{

"managed_resource_id":"string",

"queue_url":"string",

"resource_group":"string",

"subscription_id":"string"

},

"provided_pubsub":{

"managed_resource_id":"string",

"subscription_name":"string"

},

"provided_sqs":{

"managed_resource_id":"string",

"queue_url":"string"

}

},

"isolation_mode":"ISOLATION_MODE_OPEN",

"metastore_id":"string",

"name":"string",

"owner":"string",

"read_only":true,

"updated_at":0,

"updated_by":"string",

"url":"string"

}
