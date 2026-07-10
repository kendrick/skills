Title: Create a table constraint | Table Constraints API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/tableconstraints/create

Markdown Content:
## Create a table constraint

`POST/api/2.1/unity-catalog/constraints`

Creates a new table constraint.

For the table constraint creation to succeed, the user must satisfy both of these conditions:

*   the user must have the USE_CATALOG privilege on the table's parent catalog, the USE_SCHEMA privilege on the table's parent schema, and be the owner of the table.
*   if the new constraint is a ForeignKeyConstraint, the user must have the USE_CATALOG privilege on the referenced parent table's catalog, the USE_SCHEMA privilege on the referenced parent table's schema, and be the owner of the referenced parent table.

API scopes (preview):[`unity-catalog`](https://docs.databricks.com/api/workspace/api/scopes#unity-catalog)

### Request body

[`constraint`](https://docs.databricks.com/api/workspace/tableconstraints/create#constraint)required object

A table constraint, as defined by _one_ of the following fields being set: primary_key_constraint, foreign_key_constraint, named_table_constraint.

[`foreign_key_constraint`](https://docs.databricks.com/api/workspace/tableconstraints/create#constraint-foreign_key_constraint)object

[`named_table_constraint`](https://docs.databricks.com/api/workspace/tableconstraints/create#constraint-named_table_constraint)object

[`primary_key_constraint`](https://docs.databricks.com/api/workspace/tableconstraints/create#constraint-primary_key_constraint)object

[`full_name_arg`](https://docs.databricks.com/api/workspace/tableconstraints/create#full_name_arg)required string

The full name of the table referenced by the constraint.

### Responses

**200** Request completed successfully.

Request completed successfully.

[`foreign_key_constraint`](https://docs.databricks.com/api/workspace/tableconstraints/create#foreign_key_constraint)object

[`child_columns`](https://docs.databricks.com/api/workspace/tableconstraints/create#foreign_key_constraint-child_columns)Array of string

Column names for this constraint.

[`name`](https://docs.databricks.com/api/workspace/tableconstraints/create#foreign_key_constraint-name)string

The name of the constraint.

[`parent_columns`](https://docs.databricks.com/api/workspace/tableconstraints/create#foreign_key_constraint-parent_columns)Array of string

Column names for this constraint.

[`parent_table`](https://docs.databricks.com/api/workspace/tableconstraints/create#foreign_key_constraint-parent_table)string

The full name of the parent constraint.

[`rely`](https://docs.databricks.com/api/workspace/tableconstraints/create#foreign_key_constraint-rely)boolean

True if the constraint is RELY, false or unset if NORELY.

[`named_table_constraint`](https://docs.databricks.com/api/workspace/tableconstraints/create#named_table_constraint)object

[`name`](https://docs.databricks.com/api/workspace/tableconstraints/create#named_table_constraint-name)string

The name of the constraint.

[`primary_key_constraint`](https://docs.databricks.com/api/workspace/tableconstraints/create#primary_key_constraint)object

[`child_columns`](https://docs.databricks.com/api/workspace/tableconstraints/create#primary_key_constraint-child_columns)Array of string

Column names for this constraint.

[`name`](https://docs.databricks.com/api/workspace/tableconstraints/create#primary_key_constraint-name)string

The name of the constraint.

[`rely`](https://docs.databricks.com/api/workspace/tableconstraints/create#primary_key_constraint-rely)boolean

True if the constraint is RELY, false or unset if NORELY.

[`timeseries_columns`](https://docs.databricks.com/api/workspace/tableconstraints/create#primary_key_constraint-timeseries_columns)Array of string

Column names that represent a timeseries.

# Request samples

JSON

{

"constraint":{

"foreign_key_constraint":{

"child_columns":[

"string"

],

"name":"string",

"parent_columns":[

"string"

],

"parent_table":"string",

"rely":true

},

"named_table_constraint":{

"name":"string"

},

"primary_key_constraint":{

"child_columns":[

"string"

],

"name":"string",

"rely":true,

"timeseries_columns":[

"string"

]

}

},

"full_name_arg":"string"

}

# Response samples

200

{

"foreign_key_constraint":{

"child_columns":[

"string"

],

"name":"string",

"parent_columns":[

"string"

],

"parent_table":"string",

"rely":true

},

"named_table_constraint":{

"name":"string"

},

"primary_key_constraint":{

"child_columns":[

"string"

],

"name":"string",

"rely":true,

"timeseries_columns":[

"string"

]

}

}
