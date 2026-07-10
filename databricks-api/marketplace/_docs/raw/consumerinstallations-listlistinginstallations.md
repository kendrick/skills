Title: List installations for a listing | Consumer Installations API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/consumerinstallations/listlistinginstallations

Markdown Content:
## List installations for a listing

Public preview

`GET/api/2.1/marketplace-consumer/listings/{listing_id}/installations`

List all installations for a particular listing.

API scopes:[`marketplace`](https://docs.databricks.com/api/workspace/api/scopes#marketplace)

### Path parameters

[`listing_id`](https://docs.databricks.com/api/workspace/consumerinstallations/listlistinginstallations#listing_id)required string

### Query parameters

[`page_token`](https://docs.databricks.com/api/workspace/consumerinstallations/listlistinginstallations#page_token)string

[`page_size`](https://docs.databricks.com/api/workspace/consumerinstallations/listlistinginstallations#page_size)int32

### Responses

**200** Request completed successfully. The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

Request completed successfully.

 The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

[`installations`](https://docs.databricks.com/api/workspace/consumerinstallations/listlistinginstallations#installations)Array of object

Array [

[`catalog_name`](https://docs.databricks.com/api/workspace/consumerinstallations/listlistinginstallations#installations-catalog_name)string

[`error_message`](https://docs.databricks.com/api/workspace/consumerinstallations/listlistinginstallations#installations-error_message)string

[`id`](https://docs.databricks.com/api/workspace/consumerinstallations/listlistinginstallations#installations-id)string

[`installed_on`](https://docs.databricks.com/api/workspace/consumerinstallations/listlistinginstallations#installations-installed_on)int64

[`listing_id`](https://docs.databricks.com/api/workspace/consumerinstallations/listlistinginstallations#installations-listing_id)string

[`listing_name`](https://docs.databricks.com/api/workspace/consumerinstallations/listlistinginstallations#installations-listing_name)string

[`recipient_type`](https://docs.databricks.com/api/workspace/consumerinstallations/listlistinginstallations#installations-recipient_type)string

Enum: `DELTA_SHARING_RECIPIENT_TYPE_DATABRICKS | DELTA_SHARING_RECIPIENT_TYPE_OPEN`

[`repo_name`](https://docs.databricks.com/api/workspace/consumerinstallations/listlistinginstallations#installations-repo_name)string

[`repo_path`](https://docs.databricks.com/api/workspace/consumerinstallations/listlistinginstallations#installations-repo_path)string

[`share_name`](https://docs.databricks.com/api/workspace/consumerinstallations/listlistinginstallations#installations-share_name)string

[`status`](https://docs.databricks.com/api/workspace/consumerinstallations/listlistinginstallations#installations-status)string

Enum: `INSTALLED | FAILED`

[`token_detail`](https://docs.databricks.com/api/workspace/consumerinstallations/listlistinginstallations#installations-token_detail)object

[`tokens`](https://docs.databricks.com/api/workspace/consumerinstallations/listlistinginstallations#installations-tokens)Array of object

 ]

[`next_page_token`](https://docs.databricks.com/api/workspace/consumerinstallations/listlistinginstallations#next_page_token)string

# Response samples

200

{ "installations": [ { "catalog_name": "string", "error_message": "string", "id": "string", "installed_on": 0, "listing_id": "string", "listing_name": "string", "recipient_type": "DELTA_SHARING_RECIPIENT_TYPE_DATABRICKS", "repo_name": "string", "repo_path": "string", "share_name": "string", "status": "INSTALLED", "token_detail": { "bearerToken": "string", "endpoint": "string", "expirationTime": "string", "shareCredentialsVersion": 0 }, "tokens": [ { "activation_url": "string", "created_at": 0, "created_by": "string", "expiration_time": 0, "id": "string", "updated_at": 0, "updated_by": "string" } ] } ], "next_page_token": "string" }
