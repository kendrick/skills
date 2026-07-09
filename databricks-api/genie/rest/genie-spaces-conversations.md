# Genie Spaces & Conversations -- Databricks Genie REST API

Genie spaces CRUD, conversations, messages, query execution, result downloads, feedback.

> See also: genie-evals (for benchmarking/evaluation)
> Raw docs: ../docs/raw/ -- for full endpoint details, read genie-{operation}.md

## Auth

```
Authorization: Bearer <token>
Base URL: https://<workspace>.cloud.databricks.com
API scope: genie
```

## Endpoint Summary

| Method | Path | Purpose |
|--------|------|---------|
| POST | /api/2.0/genie/spaces | Create space |
| GET | /api/2.0/genie/spaces | List spaces |
| GET | /api/2.0/genie/spaces/{space_id} | Get space |
| PATCH | /api/2.0/genie/spaces/{space_id} | Update space |
| DELETE | /api/2.0/genie/spaces/{space_id} | Trash space |
| POST | /api/2.0/genie/spaces/{space_id}/start-conversation | Start conversation |
| GET | /api/2.0/genie/spaces/{space_id}/conversations | List conversations |
| DELETE | /api/2.0/genie/spaces/{space_id}/conversations/{conversation_id} | Delete conversation |
| POST | .../conversations/{conversation_id}/messages | Create message |
| GET | .../messages/{message_id} | Get message |
| GET | .../conversations/{conversation_id}/messages | List messages |
| DELETE | .../messages/{message_id} | Delete message |
| POST | .../messages/{message_id}/feedback | Send feedback |
| POST | .../attachments/{attachment_id}/execute-query | Execute attachment query |
| GET | .../attachments/{attachment_id}/query-result | Get attachment query result |
| POST | .../attachments/{attachment_id}/downloads | Generate full download |
| GET | .../attachments/{attachment_id}/downloads/{download_id} | Get download result |

---

## 1. Spaces

### Create Space
```
POST /api/2.0/genie/spaces
```
```json
{
  "serialized_space": "<JSON string>",
  "warehouse_id": "abc123",
  "title": "Sales Genie",
  "description": "Sales analytics space",
  "parent_path": "/Workspace/Users/me"
}
```
Required: `serialized_space` (string), `warehouse_id` (string).
Optional: `title`, `description`, `parent_path`, `etag` (all string; `etag` and `parent_path` are Public Preview).
Returns: `space_id`, `title`, `description`, `serialized_space`, `warehouse_id`, `etag`, `parent_path`.

### List Spaces
```
GET /api/2.0/genie/spaces?page_size=20&page_token=<token>
```
Optional: `page_size` (int32, max 100, default 20), `page_token` (string).
Returns: `spaces[]` (excludes `serialized_space`), `next_page_token`.

### Get Space
```
GET /api/2.0/genie/spaces/{space_id}
```
Required path: `space_id` (uuid).
Returns: full space object including `serialized_space`.

### Update Space
```
PATCH /api/2.0/genie/spaces/{space_id}
```
```json
{"title": "Updated Title", "serialized_space": "<JSON string>"}
```
Required path: `space_id` (string). Body fields all optional: `title`, `description`, `serialized_space`, `warehouse_id`, `etag`, `parent_path` (`etag` and `parent_path` are Public Preview).
Note: `serialized_space` is a full replacement, not a merge. Pass `etag` (from a prior GET or UPDATE response) so the update fails if the space changed in the meantime; omit `etag` to skip the check. `parent_path` moves the space to a different workspace folder.

### Trash Space
```
DELETE /api/2.0/genie/spaces/{space_id}
```
Required path: `space_id` (uuid). Returns `{}`.

---

## 2. Conversations

### Start Conversation
```
POST /api/2.0/genie/spaces/{space_id}/start-conversation
```
```json
{"content": "What were total sales last month?"}
```
Required path: `space_id`. Required body: `content` (string).
Returns: `conversation_id`, `message_id`, `conversation` object, `message` object with `status`.

### List Conversations
```
GET /api/2.0/genie/spaces/{space_id}/conversations?page_size=20&include_all=false
```
Optional: `page_size` (int32, max 100), `page_token`, `include_all` (bool -- requires CAN MANAGE).
Returns: `conversations[]` with `conversation_id`, `title`, `created_timestamp`.

### Delete Conversation
```
DELETE /api/2.0/genie/spaces/{space_id}/conversations/{conversation_id}
```
Returns `{}`.

---

## 3. Messages

### Create Message
```
POST /api/2.0/genie/spaces/{space_id}/conversations/{conversation_id}/messages
```
```json
{"content": "Show top 10 customers by revenue"}
```
Required path: `space_id`, `conversation_id`. Required body: `content` (string).
Returns: message object with `message_id`, `status`, `attachments` (initially null).

### Get Message
```
GET .../spaces/{space_id}/conversations/{conversation_id}/messages/{message_id}
```
Returns: full message with `status`, `attachments[]`, `error`, `feedback`.

### List Messages
```
GET .../spaces/{space_id}/conversations/{conversation_id}/messages?page_size=20
```
Optional: `page_size` (int32, max 100), `page_token`.
Returns: `messages[]`, `next_page_token`.

### Delete Message
```
DELETE .../spaces/{space_id}/conversations/{conversation_id}/messages/{message_id}
```
Returns `{}`.

### Message Status Values
`SUBMITTED` > `FETCHING_METADATA` > `FILTERING_CONTEXT` > `ASKING_AI` > `PENDING_WAREHOUSE` > `EXECUTING_QUERY` > `COMPLETED` | `FAILED` | `CANCELLED` | `QUERY_RESULT_EXPIRED`

---

## 4. Query Results

### Execute Attachment Query
```
POST .../messages/{message_id}/attachments/{attachment_id}/execute-query
```
Re-executes SQL for an expired query attachment. All path params required: `space_id`, `conversation_id`, `message_id`, `attachment_id`.
Returns: `statement_response` with `statement_id`, `manifest`, `result`, `status`.

### Get Attachment Query Result
```
GET .../messages/{message_id}/attachments/{attachment_id}/query-result
```
Available only when message status is `EXECUTING_QUERY` or `COMPLETED`.
Returns: `statement_response` (same structure as execute).

### Generate Full Download
```
POST .../attachments/{attachment_id}/downloads
```
Initiates full result download. Returns: `download_id`, `download_id_signature`.

### Get Download Result
```
GET .../attachments/{attachment_id}/downloads/{download_id}?download_id_signature=<jwt>
```
Required path: `download_id`. Required query: `download_id_signature` (string).
Returns: `statement_response` with `external_links[]` containing presigned URLs.

---

## 5. Feedback

### Send Message Feedback
```
POST .../messages/{message_id}/feedback
```
```json
{"rating": "POSITIVE", "comment": "Got the join wrong"}
```
Required body: `rating` (enum: `POSITIVE`, `NEGATIVE`, `NONE`). Optional: `comment` (string, <= 5000 chars; Public Preview) -- free-text feedback stored alongside the rating.
Returns `{}`.

---

## Common Errors

| HTTP | Code | Meaning |
|------|------|---------|
| 400 | BAD_REQUEST | Invalid request body or params |
| 401 | UNAUTHORIZED | Missing/invalid auth credentials |
| 403 | PERMISSION_DENIED | Insufficient permissions |
| 404 | NOT_FOUND | Resource does not exist |
| 404 | FEATURE_DISABLED | Genie feature not enabled |
| 500 | INTERNAL_ERROR | Server error |

## Gotchas

- `serialized_space` is a JSON **string** (not an object) -- must be serialized/escaped before sending.
- List Spaces **excludes** `serialized_space` -- use Get Space to retrieve full content.
- Update Space `serialized_space` is a **full replacement**, not a partial merge.
- Start Conversation returns the first message in an async processing state -- poll Get Message until `status` is `COMPLETED` or `FAILED`.
- Query results expire. When status is `QUERY_RESULT_EXPIRED`, call Execute Attachment Query to re-run.
- Full download uses `EXTERNAL_LINKS` disposition with presigned URLs -- do NOT send `Authorization` header when downloading from these URLs.
- `include_all` on List Conversations requires CAN MANAGE permission on the space.
- `id` fields on conversation/message objects are deprecated -- use `conversation_id` / `message_id` instead.
- Pagination: max `page_size` is 100 across all list endpoints; default is 20.
