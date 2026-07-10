---
name: databricks-marketplace
description: Marketplace APIs for three audiences—consumers, listing providers, and private exchange admins.
---

# Databricks Marketplace API Skills

> Parent: [../SKILL.md](../SKILL.md) (top-level Databricks API router)
> API status: Public Preview. The `marketplace` token scope is gated as preview; verify availability for your workspace before building production flows on it.

## Auth

`Authorization: Bearer <PAT-or-OAuth-token>` against `https://<workspace-host>`. Python SDK: `WorkspaceClient()` auto-detects from env or `.databrickscfg`. See [../SKILL.md](../SKILL.md) for the full auth block (account-level base URL, OAuth M2M, notebook auto-auth in DBR 13.1+).

Domain-specific: the token needs the **`marketplace`** API scope. That scope is in public preview; service principals created against an older account may need re-issuing.

## Quick Lookup

Read the matching bucket in `rest/` (HTTP) or `python-sdk/` (SDK).

| Task                                     | Bucket                     |
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

## REST Buckets

| Bucket                             | Scope                                                         | Endpoints |
| -------------------------------- | ------------------------------------------------------------- | --------- |
| `rest/mkt-consumer.md`           | Browse listings, install products, personalization, providers | 17        |
| `rest/mkt-provider-listings.md`  | Provider profiles, listings, files, analytics dashboards      | 20        |
| `rest/mkt-provider-exchanges.md` | Private exchanges, listing associations, filters              | 13        |

## Python SDK Buckets

| Bucket                                   | Key Clients                                                                                                                                          |
| -------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| `python-sdk/mkt-consumer.md`           | `w.consumer_listings`, `w.consumer_installations`, `w.consumer_fulfillments`, `w.consumer_personalization_requests`, `w.consumer_providers`          |
| `python-sdk/mkt-provider-listings.md`  | `w.provider_listings`, `w.provider_files`, `w.provider_providers`, `w.provider_personalization_requests`, `w.provider_provider_analytics_dashboards` |
| `python-sdk/mkt-provider-exchanges.md` | `w.provider_exchanges`, `w.provider_exchange_filters`                                                                                                |
