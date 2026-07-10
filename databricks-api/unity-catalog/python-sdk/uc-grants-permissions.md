# Grants & Permissions -- Databricks Python SDK

Grants, privileges, ABAC policies (row filters/column masks), workspace bindings, access requests, artifact allowlists.

> See also: uc-catalog-schema-table (objects you're granting on), uc-metastore-admin (metastore-level admin)
> Raw docs: ../_docs/raw/ — for full endpoint details, read {service}-{operation}.md

## Setup

```python
from databricks.sdk import WorkspaceClient
w = WorkspaceClient()  # uses DATABRICKS_HOST + DATABRICKS_TOKEN env vars
```

## SDK Client Map

| Service | Client | Key methods |
|---------|--------|-------------|
| Grants | `w.grants` | `get`, `get_effective`, `update` |
| ABAC Policies | `w.policies` | `create_policy`, `list_policies`, `get_policy`, `update_policy`, `delete_policy` |
| Workspace Bindings | `w.workspace_bindings` | `get_bindings`, `update_bindings`, `get` (deprecated), `update` (deprecated) |
| Request for Access | `w.rfa` | `batch_create_access_requests`, `get_access_request_destinations`, `update_access_request_destinations` |
| Artifact Allowlists | `w.artifact_allowlists` | `get`, `update` |

## 1. Grants

### Get permissions (direct only, not inherited)
```python
perms = w.grants.get(securable_type="catalog", full_name="main", max_results=0)
for pa in perms.privilege_assignments:
    print(pa.principal, pa.privileges)
```
Params: `securable_type` (req str -- e.g. "catalog", "schema", "table"), `full_name` (req str -- e.g. "main", "main.schema1", "main.schema1.table1"), `principal` (opt str -- filter to one user/group), `max_results` (opt int -- use 0 for server-default pagination, min positive value is 150).

### Get effective (includes inherited from parent securables)
```python
eff = w.grants.get_effective(securable_type="table", full_name="main.sales.orders")
for pa in eff.privilege_assignments:
    for p in pa.privileges:
        print(f"{pa.principal}: {p.privilege} (from {p.inherited_from_type} '{p.inherited_from_name}')")
```
Each privilege in the effective response tells you where it came from: direct grant on the securable itself, or inherited from a parent catalog/schema.

### Update permissions
```python
from databricks.sdk.service.catalog import PermissionsChange, Privilege

w.grants.update(
    securable_type="schema",
    full_name="main.analytics",
    changes=[PermissionsChange(
        principal="analysts",
        add=[Privilege.SELECT, Privilege.USAGE],
        remove=[Privilege.MODIFY]
    )]
)
```

## 2. ABAC Policies (Public Preview)

### Create row filter
```python
from databricks.sdk.service.catalog import (
    PolicyType, RowFilterPolicy, SecurableType
)

policy = w.policies.create_policy(
    name="region_filter",
    policy_type=PolicyType.POLICY_TYPE_ROW_FILTER,
    on_securable_type="CATALOG",
    on_securable_fullname="main",
    for_securable_type="TABLE",
    to_principals=["analysts"],
    row_filter=RowFilterPolicy(function_name="main.security.region_fn")
)
```
`for_securable_type` only supports `TABLE` despite the enum listing many types. A `row_filter.function_name` must return a boolean; a `column_mask.function_name` must accept the masked column's type as its first argument and return that same type.

### List / Get / Update / Delete
```python
# List (with inherited)
policies = w.policies.list_policies(
    on_securable_type="SCHEMA", on_securable_fullname="main.hr",
    include_inherited=True
)

# Get
p = w.policies.get_policy(
    on_securable_type="SCHEMA", on_securable_fullname="main.hr", name="mask_ssn"
)

# Update
w.policies.update_policy(
    on_securable_type="SCHEMA", on_securable_fullname="main.hr", name="mask_ssn",
    to_principals=["analysts", "interns"]
    # pass update_mask for a partial update; without it, all provided fields replace existing values
)

# Delete
w.policies.delete_policy(
    on_securable_type="SCHEMA", on_securable_fullname="main.hr", name="mask_ssn"
)
```

## 3. Workspace Bindings

```python
# Get bindings (preferred API -- the deprecated `get`/`update` only ever worked for catalogs)
bindings = w.workspace_bindings.get_bindings(
    securable_type="catalog", securable_name="main"
)

# Update bindings
from databricks.sdk.service.catalog import WorkspaceBinding, WorkspaceBindingBindingType

result = w.workspace_bindings.update_bindings(
    securable_type="catalog",
    securable_name="main",
    add=[WorkspaceBinding(
        workspace_id=12345,
        binding_type=WorkspaceBindingBindingType.BINDING_TYPE_READ_WRITE
    )],
    remove=[WorkspaceBinding(workspace_id=67890)]
)
```
Supported types: `catalog`, `storage_credential`, `credential`, `external_location`. Adding a workspace that's already bound with a different `binding_type` updates (not duplicates) the binding.

## 4. Request for Access (Public Preview)

```python
# Create access requests
from databricks.sdk.service.catalog import (
    AccessRequest, SecurablePermission, SecurableInfo, PrincipalInfo
)

resp = w.rfa.batch_create_access_requests(requests=[
    AccessRequest(
        behalf_of=PrincipalInfo(id="12345", principal_type="USER_PRINCIPAL"),
        comment="Need access to sales data",
        securable_permissions=[
            SecurablePermission(
                securable=SecurableInfo(full_name="main.sales", type="SCHEMA"),
                permissions=["USE_SCHEMA"]
            )
        ]
    )
])

# Get destinations
dests = w.rfa.get_access_request_destinations(
    securable_type="catalog", full_name="main"
)

# Update destinations (requires MANAGE or owner)
w.rfa.update_access_request_destinations(
    securable=SecurableInfo(full_name="main", type="CATALOG"),
    destinations=[{"destination_id": "admin@co.com", "destination_type": "EMAIL"}],
    update_mask="destinations"
)
```
Destinations on sub-schema objects (tables, volumes, functions, models) are inherited from the parent schema and cannot be set directly. Max 5 email + 5 external notification destinations per securable; if a URL destination is used, it must be the only one.

## 5. Artifact Allowlists

```python
from databricks.sdk.service.catalog import ArtifactMatcher, ArtifactMatchType

# Get
al = w.artifact_allowlists.get(artifact_type="LIBRARY_JAR")

# Set (full replace)
w.artifact_allowlists.update(
    artifact_type="LIBRARY_JAR",
    artifact_matchers=[
        ArtifactMatcher(artifact="com.company.*", match_type=ArtifactMatchType.PREFIX_MATCH),
        ArtifactMatcher(artifact="org.apache.spark.*", match_type=ArtifactMatchType.PREFIX_MATCH)
    ]
)
```
Requires metastore admin or `MANAGE_ALLOWLIST`. PUT replaces entire list -- always GET first, append, then PUT.

`artifact_type` values: `INIT_SCRIPT`, `LIBRARY_JAR`, `LIBRARY_MAVEN`. Only match type available: `PREFIX_MATCH`.

## Common Patterns

```python
# Grant SELECT on all tables in a schema (grant at schema level, inherits down)
w.grants.update(
    securable_type="schema", full_name="main.analytics",
    changes=[PermissionsChange(principal="readers", add=[Privilege.SELECT])]
)

# Check what a user can actually do (effective, not just direct)
eff = w.grants.get_effective(
    securable_type="table", full_name="main.analytics.revenue",
    principal="user@company.com"
)

# Restrict catalog to specific workspaces (isolate prod data)
w.workspace_bindings.update_bindings(
    securable_type="catalog", securable_name="prod",
    add=[WorkspaceBinding(workspace_id=111), WorkspaceBinding(workspace_id=222)]
)

# Read-modify-write artifact allowlist (safe pattern)
current = w.artifact_allowlists.get(artifact_type="LIBRARY_JAR")
matchers = list(current.artifact_matchers or [])
matchers.append(ArtifactMatcher(artifact="com.newlib.*", match_type=ArtifactMatchType.PREFIX_MATCH))
w.artifact_allowlists.update(artifact_type="LIBRARY_JAR", artifact_matchers=matchers)

# Paginate through all grants (pages may come back empty with a token still set -- keep iterating)
page = w.grants.get(securable_type="catalog", full_name="main", max_results=0)
all_assignments = list(page.privilege_assignments or [])
while page.next_page_token:
    page = w.grants.get(securable_type="catalog", full_name="main",
                        max_results=0, page_token=page.next_page_token)
    all_assignments.extend(page.privilege_assignments or [])
```

## Key Enums

```python
from databricks.sdk.service.catalog import (
    Privilege,           # SELECT, MODIFY, USAGE, USE_CATALOG, USE_SCHEMA, CREATE_TABLE, etc.
    SecurableType,       # CATALOG, SCHEMA, TABLE, VOLUME, FUNCTION, etc.
    PolicyType,          # POLICY_TYPE_ROW_FILTER, POLICY_TYPE_COLUMN_MASK
    ArtifactType,        # INIT_SCRIPT, LIBRARY_JAR, LIBRARY_MAVEN
    ArtifactMatchType,   # PREFIX_MATCH
    WorkspaceBindingBindingType,  # BINDING_TYPE_READ_WRITE, BINDING_TYPE_READ_ONLY
)
```

## Error Handling

```python
from databricks.sdk.errors import NotFound, PermissionDenied, BadRequest

try:
    w.grants.get(securable_type="catalog", full_name="nonexistent")
except NotFound:
    print("Catalog does not exist or no visibility")
except PermissionDenied:
    print("Need owner or metastore admin")
except BadRequest as e:
    print(f"Invalid params: {e}")
```

Common errors: 400 (invalid securable_type, max_results 1-149), 403 (insufficient privileges), 404 (not found).

## Gotchas

- Always use `max_results=0` for paginated grants/bindings calls; unpaginated is deprecated.
