# Lineage, Tags & Metadata -- Databricks Python SDK

External lineage relationships, entity tag assignments, external metadata objects.

> See also: uc-catalog-schema-table (objects you're tagging/tracing), uc-grants-permissions (for access control on tagged objects)
> Raw docs: ../_docs/raw/ — for full endpoint details, read {service}-{operation}.md

## Setup

```python
from databricks.sdk import WorkspaceClient
w = WorkspaceClient()  # uses DATABRICKS_HOST + DATABRICKS_TOKEN env vars
```

## SDK Client Map

| REST API | SDK Client | Key Methods |
|----------|-----------|-------------|
| External Lineage | `w.external_lineage` | `create_external_lineage_relationship`, `list_external_lineage_relationships`, `update_external_lineage_relationship`, `delete_external_lineage_relationship` |
| Entity Tag Assignments | `w.entity_tag_assignments` | `create`, `list`, `get`, `update`, `delete` |
| External Metadata | `w.external_metadata` | `create_external_metadata`, `list_external_metadata`, `get_external_metadata`, `update_external_metadata`, `delete_external_metadata` |

External Lineage and External Metadata are **Public Preview**. Entity Tag Assignments is **GA**.

## 1. External Lineage

```python
from databricks.sdk.service.catalog import (
    ExternalLineageObjectInfo, ExternalLineageColumnRelationship
)

# Create: table -> external metadata
rel = w.external_lineage.create_external_lineage_relationship(
    source=ExternalLineageObjectInfo(table={"name": "main.sales.transactions"}),
    target=ExternalLineageObjectInfo(external_metadata={"name": "sales_dashboard"}),
    columns=[ExternalLineageColumnRelationship(source="amount", target="revenue")],
    properties={"refresh_frequency": "daily"}
)
print(rel.id)

# List downstream relationships (lineage_direction is required -- UPSTREAM or
# DOWNSTREAM, no "both" option; call twice if you need both directions)
rels = w.external_lineage.list_external_lineage_relationships(
    object_info=ExternalLineageObjectInfo(table={"name": "main.sales.customers"}),
    lineage_direction="DOWNSTREAM"
)
for r in rels:
    print(r.external_metadata_info or r.table_info)

# Update
w.external_lineage.update_external_lineage_relationship(
    source=ExternalLineageObjectInfo(table={"name": "main.sales.transactions"}),
    target=ExternalLineageObjectInfo(external_metadata={"name": "sales_dashboard"}),
    columns=[ExternalLineageColumnRelationship(source="amount2", target="revenue2")],
    update_mask="columns"
)

# Delete
w.external_lineage.delete_external_lineage_relationship(
    source=ExternalLineageObjectInfo(table={"name": "main.sales.transactions"}),
    target=ExternalLineageObjectInfo(external_metadata={"name": "sales_dashboard"})
)
```

Source/target object types: `table` (name), `external_metadata` (name), `model_version` (name + version), `path` (path).

## 2. Entity Tag Assignments

Tags on UC entities: catalogs, schemas, tables, columns, volumes, externallocations.

**Permissions**: own the entity OR APPLY TAG + USE SCHEMA + USE CATALOG. Governed tags also need ASSIGN/MANAGE on the tag policy.

```python
# Create tag (raises if tag_key already exists on the entity -- RESOURCE_ALREADY_EXISTS)
tag = w.entity_tag_assignments.create(
    entity_name="main.default.customer_data",
    entity_type="tables",
    tag_key="Severity",
    tag_value="high"
)

# List tags for an entity (may return empty pages with a next_page_token still
# set -- the SDK handles this automatically as long as you iterate the generator)
tags = w.entity_tag_assignments.list(
    entity_type="tables",
    entity_name="main.default.customer_data"
)
for t in tags:
    print(f"{t.tag_key}={t.tag_value}")

# Get single tag
tag = w.entity_tag_assignments.get(
    entity_type="tables",
    entity_name="main.default.customer_data",
    tag_key="Severity"
)

# Update tag value
w.entity_tag_assignments.update(
    entity_type="tables",
    entity_name="main.default.customer_data",
    tag_key="Severity",
    tag_value="medium",
    update_mask="tag_value"
)

# Delete tag
w.entity_tag_assignments.delete(
    entity_type="tables",
    entity_name="main.default.customer_data",
    tag_key="Severity"
)
```

`entity_type` values: `catalogs`, `schemas`, `tables`, `columns`, `volumes`, `externallocations`.

## 3. External Metadata

Represents objects outside Databricks (Kafka topics, Tableau reports, etc.).

**Permissions**: create needs metastore admin or CREATE_EXTERNAL_METADATA. Read needs BROWSE (granted to all by default). Update needs owner or MODIFY. Owner transfer needs MANAGE.

```python
# Create
meta = w.external_metadata.create_external_metadata(
    name="security_events_stream",
    entity_type="Topic",
    system_type="KAFKA",
    description="Security event stream",
    columns=["type", "message", "date"],
    url="https://kafka.com/12345",
    properties={"topic": "prod.security.events.raw"}
)
print(meta.id)

# List all
for m in w.external_metadata.list_external_metadata():
    print(f"{m.name} ({m.system_type})")

# Get by name
meta = w.external_metadata.get_external_metadata(name="security_events_stream")

# Update -- entity_type and system_type are required even for partial updates;
# owner cannot be combined with other field updates in the same call
w.external_metadata.update_external_metadata(
    name="security_events_stream",
    entity_type="Topic",
    system_type="KAFKA",
    description="Updated description",
    update_mask="description"
)

# Delete
w.external_metadata.delete_external_metadata(name="security_events_stream")
```

`system_type` enum: `TABLEAU`, `POWER_BI`, `LOOKER`, `KAFKA`, `SALESFORCE`, `SNOWFLAKE`, `GOOGLE_BIGQUERY`, `MICROSOFT_FABRIC`, `CONFLUENT`, `DATABRICKS`, `OTHER`, and more.

## Common Patterns

```python
# Tag all tables in a schema
tables = w.tables.list(catalog_name="main", schema_name="pii")
for t in tables:
    w.entity_tag_assignments.create(
        entity_name=t.full_name,
        entity_type="tables",
        tag_key="data_class",
        tag_value="pii"
    )

# Register external system + link lineage
w.external_metadata.create_external_metadata(
    name="crm_contacts", entity_type="CRM", system_type="SALESFORCE"
)
w.external_lineage.create_external_lineage_relationship(
    source=ExternalLineageObjectInfo(table={"name": "main.sales.contacts"}),
    target=ExternalLineageObjectInfo(external_metadata={"name": "crm_contacts"}),
    columns=[ExternalLineageColumnRelationship(source="contact_id", target="id")]
)
```
