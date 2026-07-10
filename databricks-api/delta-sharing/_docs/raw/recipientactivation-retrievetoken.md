Title: Get an access token | Recipient Activation API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/recipientactivation/retrievetoken

Markdown Content:
## Get an access token

`GET/api/2.1/unity-catalog/public/data_sharing_activation/{activation_url}`

Retrieve access token with an activation url. This is a public API without any authentication.

API scopes (preview):[`sharing`](https://docs.databricks.com/api/workspace/api/scopes#sharing)

### Path parameters

[`activation_url`](https://docs.databricks.com/api/workspace/recipientactivation/retrievetoken#activation_url)required string

The one time activation url. It also accepts activation token.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`bearerToken`](https://docs.databricks.com/api/workspace/recipientactivation/retrievetoken#bearerToken)string

The token used to authorize the recipient.

[`endpoint`](https://docs.databricks.com/api/workspace/recipientactivation/retrievetoken#endpoint)string

The endpoint for the share to be used by the recipient.

[`expirationTime`](https://docs.databricks.com/api/workspace/recipientactivation/retrievetoken#expirationTime)string

Expiration timestamp of the token in epoch milliseconds.

[`shareCredentialsVersion`](https://docs.databricks.com/api/workspace/recipientactivation/retrievetoken#shareCredentialsVersion)int32

These field names must follow the delta sharing protocol.

# Response samples

200

{

"bearerToken":"string",

"endpoint":"string",

"expirationTime":"string",

"shareCredentialsVersion":0

}
