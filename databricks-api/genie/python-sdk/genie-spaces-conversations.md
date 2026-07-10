# Genie Spaces & Conversations -- Databricks Python SDK

> Raw docs: ../_docs/raw/ -- for full endpoint details, read genie-{operation}.md
> Package: databricks-sdk

## Setup

```python
from databricks.sdk import WorkspaceClient

w = WorkspaceClient()  # uses DATABRICKS_HOST + DATABRICKS_TOKEN env vars
```

## SDK Client Map

All operations use `w.genie.<method>(...)`.

| SDK Method | REST Equivalent |
|-----------|-----------------|
| `create_space()` | POST /api/2.0/genie/spaces |
| `list_spaces()` | GET /api/2.0/genie/spaces |
| `get_space()` | GET /api/2.0/genie/spaces/{space_id} |
| `update_space()` | PATCH /api/2.0/genie/spaces/{space_id} |
| `trash_space()` | DELETE /api/2.0/genie/spaces/{space_id} |
| `start_conversation()` | POST .../start-conversation |
| `list_conversations()` | GET .../conversations |
| `delete_conversation()` | DELETE .../conversations/{id} |
| `create_message()` | POST .../messages |
| `get_message()` | GET .../messages/{id} |
| `list_conversation_messages()` | GET .../messages |
| `delete_conversation_message()` | DELETE .../messages/{id} |
| `send_message_feedback()` | POST .../messages/{id}/feedback |
| `execute_message_attachment_query()` | POST .../execute-query |
| `get_message_attachment_query_result()` | GET .../query-result |
| `generate_download_full_query_result()` | POST .../downloads |
| `get_download_full_query_result()` | GET .../downloads/{id} |

---

## 1. Spaces

```python
# Create
space = w.genie.create_space(
    serialized_space='{"version": 2, "data_sources": {...}}',  # required, JSON string
    warehouse_id="abc123",  # required
    title="Sales Genie",
    description="Sales analytics"
)
print(space.space_id)

# List (paginated)
for page in w.genie.list_spaces(page_size=50):
    for s in page.spaces:
        print(s.space_id, s.title)

# Get (includes serialized_space)
space = w.genie.get_space(space_id="<space_id>")

# Update (serialized_space is full replacement)
w.genie.update_space(space_id="<space_id>", title="New Title")

# Update with optimistic concurrency (Public Preview) -- pass etag from a prior get_space()
space = w.genie.get_space(space_id="<space_id>")
w.genie.update_space(space_id="<space_id>", title="New Title", etag=space.etag)

# Move space to a different workspace folder (Public Preview)
w.genie.update_space(space_id="<space_id>", parent_path="/Workspace/Users/me/genie")

# Trash
w.genie.trash_space(space_id="<space_id>")
```

---

## 2. Conversations

```python
# Start conversation (creates first message)
result = w.genie.start_conversation(
    space_id="<space_id>",
    content="What were total sales last month?"
)
conv_id = result.conversation_id
msg_id = result.message_id

# List conversations
convos = w.genie.list_conversations(space_id="<space_id>", page_size=50)

# List all users' conversations (requires CAN MANAGE)
convos = w.genie.list_conversations(space_id="<space_id>", include_all=True)

# Delete conversation
w.genie.delete_conversation(space_id="<space_id>", conversation_id=conv_id)
```

---

## 3. Messages

```python
# Create follow-up message
msg = w.genie.create_message(
    space_id="<space_id>",
    conversation_id=conv_id,
    content="Break that down by region"
)
msg_id = msg.message_id

# Poll until complete
import time
while True:
    msg = w.genie.get_message(
        space_id="<space_id>",
        conversation_id=conv_id,
        message_id=msg_id
    )
    if msg.status in ("COMPLETED", "FAILED", "CANCELLED"):
        break
    time.sleep(2)

# List messages in conversation
msgs = w.genie.list_conversation_messages(
    space_id="<space_id>",
    conversation_id=conv_id
)

# Delete message
w.genie.delete_conversation_message(
    space_id="<space_id>",
    conversation_id=conv_id,
    message_id=msg_id
)
```

### Message Status Flow
`SUBMITTED` > `FETCHING_METADATA` > `FILTERING_CONTEXT` > `ASKING_AI` > `PENDING_WAREHOUSE` > `EXECUTING_QUERY` > `COMPLETED` | `FAILED` | `CANCELLED` | `QUERY_RESULT_EXPIRED`

---

## 4. Query Results

```python
# Get query result from attachment (status must be EXECUTING_QUERY or COMPLETED)
attachment_id = msg.attachments[0].attachment_id
result = w.genie.get_message_attachment_query_result(
    space_id="<space_id>",
    conversation_id=conv_id,
    message_id=msg_id,
    attachment_id=attachment_id
)
# result.statement_response contains manifest, result data, statement_id

# Re-execute expired query
result = w.genie.execute_message_attachment_query(
    space_id="<space_id>",
    conversation_id=conv_id,
    message_id=msg_id,
    attachment_id=attachment_id
)

# Generate full download (for large results)
download = w.genie.generate_download_full_query_result(
    space_id="<space_id>",
    conversation_id=conv_id,
    message_id=msg_id,
    attachment_id=attachment_id
)
download_id = download.download_id
download_sig = download.download_id_signature

# Poll download status
dl_result = w.genie.get_download_full_query_result(
    space_id="<space_id>",
    conversation_id=conv_id,
    message_id=msg_id,
    attachment_id=attachment_id,
    download_id=download_id,
    download_id_signature=download_sig
)
# dl_result.statement_response.result.external_links[] has presigned URLs
```

---

## 5. Feedback

```python
w.genie.send_message_feedback(
    space_id="<space_id>",
    conversation_id=conv_id,
    message_id=msg_id,
    rating="POSITIVE",      # POSITIVE | NEGATIVE | NONE
    comment="Looks right"   # optional, Public Preview, <= 5000 chars
)
```

---

## Common Patterns

### Ask-and-wait helper
```python
def ask_genie(w, space_id, question, timeout=120):
    result = w.genie.start_conversation(space_id=space_id, content=question)
    conv_id, msg_id = result.conversation_id, result.message_id
    deadline = time.time() + timeout
    while time.time() < deadline:
        msg = w.genie.get_message(space_id=space_id, conversation_id=conv_id, message_id=msg_id)
        if msg.status == "COMPLETED":
            return msg
        if msg.status in ("FAILED", "CANCELLED"):
            raise RuntimeError(f"Genie failed: {msg.error}")
        time.sleep(2)
    raise TimeoutError("Genie did not complete in time")
```

---

## Gotchas

- `serialized_space` is a JSON **string**, not a dict -- serialize with `json.dumps()` before passing.
- List Spaces **excludes** `serialized_space` -- use `get_space()` for full content.
- `update_space()` replaces `serialized_space` entirely -- fetch first with `get_space()`, modify, then update.
- Messages are async -- always poll `get_message()` until terminal status (`COMPLETED`/`FAILED`/`CANCELLED`).
- When status is `QUERY_RESULT_EXPIRED`, call `execute_message_attachment_query()` to re-run the SQL.
- Full download presigned URLs must be fetched **without** an Authorization header.
- `include_all=True` on `list_conversations()` requires CAN MANAGE permission.
- `id` fields on response objects are deprecated -- use `conversation_id` / `message_id`.
