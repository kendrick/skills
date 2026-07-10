Title: List all installations | Consumer Installations API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/consumerinstallations/list

Markdown Content:
## List all installations

Public preview

`GET/api/2.1/marketplace-consumer/installations`

List all installations across all listings.

API scopes:[`marketplace`](https://docs.databricks.com/api/workspace/api/scopes#marketplace)

### Query parameters

[`page_token`](https://docs.databricks.com/api/workspace/consumerinstallations/list#page_token)string

[`page_size`](https://docs.databricks.com/api/workspace/consumerinstallations/list#page_size)int32

### Responses

**200** Request completed successfully. The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

Request completed successfully.

 The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

[`installations`](https://docs.databricks.com/api/workspace/consumerinstallations/list#installations)Array of object

Array [

[`catalog_name`](https://docs.databricks.com/api/workspace/consumerinstallations/list#installations-catalog_name)string

[`error_message`](https://docs.databricks.com/api/workspace/consumerinstallations/list#installations-error_message)string

[`id`](https://docs.databricks.com/api/workspace/consumerinstallations/list#installations-id)string

[`installed_on`](https://docs.databricks.com/api/workspace/consumerinstallations/list#installations-installed_on)int64

[`listing_id`](https://docs.databricks.com/api/workspace/consumerinstallations/list#installations-listing_id)string

[`listing_name`](https://docs.databricks.com/api/workspace/consumerinstallations/list#installations-listing_name)string

[`recipient_type`](https://docs.databricks.com/api/workspace/consumerinstallations/list#installations-recipient_type)string

Enum: `DELTA_SHARING_RECIPIENT_TYPE_DATABRICKS | DELTA_SHARING_RECIPIENT_TYPE_OPEN`

[`repo_name`](https://docs.databricks.com/api/workspace/consumerinstallations/list#installations-repo_name)string

[`repo_path`](https://docs.databricks.com/api/workspace/consumerinstallations/list#installations-repo_path)string

[`share_name`](https://docs.databricks.com/api/workspace/consumerinstallations/list#installations-share_name)string

[`status`](https://docs.databricks.com/api/workspace/consumerinstallations/list#installations-status)string

Enum: `INSTALLED | FAILED`

[`token_detail`](https://docs.databricks.com/api/workspace/consumerinstallations/list#installations-token_detail)object

[`tokens`](https://docs.databricks.com/api/workspace/consumerinstallations/list#installations-tokens)Array of object

 ]

[`next_page_token`](https://docs.databricks.com/api/workspace/consumerinstallations/list#next_page_token)string

# Response samples

200

{ "installations": [ { "catalog_name": "string", "error_message": "string", "id": "string", "installed_on": 0, "listing_id": "string", "listing_name": "string", "recipient_type": "DELTA_SHARING_RECIPIENT_TYPE_DATABRICKS", "repo_name": "string", "repo_path": "string", "share_name": "string", "status": "INSTALLED", "token_detail": { "bearerToken": "string", "endpoint": "string", "expirationTime": "string", "shareCredentialsVersion": 0 }, "tokens": [ { "activation_url": "string", "created_at": 0, "created_by": "string", "expiration_time": 0, "id": "string", "updated_at": 0, "updated_by": "string" } ] } ], "next_page_token": "string" }
