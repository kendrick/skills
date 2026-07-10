Title: Set an artifact allowlist | Artifact Allowlists API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/artifactallowlists/update

Markdown Content:
## Set an artifact allowlist

`PUT/api/2.1/unity-catalog/artifact-allowlists/{artifact_type}`

Set the artifact allowlist of a certain artifact type. The whole artifact allowlist is replaced with the new allowlist. The caller must be a metastore admin or have the MANAGE ALLOWLIST privilege on the metastore.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`artifact_type`](https://docs.databricks.com/api/workspace/artifactallowlists/update#artifact_type)required string

Enum: `INIT_SCRIPT | LIBRARY_JAR | LIBRARY_MAVEN`

The artifact type of the allowlist.

### Request body

[`artifact_matchers`](https://docs.databricks.com/api/workspace/artifactallowlists/update#artifact_matchers)required Array of object

A list of allowed artifact match patterns.

Array [

[`artifact`](https://docs.databricks.com/api/workspace/artifactallowlists/update#artifact_matchers-artifact)required string

The artifact path or maven coordinate

[`match_type`](https://docs.databricks.com/api/workspace/artifactallowlists/update#artifact_matchers-match_type)required string

Enum: `PREFIX_MATCH`

The pattern matching type of the artifact

 ]

### Responses

**200** Request completed successfully.

Request completed successfully.

[`artifact_matchers`](https://docs.databricks.com/api/workspace/artifactallowlists/update#artifact_matchers)Array of object

A list of allowed artifact match patterns.

Array [

[`artifact`](https://docs.databricks.com/api/workspace/artifactallowlists/update#artifact_matchers-artifact)string

The artifact path or maven coordinate

[`match_type`](https://docs.databricks.com/api/workspace/artifactallowlists/update#artifact_matchers-match_type)string

Enum: `PREFIX_MATCH`

The pattern matching type of the artifact

 ]

[`created_at`](https://docs.databricks.com/api/workspace/artifactallowlists/update#created_at)int64

Time at which this artifact allowlist was set, in epoch milliseconds.

[`created_by`](https://docs.databricks.com/api/workspace/artifactallowlists/update#created_by)string

Username of the user who set the artifact allowlist.

[`metastore_id`](https://docs.databricks.com/api/workspace/artifactallowlists/update#metastore_id)string

Unique identifier of parent metastore.

# Request samples

JSON

{

"artifact_matchers":[

{

"artifact":"string",

"match_type":"PREFIX_MATCH"

}

]

}

# Response samples

200

{

"artifact_matchers":[

{

"artifact":"string",

"match_type":"PREFIX_MATCH"

}

],

"created_at":0,

"created_by":"string",

"metastore_id":"string"

}
