---
name: refresh-skill
description: Maintainer workflow—detect drift between the compressed databricks-api skill files and upstream Databricks docs, then apply updates.
---

# Databricks Skill Refresh

Detect and apply drift between the compressed skill files in `databricks-api/` and the upstream Databricks docs.

Each domain has a manifest at `databricks-api/{domain}/_docs/sources.json` tracking every endpoint's source URL and the sha256 of its last-known raw doc. A bash script (`tools/refresh.sh`, sibling of this skill in `_maintenance/`) handles the deterministic side (fetch, diff, report). This skill handles the semantic side (decide which compressed skill files need editing, propose changes, apply).

## Prereqs

`bash`, `curl`, `jq`, and `shasum` (or `sha256sum`). The script self-checks and errors with install hints if anything's missing.

## Workflow

### 0. cd to the Maintenance Dir

All commands below run from `_maintenance/`, the parent of the directory holding this SKILL.md. `cd` there first; `tools/refresh.sh` and the drift reports live there, and the script finds the domains in the sibling `databricks-api/` on its own.

### 1. Figure Out the Scope

Ask the user which domain to refresh, or whether to run against all 8. Default to asking before running an all-domains refresh (it's roughly 16 minutes of Jina fetches at the script's 3s rate limit).

### 2. Run the Drift Check

```bash
bash tools/refresh.sh --check --domain <name>
```

Omit `--domain` for all domains. This writes `refresh-report-{domain}.md` in `_maintenance/` if anything's changed or failed. If nothing drifted, the script reports "no drift" and writes nothing; exit cleanly.

### 3. Read the Report

Open `refresh-report-{domain}.md`. It has sections per operation: CHANGED (with unified diff), FAILED (fetch errors), UNTRACKED (raw files not in manifest), MISSING (manifest entries without a corresponding raw file).

For UNTRACKED: run `bash tools/refresh.sh --backfill --domain <name>` to add them to the manifest. No semantic work needed.

For MISSING: investigate whether the raw file was deleted intentionally or by accident. Restoring requires re-fetching from the URL recorded in the manifest.

For FAILED: the Jina fetch errored. Likely a transient network issue or a Databricks URL that's been moved or renamed. Retry once; if it persists, flag for the user to investigate.

For CHANGED: the real semantic work, see step 4.

### 4. Update the Compressed Skill Files

For each CHANGED operation in the report:

1. Locate which bucket file(s) contain it. Compressed skills live at `databricks-api/{domain}/rest/*.md` and `databricks-api/{domain}/python-sdk/*.md`. Grep for the operation's path or method name to find the right bucket.
2. Read the diff. Classify the change: field rename, new optional param, deprecation note, new endpoint added upstream, behavior or permission change, or cosmetic doc edit that doesn't affect the API contract.
3. For non-trivial changes, dispatch a subagent (general-purpose) with the diff plus the relevant bucket files and ask it to propose specific edits. Cosmetic doc-only changes don't need bucket-file updates; acknowledge and move on.
4. Present the proposed edits to the user for review. Apply on approval.

Done when every CHANGED operation in the report is either applied to its bucket file(s) or explicitly classified cosmetic—nothing left unaccounted for.

### 5. Commit the Manifest Update

After the user approves the compressed-skill changes:

```bash
bash tools/refresh.sh --apply --domain <name>
```

This overwrites the raw docs in `databricks-api/{domain}/_docs/raw/` with the freshly fetched versions and bumps `sha256` + `fetched_at` in the manifest. The raw doc cache and the manifest are now back in sync with upstream.

### 6. Clean Up

Delete `refresh-report-{domain}.md` from `_maintenance/` once changes are committed. It's a transient artifact, not meant to be checked in.

## Troubleshooting

### "Every operation shows as CHANGED"

If `--check` flags 80%+ of a domain's ops as changed, the cache is probably polluted with Jina render-timeout placeholders. The placeholder is a partial-render warning that Jina returns when a JS-heavy doc page doesn't finish hydrating in time; it gets cached during transient Jina failures and shows up as phantom drift on subsequent runs.

Fix:

```bash
bash tools/refresh.sh --refetch-broken --domain <name>
```

This scans `databricks-api/{domain}/_docs/raw/` for placeholder files, re-fetches each via the hardened `fetch_clean` (longer `X-Timeout` and one retry), and bumps the manifest entry. Omit `--domain` to clean every domain. Re-run `--check` after; if drift drops to a sensible number, the original "drift" was phantom.

## Adding a New Domain

When a new domain is added via `databricks-skill-generator-prompt.md` (sibling of this skill in `_maintenance/`), the generator writes `databricks-api/{domain}/_docs/sources.json` at build time (Phase 0d). No backfill needed for new domains.

For domains that pre-date this skill, run `bash tools/refresh.sh --backfill --domain <name>` once to bootstrap the manifest.

## When NOT to Use This Skill

- The user wants to add a brand-new domain: use `databricks-skill-generator-prompt.md` instead.
- The user wants to fix a known bug in a compressed skill file unrelated to upstream drift: edit the file directly.
- The user wants a one-off Databricks doc lookup: fetch the page directly via Jina or the docs site.
