Title: Get recipient federation policy | Recipient Federation Policies API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/recipientfederationpolicies/getfederationpolicy

Markdown Content:
## Get recipient federation policy

Public preview

`GET/api/2.0/data-sharing/recipients/{recipient_name}/federation-policies/{name}`

Reads an existing federation policy for an OIDC_FEDERATION recipient for sharing data from Databricks to non-Databricks recipients. The caller must have read access to the recipient.

API scopes (preview):[`sharing`](https://docs.databricks.com/api/workspace/api/scopes#sharing)

### Path parameters

[`recipient_name`](https://docs.databricks.com/api/workspace/recipientfederationpolicies/getfederationpolicy#recipient_name)required string

Name of the recipient. This is the name of the recipient for which the policy is being retrieved.

[`name`](https://docs.databricks.com/api/workspace/recipientfederationpolicies/getfederationpolicy#name)required string

Name of the policy. This is the name of the policy to be retrieved.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`comment`](https://docs.databricks.com/api/workspace/recipientfederationpolicies/getfederationpolicy#comment)string

Example`"My federation policy description."`

Description of the policy. This is a user-provided description.

[`create_time`](https://docs.databricks.com/api/workspace/recipientfederationpolicies/getfederationpolicy#create_time)date-time

System-generated timestamp indicating when the policy was created.

[`id`](https://docs.databricks.com/api/workspace/recipientfederationpolicies/getfederationpolicy#id)uuid

Unique, immutable system-generated identifier for the federation policy.

[`name`](https://docs.databricks.com/api/workspace/recipientfederationpolicies/getfederationpolicy#name)string

Example`"my-federation-policy1"`

Name of the federation policy. A recipient can have multiple policies with different names. The name must contain only lowercase alphanumeric characters, numbers, and hyphens.

[`oidc_policy`](https://docs.databricks.com/api/workspace/recipientfederationpolicies/getfederationpolicy#oidc_policy)object

Specifies the policy to use for validating OIDC claims in the federated tokens.

[`audiences`](https://docs.databricks.com/api/workspace/recipientfederationpolicies/getfederationpolicy#oidc_policy-audiences)Array of string

The allowed token audiences, as specified in the 'aud' claim of federated tokens. The audience identifier is intended to represent the recipient of the token. Can be any non-empty string value. As long as the audience in the token matches at least one audience in the policy,

[`issuer`](https://docs.databricks.com/api/workspace/recipientfederationpolicies/getfederationpolicy#oidc_policy-issuer)string

Example`"https://myidp.example.com/oidc"`

The required token issuer, as specified in the 'iss' claim of federated tokens.

[`subject`](https://docs.databricks.com/api/workspace/recipientfederationpolicies/getfederationpolicy#oidc_policy-subject)string

The required token subject, as specified in the subject claim of federated tokens. The subject claim identifies the identity of the user or machine accessing the resource. Examples for Entra ID (AAD):

*   U2M flow (group access): If the subject claim is `groups`, this must be the Object ID of the group in Entra ID.
*   U2M flow (user access): If the subject claim is `oid`, this must be the Object ID of the user in Entra ID.
*   M2M flow (OAuth App access): If the subject claim is `azp`, this must be the client ID of the OAuth app registered in Entra ID.

[`subject_claim`](https://docs.databricks.com/api/workspace/recipientfederationpolicies/getfederationpolicy#oidc_policy-subject_claim)string

Example`"azp"`

The claim that contains the subject of the token. Depending on the identity provider and the use case (U2M or M2M), this can vary:

*   For Entra ID (AAD):

*   U2M flow (group access): Use `groups`.
*   U2M flow (user access): Use `oid`.
*   M2M flow (OAuth App access): Use `azp`.

*   For other IdPs, refer to the specific IdP documentation.

Supported `subject_claim` values are:

*   `oid`: Object ID of the user.
*   `azp`: Client ID of the OAuth app.
*   `groups`: Object ID of the group.
*   `sub`: Subject identifier for other use cases.

[`update_time`](https://docs.databricks.com/api/workspace/recipientfederationpolicies/getfederationpolicy#update_time)date-time

System-generated timestamp indicating when the policy was last updated.

# Response samples

200

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
