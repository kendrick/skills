# Databricks API Skill File Generator

You are building Claude Code skill files from Databricks API documentation. This prompt works for ANY Databricks API domain — Unity Catalog, Marketplace, Apps, SQL, Jobs, Compute, etc. You will fetch raw docs, classify endpoints into task-oriented buckets, and produce two skill sets (REST-primary and Python SDK).

---

## Inputs

The user will provide:

1. **Domain name** — e.g., "Unity Catalog", "Marketplace", "Apps", "SQL Statement Execution"
2. **Endpoint list** — raw list of API endpoints (paths, methods, descriptions). May be a text dump, URLs, OpenAPI spec, or copy-paste from docs.
3. **Priority guidance (optional)** — which workflows matter most to them. Use this to front-load detail in those areas and compress harder on low-priority endpoints.

---

## Phase 0: Fetch documentation via Jina Reader

### 0a. Construct doc URLs

For each endpoint, construct the Databricks REST API reference URL:

```
https://docs.databricks.com/api/workspace/{service-name}/{operation-name}
```

Common patterns:

- `POST /api/2.0/serving-endpoints` → `.../workspace/servingendpoints/create`
- `GET /api/2.1/unity-catalog/catalogs/{name}` → `.../workspace/catalogs/get`
- `DELETE /api/2.0/sql/warehouses/{id}` → `.../workspace/warehouses/delete`

The service name in the URL is typically the resource noun (lowercase, no hyphens). If ambiguous, ask the user.

Some endpoints live under the **account** API instead of workspace:

```
https://docs.databricks.com/api/account/{service-name}/{operation-name}
```

### 0b. Fetch via Jina Reader

```bash
mkdir -p docs/raw
for url in "${URLS[@]}"; do
  filename=$(echo "$url" | sed 's|.*/workspace/||; s|.*/account/||; s|/|-|g').md
  curl -s "https://r.jina.ai/${url}" -o "docs/raw/${filename}"
  sleep 3  # rate limit
done
```

### 0c. Clean raw fetches

Jina captures the full page including sidebar navigation. Databricks API docs have a consistent structure — a giant nav block between the H1 title and the first H2 (the actual endpoint heading). Strip this on every file:

```bash
for f in docs/raw/*.md; do
  awk '
    NR<=5 { print; next }                    # keep Jina metadata (Title, URL, etc.)
    /^## / && !found { found=1 }             # first ## marks content start
    found { print }                           # print everything from first ## onward
  ' "$f" > "${f}.tmp" && mv "${f}.tmp" "$f"
done
```

This typically removes ~300 lines of sidebar links per file, cutting raw file sizes by 30-60%. Run this **before** classification and skill generation — smaller files mean faster agent processing and less noise.

### 0d. Handle failures

Jina can't extract client-rendered (SPA) pages. For each fetch, check if the output is substantive (>500 chars of content after cleanup, not just nav chrome). Mark failures as `[unfetched]`.

**Fallback options to suggest to the user:**

1. Try the Azure variant: `https://learn.microsoft.com/en-us/azure/databricks/...` (often server-rendered)
2. Use the Python SDK readthedocs page for method signatures
3. User provides the content manually
4. Use `databricks` CLI `--help` output for the relevant command group

### 0e. Write the source manifest

After fetch + cleanup, generate `{domain}/docs/sources.json` so the refresh tooling can detect drift later. One entry per successfully fetched raw doc:

```json
[
  {
    "operation": "catalogs-create",
    "url": "https://docs.databricks.com/api/workspace/catalogs/create",
    "fetched_at": "<ISO 8601 UTC>",
    "sha256": "<shasum -a 256 of the cleaned raw file>"
  }
]
```

The easiest way is to run the repo's existing tool against the new domain:

```bash
bash tools/refresh.sh --backfill --domain <new-domain-slug>
```

It walks `docs/raw/`, parses each file's `URL Source:` line, hashes the content, and writes the manifest. Idempotent.

### 0f. Checkpoint

```
## Fetch Summary — [Domain Name]

Total endpoints:  XX
Fetched:          XX
Failed/empty:     XX (listed below)
Manifest entries: XX (should equal Fetched)

Failed URLs:
- [url] (reason)

Proceed to classification? (y/n)
```

Wait for confirmation.

---

## Phase 1: Classify endpoints into domain buckets

### How to define buckets

Buckets are NOT 1:1 with Databricks API service names. They're organized by **task/workflow** — what a developer is trying to accomplish. Guidelines:

1. **Read ALL endpoints first.** Look for natural workflow clusters — endpoints that are almost always used together.
2. **Name buckets by task domain**, not by API service. Good: `uc-grants-permissions`. Bad: `grants-api`.
3. **Target 3–8 buckets per domain.** Fewer than 3 means the files are too big. More than 8 means the router becomes unwieldy.
4. **Each bucket should have 5–25 endpoints.** Under 3 → merge into a neighbor. Over 30 → split.
5. **Cross-cutting concerns get their own bucket.** Auth, permissions, and monitoring often touch many resource types — give them a dedicated bucket rather than scattering across resource buckets.

### File naming convention

```
{domain-prefix}-{bucket-name}.md
```

Examples:

- Unity Catalog: `uc-catalog-schema-table.md`, `uc-grants-permissions.md`
- Marketplace: `mkt-provider-listings.md`, `mkt-private-exchanges.md`
- Apps: `apps-lifecycle.md`, `apps-deployment.md`
- SQL: `sql-warehouses.md`, `sql-statement-execution.md`

### Classification rules

- If an endpoint touches permissions/grants on ANY object type → permissions bucket
- If an endpoint is a CRUD operation on a core resource → resource lifecycle bucket
- If an endpoint is configuration/admin → admin bucket
- Deprecated endpoints → note in Gotchas, omit from main docs
- Endpoints that don't fit → create a new bucket, tell the user

### Print summary and wait

```
## Proposed Grouping — [Domain Name]

| Bucket | File name | # Endpoints | # Unfetched | Key endpoints |
|--------|-----------|-------------|-------------|---------------|
| ... | ... | ... | ... | ... |

New buckets: [list or "none"]
Merged buckets: [list or "none"]
Dropped endpoints: [list deprecated/irrelevant ones]

Confirm grouping? (y/n)
```

**Do not proceed until confirmed.**

---

## Phase 2: Generate skill files

Generate TWO files per bucket:

- `rest/{file-name}.md` — REST/HTTP primary
- `python-sdk/{file-name}.md` — Python SDK primary

### REST skill file template

````markdown
# [Bucket Name] — Databricks [Domain] REST API

> [One-line scope]
> See also: [related-file.md] (why)
> Raw docs: ../docs/raw/ — for full endpoint details, read {service}-{operation}.md

## Auth

All requests require:

- `Authorization: Bearer <PAT-or-OAuth-token>`
- Base URL: `https://<workspace-host>` (or `https://accounts.cloud.databricks.com` for account-level APIs)

[Domain-specific permission requirements if any]

## Endpoints

| Method | Path           | Purpose |
| ------ | -------------- | ------- |
| POST   | `/api/2.x/...` | ...     |
| GET    | `/api/2.x/...` | ...     |

## [Workflow Section]

### [Operation Name]

```
METHOD /api/2.x/path
```

**Request body:**

```json
{
	"required_field": "value",
	"common_optional": "value"
}
```

**Required:** `field1`, `field2`
**Optional (notable):** `field3` (type — when you'd use it)

**Response:** `200` — Returns `ObjectType` with key fields: `id`, `name`, `status`, `created_at`

**Permissions:** [Required grants/roles]

### [Next operation...]

## Common Errors

| Code | Meaning     |
| ---- | ----------- |
| 4xx  | Explanation |

## Gotchas

- [Non-obvious behaviors]
- [Ordering dependencies]
- [Known quirks]
````

### Python SDK skill file template

````markdown
# [Bucket Name] — Databricks Python SDK

> [One-line scope]
> See also: [related-file.md] (why)
> Raw docs: ../docs/raw/ — for full endpoint details, read {service}-{operation}.md
> Package: `databricks-sdk` — verify against your version (`pip show databricks-sdk`)

## Setup

```python
from databricks.sdk import WorkspaceClient
w = WorkspaceClient()
```

## SDK Clients

| Client       | Purpose           |
| ------------ | ----------------- |
| `w.resource` | Brief description |

## [Workflow Section]

### [Operation Name]

```python
result = w.resource.method(
    required_field="value",
    common_optional="value",
)
```

**Required:** `field: type`
**Optional (notable):** `field: type`
**Returns:** `DataClass`
**Permissions:** [Required grants/roles]

### [Next operation...]

## Common Patterns

### Pagination

```python
for item in w.resource.list():
    print(item.name)
```

### Error handling

```python
from databricks.sdk.errors import NotFound, PermissionDenied
```

## Gotchas

- [SDK-specific: version breaks, field renames, etc.]
````

### Compression rules

1. **One example per operation.** Required params + single most common optional param.
2. **Extract from Jina docs:** path, method, params (names + types), permissions, errors. Discard the rest.
3. **Skip:** marketing prose, UI instructions, pagination boilerplate, cross-cloud duplication, full JSON schemas, deprecated endpoints.
4. **Keep:** endpoint path/method, required vs optional params, permissions, one example, real error codes, ordering dependencies, gotchas. Each skill file's header points to `../docs/raw/` where the full fetched docs live — agents can `Read` those files for verbose details.
5. **Size target: 1,500–3,000 tokens per file.** Over 4K → split. Under 800 → merge.
6. **Cross-reference** related files with `> See also:` in the header.

---

## Phase 3: Generate the domain SKILL.md

Each domain gets its own `SKILL.md` as the entry point / router. This lives at `{domain}/SKILL.md`.

````markdown
---
name: databricks-[domain-slug]
description: [What the skill covers, plus concrete trigger phrases. See "Description guidance" below.]
---

# Databricks [Domain Name] API Skills

> Parent: [../SKILL.md](../SKILL.md) (top-level Databricks API router with auth, account vs workspace base URLs)
> API status: [GA | Public Preview | Private Preview]. Flag this if endpoints are pre-GA.

## Usage

1. Match your task to a file using Quick Lookup below
2. Read the file in `rest/` (HTTP) or `python-sdk/` (SDK)
3. For cross-domain tasks, read multiple files

## Quick Lookup

| Task                              | File          |
| --------------------------------- | ------------- |
| [Human-readable task description] | `[file-name]` |
| ...                               | ...           |

## REST API Skills

| File             | Scope         | Endpoints |
| ---------------- | ------------- | --------- |
| `rest/[file].md` | [Brief scope] | [count]   |
| ...              | ...           | ...       |

## Python SDK Skills

| File                   | Key Clients              |
| ---------------------- | ------------------------ |
| `python-sdk/[file].md` | `w.client1`, `w.client2` |
| ...                    | ...                      |

## Auth

`Authorization: Bearer <PAT-or-OAuth-token>` against the workspace base URL. Python SDK: `WorkspaceClient()` auto-detects from env or `.databrickscfg`. See [../SKILL.md](../SKILL.md) for the full auth block (account-level base URL, OAuth M2M, notebook auto-auth in DBR 13.1+).

[Domain-specific permission notes if any (e.g., required scopes, account-vs-workspace token requirements).]
````

### Description guidance

The `description` field is the primary triggering signal. Write it so Claude reaches for the skill on realistic user phrasings, not only when the user says the exact domain name. Pattern:

```
description: <one sentence on what the skill covers>. Use when <concrete task vocabulary 1>, <task vocabulary 2>, <task vocabulary 3>, or <adjacent phrasing a user might reach for>.
```

Lean into vocabulary a real user would type: verb phrases ("query a model endpoint", "rotate a recipient token"), product nouns ("AI Gateway", "provisioned throughput", "OIDC federation"), and tasks adjacent to the domain that someone might not realize this skill handles. Mention preview status if the API is preview-only; users sometimes filter by stability.

---

## Phase 4: Self-review

1. **Coverage:** List endpoints not included. Explain why (deprecated, unfetched) or add them.
2. **Token counts:**
   ```
   | File | Tokens | Status |
   |------|--------|--------|
   | rest/... | ~2,400 | OK |
   | ... | ... | ... |
   ```
3. **Cross-references:** Verify all `> See also:` links point to real files.
4. **Unfetched gaps:** Note which files may be incomplete.
5. **SDK caveat:** Remind user to spot-check `databricks-sdk` field names.
6. **Manifest integrity:** Confirm `{domain}/docs/sources.json` exists, has one entry per raw doc, and that each entry's `sha256` matches the on-disk file. Re-run `bash tools/refresh.sh --backfill --domain <name>` if anything's out of sync.

---

## Output structure

```
{domain}/
├── SKILL.md                    ← domain entry point / router
├── rest/                       ← REST/HTTP-primary skills
│   ├── {prefix}-{bucket}.md
│   └── ...
├── python-sdk/                 ← Python SDK-primary skills
│   ├── {prefix}-{bucket}.md
│   └── ...
└── docs/raw/                   ← raw fetched docs (reference)
    └── ...
```

This gets placed at `~/.local/share/skills/databricks/{domain}/`.

The **top-level** `~/.local/share/skills/databricks/SKILL.md` routes to each domain. That file is maintained separately (see below).

---

## Appendix: Top-level router pattern

When multiple domains exist, the top-level SKILL.md at `~/.local/share/skills/databricks/SKILL.md` is a two-tier router: it points at each domain's `SKILL.md`, and the domain SKILL.md points at its sub-files. The filesystem is the source of truth for layout; don't maintain a hand-written tree.

After generating a domain skill, update the top-level SKILL.md. Add a row to the Quick Routing table in the form `| [task description] | **[Domain]** | \`{domain}/SKILL.md\` |`. If the domain isn't built yet, mark the row inline (e.g., a `🔲 Not started` cell) so users scanning the table don't follow it to a dead path. Then update the Domain Status table: change the domain's row from `🔲 Not started` to `✅ Built` with file counts and notes.

---

## How to run

1. Tell me the **domain** (e.g., "Apps", "SQL", "Jobs")
2. Paste your **endpoint list**
3. Optionally: tell me which workflows are **highest priority**
4. Phase 0: I fetch docs via Jina
5. Phase 1: I classify and show you the grouping — wait for OK
6. Phase 2: I generate REST + Python SDK skill files
7. Phase 3: I write the domain SKILL.md
8. Phase 4: Self-review
9. **Phase 5: Update the top-level SKILL.md** (Quick Routing, Domain Status, Directory Structure)
