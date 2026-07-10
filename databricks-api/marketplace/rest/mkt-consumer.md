# Marketplace Consumer -- Databricks Marketplace REST API

Browse listings, install data products, manage installations, personalization requests, view providers.

> See also: mkt-provider-listings (for publishing), mkt-provider-exchanges (for private exchanges)
> Raw docs: ../_docs/raw/ -- for full endpoint details, read {service}-{operation}.md

## Auth

All endpoints require OAuth token or PAT with **`marketplace`** API scope (preview).
Base: `https://{workspace-host}`

## Endpoint Summary

| Method | Path                                                                                | Purpose                                 |
| ------ | ----------------------------------------------------------------------------------- | --------------------------------------- |
| GET    | /api/2.1/marketplace-consumer/listings                                              | List all accessible listings            |
| GET    | /api/2.1/marketplace-consumer/listings/{id}                                         | Get single listing                      |
| GET    | /api/2.1/marketplace-consumer/listings:batchGet                                     | Batch get up to 50 listings             |
| GET    | /api/2.1/marketplace-consumer/search-listings                                       | Fuzzy search listings                   |
| GET    | /api/2.1/marketplace-consumer/installations                                         | List all installations                  |
| GET    | /api/2.1/marketplace-consumer/listings/{listing_id}/installations                   | List installations for a listing        |
| POST   | /api/2.1/marketplace-consumer/listings/{listing_id}/installations                   | Install from a listing                  |
| PUT    | /api/2.1/marketplace-consumer/listings/{listing_id}/installations/{installation_id} | Update installation / rotate token      |
| DELETE | /api/2.1/marketplace-consumer/listings/{listing_id}/installations/{installation_id} | Uninstall                               |
| GET    | /api/2.1/marketplace-consumer/listings/{listing_id}/content                         | Get listing content metadata            |
| GET    | /api/2.1/marketplace-consumer/listings/{listing_id}/fulfillments                    | List fulfillments                       |
| POST   | /api/2.1/marketplace-consumer/listings/{listing_id}/personalization-requests        | Create personalization request          |
| GET    | /api/2.1/marketplace-consumer/listings/{listing_id}/personalization-requests        | Get personalization request for listing |
| GET    | /api/2.1/marketplace-consumer/personalization-requests                              | List all personalization requests       |
| GET    | /api/2.1/marketplace-consumer/providers                                             | List providers                          |
| GET    | /api/2.1/marketplace-consumer/providers/{id}                                        | Get provider                            |
| GET    | /api/2.1/marketplace-consumer/providers:batchGet                                    | Batch get up to 50 providers            |

---

## 1. Listings

### List listings

```
GET /api/2.1/marketplace-consumer/listings
  ?page_size=20&page_token=...&is_free=true&assets=ASSET_TYPE_DATA_TABLE&categories=FINANCIAL&provider_ids=...&is_private_exchange=false&is_staff_pick=true
```

Optional query: `page_size` (int32), `page_token`, `assets` (array), `categories` (array), `tags` (`{tag_name, tag_values}` -- single tag filter, not an array), `is_free`, `is_private_exchange`, `is_staff_pick`, `provider_ids` (array).
Response: `{ listings: [...], next_page_token }`.

### Get listing

```
GET /api/2.1/marketplace-consumer/listings/{id}
```

Required path: `id`. Response: `{ listing: { id, summary, detail } }`.

### Batch get listings

```
GET /api/2.1/marketplace-consumer/listings:batchGet?ids=abc&ids=def
```

Optional query: `ids` (array, max 50). Response: `{ listings: [...] }`.

### Search listings

```
GET /api/2.1/marketplace-consumer/search-listings?query=weather+data&is_free=true
```

Required query: `query` (string, fuzzy match). Optional: `is_free`, `is_private_exchange`, `provider_ids`, `categories`, `assets`, `page_size`, `page_token`.
Response: `{ listings: [...], next_page_token }`.

---

## 2. Installations

### List all installations

```
GET /api/2.1/marketplace-consumer/installations?page_size=20
```

Optional: `page_size`, `page_token`. Response: `{ installations: [...], next_page_token }`.
Each installation: `{ id, listing_id, listing_name, catalog_name, share_name, repo_name, repo_path, status (INSTALLED|FAILED), recipient_type, error_message, token_detail, tokens }`.

### List installations for a listing

```
GET /api/2.1/marketplace-consumer/listings/{listing_id}/installations
```

Required path: `listing_id`. Optional query: `page_size`, `page_token`.

### Install from a listing

```
POST /api/2.1/marketplace-consumer/listings/{listing_id}/installations
```

```json
{
	"accepted_consumer_terms": { "version": "1.0" },
	"catalog_name": "my_catalog",
	"recipient_type": "DELTA_SHARING_RECIPIENT_TYPE_DATABRICKS"
}
```

Required path: `listing_id`. Body: `accepted_consumer_terms.version` (required string). Optional: `catalog_name`, `share_name`, `recipient_type` (DATABRICKS|OPEN), `repo_detail` (`{ repo_name, repo_path }` -- both required for git repo listings).
Response: `{ installation: { id, status, ... } }`.

### Update installation

```
PUT /api/2.1/marketplace-consumer/listings/{listing_id}/installations/{installation_id}
```

```json
{ "installation": { "catalog_name": "new_catalog" }, "rotate_token": true }
```

Required path: `listing_id`, `installation_id`. Body: `installation` (required object), `rotate_token` (bool -- rotates sharing token; forcibly rotates if `token_detail` empty).

### Uninstall

```
DELETE /api/2.1/marketplace-consumer/listings/{listing_id}/installations/{installation_id}
```

Required path: `listing_id`, `installation_id`. Response: `{}`.

---

## 3. Fulfillments

### Get listing content metadata

```
GET /api/2.1/marketplace-consumer/listings/{listing_id}/content?page_size=20
```

Required path: `listing_id`. Optional: `page_size`, `page_token`.
Response: `{ shared_data_objects: [{ name, data_object_type }], next_page_token }`. Types: TABLE, SCHEMA, NOTEBOOK_FILE, MODEL, VOLUME.

### List fulfillments

```
GET /api/2.1/marketplace-consumer/listings/{listing_id}/fulfillments
```

Required path: `listing_id`. Optional: `page_size`, `page_token`.
Response: `{ fulfillments: [{ fulfillment_type (REQUEST_ACCESS|INSTALL), listing_id, recipient_type, repo_info, share_info }], next_page_token }`.

---

## 4. Personalization Requests

### Create personalization request

```
POST /api/2.1/marketplace-consumer/listings/{listing_id}/personalization-requests
```

```json
{
	"intended_use": "Internal analytics",
	"accepted_consumer_terms": { "version": "1.0" },
	"comment": "Need access for Q4 analysis",
	"first_name": "Jane",
	"last_name": "Doe",
	"company": "Acme"
}
```

Required path: `listing_id`. Required body: `intended_use`, `accepted_consumer_terms.version`. Optional: `comment`, `first_name`, `last_name`, `company`, `recipient_type`, `is_from_lighthouse`.
Response: `{ id }`.

### Get personalization request for a listing

```
GET /api/2.1/marketplace-consumer/listings/{listing_id}/personalization-requests
```

Required path: `listing_id`. Response: `{ personalization_requests: [{ id, status (NEW|REQUEST_PENDING|FULFILLED|DENIED), intended_use, ... }] }`.
Note: Each consumer can make at most one personalization request per listing.

### List all personalization requests

```
GET /api/2.1/marketplace-consumer/personalization-requests?page_size=20
```

Optional: `page_size`, `page_token`. Response: `{ personalization_requests: [...], next_page_token }`.

---

## 5. Providers

### List providers

```
GET /api/2.1/marketplace-consumer/providers?is_featured=true&page_size=20
```

Optional: `is_featured` (bool), `page_size`, `page_token`. Only shows providers with at least one visible listing.

### Get provider

```
GET /api/2.1/marketplace-consumer/providers/{id}
```

Required path: `id`.

### Batch get providers

```
GET /api/2.1/marketplace-consumer/providers:batchGet?ids=abc&ids=def
```

Optional query: `ids` (array, max 50).

Provider fields: `id`, `name`, `description`, `business_contact_email`, `support_contact_email`, `company_website_link`, `privacy_policy_link`, `term_of_service_link`, `is_featured`, `published_by` (data aggregators only).

---

## Common Errors

- **404**: Listing/installation/provider not found or not accessible.
- **400**: Missing required field (e.g. `intended_use` on personalization, `accepted_consumer_terms` on install).
- **409**: Duplicate personalization request (max one per listing per consumer).

## Gotchas

- Batch endpoints use colon syntax: `listings:batchGet`, `providers:batchGet` -- not a sub-path.
- Batch endpoints accept max 50 IDs per request.
- `accepted_consumer_terms.version` is required for both install and personalization-request create.
- `rotate_token` on update forcibly rotates when `token_detail` is empty in the installation object.
- Fulfillment `fulfillment_type=REQUEST_ACCESS` means a personalization request is required before install.
- Search endpoint (`/search-listings`) is separate from list (`/listings`) and requires the `query` param.
- Personalization request GET and POST share the same path -- method determines operation.
- All list endpoints support cursor-based pagination via `page_token` / `next_page_token`.
- `share_info` is required for data listings but ignored for MCP and App listing types.
