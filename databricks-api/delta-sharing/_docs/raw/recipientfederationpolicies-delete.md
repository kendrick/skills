Title: Delete recipient federation policy | Recipient Federation Policies API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/recipientfederationpolicies/delete

Markdown Content:
## Delete recipient federation policy

Public preview

`DELETE/api/2.0/data-sharing/recipients/{recipient_name}/federation-policies/{name}`

Deletes an existing federation policy for an OIDC_FEDERATION recipient. The caller must be the owner of the recipient.

API scopes (preview):[`sharing`](https://docs.databricks.com/api/workspace/api/scopes#sharing)

### Path parameters

[`recipient_name`](https://docs.databricks.com/api/workspace/recipientfederationpolicies/delete#recipient_name)required string

Name of the recipient. This is the name of the recipient for which the policy is being deleted.

[`name`](https://docs.databricks.com/api/workspace/recipientfederationpolicies/delete#name)required string

Name of the policy. This is the name of the policy to be deleted.

### Responses

**200** Request completed successfully.

Request completed successfully.

# Response samples

200

{}
