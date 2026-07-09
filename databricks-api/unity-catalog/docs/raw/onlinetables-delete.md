Title: Delete an Online Table | Online Tables API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/onlinetables/delete

Markdown Content:
## Delete an Online Table

Public preview

`DELETE/api/2.0/online-tables/{name}`

Delete an online table. Warning: This will delete all the data in the online table. If the source Delta table was deleted or modified since this Online Table was created, this will lose the data forever!

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Path parameters

[`name`](https://docs.databricks.com/api/workspace/onlinetables/delete#name)required string

Full three-part (catalog, schema, table) name of the table.

### Responses

**200** Request completed successfully.

Request completed successfully.

# Response samples

200

{}
