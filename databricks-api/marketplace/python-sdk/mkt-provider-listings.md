# Marketplace Provider Listings -- Databricks Python SDK

> Raw docs: ../docs/raw/ -- for full endpoint details, read {service}-{operation}.md
> Package: `databricks-sdk` (PyPI)

## Setup

```python
from databricks.sdk import WorkspaceClient
w = WorkspaceClient()  # uses DATABRICKS_HOST + token from env/profile
```

## SDK Client Map

| Service | Client | Purpose |
|---------|--------|---------|
| Provider Profiles | `w.provider_providers` | Manage provider profiles |
| Listings | `w.provider_listings` | CRUD listings |
| Files | `w.provider_files` | Upload/manage listing files |
| Personalization Requests | `w.provider_personalization_requests` | Handle access requests |
| Analytics Dashboards | `w.provider_provider_analytics_dashboards` | Dashboard lifecycle |

---

## 1. Provider Profiles

```python
from databricks.sdk.service.marketplace import ProviderInfo

# Create
p = w.provider_providers.create(provider=ProviderInfo(
    name="Acme Data",
    business_contact_email="biz@acme.com",
    privacy_policy_link="https://acme.com/privacy",
    term_of_service_link="https://acme.com/tos"
))  # returns CreateProviderResponse with .id

# List
for prov in w.provider_providers.list():
    print(prov.name, prov.id)

# Get
prov = w.provider_providers.get(id="<provider_id>")  # returns GetProviderResponse

# Update
w.provider_providers.update(id="<provider_id>", provider=ProviderInfo(
    name="Acme Data Updated",
    business_contact_email="biz@acme.com",
    privacy_policy_link="https://acme.com/privacy",
    term_of_service_link="https://acme.com/tos"
))

# Delete
w.provider_providers.delete(id="<provider_id>")
```

Required on create/update: `name`, `business_contact_email`, `privacy_policy_link`, `term_of_service_link`.

---

## 2. Listings

```python
from databricks.sdk.service.marketplace import (
    Listing, ListingSummary, ListingDetail, ListingTag,
    ListingStatus, Visibility, ListingSetting, ShareInfo
)

# Create
resp = w.provider_listings.create(listing=Listing(
    summary=ListingSummary(
        name="My Dataset",
        listing_type="STANDARD",
        categories=["ADVERTISING_AND_MARKETING"],
        status=ListingStatus.DRAFT,
        setting=ListingSetting(visibility=Visibility.PUBLIC),
        share=ShareInfo(name="my_share", type="FULL")
    ),
    detail=ListingDetail(
        description="Dataset description",
        cost="FREE"
    )
))  # resp.listing_id

# List
for listing in w.provider_listings.list():
    print(listing.summary.name, listing.id)

# Get
lst = w.provider_listings.get(id="<listing_id>")

# Update
w.provider_listings.update(id="<listing_id>", listing=Listing(
    summary=ListingSummary(name="Updated Name", listing_type="STANDARD",
        categories=["ADVERTISING_AND_MARKETING"],
        status=ListingStatus.DRAFT,
        setting=ListingSetting(visibility=Visibility.PUBLIC)),
    detail=ListingDetail(description="Updated desc", cost="FREE")
))

# Delete
w.provider_listings.delete(id="<listing_id>")
```

---

## 3. Files

```python
from databricks.sdk.service.marketplace import FileParent, MarketplaceFileType

# Create (returns upload URL)
resp = w.provider_files.create(
    file_parent=FileParent(file_parent_type="LISTING", parent_id="<listing_id>"),
    marketplace_file_type=MarketplaceFileType.EMBEDDED_NOTEBOOK,
    mime_type="application/x-ipynb+json",
    display_name="Demo Notebook"
)
upload_url = resp.upload_url  # PUT file content here

# Upload via requests
import requests
requests.put(upload_url, data=open("notebook.ipynb", "rb"))

# List
for f in w.provider_files.list(
    file_parent=FileParent(file_parent_type="LISTING", parent_id="<listing_id>")
):
    print(f.display_name, f.status)

# Get / Delete
info = w.provider_files.get(file_id="<file_id>")
w.provider_files.delete(file_id="<file_id>")
```

File types: `PROVIDER_ICON`, `EMBEDDED_NOTEBOOK`, `APP`.
Statuses: `FILE_STATUS_PUBLISHED`, `FILE_STATUS_STAGING`, `FILE_STATUS_SANITIZING`, `FILE_STATUS_SANITIZATION_FAILED`.

---

## 4. Personalization Requests

```python
from databricks.sdk.service.marketplace import PersonalizationRequestStatus, ShareInfo

# List all (across all listings)
for req in w.provider_personalization_requests.list():
    print(req.listing_name, req.status, req.contact_info.email)

# Approve / Deny
w.provider_personalization_requests.update(
    listing_id="<listing_id>",
    request_id="<request_id>",
    status=PersonalizationRequestStatus.FULFILLED,
    share=ShareInfo(name="shared_data", type="FULL"),
    reason="Approved"
)
```

Status values: `NEW`, `REQUEST_PENDING`, `FULFILLED`, `DENIED`. `share` required for data listings when fulfilling; omit for MCP/App listings.

---

## 5. Analytics Dashboards

```python
# Create
resp = w.provider_provider_analytics_dashboards.create()  # no args
mkt_id = resp.id  # Marketplace-specific ID

# Get current
dash = w.provider_provider_analytics_dashboards.get()
lakeview_id = dash.dashboard_id  # use to open in Lakeview

# Get latest template version
latest = w.provider_provider_analytics_dashboards.get_latest_version()
print(latest.version)

# Update to latest version
updated = w.provider_provider_analytics_dashboards.update(
    id=mkt_id, version=latest.version
)
# updated.dashboard_id is the newly created Lakeview dashboard
```

---

## Common Patterns

```python
# Full workflow: create provider, listing, upload icon
provider = w.provider_providers.create(provider=ProviderInfo(
    name="Acme", business_contact_email="a@b.com",
    privacy_policy_link="https://x.com/p", term_of_service_link="https://x.com/t"
))

listing = w.provider_listings.create(listing=Listing(
    summary=ListingSummary(name="Dataset", listing_type="STANDARD",
        categories=["OTHER"], status=ListingStatus.DRAFT,
        setting=ListingSetting(visibility=Visibility.PUBLIC),
        share=ShareInfo(name="share1", type="FULL"),
        provider_id=provider.id),
    detail=ListingDetail(description="Desc", cost="FREE")
))

icon = w.provider_files.create(
    file_parent=FileParent(file_parent_type="LISTING", parent_id=listing.listing_id),
    marketplace_file_type=MarketplaceFileType.PROVIDER_ICON,
    mime_type="image/png"
)
requests.put(icon.upload_url, data=open("icon.png", "rb"))
```

## Gotchas

- File upload is two-step: `.create()` returns `upload_url`; PUT content to that pre-signed URL separately
- `term_of_service_link` (singular "term") not "terms" -- SDK will reject the wrong field name
- `is_featured` on providers is consumer-read-only; setting it on create/update has no effect
- Files go through sanitization; poll `status` until `FILE_STATUS_PUBLISHED`
- Analytics dashboard `id` vs `dashboard_id`: the former is Marketplace-internal, the latter opens Lakeview
- Personalization `share` field: required for data listings on fulfill, ignored for MCP/App listings
- `list()` methods return iterators with automatic pagination
