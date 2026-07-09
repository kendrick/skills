Title: Delete an external lineage relationship | External Lineage API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/externallineage/deleteexternallineagerelationship

Markdown Content:
## Delete an external lineage relationship

Public preview

`DELETE/api/2.0/lineage-tracking/external-lineage`

Deletes an external lineage relationship between a Databricks or external metadata object and another external metadata object.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Query parameters

[`external_lineage_relationship`](https://docs.databricks.com/api/workspace/externallineage/deleteexternallineagerelationship#external_lineage_relationship)required object

Example

[`source`](https://docs.databricks.com/api/workspace/externallineage/deleteexternallineagerelationship#external_lineage_relationship-source)required object

Source object of the external lineage relationship.

[`target`](https://docs.databricks.com/api/workspace/externallineage/deleteexternallineagerelationship#external_lineage_relationship-target)required object

Target object of the external lineage relationship.

### Responses

**200** Request completed successfully.

Request completed successfully.

# Response samples

200

{}
