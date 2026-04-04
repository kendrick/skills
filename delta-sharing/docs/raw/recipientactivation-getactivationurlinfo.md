Title: Get a share activation URL | Recipient Activation API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/recipientactivation/getactivationurlinfo

Markdown Content:
## Get a share activation URL

`GET/api/2.1/unity-catalog/public/data_sharing_activation_info/{activation_url}`

Gets an activation URL for a share.

API scopes (preview):[`sharing`](https://docs.databricks.com/api/workspace/api/scopes#sharing)

### Path parameters

[`activation_url`](https://docs.databricks.com/api/workspace/recipientactivation/getactivationurlinfo#activation_url)required string

The one time activation url. It also accepts activation token.

### Responses

**200** Request completed successfully.

Request completed successfully.

# Response samples

200

{}
