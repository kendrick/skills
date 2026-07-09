Title: List recipient federation policies | Recipient Federation Policies API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/recipientfederationpolicies/list

Markdown Content:
## List recipient federation policies

Public preview

`GET/api/2.0/data-sharing/recipients/{recipient_name}/federation-policies`

Lists federation policies for an OIDC_FEDERATION recipient for sharing data from Databricks to non-Databricks recipients. The caller must have read access to the recipient.

API scopes (preview):[`sharing`](https://docs.databricks.com/api/workspace/api/scopes#sharing)

### Path parameters

[`recipient_name`](https://docs.databricks.com/api/workspace/recipientfederationpolicies/list#recipient_name)required string

Name of the recipient. This is the name of the recipient for which the policies are being listed.

### Query parameters

[`max_results`](https://docs.databricks.com/api/workspace/recipientfederationpolicies/list#max_results)int32 Optional

[`page_token`](https://docs.databricks.com/api/workspace/recipientfederationpolicies/list#page_token)string Optional

### Responses

**200** Request completed successfully. The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

Request completed successfully.

 The response includes a list of items and pagination information. If `next_page_token` is set, there are more results.

[`next_page_token`](https://docs.databricks.com/api/workspace/recipientfederationpolicies/list#next_page_token)string

[`policies`](https://docs.databricks.com/api/workspace/recipientfederationpolicies/list#policies)Array of object

Array [

[`comment`](https://docs.databricks.com/api/workspace/recipientfederationpolicies/list#policies-comment)string

Example`"My federation policy description."`

Description of the policy. This is a user-provided description.

[`create_time`](https://docs.databricks.com/api/workspace/recipientfederationpolicies/list#policies-create_time)date-time

System-generated timestamp indicating when the policy was created.

[`id`](https://docs.databricks.com/api/workspace/recipientfederationpolicies/list#policies-id)uuid

Unique, immutable system-generated identifier for the federation policy.

[`name`](https://docs.databricks.com/api/workspace/recipientfederationpolicies/list#policies-name)string

Example`"my-federation-policy1"`

Name of the federation policy. A recipient can have multiple policies with different names. The name must contain only lowercase alphanumeric characters, numbers, and hyphens.

[`oidc_policy`](https://docs.databricks.com/api/workspace/recipientfederationpolicies/list#policies-oidc_policy)object

Specifies the policy to use for validating OIDC claims in the federated tokens.

[`update_time`](https://docs.databricks.com/api/workspace/recipientfederationpolicies/list#policies-update_time)date-time

System-generated timestamp indicating when the policy was last updated.

 ]

# Response samples

200

{

"next_page_token":"string",

"policies":[

{

"comment":"My federation policy description.",

"create_time":"2019-08-24T14:15:22Z",

"id":"497f6eca-6276-4993-bfeb-53cbbbba6f08",

"name":"my-federation-policy1",

"oidc_policy":{

"audiences":[

"string"

],

"issuer":"https://myidp.example.com/oidc",

"subject":"string",

"subject_claim":"azp"

},

"update_time":"2019-08-24T14:15:22Z"

}

]

}
