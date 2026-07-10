# Marketplace Private Exchanges -- Databricks Python SDK

> Raw docs: ../_docs/raw/ -- for full endpoint details, read {service}-{operation}.md

> Package: `databricks-sdk` (`pip install databricks-sdk`)

**Status:** Public Preview

## Setup

```python
from databricks.sdk import WorkspaceClient
w = WorkspaceClient()  # uses DATABRICKS_HOST + DATABRICKS_TOKEN env vars
```

## SDK Client Map

| Service | Client | Purpose |
|---------|--------|---------|
| ProviderExchanges | `w.provider_exchanges` | Exchange CRUD + listing associations |
| ProviderExchangeFilters | `w.provider_exchange_filters` | Filter CRUD (access control) |

---

## 1. Exchanges

### Create

```python
resp = w.provider_exchanges.create(
    exchange=Exchange(name="Partner Exchange", comment="For approved partners")
)
print(resp.exchange_id)
```

Required: `exchange.name`. Optional: `exchange.comment`.

### List

```python
for ex in w.provider_exchanges.list():
    print(ex.id, ex.name)
```

Returns iterator; handles pagination automatically.

### Get

```python
ex = w.provider_exchanges.get(id="<exchange-id>")
print(ex.exchange.name, ex.exchange.filters, ex.exchange.linked_listings)
```

### Update

```python
updated = w.provider_exchanges.update(
    id="<exchange-id>",
    exchange=Exchange(name="Renamed Exchange", comment="Updated")
)
```

Required: `id`, `exchange.name`.

### Delete

```python
w.provider_exchanges.delete(id="<exchange-id>")
```

---

## 2. Exchange-Listing Associations

### Add listing to exchange

```python
assoc = w.provider_exchanges.add_listing_to_exchange(
    exchange_id="<eid>", listing_id="<lid>"
)
print(assoc.exchange_for_listing.id)  # save this association ID for removal
```

### Remove listing from exchange

```python
w.provider_exchanges.delete_listing_from_exchange(id="<association-id>")
```

Note: pass the **association ID**, not the exchange or listing ID.

### List exchanges for a listing

```python
for assoc in w.provider_exchanges.list_exchanges_for_listing(listing_id="<lid>"):
    print(assoc.exchange_id, assoc.exchange_name)
```

### List listings for an exchange

```python
for assoc in w.provider_exchanges.list_listings_for_exchange(exchange_id="<eid>"):
    print(assoc.listing_id, assoc.listing_name)
```

---

## 3. Exchange Filters

Filters control which consumers (by metastore ID) can see an exchange.

### Create filter

```python
from databricks.sdk.service.marketplace import ExchangeFilter, FilterType

resp = w.provider_exchange_filters.create(
    filter=ExchangeFilter(
        exchange_id="<eid>",
        filter_type=FilterType.GLOBAL_METASTORE_ID,
        filter_value="<consumer-metastore-uuid>"
    )
)
print(resp.filter_id)
```

Required: `exchange_id`, `filter_type`, `filter_value`.

### List filters

```python
for f in w.provider_exchange_filters.list(exchange_id="<eid>"):
    print(f.id, f.filter_value)
```

### Update filter

```python
updated = w.provider_exchange_filters.update(
    id="<filter-id>",
    filter=ExchangeFilter(
        exchange_id="<eid>",
        filter_type=FilterType.GLOBAL_METASTORE_ID,
        filter_value="<new-metastore-uuid>"
    )
)
```

### Delete filter

```python
w.provider_exchange_filters.delete(id="<filter-id>")
```

---

## Common Patterns

### Full setup: create exchange, add filter, link listing

```python
from databricks.sdk.service.marketplace import Exchange, ExchangeFilter, FilterType

# 1. Create exchange
ex = w.provider_exchanges.create(exchange=Exchange(name="Enterprise Partners"))

# 2. Allow a consumer metastore
w.provider_exchange_filters.create(filter=ExchangeFilter(
    exchange_id=ex.exchange_id,
    filter_type=FilterType.GLOBAL_METASTORE_ID,
    filter_value="<consumer-metastore-uuid>"
))

# 3. Link a listing
w.provider_exchanges.add_listing_to_exchange(
    exchange_id=ex.exchange_id, listing_id="<listing-id>"
)
```

### Remove all listings from an exchange

```python
for assoc in w.provider_exchanges.list_listings_for_exchange(exchange_id="<eid>"):
    w.provider_exchanges.delete_listing_from_exchange(id=assoc.id)
```

## Gotchas

- `filter_type` only supports `GLOBAL_METASTORE_ID` -- the value must be the consumer's metastore UUID.
- `delete_listing_from_exchange` takes the **association ID** (from `add_listing_to_exchange` response or list), not the exchange/listing ID.
- List methods return iterators that auto-paginate. No manual `page_token` handling needed.
- SDK model imports: `from databricks.sdk.service.marketplace import Exchange, ExchangeFilter, FilterType`.
- Exchange `name` is required on both create and update.
