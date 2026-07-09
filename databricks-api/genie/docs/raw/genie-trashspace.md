Title: Trash Genie Space | Genie API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/genie/trashspace

Markdown Content:
## Trash Genie Space

`DELETE/api/2.0/genie/spaces/{space_id}`

Move a Genie Space to the trash.

API scopes:[`genie`](https://docs.databricks.com/api/workspace/api/scopes#genie)

### Path parameters

[`space_id`](https://docs.databricks.com/api/workspace/genie/trashspace#space_id)required uuid

Example`"e1ef34712a29169db030324fd0e1df5f"`

The ID associated with the Genie space to be sent to the trash.

### Responses

**200** Request completed successfully.

Request completed successfully.

 This method might return the following HTTP codes: 400, 401, 403, 404, 500

Error responses are returned in the following format:

{

"error_code":"Error code",

"message":"Human-readable error message."

}

# Possible error codes:

HTTP code

error_code

Description

400

BAD_REQUEST

Request is invalid.

401

UNAUTHORIZED

The request does not have valid authentication credentials for the operation.

403

PERMISSION_DENIED

Caller does not have permission to execute the specified operation.

404

NOT_FOUND

Operation was performed on a resource that does not exist.

500

INTERNAL_ERROR

Internal error.

# Response samples

200

{}
