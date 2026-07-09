Title: Delete an ABAC policy | ABAC Policies API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/policies/deletepolicy

Markdown Content:
## Delete an ABAC policy

Public preview

`DELETE/api/2.1/unity-catalog/policies/{on_securable_type}/{on_securable_fullname}/{name}`

Delete an ABAC policy defined on a securable.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`on_securable_type`](https://docs.databricks.com/api/workspace/policies/deletepolicy#on_securable_type)required string

Required. The type of the securable to delete the policy from.

[`on_securable_fullname`](https://docs.databricks.com/api/workspace/policies/deletepolicy#on_securable_fullname)required string

Required. The fully qualified name of the securable to delete the policy from.

[`name`](https://docs.databricks.com/api/workspace/policies/deletepolicy#name)required string

Required. The name of the policy to delete

### Responses

**200** Request completed successfully.

Request completed successfully.

# Response samples

200

{}
