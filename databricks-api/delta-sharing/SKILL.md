---
name: databricks-delta-sharing
description: Databricks Delta Sharing APIs covering shares, recipients, providers, activation tokens, and OIDC federation. Use when creating or updating a share, adding tables/volumes/notebooks to a share, granting share access, rotating recipient tokens, browsing what a provider has shared, activating a public share, or configuring OIDC federation policies for recipient identity.
---

# Databricks Delta Sharing API Skills

> Parent: [../SKILL.md](../SKILL.md) (top-level Databricks API router)

## Usage

1. Match your task to a file using Quick Lookup below
2. Read the file in `rest/` (HTTP) or `python-sdk/` (SDK)
3. For cross-domain tasks, read multiple files

## Quick Lookup

| Task | File |
|------|------|
| Create, list, update, or delete shares | `ds-shares` |
| Add/remove tables, volumes, notebooks from a share | `ds-shares` |
| Get or update share permissions | `ds-shares` |
| Create, list, update, or delete recipients | `ds-recipients` |
| Rotate recipient tokens | `ds-recipients` |
| View what shares a recipient has access to | `ds-recipients` |
| Create, list, update, or delete providers | `ds-providers` |
| Browse shares and assets from a provider | `ds-providers` |
| Activate a share (public, no auth) | `ds-recipient-auth` |
| Retrieve access token from activation URL | `ds-recipient-auth` |
| Manage OIDC federation policies for recipients | `ds-recipient-auth` |

## REST API Skills

| File | Scope | Endpoints |
|------|-------|-----------|
| `rest/ds-shares.md` | Share CRUD + permissions | 7 |
| `rest/ds-recipients.md` | Recipient CRUD + token rotation + share permissions | 7 |
| `rest/ds-providers.md` | Provider CRUD + browse shares/assets | 7 |
| `rest/ds-recipient-auth.md` | Activation (public) + OIDC federation policies | 6 |

## Python SDK Skills

| File | Key Clients |
|------|-------------|
| `python-sdk/ds-shares.md` | `w.shares` |
| `python-sdk/ds-recipients.md` | `w.recipients` |
| `python-sdk/ds-providers.md` | `w.providers` |
| `python-sdk/ds-recipient-auth.md` | `w.recipient_activation`, `w.recipient_federation_policies` |

## Auth

`Authorization: Bearer <PAT-or-OAuth-token>` against `https://<workspace-host>`. Python SDK: `WorkspaceClient()` auto-detects from env or `.databrickscfg`. See [../SKILL.md](../SKILL.md) for the full auth block (account-level base URL, OAuth M2M, notebook auto-auth in DBR 13.1+).

Domain-specific: recipient *activation* endpoints are public, so no auth header is required. Everything else needs the workspace token.
