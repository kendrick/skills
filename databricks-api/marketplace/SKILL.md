---
name: databricks-marketplace
description: Databricks Marketplace APIs. There are three distinct audiences. Use as a consumer to browse listings, install or uninstall data products, or request personalization; as a provider to publish or update listings, upload files, view analytics, or handle incoming personalization requests; as an account admin to create private exchanges, manage exchange listings, or set exchange filters.
---

# Databricks Marketplace API Skills

> Parent: [../SKILL.md](../SKILL.md) (top-level Databricks API router)
> API status: Public Preview. The `marketplace` token scope is gated as preview; verify availability for your workspace before building production flows on it.

## Usage

1. Match your task to a file using Quick Lookup below
2. Read the file in `rest/` (HTTP) or `python-sdk/` (SDK)
3. For cross-domain tasks, read multiple files

## Quick Lookup

| Task                                     | File                     |
| ---------------------------------------- | ------------------------ |
| Browse or search listings as a consumer  | `mkt-consumer`           |
| Install or uninstall a data product      | `mkt-consumer`           |
| Request personalized access to a listing | `mkt-consumer`           |
| View providers or fulfillment details    | `mkt-consumer`           |
| Create or manage a provider profile      | `mkt-provider-listings`  |
| Publish, update, or delete a listing     | `mkt-provider-listings`  |
| Upload files for a listing               | `mkt-provider-listings`  |
| Handle incoming personalization requests | `mkt-provider-listings`  |
| View provider analytics dashboards       | `mkt-provider-listings`  |
| Create or manage a private exchange      | `mkt-provider-exchanges` |
| Add/remove listings from an exchange     | `mkt-provider-exchanges` |
| Control exchange access with filters     | `mkt-provider-exchanges` |

## REST API Skills

| File                             | Scope                                                         | Endpoints |
| -------------------------------- | ------------------------------------------------------------- | --------- |
| `rest/mkt-consumer.md`           | Browse listings, install products, personalization, providers | 17        |
| `rest/mkt-provider-listings.md`  | Provider profiles, listings, files, analytics dashboards      | 20        |
| `rest/mkt-provider-exchanges.md` | Private exchanges, listing associations, filters              | 13        |

## Python SDK Skills

| File                                   | Key Clients                                                                                                                                          |
| -------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| `python-sdk/mkt-consumer.md`           | `w.consumer_listings`, `w.consumer_installations`, `w.consumer_fulfillments`, `w.consumer_personalization_requests`, `w.consumer_providers`          |
| `python-sdk/mkt-provider-listings.md`  | `w.provider_listings`, `w.provider_files`, `w.provider_providers`, `w.provider_personalization_requests`, `w.provider_provider_analytics_dashboards` |
| `python-sdk/mkt-provider-exchanges.md` | `w.provider_exchanges`, `w.provider_exchange_filters`                                                                                                |

## Auth

`Authorization: Bearer <PAT-or-OAuth-token>` against `https://<workspace-host>`. Python SDK: `WorkspaceClient()` auto-detects from env or `.databrickscfg`. See [../SKILL.md](../SKILL.md) for the full auth block (account-level base URL, OAuth M2M, notebook auto-auth in DBR 13.1+).

Domain-specific: the token needs the **`marketplace`** API scope. That scope is in public preview; service principals created against an older account may need re-issuing.
