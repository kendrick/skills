# Marketplace Private Exchanges -- Databricks Marketplace REST API

Scope: Private exchanges CRUD, exchange-listing associations, exchange filters (access control).

> See also: mkt-provider-listings (for managing the listings you add to exchanges), mkt-consumer (for the consumer view)

> Raw docs: ../docs/raw/ -- for full endpoint details, read {service}-{operation}.md

**Status:** Public Preview. All endpoints require OAuth scope `marketplace`.

## Auth

```
Authorization: Bearer <token>
Host: <workspace>.cloud.databricks.com
```

## Endpoint Summary

| Method | Path | Purpose |
|--------|------|---------|
| POST | /api/2.0/marketplace-exchange/exchanges | Create exchange |
| GET | /api/2.0/marketplace-exchange/exchanges | List exchanges |
| GET | /api/2.0/marketplace-exchange/exchanges/{id} | Get exchange |
| PUT | /api/2.0/marketplace-exchange/exchanges/{id} | Update exchange |
| DELETE | /api/2.0/marketplace-exchange/exchanges/{id} | Delete exchange |
| POST | /api/2.0/marketplace-exchange/exchanges-for-listing | Add listing to exchange |
| DELETE | /api/2.0/marketplace-exchange/exchanges-for-listing/{id} | Remove listing from exchange |
| GET | /api/2.0/marketplace-exchange/exchanges-for-listing | List exchanges for a listing |
| GET | /api/2.0/marketplace-exchange/listings-for-exchange | List listings for an exchange |
| POST | /api/2.0/marketplace-exchange/filters | Create exchange filter |
| GET | /api/2.0/marketplace-exchange/filters | List exchange filters |
| PUT | /api/2.0/marketplace-exchange/filters/{id} | Update exchange filter |
| DELETE | /api/2.0/marketplace-exchange/filters/{id} | Delete exchange filter |

---

## 1. Exchanges

### Create

```
POST /api/2.0/marketplace-exchange/exchanges
{"exchange": {"name": "Partner Exchange", "comment": "For approved partners"}}
```

- Required: `exchange.name` (string)
- Optional: `exchange.comment`
- Response: `{"exchange_id": "<id>"}`

### List

```
GET /api/2.0/marketplace-exchange/exchanges?page_size=10&page_token=...
```

- Optional: `page_size` (int32), `page_token` (string)
- Response: `{"exchanges": [...], "next_page_token": "..."}`

### Get

```
GET /api/2.0/marketplace-exchange/exchanges/{id}
```

- Required path param: `id`
- Response: `{"exchange": {...}}` -- includes embedded `filters` and `linked_listings` arrays

### Update

```
PUT /api/2.0/marketplace-exchange/exchanges/{id}
{"exchange": {"name": "Renamed Exchange", "comment": "Updated"}}
```

- Required path param: `id`; body: `exchange.name`
- Optional: `exchange.comment`
- Response: full updated `{"exchange": {...}}`

### Delete

```
DELETE /api/2.0/marketplace-exchange/exchanges/{id}
```

- Required path param: `id`
- Response: `{}`

---

## 2. Exchange-Listing Associations

### Add listing to exchange

```
POST /api/2.0/marketplace-exchange/exchanges-for-listing
{"exchange_id": "<eid>", "listing_id": "<lid>"}
```

- Required: `exchange_id`, `listing_id` (both string)
- Response: `{"exchange_for_listing": {"id": "...", "exchange_id": "...", "listing_id": "...", ...}}`

### Remove listing from exchange

```
DELETE /api/2.0/marketplace-exchange/exchanges-for-listing/{id}
```

- Required path param: `id` (the association ID, not exchange or listing ID)
- Response: `{}`

### List exchanges for a listing

```
GET /api/2.0/marketplace-exchange/exchanges-for-listing?listing_id=<lid>
```

- Required: `listing_id`; Optional: `page_size`, `page_token`
- Response: `{"exchange_listing": [...], "next_page_token": "..."}`

### List listings for an exchange

```
GET /api/2.0/marketplace-exchange/listings-for-exchange?exchange_id=<eid>
```

- Required: `exchange_id`; Optional: `page_size`, `page_token`
- Response: `{"exchange_listings": [...], "next_page_token": "..."}`

---

## 3. Exchange Filters

Filters control which consumers (by metastore ID) can access an exchange.

### Create filter

```
POST /api/2.0/marketplace-exchange/filters
{"filter": {"exchange_id": "<eid>", "filter_type": "GLOBAL_METASTORE_ID", "filter_value": "<metastore-uuid>"}}
```

- Required: `filter.exchange_id`, `filter.filter_type` (enum: `GLOBAL_METASTORE_ID`), `filter.filter_value`
- Optional: `filter.name`
- Response: `{"filter_id": "<id>"}`

### List filters

```
GET /api/2.0/marketplace-exchange/filters?exchange_id=<eid>
```

- Required: `exchange_id`; Optional: `page_size`, `page_token`
- Response: `{"filters": [...], "next_page_token": "..."}`

### Update filter

```
PUT /api/2.0/marketplace-exchange/filters/{id}
{"filter": {"exchange_id": "<eid>", "filter_type": "GLOBAL_METASTORE_ID", "filter_value": "<new-value>"}}
```

- Required path param: `id`; body: `filter.exchange_id`, `filter.filter_type`, `filter.filter_value`
- Response: `{"filter": {...}}`

### Delete filter

```
DELETE /api/2.0/marketplace-exchange/filters/{id}
```

- Required path param: `id`
- Response: `{}`

---

## Common Errors

| Code | Cause |
|------|-------|
| 400 | Missing required field (e.g. `exchange.name`, `filter.filter_value`) |
| 404 | Exchange, listing, filter, or association ID not found |
| 409 | Duplicate exchange name or duplicate listing-exchange association |
| 403 | Insufficient permissions / missing `marketplace` scope |

## Gotchas

- The delete-listing-from-exchange endpoint takes the **association ID** (returned when adding), not the exchange or listing ID.
- `filter_type` currently only supports `GLOBAL_METASTORE_ID`. The value is the target consumer's metastore UUID.
- GET exchange returns embedded `filters` and `linked_listings`, but list endpoints return them as separate arrays -- use the dedicated list endpoints for pagination.
- All list endpoints use cursor-based pagination (`page_token` / `next_page_token`).
- Exchange names must be unique within the provider's scope.
- Both `/api/2.0/marketplace-exchange/...` and `/api/2.1/marketplace-exchange/...` paths are accepted; bodies and responses are identical.
