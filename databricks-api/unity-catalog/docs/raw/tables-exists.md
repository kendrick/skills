Title: Get boolean reflecting if table exists | Tables API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/tables/exists

Markdown Content:
## Get boolean reflecting if table exists

`GET/api/2.1/unity-catalog/tables/{full_name}/exists`

Gets if a table exists in the metastore for a specific catalog and schema. The caller must satisfy one of the following requirements:

*   Be a metastore admin
*   Be the owner of the parent catalog
*   Be the owner of the parent schema and have the USE_CATALOG privilege on the parent catalog
*   Have the USE_CATALOG privilege on the parent catalog and the USE_SCHEMA privilege on the parent schema, and either be the table owner or have the SELECT privilege on the table.
*   Have BROWSE privilege on the parent catalog
*   Have BROWSE privilege on the parent schema

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`full_name`](https://docs.databricks.com/api/workspace/tables/exists#full_name)required string

Full name of the table.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`table_exists`](https://docs.databricks.com/api/workspace/tables/exists#table_exists)boolean

Whether the table exists or not.

# Response samples

200

{

"table_exists":true

}
