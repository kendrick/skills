Title: List external locations | External Locations API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/externallocations/list

Markdown Content:
## List external locations

`GET/api/2.1/unity-catalog/external-locations`

Gets an array of external locations (ExternalLocationInfo objects) from the metastore. The caller must be a metastore admin, the owner of the external location, or a user that has some privilege on the external location. There is no guarantee of a specific ordering of the elements in the array.

NOTE: we recommend using max_results=0 to use the paginated version of this API. Unpaginated calls will be deprecated soon.

PAGINATION BEHAVIOR: When using pagination (max_results >= 0), a page may contain zero results while still providing a next_page_token. Clients must continue reading pages until next_page_token is absent, which is the only indication that the end of results has been reached.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Query parameters

[`include_browse`](https://docs.databricks.com/api/workspace/externallocations/list#include_browse)boolean

Whether to include external locations in the response for which the principal can only access selective metadata for

[`max_results`](https://docs.databricks.com/api/workspace/externallocations/list#max_results)int32

<= 1000 

Maximum number of external locations to return. If not set, all the external locations are returned (not recommended).

*   when set to a value greater than 0, the page length is the minimum of this value and a server configured value;
*   when set to 0, the page length is set to a server configured value (recommended);
*   when set to a value less than 0, an invalid parameter error is returned;

[`page_token`](https://docs.databricks.com/api/workspace/externallocations/list#page_token)string

Opaque pagination token to go to next page based on previous query.

[`include_unbound`](https://docs.databricks.com/api/workspace/externallocations/list#include_unbound)boolean

Whether to include external locations not bound to the workspace. Effective only if the user has permission to update the location–workspace binding.

### Responses

**200** Request completed successfully. The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

Request completed successfully.

 The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

[`external_locations`](https://docs.databricks.com/api/workspace/externallocations/list#external_locations)Array of object

An array of external locations.

Array [

[`browse_only`](https://docs.databricks.com/api/workspace/externallocations/list#external_locations-browse_only)boolean

Indicates whether the principal is limited to retrieving metadata for the associated object through the BROWSE privilege when include_browse is enabled in the request.

[`comment`](https://docs.databricks.com/api/workspace/externallocations/list#external_locations-comment)string

User-provided free-form text description.

[`created_at`](https://docs.databricks.com/api/workspace/externallocations/list#external_locations-created_at)int64

Time at which this external location was created, in epoch milliseconds.

[`created_by`](https://docs.databricks.com/api/workspace/externallocations/list#external_locations-created_by)string

Username of external location creator.

[`credential_id`](https://docs.databricks.com/api/workspace/externallocations/list#external_locations-credential_id)string

Unique ID of the location's storage credential.

[`credential_name`](https://docs.databricks.com/api/workspace/externallocations/list#external_locations-credential_name)string

Name of the storage credential used with this location.

[`effective_enable_file_events`](https://docs.databricks.com/api/workspace/externallocations/list#external_locations-effective_enable_file_events)boolean

The effective value of `enable_file_events` after applying server-side defaults.

[`effective_file_event_queue`](https://docs.databricks.com/api/workspace/externallocations/list#external_locations-effective_file_event_queue)object

The effective file event queue configuration after applying server-side defaults. Always populated when a queue is provisioned, regardless of whether the user explicitly set `enable_file_events`. Use this field instead of `file_event_queue` for reading the actual queue state.

[`enable_file_events`](https://docs.databricks.com/api/workspace/externallocations/list#external_locations-enable_file_events)boolean

Whether to enable file events on this external location. Default to `true`. Set to `false` to disable file events. The actual applied value may differ due to server-side defaults; check `effective_enable_file_events` for the effective state.

[`encryption_details`](https://docs.databricks.com/api/workspace/externallocations/list#external_locations-encryption_details)object

Encryption options that apply to clients connecting to cloud storage.

[`fallback`](https://docs.databricks.com/api/workspace/externallocations/list#external_locations-fallback)boolean

Indicates whether fallback mode is enabled for this external location. When fallback mode is enabled, the access to the location falls back to cluster credentials if UC credentials are not sufficient.

[`file_event_queue`](https://docs.databricks.com/api/workspace/externallocations/list#external_locations-file_event_queue)object

Example

File event queue settings. If `enable_file_events` is not `false`, must be defined and have exactly one of the documented properties.

[`isolation_mode`](https://docs.databricks.com/api/workspace/externallocations/list#external_locations-isolation_mode)string

Enum: `ISOLATION_MODE_OPEN | ISOLATION_MODE_ISOLATED`

[`metastore_id`](https://docs.databricks.com/api/workspace/externallocations/list#external_locations-metastore_id)string

Unique identifier of metastore hosting the external location.

[`name`](https://docs.databricks.com/api/workspace/externallocations/list#external_locations-name)string

Name of the external location.

[`owner`](https://docs.databricks.com/api/workspace/externallocations/list#external_locations-owner)string

The owner of the external location.

[`read_only`](https://docs.databricks.com/api/workspace/externallocations/list#external_locations-read_only)boolean

Indicates whether the external location is read-only.

[`updated_at`](https://docs.databricks.com/api/workspace/externallocations/list#external_locations-updated_at)int64

Time at which external location this was last modified, in epoch milliseconds.

[`updated_by`](https://docs.databricks.com/api/workspace/externallocations/list#external_locations-updated_by)string

Username of user who last modified the external location.

[`url`](https://docs.databricks.com/api/workspace/externallocations/list#external_locations-url)string

Path URL of the external location.

 ]

[`next_page_token`](https://docs.databricks.com/api/workspace/externallocations/list#next_page_token)string

Opaque token to retrieve the next page of results. Absent if there are no more pages. page_token should be set to this value for the next request (for the next page of results).

# Response samples

200

{

"external_locations":[

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

],

"next_page_token":"string"

}
