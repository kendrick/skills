# Marketplace Consumer -- Databricks Python SDK

> Raw docs: ../_docs/raw/ -- for full endpoint details, read {service}-{operation}.md
> Package: `databricks-sdk`

## Setup

```python
from databricks.sdk import WorkspaceClient
w = WorkspaceClient()  # uses DATABRICKS_HOST + token from env/profile
```

## SDK Client Map

| REST Service | SDK Client | Methods |
|-------------|-----------|---------|
| ConsumerListings | `w.consumer_listings` | `list`, `get`, `batch_get`, `search` |
| ConsumerInstallations | `w.consumer_installations` | `list`, `list_listing_installations`, `create`, `update`, `delete` |
| ConsumerFulfillments | `w.consumer_fulfillments` | `get`, `list` |
| ConsumerPersonalizationRequests | `w.consumer_personalization_requests` | `create`, `get`, `list` |
| ConsumerProviders | `w.consumer_providers` | `list`, `get`, `batch_get` |

All require **`marketplace`** API scope (preview).

---

## 1. Listings

```python
# List with filters
for listing in w.consumer_listings.list(is_free=True, categories=["FINANCIAL"], assets=["ASSET_TYPE_DATA_TABLE"]):
    print(listing.id, listing.summary.name)

# Get single
listing = w.consumer_listings.get(id="<listing-id>")

# Batch get (max 50)
results = w.consumer_listings.batch_get(ids=["id1", "id2"])

# Search (fuzzy)
for listing in w.consumer_listings.search(query="weather data", is_free=True):
    print(listing.summary.name)
```

`list` optional: `page_size`, `page_token`, `assets`, `categories`, `tags` (single `{tag_name, tag_values}`, not a list), `is_free`, `is_private_exchange`, `is_staff_pick`, `provider_ids`.
`search` required: `query`. Optional: same filters minus `tags`, `is_staff_pick`.

---

## 2. Installations

```python
from databricks.sdk.service.marketplace import ConsumerTerms

# List all installations
for inst in w.consumer_installations.list():
    print(inst.id, inst.listing_name, inst.status)  # INSTALLED | FAILED

# List installations for a specific listing
for inst in w.consumer_installations.list_listing_installations(listing_id="<listing-id>"):
    print(inst.catalog_name)

# Install a data listing
result = w.consumer_installations.create(
    listing_id="<listing-id>",
    accepted_consumer_terms=ConsumerTerms(version="1.0"),
    catalog_name="my_catalog",
    recipient_type="DELTA_SHARING_RECIPIENT_TYPE_DATABRICKS"
)
print(result.installation.id, result.installation.status)

# Install a git repo listing
result = w.consumer_installations.create(
    listing_id="<listing-id>",
    accepted_consumer_terms=ConsumerTerms(version="1.0"),
    repo_detail=RepoInstallation(repo_name="my_repo", repo_path="/Repos/me/my_repo")
)

# Update / rotate token
w.consumer_installations.update(
    listing_id="<listing-id>",
    installation_id="<install-id>",
    installation=InstallationDetail(catalog_name="new_catalog"),
    rotate_token=True
)

# Uninstall
w.consumer_installations.delete(listing_id="<listing-id>", installation_id="<install-id>")
```

Required for install: `listing_id`, `accepted_consumer_terms.version`. `rotate_token=True` on update forcibly rotates the sharing token when `token_detail` is empty on the installation.

---

## 3. Fulfillments

```python
# Get listing content metadata (shared objects preview)
for obj in w.consumer_fulfillments.get(listing_id="<listing-id>"):
    print(obj.name, obj.data_object_type)  # TABLE, SCHEMA, MODEL, VOLUME, NOTEBOOK_FILE

# List fulfillments (potential installations)
for f in w.consumer_fulfillments.list(listing_id="<listing-id>"):
    print(f.fulfillment_type)  # REQUEST_ACCESS | INSTALL
```

`fulfillment_type=REQUEST_ACCESS` means a personalization request is required before install. `share_info` is required for data listings but ignored for MCP/App listing types.

---

## 4. Personalization Requests

```python
# Create request (max one per listing per consumer)
result = w.consumer_personalization_requests.create(
    listing_id="<listing-id>",
    intended_use="Internal analytics",
    accepted_consumer_terms=ConsumerTerms(version="1.0"),
    comment="Need Q4 data",
    first_name="Jane", last_name="Doe", company="Acme"
)
print(result.id)

# Get request for a specific listing
reqs = w.consumer_personalization_requests.get(listing_id="<listing-id>")
for r in reqs.personalization_requests:
    print(r.status)  # NEW | REQUEST_PENDING | FULFILLED | DENIED

# List all personalization requests
for r in w.consumer_personalization_requests.list():
    print(r.listing_name, r.status)
```

Required on create: `intended_use`, `accepted_consumer_terms`. Optional: `comment`, `first_name`, `last_name`, `company`, `recipient_type`, `is_from_lighthouse`. Max one personalization request per listing per consumer -- creating a duplicate raises an error. `get` returns a list (`personalization_requests`) even though at most one request exists per listing.

---

## 5. Providers

```python
# List (only providers with visible listings)
for p in w.consumer_providers.list(is_featured=True):
    print(p.id, p.name)

# Get single
provider = w.consumer_providers.get(id="<provider-id>")

# Batch get (max 50)
results = w.consumer_providers.batch_get(ids=["id1", "id2"])
```

---

## Common Patterns

```python
# Browse -> inspect -> install workflow
listings = list(w.consumer_listings.search(query="covid data"))
listing = w.consumer_listings.get(id=listings[0].id)

# Check fulfillment type before installing
fulfillments = list(w.consumer_fulfillments.list(listing_id=listing.id))
if fulfillments[0].fulfillment_type == "INSTALL":
    w.consumer_installations.create(
        listing_id=listing.id,
        accepted_consumer_terms=ConsumerTerms(version="1.0"),
        catalog_name="covid_data"
    )
else:
    # Must request access first
    w.consumer_personalization_requests.create(
        listing_id=listing.id,
        intended_use="Research",
        accepted_consumer_terms=ConsumerTerms(version="1.0")
    )
```

## Gotchas

- `list` methods return iterators that auto-paginate; no manual `page_token` handling needed.
