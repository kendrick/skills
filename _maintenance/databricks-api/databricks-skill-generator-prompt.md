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
mkdir -p _docs/raw
for url in "${URLS[@]}"; do
  filename=$(echo "$url" | sed 's|.*/workspace/||; s|.*/account/||; s|/|-|g').md
  curl -s "https://r.jina.ai/${url}" -o "_docs/raw/${filename}"
  sleep 3  # rate limit
done
```

### 0c. Clean raw fetches

Jina captures the full page including sidebar navigation. Databricks API docs have a consistent structure — a giant nav block between the H1 title and the first H2 (the actual endpoint heading). Strip this on every file:

```bash
for f in _docs/raw/*.md; do
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

After fetch + cleanup, generate `{domain}/_docs/sources.json` so the refresh tooling can detect drift later. One entry per successfully fetched raw doc:

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

The easiest way is to run the repo's existing tool against the new domain (from `_maintenance/`):

```bash
bash tools/refresh.sh --backfill --domain <new-domain-slug>
```

It walks `_docs/raw/`, parses each file's `URL Source:` line, hashes the content, and writes the manifest. Idempotent.

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
> Raw docs: ../_docs/raw/ — for full endpoint details, read {service}-{operation}.md

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

- [Cross-cutting quirks ONLY — behaviors that span operations (TTLs, service-wide limits, ordering across endpoints). A caveat scoped to one operation lives inline in that operation's section, stated once.]
````

### Python SDK skill file template

````markdown
# [Bucket Name] — Databricks Python SDK

> [One-line scope]
> See also: [related-file.md] (why)
> Raw docs: ../_docs/raw/ — for full endpoint details, read {service}-{operation}.md
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

- [Cross-cutting quirks ONLY (version breaks, service-wide behavior). Operation-scoped caveats live inline with their operation, stated once.]
````

### Compression rules

1. **One example per operation.** Required params + single most common optional param.
2. **Extract from Jina docs:** path, method, params (names + types), permissions, errors. Discard the rest.
3. **Skip:** marketing prose, UI instructions, pagination boilerplate, cross-cloud duplication, full JSON schemas, deprecated endpoints.
4. **Keep:** endpoint path/method, required vs optional params, permissions, one example, real error codes, ordering dependencies, gotchas. Each skill file's header points to `../_docs/raw/` where the full fetched docs live — agents can `Read` those files for verbose details.
5. **Size target: 1,500–3,000 tokens per file.** Over 4K → split. Under 800 → merge.
6. **Cross-reference** related files with `> See also:` in the header.
7. **Co-locate caveats with their operation.** Each caveat is stated once, next to the operation it constrains. The Gotchas section holds only cross-cutting quirks that span operations — never a restatement of something already inline.

---

## Phase 3: Generate the domain SKILL.md

Each domain gets its own `SKILL.md` as the entry point / router. This lives at `{domain}/SKILL.md`.

````markdown
---
name: databricks-[domain-slug]
description: [One line: what the domain covers. See "Description guidance" below.]
---

# Databricks [Domain Name] API Skills

> Parent: [../SKILL.md](../SKILL.md) (top-level Databricks API router with auth, account vs workspace base URLs)
> API status: [GA | Public Preview | Private Preview]. Flag this only if endpoints are pre-GA.

## Auth

`Authorization: Bearer <PAT-or-OAuth-token>` against the workspace base URL. Python SDK: `WorkspaceClient()` auto-detects from env or `.databrickscfg`. See [../SKILL.md](../SKILL.md) for the full auth block (account-level base URL, OAuth M2M, notebook auto-auth in DBR 13.1+).

[Domain-specific permission notes if any (e.g., required scopes, account-vs-workspace token requirements).]

[Domain-wide gotchas worth surfacing before routing, if any (API version traps, expiring URLs). Keep to a line or two each.]

## Quick Lookup

Read the matching bucket in `rest/` (HTTP) or `python-sdk/` (SDK).

| Task                              | Bucket        |
| --------------------------------- | ------------- |
| [Human-readable task description] | `[file-name]` |
| ...                               | ...           |

## REST Buckets

| Bucket           | Scope         | Endpoints |
| ---------------- | ------------- | --------- |
| `rest/[file].md` | [Brief scope] | [count]   |
| ...              | ...           | ...       |

## Python SDK Buckets

| Bucket                 | Key Clients              |
| ---------------------- | ------------------------ |
| `python-sdk/[file].md` | `w.client1`, `w.client2` |
| ...                    | ...                      |
````

### Description guidance

Domain SKILL.mds are reached through the top-level router, never invoked on their own—under the symlink-only deployment this repo assumes, nested SKILL.mds don't register as skills, so trigger phrasing in their descriptions does no work. Write one human-facing line summarizing what the domain covers (the Quick Lookup table carries the routing), e.g.:

```
description: SQL APIs—warehouses, statement execution, saved queries, and alerts.
```

Trigger vocabulary belongs in ONE place: the top-level router's description, where invocation actually happens. If the new domain adds task vocabulary a user would type ("serve a model", "rotate a recipient token"), extend the top router's description enumeration instead.

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
6. **Manifest integrity:** Confirm `{domain}/_docs/sources.json` exists, has one entry per raw doc, and that each entry's `sha256` matches the on-disk file. Re-run `bash tools/refresh.sh --backfill --domain <name>` (from `_maintenance/`) if anything's out of sync.

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
└── _docs/raw/                   ← raw fetched docs (reference)
    └── ...
```

This gets placed at `databricks-api/{domain}/` in the skills repo (the shipped payload; maintainer tooling like this prompt lives in the sibling `_maintenance/`).

The **top-level** `databricks-api/SKILL.md` routes to each domain. That file is maintained separately (see below).

---

## Appendix: Top-level router pattern

When multiple domains exist, the top-level `databricks-api/SKILL.md` is a two-tier router: it points at each domain's `SKILL.md`, and the domain SKILL.md points at its sub-files. The filesystem is the source of truth for layout; don't maintain a hand-written tree.

After generating a domain skill, update the top-level SKILL.md: add a row to the Quick Routing table in the form `| [task description] | **[Domain]** | \`{domain}/SKILL.md\` |`, and remove the domain from the "Not yet covered" line beneath the table. Then update the status table in `databricks-api/README.md`, the single source of truth for build status.

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
9. **Phase 5: Update the top-level SKILL.md** (Quick Routing row, "Not yet covered" line) **and the README status table**
