# Marketplace Provider Listings -- Databricks Marketplace REST API

Publish and manage listings, upload files, manage provider profiles, handle personalization requests, and analytics dashboards.

> See also: mkt-consumer (consumer view), mkt-provider-exchanges (private exchanges)
> Raw docs: ../_docs/raw/ -- for full endpoint details, read {service}-{operation}.md

All endpoints: **Public Preview**. Scope: `marketplace`. Base: `{workspace-url}/api/2.0/marketplace-provider`.

## Auth

```
Authorization: Bearer <token>
```

Token needs `marketplace` API scope.

## Endpoint Summary

| Method | Path                                                                        | Purpose                           |
| ------ | --------------------------------------------------------------------------- | --------------------------------- |
| POST   | /provider                                                                   | Create provider profile           |
| GET    | /providers                                                                  | List provider profiles            |
| GET    | /providers/{id}                                                             | Get provider profile              |
| PUT    | /providers/{id}                                                             | Update provider profile           |
| DELETE | /providers/{id}                                                             | Delete provider profile           |
| POST   | /listing                                                                    | Create listing                    |
| GET    | /listings                                                                   | List listings                     |
| GET    | /listings/{id}                                                              | Get listing                       |
| PUT    | /listings/{id}                                                              | Update listing                    |
| DELETE | /listings/{id}                                                              | Delete listing                    |
| POST   | /files                                                                      | Create/upload file                |
| GET    | /files                                                                      | List files                        |
| GET    | /files/{file_id}                                                            | Get file                          |
| DELETE | /files/{file_id}                                                            | Delete file                       |
| GET    | /personalization-requests                                                   | List all personalization requests |
| PUT    | /listings/{listing_id}/personalization-requests/{request_id}/request-status | Update request status             |
| POST   | /analytics_dashboard                                                        | Create analytics dashboard        |
| GET    | /analytics_dashboard                                                        | Get analytics dashboard           |
| GET    | /analytics_dashboard/latest                                                 | Get latest dashboard version      |
| PUT    | /analytics_dashboard/{id}                                                   | Update analytics dashboard        |

---

## 1. Provider Profiles

### Create Provider

```
POST /api/2.0/marketplace-provider/provider
```

```json
{
	"provider": {
		"name": "Acme Data",
		"business_contact_email": "biz@acme.com",
		"privacy_policy_link": "https://acme.com/privacy",
		"term_of_service_link": "https://acme.com/tos"
	}
}
```

**Required**: `name`, `business_contact_email`, `privacy_policy_link`, `term_of_service_link` (singular "term", not "terms")
**Optional**: `description`, `company_website_link`, `support_contact_email`, `icon_file_id`, `dark_mode_icon_file_id`, `published_by`
Note: `is_featured` is read-only for consumers; ignored on create/update.
**Response**: `{"id": "<provider_id>"}`

### List Providers

```
GET /api/2.0/marketplace-provider/providers?page_size=20&page_token=...
```

**Response**: `{providers: [...], next_page_token}`

### Get / Update / Delete Provider

```
GET    /api/2.0/marketplace-provider/providers/{id}
PUT    /api/2.0/marketplace-provider/providers/{id}   (body: {provider: {...}})
DELETE /api/2.0/marketplace-provider/providers/{id}
```

Update requires same fields as create. Response returns full provider object.

---

## 2. Listings

### Create Listing

```
POST /api/2.0/marketplace-provider/listing
```

```json
{
	"listing": {
		"summary": {
			"name": "My Dataset",
			"listingType": "STANDARD",
			"categories": ["ADVERTISING_AND_MARKETING"],
			"status": "DRAFT",
			"setting": { "visibility": "PUBLIC" },
			"share": { "name": "my_share", "type": "FULL" }
		},
		"detail": {
			"description": "Dataset description",
			"cost": "FREE"
		}
	}
}
```

**Key summary fields**: `name` (req), `listingType` (STANDARD|PERSONALIZED; camelCase in JSON, not `listing_type`), `categories[]`, `status` (DRAFT|PUBLISHED), `setting.visibility` (PUBLIC|PRIVATE), `share` (name+type for data listings), `provider_id`, `exchange_ids[]`
**Key detail fields**: `description`, `cost`, `documentation_link`, `terms_of_service`, `tags[]`, `file_ids[]`
**Response**: `{"listing_id": "<id>"}`

### List Listings

```
GET /api/2.0/marketplace-provider/listings?page_size=20&page_token=...
```

### Get / Update / Delete Listing

```
GET    /api/2.0/marketplace-provider/listings/{id}
PUT    /api/2.0/marketplace-provider/listings/{id}   (body: {listing: {...}})
DELETE /api/2.0/marketplace-provider/listings/{id}
```

Update returns full listing object. Delete returns `{}`.

---

## 3. Files

Supports: `PROVIDER_ICON`, `EMBEDDED_NOTEBOOK`, `APP`. File statuses: `FILE_STATUS_PUBLISHED`, `FILE_STATUS_STAGING`, `FILE_STATUS_SANITIZING`, `FILE_STATUS_SANITIZATION_FAILED`.
`file_parent_type` enum: `PROVIDER` (icon), `LISTING` (listing files), `LISTING_RESOURCE`.
Files go through sanitization -- check `status` before assuming they are available.

### Create File (get upload URL)

```
POST /api/2.0/marketplace-provider/files
```

```json
{
	"file_parent": { "file_parent_type": "LISTING", "parent_id": "<listing_id>" },
	"marketplace_file_type": "EMBEDDED_NOTEBOOK",
	"mime_type": "application/x-ipynb+json",
	"display_name": "Demo Notebook"
}
```

**Required**: `file_parent` (type + parent_id), `marketplace_file_type`, `mime_type`
**Optional**: `display_name`
**Response**: `{file_info: {...}, upload_url: "<pre-signed URL>"}`

Upload the file content to `upload_url` via PUT after creating.

### List Files

```
GET /api/2.0/marketplace-provider/files?file_parent.file_parent_type=LISTING&file_parent.parent_id=<id>
```

**Required**: `file_parent` (type + parent_id). Paginated.

### Get / Delete File

```
GET    /api/2.0/marketplace-provider/files/{file_id}
DELETE /api/2.0/marketplace-provider/files/{file_id}
```

---

## 4. Personalization Requests

### List All Requests

```
GET /api/2.0/marketplace-provider/personalization-requests?page_size=20
```

Returns all requests across all listings. Each request includes: `id`, `listing_id`, `listing_name`, `status` (NEW|REQUEST_PENDING|FULFILLED|DENIED), `contact_info`, `consumer_region`, `intended_use`, `recipient_type`, `metastore_id`.

### Update Request Status

```
PUT /api/2.0/marketplace-provider/listings/{listing_id}/personalization-requests/{request_id}/request-status
```

```json
{
	"status": "FULFILLED",
	"share": { "name": "shared_data", "type": "FULL" },
	"reason": "Approved"
}
```

**Required**: `status`. **Optional**: `share` (required for data listings when fulfilling), `reason`.
`share` is required for data listings but should be empty for non-data listings (MCP/App).

---

## 5. Analytics Dashboards

### Create Dashboard

```
POST /api/2.0/marketplace-provider/analytics_dashboard
```

No body required. Returns `{"id": "<marketplace_dashboard_id>"}`. This is a Marketplace-specific ID, not the Lakeview dashboard ID.

### Get Dashboard

```
GET /api/2.0/marketplace-provider/analytics_dashboard
```

Returns `{id, dashboard_id, version}`. Use `dashboard_id` to open in Lakeview.

### Get Latest Version

```
GET /api/2.0/marketplace-provider/analytics_dashboard/latest
```

Returns `{"version": <int>}` -- latest logical version of the dashboard template.

### Update Dashboard

```
PUT /api/2.0/marketplace-provider/analytics_dashboard/{id}
```

```json
{ "version": 2 }
```

**Required path**: `id` (immutable). **Body**: `version` (should equal latest template version).
Returns `{id, dashboard_id, version}` with newly created Lakeview dashboard.

---

## Common Errors

- **404**: Resource not found (invalid ID)
- **403**: Missing `marketplace` scope or insufficient permissions
- **409**: Conflict (duplicate provider name, listing name collision)
- **400**: Missing required fields, invalid enum values

## Gotchas

- Both `/api/2.0/marketplace-provider/...` and `/api/2.1/marketplace-provider/...` paths are accepted; bodies and responses are identical.
